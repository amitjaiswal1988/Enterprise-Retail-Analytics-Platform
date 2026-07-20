# 13 — Phase 3: SSMS Execution Guide

## Step-by-Step SQL Script Execution in SQL Server Management Studio

---

| Document Control | Details |
|-----------------|---------|
| **Document ID** | EXEC-P3-2026-001 |
| **Phase** | Phase 3 — Database Design |
| **Tool** | SQL Server Management Studio (SSMS 22) |
| **Database** | RetailDW |
| **Total Scripts** | 7 (execute in order) |
| **Total Time** | < 2 minutes |

---

## Pre-Requisites

| # | Requirement | How to Check |
|---|------------|-------------|
| 1 | SQL Server installed & running | `Get-Service MSSQLSERVER` → Status: Running |
| 2 | SSMS installed | Start Menu → search "SSMS" |
| 3 | Project files pulled locally | VS Code: all SQL files in `SQL/` folder |
| 4 | Connected to SQL Server in SSMS | Object Explorer shows localhost |

---

## How to Execute a Script in SSMS

### Method 1: Copy-Paste (Recommended for beginners)

```
1. VS Code mein SQL file open karo
2. Ctrl+A (select all)
3. Ctrl+C (copy)
4. SSMS mein jaao
5. Ctrl+N (new query window)
6. Ctrl+V (paste)
7. F5 (execute)
8. Messages tab mein result dekho
```

### Method 2: File → Open

```
1. SSMS mein: File → Open → File
2. Navigate to: C:\Users\Amit\Documents\Enterprise-Retail-Analytics-Platform\SQL\
3. Select file → Click Open
4. F5 (execute)
```

### Method 3: sqlcmd (Terminal — advanced)

```powershell
sqlcmd -S localhost -E -i "SQL\00_Create_Database.sql"
```

---

## Script 1 of 7: Create Database

---

### WHAT — Kya karta hai ye script?

Creates the `RetailDW` database and 3 schemas (landing, staging, warehouse).

### WHY — Kyun zaruri hai?

| Without This | With This |
|-------------|-----------|
| No database exists | RetailDW database ready |
| Tables kahin bhi banti | 3 organized schemas (layers) |
| No separation of concerns | Landing vs Staging vs Warehouse clearly separated |

### WHEN — Kab execute karna hai?

- **First time only** — sirf ek baar
- Agar database drop kar diya toh dobara
- Production mein: DBA creates this during initial deployment

### HOW — Kaise execute karo?

**SSMS mein New Query (Ctrl+N) → Paste this → F5:**

```sql
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'RetailDW')
BEGIN
    CREATE DATABASE RetailDW;
    PRINT 'Database RetailDW created successfully.';
END
ELSE
BEGIN
    PRINT 'Database RetailDW already exists.';
END
GO

USE RetailDW;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'landing')
    EXEC('CREATE SCHEMA landing');
GO
PRINT 'Schema [landing] ready.';
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'staging')
    EXEC('CREATE SCHEMA staging');
GO
PRINT 'Schema [staging] ready.';
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'warehouse')
    EXEC('CREATE SCHEMA warehouse');
GO
PRINT 'Schema [warehouse] ready.';
GO

ALTER DATABASE RetailDW SET RECOVERY SIMPLE;
GO

PRINT '============================================================';
PRINT '  RetailDW Database Setup Complete';
PRINT '  Schemas: [landing], [staging], [warehouse]';
PRINT '============================================================';
GO
```

### Expected Output (Messages tab):

```
Database RetailDW created successfully.
Schema [landing] ready.
Schema [staging] ready.
Schema [warehouse] ready.
============================================================
  RetailDW Database Setup Complete
  Schemas: [landing], [staging], [warehouse]
============================================================
```

### Verification (Object Explorer):

After F5, press **F5** on Object Explorer OR right-click → Refresh:
```
📁 Databases
  📁 RetailDW  ← NEW! This should appear
```

### Common Errors & Fixes:

| Error | Cause | Fix |
|-------|-------|-----|
| `Incorrect syntax near ')'` | File not fully copied/pasted | Use the simplified version above |
| `Database already exists` | Script ran before | This is OK — it handles IF NOT EXISTS |
| `Cannot open database` | Not connected to server | Reconnect in Object Explorer |

---

## Script 2 of 7: Landing Tables

---

### WHAT — Kya karta hai?

Creates 12 raw ingestion tables in the `[landing]` schema. ALL columns are VARCHAR (no data type enforcement).

### WHY — Kyun sab VARCHAR hai?

| Question | Answer |
|----------|--------|
| Source CSV mein "abc" numeric field mein ho toh? | VARCHAR accepts it — no error |
| Date field mein "N/A" ho toh? | VARCHAR accepts it |
| Empty string ho toh? | VARCHAR accepts it |
| Kya landing table reject karega? | **NEVER** — accept everything |

> **Enterprise Rule:** Landing layer ka kaam hai sirf capture karna. Quality check staging mein hoga.

### WHEN — Kab execute karo?

After Script 1 (database must exist first).

### HOW — Execute karo:

1. SSMS mein: make sure dropdown shows **RetailDW** (not master)
2. File → Open → `SQL\Landing\01_Landing_Tables.sql`
3. **F5**

### Expected Output:

```
Created: landing.Regions
Created: landing.Categories
Created: landing.Suppliers
Created: landing.Products
Created: landing.Stores
Created: landing.Employees
Created: landing.Customers
Created: landing.Orders
Created: landing.OrderDetails
Created: landing.Returns
Created: landing.Shipping
Created: landing.Inventory
============================================================
  Landing Layer Complete — 12 Tables Created
============================================================
```

### ⚠️ IMPORTANT: Database Dropdown

SSMS mein top-left pe ek dropdown hai jo database select karta hai. **Script 2–7 ke liye ye "RetailDW" hona chahiye** (not "master").

Agar "master" selected hai: dropdown click karo → "RetailDW" select karo.

---

## Script 3 of 7: Staging Tables

---

### WHAT — Kya karta hai?

Creates 12 cleaned tables + 1 Quarantine table in `[staging]` schema. Proper data types, PRIMARY KEYs, CHECK constraints, computed columns.

### WHY — Staging kyun alag hai Landing se?

| Feature | Landing | Staging |
|---------|---------|---------|
| Data types | ALL VARCHAR | INT, DATE, DECIMAL (correct) |
| Primary Key | No | Yes (dedup guarantee) |
| Constraints | None | CHECK, NOT NULL |
| Computed columns | None | GrossMargin, FullName, etc. |
| Quality flags | None | _IsEmailMissing, _IsOrphanProduct |

### WHEN — Kab?

After Script 2 (landing tables exist).

### HOW:

1. SSMS → dropdown = "RetailDW"
2. File → Open → `SQL\Staging\02_Staging_Tables.sql`
3. **F5**

### Expected:

```
Created: staging.Regions
Created: staging.Categories
...
Created: staging.Quarantine (error capture table)
============================================================
  Staging Layer Complete — 12 Tables + 1 Quarantine Table
============================================================
```

---

## Script 4 of 7: Dimension Tables

---

### WHAT?

Creates 8 dimension tables in `[warehouse]` schema with surrogate keys and Unknown member (SK=-1).

### WHY Surrogate Keys?

| Without SK | With SK |
|-----------|---------|
| Source changes CustomerID format → warehouse breaks | SK stays same, business key updated separately |
| Can't handle Type 2 SCD (history) | Multiple SK rows per business key = history |
| VARCHAR JOINs (slow) | INT JOINs (fast) |

### WHY Unknown Member (SK=-1)?

| Without Unknown | With Unknown |
|----------------|-------------|
| Orphan FK → NULL in fact | Orphan FK → points to -1 (Unknown) |
| NULL breaks COUNT/SUM | Unknown row included in aggregations |
| Reports show blank | Reports show "Unknown" (visible, debuggable) |

### HOW:

1. SSMS → RetailDW
2. File → Open → `SQL\Warehouse\03_Dimension_Tables.sql`
3. **F5**

### Expected:

```
Created: warehouse.DimDate (role-playing calendar dimension)
Created: warehouse.DimRegion (with Unknown member)
Created: warehouse.DimCategory (with Unknown member)
Created: warehouse.DimSupplier (with derived categories)
Created: warehouse.DimStore (with derived size/age)
Created: warehouse.DimEmployee (with tenure/salary bands)
Created: warehouse.DimCustomer (with tenure/join year)
Created: warehouse.DimProduct (with margin/price range)
============================================================
  Warehouse Dimensions Complete — 8 Tables Created
============================================================
```

---

## Script 5 of 7: Fact Tables

---

### WHAT?

Creates 3 fact tables: FactSales, FactReturns, FactInventory.

### WHY 3 separate facts (not 1)?

| Fact | Grain | Why Separate |
|------|-------|-------------|
| FactSales | Order line item | Every sale transaction |
| FactReturns | Returned item | Different lifecycle (days after sale) |
| FactInventory | Product/Store/Date | Periodic snapshot (different time behavior) |

> Combining them would create a "monster fact" with too many NULLs and conflicting grains.

### HOW:

1. SSMS → RetailDW
2. File → Open → `SQL\Warehouse\04_Fact_Tables.sql`
3. **F5**

### Expected:

```
Created: warehouse.FactSales (grain: order line item)
Created: warehouse.FactReturns (grain: returned line item)
Created: warehouse.FactInventory (grain: product/store/snapshot, periodic)
============================================================
  Warehouse Fact Tables Complete — 3 Tables Created
============================================================
```

---

## Script 6 of 7: Indexes & Foreign Keys

---

### WHAT?

Creates 48 objects: 21 Foreign Keys + 15 Non-clustered indexes + 2 Columnstore + 7 dimension lookups + 1 filtered index.

### WHY Indexes?

| Without Indexes | With Indexes |
|----------------|-------------|
| Power BI query scans 2M rows | Seeks directly to matching rows |
| Dashboard loads in 30 seconds | Dashboard loads in 2 seconds |
| CPU at 100% during refresh | Minimal CPU usage |

### HOW:

1. SSMS → RetailDW
2. File → Open → `SQL\Warehouse\05_Indexes_And_ForeignKeys.sql`
3. **F5**

### Expected:

```
FactSales: 8 Foreign Keys created
FactReturns: 7 Foreign Keys created
FactInventory: 6 Foreign Keys created
FactSales: 8 Non-Clustered indexes created
...
============================================================
  Indexes & Foreign Keys Complete
  Total: 45 index/constraint objects
============================================================
```

---

## Script 7 of 7: ETL Stored Procedures

---

### WHAT?

Creates 13 stored procedures that move data from Landing → Staging (with cleaning).

### WHY Stored Procedures?

| Ad-hoc SQL | Stored Procedures |
|-----------|-------------------|
| Run manually each time | One command: `EXEC staging.usp_LoadAll_LandingToStaging` |
| Can't schedule | SQL Agent can schedule daily |
| No error handling | TRY_CAST, quarantine, flags |
| No audit trail | PRINT statements show progress |

### HOW:

1. SSMS → RetailDW
2. File → Open → `SQL\Stored Procedures\06_ETL_Landing_To_Staging.sql`
3. **F5**

### Expected:

```
============================================================
  ETL Stored Procedures Created — 12 + 1 Master
  Execute: EXEC staging.usp_LoadAll_LandingToStaging
============================================================
```

---

## Final Verification

After all 7 scripts execute, run this in SSMS:

```sql
USE RetailDW;
SELECT 
    s.name AS SchemaName,
    COUNT(*) AS TableCount
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
GROUP BY s.name
ORDER BY s.name;
```

### Expected Result:

| SchemaName | TableCount |
|-----------|-----------|
| landing | 12 |
| staging | 13 |
| warehouse | 11 |

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| "Database RetailDW does not exist" | Script 1 didn't run — execute it first |
| "Invalid object name 'landing.xxx'" | Database dropdown not set to RetailDW |
| "Incorrect syntax near ')'" | File not fully copied — use simplified version |
| "Cannot create schema" | Already exists — this is OK (IF NOT EXISTS handles it) |
| "Permission denied" | Connect with Windows Authentication (admin) |

---

## Copilot Prompts (for each step)

```
@terminal cat "SQL/00_Create_Database.sql" | clip
@terminal cat "SQL/Landing/01_Landing_Tables.sql" | clip
@terminal cat "SQL/Staging/02_Staging_Tables.sql" | clip
@terminal cat "SQL/Warehouse/03_Dimension_Tables.sql" | clip
@terminal cat "SQL/Warehouse/04_Fact_Tables.sql" | clip
@terminal cat "SQL/Warehouse/05_Indexes_And_ForeignKeys.sql" | clip
@terminal cat "SQL/Stored Procedures/06_ETL_Landing_To_Staging.sql" | clip
```

After each: SSMS → Ctrl+N → Ctrl+V → F5

---

*End of Document*
