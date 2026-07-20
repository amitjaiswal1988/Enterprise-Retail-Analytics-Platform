# Phase 3 — Warehouse Load: Staging → Star Schema

**Author:** BI Development Team
**Date:** 2026-07-21
**Scope:** Populating the Kimball star schema (`warehouse.*`) from the cleaned `staging.*` layer.
**Status:** ✅ Completed & verified — Phase 3 (data warehouse) is now end-to-end complete.

> Documents **WHEN, WHY, WHAT, and HOW (mode)** for the warehouse load, plus the
> two data bugs found and fixed during this step.

---

## 1. Where this fits

```
[staging.*]  (typed, cleaned, deduplicated)
     │  SQL: warehouse.usp_LoadAll_StagingToWarehouse
     ▼
[warehouse.*]  ← star schema: 8 dimensions + 3 facts (surrogate keys)
     │  (next phase) SQL Views + Power BI model
     ▼
   Reports / dashboards
```

| Field | Detail |
|-------|--------|
| **WHEN** | Phase 3 final step, after the Landing→Staging ETL. |
| **WHY** | Power BI needs a dimensional model. Facts must carry **surrogate keys** (SKs), not business keys, so we resolve every key against its dimension and route orphans to the `-1` "Unknown" member. |
| **WHAT** | 1 DimDate generator + 7 dimension loaders + 3 fact loaders + 1 master orchestrator. |
| **MODE / HOW** | T-SQL stored procedures via `sqlcmd`. |
| **Script** | [SQL/Stored Procedures/07_ETL_Staging_To_Warehouse.sql](../SQL/Stored%20Procedures/07_ETL_Staging_To_Warehouse.sql) |
| **Command** | `sqlcmd -S localhost -E -C -d RetailDW -b -Q "EXEC warehouse.usp_LoadAll_StagingToWarehouse;"` |

---

## 2. Load order (FK-safe)

1. **Clear facts** (FactSales, FactReturns, FactInventory) — must be emptied first so
   dimension reloads are not blocked by foreign keys.
2. **Load dimensions:** DimDate (generated) → DimRegion → DimCategory → DimSupplier →
   DimStore → DimEmployee → DimCustomer → DimProduct.
3. **Load facts:** FactSales → FactReturns → FactInventory (business keys → SKs).

**Reload pattern for dimensions:** `DELETE WHERE <SK> <> -1` then re-`INSERT`.
We cannot `TRUNCATE` because the tables are referenced by fact FKs *and* truncation would
wipe the `-1` Unknown member seeded via `IDENTITY_INSERT` in script 03.

---

## 3. Key design decisions

| Topic | Decision |
|-------|----------|
| **DimDate** | Generated (not from CSV) for 2020-01-01 … 2026-12-31 = 2,557 days. `DateKey` = `YYYYMMDD`. Includes fiscal year (Jul–Jun), weekend flags, and simple US holiday flags. |
| **Surrogate keys** | Every dimension has an `IDENTITY` SK; the `-1` member handles orphans/unknowns. |
| **Orphan handling** | All fact→dim lookups use `LEFT JOIN … + ISNULL(sk, -1)`. An unmatched business key resolves to the Unknown member instead of dropping the row or failing the FK. |
| **Online orders** | E-commerce orders have NULL Store/Employee → resolve to `StoreSK = -1` / `EmployeeSK = -1` ("Unknown/Online" member). |
| **RegionSK** | Derived by joining the dimension's region **name** text to `DimRegion.RegionName` (sales = customer region; inventory = store region). |
| **Derived measures** | `LineCOGS = Quantity × UnitCost`, `GrossProfit = LineTotal − LineCOGS`, `DiscountAmount = Quantity × UnitPrice × Discount`, `InventoryValue = QtyOnHand × UnitCost`. |

---

## 4. Bugs found & fixed during this step

Both were **upstream in the Staging ETL** (script 06), surfaced only when the warehouse
load routed *every* sale to the "Unknown store".

| # | Symptom | Root cause | Fix |
|---|---------|-----------|-----|
| 1 | All 201,282 sales had `StoreSK = -1` / `EmployeeSK = -1` (no real store ever matched) | `StoreID`/`EmployeeID` land as float-formatted strings (`'48.0'`) because they are nullable at source and pandas stores nullable ints as floats. `TRY_CAST('48.0' AS INT)` returns **NULL**. | Cast via FLOAT first: `TRY_CAST(TRY_CAST(NULLIF(col,'') AS FLOAT) AS INT)`. Same fix applied to `Employees.ManagerID`. |
| 2 | E-commerce rows would get `StoreID = 0` instead of NULL | `TRY_CAST('' AS FLOAT)` returns **0, not NULL** in SQL Server. | Wrap the source in `NULLIF(LTRIM(RTRIM(col)),'')` so empty → NULL before casting. |

**Result after fix:** store sales `StoreSK<>-1` = 120,796 (~60%), online `StoreSK=-1` = 80,486 (~40%) — matching the source channel mix. 950 of 1,000 employees have a manager (50 top-level = NULL).

---

## 5. Load results

| Dimension | Rows* | Fact | Rows |
|-----------|------:|------|-----:|
| DimDate | 2,557 | FactSales | 201,282 |
| DimRegion | 5 | FactReturns | 8,571 |
| DimCategory | 26 | FactInventory | 400,000 |
| DimSupplier | 101 | | |
| DimStore | 51 | | |
| DimEmployee | 1,001 | | |
| DimCustomer | 20,001 | | |
| DimProduct | 2,001 | | |

\* Dimension counts include the `-1` Unknown member.

**Row reconciliation (facts):**
- FactSales 201,282 = staging.OrderDetails 201,473 − 191 lines whose parent order was removed (dup/future-date). Sales lines for a non-existent order are correctly excluded.
- FactReturns 8,571 = staging.Returns 8,578 − 7 returns whose order was removed.
- FactInventory 400,000 = staging.Inventory 400,000 (all matched).

**Orphan routing verified:** 379 sales lines → `ProductSK = -1` (DEF-04 orphan products).
**Referential integrity:** 0 broken fact→DimDate keys across all three facts.

**Headline KPIs (proof the star works):**
| Metric | Value |
|--------|------:|
| Total Revenue | $720,097,230 |
| Gross Profit | $121,203,540 |
| Gross Margin | 16.8% |

---

## 6. Full reproduction

```bash
# after schemas/tables/procs exist and staging is loaded:
sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Stored Procedures/07_ETL_Staging_To_Warehouse.sql"
sqlcmd -S localhost -E -C -d RetailDW -b -Q "EXEC warehouse.usp_LoadAll_StagingToWarehouse;"
```

---

## 7. Next step

Phase 3 tables + ETL are complete. Next is the **presentation layer**:
1. `SQL/Views/` — analytics views (e.g. `vw_SalesByMonth`, `vw_ProductPerformance`,
   `vw_InventoryHealth`, `vw_ReturnsAnalysis`) joining facts to dimensions.
2. Power BI: connect to `RetailDW`, build the model (relationships on SKs), and author
   the report pages against the BRD KPIs.
