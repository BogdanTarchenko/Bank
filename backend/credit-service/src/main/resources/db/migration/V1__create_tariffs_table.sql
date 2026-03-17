CREATE TABLE tariffs (
    id            BIGSERIAL PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    min_amount    DECIMAL(19,2) NOT NULL DEFAULT 1000,
    max_amount    DECIMAL(19,2) NOT NULL DEFAULT 10000000,
    min_term_days INTEGER NOT NULL DEFAULT 30,
    max_term_days INTEGER NOT NULL DEFAULT 3650,
    active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT now()
);
