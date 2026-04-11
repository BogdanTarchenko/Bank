package com.bank.monitoring.dto;

import java.time.LocalDateTime;
import java.util.List;

public record TraceSummary(
        String traceId,
        LocalDateTime startTime,
        LocalDateTime endTime,
        long totalDurationMs,
        int spanCount,
        int errorCount,
        List<String> services,
        String rootService,
        String rootMethod,
        String rootPath,
        Integer rootStatus,
        boolean hasError
) {
}
