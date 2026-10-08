CREATE TABLE IF NOT EXISTS work_order_triage (
    work_order_id VARCHAR(32) PRIMARY KEY,
    asset VARCHAR(80) NOT NULL,
    priority VARCHAR(16) NOT NULL,
    summary VARCHAR(240) NOT NULL,
    source_status VARCHAR(24) NOT NULL,
    triage_state VARCHAR(24) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
