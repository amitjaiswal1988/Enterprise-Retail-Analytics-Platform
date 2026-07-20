# 09 — Phase Summary

## What Was Done in Each Phase — Timeline & Deliverables

---

## Phase 1: Business Understanding ✅

| Attribute | Details |
|-----------|---------|
| **Objective** | Understand the business before writing any code |
| **Duration** | Day 1 |
| **Key Output** | Business Requirement Document (BRD) |

### What We Did
1. Defined ShopStar Retail as our simulated enterprise retailer
2. Documented business model (Brick & Mortar + E-commerce)
3. Defined 20+ KPIs across 4 categories (Financial, Operational, Customer, Employee)
4. Mapped 10 stakeholders with their reporting needs
5. Wrote 15 Functional Requirements (dashboards, drill-downs, etc.)
6. Wrote Non-Functional Requirements (performance, security, scalability)
7. Created full BRD document (400+ lines)

### Files Created
- `Documentation/Business_Requirement_Document_BRD.md`

### Interview Value
- "How do you gather BI requirements?" → Stakeholder mapping, KPI definition
- "What comes before building dashboards?" → Business understanding

---

## Phase 2: Dataset Selection & Generation ✅

| Attribute | Details |
|-----------|---------|
| **Objective** | Create realistic enterprise-scale synthetic data |
| **Duration** | Day 1-2 |
| **Key Output** | Python generator + 68 automated tests |
| **GitHub PR** | #1 — feat/dataset-generator (Merged) |

### What We Did
1. Evaluated 5 Kaggle datasets (Superstore, Olist, UCI Retail, etc.)
2. Decided on hybrid approach: Python-generated synthetic data
3. Built `generate_dataset.py` with 2 profiles (dev: 50K, prod: 500K orders)
4. Designed 7 intentional data quality defects
5. Documented each defect with expected staging treatment
6. Created 68 automated tests covering schema, volume, integrity, defects
7. Set up professional .gitignore and folder structure
8. Replaced HPE branding with ShopStar Retail

### Files Created
- `Python/generate_dataset.py` — Main generator (653 lines)
- `Python/requirements.txt` — Dependencies
- `Documentation/Data_Generation_Spec.md` — Defect catalog
- `tests/test_data_quality.py` — 68 tests
- `.gitignore` — Proper exclusions
- All `.gitkeep` placeholder files

### Technical Decisions & Why
| Decision | Reason |
|----------|--------|
| Python not Kaggle dataset | More control, realistic defects, enterprise scale |
| Deterministic seed (42) | Reproducibility — same data every run |
| 2 profiles | Fast iteration (dev) + real testing (prod) |
| Intentional defects | Demonstrates ETL skills in Phase 4 |
| 12 separate files | Simulates multiple source systems (like real enterprise) |

---

## Phase 3: Database Design (SQL Server) ✅

| Attribute | Details |
|-----------|---------|
| **Objective** | Create the `RetailDW` database with a 3-layer architecture (Landing → Staging → Warehouse) |
| **Duration** | Day 2 |
| **Key Output** | DDL scripts for all schemas, tables, indexes, and foreign keys |
| **Status** | ✅ Complete |

### What We Did
1. Created database `RetailDW` with three schemas: `landing`, `staging`, `warehouse`
2. Built 12 `landing.*` raw-ingestion tables (all-string, with `_LoadedAt`/`_SourceFile` metadata)
3. Built 13 `staging.*` cleaned/typed tables plus a `Quarantine` table for rejected rows
4. Designed the Kimball star schema: 8 dimensions + 3 facts (11 `warehouse.*` tables)
5. Added surrogate keys (IDENTITY), a seeded `-1` "Unknown" member per dimension
6. Created indexes and all fact→dimension foreign keys

### Files Created
- `SQL/00_Create_Database.sql` — Database + schemas
- `SQL/01_Landing_Tables.sql` — 12 landing tables
- `SQL/02_Staging_Tables.sql` — 13 staging tables + Quarantine
- `SQL/03_Dimension_Tables.sql` — 8 dimensions + `-1` seed
- `SQL/04_Fact_Tables.sql` — FactSales, FactReturns, FactInventory
- `SQL/05_Indexes_And_ForeignKeys.sql` — Indexes + FKs

### Verified
Schema counts: **landing = 12, staging = 13, warehouse = 11.**

---

## Phase 4: Data Cleaning (ETL) ✅

| Attribute | Details |
|-----------|---------|
| **Objective** | Load raw CSVs into Landing, then clean/validate into Staging |
| **Duration** | Day 2 |
| **Key Output** | Python bulk loader + 12 staging ETL procedures |
| **Status** | ✅ Complete |

### What We Did
1. Built `Python/load_landing.py` — bulk-loads 12 CSVs into `landing.*` (**705,984 rows** in ~30s) using pandas + SQLAlchemy + pyodbc (`fast_executemany`)
2. Built `SQL/Stored Procedures/06_ETL_Landing_To_Staging.sql` — 12 load procs + master `staging.usp_LoadAll_LandingToStaging`
3. Applied type-safe casts, trimming, de-duplication, and defect routing to `staging.Quarantine`
4. Fixed 3 ETL bugs found during execution (see Issues Log ISS-010/011/012)

### Files Created
- `Python/load_landing.py` — Landing bulk loader
- `SQL/Stored Procedures/06_ETL_Landing_To_Staging.sql` — Staging ETL

### Verified
**705,735 rows** loaded to staging. Defects captured — DEF-01: 1012, DEF-02: 249, DEF-03: 44, DEF-04: 380, DEF-06: 204.

---

## Phase 5: Data Warehouse (Star Schema) ✅

| Attribute | Details |
|-----------|---------|
| **Objective** | Populate the star schema from Staging + build reporting views |
| **Duration** | Day 2 |
| **Key Output** | Warehouse ETL procedures + 10 analytics views |
| **Status** | ✅ Complete |

### What We Did
1. Built `SQL/Stored Procedures/07_ETL_Staging_To_Warehouse.sql` — DimDate generator, 7 dimension loaders, 3 fact loaders + master proc
2. Routed orphan facts to the `-1` Unknown member via `LEFT JOIN + ISNULL(sk,-1)`
3. Built `SQL/Views/08_Analytics_Views.sql` — 10 business-facing views (one per BRD dashboard)
4. Verified fact surrogate-key distributions (not just counts) — caught the nullable-int float bug (ISS-012)

### Files Created
- `SQL/Stored Procedures/07_ETL_Staging_To_Warehouse.sql` — Warehouse ETL
- `SQL/Views/08_Analytics_Views.sql` — 10 analytics views
- `Documentation/Phase3_Warehouse_Load.md`, `Documentation/Phase3_Analytics_Views.md`

### Verified
Warehouse populated: DimDate 2557, DimRegion 5, DimCategory 26, DimSupplier 101, DimStore 51, DimEmployee 1001, DimCustomer 20001, DimProduct 2001, FactSales 201282, FactReturns 8571, FactInventory 400000. **Revenue $720,097,230, Gross Margin 16.83%, 0 broken fact→DimDate FKs.** Store/online split ~60/40. All 10 views execute and return sensible data (repeat-customer rate 77.44%).

---

## Phase 6: Power BI Data Model ✅

| Attribute | Details |
|-----------|---------|
| **Objective** | Shape the SQL Star Schema into a clean Power BI semantic model |
| **Duration** | Day 3 |
| **Key Output** | Power Query (M) ETL layer + data modeling best-practice guide |
| **Status** | ✅ Complete |

### What We Did
1. Authored the complete **Power Query (M)** layer — one query per `warehouse.*`
   table: connect, remove `_LoadedAt`, drop PII (`Email`), set explicit types,
   mark `DimDate` as the date table
2. Documented **query folding** (what folds, what breaks it, how to verify) and
   **incremental refresh** (`RangeStart`/`RangeEnd` params + folding date filter)
3. Wrote **Data Modeling Best Practices**: star schema wiring, 1:Many/Single
   cardinality, cross-filter direction, hierarchies, display folders, the
   `_Measures` table pattern, hidden keys, performance, composite & aggregation
   models

### Files Created
- `Power BI/PowerQuery_M_Code_Complete.md` — full M ETL layer (commented)
- `Documentation/Data_Modeling_Best_Practices.md` — modeling playbook

---

## Phase 7: Advanced DAX (100 Measures) ✅

| Attribute | Details |
|-----------|---------|
| **Objective** | Implement all 15 BRD KPIs plus advanced analytics as DAX measures |
| **Duration** | Day 3 |
| **Key Output** | 100 documented DAX measures across 5 files |
| **Status** | ✅ Complete |

### What We Did
1. `DAX/01_Revenue_And_Sales_Measures.dax` — **25** measures (revenue, AOV, YTD/
   QTD/MTD, YoY/MoM, rolling & moving averages, channel split, dynamic title)
2. `DAX/02_Profitability_Measures.dax` — **15** measures (COGS, gross profit &
   margin, discounts, net revenue, margin RAG vs 35% target)
3. `DAX/03_Customer_Analytics_Measures.dax` — **20** measures (retention, repeat
   rate, CLV, RFM scoring & segments, cohorts, churn)
4. `DAX/04_Inventory_Returns_Measures.dax` — **20** measures (semi-additive stock
   via `LASTNONBLANK`, turnover, DIO, stockout & return rates, RAG statuses)
5. `DAX/05_Advanced_Analytics_Measures.dax` — **20** measures (RANKX, TOPN, ABC/
   Pareto, CAGR, seasonal index, Field Parameters, sparkline)
6. Every measure carries a full header: WHAT / WHY / WHEN / TARGET / Power BI
   visual / dashboard / DAX concept / interview tip / line-by-line explanation
7. All measures reference the exact `warehouse.*` column names (verified against
   `04_Fact_Tables.sql` and `03_Dimension_Tables.sql`) and the `Store` /
   `E-commerce` channel values

### Files Created
- `DAX/01_..05_*.dax` — 100 measures total
- `Documentation/PowerBI_Service_Complete_Guide.md` — Service deployment + RLS

### Verified
**100 measures** implementing all **15 BRD KPIs** with Red/Amber/Green status
measures vs targets. Revenue definition centralized in `[Total Revenue]` and
reused throughout for a single source of truth.

---

## Phases 8-14: Upcoming

| Phase | Status | Depends On |
|-------|--------|-----------|
| 8 — Dashboard Development (9) | Pending | Phase 7 |
| 9 — Power BI Service Deploy | Pending | Phase 8 |
| 10 — Row-Level Security | Pending | Phase 9 |
| 11 — Performance Optimization | Pending | Phase 10 |
| 12 — Full Documentation | Pending | Phase 11 |
| 13 — GitHub Portfolio Polish | Pending | Phase 12 |
| 14 — Interview Preparation | Ongoing | All |

---

## Git History (Commits & PRs)

| # | PR/Commit | What Was Delivered |
|---|-----------|-------------------|
| 1 | Initial commit (main) | README, LICENSE, BRD, folder structure |
| 2 | PR #1: feat/dataset-generator | Generator, tests, .gitignore, rebranding |
| 3 | PR #2: docs/developer-setup-guide | Setup documentation |
| 4 | PR #3: docs/step-by-step-guides | This Guides/ folder |
| 5 | `8b70dea` | Landing bulk loader + Staging ETL (Phase 4) |
| 6 | `1031b1b` | Warehouse star-schema ETL (Phase 5) |
| 7 | `10f10aa` | 10 analytics views over the star schema (Phase 5) |
| 8 | `8e77f2f` | README + Guides phase status update (Phase 3/4/5 complete) |
| 9 | (this commit) | 100 SQL practice queries + 15 analytics views + Power BI Implementation Guide (Phase 5.5) |

---

*This document will be updated as each phase completes.*
