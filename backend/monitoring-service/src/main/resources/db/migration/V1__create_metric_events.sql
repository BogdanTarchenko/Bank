CREATE TABLE metric_events (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    service VARCHAR(100) NOT NULL,
    trace_id VARCHAR(100),
    recorded_at TIMESTAMP NOT NULL,
    duration_ms BIGINT,
    method VARCHAR(10),
    path VARCHAR(500),
    status_code INTEGER,
    error_message TEXT,
    metadata TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_metric_events_service ON metric_events(service);
CREATE INDEX idx_metric_events_type ON metric_events(type);
CREATE INDEX idx_metric_events_recorded_at ON metric_events(recorded_at);
CREATE INDEX idx_metric_events_status_code ON metric_events(status_code);
