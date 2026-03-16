package com.bank.core.controller;

import com.bank.core.dto.AccountResponse;
import com.bank.core.dto.CreateAccountRequest;
import com.bank.core.dto.MoneyOperationRequest;
import com.bank.core.dto.OperationResponse;
import com.bank.core.service.AccountService;
import com.bank.core.service.OperationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/accounts")
@RequiredArgsConstructor
public class AccountController {

    private final AccountService accountService;
    private final OperationService operationService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AccountResponse createAccount(@Valid @RequestBody CreateAccountRequest request) {
        return accountService.createAccount(request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void closeAccount(@PathVariable Long id) {
        accountService.closeAccount(id);
    }

    @GetMapping(params = "userId")
    public List<AccountResponse> getAccountsByUserId(@RequestParam Long userId) {
        return accountService.getAccountsByUserId(userId);
    }

    @GetMapping
    public List<AccountResponse> getAllAccounts() {
        return accountService.getAllAccounts();
    }

    @GetMapping("/{id}")
    public AccountResponse getAccountById(@PathVariable Long id) {
        return accountService.getAccountById(id);
    }

    @PostMapping("/{id}/deposit")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void deposit(@PathVariable Long id, @Valid @RequestBody MoneyOperationRequest request) {
        operationService.requestDeposit(id, request);
    }

    @PostMapping("/{id}/withdraw")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void withdraw(@PathVariable Long id, @Valid @RequestBody MoneyOperationRequest request) {
        operationService.requestWithdrawal(id, request);
    }

    @GetMapping("/{id}/operations")
    public Page<OperationResponse> getOperations(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return operationService.getOperationsByAccountId(id, page, size);
    }
}
