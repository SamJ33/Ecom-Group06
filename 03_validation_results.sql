-- ==========================================================
-- 03_validation_results.sql
-- SQL Analytics Modeling - Validation Queries
-- ==========================================================

-- VALIDATION 1: Total Revenue Match (order level)
SELECT 
    (SELECT SUM(total_revenue) 
     FROM (SELECT DISTINCT order_id, total_revenue FROM fact_orders) d
    )                                                      AS fact_total_revenue,
    (SELECT SUM(payment_value) FROM stg_order_revenue)    AS staging_total_revenue;

-- VALIDATION 2: Order Count Consistency
SELECT
    (SELECT COUNT(DISTINCT order_id) FROM stg_orders)     AS staging_order_count,
    (SELECT COUNT(DISTINCT order_id) FROM fact_orders)    AS fact_order_count;

-- VALIDATION 3: No Duplicate Primary Keys (expect 0 rows)
SELECT order_id, order_item_id, COUNT(*) AS duplicate_count
FROM fact_orders
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- VALIDATION 4: Referential Integrity - All Foreign Keys
SELECT 
    COUNT(CASE WHEN c.customer_id      IS NULL THEN 1 END) AS orphaned_customers,
    COUNT(CASE WHEN p.product_id       IS NULL THEN 1 END) AS orphaned_products,
    COUNT(CASE WHEN d.date_key         IS NULL THEN 1 END) AS orphaned_dates,
    COUNT(CASE WHEN s.seller_id        IS NULL THEN 1 END) AS orphaned_sellers,
    COUNT(CASE WHEN pt.payment_type_id IS NULL THEN 1 END) AS orphaned_payment_types,
    COUNT(CASE WHEN os.order_status    IS NULL THEN 1 END) AS orphaned_order_statuses
FROM fact_orders f
LEFT JOIN dim_customers    c  ON f.customer_id       = c.customer_id
LEFT JOIN dim_products     p  ON f.product_id        = p.product_id
LEFT JOIN dim_date         d  ON f.date_key          = d.date_key
LEFT JOIN dim_sellers      s  ON f.seller_id         = s.seller_id
LEFT JOIN dim_payment_type pt ON f.payment_type_short = pt.payment_type_id
LEFT JOIN dim_order_status os ON f.order_status      = os.order_status;

-- VALIDATION 5: Geolocation Coverage
SELECT
    (SELECT COUNT(*) FROM dim_customers 
     WHERE customer_zip_code_prefix NOT IN 
     (SELECT geolocation_zip_code_prefix FROM dim_geolocation)) AS customers_missing_geo,
    (SELECT COUNT(*) FROM dim_sellers 
     WHERE seller_zip_code_prefix NOT IN 
     (SELECT geolocation_zip_code_prefix FROM dim_geolocation))  AS sellers_missing_geo;

-- VALIDATION 6: Revenue Non-Negativity (expect 0)
SELECT COUNT(*) AS negative_revenue_count
FROM fact_orders
WHERE total_revenue < 0 OR price < 0 OR freight_value < 0;

-- VALIDATION 7: Delivery Consistency (expect 0)
SELECT COUNT(*) AS invalid_delivery_days
FROM fact_orders
WHERE delivery_days < 0;

-- VALIDATION 8: Null Primary Keys (expect all 0s)
SELECT
    COUNT(CASE WHEN order_id    IS NULL THEN 1 END) AS null_order_ids,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS null_customer_ids,
    COUNT(CASE WHEN product_id  IS NULL THEN 1 END) AS null_product_ids
FROM fact_orders;

-- VALIDATION 9: Review Sentiment Distribution (data quality check)
SELECT sentiment, COUNT(*) AS count, ROUND(AVG(sentiment_score)::NUMERIC, 3) AS avg_score
FROM dim_reviews
GROUP BY sentiment
ORDER BY count DESC;