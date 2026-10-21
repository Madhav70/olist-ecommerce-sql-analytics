-- ==============================================================================
-- Query 03: Sales Growth, Seasonality & Peak Purchasing Patterns
-- ==============================================================================
-- Business Objective:
-- 1. Track monthly revenue trends and Month-over-Month (MoM) growth rates using LAG().
-- 2. Identify peak buying times by Day of Week and Hour of Day.
-- 3. Analyze the Black Friday 2017 sales surge and its operational impact.
-- ==============================================================================

-- Part A: Monthly GMV Trends & MoM Growth Analysis
WITH monthly_metrics AS (
    SELECT 
        STRFTIME('%Y-%m', o.order_purchase_timestamp) AS order_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(oi.order_item_id) AS total_items_sold,
        ROUND(SUM(oi.price), 2) AS monthly_gmv,
        ROUND(SUM(oi.freight_value), 2) AS monthly_freight,
        ROUND(AVG(oi.price), 2) AS avg_item_price,
        ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value_aov
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
    GROUP BY STRFTIME('%Y-%m', o.order_purchase_timestamp)
),
mom_growth AS (
    SELECT 
        order_month,
        total_orders,
        total_items_sold,
        monthly_gmv,
        monthly_freight,
        avg_order_value_aov,
        LAG(monthly_gmv, 1) OVER (ORDER BY order_month) AS prev_month_gmv,
        LAG(total_orders, 1) OVER (ORDER BY order_month) AS prev_month_orders
    FROM monthly_metrics
)
SELECT 
    order_month,
    total_orders,
    monthly_gmv,
    monthly_freight,
    avg_order_value_aov,
    prev_month_gmv,
    ROUND(100.0 * (monthly_gmv - prev_month_gmv) / prev_month_gmv, 2) AS mom_gmv_growth_pct,
    ROUND(100.0 * (total_orders - prev_month_orders) / prev_month_orders, 2) AS mom_order_growth_pct
FROM mom_growth
ORDER BY order_month;

-- Part B: Day of Week & Hour of Day Purchase Patterns
SELECT 
    CASE CAST(STRFTIME('%w', o.order_purchase_timestamp) AS INTEGER)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_of_week,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(100.0 * COUNT(DISTINCT o.order_id) / (SELECT COUNT(*) FROM orders WHERE order_status = 'delivered'), 2) AS pct_of_total_orders,
    ROUND(SUM(oi.price), 2) AS total_gmv,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY CAST(STRFTIME('%w', o.order_purchase_timestamp) AS INTEGER)
ORDER BY total_orders DESC;

-- Part C: Peak Purchase Hours (Hourly Distribution)
SELECT 
    STRFTIME('%H', order_purchase_timestamp) AS hour_of_day,
    CASE 
        WHEN CAST(STRFTIME('%H', order_purchase_timestamp) AS INTEGER) BETWEEN 6 AND 11 THEN 'Morning (06-11)'
        WHEN CAST(STRFTIME('%H', order_purchase_timestamp) AS INTEGER) BETWEEN 12 AND 17 THEN 'Afternoon (12-17)'
        WHEN CAST(STRFTIME('%H', order_purchase_timestamp) AS INTEGER) BETWEEN 18 AND 23 THEN 'Evening (18-23)'
        ELSE 'Night / Early Morning (00-05)'
    END AS time_window,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(100.0 * COUNT(DISTINCT o.order_id) / (SELECT COUNT(*) FROM orders WHERE order_status = 'delivered'), 2) AS pct_of_orders
FROM orders o
WHERE o.order_status = 'delivered'
GROUP BY STRFTIME('%H', order_purchase_timestamp)
ORDER BY hour_of_day ASC;
