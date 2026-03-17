package com.bank.credit.controller;

import com.bank.credit.dto.CreateTariffRequest;
import com.bank.credit.dto.TariffResponse;
import com.bank.credit.service.TariffService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/tariffs")
@RequiredArgsConstructor
public class TariffController {

    private final TariffService tariffService;

    @GetMapping
    public List<TariffResponse> getTariffs() {
        return tariffService.getActiveTariffs();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TariffResponse createTariff(@Valid @RequestBody CreateTariffRequest request) {
        return tariffService.createTariff(request);
    }
}
