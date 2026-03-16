CREATE TABLE accounts (
    id           BIGSERIAL    PRIMARY KEY,
    user_id      BIGINT       NOT NULL,
    currency     VARCHAR(3)   NOT NULL CHECK (currency IN ('RUB', 'USD', 'EUR')),
    balance      NUMERIC(19, 4) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    account_type VARCHAR(20)  NOT NULL DEFAULT 'PERSONAL' CHECK (account_type IN ('PERSONAL', 'MASTER')),
    is_closed    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at   TIMESTAMP    NOT NULL DEFAULT now(),
    version      BIGINT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_accounts_user_id ON accounts (user_id);
CREATE INDEX idx_accounts_type ON accounts (account_type);

CREATE UNIQUE INDEX uq_master_account_per_currency
    ON accounts (account_type, currency)
    WHERE account_type = 'MASTER';
