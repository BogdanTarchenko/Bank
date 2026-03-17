package com.bank.credit.repository;

import com.bank.credit.model.Credit;
import com.bank.credit.model.CreditStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CreditRepository extends JpaRepository<Credit, Long> {

    List<Credit> findByUserId(Long userId);

    List<Credit> findByStatus(CreditStatus status);
}
