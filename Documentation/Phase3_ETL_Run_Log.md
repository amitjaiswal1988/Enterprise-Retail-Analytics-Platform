# Phase 3 — ETL Run Log: Landing → Staging

**Author:** BI Development Team
**Date:** 2026-07-21
**Scope:** Loading raw CSVs into the `landing` layer and transforming them into the cleaned `staging` layer of `RetailDW`.
**Status:** ✅ Completed & verified

> This document records **WHEN, WHY, WHAT, and HOW (mode)** for every operation in this
> step, so the pipeline is fully reproducible and auditable — as expected of a BI /
> analytics engineering deliverable.

---

## 1. Where this fits in the pipeline

```
CSV files (Dataset/)
      │  (E-L)  Python: load_landing.py
      ▼
[landing.*]   ← raw, all VARCHAR, "load as-is" (schema-on-read)
      │  (T)   SQL: staging.usp_LoadAll_LandingToStaging
      ▼
[staging.*]   ← typed, cleaned, deduplicated, defect-flagged
      │  (next phase) Warehouse load (dims + facts)
      ▼
[warehouse.*] ← star schema (already built: 8 dims + 3 facts)
```

This step is the **E-L-T** middle: Extract+Load in Python, Transform in SQL Server.

---

## 2. Step 1 — Load CSVs into Landing (Python)

| Field | Detail |
|-------|--------|
| **WHEN** | Phase 3, after `01_Landing_Tables.sql` created the empty landing tables. |
| **WHY** | Get raw data into SQL Server **without any transformation**, preserving deliberate data-quality defects so the staging ETL can be tested against them. |
| **WHAT** | Bulk-loads all 12 `Dataset/*.csv` files into `landing.*`. |
| **MODE / HOW** | Python (`pandas` + `SQLAlchemy` + `pyodbc`, `fast_executemany`), Windows auth, ODBC Driver 18. |
| **Script** | [Python/load_landing.py](../Python/load_landing.py) |
| **Command** | `(.venv) python Python/load_landing.py` |

### Why Python instead of `BULK INSERT` / `bcp`
1. Landing tables carry two extra metadata columns (`_LoadedAt DEFAULT GETDATE()`,
   `_SourceFile DEFAULT '<file>.csv'`). A positional `BULK INSERT` would fail on the
   column-count mismatch unless we authored 12 format files. `pandas.to_sql` lists only
   the CSV columns in its `INSERT`, so those two columns fall through to their `DEFAULT`s.
2. Every value is read as **string** (`dtype=str`, `keep_default_na=False`) — no silent
   type coercion — so the raw defects survive intact into landing.
3. Each table is `TRUNCATE`d first → **idempotent, safely re-runnable**.

### Result
| Table | Rows | Table | Rows |
|-------|-----:|-------|-----:|
| Regions | 4 | Customers | 20,000 |
| Categories | 25 | Orders | 50,250 |
| Suppliers | 100 | OrderDetails | 201,473 |
| Products | 2,000 | Returns | 8,578 |
| Stores | 50 | Shipping | 22,504 |
| Employees | 1,000 | Inventory | 400,000 |
| **Total** | | | **705,984** |

---

## 3. Step 2 — Transform Landing → Staging (SQL)

| Field | Detail |
|-------|--------|
| **WHEN** | Immediately after the landing load. |
| **WHY** | Convert raw text to correct types, enforce keys/constraints, deduplicate, and quarantine/flag bad data before it can reach the warehouse. |
| **WHAT** | 12 load procedures + 1 orchestrator, one per source table. |
| **MODE / HOW** | T-SQL stored procedures executed via `sqlcmd` (Windows auth, `-C` trust cert). |
| **Script** | [SQL/Stored Procedures/06_ETL_Landing_To_Staging.sql](../SQL/Stored%20Procedures/06_ETL_Landing_To_Staging.sql) |
| **Command** | `sqlcmd -S localhost -E -C -d RetailDW -b -Q "EXEC staging.usp_LoadAll_LandingToStaging;"` |

### Execution order (dependency layers)
1. **Reference dims:** Regions → Categories → Suppliers
2. **Entity dims:** Stores → Employees → Products → Customers
3. **Transaction facts:** Orders → OrderDetails
4. **Related facts:** Returns → Shipping → Inventory

### Data-quality rules applied (from BRD defect catalog)
| Defect | Rule | Action | Rows |
|--------|------|--------|-----:|
| DEF-01 | Missing customer email | Flag `_IsEmailMissing = 1` (keep row) | 1,012 |
| DEF-02 | Duplicate orders | Deduplicate via `ROW_NUMBER()` (keep first) | 249 removed |
| DEF-03 | Future order dates (> 2025-12-31) | Move to `staging.Quarantine` | 44 quarantined |
| DEF-04 | Orphan `ProductID` in order details | Flag `_IsOrphanProduct = 1` | 380 |
| DEF-05 | Inconsistent category casing | Normalize casing | 25 rows normalized |
| DEF-06 | Negative quantities | Correct to `ABS()`, flag `_IsQuantityCorrected = 1` | 204 |

### Result
| Layer | Tables | Rows |
|-------|-------:|-----:|
| landing | 12 | 705,984 |
| staging | 13 (12 + Quarantine) | 705,735 |

Row reconciliation: `705,984 − 249 dup orders − 44 future-date orders + 44 quarantine-log rows = 705,735` ✓

---

## 4. Bugs found & fixed during this run

| # | Symptom | Root cause | Fix |
|---|---------|-----------|-----|
| 1 | `Subqueries are not allowed in this context` (master proc) | Subquery embedded inside a `PRINT` string-concat | Moved count into a scalar variable first |
| 2 | `staging.Customers/Orders/OrderDetails loaded: 1 rows` (wrong) | A `SELECT COUNT(*)` after the `INSERT` reset `@@ROWCOUNT` to 1 | Capture `@@ROWCOUNT` into `@RowsLoaded` **immediately** after the `INSERT` |
| 3 | Quarantine count doubled on re-run (44 → 88) | `staging.Quarantine` never cleared between runs | `TRUNCATE TABLE staging.Quarantine` at the start of the master proc (idempotency) |

All three are committed in the SQL scripts.

---

## 5. How to reproduce from scratch

```bash
# 0. (once) create DB + all schemas/tables/procs
sqlcmd -S localhost -E -C -i "SQL/00_Create_Database.sql"
sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Landing/01_Landing_Tables.sql"
sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Staging/02_Staging_Tables.sql"
sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Warehouse/03_Dimension_Tables.sql"
sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Warehouse/04_Fact_Tables.sql"
sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Warehouse/05_Indexes_And_ForeignKeys.sql"
sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Stored Procedures/06_ETL_Landing_To_Staging.sql"

# 1. load raw CSVs -> landing
python Python/load_landing.py

# 2. transform landing -> staging
sqlcmd -S localhost -E -C -d RetailDW -b -Q "EXEC staging.usp_LoadAll_LandingToStaging;"
```

---

## 6. Next step (Phase 3 — final)

Build the **warehouse load** procedures (`staging.* → warehouse.*`):
1. `DimDate` population (calendar generation).
2. Surrogate-key dimension loads (with `-1` "Unknown" member for orphan handling).
3. Fact loads (`FactSales`, `FactReturns`, `FactInventory`) — resolve business keys to
   surrogate keys, route orphans to the `-1` member.
4. Validate fact/dim row counts and referential integrity.
