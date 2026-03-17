CREATE TABLE payments (
    id         BIGSERIAL PRIMARY KEY,
    credit_id  BIGINT NOT NULL REFERENCES credits(id),
    amount     DECIMAL(19,2) NOT NULL,
    status     VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    due_date   TIMESTAMP NOT NULL,
    paid_at    TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_credit_id ON payments(credit_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_due_date ON payments(due_date);
