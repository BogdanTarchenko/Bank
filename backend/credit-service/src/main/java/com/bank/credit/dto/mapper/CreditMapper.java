package com.bank.credit.dto.mapper;

import com.bank.credit.dto.CreditResponse;
import com.bank.credit.dto.PaymentResponse;
import com.bank.credit.dto.TariffResponse;
import com.bank.credit.model.Credit;
import com.bank.credit.model.Payment;
import com.bank.credit.model.Tariff;

public final class CreditMapper {

    private CreditMapper() {}

    public static TariffResponse toResponse(Tariff tariff) {
        return new TariffResponse(
                tariff.getId(),
                tariff.getName(),
                tariff.getInterestRate(),
                tariff.getMinAmount(),
                tariff.getMaxAmount(),
                tariff.getMinTermDays(),
                tariff.getMaxTermDays(),
                tariff.isActive(),
                tariff.getCreatedAt()
        );
    }

    public static CreditResponse toResponse(Credit credit) {
        return new CreditResponse(
                credit.getId(),
                credit.getUserId(),
                credit.getAccountId(),
                credit.getTariff().getId(),
                credit.getTariff().getName(),
                credit.getPrincipal(),
                credit.getRemaining(),
                credit.getInterestRate(),
                credit.getTermDays(),
                credit.getDailyPayment(),
                credit.getStatus(),
                credit.getCreatedAt(),
                credit.getClosedAt()
        );
    }

    public static PaymentResponse toResponse(Payment payment) {
        return new PaymentResponse(
                payment.getId(),
                payment.getCredit().getId(),
                payment.getAmount(),
                payment.getStatus(),
                payment.getDueDate(),
                payment.getPaidAt()
        );
    }
}
