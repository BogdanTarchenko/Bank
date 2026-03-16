package com.bank.core.dto.mapper;

import com.bank.core.dto.AccountResponse;
import com.bank.core.dto.CreateAccountRequest;
import com.bank.core.model.Account;
import com.bank.core.model.AccountType;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@NoArgsConstructor(access = AccessLevel.PRIVATE)
public final class AccountMapper {

    public static AccountResponse toResponse(Account account) {
        return new AccountResponse(
                account.getId(),
                account.getUserId(),
                account.getCurrency(),
                account.getBalance(),
                account.getAccountType(),
                account.getIsClosed(),
                account.getCreatedAt()
        );
    }

    public static Account toEntity(CreateAccountRequest request) {
        return Account.builder()
                .userId(request.userId())
                .currency(request.currency())
                .balance(BigDecimal.ZERO)
                .accountType(AccountType.PERSONAL)
                .isClosed(false)
                .build();
    }
}
