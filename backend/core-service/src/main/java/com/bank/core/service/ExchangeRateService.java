package com.bank.core.service;

import com.bank.core.model.Currency;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ExchangeRateService {

    private final ExchangeRateClient exchangeRateClient;

    public BigDecimal getRate(Currency from, Currency to) {
        if (from == to) {
            return BigDecimal.ONE;
        }
        Map<String, BigDecimal> rates = exchangeRateClient.getRates(from);
        return rates.get(to.name());
    }

    public BigDecimal convert(BigDecimal amount, Currency from, Currency to) {
        if (from == to) {
            return amount;
        }
        BigDecimal rate = getRate(from, to);
        return amount.multiply(rate).setScale(4, RoundingMode.HALF_UP);
    }
}
