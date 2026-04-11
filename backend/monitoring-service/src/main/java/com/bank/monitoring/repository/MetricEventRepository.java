package com.bank.monitoring.repository;

import com.bank.monitoring.model.MetricEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface MetricEventRepository extends JpaRepository<MetricEvent, Long> {

    List<MetricEvent> findByServiceAndRecordedAtBetweenOrderByRecordedAtDesc(
            String service, LocalDateTime from, LocalDateTime to);

    List<MetricEvent> findByRecordedAtBetweenOrderByRecordedAtDesc(
            LocalDateTime from, LocalDateTime to);

    List<MetricEvent> findTop500ByOrderByRecordedAtDesc();

    @Query("SELECT DISTINCT m.service FROM MetricEvent m ORDER BY m.service")
    List<String> findDistinctServices();

    @Query("SELECT COUNT(m) FROM MetricEvent m WHERE m.service = :service AND m.recordedAt >= :from AND m.recordedAt <= :to")
    long countByServiceAndPeriod(@Param("service") String service,
                                 @Param("from") LocalDateTime from,
                                 @Param("to") LocalDateTime to);

    @Query("SELECT COUNT(m) FROM MetricEvent m WHERE m.service = :service AND m.statusCode >= 500 AND m.recordedAt >= :from AND m.recordedAt <= :to")
    long countErrorsByServiceAndPeriod(@Param("service") String service,
                                       @Param("from") LocalDateTime from,
                                       @Param("to") LocalDateTime to);
}
