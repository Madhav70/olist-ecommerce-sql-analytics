-- ==============================================================================
-- Query 08: Advanced SQL Analytics (Window Functions, CTEs & Cohorts)
-- ==============================================================================
-- Business Objective:
-- Demonstrate advanced analytical SQL modeling:
-- 1. Running cumulative GMV and 3-month moving average of monthly platform revenue.
-- 2. Seller category leadership ranking using DENSE_RANK() OVER (PARTITION BY...).
-- 3. Inter-purchase latency: Days elapsed between order 1 and order 2 for repeat customers.
-- ==============================================================================

-- Part A: Cumulative Platform Revenue & 3-Month Rolling Moving Average
WITH monthly_sales AS (
    SELECT 
        STRFTIME('%Y-%m', o.order_purchase_timestamp) AS sales_month,
        ROUND(SUM(oi.price), 2) AS monthly_gmv,
        COUNT(DISTINCT o.order_id) AS monthly_orders
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
    GROUP BY STRFTIME('%Y-%m', o.order_purchase_timestamp)
)
SELECT 
    sales_month,
    monthly_orders,
    monthly_gmv,
    -- Running Cumulative Total GMV
    ROUND(SUM(monthly_gmv) OVER (
        ORDER BY sales_month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_gmv_to_date,
    -- 3-Month Moving Average of Monthly GMV
    ROUND(AVG(monthly_gmv) OVER (
        ORDER BY sales_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3month_avg_gmv
FROM monthly_sales
ORDER BY sales_month ASC;

-- Part B: Top 3 Sellers Ranked within Top 5 Product Categories (Partitioned Ranking)
WITH top_categories AS (
    SELECT 
        COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name,
        SUM(oi.price) AS category_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown')
    ORDER BY category_revenue DESC
    LIMIT 5
),
seller_category_sales AS (
    SELECT 
        COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name,
        oi.seller_id,
        s.seller_state,
        COUNT(oi.order_item_id) AS items_sold,
        ROUND(SUM(oi.price), 2) AS seller_category_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') IN (SELECT category_name FROM top_categories)
    GROUP BY COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown'), oi.seller_id, s.seller_state
),
ranked_sellers AS (
    SELECT 
        category_name,
        seller_id,
        seller_state,
        items_sold,
        seller_category_revenue,
        DENSE_RANK() OVER (
            PARTITION BY category_name 
            ORDER BY seller_category_revenue DESC
        ) AS rank_in_category
    FROM seller_category_sales
)
SELECT 
    category_name,
    rank_in_category,
    seller_id,
    seller_state,
    items_sold,
    seller_category_revenue
FROM ranked_sellers
WHERE rank_in_category <= 3
ORDER BY category_name, rank_in_category;

-- Part C: Repeat Buyer Purchase Sequencing & Time to Second Order
WITH customer_orders_sequenced AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS order_sequence_number,
        LAG(o.order_purchase_timestamp, 1) OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS prior_order_timestamp
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
second_orders AS (
    SELECT 
        customer_unique_id,
        order_purchase_timestamp AS second_order_date,
        prior_order_timestamp AS first_order_date,
        ROUND(JULIANDAY(order_purchase_timestamp) - JULIANDAY(prior_order_timestamp), 1) AS days_between_orders
    FROM customer_orders_sequenced
    WHERE order_sequence_number = 2
)
SELECT 
    CASE 
        WHEN days_between_orders <= 7 THEN '1. Within 1 Week (0 - 7 days)'
        WHEN days_between_orders BETWEEN 8 AND 30 THEN '2. Within 1 Month (8 - 30 days)'
        WHEN days_between_orders BETWEEN 31 AND 90 THEN '3. 1 - 3 Months (31 - 90 days)'
        WHEN days_between_orders BETWEEN 91 AND 180 THEN '4. 3 - 6 Months (91 - 180 days)'
        ELSE '5. Over 6 Months (> 180 days)'
    END AS repurchase_timeframe,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM second_orders), 2) AS pct_of_repeat_buyers,
    ROUND(AVG(days_between_orders), 1) AS avg_days_to_repurchase
FROM second_orders
GROUP BY repurchase_timeframe
ORDER BY repurchase_timeframe ASC;
