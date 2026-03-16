package com.bank.core.dto.mapper;

import com.bank.core.dto.OperationResponse;
import com.bank.core.model.Operation;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;

@NoArgsConstructor(access = AccessLevel.PRIVATE)
public final class OperationMapper {

    public static OperationResponse toResponse(Operation operation) {
        return new OperationResponse(
                operation.getId(),
                operation.getAccount().getId(),
                operation.getType(),
                operation.getAmount(),
                operation.getCurrency(),
                operation.getRelatedAccount() != null ? operation.getRelatedAccount().getId() : null,
                operation.getExchangeRate(),
                operation.getDescription(),
                operation.getCreatedAt()
        );
    }
}
