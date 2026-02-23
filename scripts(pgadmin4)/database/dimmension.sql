-- Create the core schema
CREATE SCHEMA IF NOT EXISTS core;

-- ==========================================================
-- 1. DIMENSION: GEOGRAPHY
-- ==========================================================
DROP TABLE IF EXISTS core.dim_geography CASCADE;
CREATE TABLE core.dim_geography (
    zip_code_prefix INTEGER PRIMARY KEY,
    city VARCHAR(100),
    state CHAR(2)
);

-- Load unique zips from all sources
INSERT INTO core.dim_geography (zip_code_prefix, state)
SELECT DISTINCT geolocation_zip_code_prefix, geolocation_state FROM stg_geolocation
ON CONFLICT (zip_code_prefix) DO NOTHING;

INSERT INTO core.dim_geography (zip_code_prefix, state, city)
SELECT DISTINCT customer_zip_code_prefix, customer_state, customer_city FROM stg_customers
ON CONFLICT (zip_code_prefix) DO NOTHING;

INSERT INTO core.dim_geography (zip_code_prefix, state, city)
SELECT DISTINCT seller_zip_code_prefix, seller_state, seller_city FROM stg_sellers
ON CONFLICT (zip_code_prefix) DO NOTHING;

-- ==========================================================
-- 2. DIMENSION: CUSTOMERS
-- ==========================================================
DROP TABLE IF EXISTS core.dim_customers CASCADE;
CREATE TABLE core.dim_customers (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(100) UNIQUE,
    customer_unique_id VARCHAR(100),
    customer_zip_code_prefix INTEGER REFERENCES core.dim_geography(zip_code_prefix),
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

INSERT INTO core.dim_customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT DISTINCT ON (customer_id) customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state
FROM stg_customers;

-- ==========================================================
-- 3. DIMENSION: PRODUCTS
-- ==========================================================
DROP TABLE IF EXISTS core.dim_products CASCADE;
CREATE TABLE core.dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(100) UNIQUE,
    product_category_name_english VARCHAR(100),
    product_department VARCHAR(100),
    product_weight_g NUMERIC,
    product_volume_cm3 NUMERIC
);

INSERT INTO core.dim_products (product_id, product_category_name_english, product_department, product_weight_g, product_volume_cm3)
SELECT DISTINCT ON (product_id) product_id, product_category_name_english, product_department, product_weight_g, product_volume_cm3
FROM stg_products;

-- ==========================================================
-- 4. DIMENSION: SELLERS
-- ==========================================================
DROP TABLE IF EXISTS core.dim_sellers CASCADE;
CREATE TABLE core.dim_sellers (
    seller_key SERIAL PRIMARY KEY,
    seller_id VARCHAR(100) UNIQUE,
    seller_city VARCHAR(100),
    seller_state CHAR(2),
    seller_zip_code_prefix INTEGER REFERENCES core.dim_geography(zip_code_prefix)
);

INSERT INTO core.dim_sellers (seller_id, seller_city, seller_state, seller_zip_code_prefix)
SELECT DISTINCT ON (seller_id) seller_id, seller_city, seller_state, seller_zip_code_prefix
FROM stg_sellers;

-- ==========================================================
-- 5. DIMENSION: DATE
-- ==========================================================
DROP TABLE IF EXISTS core.dim_date CASCADE;
CREATE TABLE core.dim_date (
    date_key DATE PRIMARY KEY,
    day_name VARCHAR(10),
    month_name VARCHAR(10),
    year_actual INTEGER
);

INSERT INTO core.dim_date
SELECT DISTINCT datum AS date_key, TO_CHAR(datum, 'Day'), TO_CHAR(datum, 'Month'), EXTRACT(YEAR FROM datum)
FROM (SELECT generate_series('2016-01-01'::DATE, '2018-12-31'::DATE, '1 day'::interval)::DATE AS datum) d;

-- ==========================================================
-- 6. DIMENSION: REVIEWS (FIXED FOR DUPLICATES)
-- ==========================================================
DROP TABLE IF EXISTS core.dim_reviews CASCADE;
CREATE TABLE core.dim_reviews (
    review_key SERIAL PRIMARY KEY,
    review_id VARCHAR(100) UNIQUE,
    review_score INTEGER,
    sentiment VARCHAR(20),
    sentiment_score NUMERIC,
    keywords_nlp TEXT
);

-- This logic picks only ONE record if a review_id appears twice
INSERT INTO core.dim_reviews (review_id, review_score, sentiment, sentiment_score, keywords_nlp)
SELECT review_id, review_score, sentiment, sentiment_score, keywords_nlp
FROM (
    SELECT review_id, review_score, sentiment, sentiment_score, keywords_nlp,
           ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_score DESC) as rn
    FROM stg_order_reviews
) t
WHERE rn = 1;
-- ==========================================================
-- 7. DIMENSION: PAYMENTS (Fixing the "Empty" issue)
-- ==========================================================
DROP TABLE IF EXISTS core.dim_payments CASCADE;
CREATE TABLE core.dim_payments (
    payment_key SERIAL PRIMARY KEY,
    payment_segment VARCHAR(50),
    installment_segment VARCHAR(50),
    payment_type_short VARCHAR(10)
);

-- Insert unique combinations only. 
-- We use COALESCE to ensure 'null' values don't break the join later.
INSERT INTO core.dim_payments (payment_segment, installment_segment, payment_type_short)
SELECT DISTINCT 
    COALESCE(payment_segment, 'Unknown'), 
    COALESCE(installment_segment, 'Unknown'), 
    COALESCE(payment_type_short, 'Unknown')
FROM stg_order_payments;

-- ==========================================================
-- 8. DIMENSION: ORDER STATUS (Fixing the "Order" part)
-- ==========================================================
DROP TABLE IF EXISTS core.dim_order_status CASCADE;
CREATE TABLE core.dim_order_status (
    order_status_key SERIAL PRIMARY KEY,
    order_status VARCHAR(50),
    delivery_behavior VARCHAR(50)
);

INSERT INTO core.dim_order_status (order_status, delivery_behavior)
SELECT DISTINCT 
    COALESCE(order_status, 'Unknown'), 
    COALESCE(delivery_behavior, 'Standard')
FROM stg_orders;

-- ==========================================================
-- 9. RE-BUILDING FACT_ORDERS (The "Black Lines" connector)
-- ==========================================================
DROP TABLE IF EXISTS core.fact_orders CASCADE;
CREATE TABLE core.fact_orders (
    fact_key SERIAL PRIMARY KEY,
    order_id VARCHAR(100),
    customer_key INTEGER REFERENCES core.dim_customers(customer_key),
    product_key INTEGER REFERENCES core.dim_products(product_key),
    payment_key INTEGER REFERENCES core.dim_payments(payment_key),
    order_status_key INTEGER REFERENCES core.dim_order_status(order_status_key),
    date_key DATE REFERENCES core.dim_date(date_key),
    price NUMERIC,
    payment_value NUMERIC,
    is_late BOOLEAN
);

INSERT INTO core.fact_orders (
    order_id, customer_key, product_key, payment_key, 
    order_status_key, date_key, price, payment_value, is_late
)
SELECT 
    oi.order_id,
    c.customer_key,
    p.product_key,
    pay_dim.payment_key,
    stat_dim.order_status_key,
    o.order_purchase_timestamp::DATE,
    oi.price,
    pay_sum.total_payment_value,
    o.is_late
FROM stg_order_items oi
JOIN stg_orders o ON oi.order_id = o.order_id
-- Connect to Dimensions
LEFT JOIN core.dim_customers c ON o.customer_id = c.customer_id
LEFT JOIN core.dim_products p ON oi.product_id = p.product_id
-- Join to Status
LEFT JOIN core.dim_order_status stat_dim 
    ON COALESCE(o.order_status, 'Unknown') = stat_dim.order_status 
    AND COALESCE(o.delivery_behavior, 'Standard') = stat_dim.delivery_behavior
-- Join to Payments (Summarized so we don't duplicate rows)
LEFT JOIN (
    SELECT 
        order_id, 
        SUM(payment_value) as total_payment_value,
        MAX(payment_segment) as p_seg, 
        MAX(installment_segment) as i_seg, 
        MAX(payment_type_short) as p_type
    FROM stg_order_payments
    GROUP BY order_id
) pay_sum ON oi.order_id = pay_sum.order_id
LEFT JOIN core.dim_payments pay_dim 
    ON pay_sum.p_seg = pay_dim.payment_segment 
    AND pay_sum.i_seg = pay_dim.installment_segment 
    AND pay_sum.p_type = pay_dim.payment_type_short;

-- VERIFICATION:
SELECT 'Payments' as table, count(*) FROM core.dim_payments
UNION ALL
SELECT 'Fact Orders', count(*) FROM core.fact_orders;