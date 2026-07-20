"""
=============================================================================
Enterprise Retail Analytics Platform - Landing Layer Loader (ELT: Extract-Load)
=============================================================================
Script:   load_landing.py
Purpose:  Bulk-load the 12 raw CSV files from Dataset/ into the [landing]
          schema of RetailDW. This is the "E-L" of the ELT pipeline; the
          "T" (transform) happens later inside SQL Server via the staging
          stored procedures (06_ETL_Landing_To_Staging.sql).

WHEN does this run?
  Phase 3, Step 2 of the build:
    Step 1 (done): 01_Landing_Tables.sql created the empty landing tables.
    Step 2 (THIS): load raw CSVs -> landing.*  (all columns VARCHAR/NVARCHAR)
    Step 3 (next): EXEC staging.usp_LoadAll_LandingToStaging  (clean + typecast)

WHY a Python loader (not BULK INSERT / bcp)?
  1. The landing tables carry two extra metadata columns (_LoadedAt with a
     GETDATE() DEFAULT, and _SourceFile with a literal DEFAULT). A raw
     BULK INSERT maps CSV fields to columns positionally and would fail on
     the column-count mismatch unless we hand-author 12 format files.
     pandas.to_sql emits INSERTs that list ONLY the CSV columns, so the two
     metadata columns fall through to their DEFAULT constraints automatically.
  2. Landing is intentionally "load as-is" (schema-on-read). Reading every
     CSV value as a string (dtype=str) preserves the raw text exactly -
     including the deliberate data-quality defects (nulls, dup rows, future
     dates, negative qty) that the staging ETL is designed to catch. No
     silent type coercion happens at this layer.
  3. It is idempotent and re-runnable (each table is TRUNCATEd first), which
     is what you want for a repeatable portfolio build.

WHAT it does (per table):
  a. TRUNCATE landing.<Table>            -> clean slate, reset for reload
  b. read CSV as all-string DataFrame    -> preserve raw values + defects
  c. to_sql(append, fast_executemany)    -> batched insert; defaults fill meta
  d. verify row count matches the CSV

CONNECTION:
  Windows Authentication (trusted connection) to localhost, database RetailDW,
  via ODBC Driver 18. Encrypt=yes is the driver default, so we pass
  TrustServerCertificate=yes to accept the local self-signed certificate
  (same reason sqlcmd needed the -C flag).

USAGE:
  (.venv) python Python/load_landing.py
=============================================================================
"""

from __future__ import annotations

import sys
import time
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

# Force UTF-8 stdout so the arrow/box characters in log lines don't blow up on
# the Windows cp1252 console (same fix used in generate_dataset.py).
sys.stdout.reconfigure(encoding="utf-8")

# --- Configuration ----------------------------------------------------------
SERVER = "localhost"
DATABASE = "RetailDW"
DRIVER = "ODBC Driver 18 for SQL Server"

# Resolve Dataset/ relative to the repo root (this file lives in Python/).
REPO_ROOT = Path(__file__).resolve().parent.parent
DATASET_DIR = REPO_ROOT / "Dataset"

# Ordered mapping: CSV file  ->  fully-qualified landing table.
# Order matters only for readable logs; landing has no FKs so any order loads.
# Batch size is tuned per table: the big fact-like files (order_details,
# inventory, shipping) use larger batches to cut round-trips.
CSV_TO_TABLE: list[tuple[str, str, int]] = [
    # (csv_file,          landing table,          insert batch size)
    ("regions.csv",       "landing.Regions",         1_000),
    ("categories.csv",    "landing.Categories",      1_000),
    ("suppliers.csv",     "landing.Suppliers",       1_000),
    ("products.csv",      "landing.Products",        5_000),
    ("stores.csv",        "landing.Stores",          1_000),
    ("employees.csv",     "landing.Employees",       5_000),
    ("customers.csv",     "landing.Customers",      10_000),
    ("orders.csv",        "landing.Orders",         10_000),
    ("order_details.csv", "landing.OrderDetails",   20_000),
    ("returns.csv",       "landing.Returns",        10_000),
    ("shipping.csv",      "landing.Shipping",       10_000),
    ("inventory.csv",     "landing.Inventory",      20_000),
]


def build_engine():
    """Create a SQLAlchemy engine for RetailDW using Windows auth.

    WHY fast_executemany=True: pyodbc otherwise sends one INSERT round-trip per
    row. With ~660K rows across 12 files that is unusably slow. fast_executemany
    batches parameters into a single call, turning a multi-minute load into
    seconds. It is the single most important performance switch here.
    """
    odbc_connect = (
        f"DRIVER={{{DRIVER}}};"
        f"SERVER={SERVER};"
        f"DATABASE={DATABASE};"
        "Trusted_Connection=yes;"      # Windows integrated auth (no password)
        "Encrypt=yes;"                 # Driver 18 default; be explicit
        "TrustServerCertificate=yes;"  # accept local self-signed cert
    )
    url = f"mssql+pyodbc:///?odbc_connect={odbc_connect}"
    return create_engine(url, fast_executemany=True)


def load_table(engine, csv_file: str, table: str, batch: int) -> tuple[int, int]:
    """Truncate one landing table and reload it from its CSV.

    Returns (csv_rows, table_rows) so the caller can assert they match.
    """
    csv_path = DATASET_DIR / csv_file
    if not csv_path.exists():
        raise FileNotFoundError(f"Missing source CSV: {csv_path}")

    # Read EVERYTHING as string. Landing is schema-on-read: we must not let
    # pandas guess types (which would turn '' into NaN, drop leading zeros,
    # or coerce dates) - the staging ETL owns all typing decisions.
    # keep_default_na=False keeps empty cells as '' rather than NaN so the
    # raw "missing email" defect (DEF-01) survives intact into landing.
    df = pd.read_csv(csv_path, dtype=str, keep_default_na=False)
    csv_rows = len(df)

    schema, tbl = table.split(".", 1)

    with engine.begin() as conn:
        # Idempotent reload: wipe the table so re-running never double-loads.
        conn.execute(text(f"TRUNCATE TABLE {table};"))

    # Append: pandas lists only the DataFrame's columns in the INSERT, so the
    # _LoadedAt / _SourceFile metadata columns fall back to their DEFAULTs.
    df.to_sql(
        name=tbl,
        con=engine,
        schema=schema,
        if_exists="append",
        index=False,
        chunksize=batch,
        method=None,  # plain executemany + fast_executemany engine flag
    )

    with engine.connect() as conn:
        table_rows = conn.execute(text(f"SELECT COUNT(*) FROM {table};")).scalar_one()

    return csv_rows, table_rows


def main() -> int:
    print("=" * 70)
    print("  LANDING LOADER  |  Dataset/*.csv  ->  RetailDW.landing.*")
    print(f"  Source : {DATASET_DIR}")
    print(f"  Target : {SERVER} / {DATABASE}  (Windows auth, {DRIVER})")
    print("=" * 70)

    engine = build_engine()

    grand_total = 0
    failures: list[str] = []
    t0 = time.perf_counter()

    for csv_file, table, batch in CSV_TO_TABLE:
        start = time.perf_counter()
        try:
            csv_rows, table_rows = load_table(engine, csv_file, table, batch)
        except Exception as exc:  # surface which table broke, keep going
            failures.append(f"{table}: {exc}")
            print(f"  [FAIL] {table:<26} {exc}")
            continue

        elapsed = time.perf_counter() - start
        status = "OK" if csv_rows == table_rows else "ROW MISMATCH"
        grand_total += table_rows
        print(
            f"  [{status:>12}] {table:<26} "
            f"csv={csv_rows:>8,}  loaded={table_rows:>8,}  ({elapsed:5.1f}s)"
        )

    total_elapsed = time.perf_counter() - t0
    print("-" * 70)
    print(f"  TOTAL rows loaded: {grand_total:,}  in {total_elapsed:0.1f}s")

    if failures:
        print(f"  {len(failures)} TABLE(S) FAILED:")
        for f in failures:
            print(f"    - {f}")
        print("=" * 70)
        return 1

    print("  Landing load complete. Next: EXEC staging.usp_LoadAll_LandingToStaging")
    print("=" * 70)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
