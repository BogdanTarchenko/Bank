package com.bank.credit.service;

import com.bank.credit.dto.CreateTariffRequest;
import com.bank.credit.dto.TariffResponse;
import com.bank.credit.dto.mapper.CreditMapper;
import com.bank.credit.exception.TariffNotFoundException;
import com.bank.credit.model.Tariff;
import com.bank.credit.repository.TariffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TariffService {

    private final TariffRepository tariffRepository;

    @Transactional
    public TariffResponse createTariff(CreateTariffRequest request) {
        Tariff tariff = Tariff.builder()
                .name(request.name())
                .interestRate(request.interestRate())
                .minAmount(request.minAmount() != null ? request.minAmount() : new BigDecimal("1000"))
                .maxAmount(request.maxAmount() != null ? request.maxAmount() : new BigDecimal("10000000"))
                .minTermDays(request.minTermDays() != null ? request.minTermDays() : 30)
                .maxTermDays(request.maxTermDays() != null ? request.maxTermDays() : 3650)
                .active(true)
                .build();
        return CreditMapper.toResponse(tariffRepository.save(tariff));
    }

    @Transactional(readOnly = true)
    public List<TariffResponse> getActiveTariffs() {
        return tariffRepository.findByActiveTrue().stream()
                .map(CreditMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Tariff findById(Long id) {
        return tariffRepository.findById(id)
                .orElseThrow(() -> new TariffNotFoundException(id));
    }
}
