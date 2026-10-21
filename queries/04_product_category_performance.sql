-- ==============================================================================
-- Query 04: Product & Category Analytics, Freight Burden & Cross-Selling
-- ==============================================================================
-- Business Objective:
-- 1. Identify top revenue-generating and highest-volume product categories.
-- 2. Detect high-friction categories where freight cost exceeds 20% of product value.
-- 3. Discover cross-purchasing patterns (Market Basket Analysis) across categories.
-- 4. Evaluate physical shipping burdens (weight & volume vs freight cost).
-- ==============================================================================

-- Part A: Top 15 Product Categories by Revenue and Units Sold
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(100.0 * SUM(oi.price) / (SELECT SUM(price) FROM order_items oi2 JOIN orders o2 ON oi2.order_id = o2.order_id WHERE o2.order_status = 'delivered'), 2) AS revenue_share_pct,
    ROUND(AVG(oi.price), 2) AS avg_selling_price_asp,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight,
    ROUND(AVG(r.review_score), 2) AS avg_customer_rating
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown')
ORDER BY total_revenue DESC
LIMIT 15;

-- Part B: Categories with Highest Freight Friction (% of Merchandise Price)
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name,
    COUNT(oi.order_item_id) AS units_sold,
    ROUND(AVG(oi.price), 2) AS avg_unit_price,
    ROUND(AVG(oi.freight_value), 2) AS avg_unit_freight,
    ROUND(100.0 * AVG(oi.freight_value) / AVG(oi.price), 2) AS freight_to_price_ratio_pct,
    ROUND(AVG(p.product_weight_g) / 1000.0, 2) AS avg_weight_kg
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown')
HAVING units_sold >= 100
ORDER BY freight_to_price_ratio_pct DESC
LIMIT 10;

-- Part C: Cross-Selling / Market Basket Analysis (Categories Frequently Bought Together)
WITH multi_item_orders AS (
    SELECT 
        oi1.order_id,
        COALESCE(t1.product_category_name_english, p1.product_category_name, 'Unknown') AS category_a,
        COALESCE(t2.product_category_name_english, p2.product_category_name, 'Unknown') AS category_b
    FROM order_items oi1
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.order_item_id < oi2.order_item_id
    JOIN products p1 ON oi1.product_id = p1.product_id
    JOIN products p2 ON oi2.product_id = p2.product_id
    LEFT JOIN product_category_translation t1 ON p1.product_category_name = t1.product_category_name
    LEFT JOIN product_category_translation t2 ON p2.product_category_name = t2.product_category_name
    WHERE p1.product_category_name <> p2.product_category_name
)
SELECT 
    category_a,
    category_b,
    COUNT(DISTINCT order_id) AS co_occurrence_orders
FROM multi_item_orders
GROUP BY category_a, category_b
ORDER BY co_occurrence_orders DESC
LIMIT 10;
