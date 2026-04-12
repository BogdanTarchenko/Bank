package com.bank.monitoring.service;

import com.bank.monitoring.dto.MetricEventRequest;
import com.bank.monitoring.dto.MetricStats;
import com.bank.monitoring.dto.TraceDetails;
import com.bank.monitoring.dto.TraceSummary;
import com.bank.monitoring.model.MetricEvent;
import com.bank.monitoring.repository.MetricEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

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

    @Transactional(readOnly = true)
    public List<TraceSummary> getTraces(String service, int hours, int limit) {
        LocalDateTime from = LocalDateTime.now().minusHours(hours);
        LocalDateTime to = LocalDateTime.now();
        String svcFilter = (service != null && !service.isBlank()) ? service : null;

        List<String> traceIds = repository.findDistinctTraceIds(from, to, svcFilter, PageRequest.of(0, limit));
        List<TraceSummary> result = new ArrayList<>();

        for (String traceId : traceIds) {
            List<MetricEvent> spans = repository.findByTraceIdOrderByRecordedAtAsc(traceId);
            if (spans.isEmpty()) continue;
            result.add(buildSummary(traceId, spans));
        }

        result.sort(Comparator.comparing(TraceSummary::startTime).reversed());
        return result;
    }

    @Transactional(readOnly = true)
    public TraceDetails getTrace(String traceId) {
        List<MetricEvent> spans = repository.findByTraceIdOrderByRecordedAtAsc(traceId);
        if (spans.isEmpty()) {
            return null;
        }
        return new TraceDetails(buildSummary(traceId, spans), spans);
    }

    @Transactional(readOnly = true)
    public List<MetricEvent> getErrors(String service, int hours, int limit) {
        LocalDateTime from = LocalDateTime.now().minusHours(hours);
        LocalDateTime to = LocalDateTime.now();
        String svcFilter = (service != null && !service.isBlank()) ? service : null;
        return repository.findErrors(from, to, svcFilter, PageRequest.of(0, limit));
    }

    private TraceSummary buildSummary(String traceId, List<MetricEvent> spans) {
        MetricEvent first = spans.get(0);
        MetricEvent last = spans.get(spans.size() - 1);

        LocalDateTime startTime = first.getRecordedAt();
        LocalDateTime endTime = last.getRecordedAt();

        long endMillis = endTime.atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
        long startMillis = startTime.atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
        long totalDuration = endMillis - startMillis;
        Long lastDuration = last.getDurationMs();
        if (lastDuration != null) totalDuration += lastDuration;
        if (totalDuration < 0) totalDuration = 0;

        // rough fallback: if spans share same timestamp (common when all recorded near-simultaneously)
        if (totalDuration == 0) {
            totalDuration = spans.stream()
                    .filter(s -> s.getDurationMs() != null)
                    .mapToLong(MetricEvent::getDurationMs)
                    .max().orElse(0L);
        }

        Set<String> services = new LinkedHashSet<>();
        int errorCount = 0;
        for (MetricEvent span : spans) {
            services.add(span.getService());
            if (span.getStatusCode() != null && span.getStatusCode() >= 500) {
                errorCount++;
            }
        }

        // Root span = shortest path or first recorded. Use first recorded.
        MetricEvent root = first;
        // Prefer a BFF/auth entry point as root if present
        for (MetricEvent span : spans) {
            if (span.getService() != null && (span.getService().contains("bff") || span.getService().contains("auth"))) {
                root = span;
                break;
            }
        }

        return new TraceSummary(
                traceId,
                startTime,
                endTime,
                totalDuration,
                spans.size(),
                errorCount,
                new ArrayList<>(services),
                root.getService(),
                root.getMethod(),
                root.getPath(),
                root.getStatusCode(),
                errorCount > 0
        );
    }
}
