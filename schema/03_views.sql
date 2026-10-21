-- ==============================================================================
-- Olist Brazilian E-Commerce Database Reporting Views
-- ==============================================================================
-- Description: Standardized business views providing denormalized, ready-to-query
-- datasets for analytics, reporting dashboards, and ad-hoc queries.
-- ==============================================================================

-- 1. Deduplicated Geolocation Lookup View
-- Calculates the centroid (average lat/lng) for each zip code prefix.
DROP VIEW IF EXISTS vw_zip_code_geolocation;
CREATE VIEW vw_zip_code_geolocation AS
SELECT 
    geolocation_zip_code_prefix AS zip_code_prefix,
    ROUND(AVG(geolocation_lat), 6) AS avg_latitude,
    ROUND(AVG(geolocation_lng), 6) AS avg_longitude,
    MIN(geolocation_city) AS city,
    MIN(geolocation_state) AS state
FROM geolocation
GROUP BY geolocation_zip_code_prefix;

-- 2. Master Order Summary View
-- Denormalizes order details, customer demographics, financial totals, 
-- fulfillment timestamps, and delivery SLA performance.
DROP VIEW IF EXISTS vw_order_master;
CREATE VIEW vw_order_master AS
WITH items_agg AS (
    SELECT 
        order_id,
        COUNT(order_item_id) AS total_items,
        COUNT(DISTINCT product_id) AS unique_products,
        COUNT(DISTINCT seller_id) AS unique_sellers,
        ROUND(SUM(price), 2) AS total_item_value,
        ROUND(SUM(freight_value), 2) AS total_freight_value,
        ROUND(SUM(price + freight_value), 2) AS total_order_value
    FROM order_items
    GROUP BY order_id
),
payments_agg AS (
    SELECT 
        order_id,
        ROUND(SUM(payment_value), 2) AS total_payment_value,
        MAX(payment_installments) AS max_installments,
        GROUP_CONCAT(DISTINCT payment_type) AS payment_methods_used
    FROM order_payments
    GROUP BY order_id
),
reviews_agg AS (
    SELECT 
        order_id,
        ROUND(AVG(review_score), 2) AS avg_review_score,
        COUNT(review_id) AS total_reviews
    FROM order_reviews
    GROUP BY order_id
)
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- Delivery latency in fractional days (delivered - purchased)
    ROUND(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp), 2) AS delivery_days,
    -- Carrier transit time in fractional days (delivered - handed to carrier)
    ROUND(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_delivered_carrier_date), 2) AS carrier_transit_days,
    -- Delivery SLA status: 1 if delayed past estimated delivery date, else 0
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
        WHEN o.order_delivered_customer_date IS NOT NULL THEN 0
        ELSE NULL
    END AS is_delivery_delayed,

    COALESCE(i.total_items, 0) AS total_items,
    COALESCE(i.unique_products, 0) AS unique_products,
    COALESCE(i.unique_sellers, 0) AS unique_sellers,
    COALESCE(i.total_item_value, 0.0) AS merchandise_revenue,
    COALESCE(i.total_freight_value, 0.0) AS freight_revenue,
    COALESCE(p.total_payment_value, i.total_order_value, 0.0) AS total_order_spend,
    p.payment_methods_used,
    p.max_installments,
    r.avg_review_score,
    r.total_reviews
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN items_agg i ON o.order_id = i.order_id
LEFT JOIN payments_agg p ON o.order_id = p.order_id
LEFT JOIN reviews_agg r ON o.order_id = r.order_id;

-- 3. Customer RFM Foundation View
-- Aggregates customer behavioral metrics for RFM segmentation.
DROP VIEW IF EXISTS vw_customer_rfm_raw;
CREATE VIEW vw_customer_rfm_raw AS
SELECT 
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_merchandise_spend,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_order_spend,
    MIN(o.order_purchase_timestamp) AS first_purchase_date,
    MAX(o.order_purchase_timestamp) AS last_purchase_date,
    -- Recency: Days from the dataset snapshot cutoff (2018-10-18) to customer's last order
    ROUND(JULIANDAY('2018-10-18') - JULIANDAY(MAX(o.order_purchase_timestamp)), 1) AS recency_days
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id, c.customer_state, c.customer_city;

-- 4. Product Category Performance View
-- Aggregates category performance with English translations.
DROP VIEW IF EXISTS vw_product_category_summary;
CREATE VIEW vw_product_category_summary AS
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_unit_price,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    ROUND(AVG(oi.freight_value), 2) AS avg_unit_freight,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
LEFT JOIN order_reviews r ON oi.order_id = r.order_id
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown');

-- 5. Seller Scorecard View
-- Aggregates seller sales performance, fulfillment speed, and satisfaction.
DROP VIEW IF EXISTS vw_seller_scorecard;
CREATE VIEW vw_seller_scorecard AS
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(o.order_id), 2) AS late_delivery_rate_pct,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state;
