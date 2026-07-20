# Power Query (M) — Complete ETL Layer for RetailDW

> **Project:** Enterprise Retail Analytics Platform — ShopStar Retail
> **Author:** Amit Jaiswal — Senior BI Engineer
> **Phase:** Phase 6 — Power BI Data Model
> **Purpose:** Every Power Query (M) transformation used to shape the `warehouse.*`
> Star Schema into the Power BI semantic model — fully commented for a junior
> developer's first enterprise BI job.

---

## How to read this guide

Power Query is Power BI's **data preparation** layer. It runs the **Extract →
Transform → Load** steps *before* DAX ever sees the data. Written in the **M**
language, each query is a sequence of **steps**, where every step transforms the
result of the previous one.

Every code block below is annotated with four tags:

| Tag | Meaning |
|-----|---------|
| `// WHAT` | What this step technically does |
| `// WHY` | The business/technical reason it exists |
| `// WHEN` | When it runs (setup vs each refresh) |
| `// QUERY FOLDING: Yes/No` | Whether the step folds to SQL Server (see §3) |

> **Golden rule:** We already did the heavy cleaning in SQL (Landing → Staging →
> Warehouse). Power Query's job here is **light** — connect, pick columns, set
> types, remove PII, and mark the date table. Keep transformations minimal so
> **query folding** (§3) pushes work back to SQL Server.

---

## Table of Contents

1. [Connection to SQL Server](#section-1--connection-to-sql-server)
2. [Each Table's Power Query](#section-2--each-tables-power-query)
3. [Query Folding](#section-3--query-folding)
4. [Incremental Refresh Parameters](#section-4--incremental-refresh-parameters)
5. [Date Table (fallback generator)](#section-5--date-table-fallback-generator)

---

## SECTION 1 — Connection to SQL Server

```m
let
    // WHAT: Open a connection to the SQL Server RetailDW database.
    // WHY:  RetailDW holds our clean Star Schema (warehouse schema). This is
    //       the single source of truth for every visual.
    // WHEN: Runs at initial setup and on every scheduled refresh.
    // QUERY FOLDING: Yes — Sql.Database is a folding-capable connector.
    //
    // NOTE: We DO NOT pass a native SQL query here. Passing hand-written SQL
    //       (the 4th argument [Query=...]) BREAKS folding for downstream steps.
    //       Let Power Query generate SQL by navigating objects instead.
    Source = Sql.Database ( "localhost", "RetailDW" ),

    // WHAT: Navigate into the [warehouse] schema object.
    // WHY:  We only want curated Star Schema tables — never landing/staging,
    //       which contain raw, dirty, all-string data.
    // WHEN: Every refresh.
    // QUERY FOLDING: Yes.
    Warehouse = Source{[Schema = "warehouse"]}[Data],

    // WHAT: Select the FactSales table from the warehouse schema.
    // WHY:  FactSales is our main transaction fact (~200K rows in dev,
    //       ~2M in production).
    // WHEN: Every refresh.
    // QUERY FOLDING: Yes.
    FactSales = Warehouse{[Name = "FactSales"]}[Data]
in
    FactSales
```

> **Best practice — parameterize the server/database.** Hard-coding `"localhost"`
> is fine for local dev but painful across Dev/Test/Prod. Create two parameters
> (`pServerName`, `pDatabaseName`) and call `Sql.Database(pServerName,
> pDatabaseName)`. Deployment Pipelines (see the Service guide, §10) then swap
> them per stage.

---

## SECTION 2 — Each Table's Power Query

Below is the recommended query per model table. The pattern is identical, so the
**first fact is fully commented**; later tables highlight only what differs.

### 2.1 — FactSales (fully commented reference pattern)

```m
let
    // WHAT: Connect + navigate to warehouse.FactSales.
    // WHY:  Main transactional fact table.
    // WHEN: Every refresh.  QUERY FOLDING: Yes.
    Source = Sql.Database ( "localhost", "RetailDW" ),
    FactSales = Source{[Schema = "warehouse", Item = "FactSales"]}[Data],

    // WHAT: Remove the ETL audit column _LoadedAt.
    // WHY:  Audit metadata is irrelevant to analytics and only wastes memory in
    //       the VertiPaq model. Every removed column shrinks the .pbix.
    // WHEN: Every refresh.  QUERY FOLDING: Yes (column projection folds to a
    //       SELECT list — SQL Server drops the column, not Power BI).
    RemovedAudit = Table.RemoveColumns ( FactSales, { "_LoadedAt" } ),

    // WHAT: Set explicit data types on every column.
    // WHY:  Correct types = correct aggregations, smaller model, and folding.
    //       Never leave columns as 'any'. Keys are Int64; money is Currency.
    // WHEN: Every refresh.  QUERY FOLDING: Yes (CAST folds to SQL).
    TypedColumns = Table.TransformColumnTypes (
        RemovedAudit,
        {
            { "SalesFactID", Int64.Type },
            { "OrderDateKey", Int64.Type },
            { "CustomerSK", Int64.Type },
            { "ProductSK", Int64.Type },
            { "StoreSK", Int64.Type },
            { "EmployeeSK", Int64.Type },
            { "SupplierSK", Int64.Type },
            { "CategorySK", Int64.Type },
            { "RegionSK", Int64.Type },
            { "OrderID", Int64.Type },
            { "OrderDetailID", Int64.Type },
            { "Channel", type text },
            { "OrderStatus", type text },
            { "Quantity", Int64.Type },
            { "UnitPrice", Currency.Type },
            { "UnitCost", Currency.Type },
            { "DiscountPercent", type number },
            { "DiscountAmount", Currency.Type },
            { "LineTotal", Currency.Type },
            { "LineCOGS", Currency.Type },
            { "GrossProfit", Currency.Type }
        }
    )
    // NOTE: We deliberately DO NOT rename fact columns — [Total Revenue] etc.
    //       in the DAX files reference these exact names (LineTotal, LineCOGS).
in
    TypedColumns
```

### 2.2 — FactReturns

```m
let
    // WHAT/WHY/WHEN: same connect pattern → warehouse.FactReturns.
    // QUERY FOLDING: Yes.
    Source = Sql.Database ( "localhost", "RetailDW" ),
    FactReturns = Source{[Schema = "warehouse", Item = "FactReturns"]}[Data],

    // WHAT: Drop the audit column.  WHY: memory hygiene.  FOLDING: Yes.
    RemovedAudit = Table.RemoveColumns ( FactReturns, { "_LoadedAt" } ),

    // WHAT: Type the columns (keys Int64, RefundAmount Currency, DaysToReturn Int).
    // WHY: correctness + folding.  WHEN: every refresh.  FOLDING: Yes.
    TypedColumns = Table.TransformColumnTypes (
        RemovedAudit,
        {
            { "ReturnFactID", Int64.Type }, { "ReturnDateKey", Int64.Type },
            { "OrderDateKey", Int64.Type }, { "CustomerSK", Int64.Type },
            { "ProductSK", Int64.Type }, { "StoreSK", Int64.Type },
            { "CategorySK", Int64.Type }, { "RegionSK", Int64.Type },
            { "ReturnID", Int64.Type }, { "OrderDetailID", Int64.Type },
            { "OrderID", Int64.Type }, { "Reason", type text },
            { "Condition", type text }, { "RefundAmount", Currency.Type },
            { "OriginalQuantity", Int64.Type }, { "OriginalLineTotal", Currency.Type },
            { "DaysToReturn", Int64.Type }
        }
    )
in
    TypedColumns
```

### 2.3 — FactInventory

```m
let
    // Connect → warehouse.FactInventory.  FOLDING: Yes.
    Source = Sql.Database ( "localhost", "RetailDW" ),
    FactInventory = Source{[Schema = "warehouse", Item = "FactInventory"]}[Data],

    // WHAT: Remove audit column.  FOLDING: Yes.
    RemovedAudit = Table.RemoveColumns ( FactInventory, { "_LoadedAt" } ),

    // WHAT: Type columns. NOTE the BIT flags become logical (true/false) so the
    //       DAX measures [Low Stock Items Count] etc. can test = TRUE().
    // WHY: correct semi-additive handling relies on clean types + a good date rel.
    // FOLDING: Yes.
    TypedColumns = Table.TransformColumnTypes (
        RemovedAudit,
        {
            { "InventoryFactID", Int64.Type }, { "SnapshotDateKey", Int64.Type },
            { "ProductSK", Int64.Type }, { "StoreSK", Int64.Type },
            { "SupplierSK", Int64.Type }, { "CategorySK", Int64.Type },
            { "RegionSK", Int64.Type }, { "InventoryID", Int64.Type },
            { "QuantityOnHand", Int64.Type }, { "ReorderPoint", Int64.Type },
            { "ReorderQuantity", Int64.Type }, { "UnitCost", Currency.Type },
            { "InventoryValue", Currency.Type },
            { "IsLowStock", type logical }, { "IsOutOfStock", type logical }
        }
    )
in
    TypedColumns
```

### 2.4 — DimDate (mark as Date Table)

```m
let
    // Connect → warehouse.DimDate (generated in SQL, 2020-01-01 → 2026-12-31).
    // FOLDING: Yes.
    Source = Sql.Database ( "localhost", "RetailDW" ),
    DimDate = Source{[Schema = "warehouse", Item = "DimDate"]}[Data],

    // WHAT: Type columns; FullDate MUST be type date (powers Time Intelligence).
    // WHY: DATESYTD/SAMEPERIODLASTYEAR require a real, contiguous date column.
    // FOLDING: Yes.
    TypedColumns = Table.TransformColumnTypes (
        DimDate,
        {
            { "DateKey", Int64.Type }, { "FullDate", type date },
            { "Year", Int64.Type }, { "Quarter", Int64.Type },
            { "MonthNumber", Int64.Type }, { "MonthName", type text },
            { "YearMonth", type text }, { "IsWeekend", type logical }
        }
    )
    // AFTER LOADING: In Report view, select DimDate → Table tools → "Mark as
    // date table" → choose FullDate. WHY: guarantees correct time intelligence
    // and removes Power BI's auto date/time hierarchies (which bloat the model).
in
    TypedColumns
```

### 2.5 — DimCustomer (remove PII)

```m
let
    Source = Sql.Database ( "localhost", "RetailDW" ),
    DimCustomer = Source{[Schema = "warehouse", Item = "DimCustomer"]}[Data],

    // WHAT: Remove the Email column (Personally Identifiable Information).
    // WHY:  PII must not sit in a widely-shared analytics model (GDPR/privacy).
    //       We keep FullName for display but drop the direct contact field.
    // WHEN: Every refresh.  QUERY FOLDING: Yes (column projection).
    RemovedPII = Table.RemoveColumns ( DimCustomer, { "Email", "_LoadedAt" } ),

    // WHAT: Type the remaining columns.  FOLDING: Yes.
    TypedColumns = Table.TransformColumnTypes (
        RemovedPII,
        {
            { "CustomerSK", Int64.Type }, { "CustomerID", Int64.Type },
            { "FullName", type text }, { "Segment", type text },
            { "JoinDate", type date }, { "City", type text },
            { "State", type text }, { "Region", type text },
            { "CustomerTenureYears", Int64.Type }, { "JoinYear", Int64.Type }
        }
    )
in
    TypedColumns
```

### 2.6 — DimProduct (keep PriceRange, MarginPercent)

```m
let
    Source = Sql.Database ( "localhost", "RetailDW" ),
    DimProduct = Source{[Schema = "warehouse", Item = "DimProduct"]}[Data],

    // WHAT: Drop audit only — KEEP MarginPercent & PriceRange.
    // WHY:  DAX measures [High/Low Margin Products Count] and slicers rely on
    //       these SQL-derived columns; do not remove them.
    // FOLDING: Yes.
    RemovedAudit = Table.RemoveColumns ( DimProduct, { "_LoadedAt" } ),

    TypedColumns = Table.TransformColumnTypes (
        RemovedAudit,
        {
            { "ProductSK", Int64.Type }, { "ProductID", Int64.Type },
            { "ProductName", type text }, { "CategoryName", type text },
            { "SubCategoryName", type text }, { "Brand", type text },
            { "UnitCost", Currency.Type }, { "UnitPrice", Currency.Type },
            { "GrossMargin", Currency.Type }, { "MarginPercent", type number },
            { "PriceRange", type text }
        }
    )
in
    TypedColumns
```

### 2.7 — DimStore, DimEmployee, DimRegion, DimCategory, DimSupplier

```m
// All follow the SAME minimal pattern:
//   Source → navigate → Table.RemoveColumns({ "_LoadedAt" }) → set types.
//
// DimStore    : keep StoreSize, YearsOpen (SQL-derived slicer columns).
// DimEmployee : keep SalaryBand, TenureYears; keep FullName; drop nothing PII-
//               critical beyond audit (Salary stays for [Sales Per Associate]).
// DimRegion   : tiny (5 rows) — just remove _LoadedAt and type RegionSK/Name.
// DimCategory : small — remove _LoadedAt; type CategorySK/CategoryName/etc.
// DimSupplier : keep LeadTimeCategory, RatingCategory; remove _LoadedAt.
//
// Example (DimStore):
let
    Source = Sql.Database ( "localhost", "RetailDW" ),
    DimStore = Source{[Schema = "warehouse", Item = "DimStore"]}[Data],
    RemovedAudit = Table.RemoveColumns ( DimStore, { "_LoadedAt" } ),   // FOLDING: Yes
    TypedColumns = Table.TransformColumnTypes (
        RemovedAudit,
        {
            { "StoreSK", Int64.Type }, { "StoreID", Int64.Type },
            { "StoreName", type text }, { "City", type text },
            { "State", type text }, { "Region", type text },
            { "StoreType", type text }, { "OpenDate", type date },
            { "SquareFootage", Int64.Type }, { "StoreSize", type text },
            { "YearsOpen", Int64.Type }
        }
    )
in
    TypedColumns
```

---

## SECTION 3 — Query Folding

**Query folding** is Power Query's ability to translate your M steps back into a
single **native SQL query** that SQL Server executes. This is the single most
important performance concept in the ETL layer.

### Why it matters

| | Folded (good) | Not folded (bad) |
|-----|---------------|------------------|
| Who does the work | **SQL Server** (optimized engine, indexes) | **Power BI** (row-by-row in memory) |
| Data moved | Only the final, filtered result | The entire table, then filtered locally |
| Refresh speed | Fast, scales to millions of rows | Slow, memory-heavy |
| Incremental refresh | **Requires** folding on the date filter | Won't partition correctly |

### What folds vs what breaks folding

| Folds ✅ | Breaks folding ❌ |
|----------|-------------------|
| `Table.SelectRows` (filter) | Custom columns with complex M functions |
| `Table.SelectColumns` / `RemoveColumns` | `Text.Combine`, most `List.*` operations |
| `Table.RenameColumns` | `Table.AddIndexColumn` |
| `Table.TransformColumnTypes` (CAST) | Merging with a non-foldable/other-source query |
| `Table.Sort` | Anything after a step that already broke folding |
| `Table.Group` (simple aggregations) | Invoking custom functions per row |

> **Rule of thumb:** Do all foldable steps **first** (filter, remove columns,
> type, rename). Put any non-foldable step **last**, because once folding
> breaks, *every* step after it also runs locally.

### How to check folding

1. In the Power Query Editor, right-click a step in **Applied Steps**.
2. If **"View Native Query"** is **enabled**, that step (and all before it)
   folds — you can read the exact SQL sent to the server.
3. If **"View Native Query"** is **greyed out**, folding has **broken** at or
   before this step. Move the offending step later or replace it.

```m
// EXAMPLE — a fully folding query (this becomes ONE efficient SQL statement):
let
    Source = Sql.Database ( "localhost", "RetailDW" ),
    FactSales = Source{[Schema = "warehouse", Item = "FactSales"]}[Data],

    // WHAT: Keep only completed orders.  FOLDING: Yes → SQL WHERE clause.
    OnlyCompleted = Table.SelectRows ( FactSales, each [OrderStatus] = "Completed" ),

    // WHAT: Keep only needed columns.  FOLDING: Yes → SQL SELECT list.
    Slim = Table.SelectColumns ( OnlyCompleted, { "OrderDateKey", "CustomerSK", "LineTotal" } )
    // Right-click "Slim" → View Native Query shows:
    //   SELECT [OrderDateKey],[CustomerSK],[LineTotal]
    //   FROM [warehouse].[FactSales] WHERE [OrderStatus] = 'Completed'
in
    Slim
```

---

## SECTION 4 — Incremental Refresh Parameters

For the **production** dataset (~2M rows), refreshing the whole table daily is
wasteful. **Incremental refresh** loads only recent data and keeps historical
partitions frozen.

### Step 1 — Create the two reserved parameters

Power BI recognizes two **specifically named** `datetime` parameters. The names
must be **exactly** `RangeStart` and `RangeEnd`.

```m
// WHAT: RangeStart — lower bound of the refresh window.
// WHY:  Incremental refresh partitions the fact table on this date filter.
// WHEN: Set once; Power BI Service overrides these values per partition.
// QUERY FOLDING: Yes — this MUST fold or incremental refresh fails.
RangeStart = #datetime ( 2025, 1, 1, 0, 0, 0 )
    meta [ IsParameterQuery = true, Type = "DateTime", IsParameterQueryRequired = true ]
```

```m
// WHAT: RangeEnd — upper bound (exclusive) of the refresh window.
// WHY/WHEN/FOLDING: same as RangeStart.
RangeEnd = #datetime ( 2025, 12, 31, 0, 0, 0 )
    meta [ IsParameterQuery = true, Type = "DateTime", IsParameterQueryRequired = true ]
```

### Step 2 — Filter the fact query on a real date column

The filter must use a **DateTime** column that folds. Our fact stores
`OrderDateKey` as an INT (YYYYMMDD), so we join/relate to `DimDate` for the real
date, OR add a foldable date filter using a computed date. The cleanest approach
is to expose an `OrderDate` (DateTime) via the SQL view, then:

```m
// WHAT: Keep only rows inside [RangeStart, RangeEnd).
// WHY:  Power BI generates one partition per period using these bounds; only the
//       latest partition(s) refresh each day.
// WHEN: Every refresh (Service substitutes the bounds per partition).
// QUERY FOLDING: Yes — REQUIRED. Verify with "View Native Query".
FilteredRows = Table.SelectRows (
    FactSales,
    each [OrderDate] >= RangeStart and [OrderDate] < RangeEnd
)
```

### Step 3 — Configure the policy in Desktop

Right-click the table → **Incremental refresh** →
- **Archive data starting** *5 years* before refresh date.
- **Incrementally refresh data** *10 days* before refresh date.
- (Optional) **Detect data changes** on a `_LoadedAt` column.
- (Optional) **Only refresh complete periods**.

> **Publishing requirement:** Incremental refresh is applied when you **publish
> to the Service** and run the **first full refresh** there — it does not
> partition inside Desktop.

---

## SECTION 5 — Date Table (fallback generator)

We already have `warehouse.DimDate` from SQL, so **prefer that**. But if you ever
need a Power-BI-native date table (e.g. a quick model without SQL), here is a
complete, commented generator.

```m
let
    // WHAT: Define the calendar span.
    // WHY:  Must cover the FULL range of every fact date (orders, returns,
    //       inventory snapshots) or time intelligence produces gaps.
    // WHEN: Setup; extend the end date as new data arrives.
    // QUERY FOLDING: No — this is generated in Power BI (no SQL source).
    StartDate = #date ( 2020, 1, 1 ),
    EndDate = #date ( 2026, 12, 31 ),

    // WHAT: Build a continuous list of dates, then turn it into a table.
    // WHY:  Time intelligence REQUIRES a contiguous, gap-free daily grain.
    DayCount = Duration.Days ( EndDate - StartDate ) + 1,
    DateList = List.Dates ( StartDate, DayCount, #duration ( 1, 0, 0, 0 ) ),
    TableFromList = Table.FromList ( DateList, Splitter.SplitByNothing (), { "FullDate" } ),
    TypedDate = Table.TransformColumnTypes ( TableFromList, { { "FullDate", type date } } ),

    // WHAT: Add the standard calendar attribute columns.
    // WHY:  These become slicers, axes, and hierarchy levels in every report.
    // WHEN: Every refresh.
    AddYear = Table.AddColumn ( TypedDate, "Year", each Date.Year ( [FullDate] ), Int64.Type ),
    AddQuarter = Table.AddColumn ( AddYear, "Quarter", each Date.QuarterOfYear ( [FullDate] ), Int64.Type ),
    AddMonthNum = Table.AddColumn ( AddQuarter, "MonthNumber", each Date.Month ( [FullDate] ), Int64.Type ),
    AddMonthName = Table.AddColumn ( AddMonthNum, "MonthName", each Date.MonthName ( [FullDate] ), type text ),
    AddWeek = Table.AddColumn ( AddMonthName, "WeekOfYear", each Date.WeekOfYear ( [FullDate] ), Int64.Type ),
    AddDay = Table.AddColumn ( AddWeek, "DayOfMonth", each Date.Day ( [FullDate] ), Int64.Type ),
    AddYearMonth = Table.AddColumn ( AddDay, "YearMonth", each Date.ToText ( [FullDate], "yyyy-MM" ), type text ),

    // WHAT: Fiscal year (retail fiscal year starts in July, matching DimDate).
    // WHY:  Finance reports on fiscal, not calendar, periods.
    AddFiscalYear = Table.AddColumn (
        AddYearMonth, "FiscalYear",
        each if Date.Month ( [FullDate] ) >= 7 then Date.Year ( [FullDate] ) + 1 else Date.Year ( [FullDate] ),
        Int64.Type
    ),

    // WHAT: Weekend flag.  WHY: staffing & footfall analysis need weekday/weekend.
    AddIsWeekend = Table.AddColumn (
        AddFiscalYear, "IsWeekend",
        each Date.DayOfWeek ( [FullDate], Day.Monday ) >= 5, type logical
    ),

    // WHAT: Simple holiday flag (extend with a real holiday list).
    // WHY:  Holidays distort daily comparisons; flagging enables clean analysis.
    AddIsHoliday = Table.AddColumn (
        AddIsWeekend, "IsHoliday",
        each ( Date.Month ( [FullDate] ) = 12 and Date.Day ( [FullDate] ) = 25 )
             or ( Date.Month ( [FullDate] ) = 1 and Date.Day ( [FullDate] ) = 1 ),
        type logical
    )
in
    AddIsHoliday
    // AFTER LOADING: Mark as date table on [FullDate].
```

---

## Summary checklist

- [ ] Parameterize server + database (`pServerName`, `pDatabaseName`).
- [ ] Every query: remove `_LoadedAt`, remove PII (`Email`), set explicit types.
- [ ] Do **not** rename fact measure columns (DAX depends on exact names).
- [ ] Verify **View Native Query** is enabled on the last step of each query.
- [ ] Mark `DimDate` as the date table on `FullDate`; disable auto date/time.
- [ ] For production, add `RangeStart`/`RangeEnd` + a folding date filter.
