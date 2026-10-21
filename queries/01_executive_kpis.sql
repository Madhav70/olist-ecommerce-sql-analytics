-- ==============================================================================
-- Query 01: Executive KPIs & Platform Overview
-- ==============================================================================
-- Business Objective:
-- Provide C-Suite leadership with an end-to-end executive scorecard:
-- platform volume, total revenue (GMV), freight collected, order fulfillment rate,
-- customer base scale, basket size, and average order value (AOV).
-- ==============================================================================

WITH platform_summary AS (
    SELECT 
        -- Total Orders
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END) AS delivered_orders,
        COUNT(DISTINCT CASE WHEN o.order_status = 'canceled' THEN o.order_id END) AS canceled_orders,
        
        -- Delivery SLA Performance
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_status = 'delivered' THEN o.order_id END) / COUNT(DISTINCT o.order_id), 2) AS fulfillment_rate_pct,
        
        -- Customers and Sellers Count
        COUNT(DISTINCT c.customer_unique_id) AS total_unique_customers,
        COUNT(DISTINCT oi.seller_id) AS active_sellers,
        COUNT(DISTINCT oi.product_id) AS unique_products_sold,
        
        -- Volume & Financial Metrics (Delivered Orders Only for Financial Accrual)
        COUNT(oi.order_item_id) AS total_items_sold,
        ROUND(SUM(CASE WHEN o.order_status = 'delivered' THEN oi.price ELSE 0 END), 2) AS total_delivered_gmv,
        ROUND(SUM(CASE WHEN o.order_status = 'delivered' THEN oi.freight_value ELSE 0 END), 2) AS total_delivered_freight,
        ROUND(SUM(CASE WHEN o.order_status = 'delivered' THEN (oi.price + oi.freight_value) ELSE 0 END), 2) AS total_customer_spend,
        
        -- Averages
        ROUND(AVG(CASE WHEN o.order_status = 'delivered' THEN oi.price END), 2) AS avg_item_price,
        ROUND(AVG(CASE WHEN o.order_status = 'delivered' THEN oi.freight_value END), 2) AS avg_item_freight
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
),
reviews_summary AS (
    SELECT 
        ROUND(AVG(review_score), 2) AS avg_platform_review_score,
        COUNT(review_id) AS total_reviews_collected
    FROM order_reviews
)
SELECT 
    ps.total_orders,
    ps.delivered_orders,
    ps.canceled_orders,
    ps.fulfillment_rate_pct,
    ps.total_unique_customers,
    ps.active_sellers,
    ps.unique_products_sold,
    ps.total_items_sold,
    ps.total_delivered_gmv,
    ps.total_delivered_freight,
    ps.total_customer_spend,
    ROUND(ps.total_delivered_gmv / ps.delivered_orders, 2) AS average_order_value_aov,
    ROUND(CAST(ps.total_items_sold AS FLOAT) / ps.delivered_orders, 2) AS items_per_order,
    ROUND(100.0 * ps.total_delivered_freight / ps.total_customer_spend, 2) AS freight_share_of_spend_pct,
    rs.avg_platform_review_score,
    rs.total_reviews_collected
FROM platform_summary ps
CROSS JOIN reviews_summary rs;
