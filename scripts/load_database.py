"""
==============================================================================
Olist Brazilian E-Commerce ETL & Database Ingestion Pipeline
==============================================================================
Author: Antigravity Data Engineering
Description: Automated pipeline that parses, cleans, and loads the 9 Olist CSV
files into a high-performance, fully indexed SQLite relational database.
==============================================================================
"""

import os
import sys
import time
import sqlite3
import pandas as pd

DB_FILE = "olist_ecommerce.db"
SCHEMA_SQL = os.path.join("schema", "01_schema_sqlite.sql")
INDEXES_SQL = os.path.join("schema", "02_indexes.sql")
VIEWS_SQL = os.path.join("schema", "03_views.sql")

def log(msg):
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}")

def execute_sql_file(conn, file_path):
    log(f"Executing SQL script: {file_path}")
    with open(file_path, "r", encoding="utf-8") as f:
        sql = f.read()
    conn.executescript(sql)

def load_data():
    start_total = time.time()
    log("Starting Olist Database Ingestion Pipeline...")

    # Remove existing database if present for a clean rebuild
    if os.path.exists(DB_FILE):
        log(f"Removing existing {DB_FILE} to ensure clean load...")
        os.remove(DB_FILE)

    conn = sqlite3.connect(DB_FILE)
    conn.execute("PRAGMA journal_mode = WAL;")
    conn.execute("PRAGMA synchronous = NORMAL;")
    conn.execute("PRAGMA cache_size = -64000;")  # 64MB cache

    # Step 1: Create Schema
    execute_sql_file(conn, SCHEMA_SQL)

    # Step 2: Ingest Tables
    # Order of ingestion respects foreign key hierarchy
    # 2.1 Category Translation
    log("Loading product category translations...")
    trans_df = pd.read_csv("product_category_name_translation.csv")
    # Add missing translations identified in data profiling
    missing_translations = pd.DataFrame([
        {"product_category_name": "pc_gamer", "product_category_name_english": "pc_gamer"},
        {"product_category_name": "portateis_cozinha_e_preparadores_de_alimentos", "product_category_name_english": "small_appliances"}
    ])
    trans_df = pd.concat([trans_df, missing_translations], ignore_index=True).drop_duplicates(subset=["product_category_name"])
    trans_df.to_sql("product_category_translation", conn, if_exists="append", index=False)
    log(f"  -> Loaded {len(trans_df):,} category translation records")

    # 2.2 Customers
    log("Loading customers...")
    cust_df = pd.read_csv("olist_customers_dataset.csv")
    cust_df.to_sql("customers", conn, if_exists="append", index=False)
    log(f"  -> Loaded {len(cust_df):,} customers records")

    # 2.3 Sellers
    log("Loading sellers...")
    sellers_df = pd.read_csv("olist_sellers_dataset.csv")
    sellers_df.to_sql("sellers", conn, if_exists="append", index=False)
    log(f"  -> Loaded {len(sellers_df):,} sellers records")

    # 2.4 Products
    log("Loading products...")
    prod_df = pd.read_csv("olist_products_dataset.csv")
    prod_df.to_sql("products", conn, if_exists="append", index=False)
    log(f"  -> Loaded {len(prod_df):,} products records")

    # 2.5 Orders
    log("Loading orders...")
    orders_df = pd.read_csv("olist_orders_dataset.csv")
    orders_df.to_sql("orders", conn, if_exists="append", index=False)
    log(f"  -> Loaded {len(orders_df):,} orders records")

    # 2.6 Order Items
    log("Loading order items...")
    items_df = pd.read_csv("olist_order_items_dataset.csv")
    items_df.to_sql("order_items", conn, if_exists="append", index=False)
    log(f"  -> Loaded {len(items_df):,} order_items records")

    # 2.7 Order Payments
    log("Loading order payments...")
    payments_df = pd.read_csv("olist_order_payments_dataset.csv")
    payments_df.to_sql("order_payments", conn, if_exists="append", index=False)
    log(f"  -> Loaded {len(payments_df):,} order_payments records")

    # 2.8 Order Reviews
    log("Loading order reviews...")
    reviews_df = pd.read_csv("olist_order_reviews_dataset.csv")
    # Clean duplicates if any on composite key (review_id, order_id)
    reviews_df = reviews_df.drop_duplicates(subset=["review_id", "order_id"])
    reviews_df.to_sql("order_reviews", conn, if_exists="append", index=False)
    log(f"  -> Loaded {len(reviews_df):,} order_reviews records")

    # 2.9 Geolocation
    log("Loading geolocation (deduplicating exact matches for optimization)...")
    geo_df = pd.read_csv("olist_geolocation_dataset.csv")
    raw_geo_count = len(geo_df)
    geo_df = geo_df.drop_duplicates()
    dedup_geo_count = len(geo_df)
    log(f"  -> Cleaned {raw_geo_count - dedup_geo_count:,} duplicate coordinate records. Retained {dedup_geo_count:,} rows.")
    geo_df.to_sql("geolocation", conn, if_exists="append", index=False)

    # Step 3: Create Indexes
    execute_sql_file(conn, INDEXES_SQL)
    log("All performance indexes built successfully.")

    # Step 4: Create Reporting Views
    execute_sql_file(conn, VIEWS_SQL)
    log("All analytical views created successfully.")

    # Step 5: Verification & Quality Assurance
    log("Running Data Integrity and Foreign Key Checks...")
    fk_errors = conn.execute("PRAGMA foreign_key_check;").fetchall()
    if fk_errors:
        log(f"WARNING: Found {len(fk_errors)} foreign key violations!")
    else:
        log("SUCCESS: PRAGMA foreign_key_check passed with 0 violations!")

    # Summary table
    tables = [
        "customers", "sellers", "product_category_translation", "products",
        "orders", "order_items", "order_payments", "order_reviews", "geolocation"
    ]
    log("\n" + "=" * 55)
    log(f"{'TABLE NAME':<32} | {'ROW COUNT':>15}")
    log("=" * 55)
    for tbl in tables:
        count = conn.execute(f"SELECT COUNT(*) FROM {tbl};").fetchone()[0]
        log(f"{tbl:<32} | {count:>15,}")
    log("=" * 55)

    # Verify Views
    view_test = conn.execute("SELECT COUNT(*) FROM vw_order_master;").fetchone()[0]
    log(f"View 'vw_order_master' tested: {view_test:,} records mapped.")

    conn.close()
    elapsed = time.time() - start_total
    log(f"Database build complete in {elapsed:.2f} seconds! Database stored at: {DB_FILE}\n")

if __name__ == "__main__":
    load_data()
