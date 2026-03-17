package com.bank.credit.service;

import com.bank.credit.model.CreditStatus;
import com.bank.credit.model.Payment;
import com.bank.credit.model.PaymentStatus;
import com.bank.credit.repository.CreditRepository;
import com.bank.credit.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentScheduler {

    private final PaymentRepository paymentRepository;
    private final CreditRepository creditRepository;
    private final CoreServiceClient coreServiceClient;

    @Scheduled(cron = "${credit.payment-schedule:0 0 0 * * *}")
    @Transactional
    public void processPayments() {
        log.info("Запуск обработки платежей по кредитам");

        List<Payment> duePayments = paymentRepository.findByStatusAndDueDateBefore(
                PaymentStatus.PENDING, LocalDateTime.now());

        for (Payment payment : duePayments) {
            try {
                coreServiceClient.withdrawFromAccount(
                        payment.getCredit().getAccountId(),
                        payment.getAmount());

                payment.setStatus(PaymentStatus.PAID);
                payment.setPaidAt(LocalDateTime.now());
                paymentRepository.save(payment);

                // Уменьшаем остаток кредита
                var credit = payment.getCredit();
                credit.setRemaining(credit.getRemaining().subtract(payment.getAmount()));
                if (credit.getRemaining().signum() <= 0) {
                    credit.setRemaining(java.math.BigDecimal.ZERO);
                    credit.setStatus(CreditStatus.CLOSED);
                    credit.setClosedAt(LocalDateTime.now());
                }
                creditRepository.save(credit);

                log.info("Платёж {} по кредиту {} обработан", payment.getId(), credit.getId());
            } catch (Exception e) {
                payment.setStatus(PaymentStatus.OVERDUE);
                paymentRepository.save(payment);

                var credit = payment.getCredit();
                if (credit.getStatus() != CreditStatus.OVERDUE) {
                    credit.setStatus(CreditStatus.OVERDUE);
                    creditRepository.save(credit);
                }

                log.warn("Платёж {} просрочен: {}", payment.getId(), e.getMessage());
            }
        }

        log.info("Обработка платежей завершена: {} платежей", duePayments.size());
    }
}
