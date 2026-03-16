package com.bank.core.controller;

import com.bank.core.dto.AccountResponse;
import com.bank.core.model.Currency;
import com.bank.core.service.AccountService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/master-account")
@RequiredArgsConstructor
public class MasterAccountController {

    private final AccountService accountService;

    @GetMapping
    public List<AccountResponse> getMasterAccounts() {
        return accountService.getAllMasterAccounts();
    }

    @GetMapping(params = "currency")
    public AccountResponse getMasterAccount(@RequestParam Currency currency) {
        return accountService.getMasterAccount(currency);
    }
}
