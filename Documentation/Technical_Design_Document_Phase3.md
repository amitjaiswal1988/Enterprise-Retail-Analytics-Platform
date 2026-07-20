# Technical Design Document — Phase 3

## Database Architecture & Star Schema Design

---

| Document Control | Details |
|-----------------|---------|
| **Document ID** | TDD-PHASE3-2026-001 |
| **Version** | 1.0 |
| **Author** | BI Development Team |
| **Date Created** | July 20, 2026 |
| **Database** | RetailDW |
| **SQL Server** | 2022 (Compatibility Level 160) |

---

## 1. Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         RetailDW DATABASE                                 │
├──────────────────┬──────────────────────┬────────────────────────────────┤
│  [landing]       │  [staging]           │  [warehouse]                   │
│                  │                      │                                │
│  12 tables       │  12 tables           │  8 Dimension tables            │
│  ALL VARCHAR     │  + 1 Quarantine      │  3 Fact tables                 │
│  No constraints  │  Proper data types   │  21 Foreign Keys               │
│  Audit metadata  │  PKs + CHECKs        │  15 NC Indexes                 │
│                  │  Computed columns    │  2 Columnstore indexes         │
│                  │  Defect flags        │  7 Dim business key indexes    │
│                  │                      │                                │
│  ← CSV Import    │  ← ETL Procs (13)   │  ← Staging → Warehouse ETL    │
└──────────────────┴──────────────────────┴────────────────────────────────┘
```

---

## 2. Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Star Schema (not Snowflake) | Simpler JOINs, faster Power BI queries, easier DAX |
| 2 | Surrogate keys on all dims | Handles Type 2 SCD (future), isolates from source key changes |
| 3 | Unknown member (SK = -1) | Orphan FK rows point here instead of failing |
| 4 | All VARCHAR in landing | Never reject a row at ingestion — capture everything |
| 5 | Computed columns in staging | GrossMargin, FullName, TransitDays auto-calculated |
| 6 | Columnstore on fact tables | 10x compression, batch-mode aggregation for Power BI |
| 7 | DateKey as INT (YYYYMMDD) | Partition-friendly, efficient range scans |
| 8 | 3-layer architecture | Audit trail, separation of concerns, enterprise standard |
| 9 | Quarantine table | Bad rows captured with defect type — not silently dropped |
| 10 | SIMPLE recovery model | Portfolio/dev project — minimizes log file growth |

---

## 3. Star Schema Diagram

```
                              ┌─────────────┐
                              │  DimDate    │
                              │ (Calendar)  │
                              └──────┬──────┘
                                     │
        ┌────────────┐    ┌──────────┴──────────┐    ┌─────────────┐
        │ DimProduct │────│     FactSales       │────│ DimCustomer │
        │            │    │ (Order Line Item)   │    │             │
        └──────┬─────┘    └──────────┬──────────┘    └─────────────┘
               │                     │
        ┌──────┴─────┐       ┌──────┴──────┐
        │DimCategory │       │  DimStore   │
        └────────────┘       └─────────────┘
                                     │
                              ┌──────┴──────┐     ┌──────────────┐
                              │ DimEmployee │     │ DimSupplier  │
                              └─────────────┘     └──────────────┘
                                                         │
                                                  ┌──────┴──────┐
                                                  │  DimRegion  │
                                                  └─────────────┘
```

---

## 4. Fact Table Definitions

### 4.1 FactSales

| Attribute | Value |
|-----------|-------|
| **Grain** | One row per order line item |
| **Type** | Transactional |
| **Est. Rows** | ~200K (dev) / ~2M (prod) |
| **FKs** | 8 (Date, Customer, Product, Store, Employee, Supplier, Category, Region) |
| **Measures** | Quantity, UnitPrice, UnitCost, DiscountAmount, LineTotal, LineCOGS, GrossProfit |
| **Degenerate Dims** | OrderID, OrderDetailID, Channel, OrderStatus |

### 4.2 FactReturns

| Attribute | Value |
|-----------|-------|
| **Grain** | One row per returned line item |
| **Type** | Transactional |
| **Est. Rows** | ~8.5K (dev) / ~85K (prod) |
| **FKs** | 7 (ReturnDate, OrderDate, Customer, Product, Store, Category, Region) |
| **Measures** | RefundAmount, OriginalQuantity, OriginalLineTotal, DaysToReturn |
| **Degenerate Dims** | ReturnID, OrderDetailID, OrderID, Reason, Condition |

### 4.3 FactInventory

| Attribute | Value |
|-----------|-------|
| **Grain** | One row per product/store/snapshot date |
| **Type** | Periodic Snapshot |
| **Est. Rows** | ~400K (dev) / ~4M (prod) |
| **FKs** | 6 (SnapshotDate, Product, Store, Supplier, Category, Region) |
| **Measures** | QuantityOnHand, ReorderPoint, ReorderQuantity, UnitCost, InventoryValue |
| **Flags** | IsLowStock, IsOutOfStock |

> **Semi-Additive Note:** FactInventory measures are additive across Product, Store, Region — but NOT across Date (use LASTNONBLANK in DAX).

---

## 5. Dimension Table Definitions

| Dimension | Grain | Rows | SCD Type | Key Derived Columns |
|-----------|-------|------|----------|-------------------|
| DimDate | One day | 2,557 (7 years) | N/A (generated) | FiscalYear, Quarter, IsWeekend, IsHoliday |
| DimRegion | One region | 4 | Static | — |
| DimCategory | One sub-category | 25-50 | Static | — |
| DimSupplier | One supplier | 100-500 | Type 1 | LeadTimeCategory, RatingCategory |
| DimStore | One store | 50-120 | Type 1 | StoreSize, YearsOpen |
| DimEmployee | One employee | 1K-5K | Type 1 | TenureYears, SalaryBand |
| DimCustomer | One customer | 20K-200K | Type 1 | CustomerTenureYears, JoinYear |
| DimProduct | One product | 2K-10K | Type 1 | GrossMargin, MarginPercent, PriceRange |

---

## 6. ETL Flow

```
CSV Files (12)
    │
    ▼ BULK INSERT / OPENROWSET
┌─────────────────────┐
│  [landing] tables   │  ← All VARCHAR, no validation
└─────────┬───────────┘
          │
          ▼ staging.usp_LoadAll_LandingToStaging
┌─────────────────────┐
│  [staging] tables   │  ← Type cast, dedupe, normalize, flag defects
└─────────┬───────────┘
          │
          ▼ warehouse.usp_LoadAll_StagingToWarehouse (Phase 4)
┌─────────────────────┐
│ [warehouse] tables  │  ← Surrogate key lookup, fact population
└─────────────────────┘
          │
          ▼ Power BI Import / DirectQuery
┌─────────────────────┐
│    Dashboards       │
└─────────────────────┘
```

---

## 7. ETL Defect Handling Summary

| Defect | Layer Detected | Treatment | Evidence |
|--------|---------------|-----------|----------|
| DEF-01: NULL emails | Staging | Flagged `_IsEmailMissing = 1` | Column on staging.Customers |
| DEF-02: Duplicate orders | Staging | `ROW_NUMBER()` keeps first | Dedup CTE in usp_Load_Orders |
| DEF-03: Future dates | Staging | Quarantined to staging.Quarantine | INSERT to Quarantine table |
| DEF-04: Orphan products | Staging | Flagged `_IsOrphanProduct = 1` | LEFT JOIN check in usp_Load_OrderDetails |
| DEF-05: Casing | Staging | `CASE UPPER()` normalization | Canonical mapping in usp_Load_Categories |
| DEF-06: Negative qty | Staging | `ABS()` applied, flagged | `_IsQuantityCorrected = 1` |
| DEF-07: NULL ManagerID | None needed | Valid hierarchy terminator | NULL allowed in staging.Employees |

---

## 8. Index Strategy

| Index Type | Count | Purpose |
|-----------|-------|---------|
| Clustered (PK) | 23 | Row uniqueness + physical sort |
| Non-Clustered (fact FKs) | 15 | Dimension lookup performance |
| Non-Clustered Columnstore | 2 | Analytical aggregation (SUM, AVG) |
| Filtered | 1 | Low-stock alert queries |
| Unique (dim business keys) | 7 | ETL surrogate key lookups |
| **Total** | **48** | |

---

## 9. Script Execution Order

| # | Script | Layer | Run Time |
|---|--------|-------|----------|
| 1 | `SQL/00_Create_Database.sql` | Database + Schemas | 2 sec |
| 2 | `SQL/Landing/01_Landing_Tables.sql` | Landing | 1 sec |
| 3 | `SQL/Staging/02_Staging_Tables.sql` | Staging | 1 sec |
| 4 | `SQL/Warehouse/03_Dimension_Tables.sql` | Warehouse Dims | 1 sec |
| 5 | `SQL/Warehouse/04_Fact_Tables.sql` | Warehouse Facts | 1 sec |
| 6 | `SQL/Warehouse/05_Indexes_And_ForeignKeys.sql` | Indexes + FKs | 2 sec |
| 7 | `SQL/Stored Procedures/06_ETL_Landing_To_Staging.sql` | ETL Procs | 1 sec |

**Total deployment time:** < 10 seconds (structure only, no data)

---

## 10. Naming Conventions

| Object | Convention | Example |
|--------|-----------|---------|
| Database | PascalCase | `RetailDW` |
| Schema | lowercase | `landing`, `staging`, `warehouse` |
| Table (Dim) | PascalCase with Dim prefix | `DimCustomer` |
| Table (Fact) | PascalCase with Fact prefix | `FactSales` |
| Column | PascalCase | `CustomerID`, `OrderDate` |
| Surrogate Key | TableName + SK | `CustomerSK` |
| Business Key | Entity + ID | `CustomerID` |
| Index | IX_Table_Column | `IX_FactSales_OrderDateKey` |
| Foreign Key | FK_Child_Parent | `FK_FactSales_DimCustomer` |
| Stored Procedure | schema.usp_Action_Detail | `staging.usp_Load_Orders` |
| Computed Column | Descriptive name | `GrossMargin`, `IsLowStock` |
| Audit Column | Underscore prefix | `_LoadedAt`, `_IsValid` |

---

## 11. Power BI Optimization Considerations

| Design Choice | Power BI Benefit |
|--------------|-----------------|
| Star Schema | Native relationship detection, simple model |
| Integer DateKey (YYYYMMDD) | Fast date filtering, mark-as-date-table ready |
| Surrogate keys (INT) | Smaller model size vs NVARCHAR joins |
| Computed PriceRange/StoreSize | Ready-made slicers (no DAX needed) |
| Columnstore indexes | DirectQuery mode performance |
| Pre-calculated GrossProfit | Reduces DAX calculation load |
| Unknown member (SK=-1) | No blank/error rows in visuals |

---

## 12. Security Considerations

| Layer | Access |
|-------|--------|
| `[landing]` | ETL service account only |
| `[staging]` | ETL service + Data Engineers |
| `[warehouse]` | Power BI service account (read-only) |
| Row-Level Security | Implemented in Power BI (Phase 10) via DimStore.Region |

---

## 13. Future Enhancements (Not in Current Phase)

| Enhancement | Phase | Description |
|-------------|-------|-------------|
| DimDate population script | Phase 4 | Generate 7 years of calendar rows |
| Staging → Warehouse ETL | Phase 4 | Surrogate key lookup + fact loading |
| Type 2 SCD on DimCustomer | Phase 11 | Track historical segment changes |
| Partitioning on FactSales | Phase 11 | By year for incremental refresh |
| Aggregation tables | Phase 11 | Monthly rollups for dashboard performance |

---

*End of Document*
