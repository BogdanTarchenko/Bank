package com.bank.credit.repository;

import com.bank.credit.model.Payment;
import com.bank.credit.model.PaymentStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

    List<Payment> findByCreditIdOrderByDueDateAsc(Long creditId);

    List<Payment> findByStatusAndDueDateBefore(PaymentStatus status, LocalDateTime dateTime);

    int countByCreditUserIdAndStatus(Long userId, PaymentStatus status);

    int countByCreditUserId(Long userId);
}
