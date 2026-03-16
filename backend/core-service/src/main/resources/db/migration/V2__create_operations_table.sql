CREATE TABLE operations (
    id                 BIGSERIAL      PRIMARY KEY,
    idempotency_key    UUID           NOT NULL UNIQUE,
    account_id         BIGINT         NOT NULL REFERENCES accounts (id),
    type               VARCHAR(20)    NOT NULL CHECK (type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER_IN', 'TRANSFER_OUT')),
    amount             NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
    currency           VARCHAR(3)     NOT NULL CHECK (currency IN ('RUB', 'USD', 'EUR')),
    related_account_id BIGINT         REFERENCES accounts (id),
    exchange_rate      NUMERIC(12, 6),
    description        VARCHAR(500),
    created_at         TIMESTAMP      NOT NULL DEFAULT now()
);

CREATE INDEX idx_operations_account_id ON operations (account_id);
CREATE INDEX idx_operations_created_at ON operations (created_at);
CREATE INDEX idx_operations_account_created ON operations (account_id, created_at DESC);
