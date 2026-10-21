-- ==============================================================================
-- Olist Brazilian E-Commerce Database Schema (SQLite Dialect)
-- ==============================================================================
-- Description: Table definitions with primary keys, foreign keys, and constraints.
-- ==============================================================================

PRAGMA foreign_keys = ON;

-- 1. Customers Table
-- Contains information about customers and their geographical locations.
-- Note: 'customer_unique_id' represents a real human customer, whereas 'customer_id'
-- is a unique transaction-level customer identifier generated per order.
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix INTEGER NOT NULL,
    customer_city TEXT NOT NULL,
    customer_state TEXT NOT NULL
);

-- 2. Sellers Table
-- Information on sellers partnering with Olist.
DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix INTEGER NOT NULL,
    seller_city TEXT NOT NULL,
    seller_state TEXT NOT NULL
);

-- 3. Product Category Translation Table
-- Portuguese to English translation for product category names.
DROP TABLE IF EXISTS product_category_translation;
CREATE TABLE product_category_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL
);

-- 4. Products Table
-- Catalog information about products sold through the platform.
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g REAL,
    product_length_cm REAL,
    product_height_cm REAL,
    product_width_cm REAL,
    FOREIGN KEY (product_category_name) REFERENCES product_category_translation(product_category_name)
);

-- 5. Orders Table
-- Core transaction table tracking order status, timestamps, and customer link.
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_status TEXT NOT NULL CHECK(order_status IN ('delivered', 'shipped', 'canceled', 'unavailable', 'invoiced', 'processing', 'created', 'approved')),
    order_purchase_timestamp TEXT NOT NULL,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 6. Order Items Table
-- Individual items associated with each order, seller, and price/freight.
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_id TEXT NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id TEXT NOT NULL,
    seller_id TEXT NOT NULL,
    shipping_limit_date TEXT NOT NULL,
    price REAL NOT NULL CHECK(price >= 0),
    freight_value REAL NOT NULL CHECK(freight_value >= 0),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

-- 7. Order Payments Table
-- Payment breakdown by method, installments, and payment value per order.
DROP TABLE IF EXISTS order_payments;
CREATE TABLE order_payments (
    order_id TEXT NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type TEXT NOT NULL CHECK(payment_type IN ('credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined')),
    payment_installments INTEGER NOT NULL CHECK(payment_installments >= 0),
    payment_value REAL NOT NULL CHECK(payment_value >= 0),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- 8. Order Reviews Table
-- Customer satisfaction reviews and textual feedback submitted after order.
DROP TABLE IF EXISTS order_reviews;
CREATE TABLE order_reviews (
    review_id TEXT NOT NULL,
    order_id TEXT NOT NULL,
    review_score INTEGER NOT NULL CHECK(review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT NOT NULL,
    review_answer_timestamp TEXT NOT NULL,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- 9. Geolocation Table
-- Brazilian zip codes with latitude and longitude coordinates.
DROP TABLE IF EXISTS geolocation;
CREATE TABLE geolocation (
    geolocation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    geolocation_zip_code_prefix INTEGER NOT NULL,
    geolocation_lat REAL NOT NULL,
    geolocation_lng REAL NOT NULL,
    geolocation_city TEXT NOT NULL,
    geolocation_state TEXT NOT NULL
);
