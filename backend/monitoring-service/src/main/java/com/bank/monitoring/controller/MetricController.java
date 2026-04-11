package com.bank.monitoring.controller;

import com.bank.monitoring.dto.MetricEventRequest;
import com.bank.monitoring.dto.MetricStats;
import com.bank.monitoring.model.MetricEvent;
import com.bank.monitoring.service.MetricService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
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
}
