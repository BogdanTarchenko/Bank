CREATE TABLE credits (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    account_id      BIGINT NOT NULL,
    tariff_id       BIGINT NOT NULL REFERENCES tariffs(id),
    principal       DECIMAL(19,2) NOT NULL,
    remaining       DECIMAL(19,2) NOT NULL,
    interest_rate   DECIMAL(5,2) NOT NULL,
    term_days       INTEGER NOT NULL,
    daily_payment   DECIMAL(19,2) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    closed_at       TIMESTAMP
);

CREATE INDEX idx_credits_user_id ON credits(user_id);
CREATE INDEX idx_credits_status ON credits(status);
