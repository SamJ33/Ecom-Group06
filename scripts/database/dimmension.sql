-- 1. custumer
CREATE TABLE dim_customers (
    customer_key SERIAL PRIMARY KEY, -- Unique key for the star schema
    customer_id VARCHAR(100) UNIQUE,
    customer_unique_id VARCHAR(100),
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

INSERT INTO dim_customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state
FROM staging.stg_customers;
-- 2. product 
CREATE TABLE dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(100) UNIQUE,
    product_category_name_english VARCHAR(100),
    product_department VARCHAR(100),
    product_weight_g NUMERIC,
    product_volume_cm3 NUMERIC
);

INSERT INTO dim_products (product_id, product_category_name_english, product_department, product_weight_g, product_volume_cm3)
SELECT product_id, product_category_name_english, product_department, product_weight_g, product_volume_cm3
FROM staging.stg_products;

--3.order
CREATE TABLE dim_date (
    date_key DATE PRIMARY KEY,
    day_of_week INTEGER,
    day_name VARCHAR(10),
    month_actual INTEGER,
    month_name VARCHAR(10),
    quarter_actual INTEGER,
    year_actual INTEGER
);

-- Clear the table first
TRUNCATE TABLE dim_date;

-- Now run the insert again
INSERT INTO dim_date
SELECT 
    datum AS date_key,
    EXTRACT(DOW FROM datum) AS day_of_week,
    TO_CHAR(datum, 'Day') AS day_name,
    EXTRACT(MONTH FROM datum) AS month_actual,
    TO_CHAR(datum, 'Month') AS month_name,
    EXTRACT(QUARTER FROM datum) AS quarter_actual,
    EXTRACT(YEAR FROM datum) AS year_actual
FROM (
    SELECT generate_series(
        '2016-01-01'::DATE, 
        '2018-12-31'::DATE, 
        '1 day'::interval
    )::DATE AS datum
) d;
SELECT * FROM dim_date ORDER BY date_key LIMIT 10;

-- 4. sellers
CREATE TABLE dim_sellers (
    seller_key SERIAL PRIMARY KEY,
    seller_id VARCHAR(100) UNIQUE,
    seller_city VARCHAR(100),
    seller_state CHAR(2),
    seller_zip_code_prefix INTEGER
);

INSERT INTO dim_sellers (seller_id, seller_city, seller_state, seller_zip_code_prefix)
SELECT seller_id, seller_city, seller_state, seller_zip_code_prefix
FROM stg_sellers;

-- 5.geolocation 
CREATE TABLE dim_geography (
    geo_key SERIAL PRIMARY KEY,
    zip_code_prefix INTEGER UNIQUE,
    city VARCHAR(100),
    state CHAR(2)
);

INSERT INTO dim_geography (zip_code_prefix, state)
SELECT DISTINCT geolocation_zip_code_prefix,geolocation_state
FROM stg_geolocation
ON CONFLICT (zip_code_prefix) DO NOTHING;