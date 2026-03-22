CREATE TABLE outbox_events
(
    id          BIGSERIAL    PRIMARY KEY,
    topic       VARCHAR(255) NOT NULL,
    event_key   VARCHAR(255),
    payload     TEXT         NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                             CHECK (status IN ('PENDING', 'SENT', 'FAILED')),
    retry_count INT          NOT NULL DEFAULT 0,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    sent_at     TIMESTAMP
);

CREATE INDEX idx_outbox_status_created ON outbox_events (status, created_at)
    WHERE status = 'PENDING';
