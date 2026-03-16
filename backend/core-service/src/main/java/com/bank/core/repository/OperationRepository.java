package com.bank.core.repository;

import com.bank.core.model.Operation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface OperationRepository extends JpaRepository<Operation, Long> {

    Page<Operation> findByAccountIdOrderByCreatedAtDesc(Long accountId, Pageable pageable);

    boolean existsByIdempotencyKey(UUID idempotencyKey);
}
