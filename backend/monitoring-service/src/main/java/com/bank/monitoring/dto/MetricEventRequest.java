package com.bank.monitoring.dto;

import jakarta.validation.constraints.NotBlank;

import java.time.LocalDateTime;

public record MetricEventRequest(
        @NotBlank String type,
        @NotBlank String service,
        String traceId,
        LocalDateTime recordedAt,
        Long durationMs,
        String method,
        String path,
        Integer statusCode,
        String errorMessage,
        String metadata
) {
}
