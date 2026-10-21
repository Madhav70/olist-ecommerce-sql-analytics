-- ==============================================================================
-- Query 05: Logistics, Fulfillment Speeds & Delivery SLA Performance
-- ==============================================================================
-- Business Objective:
-- 1. Measure on-time delivery SLA compliance against promised delivery dates.
-- 2. Decompose delivery cycle time into:
--      a) Seller processing delay (purchase -> carrier handover)
--      b) Carrier transit delay (carrier handover -> customer receipt)
-- 3. Identify regional delivery bottlenecks across Brazilian states.
-- ==============================================================================

-- Part A: Overall Delivery SLA Performance & Fulfillment Breakdown
WITH delivery_times AS (
    SELECT 
        order_id,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        -- Total delivery cycle (purchase to delivery) in days
        (JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_purchase_timestamp)) AS total_delivery_days,
        -- Seller processing time (purchase to carrier handover) in days
        (JULIANDAY(order_delivered_carrier_date) - JULIANDAY(order_purchase_timestamp)) AS seller_dispatch_days,
        -- Carrier transit time (carrier handover to delivery) in days
        (JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_delivered_carrier_date)) AS carrier_transit_days,
        -- Promised SLA window in days
        (JULIANDAY(order_estimated_delivery_date) - JULIANDAY(order_purchase_timestamp)) AS estimated_sla_days,
        -- Delivery buffer (positive = delivered early, negative = delivered late)
        (JULIANDAY(order_estimated_delivery_date) - JULIANDAY(order_delivered_customer_date)) AS sla_margin_days,
        CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Delayed (Late SLA)'
            ELSE 'On-Time (Met SLA)'
        END AS sla_status
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_delivered_carrier_date IS NOT NULL
)
SELECT 
    COUNT(*) AS total_delivered_orders,
    SUM(CASE WHEN sla_status = 'On-Time (Met SLA)' THEN 1 ELSE 0 END) AS on_time_orders,
    SUM(CASE WHEN sla_status = 'Delayed (Late SLA)' THEN 1 ELSE 0 END) AS late_orders,
    ROUND(100.0 * SUM(CASE WHEN sla_status = 'On-Time (Met SLA)' THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_sla_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN sla_status = 'Delayed (Late SLA)' THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_delivery_rate_pct,
    ROUND(AVG(total_delivery_days), 1) AS avg_actual_delivery_days,
    ROUND(AVG(estimated_sla_days), 1) AS avg_estimated_sla_days,
    ROUND(AVG(seller_dispatch_days), 1) AS avg_seller_dispatch_days,
    ROUND(AVG(carrier_transit_days), 1) AS avg_carrier_transit_days,
    ROUND(AVG(sla_margin_days), 1) AS avg_days_delivered_early
FROM delivery_times;

-- Part B: Delivery Performance & SLA Compliance by Customer State
SELECT 
    c.customer_state,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_actual_delivery_days,
    ROUND(AVG(JULIANDAY(o.order_estimated_delivery_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_estimated_delivery_days,
    ROUND(AVG(JULIANDAY(o.order_estimated_delivery_date) - JULIANDAY(o.order_delivered_customer_date)), 1) AS avg_days_early,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS delayed_orders,
    ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(o.order_id), 2) AS late_rate_pct,
    ROUND(AVG(r.review_score), 2) AS avg_customer_review_score
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_rate_pct DESC;
