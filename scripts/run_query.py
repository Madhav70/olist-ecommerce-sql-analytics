"""
==============================================================================
Olist Database Query Runner & Analytical CLI
==============================================================================
Author: Antigravity Data Engineering
Description: Executes SQL query files or inline queries against olist_ecommerce.db,
measures execution duration, formats results cleanly, and supports export to CSV/Markdown.
==============================================================================
"""

import sys
import os
import time
import sqlite3
import pandas as pd

DB_FILE = "olist_ecommerce.db"

def run_query(sql_text_or_path, params=None, export_csv=None, export_md=None, limit=None):
    if not os.path.exists(DB_FILE):
        print(f"Error: Database {DB_FILE} does not exist. Run scripts/load_database.py first.")
        sys.exit(1)

    # Check if input is a file path
    if os.path.isfile(sql_text_or_path):
        with open(sql_text_or_path, "r", encoding="utf-8") as f:
            raw_sql = f.read()
        print(f"\n================================================================================")
        print(f"Executing Query File: {sql_text_or_path}")
        print(f"================================================================================")
    else:
        raw_sql = sql_text_or_path
        print("\n--- Executing Inline Query ---")

    import re
    # Remove single-line comments (-- ...) and split by semicolon
    cleaned_sql = re.sub(r'--[^\n]*\n', '\n', raw_sql)
    statements = [stmt.strip() for stmt in cleaned_sql.split(";") if stmt.strip()]

    conn = sqlite3.connect(DB_FILE)
    results = []
    try:
        for idx, statement in enumerate(statements, 1):
            if len(statements) > 1:
                print(f"\n>>> Statement {idx} of {len(statements)}:")

            start = time.time()
            df = pd.read_sql_query(statement, conn, params=params)
            duration_ms = (time.time() - start) * 1000

            print(f"Result: {len(df):,} rows returned in {duration_ms:.2f} ms.\n")

            display_df = df.head(limit) if limit else df
            pd.set_option('display.max_columns', None)
            pd.set_option('display.width', 1000)
            print(display_df.to_string(index=False))

            if limit and len(df) > limit:
                print(f"\n... (Showing top {limit} of {len(df):,} rows)")

            results.append(df)

            if export_csv and len(statements) == 1:
                df.to_csv(export_csv, index=False)
                print(f"\n[Exported full result to CSV: {export_csv}]")

            if export_md and len(statements) == 1:
                with open(export_md, "w", encoding="utf-8") as f:
                    f.write(df.to_markdown(index=False))
                print(f"[Exported full result to Markdown: {export_md}]")

        return results[0] if len(results) == 1 else results
    except Exception as e:
        print(f"Error executing query: {e}")
        return None
    finally:
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python scripts/run_query.py <path_to_sql_file_or_query_string> [--limit N] [--csv output.csv]")
        print("\nExample:")
        print("  python scripts/run_query.py queries/01_executive_kpis.sql")
        sys.exit(0)

    target = sys.argv[1]
    limit_val = None
    csv_file = None

    if "--limit" in sys.argv:
        idx = sys.argv.index("--limit")
        if idx + 1 < len(sys.argv):
            limit_val = int(sys.argv[idx + 1])

    if "--csv" in sys.argv:
        idx = sys.argv.index("--csv")
        if idx + 1 < len(sys.argv):
            csv_file = sys.argv[idx + 1]

    run_query(target, limit=limit_val, export_csv=csv_file)
