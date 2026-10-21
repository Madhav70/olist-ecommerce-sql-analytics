-- ==============================================================================
-- Query 07: Payment Methods, Financing Patterns & Installment Economics
-- ==============================================================================
-- Business Objective:
-- 1. Quantify the market share of payment methods in Brazil (Credit Card, Boleto, Voucher, Debit).
-- 2. Analyze customer credit financing behavior and installment selection across price tiers.
-- 3. Examine split-payment orders and voucher redemption trends.
-- ==============================================================================

-- Part A: Payment Method Market Share and Basket Economics
SELECT 
    payment_type,
    COUNT(order_id) AS payment_transactions,
    ROUND(100.0 * COUNT(order_id) / (SELECT COUNT(*) FROM order_payments), 2) AS transaction_share_pct,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(100.0 * SUM(payment_value) / (SELECT SUM(payment_value) FROM order_payments), 2) AS gmv_share_pct,
    ROUND(AVG(payment_value), 2) AS avg_transaction_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM order_payments
WHERE payment_type <> 'not_defined'
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Part B: Credit Card Installment Tiering & Price Elasticity
WITH credit_orders AS (
    SELECT 
        payment_installments,
        payment_value,
        CASE 
            WHEN payment_installments = 1 THEN '01. Single Payment (1x)'
            WHEN payment_installments BETWEEN 2 AND 3 THEN '02. Short Term (2x - 3x)'
            WHEN payment_installments BETWEEN 4 AND 6 THEN '03. Medium Term (4x - 6x)'
            WHEN payment_installments BETWEEN 7 AND 10 THEN '04. Long Term (7x - 10x)'
            ELSE '05. Ultra Long Term (> 10x)'
        END AS installment_bracket
    FROM order_payments
    WHERE payment_type = 'credit_card'
)
SELECT 
    installment_bracket,
    COUNT(*) AS total_transactions,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM credit_orders), 2) AS transaction_pct,
    ROUND(SUM(payment_value), 2) AS total_value,
    ROUND(AVG(payment_value), 2) AS avg_order_ticket_size,
    MIN(payment_value) AS min_ticket,
    MAX(payment_value) AS max_ticket
FROM credit_orders
GROUP BY installment_bracket
ORDER BY installment_bracket ASC;

-- Part C: Multi-Payment & Voucher Split Order Analysis
WITH order_splits AS (
    SELECT 
        order_id,
        COUNT(payment_sequential) AS payments_count,
        COUNT(DISTINCT payment_type) AS distinct_methods,
        SUM(CASE WHEN payment_type = 'voucher' THEN 1 ELSE 0 END) AS voucher_count,
        ROUND(SUM(payment_value), 2) AS order_total_value
    FROM order_payments
    GROUP BY order_id
)
SELECT 
    CASE 
        WHEN payments_count = 1 THEN '1. Single Transaction Payment'
        WHEN payments_count > 1 AND distinct_methods = 1 THEN '2. Split Payments (Same Method, e.g. Multi-Vouchers)'
        ELSE '3. Hybrid Split (Multiple Payment Methods)'
    END AS payment_structure,
    COUNT(order_id) AS total_orders,
    ROUND(100.0 * COUNT(order_id) / (SELECT COUNT(*) FROM order_splits), 2) AS pct_of_orders,
    ROUND(AVG(order_total_value), 2) AS avg_order_value,
    SUM(voucher_count) AS total_vouchers_used
FROM order_splits
GROUP BY payment_structure
ORDER BY total_orders DESC;
