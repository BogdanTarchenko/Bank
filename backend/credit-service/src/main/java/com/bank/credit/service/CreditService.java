package com.bank.credit.service;

import com.bank.credit.dto.*;
import com.bank.credit.dto.mapper.CreditMapper;
import com.bank.credit.exception.CreditAlreadyClosedException;
import com.bank.credit.exception.CreditNotFoundException;
import com.bank.credit.exception.InvalidCreditAmountException;
import com.bank.credit.model.*;
import com.bank.credit.repository.CreditRepository;
import com.bank.credit.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CreditService {

    private final CreditRepository creditRepository;
    private final PaymentRepository paymentRepository;
    private final TariffService tariffService;
    private final CoreServiceClient coreServiceClient;

    @Transactional
    public CreditResponse createCredit(CreateCreditRequest request) {
        Tariff tariff = tariffService.findById(request.tariffId());

        if (request.amount().compareTo(tariff.getMinAmount()) < 0 ||
            request.amount().compareTo(tariff.getMaxAmount()) > 0) {
            throw new InvalidCreditAmountException(
                    String.format("Сумма кредита должна быть от %s до %s", tariff.getMinAmount(), tariff.getMaxAmount()));
        }

        if (request.termDays() < tariff.getMinTermDays() || request.termDays() > tariff.getMaxTermDays()) {
            throw new InvalidCreditAmountException(
                    String.format("Срок кредита должен быть от %d до %d дней", tariff.getMinTermDays(), tariff.getMaxTermDays()));
        }

        BigDecimal totalWithInterest = request.amount()
                .multiply(BigDecimal.ONE.add(tariff.getInterestRate().divide(BigDecimal.valueOf(100), 10, RoundingMode.HALF_UP)));
        BigDecimal dailyPayment = totalWithInterest.divide(BigDecimal.valueOf(request.termDays()), 2, RoundingMode.CEILING);

        Credit credit = Credit.builder()
                .userId(request.userId())
                .accountId(request.accountId())
                .tariff(tariff)
                .principal(request.amount())
                .remaining(totalWithInterest)
                .interestRate(tariff.getInterestRate())
                .termDays(request.termDays())
                .dailyPayment(dailyPayment)
                .status(CreditStatus.ACTIVE)
                .build();

        credit = creditRepository.save(credit);

        // Создаём расписание платежей
        LocalDateTime dueDate = LocalDateTime.now().plusDays(1);
        for (int i = 0; i < request.termDays(); i++) {
            BigDecimal paymentAmount = (i == request.termDays() - 1)
                    ? credit.getRemaining().subtract(dailyPayment.multiply(BigDecimal.valueOf(i)))
                    : dailyPayment;
            if (paymentAmount.compareTo(BigDecimal.ZERO) <= 0) break;

            Payment payment = Payment.builder()
                    .credit(credit)
                    .amount(paymentAmount)
                    .status(PaymentStatus.PENDING)
                    .dueDate(dueDate.plusDays(i))
                    .build();
            paymentRepository.save(payment);
        }

        // Перевод денег с мастер-счёта на счёт клиента
        coreServiceClient.transferFromMasterAccount(request.accountId(), request.amount());

        return CreditMapper.toResponse(credit);
    }

    @Transactional(readOnly = true)
    public CreditResponse getCreditById(Long id) {
        return CreditMapper.toResponse(findById(id));
    }

    @Transactional(readOnly = true)
    public List<CreditResponse> getCreditsByUserId(Long userId) {
        return creditRepository.findByUserId(userId).stream()
                .map(CreditMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PaymentResponse> getPayments(Long creditId) {
        findById(creditId); // проверяем существование
        return paymentRepository.findByCreditIdOrderByDueDateAsc(creditId).stream()
                .map(CreditMapper::toResponse)
                .toList();
    }

    @Transactional
    public CreditResponse repayCredit(Long creditId, RepayRequest request) {
        Credit credit = findById(creditId);
        if (credit.getStatus() == CreditStatus.CLOSED) {
            throw new CreditAlreadyClosedException(creditId);
        }

        BigDecimal repayAmount = request.amount().min(credit.getRemaining());

        // Списываем со счёта клиента
        coreServiceClient.withdrawFromAccount(credit.getAccountId(), repayAmount);

        credit.setRemaining(credit.getRemaining().subtract(repayAmount));

        // Закрываем ожидающие платежи на сумму погашения
        BigDecimal remainingRepay = repayAmount;
        List<Payment> pendingPayments = paymentRepository.findByCreditIdOrderByDueDateAsc(creditId).stream()
                .filter(p -> p.getStatus() == PaymentStatus.PENDING || p.getStatus() == PaymentStatus.OVERDUE)
                .toList();

        for (Payment payment : pendingPayments) {
            if (remainingRepay.compareTo(BigDecimal.ZERO) <= 0) break;
            if (remainingRepay.compareTo(payment.getAmount()) >= 0) {
                remainingRepay = remainingRepay.subtract(payment.getAmount());
                payment.setStatus(PaymentStatus.PAID);
                payment.setPaidAt(LocalDateTime.now());
                paymentRepository.save(payment);
            }
        }

        if (credit.getRemaining().compareTo(BigDecimal.ZERO) <= 0) {
            credit.setRemaining(BigDecimal.ZERO);
            credit.setStatus(CreditStatus.CLOSED);
            credit.setClosedAt(LocalDateTime.now());
        }

        return CreditMapper.toResponse(creditRepository.save(credit));
    }

    @Transactional(readOnly = true)
    public CreditRatingResponse getCreditRating(Long userId) {
        List<Credit> credits = creditRepository.findByUserId(userId);
        int totalCredits = credits.size();
        int activeCredits = (int) credits.stream().filter(c -> c.getStatus() == CreditStatus.ACTIVE).count();
        int overduePayments = paymentRepository.countByCreditUserIdAndStatus(userId, PaymentStatus.OVERDUE);
        int totalPayments = paymentRepository.countByCreditUserId(userId);

        // Формула рейтинга: базовый 850, -50 за каждый просроченный платёж, +10 за каждый закрытый кредит
        int score = 850;
        score -= overduePayments * 50;
        score += (totalCredits - activeCredits) * 10;
        score = Math.max(300, Math.min(850, score));

        String grade;
        if (score >= 750) grade = "EXCELLENT";
        else if (score >= 650) grade = "GOOD";
        else if (score >= 550) grade = "FAIR";
        else if (score >= 450) grade = "POOR";
        else grade = "BAD";

        return new CreditRatingResponse(userId, score, grade, totalCredits, activeCredits, overduePayments, totalPayments);
    }

    private Credit findById(Long id) {
        return creditRepository.findById(id)
                .orElseThrow(() -> new CreditNotFoundException(id));
    }
}
