package com.bank.credit.dto;

public record CreditRatingResponse(
        Long userId,
        int score,
        String grade,
        int totalCredits,
        int activeCredits,
        int overduePayments,
        int totalPayments
) {}
