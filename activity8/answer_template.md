# Activity 8 Answer Template

## Part 1: Star Schema Design

### 1. Fact Table Grain

- One row per sales transaction per product per branch per day

### 2. Fact Measures

- Quantity (qty): The number of units sold.
- Unit Price (unit_price): The price per unit at the time of sale.
- Total Amount (total_amount): A calculated measure ($qty \times unit\_price$).
### 3. Dimension Tables and Attributes

- `dim_date`: (date_key (PK), date, year, quarter, month, day_of_week)
- `dim_customer`: (customer_key (PK), source_id (customer_id), full_name, region_code)
- `dim_product`: (product_key (PK), source_id (product_id), product_name, category, unit_price)
- `dim_branch`: (branch_key (PK), source_id (branch_id), branch_name, city, region)

### 4. Relationship Summary

- fact_sales.date_key → dim_date.date_key
- fact_sales.customer_key → dim_customer.customer_key
- fact_sales.product_key → dim_product.product_key
- fact_sales.branch_key → dim_branch.branch_key


## Part 2: Warehouse DDL

```sql
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
```

## Part 3: ETL Procedure

### 1. Procedure Code

```sql
CREATE OR REPLACE PROCEDURE dw.run_sales_etl()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_loaded INT := 0;
BEGIN
    INSERT INTO dw.dim_date (date_key, date, year, quarter, month, day_of_week)
    SELECT DISTINCT
        TO_CHAR(s.txn_date, 'YYYYMMDD')::INT AS date_key,
        s.txn_date::DATE,
        EXTRACT(YEAR FROM s.txn_date)::INT,
        EXTRACT(QUARTER FROM s.txn_date)::INT,
        EXTRACT(MONTH FROM s.txn_date)::INT,
        EXTRACT(DOW FROM s.txn_date)::INT
    FROM public.sales_txn s
    WHERE s.txn_date IS NOT NULL
    ON CONFLICT (date) DO NOTHING;

    INSERT INTO dw.dim_customer (source_id, full_name, region_code)
    SELECT c.id, c.full_name, c.region_code
    FROM public.customers c
    ON CONFLICT (source_id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        region_code = EXCLUDED.region_code;

    INSERT INTO dw.dim_product (source_id, product_name, category, unit_price)
    SELECT p.id, p.product_name, p.category, p.unit_price
    FROM public.products p
    ON CONFLICT (source_id) DO UPDATE
    SET product_name = EXCLUDED.product_name,
        category = EXCLUDED.category,
        unit_price = EXCLUDED.unit_price;

    INSERT INTO dw.dim_branch (source_id, branch_name, city, region)
    SELECT b.id, b.branch_name, b.city, b.region
    FROM public.branches b
    ON CONFLICT (source_id) DO UPDATE
    SET branch_name = EXCLUDED.branch_name,
        city = EXCLUDED.city,
        region = EXCLUDED.region;

    INSERT INTO dw.fact_sales (
        source_id,
        date_key,
        customer_key,
        product_key,
        branch_key,
        qty,
        unit_price
    )
    SELECT
        s.id AS source_id,
        dd.date_key,
        dc.customer_key,
        dp.product_key,
        db.branch_key,
        s.qty,
        s.unit_price
    FROM public.sales_txn s
    JOIN dw.dim_date dd ON dd.date = s.txn_date::DATE
    JOIN dw.dim_customer dc ON dc.source_id = s.customer_id
    JOIN dw.dim_product dp ON dp.source_id = s.product_id
    JOIN dw.dim_branch db ON db.source_id = s.branch_id
    WHERE s.qty > 0
      AND s.unit_price > 0
      AND NOT EXISTS (
          SELECT 1
          FROM dw.fact_sales f
          WHERE f.source_id = s.id
      );

    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    INSERT INTO dw.etl_log (status, rows_loaded, error_message)
    VALUES ('SUCCESS', v_rows_loaded, NULL);

EXCEPTION WHEN OTHERS THEN
    INSERT INTO dw.etl_log (status, rows_loaded, error_message)
    VALUES ('FAIL', NULL, SQLERRM);

END;
$$;
```

### 2. Procedure Execution

```sql
CALL dw.run_sales_etl();
```

### 3. ETL Log Output

```sql
SELECT * FROM dw.etl_log ORDER BY run_ts DESC;
```

```txt
coffee_db=# SELECT * FROM dw.etl_log ORDER BY run_ts DESC;
            run_ts             | status  | rows_loaded | error_message
-------------------------------+---------+-------------+---------------
 2026-03-11 08:28:37.743372+08 | SUCCESS |      100000 |
(1 row)
```

## Part 4: Analytical Queries

### Query 1: Monthly Revenue by Branch Region

```sql
SELECT
    d.year,
    d.month,
    b.region,
    SUM(f.total_amount) AS total_revenue
FROM dw.fact_sales f
JOIN dw.dim_date d ON f.date_key = d.date_key
JOIN dw.dim_branch b ON f.branch_key = b.branch_key
GROUP BY d.year, d.month, b.region
ORDER BY d.year, d.month;
```

Interpretation:
- The total revenue per month for each branch region shows that some regions consistently generate higher sales than others. This pattern suggests that certain regions are strong performers, while others experience fluctuations in revenue. Based on this, the business can focus marketing strategies and resource allocation on high-performing regions, and investigate ways to improve sales in lower-performing regions.
### Query 2: Top 5 Products by Total Revenue

```sql
SELECT
    p.product_name,
    SUM(f.total_amount) AS total_revenue
FROM dw.fact_sales f
JOIN dw.dim_product p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;
```

Interpretation:

- This query identifies the top five products that generate the highest total revenue, indicating clear customer preferences for these items. This pattern shows that a few products dominate the revenue stream. Consequently, the business can increase stock levels, plan promotions, or create bundles for these top products to maximize overall revenue.

### Query 3: Customer Region Contribution to Sales

```sql
SELECT
    c.region_code,
    SUM(f.total_amount) AS total_sales
FROM dw.fact_sales f
JOIN dw.dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.region_code
ORDER BY total_sales DESC;
```

Interpretation:

- This query shows how much each customer region contributes to overall sales, helping analyze regional market demand.