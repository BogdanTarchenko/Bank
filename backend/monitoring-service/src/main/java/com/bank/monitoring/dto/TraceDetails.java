package com.bank.monitoring.dto;

import com.bank.monitoring.model.MetricEvent;

import java.util.List;

public record TraceDetails(
        TraceSummary summary,
        List<MetricEvent> spans
) {
}
