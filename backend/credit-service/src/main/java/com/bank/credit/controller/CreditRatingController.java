package com.bank.credit.controller;

import com.bank.credit.dto.CreditRatingResponse;
import com.bank.credit.service.CreditService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class CreditRatingController {

    private final CreditService creditService;

    @GetMapping("/{id}/credit-rating")
    public CreditRatingResponse getCreditRating(@PathVariable Long id) {
        return creditService.getCreditRating(id);
    }
}
