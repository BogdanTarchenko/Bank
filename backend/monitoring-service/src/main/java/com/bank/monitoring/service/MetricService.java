package com.bank.monitoring.service;

import com.bank.monitoring.dto.MetricEventRequest;
import com.bank.monitoring.dto.MetricStats;
import com.bank.monitoring.model.MetricEvent;
import com.bank.monitoring.repository.MetricEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MetricService {

    private final MetricEventRepository repository;

    @Transactional
    public MetricEvent save(MetricEventRequest req) {
        MetricEvent event = MetricEvent.builder()
                .type(req.type())
                .service(req.service())
                .traceId(req.traceId())
                .recordedAt(req.recordedAt() != null ? req.recordedAt() : LocalDateTime.now())
                .durationMs(req.durationMs())
                .method(req.method())
                .path(req.path())
                .statusCode(req.statusCode())
                .errorMessage(req.errorMessage())
                .metadata(req.metadata())
                .build();
        return repository.save(event);
    }

    @Transactional(readOnly = true)
    public List<MetricEvent> getRecentEvents(String service, int hours) {
        LocalDateTime from = LocalDateTime.now().minusHours(hours);
        LocalDateTime to = LocalDateTime.now();

        List<MetricEvent> events;
        if (service != null && !service.isBlank()) {
            events = repository.findByServiceAndRecordedAtBetweenOrderByRecordedAtDesc(service, from, to);
        } else {
            events = repository.findByRecordedAtBetweenOrderByRecordedAtDesc(from, to);
        }

        return events.size() > 500 ? events.subList(0, 500) : events;
    }

    @Transactional(readOnly = true)
    public List<MetricStats> getStats(int hours) {
        LocalDateTime from = LocalDateTime.now().minusHours(hours);
        LocalDateTime to = LocalDateTime.now();

        List<String> services = repository.findDistinctServices();
        List<MetricStats> stats = new ArrayList<>();

        for (String svc : services) {
            long totalRequests = repository.countByServiceAndPeriod(svc, from, to);
            long errorCount = repository.countErrorsByServiceAndPeriod(svc, from, to);
            double errorRate = totalRequests > 0 ? (double) errorCount / totalRequests * 100.0 : 0.0;

            List<MetricEvent> events = repository.findByServiceAndRecordedAtBetweenOrderByRecordedAtDesc(svc, from, to);
            List<Long> durations = events.stream()
                    .filter(e -> e.getDurationMs() != null)
                    .map(MetricEvent::getDurationMs)
                    .sorted()
                    .toList();

            double avgDuration = durations.isEmpty() ? 0.0
                    : durations.stream().mapToLong(Long::longValue).average().orElse(0.0);

            double p95Duration = 0.0;
            if (!durations.isEmpty()) {
                int p95Index = (int) Math.ceil(durations.size() * 0.95) - 1;
                p95Duration = durations.get(Math.max(0, p95Index));
            }

            stats.add(new MetricStats(svc, totalRequests, errorCount, errorRate, avgDuration, p95Duration));
        }

        stats.sort((a, b) -> a.service().compareToIgnoreCase(b.service()));
        return stats;
    }

    @Transactional(readOnly = true)
    public List<String> getAllServices() {
        return repository.findDistinctServices();
    }
}
