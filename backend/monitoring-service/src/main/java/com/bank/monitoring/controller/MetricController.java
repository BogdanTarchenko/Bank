package com.bank.monitoring.controller;

import com.bank.monitoring.dto.MetricEventRequest;
import com.bank.monitoring.dto.MetricStats;
import com.bank.monitoring.dto.TraceDetails;
import com.bank.monitoring.dto.TraceSummary;
import com.bank.monitoring.model.MetricEvent;
import com.bank.monitoring.service.MetricService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/metrics")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class MetricController {

    private final MetricService metricService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public MetricEvent create(@Valid @RequestBody MetricEventRequest request) {
        return metricService.save(request);
    }

    @GetMapping
    public List<MetricEvent> list(
            @RequestParam(required = false) String service,
            @RequestParam(defaultValue = "1") int hours) {
        return metricService.getRecentEvents(service, hours);
    }

    @GetMapping("/stats")
    public List<MetricStats> stats(@RequestParam(defaultValue = "1") int hours) {
        return metricService.getStats(hours);
    }

    @GetMapping("/services")
    public List<String> services() {
        return metricService.getAllServices();
    }

    @GetMapping("/errors")
    public List<MetricEvent> errors(
            @RequestParam(required = false) String service,
            @RequestParam(defaultValue = "1") int hours,
            @RequestParam(defaultValue = "200") int limit) {
        return metricService.getErrors(service, hours, limit);
    }

    @GetMapping("/traces")
    public List<TraceSummary> traces(
            @RequestParam(required = false) String service,
            @RequestParam(defaultValue = "1") int hours,
            @RequestParam(defaultValue = "100") int limit) {
        return metricService.getTraces(service, hours, limit);
    }

    @GetMapping("/traces/{traceId}")
    public ResponseEntity<TraceDetails> trace(@PathVariable String traceId) {
        TraceDetails details = metricService.getTrace(traceId);
        if (details == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(details);
    }
}
