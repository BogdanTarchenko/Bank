package com.bank.core.controller;

import com.bank.core.dto.AccountResponse;
import com.bank.core.dto.MasterAccountTransferRequest;
import com.bank.core.dto.TransferRequest;
import com.bank.core.model.Currency;
import com.bank.core.service.AccountService;
import com.bank.core.service.OperationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/master-account")
@RequiredArgsConstructor
public class MasterAccountController {

    private final AccountService accountService;
    private final OperationService operationService;

    @GetMapping
    public List<AccountResponse> getMasterAccounts() {
        return accountService.getAllMasterAccounts();
    }

    @GetMapping(params = "currency")
    public AccountResponse getMasterAccount(@RequestParam Currency currency) {
        return accountService.getMasterAccount(currency);
    }

    @PostMapping("/transfer")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void transferFromMasterAccount(@Valid @RequestBody MasterAccountTransferRequest request) {
        AccountResponse targetAccount = accountService.getAccountById(request.targetAccountId());
        AccountResponse masterAccount = accountService.getMasterAccount(targetAccount.currency());

        operationService.requestTransfer(new TransferRequest(
                masterAccount.id(),
                request.targetAccountId(),
                request.amount()
        ));
    }
}
