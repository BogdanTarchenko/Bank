package com.bank.monitoring.dto;

public record MetricStats(
        String service,
        long totalRequests,
        long errorCount,
        double errorRate,
        double avgDurationMs,
        double p95DurationMs
) {
}
