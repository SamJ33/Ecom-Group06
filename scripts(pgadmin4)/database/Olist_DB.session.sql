-- Create a schema to keep things organized
CREATE SCHEMA IF NOT EXISTS staging;

-- 1. Customers
CREATE TABLE stg_customers (
    customer_id VARCHAR(100) PRIMARY KEY,
    customer_unique_id VARCHAR(100),
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- 2. Geolocation
CREATE TABLE stg_geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_state CHAR(2)
);

-- 3. Sellers
CREATE TABLE stg_sellers (
    seller_id VARCHAR(100) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- 4. Order Items
CREATE TABLE stg_order_items (
    order_id VARCHAR(100),
    order_item_id INTEGER,
    product_id VARCHAR(100),
    seller_id VARCHAR(100),
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    total_price DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);
-- 5 .Product 
CREATE TABLE stg_products (
    product_id VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100),
    product_volume_cm3 NUMERIC,
    product_density_g_cm3 NUMERIC,
    product_department VARCHAR(100),
    product_photos_qty NUMERIC,
    product_weight_g NUMERIC,

    
);
