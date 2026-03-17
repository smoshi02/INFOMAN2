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