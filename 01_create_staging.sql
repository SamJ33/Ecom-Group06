-- 1. Staging for Products
CREATE TABLE stg_products (
    product_id VARCHAR(100) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght NUMERIC,
    product_description_lenght NUMERIC,
    product_photos_qty NUMERIC,
    product_weight_g NUMERIC,
    product_volume_cm3 NUMERIC,
    product_density_g_cm3 NUMERIC,
    product_category_name_english VARCHAR(100),
    product_department VARCHAR(100)  
);

-- 2. Staging for Sellers
CREATE TABLE stg_sellers (
    seller_id VARCHAR(100) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- 3. Staging for Order Items 
-- This is the "bridge" between Products, Sellers, and Orders
CREATE TABLE stg_order_items (
    order_id VARCHAR(100),
    order_item_id INT,
    product_id VARCHAR(100), -- Connects to stg_products
    seller_id VARCHAR(100),  -- Connects to stg_sellers
    price NUMERIC,
    freight_value NUMERIC,
    total_price NUMERIC,     -- Calculated feature
    PRIMARY KEY (order_id, order_item_id)
);

-- 4. Staging for Geolocation
-- Connects to Sellers via zip_code_prefix
CREATE TABLE stg_geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_state CHAR(2)
);-- 4. Staging for Geolocation
-- Connects to Sellers via zip_code_prefix
CREATE TABLE stg_geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_state CHAR(2)
);-- 3. Staging for Order Items 
-- This is the "bridge" between Products, Sellers, and Orders
CREATE TABLE stg_order_items (
    order_id VARCHAR(100),
    order_item_id INT,
    product_id VARCHAR(100), -- Connects to stg_products
    seller_id VARCHAR(100),  -- Connects to stg_sellers
    price NUMERIC,
    freight_value NUMERIC,
    total_price NUMERIC,     -- Calculated feature
    PRIMARY KEY (order_id, order_item_id)
);


-- 5. Staging for Orders
CREATE TABLE stg_orders (
    order_id VARCHAR(100) PRIMARY KEY,
    customer_id VARCHAR(100),
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    delivery_behavior VARCHAR(50),
    delivery_days INT,
    shipping_days INT,
    processing_days INT,
    order_estimated_delivery_date TIMESTAMP,
    is_late BOOLEAN
);

-- 6. Staging for Order Revenue/Payments
-- Note: We don't use PRIMARY KEY here because one order can have multiple payment rows
CREATE TABLE stg_order_revenue (
    order_id VARCHAR(100),
    payment_value NUMERIC,
    payment_segment VARCHAR(50),
    installment_segment VARCHAR(50),
    payment_type_short VARCHAR(10)
);


-- 7. Staging for Customers
CREATE TABLE stg_customers (
    customer_id VARCHAR(100) PRIMARY KEY,
    customer_unique_id VARCHAR(100),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- 8. Staging for Order Reviews
DROP TABLE IF EXISTS stg_order_reviews;

CREATE TABLE stg_order_reviews (
    review_id                VARCHAR(100),
    order_id                 VARCHAR(100),
    review_score             INT,
    review_comment_title     TEXT,
    review_comment_message   TEXT,
    text_for_nlp             TEXT,
    sentiment                VARCHAR(20),
    sentiment_score          NUMERIC,
    keywords_nlp             TEXT
);