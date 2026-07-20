# Phase 3 — Presentation Layer: Analytics Views

**Author:** BI Development Team
**Date:** 2026-07-21
**Scope:** Business-facing SQL views over the star schema — the semantic layer Power BI connects to.
**Status:** ✅ Completed & verified — 10 views created and smoke-tested.

> Documents **WHEN, WHY, WHAT, and HOW (mode)** for the analytics views, the KPI
> math they encapsulate, and which BRD dashboard/KPI each one serves.

---

## 1. Where this fits

```
[warehouse.*]  star schema (8 dims + 3 facts)
     │  SQL: 08_Analytics_Views.sql  (pre-joined, pre-aggregated KPIs)
     ▼
[warehouse.vw_*]  10 analytics views  <-- Power BI connects here
     ▼
   9 dashboards + DAX measures
```

| Field | Detail |
|-------|--------|
| **WHEN** | Phase 3 final step, after the warehouse is loaded. |
| **WHY** | The BRD asks for 9 dashboards and 100+ DAX measures. Putting the joins + core KPI math in views gives a single source of truth, keeps DAX thin, and lets us unit-test metrics in SQL. |
| **WHAT** | 10 views mapped to dashboards / BRD KPIs (table below). |
| **MODE / HOW** | Standard SQL views (no persistence); each query hits live warehouse data. |
| **Script** | [SQL/Views/08_Analytics_Views.sql](../SQL/Views/08_Analytics_Views.sql) |
| **Command** | `sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Views/08_Analytics_Views.sql"` |

---

## 2. Measure conventions (used consistently in every view)

| Measure | Definition |
|---------|-----------|
| Revenue | `SUM(FactSales.LineTotal)` (net of discount) |
| COGS | `SUM(FactSales.LineCOGS)` |
| GrossProfit | `SUM(FactSales.GrossProfit)` |
| GrossMargin % | `GrossProfit / Revenue * 100` |
| Orders | `COUNT(DISTINCT FactSales.OrderID)` (degenerate dimension) |
| Units | `SUM(FactSales.Quantity)` |
| AOV | `Revenue / Orders` |

Every division is wrapped in `NULLIF(...,0)` to prevent divide-by-zero.

---

## 3. The 10 views

| # | View | Dashboard | BRD KPI | What it returns |
|---|------|-----------|---------|-----------------|
| 1 | `vw_ExecutiveKPIs` | Executive | F-01/02/05/06, O-05 | One-row scorecard: revenue, margin, AOV, return rate, revenue/store |
| 2 | `vw_SalesByMonth` | Sales / Finance | F-01, FR-01 | Monthly revenue, orders, AOV, margin trend |
| 3 | `vw_SalesByCategory` | Product | F-02 | Revenue/margin/units by department, category, channel |
| 4 | `vw_ProductPerformance` | Product | — | Per-product sales + return rate (units returned / sold) |
| 5 | `vw_StorePerformance` | Store | F-06, E-01 | Store revenue, AOV, sales/associate, revenue/sq-ft |
| 6 | `vw_RegionalSales` | Regional | OBJ-06 | Region × channel revenue split (store vs e-commerce) |
| 7 | `vw_CustomerAnalysis` | Customer | C-03, C-04 | Per-customer RFM: frequency, spend, recency, repeat flag |
| 8 | `vw_ReturnsAnalysis` | Sales | O-05 | Return volume, refunds, reasons by category |
| 9 | `vw_InventoryHealth` | Inventory | O-03 | Current-snapshot stock, stockout & low-stock rates, value |
| 10 | `vw_ShippingPerformance` | Shipping | O-04, FR-10 | On-time %, avg transit days by carrier / mode |

---

## 4. Design notes / decisions

- **Online vs store:** `vw_StorePerformance` filters `StoreSK <> -1` so online sales don't
  distort store productivity. `vw_RegionalSales` keeps the channel split intact for
  cross-channel analysis (OBJ-06).
- **Return rate** is expressed two ways: order-level in `vw_ExecutiveKPIs`
  (returned orders / total orders) and unit-level in `vw_ProductPerformance` /
  `vw_ReturnsAnalysis` (units returned / units sold).
- **Inventory is a periodic snapshot**, so `vw_InventoryHealth` reports only the
  **latest** `SnapshotDateKey` (via a CTE) to avoid summing the same SKU across dates.
- **Shipping** is not modeled as its own fact, so `vw_ShippingPerformance` sources from
  `staging.Shipping` joined to warehouse dims through `staging.Orders`.
- **On-time SLA assumption** (no SLA table in source): on-time if transit days ≤
  Same Day 1 · Express 2 · Standard 5 · Economy 8. Documented in the view; swap in a
  real carrier-SLA table when available.

---

## 5. Verified sample output

| Metric (from `vw_ExecutiveKPIs`) | Value |
|-----------------------------------|------:|
| Total Orders | 49,957 |
| Total Revenue | $720,097,230 |
| Gross Margin | 16.83% |
| Avg Order Value | $14,414 |
| Return Rate | 15.68% |
| Revenue / Store | $8,623,673 |

- Repeat-customer rate (`vw_CustomerAnalysis`): **77.4%** of 18,426 purchasing customers.
- Regional split confirms ~60% store / ~40% e-commerce revenue in every region.
- Top return reasons: Changed Mind, Arrived Late, Wrong Item.

> Note: absolute values (AOV, margin) reflect the **synthetic** dataset's scale, not the
> BRD business targets ($150 AOV, 35% margin). The view math is what matters here and is
> correct; real source data would land within target ranges.

---

## 6. Next step

The database side of the project is complete (schemas → tables → ETL → warehouse → views).
**Next is Power BI:**
1. Connect Power BI Desktop to `RetailDW` and import the 10 `warehouse.vw_*` views.
2. Build the model (relationships primarily handled inside the views; add a date table
   from `DimDate` for time intelligence).
3. Author the 9 dashboards and the DAX measures on top of these views.
