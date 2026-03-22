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
import java.time.Duration;
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

        String accountCurrency = coreServiceClient.getAccountCurrency(request.accountId());
        if (!accountCurrency.equalsIgnoreCase(tariff.getCurrency())) {
            throw new InvalidCreditAmountException(
                    String.format("Валюта счёта (%s) не совпадает с валютой тарифа кредита (%s). Выберите счёт в валюте %s.",
                            accountCurrency, tariff.getCurrency(), tariff.getCurrency()));
        }

        if (request.amount().compareTo(tariff.getMinAmount()) < 0 ||
            request.amount().compareTo(tariff.getMaxAmount()) > 0) {
            throw new InvalidCreditAmountException(
                    String.format("Сумма кредита должна быть от %s до %s", tariff.getMinAmount(), tariff.getMaxAmount()));
        }

        if (request.termDays() < tariff.getMinTermDays() || request.termDays() > tariff.getMaxTermDays()) {
            throw new InvalidCreditAmountException(
                    String.format("Срок кредита должен быть от %d до %d дней", tariff.getMinTermDays(), tariff.getMaxTermDays()));
        }

        double annualRateD = tariff.getInterestRate().doubleValue() / 100.0;
        double minuteRate = annualRateD / (365.0 * 24 * 60);
        double effectiveDailyRate = Math.pow(1 + minuteRate, 1440) - 1;
        BigDecimal dailyRate = BigDecimal.valueOf(effectiveDailyRate);

        BigDecimal dailyPayment;
        if (effectiveDailyRate == 0) {
            dailyPayment = request.amount()
                    .divide(BigDecimal.valueOf(request.termDays()), 2, RoundingMode.CEILING);
        } else {
            double annuity = request.amount().doubleValue() * effectiveDailyRate
                    / (1 - Math.pow(1 + effectiveDailyRate, -request.termDays()));
            dailyPayment = BigDecimal.valueOf(annuity).setScale(2, RoundingMode.CEILING);
        }

        Credit credit = Credit.builder()
                .userId(request.userId())
                .accountId(request.accountId())
                .tariff(tariff)
                .principal(request.amount())
                .remaining(request.amount())
                .interestRate(tariff.getInterestRate())
                .termDays(request.termDays())
                .dailyPayment(dailyPayment)
                .status(CreditStatus.ACTIVE)
                .build();

        credit = creditRepository.save(credit);

        // Создаём расписание аннуитетных платежей с процентами на остаток
        LocalDateTime dueDate = LocalDateTime.now().plusDays(1);
        BigDecimal remainingPrincipal = request.amount();
        for (int i = 0; i < request.termDays(); i++) {
            BigDecimal interest = remainingPrincipal.multiply(dailyRate)
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal paymentAmount;
            if (i == request.termDays() - 1) {
                paymentAmount = remainingPrincipal.add(interest);
            } else {
                paymentAmount = dailyPayment;
            }
            if (paymentAmount.compareTo(BigDecimal.ZERO) <= 0) break;

            BigDecimal principalPortion = paymentAmount.subtract(interest);
            remainingPrincipal = remainingPrincipal.subtract(principalPortion)
                    .max(BigDecimal.ZERO);

            Payment payment = Payment.builder()
                    .credit(credit)
                    .amount(paymentAmount)
                    .status(PaymentStatus.PENDING)
                    .dueDate(dueDate.plusDays(i))
                    .build();
            paymentRepository.save(payment);
        }

        coreServiceClient.transferFromMasterAccount(request.accountId(), request.amount(), tariff.getCurrency());

        return CreditMapper.toResponse(credit, BigDecimal.ZERO);
    }

    @Transactional(readOnly = true)
    public CreditResponse getCreditById(Long id) {
        Credit credit = findById(id);
        return CreditMapper.toResponse(credit, calcAccruedInterest(credit));
    }

    @Transactional(readOnly = true)
    public List<CreditResponse> getCreditsByUserId(Long userId) {
        return creditRepository.findByUserId(userId).stream()
                .map(c -> CreditMapper.toResponse(c, calcAccruedInterest(c)))
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

        BigDecimal accruedInterest = calcAccruedInterest(credit);
        BigDecimal totalOwed = credit.getRemaining().add(accruedInterest);
        BigDecimal repayAmount = request.amount().min(totalOwed);

        coreServiceClient.withdrawFromAccount(credit.getAccountId(), repayAmount);

        // Сначала гасим набежавшие проценты, остаток — в тело долга
        BigDecimal interestPaid = repayAmount.min(accruedInterest);
        BigDecimal principalPaid = repayAmount.subtract(interestPaid);
        credit.setRemaining(credit.getRemaining().subtract(principalPaid));
        credit.setLastAccrualAt(LocalDateTime.now());

        List<Payment> pendingPayments = paymentRepository.findByCreditIdOrderByDueDateAsc(creditId).stream()
                .filter(p -> p.getStatus() == PaymentStatus.PENDING || p.getStatus() == PaymentStatus.OVERDUE)
                .toList();

        BigDecimal remainingRepay = repayAmount;
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
            pendingPayments.stream()
                    .filter(p -> p.getStatus() == PaymentStatus.PENDING || p.getStatus() == PaymentStatus.OVERDUE)
                    .forEach(p -> {
                        p.setStatus(PaymentStatus.PAID);
                        p.setPaidAt(LocalDateTime.now());
                        paymentRepository.save(p);
                    });
        }

        credit = creditRepository.save(credit);
        return CreditMapper.toResponse(credit, calcAccruedInterest(credit));
    }

    private BigDecimal calcAccruedInterest(Credit credit) {
        long minutesElapsed = Duration.between(credit.getLastAccrualAt(), LocalDateTime.now()).toMinutes();
        if (minutesElapsed <= 0) return BigDecimal.ZERO;

        double minuteRate = credit.getInterestRate().doubleValue() / 100.0 / (365.0 * 24 * 60);
        double factor = Math.pow(1 + minuteRate, minutesElapsed) - 1;
        return credit.getRemaining().multiply(BigDecimal.valueOf(factor))
                .setScale(2, RoundingMode.HALF_UP);
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
