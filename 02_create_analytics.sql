-- ==========================================================
-- 1. CLEANUP (Drop in order of dependency)
-- ==========================================================
DROP TABLE IF EXISTS dim_reviews CASCADE;
DROP TABLE IF EXISTS fact_orders CASCADE;
DROP TABLE IF EXISTS dim_customers CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS dim_sellers CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_geolocation CASCADE;
DROP TABLE IF EXISTS dim_payment_type CASCADE;
DROP TABLE IF EXISTS dim_order_status CASCADE;

-- ==========================================================
-- 2. UNIVERSAL GEOLOCATION (The Fix for FK Violations)
-- ==========================================================
CREATE TABLE dim_geolocation AS
SELECT 
    zip_code_prefix AS geolocation_zip_code_prefix,
    MAX(state_name) AS geolocation_state
FROM (
    -- Take existing geo data
    SELECT geolocation_zip_code_prefix AS zip_code_prefix, geolocation_state AS state_name FROM stg_geolocation
    UNION ALL
    -- Add missing zip codes from customers
    SELECT customer_zip_code_prefix, customer_state FROM stg_customers
    UNION ALL
    -- Add missing zip codes from sellers
    SELECT seller_zip_code_prefix, seller_state FROM stg_sellers
) AS master_zip_list
WHERE zip_code_prefix IS NOT NULL
GROUP BY zip_code_prefix;

ALTER TABLE dim_geolocation ADD PRIMARY KEY (geolocation_zip_code_prefix);

-- ==========================================================
-- 3. DIMENSION TABLES (With New Features)
-- ==========================================================

-- dim_customers (Old structure + Keys)
CREATE TABLE dim_customers AS
SELECT customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state 
FROM stg_customers;
ALTER TABLE dim_customers ADD PRIMARY KEY (customer_id);

-- dim_products (New Columns: Weight, Volume, Density, etc.)
CREATE TABLE dim_products AS
SELECT 
    product_id, product_category_name_english AS category_name_english, category_name_portuguese,
    product_department, product_weight_g, product_volume_cm3, product_density_g_cm3,
    product_photos_qty, product_name_lenght, product_description_lenght
FROM stg_products;
ALTER TABLE dim_products ADD PRIMARY KEY (product_id);

-- dim_sellers
CREATE TABLE dim_sellers AS
SELECT seller_id, seller_zip_code_prefix, seller_city, seller_state 
FROM stg_sellers;
ALTER TABLE dim_sellers ADD PRIMARY KEY (seller_id);

-- dim_date
CREATE TABLE dim_date AS
SELECT DISTINCT
    order_purchase_timestamp::DATE AS date_key,
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    EXTRACT(QUARTER FROM order_purchase_timestamp) AS quarter,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
    TO_CHAR(order_purchase_timestamp, 'Month') AS month_name,
    TO_CHAR(order_purchase_timestamp, 'Day') AS day_name,
    EXTRACT(WEEK FROM order_purchase_timestamp) AS week_number
FROM stg_orders WHERE order_purchase_timestamp IS NOT NULL;
ALTER TABLE dim_date ADD PRIMARY KEY (date_key);

-- dim_payment_type (New Columns: Segments)
CREATE TABLE dim_payment_type AS
SELECT payment_type_short AS payment_type_id, MAX(payment_segment) AS payment_segment, MAX(installment_segment) AS installment_segment
FROM stg_order_revenue WHERE payment_type_short IS NOT NULL GROUP BY payment_type_short;
ALTER TABLE dim_payment_type ADD PRIMARY KEY (payment_type_id);

-- dim_order_status (New Column: Delivery Behavior)
CREATE TABLE dim_order_status AS
SELECT order_status, MAX(delivery_behavior) AS delivery_behavior 
FROM stg_orders WHERE order_status IS NOT NULL GROUP BY order_status;
ALTER TABLE dim_order_status ADD PRIMARY KEY (order_status);

-- dim_reviews (New Columns: Sentiment, NLP Keywords)
CREATE TABLE dim_reviews AS
SELECT DISTINCT ON (review_id) review_id, order_id, review_score, sentiment, sentiment_score, keywords_nlp
FROM stg_order_reviews ORDER BY review_id;
ALTER TABLE dim_reviews ADD PRIMARY KEY (review_id);

-- ==========================================================
-- 4. FACT TABLE (The Heart of the Model)
-- ==========================================================
CREATE TABLE fact_orders AS
SELECT 
    oi.order_id, oi.order_item_id,
    o.customer_id, oi.product_id, oi.seller_id,
    o.order_purchase_timestamp::DATE AS date_key,
    o.order_status, rev.payment_type_short,
    oi.price, oi.freight_value,
    COALESCE(rev.total_revenue, 0) AS total_revenue,
    (oi.price + oi.freight_value) AS gross_order_value,
    -- New Delivery Metrics
    o.delivery_days, o.shipping_days, o.processing_days, o.delivery_behavior, o.is_late,
    o.order_estimated_delivery_date::DATE AS estimated_delivery_date,
    o.order_delivered_customer_date::DATE AS actual_delivery_date
FROM stg_order_items oi
JOIN stg_orders o ON oi.order_id = o.order_id
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS total_revenue, MAX(payment_type_short) AS payment_type_short
    FROM stg_order_revenue GROUP BY order_id
) rev ON oi.order_id = rev.order_id;

ALTER TABLE fact_orders ADD PRIMARY KEY (order_id, order_item_id);

-- ==========================================================
-- 5. THE BRIDGE (Applying Constraints)
-- ==========================================================
ALTER TABLE fact_orders ADD CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id);
ALTER TABLE fact_orders ADD CONSTRAINT fk_product  FOREIGN KEY (product_id) REFERENCES dim_products(product_id);
ALTER TABLE fact_orders ADD CONSTRAINT fk_date     FOREIGN KEY (date_key) REFERENCES dim_date(date_key);
ALTER TABLE fact_orders ADD CONSTRAINT fk_seller   FOREIGN KEY (seller_id) REFERENCES dim_sellers(seller_id);
ALTER TABLE fact_orders ADD CONSTRAINT fk_pay_type FOREIGN KEY (payment_type_short) REFERENCES dim_payment_type(payment_type_id);
ALTER TABLE fact_orders ADD CONSTRAINT fk_status   FOREIGN KEY (order_status) REFERENCES dim_order_status(order_status);

ALTER TABLE dim_customers ADD CONSTRAINT fk_geolocation FOREIGN KEY (customer_zip_code_prefix) REFERENCES dim_geolocation(geolocation_zip_code_prefix);



-- Add a column to the fact table for the review link
ALTER TABLE fact_orders ADD COLUMN review_id VARCHAR(100);

-- Update the fact table to pull in the review IDs
UPDATE fact_orders f
SET review_id = r.review_id
FROM dim_reviews r
WHERE f.order_id = r.order_id;
ALTER TABLE fact_orders
    ADD CONSTRAINT fk_review
    FOREIGN KEY (review_id) REFERENCES dim_reviews(review_id);





    ALTER TABLE dim_sellers
    ADD CONSTRAINT fk_seller_geolocation
    FOREIGN KEY (seller_zip_code_prefix) REFERENCES dim_geolocation(geolocation_zip_code_prefix);