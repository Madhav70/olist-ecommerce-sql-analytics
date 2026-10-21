-- ==============================================================================
-- Query 02: Customer RFM Segmentation & Repeat Purchase Behavior
-- ==============================================================================
-- Business Objective:
-- Quantify customer loyalty, calculate the platform's repeat purchase rate,
-- and segment customers using Recency, Frequency, and Monetary (RFM) scoring.
-- Identifies VIPs ('Champions'), at-risk buyers, and single-purchase drop-offs.
-- ==============================================================================

-- Part A: Customer Repeat Purchase Rate
WITH customer_order_counts AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        ROUND(SUM(oi.price), 2) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
retention_stats AS (
    SELECT 
        COUNT(*) AS total_customers,
        SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_buyers,
        SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_buyers,
        ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_purchase_rate_pct,
        ROUND(AVG(CASE WHEN order_count = 1 THEN total_spend END), 2) AS avg_spend_one_time,
        ROUND(AVG(CASE WHEN order_count > 1 THEN total_spend END), 2) AS avg_spend_repeat
    FROM customer_order_counts
)
SELECT 
    'Retention Summary' AS analysis_section,
    total_customers,
    one_time_buyers,
    repeat_buyers,
    repeat_purchase_rate_pct,
    avg_spend_one_time,
    avg_spend_repeat
FROM retention_stats;

-- Part B: RFM Segmentation & Customer Tier Distribution
WITH customer_rfm_base AS (
    SELECT 
        c.customer_unique_id,
        -- Snapshot anchor date is 2018-10-18 (latest order recorded in dataset)
        ROUND(JULIANDAY('2018-10-18') - JULIANDAY(MAX(o.order_purchase_timestamp)), 1) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency_orders,
        ROUND(SUM(oi.price), 2) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency_orders,
        monetary_value,
        -- Recency Score: 5 is most recent (lowest days), 1 is least recent (highest days)
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        -- Frequency Score: 5 for repeat buyers (>=2 orders), 1-2 for single orders
        CASE 
            WHEN frequency_orders >= 3 THEN 5
            WHEN frequency_orders = 2 THEN 4
            ELSE 1
        END AS f_score,
        -- Monetary Score: 5 is highest spend, 1 is lowest spend
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM customer_rfm_base
),
customer_segments AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency_orders,
        monetary_value,
        r_score,
        f_score,
        m_score,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN '1. Champions (VIP)'
            WHEN r_score >= 3 AND f_score >= 4 THEN '2. Loyal Customers'
            WHEN r_score >= 4 AND f_score = 1 AND m_score >= 4 THEN '3. High-Value New Customers'
            WHEN r_score >= 4 AND f_score = 1 AND m_score < 4 THEN '4. Recent Promising'
            WHEN r_score BETWEEN 2 AND 3 AND m_score >= 3 THEN '5. Needs Attention'
            WHEN r_score <= 2 AND f_score >= 4 THEN '6. At Risk (Former Loyal)'
            WHEN r_score <= 2 AND m_score >= 4 THEN '7. High-Value Churned'
            ELSE '8. Hibernating / Lost'
        END AS customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_segments), 2) AS pct_of_customer_base,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency_orders), 2) AS avg_orders,
    ROUND(AVG(monetary_value), 2) AS avg_spend_per_customer,
    ROUND(SUM(monetary_value), 2) AS segment_total_spend,
    ROUND(100.0 * SUM(monetary_value) / (SELECT SUM(monetary_value) FROM customer_segments), 2) AS pct_of_total_gmv
FROM customer_segments
GROUP BY customer_segment
ORDER BY segment_total_spend DESC;
