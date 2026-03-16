package com.bank.core.controller;

import com.bank.core.dto.TransferRequest;
import com.bank.core.service.OperationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/transfers")
@RequiredArgsConstructor
public class TransferController {

    private final OperationService operationService;

    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void transfer(@Valid @RequestBody TransferRequest request) {
        operationService.requestTransfer(request);
    }
}
