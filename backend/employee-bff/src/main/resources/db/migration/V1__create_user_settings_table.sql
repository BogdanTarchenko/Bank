CREATE TABLE user_settings (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL UNIQUE,
    theme           VARCHAR(20) NOT NULL DEFAULT 'LIGHT',
    hidden_accounts TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now()
);
