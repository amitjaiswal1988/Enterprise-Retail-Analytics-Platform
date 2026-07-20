# 12 — Phase 3 Interview Guide

## Data Warehouse Design — Interview Questions & Answers

---

| Document Control | Details |
|-----------------|---------|
| **Document ID** | INTERVIEW-P3-2026-001 |
| **Phase** | Phase 3 — Database Design |
| **Topics** | Star Schema, ETL, Indexing, Data Quality, SQL Server |
| **Difficulty** | Senior Data Analyst / BI Developer level |
| **Total Questions** | 30 |

---

## Section 1: Architecture & Design (10 Questions)

---

### Q1: "Explain your data warehouse architecture."

**Answer:**

> "I designed a 3-layer architecture in SQL Server:
>
> **Landing** — Raw data exactly as it comes from source CSVs. All columns are VARCHAR with no constraints. Purpose: never lose source data.
>
> **Staging** — Cleaned and validated data. Proper data types (INT, DATE, DECIMAL), primary keys, CHECK constraints, computed columns. Purpose: single point of quality enforcement.
>
> **Warehouse** — Kimball-style Star Schema with surrogate keys, 8 dimensions, 3 fact tables. Purpose: optimized for Power BI analytical queries.
>
> This separation gives us audit trail (landing), quality control (staging), and performance (warehouse)."

**Why this is a good answer:**
- Shows understanding of ELT pattern
- Mentions industry-standard methodology (Kimball)
- Explains PURPOSE of each layer (not just what it is)

---

### Q2: "Why Star Schema and not Snowflake?"

**Answer:**

> "Star Schema for three reasons:
> 1. **Fewer JOINs** — Power BI generates DAX that translates to SQL. Star Schema means 1 JOIN per dimension vs multiple in Snowflake.
> 2. **VertiPaq optimization** — Power BI's in-memory engine is designed for wide, denormalized dimension tables.
> 3. **Simpler DAX** — RELATED() function works naturally with star relationships. Snowflake requires bridge tables and USERELATIONSHIP().
>
> Snowflake would only make sense if we had extreme dimension table sizes (100M+ rows) where normalization saves significant storage — not the case here."

---

### Q3: "What is the grain of your fact table?"

**Answer:**

> "**FactSales grain:** One row per order line item (OrderDetail level). If a customer buys 3 products in one order, that creates 3 rows in FactSales. This is the lowest granularity that supports all our reporting needs.
>
> **FactInventory grain:** One row per product, per store, per snapshot date. This is a periodic snapshot — capturing stock levels at specific points in time.
>
> **FactReturns grain:** One row per returned line item."

**Why grain matters:**
- Determines what questions you can answer
- Too high = can't drill down
- Too low = unnecessary complexity
- #1 most asked data warehouse interview question

---

### Q4: "What's a surrogate key and why use it?"

**Answer:**

> "A surrogate key is a system-generated integer (IDENTITY column) that has NO business meaning. Example: `CustomerSK INT IDENTITY(1,1)`.
>
> Why use it:
> 1. **Source independence** — if source system changes CustomerID from INT to GUID, our warehouse doesn't break
> 2. **SCD support** — Type 2 slowly changing dimensions create multiple rows per customer. Business key stays same, but each version gets a new SK
> 3. **Performance** — INT joins are faster than VARCHAR joins (4 bytes vs variable)
> 4. **Consistency** — All dimension FKs in fact tables are same type (INT)"

---

### Q5: "How do you handle missing/unknown dimension values?"

**Answer:**

> "I insert an 'Unknown' member row with SK = -1 in every dimension table BEFORE loading facts. Example:
> ```sql
> INSERT INTO DimProduct (ProductSK, ProductID, ProductName, ...)
> VALUES (-1, -1, 'Unknown Product', ...);
> ```
>
> When a fact row references a product that doesn't exist in the dimension (orphan FK), it gets assigned SK = -1 instead of NULL.
>
> Benefits:
> - No NULL foreign keys in fact tables (cleaner model)
> - Reports show 'Unknown' instead of blank (better UX)
> - SUM and COUNT include these rows (NULLs get excluded silently)"

---

### Q6: "What's the difference between additive, semi-additive, and non-additive measures?"

**Answer:**

> "**Additive** (FactSales.LineTotal): Can SUM across ALL dimensions including time. Revenue on Monday + Tuesday = Total Revenue. Most measures are additive.
>
> **Semi-additive** (FactInventory.QuantityOnHand): Can SUM across products and stores, but NOT across time. Stock on Jan 1 + Stock on Jan 2 ≠ meaningful number. Use LASTNONBLANK or AVERAGE across dates.
>
> **Non-additive** (Ratios, percentages): Gross Margin % cannot be summed — must be recalculated from components at each aggregation level."

---

### Q7: "Why did you use schemas instead of separate databases?"

**Answer:**

> "Single database with 3 schemas (landing/staging/warehouse) because:
> 1. **Cross-schema JOINs** — ETL procs can JOIN landing to staging without linked servers
> 2. **Single backup** — One backup covers entire pipeline
> 3. **Transaction consistency** — Cross-schema transactions are straightforward
> 4. **Simpler permissions** — GRANT/DENY at schema level
> 5. **Resource sharing** — One tempdb, one buffer pool
>
> Separate databases make sense when teams/SLAs are different or cross-server replication is needed."

---

### Q8: "Explain your Quarantine table design."

**Answer:**

> "I created `staging.Quarantine` to capture rows that fail validation without silently dropping them:
> ```sql
> CREATE TABLE staging.Quarantine (
>     QuarantineID    INT IDENTITY PRIMARY KEY,
>     SourceTable     VARCHAR(50),       -- Which table it came from
>     SourceRowData   NVARCHAR(MAX),     -- JSON of the bad row
>     DefectType      VARCHAR(50),       -- DEF-03, DEF-04, etc.
>     DefectDetail    NVARCHAR(500),     -- Human-readable explanation
>     QuarantinedAt   DATETIME2,
>     ResolvedAt      DATETIME2 NULL,    -- When someone fixed it
>     Resolution      VARCHAR(50) NULL   -- Fixed / Deleted / Accepted
> );
> ```
>
> Enterprise value: Data stewards can review quarantined rows, fix source systems, and re-process. Nothing is lost."

---

### Q9: "What is a computed/persisted column?"

**Answer:**

> "A computed column is calculated automatically from other columns in the same row. PERSISTED means it's physically stored on disk (not recalculated every read).
>
> Examples in my design:
> - `GrossMargin AS (UnitPrice - UnitCost) PERSISTED`
> - `PriceRange AS (CASE WHEN UnitPrice >= 500 THEN 'Premium' ... END) PERSISTED`
> - `IsLowStock AS (CASE WHEN QtyOnHand <= ReorderPoint THEN 1 ELSE 0 END) PERSISTED`
>
> Benefits:
> - No DAX needed for these calculations (already in data)
> - Indexable (can create index on PriceRange)
> - Consistent definition (everyone uses same logic)"

---

### Q10: "Why SIMPLE recovery model?"

**Answer:**

> "For a development/portfolio project, SIMPLE recovery:
> - Minimizes log file growth (no log chain)
> - Faster checkpoints
> - Simpler maintenance
>
> In **production**, I would use FULL recovery for point-in-time restore capability. But for a data warehouse that can always be reloaded from source, SIMPLE is acceptable even in prod (since the source system has the log, not the DW)."

---

## Section 2: ETL & Data Quality (10 Questions)

---

### Q11: "How do you handle duplicate records?"

**Answer:**

> "Using ROW_NUMBER() window function:
> ```sql
> ;WITH Deduplicated AS (
>     SELECT *,
>         ROW_NUMBER() OVER (
>             PARTITION BY OrderID, CustomerID, OrderDate
>             ORDER BY _LoadedAt ASC
>         ) AS rn
>     FROM landing.Orders
> )
> INSERT INTO staging.Orders
> SELECT ... FROM Deduplicated WHERE rn = 1;
> ```
>
> This keeps the FIRST occurrence (earliest load timestamp) and discards later duplicates. The PARTITION BY defines what 'duplicate' means (same order + customer + date)."

---

### Q12: "How do you handle NULL values?"

**Answer:**

> "Depends on business context:
> 1. **Valid NULL** (orders.StoreID for e-commerce) — Keep as NULL, it's meaningful
> 2. **Data quality issue** (customers.Email missing) — Keep NULL but FLAG with `_IsEmailMissing = 1` for visibility
> 3. **Required field** (OrderDate) — If NULL after TRY_CAST, quarantine the entire row
>
> I never replace NULLs with magic values like -1 or 'N/A' in staging. That happens only in the warehouse Unknown member pattern."

---

### Q13: "What is TRY_CAST and why use it?"

**Answer:**

> "`TRY_CAST` attempts a type conversion and returns NULL on failure (instead of erroring):
> ```sql
> TRY_CAST('abc' AS INT)  -- Returns NULL (not error)
> CAST('abc' AS INT)       -- Throws ERROR
> ```
>
> I use it in ETL for safe type conversion from VARCHAR landing columns:
> ```sql
> WHERE TRY_CAST(OrderDate AS DATE) IS NOT NULL  -- Only load valid dates
> ```
>
> Rows where TRY_CAST returns NULL are sent to quarantine."

---

### Q14: "What's your ETL execution order and why?"

**Answer:**

> "4 dependency layers:
> 1. **Reference dimensions** (Regions, Categories, Suppliers) — no dependencies
> 2. **Entity dimensions** (Stores, Employees, Products, Customers) — depend on layer 1
> 3. **Transactions** (Orders, OrderDetails) — depend on layer 2
> 4. **Related facts** (Returns, Shipping, Inventory) — depend on layer 3
>
> Why: Foreign key checks in staging need parent tables loaded first. Can't validate CustomerID in Orders if Customers isn't loaded yet."

---

### Q15: "How do you normalize inconsistent data?"

**Answer:**

> "For DEF-05 (category casing: 'ELECTRONICS' vs 'electronics' vs 'Electronics'):
> ```sql
> CASE UPPER(LTRIM(RTRIM(CategoryName)))
>     WHEN 'ELECTRONICS'           THEN 'Electronics'
>     WHEN 'HOME & KITCHEN'        THEN 'Home & Kitchen'
>     WHEN 'OFFICE SUPPLIES'       THEN 'Office Supplies'
>     ...
>     ELSE LTRIM(RTRIM(CategoryName))  -- Keep unknown as-is
> END
> ```
>
> I normalize to UPPER first (handles all variations), then map to canonical Title Case. Unknown values pass through for manual review."

---

### Q16: "TRUNCATE vs DELETE in ETL — which and why?"

**Answer:**

> "I use `TRUNCATE TABLE staging.Orders` at the start of each ETL run:
> - **TRUNCATE** — Minimal logging, resets identity, instant on large tables
> - **DELETE** — Fully logged, row-by-row, maintains identity counter
>
> TRUNCATE is safe here because we're doing full reload (not incremental). In production incremental loads, I'd use MERGE or DELETE WHERE."

---

### Q17: "What's the difference between CAST and CONVERT?"

**Answer:**

> "Both convert types but:
> - `CAST(x AS DATE)` — ANSI standard, portable across databases
> - `CONVERT(DATE, x, 120)` — SQL Server specific, supports style codes for date formatting
>
> I prefer CAST for type conversion (standard) and CONVERT only when specific date/time formatting is needed (e.g., `CONVERT(VARCHAR, GETDATE(), 120)` for ISO format)."

---

### Q18: "What happens if ETL fails midway?"

**Answer:**

> "My design handles this through:
> 1. **TRUNCATE at start** — staging is either fully old or fully new, never half
> 2. **Landing preserved** — raw data never deleted, can always re-run
> 3. **Quarantine captures errors** — bad rows don't crash the pipeline
> 4. **Master orchestrator** — runs procs in sequence, prints progress, can be wrapped in TRY/CATCH
>
> For production, I'd add: BEGIN TRANSACTION with explicit COMMIT/ROLLBACK, error logging table, and SQL Agent alerting."

---

### Q19: "How do you validate referential integrity in ETL?"

**Answer:**

> "LEFT JOIN pattern to detect orphan references:
> ```sql
> SELECT od.*, 
>     CASE WHEN p.ProductID IS NULL THEN 1 ELSE 0 END AS _IsOrphanProduct
> FROM landing.OrderDetails od
> LEFT JOIN staging.Products p ON TRY_CAST(od.ProductID AS INT) = p.ProductID
> ```
>
> Orphan rows are LOADED (not rejected) but FLAGGED. In the warehouse, they reference DimProduct SK=-1 ('Unknown Product'). This preserves revenue data while highlighting data quality gaps."

---

### Q20: "What's a master/orchestrator stored procedure?"

**Answer:**

> "`staging.usp_LoadAll_LandingToStaging` executes all 12 individual load procedures in correct order:
> ```sql
> EXEC staging.usp_Load_Regions;
> EXEC staging.usp_Load_Categories;
> ...
> EXEC staging.usp_Load_Inventory;
> ```
>
> Benefits:
> - One command to run entire ETL (`EXEC staging.usp_LoadAll_LandingToStaging`)
> - SQL Agent can schedule it (daily at 5 AM)
> - Execution timing tracked (start/end, duration)
> - Quarantine count reported at end"

---

## Section 3: Performance & Optimization (10 Questions)

---

### Q21: "Why did you create columnstore indexes?"

**Answer:**

> "Columnstore indexes store data column-by-column (not row-by-row). Benefits for BI:
> 1. **10x compression** — 2GB fact table becomes 200MB
> 2. **Batch mode processing** — SQL Server processes 900 rows at once vs 1 row (row mode)
> 3. **Segment elimination** — only reads columns referenced in query
>
> Perfect for Power BI which generates queries like `SELECT DateKey, SUM(LineTotal) FROM FactSales GROUP BY DateKey` — this touches only 2 columns out of 15."

---

### Q22: "What's a covering index?"

**Answer:**

> "An index that contains ALL columns needed by a query in its INCLUDE clause:
> ```sql
> CREATE INDEX IX_FactSales_DateKey
>     ON FactSales (OrderDateKey)
>     INCLUDE (LineTotal, GrossProfit, Quantity);
> ```
>
> If Power BI queries `WHERE OrderDateKey = 20230615` and selects `LineTotal, GrossProfit`, this index covers the entire query — no bookmark lookup to the base table needed. This is a key lookup elimination pattern."

---

### Q23: "What's a filtered index?"

**Answer:**

> "An index with a WHERE clause — only indexes subset of rows:
> ```sql
> CREATE INDEX IX_FactInventory_LowStock
>     ON FactInventory (IsLowStock, IsOutOfStock)
>     WHERE IsLowStock = 1 OR IsOutOfStock = 1;
> ```
>
> Only ~5% of inventory rows are low stock. This index is tiny but fast for alert queries like 'show me all out-of-stock items'. Full index would be wasteful."

---

### Q24: "How does DateKey as INT help performance?"

**Answer:**

> "Using INT (YYYYMMDD format, e.g., 20230615) instead of DATE type:
> 1. **4 bytes vs 3 bytes** — DATE is 3 bytes, INT is 4 — negligible difference
> 2. **Partition-friendly** — `WHERE DateKey BETWEEN 20230101 AND 20231231` does efficient range scan
> 3. **No time component** — eliminates midnight issues
> 4. **Power BI optimization** — Mark as Date Table works naturally with INT key
> 5. **Human readable** — Developers can read 20230615 without conversion"

---

### Q25: "IDENTITY vs SEQUENCE for surrogate keys?"

**Answer:**

> "I used IDENTITY(1,1) because:
> - Simpler syntax — automatic on INSERT
> - One table = one counter (no conflicts)
> - 99% of dimension loading uses it
>
> SEQUENCE is better when:
> - Multiple tables share one counter
> - Need to generate keys BEFORE insert (batch operations)
> - Need to reserve ranges for parallel loading"

---

### Q26: "How do you ensure Power BI performance with 2M rows?"

**Answer:**

> "Multi-layer approach:
> 1. **Star Schema** — minimizes JOINs (Power BI generates 1 JOIN per dim)
> 2. **INT surrogate keys** — smaller model size (4 bytes vs 50-byte VARCHAR)
> 3. **Pre-calculated measures** — GrossProfit in fact table (not DAX)
> 4. **Columnstore** — 10x compression = fits in RAM
> 5. **Computed dim columns** — PriceRange, StoreSize = instant slicers
> 6. **Remove unused columns** — No email, no address in Power BI model
> 7. **Aggregation tables** (Phase 11) — Monthly rollups for dashboard pages"

---

### Q27: "What's snapshot isolation and why enable it?"

**Answer:**

> "Snapshot isolation allows readers to see a consistent view of data WITHOUT being blocked by writers:
> ```sql
> ALTER DATABASE RetailDW SET ALLOW_SNAPSHOT_ISOLATION ON;
> ```
>
> Without it: Power BI refresh and ETL writing run simultaneously → Power BI gets blocked (waits for ETL lock release).
>
> With it: Power BI reads the last committed version while ETL writes new data. Zero blocking."

---

### Q28: "What's the difference between clustered and non-clustered indexes?"

**Answer:**

> "**Clustered** (1 per table, IS the table):
> - Physically sorts data on disk by the key
> - Primary Key creates one automatically
> - Range scans are very fast (data is contiguous)
>
> **Non-clustered** (up to 999 per table, separate structure):
> - Separate data structure pointing to base table
> - Used for alternate access paths (FK lookups, filters)
> - INCLUDE columns avoid bookmark lookups
>
> My design: PK = clustered on every table. Non-clustered on fact FK columns for dimension joins."

---

### Q29: "Why NOT NULL on all fact table FK columns?"

**Answer:**

> "Two reasons:
> 1. **Data quality guarantee** — every fact row MUST relate to a dimension. No 'homeless' metrics.
> 2. **Query optimizer** — NOT NULL lets SQL Server use INNER JOIN semantics even when LEFT JOIN is written. Better plans.
>
> For e-commerce orders (no StoreID): they don't get NULL — they reference `DimStore SK=-1` ('Unknown/Online'). This maintains NOT NULL while being semantically correct."

---

### Q30: "If you had to redesign, what would you change?"

**Answer:**

> "Three improvements:
> 1. **Add Type 2 SCD on DimCustomer** — track when customers change segments (Consumer → Premium). Currently Type 1 (overwrite).
> 2. **Partitioning FactSales by Year** — enables partition switching for incremental loads (instant load + instant archival).
> 3. **Add FactShipping** — currently shipping data is in staging only. A proper fact would enable delivery performance analytics with date dimension relationships (ShipDateKey, DeliveryDateKey).
>
> These are planned for Phase 11 (Performance Optimization)."

---

## Quick Revision Card

| Concept | One-Line Answer |
|---------|----------------|
| Grain | "Lowest level of detail in a fact table" |
| Surrogate Key | "System-generated INT, decouples from source" |
| Star Schema | "One fact table surrounded by denormalized dimensions" |
| Unknown Member | "SK=-1 row in dims for orphan FK handling" |
| Semi-additive | "Can SUM across all dims EXCEPT time" |
| Columnstore | "Column-oriented storage, 10x compression, batch mode" |
| Covering Index | "Index + INCLUDE has all columns query needs" |
| Quarantine | "Error table for rows that fail validation" |
| TRY_CAST | "Safe type conversion — returns NULL on failure" |
| ELT vs ETL | "ELT loads first then transforms (our approach)" |

---

*This document will be expanded with Phase 4-14 interview questions as each phase completes.*
