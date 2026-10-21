-- ==============================================================================
-- Olist Brazilian E-Commerce Database Indexes
-- ==============================================================================
-- Description: Indexes designed to accelerate join operations, date-range
-- aggregations, customer tracking, and geospatial lookups.
-- ==============================================================================

-- 1. Orders Indexes
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (order_status);
CREATE INDEX IF NOT EXISTS idx_orders_purchase_ts ON orders (order_purchase_timestamp);

-- 2. Order Items Indexes
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_seller_id ON order_items (seller_id);
CREATE INDEX IF NOT EXISTS idx_order_items_shipping_date ON order_items (shipping_limit_date);

-- 3. Order Payments Indexes
CREATE INDEX IF NOT EXISTS idx_order_payments_type ON order_payments (payment_type);
CREATE INDEX IF NOT EXISTS idx_order_payments_order_id ON order_payments (order_id);

-- 4. Order Reviews Indexes
CREATE INDEX IF NOT EXISTS idx_order_reviews_score ON order_reviews (review_score);
CREATE INDEX IF NOT EXISTS idx_order_reviews_order_id ON order_reviews (order_id);

-- 5. Customers Indexes
CREATE INDEX IF NOT EXISTS idx_customers_unique_id ON customers (customer_unique_id);
CREATE INDEX IF NOT EXISTS idx_customers_state_city ON customers (customer_state, customer_city);
CREATE INDEX IF NOT EXISTS idx_customers_zip ON customers (customer_zip_code_prefix);

-- 6. Products Indexes
CREATE INDEX IF NOT EXISTS idx_products_category ON products (product_category_name);

-- 7. Sellers Indexes
CREATE INDEX IF NOT EXISTS idx_sellers_state_city ON sellers (seller_state, seller_city);
CREATE INDEX IF NOT EXISTS idx_sellers_zip ON sellers (seller_zip_code_prefix);

-- 8. Geolocation Indexes
CREATE INDEX IF NOT EXISTS idx_geo_zip ON geolocation (geolocation_zip_code_prefix);
