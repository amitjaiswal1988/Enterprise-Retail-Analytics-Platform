# Performance Optimization Guide

> **Audience:** BI developers who need the ShopStar platform to load fast, stay small, and respond instantly — from SQL Server all the way to the Power BI dashboard.
>
> **Format:** Every section uses **WHAT / WHY / WHEN / HOW** in simple English, with real examples from the **ShopStar Retail** project ($719M revenue, ~2M production sales rows, 9 dashboards, 98 DAX measures).

---

## The big picture

Performance is a chain. A slow dashboard can be caused at any link:

```
SQL Server  →  Power Query  →  Data Model  →  DAX  →  Visuals
 (source)      (transform)      (storage)     (calc)   (render)
```

This guide optimizes each link in order.

---

## 1. SQL Server Optimization

**WHAT:** Tuning the `RetailDW` warehouse so queries that feed Power BI run quickly.

**WHY:** Every refresh and every DirectQuery hits SQL Server. If the source is slow, nothing downstream can be fast.

**WHEN:** During warehouse design, and again whenever refresh times grow.

**HOW:**
- **Columnstore indexes (already done):** The large fact tables use clustered columnstore indexes. WHY they help: columnstore stores data column-by-column and compresses it heavily, so a query that sums `SalesAmount` over 2M rows reads only that one compressed column instead of every row. This is the single biggest win for analytics workloads.
- **Query execution plans:** In SSMS, turn on **Include Actual Execution Plan** (Ctrl+M) and run the ETL/reporting queries. Look for expensive **table scans**, **key lookups**, and **hash spills**; add or fix indexes where the plan shows the most cost.
- **Statistics update schedule:** SQL Server uses column statistics to pick a good plan. After each large ETL load, run `UPDATE STATISTICS` (or enable **Auto Update Statistics**) so the optimizer knows the new row counts. Schedule a weekly `sp_updatestats` job for the warehouse.

---

## 2. Power Query Optimization

**WHAT:** Making the transformation (M) layer do less work and push work back to SQL Server.

**WHY:** Power Query runs on every refresh. Cheap, foldable queries refresh in seconds; heavy client-side transforms can take minutes.

**WHEN:** While building each query, and when refresh is slow.

**HOW:**
- **Query folding (fold everything you can):** Folding means Power BI translates your M steps into a single SQL query that SQL Server runs. WHAT folds: filtering rows, removing columns, renaming, grouping, joins on the SQL source. WHAT does **not** fold: adding a custom column with complex logic, `Table.Buffer`, merging with a non-SQL source, some text/date functions. Right-click a step → **View Native Query**; if it is available, that step folded. Keep all foldable steps **before** any non-folding step.
- **Remove unused columns early:** In each query, remove columns the model does not need (this project already drops `_LoadedAt` and the relationship navigation columns). Fewer columns = smaller model and faster refresh.
- **Disable auto date/time:** **File → Options → Data Load → uncheck "Auto date/time"**. WHY: Power BI otherwise creates a hidden date table for **every** date column, which silently bloats the model. ShopStar uses one proper `DimDate` instead.

---

## 3. Data Model Optimization

**WHAT:** Shaping the star schema so it stores less and queries faster.

**WHY:** A smaller, cleaner model uses less memory, refreshes faster, and gives quicker visuals.

**WHEN:** During modeling, and when the `.pbix` size or query time grows.

**HOW:**
- **Use INT keys, not VARCHAR joins:** Relationships join on integer surrogate keys (`RegionSK`, `StoreSK`, `ProductSK`), not text. WHY: integer joins are far faster and compress better than joining on long text strings.
- **Remove high-cardinality columns:** High cardinality = many unique values (order GUIDs, free-text notes, exact timestamps). These compress poorly and swell the model. Drop them, or split a datetime into a date (low cardinality) + time bucket instead of storing exact seconds.
- **Split large tables using aggregations:** For very large facts, add a pre-summarized **aggregation table** (for example, sales by month/region) and let Power BI answer high-level visuals from the small agg table and drill to the detail table only when needed. This keeps executive pages instant even on 2M rows.

---

## 4. DAX Optimization

**WHAT:** Writing measures that the engine can evaluate quickly.

**WHY:** A slow measure makes every visual that uses it slow. Small DAX changes can cut query time dramatically.

**WHEN:** While writing measures, and when a specific visual is slow.

**HOW:**
- **Use VARIABLES (evaluate once, reuse many times):**
  ```DAX
  Gross Margin % =
  VAR Rev = [Total Revenue]
  VAR Profit = [Gross Profit]
  RETURN DIVIDE( Profit, Rev )
  ```
  WHY: a `VAR` is calculated once and reused, instead of re-evaluating `[Total Revenue]` several times in one formula.
- **Avoid `FILTER` on large tables:** Prefer `CALCULATE` with a simple column predicate over wrapping a whole fact table in `FILTER`.
  - Slower: `CALCULATE([Total Revenue], FILTER(FactSales, FactSales[Channel] = "Store"))`
  - Faster: `CALCULATE([Total Revenue], FactSales[Channel] = "Store")`
  WHY: the second form lets the storage engine apply the filter directly instead of iterating row by row in the formula engine.
- **Use `DIVIDE` instead of `/`:** `DIVIDE(a, b)` safely returns blank on divide-by-zero, avoiding errors and an extra `IF` check. Every ratio measure in ShopStar (Margin %, AOV, Return Rate %) uses `DIVIDE`.

---

## 5. Dashboard Rendering

**WHAT:** Designing report pages so they draw quickly on screen.

**WHY:** Each visual sends its own query. Too many visuals = many queries = a slow page, no matter how good the model is.

**WHEN:** During dashboard design and layout review.

**HOW:**
- **Limit visuals per page (max 8–10):** Every ShopStar page keeps to 4 KPI cards + 4 charts (8 visuals). Fewer visuals = fewer queries = faster load.
- **Use Import mode:** ShopStar uses Import (data cached in the model) rather than DirectQuery. WHY: Import serves visuals from fast in-memory storage; DirectQuery sends a live query to SQL Server for every interaction, which is slower for dashboards.
- **Avoid bi-directional cross-filter:** Keep relationships single-direction (dimension → fact). Bi-directional filters create ambiguous, heavy query paths and can also break RLS. Use them only when truly required (some many-to-many cases).
- Also: turn off unused visual interactions, avoid overly complex conditional formatting, and don't put dozens of fields in one table visual.

---

## 6. Incremental Refresh (performance angle)

**WHAT:** Refreshing only recent partitions of a fact table instead of the whole table (full detail in the Deployment guide, Section 5).

**WHY (performance):** ShopStar's 2M-row `FactSales` takes ~10 minutes for a full refresh but ~30 seconds when only the last 7 days are reloaded. Less time, less SQL Server load, less memory churn.

**WHEN:** On date-based fact tables once they pass a few hundred thousand rows.

**HOW — partition strategy:**
- **Hot data:** the last 7 days — refreshed every day.
- **Warm/archive data:** the previous 5 years — loaded once, then left untouched.
- Optionally enable **Detect data changes** on a `_LoadedAt` column so even the hot window only reloads rows that actually changed.

---

## 7. Before vs After Comparison

**WHAT:** A summary of what each optimization improves.

**WHY:** In an interview or a review, this table shows you can measure impact, not just apply tricks.

| Optimization | Improves | Typical Before | Typical After |
|--------------|----------|----------------|---------------|
| Columnstore index on facts | Query time | Full row scan of 2M rows | Compressed column scan (seconds) |
| Query folding | Refresh time | Transforms run in Power BI | One SQL query on the server |
| Remove unused columns | Model size | Larger `.pbix` | Noticeably smaller `.pbix` |
| Disable auto date/time | Model size | Hidden date table per column | One shared `DimDate` |
| INT surrogate keys | Relationship speed | Slow text joins | Fast integer joins |
| VARIABLES in DAX | Measure speed | Measure re-evaluated many times | Evaluated once |
| `CALCULATE` over `FILTER` | Measure speed | Row-by-row iteration | Storage-engine filter |
| Max 8–10 visuals/page | Page load | Many queries per page | Few queries per page |
| Import mode | Interaction speed | Live query per click | Served from memory |
| Incremental refresh | Refresh time | ~10 min full reload | ~30 sec recent-only |

---

## Optimization Checklist (ShopStar)

- [ ] Columnstore indexes on `FactSales`, `FactReturns`, `FactInventory`.
- [ ] Statistics updated after each ETL load.
- [ ] Every Power Query step folds where possible (checked via View Native Query).
- [ ] Unused columns removed; auto date/time disabled.
- [ ] Relationships on INT surrogate keys, single-direction.
- [ ] Measures use `VAR`, `CALCULATE` predicates, and `DIVIDE`.
- [ ] Each page has 8–10 visuals; Import mode; no needless bi-directional filters.
- [ ] Incremental refresh on `FactSales` (7-day hot / 5-year archive).
