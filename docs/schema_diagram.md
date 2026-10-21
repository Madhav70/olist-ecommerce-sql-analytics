# Entity-Relationship Architecture (ERD)

This document visualizes the relational schema design for the Olist Brazilian E-Commerce dataset.

---

## 1. Mermaid Entity-Relationship Diagram

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : "places (1:N)"
    ORDERS ||--|{ ORDER_ITEMS : "contains (1:N)"
    ORDERS ||--|{ ORDER_PAYMENTS : "paid via (1:N)"
    ORDERS ||--o{ ORDER_REVIEWS : "receives (1:N)"
    PRODUCTS ||--o{ ORDER_ITEMS : "ordered in (1:N)"
    SELLERS ||--o{ ORDER_ITEMS : "fulfills (1:N)"
    PRODUCT_CATEGORY_TRANSLATION ||--o{ PRODUCTS : "translates (1:N)"
    CUSTOMERS }o--o{ GEOLOCATION : "located at (N:M)"
    SELLERS }o--o{ GEOLOCATION : "located at (N:M)"

    CUSTOMERS {
        string customer_id PK "Unique order-level customer ID"
        string customer_unique_id "Real customer identifier"
        int customer_zip_code_prefix "Zip code prefix"
        string customer_city "City"
        string customer_state "State abbreviation"
    }

    ORDERS {
        string order_id PK "Unique order identifier"
        string customer_id FK "References customers.customer_id"
        string order_status "Order status (delivered, shipped, etc.)"
        timestamp order_purchase_timestamp "Purchase timestamp"
        timestamp order_approved_at "Payment approval timestamp"
        timestamp order_delivered_carrier_date "Handed to carrier timestamp"
        timestamp order_delivered_customer_date "Delivered to customer timestamp"
        timestamp order_estimated_delivery_date "Target delivery SLA"
    }

    ORDER_ITEMS {
        string order_id PK, FK "References orders.order_id"
        int order_item_id PK "Item sequential index (1, 2, ...)"
        string product_id FK "References products.product_id"
        string seller_id FK "References sellers.seller_id"
        timestamp shipping_limit_date "Seller shipping deadline"
        numeric price "Merchandise item price (BRL)"
        numeric freight_value "Item freight charge (BRL)"
    }

    ORDER_PAYMENTS {
        string order_id PK, FK "References orders.order_id"
        int payment_sequential PK "Payment split index (1, 2, ...)"
        string payment_type "credit_card, boleto, voucher, debit_card"
        int payment_installments "Number of installments"
        numeric payment_value "Monetary amount paid"
    }

    ORDER_REVIEWS {
        string review_id PK "Unique review identifier"
        string order_id PK, FK "References orders.order_id"
        int review_score "Rating (1 to 5)"
        string review_comment_title "Review headline"
        string review_comment_message "Review text"
        timestamp review_creation_date "Survey sent date"
        timestamp review_answer_timestamp "Survey response date"
    }

    PRODUCTS {
        string product_id PK "Unique product identifier"
        string product_category_name FK "References product_category_translation"
        int product_name_lenght "Name character length"
        int product_description_lenght "Description character length"
        int product_photos_qty "Number of photos"
        numeric product_weight_g "Weight in grams"
        numeric product_length_cm "Package length"
        numeric product_height_cm "Package height"
        numeric product_width_cm "Package width"
    }

    PRODUCT_CATEGORY_TRANSLATION {
        string product_category_name PK "Portuguese category name"
        string product_category_name_english "Standard English translation"
    }

    SELLERS {
        string seller_id PK "Unique seller identifier"
        int seller_zip_code_prefix "Zip code prefix"
        string seller_city "City"
        string seller_state "State abbreviation"
    }

    GEOLOCATION {
        bigint geolocation_id PK "Surrogate ID"
        int geolocation_zip_code_prefix "Postal prefix"
        numeric geolocation_lat "Latitude decimal"
        numeric geolocation_lng "Longitude decimal"
        string geolocation_city "City"
        string geolocation_state "State"
    }
```

---

## 2. Relational Modeling Decisions & Highlights

1. **Third Normal Form (3NF) Compliance**:
   - The original CSV schema is normalized into 3NF. Transitive dependencies are isolated (e.g., product category translations are split from the products catalog).
   - Customers have two ID concepts: `customer_id` (a transaction-level key scoped to one purchase) and `customer_unique_id` (representing the human account across repeat purchases).

2. **Composite Primary Keys**:
   - `order_items`: `(order_id, order_item_id)` handles multi-item shopping carts where multiple items of identical or distinct products exist.
   - `order_payments`: `(order_id, payment_sequential)` accommodates split payments (e.g., payment partially via voucher and remainder via credit card).
   - `order_reviews`: `(review_id, order_id)` handles multi-order batches where one review survey covers multiple linked orders.

3. **Geospatial Optimization**:
   - Geolocation data contains multiple coordinate measurements per zip code prefix. To optimize query runtime, `schema/03_views.sql` creates `vw_zip_code_geolocation` which computes centroid coordinates `(AVG(lat), AVG(lng))` per prefix.
