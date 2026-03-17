package com.bank.credit.controller;

import com.bank.credit.dto.*;
import com.bank.credit.service.CreditService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/credits")
@RequiredArgsConstructor
public class CreditController {

    private final CreditService creditService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CreditResponse createCredit(@Valid @RequestBody CreateCreditRequest request) {
        return creditService.createCredit(request);
    }

    @GetMapping("/{id}")
    public CreditResponse getCredit(@PathVariable Long id) {
        return creditService.getCreditById(id);
    }

    @GetMapping
    public List<CreditResponse> getCreditsByUser(@RequestParam Long userId) {
        return creditService.getCreditsByUserId(userId);
    }

    @GetMapping("/{id}/payments")
    public List<PaymentResponse> getPayments(@PathVariable Long id) {
        return creditService.getPayments(id);
    }

    @PostMapping("/{id}/repay")
    public CreditResponse repayCredit(@PathVariable Long id, @Valid @RequestBody RepayRequest request) {
        return creditService.repayCredit(id, request);
    }
}
