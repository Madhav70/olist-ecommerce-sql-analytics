# Olist Brazilian E-Commerce: Data Dictionary

Comprehensive technical and business metadata for all entities within the relational schema.

---

## 1. `customers`
Stores customer identity, order mapping, and geographic location.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `customer_id` | `VARCHAR(32)` | **PK** | No | Unique transaction-level identifier generated per individual order. |
| `customer_unique_id` | `VARCHAR(32)` | - | No | Unique identifier representing the real human customer (persists across repeat orders). |
| `customer_zip_code_prefix` | `INTEGER` | - | No | First 5 digits of the customer's Brazilian postal code (CEP). |
| `customer_city` | `VARCHAR(100)` | - | No | Customer's city name. |
| `customer_state` | `VARCHAR(2)` | - | No | Two-letter Brazilian state abbreviation (e.g., `SP`, `RJ`, `MG`). |

---

## 2. `orders`
Core transaction table tracking order status and lifecycle timestamps.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | `VARCHAR(32)` | **PK** | No | Unique identifier for each order placed on the platform. |
| `customer_id` | `VARCHAR(32)` | **FK** | No | Foreign key linking to `customers.customer_id`. |
| `order_status` | `VARCHAR(20)` | - | No | Status of order: `delivered`, `shipped`, `canceled`, `unavailable`, `invoiced`, `processing`, `created`, `approved`. |
| `order_purchase_timestamp` | `TIMESTAMP` | - | No | Exact timestamp when customer placed the purchase. |
| `order_approved_at` | `TIMESTAMP` | - | Yes | Timestamp of payment confirmation/approval. |
| `order_delivered_carrier_date` | `TIMESTAMP` | - | Yes | Timestamp when the seller handed over the parcel to the logistics carrier. |
| `order_delivered_customer_date` | `TIMESTAMP` | - | Yes | Actual timestamp when parcel was delivered to customer's address. |
| `order_estimated_delivery_date` | `TIMESTAMP` | - | No | Target SLA delivery date communicated to customer at checkout. |

---

## 3. `order_items`
Line-item detail for every product in an order, including seller assignment and pricing.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | `VARCHAR(32)` | **PK, FK** | No | Foreign key referencing `orders.order_id`. |
| `order_item_id` | `INTEGER` | **PK** | No | Sequential item number within the same order (1, 2, 3...). |
| `product_id` | `VARCHAR(32)` | **FK** | No | Foreign key referencing `products.product_id`. |
| `seller_id` | `VARCHAR(32)` | **FK** | No | Foreign key referencing `sellers.seller_id`. |
| `shipping_limit_date` | `TIMESTAMP` | - | No | Target deadline for seller to hand package over to carrier. |
| `price` | `NUMERIC(10, 2)` | - | No | Item merchandise price in Brazilian Reais (BRL / R$). |
| `freight_value` | `NUMERIC(10, 2)` | - | No | Shipping fee allocated to this item in BRL (R$). |

---

## 4. `order_payments`
Financial breakdown of methods and installment schedules per order.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | `VARCHAR(32)` | **PK, FK** | No | Foreign key referencing `orders.order_id`. |
| `payment_sequential` | `INTEGER` | **PK** | No | Sequence index when customer uses multiple payment methods or vouchers (1, 2, 3...). |
| `payment_type` | `VARCHAR(20)` | - | No | Method of payment: `credit_card`, `boleto`, `voucher`, `debit_card`. |
| `payment_installments` | `INTEGER` | - | No | Number of installment payments selected by customer (1x to 24x). |
| `payment_value` | `NUMERIC(10, 2)` | - | No | Transaction monetary amount paid in BRL (R$). |

---

## 5. `order_reviews`
Customer review ratings and textual feedback collected post-delivery.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `review_id` | `VARCHAR(32)` | **PK** | No | Unique identifier for each review submission. |
| `order_id` | `VARCHAR(32)` | **PK, FK** | No | Foreign key referencing `orders.order_id`. |
| `review_score` | `SMALLINT` | - | No | Customer satisfaction rating from 1 (lowest) to 5 (highest). |
| `review_comment_title` | `TEXT` | - | Yes | Short title of customer's review comment in Portuguese. |
| `review_comment_message` | `TEXT` | - | Yes | Detailed customer review feedback message in Portuguese. |
| `review_creation_date` | `TIMESTAMP` | - | No | Timestamp when the satisfaction survey invitation was sent. |
| `review_answer_timestamp` | `TIMESTAMP` | - | No | Timestamp when customer submitted their review response. |

---

## 6. `products`
Product catalog metadata, category classifications, and physical dimensions.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `product_id` | `VARCHAR(32)` | **PK** | No | Unique product catalog identifier. |
| `product_category_name` | `VARCHAR(100)` | **FK** | Yes | Portuguese category name referencing translation table. |
| `product_name_lenght` | `INTEGER` | - | Yes | Number of characters in the product title. |
| `product_description_lenght`| `INTEGER` | - | Yes | Number of characters in the product description. |
| `product_photos_qty` | `INTEGER` | - | Yes | Number of product photos displayed on platform listing. |
| `product_weight_g` | `NUMERIC(10, 2)` | - | Yes | Product weight in grams (g). |
| `product_length_cm` | `NUMERIC(10, 2)` | - | Yes | Package length in centimeters (cm). |
| `product_height_cm` | `NUMERIC(10, 2)` | - | Yes | Package height in centimeters (cm). |
| `product_width_cm` | `NUMERIC(10, 2)` | - | Yes | Package width in centimeters (cm). |

---

## 7. `product_category_translation`
Lookup table mapping Brazilian Portuguese category taxonomy to English.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `product_category_name` | `VARCHAR(100)` | **PK** | No | Category name in Brazilian Portuguese. |
| `product_category_name_english` | `VARCHAR(100)` | - | No | Standardized English translation of the category. |

---

## 8. `sellers`
Merchant and seller registry partnering with the Olist marketplace.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `seller_id` | `VARCHAR(32)` | **PK** | No | Unique seller identifier. |
| `seller_zip_code_prefix` | `INTEGER` | - | No | First 5 digits of the seller's postal code (CEP). |
| `seller_city` | `VARCHAR(100)` | - | No | Seller fulfillment hub city name. |
| `seller_state` | `VARCHAR(2)` | - | No | Two-letter Brazilian state abbreviation. |

---

## 9. `geolocation`
Spatial coordinate points across Brazilian postal code prefixes.

| Column Name | Data Type | Key | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `geolocation_id` | `BIGINT` | **PK** | No | Auto-increment surrogate primary key. |
| `geolocation_zip_code_prefix`| `INTEGER` | - | No | First 5 digits of Brazilian postal code. |
| `geolocation_lat` | `NUMERIC(10, 7)` | - | No | Latitude coordinate in decimal degrees. |
| `geolocation_lng` | `NUMERIC(10, 7)` | - | No | Longitude coordinate in decimal degrees. |
| `geolocation_city` | `VARCHAR(100)` | - | No | City name associated with postal prefix. |
| `geolocation_state` | `VARCHAR(2)` | - | No | Two-letter Brazilian state abbreviation. |
