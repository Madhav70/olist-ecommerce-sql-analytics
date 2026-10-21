-- ==============================================================================
-- Query 06: Customer Reviews, Satisfaction Drivers & Delay Correlation
-- ==============================================================================
-- Business Objective:
-- 1. Analyze platform customer satisfaction scores (1 to 5 stars).
-- 2. Prove mathematically the negative impact of delivery delays on customer ratings.
-- 3. Segment review scores by delivery latency buckets (days to deliver).
-- 4. Identify high-volume sellers with subpar customer satisfaction ratings.
-- ==============================================================================

-- Part A: Customer Review Score Distribution & Feedback Behavior
SELECT 
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_reviews), 2) AS pct_of_reviews,
    SUM(CASE WHEN review_comment_message IS NOT NULL THEN 1 ELSE 0 END) AS reviews_with_written_comment,
    ROUND(100.0 * SUM(CASE WHEN review_comment_message IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS written_comment_rate_pct
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;

-- Part B: On-Time vs Delayed Orders Impact on Review Scores
WITH order_delivery_reviews AS (
    SELECT 
        o.order_id,
        r.review_score,
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Delayed (Past Estimated SLA)'
            ELSE 'On-Time (Delivered Before/On Estimated SLA)'
        END AS delivery_performance
    FROM orders o
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT 
    delivery_performance,
    COUNT(*) AS total_reviews,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * SUM(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) / COUNT(*), 2) AS five_star_pct,
    ROUND(100.0 * SUM(CASE WHEN review_score = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS one_star_pct
FROM order_delivery_reviews
GROUP BY delivery_performance;

-- Part C: Review Scores by Delivery Latency Buckets
WITH order_latency AS (
    SELECT 
        o.order_id,
        ROUND(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp), 0) AS delivery_days,
        r.review_score
    FROM orders o
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT 
    CASE 
        WHEN delivery_days <= 3 THEN '1. Super Express (<= 3 days)'
        WHEN delivery_days BETWEEN 4 AND 7 THEN '2. Fast (4 - 7 days)'
        WHEN delivery_days BETWEEN 8 AND 14 THEN '3. Standard (8 - 14 days)'
        WHEN delivery_days BETWEEN 15 AND 21 THEN '4. Moderate (15 - 21 days)'
        WHEN delivery_days BETWEEN 22 AND 30 THEN '5. Slow (22 - 30 days)'
        ELSE '6. Severe Delay (> 30 days)'
    END AS delivery_latency_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * SUM(CASE WHEN review_score = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS one_star_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) / COUNT(*), 2) AS five_star_rate_pct
FROM order_latency
GROUP BY delivery_latency_bucket
ORDER BY delivery_latency_bucket ASC;

-- Part D: High-Volume Sellers with Lowest Customer Ratings (Quality Alert)
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(DISTINCT oi.order_id), 2) AS late_delivery_rate_pct
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING total_orders >= 100
ORDER BY avg_review_score ASC
LIMIT 10;
