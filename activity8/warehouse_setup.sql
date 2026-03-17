CREATE SCHEMA IF NOT EXISTS dw;

CREATE TABLE IF NOT EXISTS dw.dim_date(
    date_key INT PRIMARY KEY,
    date DATE UNIQUE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    day_of_week INT NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_customer (
    customer_key BIGSERIAL PRIMARY KEY,
    source_id BIGINT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    region_code TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_product (
    product_key BIGSERIAL PRIMARY KEY,
    source_id BIGINT UNIQUE NOT NULL,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_branch (
    branch_key BIGSERIAL PRIMARY KEY,
    source_id BIGINT UNIQUE NOT NULL,
    branch_name TEXT NOT NULL,
    city TEXT NOT NULL,
    region TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.fact_sales (
    sales_key BIGSERIAL PRIMARY KEY,
    source_id BIGINT UNIQUE NOT NULL,
    date_key INT NOT NULL REFERENCES dw.dim_date(date_key),
    customer_key BIGINT NOT NULL REFERENCES dw.dim_customer(customer_key),
    product_key BIGINT NOT NULL REFERENCES dw.dim_product(product_key),
    branch_key BIGINT NOT NULL REFERENCES dw.dim_branch(branch_key),
    qty INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    total_amount NUMERIC(12,2) GENERATED ALWAYS AS (qty * unit_price) STORED
);

CREATE TABLE IF NOT EXISTS dw.etl_log (
    run_ts TIMESTAMPTZ DEFAULT now(),
    status TEXT NOT NULL,
    rows_loaded INT,
    error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_fact_date ON dw.fact_sales(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_branch ON dw.fact_sales(branch_key);
CREATE INDEX IF NOT EXISTS idx_fact_product ON dw.fact_sales(product_key);