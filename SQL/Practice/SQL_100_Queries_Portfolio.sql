-- =============================================================================
-- ShopStar Retail — Enterprise Analytics Platform
-- SQL 100-Query Interview Portfolio  (Database: RetailDW)
-- =============================================================================
-- File:     SQL/Practice/SQL_100_Queries_Portfolio.sql
-- Author:   BI Development Team
-- Created:  2026-07-21
-- Target:   Microsoft SQL Server 2019+  (RetailDW warehouse star schema)
--
-- PURPOSE
--   100 progressively harder, REAL-WORLD business queries an enterprise retail
--   analyst (Walmart / Amazon / Target style) actually writes. Every query is
--   documented with the business problem it answers, the SQL concept it proves,
--   why/when an analyst runs it, the insight it yields, how it maps to a Power BI
--   measure/visual + dashboard, and what an interviewer is testing.
--
-- HOW TO RUN
--   sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Practice/SQL_100_Queries_Portfolio.sql"
--   (or open in SSMS and run a single query at a time — recommended for practice)
--
-- SKILL PROGRESSION
--   Section 1  EDA & Data Profiling ............ Q1–Q20   (Junior)
--   Section 2  Aggregations & GROUP BY ......... Q21–Q35  (Junior→Mid)
--   Section 3  JOINs (star-schema patterns) .... Q36–Q50  (Mid)
--   Section 4  Subqueries & CTEs ............... Q51–Q70  (Mid→Senior)
--   Section 5  Window Functions ................ Q71–Q90  (Senior)
--   Section 6  Advanced Analytics .............. Q91–Q100 (Senior/Lead)
--
-- STAR SCHEMA QUICK REFERENCE
--   Facts:  FactSales, FactReturns, FactInventory
--   Dims:   DimDate, DimCustomer, DimProduct, DimStore, DimEmployee,
--           DimSupplier, DimCategory, DimRegion
--   Keys:   Facts join to dims on surrogate keys (…SK); DimDate on DateKey (INT YYYYMMDD).
--           SK = -1 is the "Unknown" member (online orders have StoreSK/EmployeeSK = -1).
--   Money:  Revenue = LineTotal | COGS = LineCOGS | Profit = GrossProfit
-- =============================================================================

USE RetailDW;
GO

SET NOCOUNT ON;              -- WHAT: suppress "n rows affected" | WHY: cleaner output | WHEN: whole script
SET QUOTED_IDENTIFIER ON;    -- WHAT: ANSI identifier quoting | WHY: consistency across clients
SET ANSI_NULLS ON;           -- WHAT: ANSI NULL comparison    | WHY: predictable NULL logic
GO


-- #############################################################################
-- SECTION 1 — EDA & DATA EXPLORATION  (Q1–Q20)
-- Goal: understand size, shape, ranges and quality of the data BEFORE analysis.
-- #############################################################################

-- ============================================================
-- QUERY #01: Total row count of the sales fact
-- ============================================================
-- BUSINESS PROBLEM: "How big is our sales dataset?"
-- SOLUTION: COUNT(*) over the fact table.
-- SQL CONCEPTS: COUNT, aggregate
-- WHY: Sizing drives refresh strategy, indexing and Power BI mode (Import vs DirectQuery).
-- WHEN: Once, at project kickoff / whenever the warehouse reloads.
-- WHAT: Confirms the fact grain volume (~201K order-line rows).
-- POWER BI IMPACT: Informs whether to use aggregation tables / incremental refresh.
-- DASHBOARD: (foundation — all)
-- INTERVIEW TIP: Tests that you profile data before querying it.
-- ============================================================
SELECT COUNT(*) AS FactSales_RowCount   -- WHAT: count every sales line | WHY: dataset size
FROM warehouse.FactSales;               -- WHAT: source = sales fact


-- ============================================================
-- QUERY #02: Row counts across all core tables (one result set)
-- ============================================================
-- BUSINESS PROBLEM: "How many customers, products, stores, orders do we have?"
-- SOLUTION: UNION ALL of per-table COUNT(*) into a single inventory of the model.
-- SQL CONCEPTS: UNION ALL, COUNT
-- WHY: A single "model census" is the fastest sanity check after an ETL run.
-- WHEN: After every warehouse load; part of the smoke test.
-- WHAT: Expected — DimCustomer 20001, DimProduct 2001, DimStore 51, FactSales 201282, etc.
-- POWER BI IMPACT: Reconcile against Power BI's row counts to detect load gaps.
-- DASHBOARD: (foundation)
-- INTERVIEW TIP: Shows you validate referential completeness, not just one table.
-- ============================================================
SELECT 'DimCustomer'  AS TableName, COUNT(*) AS Rows FROM warehouse.DimCustomer   -- WHAT: customers incl. Unknown
UNION ALL SELECT 'DimProduct',   COUNT(*) FROM warehouse.DimProduct               -- WHAT: products
UNION ALL SELECT 'DimStore',     COUNT(*) FROM warehouse.DimStore                 -- WHAT: stores
UNION ALL SELECT 'DimEmployee',  COUNT(*) FROM warehouse.DimEmployee              -- WHAT: employees
UNION ALL SELECT 'DimSupplier',  COUNT(*) FROM warehouse.DimSupplier              -- WHAT: suppliers
UNION ALL SELECT 'DimDate',      COUNT(*) FROM warehouse.DimDate                  -- WHAT: calendar days
UNION ALL SELECT 'FactSales',    COUNT(*) FROM warehouse.FactSales                -- WHAT: sales lines
UNION ALL SELECT 'FactReturns',  COUNT(*) FROM warehouse.FactReturns              -- WHAT: return lines
UNION ALL SELECT 'FactInventory',COUNT(*) FROM warehouse.FactInventory            -- WHAT: inventory snapshots
ORDER BY TableName;                                                              -- WHY: stable, readable order


-- ============================================================
-- QUERY #03: Distinct value counts (cardinality profiling)
-- ============================================================
-- BUSINESS PROBLEM: "How many unique orders/products/customers actually transacted?"
-- SOLUTION: COUNT(DISTINCT ...) on key columns of the fact.
-- SQL CONCEPTS: COUNT DISTINCT
-- WHY: Cardinality tells you fan-out (lines per order) and active vs total customers.
-- WHEN: EDA phase; also whenever numbers "look off".
-- WHAT: DISTINCT OrderID ≈ 49,957 orders spread over 201,282 lines (~4 lines/order).
-- POWER BI IMPACT: DISTINCTCOUNT measures mirror this; validates AOV denominator.
-- DASHBOARD: Executive, Sales
-- INTERVIEW TIP: Tests understanding of grain vs. business entity counts.
-- ============================================================
SELECT
    COUNT(DISTINCT OrderID)    AS DistinctOrders,      -- WHAT: unique orders | WHY: AOV denominator
    COUNT(DISTINCT CustomerSK) AS ActiveCustomers,     -- WHAT: customers who bought
    COUNT(DISTINCT ProductSK)  AS ProductsSold,        -- WHAT: products that sold
    COUNT(*)                   AS TotalLines           -- WHAT: total line items (grain)
FROM warehouse.FactSales;                              -- WHAT: source fact


-- ============================================================
-- QUERY #04: Date range of sales activity
-- ============================================================
-- BUSINESS PROBLEM: "What time period does our data cover?"
-- SOLUTION: MIN/MAX of the order date via a join to DimDate.
-- SQL CONCEPTS: MIN, MAX, JOIN
-- WHY: Defines dashboard default date filters and incremental-refresh windows.
-- WHEN: EDA; and before configuring RangeStart/RangeEnd in Power BI.
-- WHAT: First and last order dates + total span in days.
-- POWER BI IMPACT: Sets the DimDate range to mark as the model's date table.
-- DASHBOARD: All (date slicer defaults)
-- INTERVIEW TIP: Tests joining facts to a date dimension instead of parsing raw dates.
-- ============================================================
SELECT
    MIN(d.FullDate) AS FirstOrderDate,                          -- WHAT: earliest sale
    MAX(d.FullDate) AS LastOrderDate,                           -- WHAT: latest sale
    DATEDIFF(DAY, MIN(d.FullDate), MAX(d.FullDate)) AS SpanDays -- WHAT: coverage length
FROM warehouse.FactSales fs
JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey;        -- WHY: dates live in DimDate


-- ============================================================
-- QUERY #05: NULL / Unknown-member audit on FactSales dimensions
-- ============================================================
-- BUSINESS PROBLEM: "Do we have orphaned facts pointing to the Unknown member?"
-- SOLUTION: Count rows where each SK = -1 (the reserved Unknown key).
-- SQL CONCEPTS: conditional aggregation (SUM CASE)
-- WHY: High Unknown counts signal broken lookups in ETL (data-quality risk).
-- WHEN: After every load — a governance/QA control.
-- WHAT: StoreSK=-1 & EmployeeSK=-1 are EXPECTED for e-commerce; others should be ~0.
-- POWER BI IMPACT: Prevents "(Blank)" buckets silently absorbing revenue in visuals.
-- DASHBOARD: Data Quality / Executive footnotes
-- INTERVIEW TIP: Tests knowledge of surrogate-key Unknown-member handling.
-- ============================================================
SELECT
    SUM(CASE WHEN CustomerSK = -1 THEN 1 ELSE 0 END) AS UnknownCustomer, -- WHAT: orphan customer (bad)
    SUM(CASE WHEN ProductSK  = -1 THEN 1 ELSE 0 END) AS UnknownProduct,  -- WHAT: orphan product (bad)
    SUM(CASE WHEN StoreSK    = -1 THEN 1 ELSE 0 END) AS OnlineOrUnknownStore, -- WHAT: online (expected)
    SUM(CASE WHEN EmployeeSK = -1 THEN 1 ELSE 0 END) AS OnlineOrUnknownEmp,   -- WHAT: online (expected)
    SUM(CASE WHEN CategorySK = -1 THEN 1 ELSE 0 END) AS UnknownCategory  -- WHAT: orphan category (bad)
FROM warehouse.FactSales;


-- ============================================================
-- QUERY #06: Column-level NULL profiling on a dimension
-- ============================================================
-- BUSINESS PROBLEM: "Which customer attributes are incomplete?"
-- SOLUTION: Count NULLs per nullable column using SUM(CASE WHEN col IS NULL).
-- SQL CONCEPTS: NULL handling, conditional aggregation
-- WHY: Missing Email/Segment weakens targeting and segmentation quality.
-- WHEN: EDA and ongoing data-quality monitoring.
-- WHAT: % of customers missing Email (drives a completeness KPI).
-- POWER BI IMPACT: A "Data Completeness %" card on a governance page.
-- DASHBOARD: Data Quality
-- INTERVIEW TIP: Tests NULL-aware profiling, not assuming clean data.
-- ============================================================
SELECT
    COUNT(*)                                              AS TotalCustomers,        -- WHAT: denominator
    SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END)        AS MissingEmail,          -- WHAT: null emails
    CAST(SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) * 100.0
         / NULLIF(COUNT(*),0) AS DECIMAL(5,2))            AS MissingEmailPct        -- WHAT: completeness gap %
FROM warehouse.DimCustomer
WHERE CustomerSK <> -1;                                                            -- WHY: exclude Unknown member


-- ============================================================
-- QUERY #07: Distinct categorical values (domain discovery)
-- ============================================================
-- BUSINESS PROBLEM: "What sales channels and order statuses exist?"
-- SOLUTION: DISTINCT on the categorical columns.
-- SQL CONCEPTS: DISTINCT
-- WHY: Confirms the allowed domain before building slicers/CHECK logic.
-- WHEN: EDA; whenever a new source feed arrives.
-- WHAT: Channel ∈ {Store, E-commerce}; OrderStatus ∈ {Completed, Shipped, ...}.
-- POWER BI IMPACT: These become slicer values / legend categories.
-- DASHBOARD: Sales, Executive
-- INTERVIEW TIP: Tests you inspect categorical domains before filtering on them.
-- ============================================================
SELECT DISTINCT Channel, OrderStatus   -- WHAT: unique channel/status combos
FROM warehouse.FactSales
ORDER BY Channel, OrderStatus;         -- WHY: readable enumeration


-- ============================================================
-- QUERY #08: Numeric distribution summary of line revenue
-- ============================================================
-- BUSINESS PROBLEM: "What does a typical order line look like in value terms?"
-- SOLUTION: MIN/MAX/AVG/STDEV plus median via PERCENTILE_CONT.
-- SQL CONCEPTS: aggregate stats, PERCENTILE_CONT (ordered-set)
-- WHY: Mean vs median reveals skew (a few huge lines pulling the average up).
-- WHEN: EDA; before choosing average vs median in a KPI.
-- WHAT: Median LineTotal vs mean LineTotal — skew indicator.
-- POWER BI IMPACT: Justifies MEDIANX vs AVERAGE choice for the AOV card.
-- DASHBOARD: Sales, Finance
-- INTERVIEW TIP: Tests statistical literacy (skew, robust vs non-robust stats).
-- ============================================================
-- NOTE: PERCENTILE_CONT is a window function (returns a value per row), so it
-- cannot be mixed with scalar aggregates (MIN/MAX/AVG) in the same ungrouped
-- SELECT. We isolate the median in its own single-value subquery.
SELECT
    MIN(fs.LineTotal)                                               AS MinLine,   -- WHAT: smallest line
    MAX(fs.LineTotal)                                               AS MaxLine,   -- WHAT: largest line
    CAST(AVG(fs.LineTotal) AS DECIMAL(12,2))                        AS MeanLine,  -- WHAT: mean (skew-sensitive)
    CAST(STDEV(fs.LineTotal) AS DECIMAL(12,2))                      AS StdDevLine,-- WHAT: spread
    (SELECT CAST(MAX(MedianLine) AS DECIMAL(12,2)) FROM (           -- WHAT: robust middle (median)
        SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY LineTotal) OVER () AS MedianLine
        FROM warehouse.FactSales) m)                                AS MedianLine
FROM warehouse.FactSales fs;


-- ============================================================
-- QUERY #09: Sales volume by year (trend shape)
-- ============================================================
-- BUSINESS PROBLEM: "Is the business growing year over year?"
-- SOLUTION: GROUP BY calendar year from DimDate.
-- SQL CONCEPTS: JOIN, GROUP BY
-- WHY: The single most-asked exec question — growth trajectory.
-- WHEN: Monthly business reviews.
-- WHAT: Rows/revenue per year to eyeball the growth curve.
-- POWER BI IMPACT: Base for a YoY line chart and growth-% measure.
-- DASHBOARD: Executive, Finance
-- INTERVIEW TIP: Tests grouping on a dimension attribute vs raw date.
-- ============================================================
SELECT
    d.Year                                       AS SalesYear,   -- WHAT: calendar year
    COUNT(*)                                     AS Lines,       -- WHAT: line volume
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))     AS Revenue      -- WHAT: revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
GROUP BY d.Year
ORDER BY d.Year;                                                 -- WHY: chronological


-- ============================================================
-- QUERY #10: Top 10 products by units sold (quick EDA ranking)
-- ============================================================
-- BUSINESS PROBLEM: "Which products move the most volume?"
-- SOLUTION: GROUP BY product, ORDER BY units, TOP 10.
-- SQL CONCEPTS: TOP, GROUP BY, JOIN, ORDER BY
-- WHY: Volume leaders drive replenishment and shelf-space decisions.
-- WHEN: Weekly merchandising review.
-- WHAT: The 10 best-selling SKUs by quantity.
-- POWER BI IMPACT: A "Top N products" bar chart with a TOPN measure.
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests TOP + ORDER BY + join to get a human-readable name.
-- ============================================================
SELECT TOP (10)
    p.ProductName,                               -- WHAT: readable product name
    SUM(fs.Quantity) AS UnitsSold                -- WHAT: total units
FROM warehouse.FactSales fs
JOIN warehouse.DimProduct p ON fs.ProductSK = p.ProductSK
GROUP BY p.ProductName
ORDER BY UnitsSold DESC;                         -- WHY: biggest movers first


-- ============================================================
-- QUERY #11: Orders by channel split (share of business)
-- ============================================================
-- BUSINESS PROBLEM: "How much of our business is online vs in-store?"
-- SOLUTION: GROUP BY Channel with revenue + % of total via window SUM.
-- SQL CONCEPTS: GROUP BY, SUM() OVER () for share
-- WHY: Channel mix guides investment (e-com platform vs store ops).
-- WHEN: Monthly exec review.
-- WHAT: Revenue and % share per channel (expected ~60/40 store/online).
-- POWER BI IMPACT: A donut chart; share = DIVIDE(channel, ALL channel).
-- DASHBOARD: Executive, Regional
-- INTERVIEW TIP: Tests computing "% of total" without a self-join (window SUM).
-- ============================================================
SELECT
    Channel,                                                                   -- WHAT: sales channel
    CAST(SUM(LineTotal) AS DECIMAL(18,2))                       AS Revenue,     -- WHAT: channel revenue
    CAST(SUM(LineTotal) * 100.0
         / SUM(SUM(LineTotal)) OVER () AS DECIMAL(5,2))         AS PctOfTotal   -- WHAT: share of total
FROM warehouse.FactSales
GROUP BY Channel
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #12: Weekend vs weekday sales pattern
-- ============================================================
-- BUSINESS PROBLEM: "Do we sell more on weekends?"
-- SOLUTION: Group by the IsWeekend flag on DimDate.
-- SQL CONCEPTS: JOIN, GROUP BY, BIT flag
-- WHY: Staffing and promo timing depend on the weekly rhythm.
-- WHEN: Workforce planning; promo calendar design.
-- WHAT: Revenue and average line value split weekend vs weekday.
-- POWER BI IMPACT: A day-type slicer; supports "same-store weekend lift" measure.
-- DASHBOARD: Store, Sales
-- INTERVIEW TIP: Tests using pre-computed calendar flags instead of DATEPART logic.
-- ============================================================
SELECT
    CASE WHEN d.IsWeekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS DayType,  -- WHAT: bucket
    COUNT(*)                                  AS Lines,                       -- WHAT: volume
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))  AS Revenue,                     -- WHAT: revenue
    CAST(AVG(fs.LineTotal) AS DECIMAL(12,2))  AS AvgLine                      -- WHAT: avg line value
FROM warehouse.FactSales fs
JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
GROUP BY d.IsWeekend
ORDER BY DayType;


-- ============================================================
-- QUERY #13: Customer distribution by segment
-- ============================================================
-- BUSINESS PROBLEM: "How is our customer base segmented?"
-- SOLUTION: GROUP BY Segment on DimCustomer.
-- SQL CONCEPTS: GROUP BY, filter Unknown member
-- WHY: Segment mix frames marketing strategy and CLV modeling.
-- WHEN: EDA; quarterly customer review.
-- WHAT: Count of customers per segment (Consumer/Corporate/Home Office...).
-- POWER BI IMPACT: Segment slicer + a segment breakdown visual.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests excluding the Unknown member from dimension counts.
-- ============================================================
SELECT
    Segment,                          -- WHAT: customer segment
    COUNT(*) AS Customers             -- WHAT: customers in segment
FROM warehouse.DimCustomer
WHERE CustomerSK <> -1                -- WHY: exclude Unknown placeholder
GROUP BY Segment
ORDER BY Customers DESC;


-- ============================================================
-- QUERY #14: Product price-range distribution
-- ============================================================
-- BUSINESS PROBLEM: "How is our catalog spread across price tiers?"
-- SOLUTION: GROUP BY the PERSISTED PriceRange computed column.
-- SQL CONCEPTS: GROUP BY on computed column
-- WHY: Assortment balance across Budget→Premium affects margin mix.
-- WHEN: Merchandising / assortment planning.
-- WHAT: SKU count per price band.
-- POWER BI IMPACT: Price-band slicer reused across product visuals.
-- DASHBOARD: Product, Finance
-- INTERVIEW TIP: Tests awareness that derived banding can live in the model.
-- ============================================================
SELECT
    PriceRange,                       -- WHAT: pre-computed price tier
    COUNT(*) AS ProductCount          -- WHAT: SKUs in tier
FROM warehouse.DimProduct
WHERE ProductSK <> -1
GROUP BY PriceRange
ORDER BY ProductCount DESC;


-- ============================================================
-- QUERY #15: Stores per region (footprint profiling)
-- ============================================================
-- BUSINESS PROBLEM: "Where is our physical footprint concentrated?"
-- SOLUTION: GROUP BY Region on DimStore.
-- SQL CONCEPTS: GROUP BY
-- WHY: Footprint concentration guides regional revenue expectations.
-- WHEN: EDA; expansion planning.
-- WHAT: Number of stores per region.
-- POWER BI IMPACT: Map bubble sizing / regional store-count card.
-- DASHBOARD: Regional, Store
-- INTERVIEW TIP: Tests basic dimensional grouping and Unknown exclusion.
-- ============================================================
SELECT
    Region,                           -- WHAT: geographic region
    COUNT(*) AS StoreCount            -- WHAT: stores in region
FROM warehouse.DimStore
WHERE StoreSK <> -1
GROUP BY Region
ORDER BY StoreCount DESC;


-- ============================================================
-- QUERY #16: Duplicate-key sanity check on the fact
-- ============================================================
-- BUSINESS PROBLEM: "Could double-counting inflate our revenue?"
-- SOLUTION: GROUP BY the business key (OrderDetailID) HAVING COUNT>1.
-- SQL CONCEPTS: GROUP BY, HAVING
-- WHY: Duplicate order-detail rows would silently overstate sales.
-- WHEN: Post-load QA control.
-- WHAT: Any OrderDetailID appearing more than once (should return 0 rows).
-- POWER BI IMPACT: Guarantees SUM measures are not double-counted.
-- DASHBOARD: Data Quality
-- INTERVIEW TIP: Tests the classic "find duplicates" pattern.
-- ============================================================
SELECT
    OrderDetailID,                    -- WHAT: business key of the line
    COUNT(*) AS Occurrences           -- WHAT: how many times it appears
FROM warehouse.FactSales
GROUP BY OrderDetailID
HAVING COUNT(*) > 1                   -- WHY: only surface duplicates
ORDER BY Occurrences DESC;


-- ============================================================
-- QUERY #17: Referential integrity — facts vs DimDate
-- ============================================================
-- BUSINESS PROBLEM: "Do all sales point to a valid calendar date?"
-- SOLUTION: LEFT JOIN fact→DimDate, keep rows where the date is missing.
-- SQL CONCEPTS: LEFT JOIN, IS NULL (anti-join)
-- WHY: Orphan date keys break time intelligence in Power BI.
-- WHEN: Post-load QA.
-- WHAT: Count of sales whose OrderDateKey has no DimDate match (should be 0).
-- POWER BI IMPACT: Ensures the date relationship is 100% valid before marking date table.
-- DASHBOARD: Data Quality
-- INTERVIEW TIP: Tests the anti-join pattern for orphan detection.
-- ============================================================
SELECT COUNT(*) AS OrphanDateKeys                       -- WHAT: broken date links
FROM warehouse.FactSales fs
LEFT JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
WHERE d.DateKey IS NULL;                                -- WHY: no match => orphan


-- ============================================================
-- QUERY #18: Discount usage profile
-- ============================================================
-- BUSINESS PROBLEM: "How often and how deeply do we discount?"
-- SOLUTION: Bucket DiscountPercent and count lines per bucket.
-- SQL CONCEPTS: CASE bucketing, GROUP BY
-- WHY: Excessive discounting erodes margin; profiling reveals the pattern.
-- WHEN: Pricing/margin reviews.
-- WHAT: Share of lines at 0%, 1–10%, 11–20%, 20%+ discount.
-- POWER BI IMPACT: Discount-depth histogram; feeds a "margin leakage" story.
-- DASHBOARD: Finance, Sales
-- INTERVIEW TIP: Tests CASE-based bucketing of a continuous measure.
-- ============================================================
SELECT
    CASE                                                     -- WHAT: discount depth bucket
        WHEN DiscountPercent = 0            THEN '0% (none)'
        WHEN DiscountPercent <= 10          THEN '1-10%'
        WHEN DiscountPercent <= 20          THEN '11-20%'
        ELSE '20%+'
    END                                       AS DiscountBucket,
    COUNT(*)                                  AS Lines,       -- WHAT: lines in bucket
    CAST(SUM(LineTotal) AS DECIMAL(18,2))     AS Revenue      -- WHAT: revenue in bucket
FROM warehouse.FactSales
GROUP BY CASE
        WHEN DiscountPercent = 0            THEN '0% (none)'
        WHEN DiscountPercent <= 10          THEN '1-10%'
        WHEN DiscountPercent <= 20          THEN '11-20%'
        ELSE '20%+'
    END
ORDER BY Lines DESC;


-- ============================================================
-- QUERY #19: Inventory snapshot coverage
-- ============================================================
-- BUSINESS PROBLEM: "How many snapshot dates and SKUs does inventory cover?"
-- SOLUTION: DISTINCT snapshot dates + product/store cardinality on FactInventory.
-- SQL CONCEPTS: COUNT DISTINCT
-- WHY: Confirms the periodic-snapshot grain before semi-additive measures.
-- WHEN: EDA of the inventory fact.
-- WHAT: # snapshot dates, # products, # stores covered.
-- POWER BI IMPACT: Warns that inventory is semi-additive (don't SUM across dates).
-- DASHBOARD: Inventory
-- INTERVIEW TIP: Tests recognizing snapshot (semi-additive) fact grain.
-- ============================================================
SELECT
    COUNT(DISTINCT SnapshotDateKey) AS SnapshotDates,   -- WHAT: distinct snapshot days
    COUNT(DISTINCT ProductSK)       AS ProductsTracked, -- WHAT: SKUs tracked
    COUNT(DISTINCT StoreSK)         AS StoresTracked,   -- WHAT: stores tracked
    COUNT(*)                        AS TotalRows        -- WHAT: total snapshot rows
FROM warehouse.FactInventory;


-- ============================================================
-- QUERY #20: Return reasons frequency (quality signal)
-- ============================================================
-- BUSINESS PROBLEM: "Why are customers returning products?"
-- SOLUTION: GROUP BY Reason on FactReturns.
-- SQL CONCEPTS: GROUP BY, ORDER BY
-- WHY: Top reasons pinpoint product/logistics fixes that cut returns.
-- WHEN: Monthly returns review.
-- WHAT: Ranked list of return reasons by volume.
-- POWER BI IMPACT: Returns-reason bar chart on the returns page.
-- DASHBOARD: Sales (Returns), Product
-- INTERVIEW TIP: Tests basic frequency analysis of a text dimension.
-- ============================================================
SELECT
    Reason,                                   -- WHAT: reason text
    COUNT(*)                    AS Returns,    -- WHAT: return count
    CAST(SUM(RefundAmount) AS DECIMAL(18,2)) AS TotalRefund  -- WHAT: refunded $
FROM warehouse.FactReturns
GROUP BY Reason
ORDER BY Returns DESC;


-- #############################################################################
-- SECTION 2 — AGGREGATIONS & GROUP BY  (Q21–Q35)
-- Goal: the core measures every retail dashboard is built on.
-- #############################################################################

-- ============================================================
-- QUERY #21: Total revenue, COGS, gross profit and margin %
-- ============================================================
-- BUSINESS PROBLEM: "What are our headline P&L numbers?"
-- SOLUTION: SUM the additive money measures; derive margin with NULLIF guard.
-- SQL CONCEPTS: SUM, safe division
-- WHY: These four numbers anchor every executive conversation.
-- WHEN: Daily/at every board meeting.
-- WHAT: Revenue, COGS, GrossProfit and GrossMargin%.
-- POWER BI IMPACT: Four KPI cards; margin = DIVIDE(profit, revenue).
-- DASHBOARD: Executive, Finance
-- INTERVIEW TIP: Tests divide-by-zero safety with NULLIF.
-- ============================================================
SELECT
    CAST(SUM(LineTotal)   AS DECIMAL(18,2))                                  AS Revenue,     -- WHAT: net sales
    CAST(SUM(LineCOGS)    AS DECIMAL(18,2))                                  AS COGS,        -- WHAT: cost
    CAST(SUM(GrossProfit) AS DECIMAL(18,2))                                  AS GrossProfit, -- WHAT: profit
    CAST(SUM(GrossProfit) * 100.0 / NULLIF(SUM(LineTotal),0) AS DECIMAL(5,2)) AS GrossMarginPct -- WHAT: margin %
FROM warehouse.FactSales;


-- ============================================================
-- QUERY #22: Revenue by region
-- ============================================================
-- BUSINESS PROBLEM: "How does revenue split across regions?"
-- SOLUTION: JOIN fact→DimRegion, SUM revenue grouped by region.
-- SQL CONCEPTS: JOIN, GROUP BY
-- WHY: Regional P&L ownership and target-setting.
-- WHEN: Monthly regional review.
-- WHAT: Revenue per region, ranked.
-- POWER BI IMPACT: Filled map / regional bar; base for RegionSK relationship.
-- DASHBOARD: Regional
-- INTERVIEW TIP: Tests using the conformed RegionSK path vs text region.
-- ============================================================
SELECT
    r.RegionName,                                        -- WHAT: region
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2)) AS Revenue  -- WHAT: revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimRegion r ON fs.RegionSK = r.RegionSK
GROUP BY r.RegionName
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #23: Average order value (AOV)
-- ============================================================
-- BUSINESS PROBLEM: "What is the average value of an order?"
-- SOLUTION: Revenue / distinct orders (NOT / line count).
-- SQL CONCEPTS: SUM, COUNT DISTINCT, division
-- WHY: AOV is a top-line KPI for merchandising and basket strategy.
-- WHEN: Daily KPI card.
-- WHAT: Total revenue divided by unique orders.
-- POWER BI IMPACT: AOV = DIVIDE([Revenue], [Order Count]) — exact mirror.
-- DASHBOARD: Executive, Sales
-- INTERVIEW TIP: Tests the classic AOV-denominator trap (orders, not lines).
-- ============================================================
SELECT
    CAST(SUM(LineTotal) AS DECIMAL(18,2))                             AS Revenue,     -- WHAT: numerator
    COUNT(DISTINCT OrderID)                                           AS Orders,      -- WHAT: denominator
    CAST(SUM(LineTotal) / NULLIF(COUNT(DISTINCT OrderID),0)
         AS DECIMAL(12,2))                                            AS AvgOrderValue -- WHAT: AOV
FROM warehouse.FactSales;


-- ============================================================
-- QUERY #24: Top 10 products by revenue (with margin)
-- ============================================================
-- BUSINESS PROBLEM: "Which products make us the most money?"
-- SOLUTION: GROUP BY product, SUM revenue & profit, TOP 10.
-- SQL CONCEPTS: TOP, GROUP BY, JOIN
-- WHY: Revenue leaders (not just volume) drive strategic focus.
-- WHEN: Weekly merchandising review.
-- WHAT: 10 highest-revenue SKUs plus their margin %.
-- POWER BI IMPACT: Top-N table with a margin conditional-format column.
-- DASHBOARD: Product, Finance
-- INTERVIEW TIP: Tests combining ranking with a derived margin measure.
-- ============================================================
SELECT TOP (10)
    p.ProductName,                                                              -- WHAT: product
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))                       AS Revenue,   -- WHAT: revenue
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))                     AS Profit,    -- WHAT: profit
    CAST(SUM(fs.GrossProfit) * 100.0
         / NULLIF(SUM(fs.LineTotal),0) AS DECIMAL(5,2))           AS MarginPct  -- WHAT: margin %
FROM warehouse.FactSales fs
JOIN warehouse.DimProduct p ON fs.ProductSK = p.ProductSK
GROUP BY p.ProductName
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #25: Revenue by department & category
-- ============================================================
-- BUSINESS PROBLEM: "Which merchandise categories drive the business?"
-- SOLUTION: JOIN fact→DimCategory, group by Department + CategoryName.
-- SQL CONCEPTS: JOIN, multi-level GROUP BY
-- WHY: Category management and space/assortment allocation.
-- WHEN: Monthly category review.
-- WHAT: Revenue & profit per department/category.
-- POWER BI IMPACT: Matrix visual with Department→Category drilldown.
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests grouping across a two-level hierarchy.
-- ============================================================
SELECT
    c.Department,                                            -- WHAT: top-level dept
    c.CategoryName,                                          -- WHAT: category
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2)) AS Revenue,   -- WHAT: revenue
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2)) AS Profit     -- WHAT: profit
FROM warehouse.FactSales fs
JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
GROUP BY c.Department, c.CategoryName
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #26: Monthly revenue trend
-- ============================================================
-- BUSINESS PROBLEM: "How does revenue trend month by month?"
-- SOLUTION: GROUP BY Year + MonthNumber from DimDate.
-- SQL CONCEPTS: JOIN, GROUP BY, ORDER BY on multiple keys
-- WHY: Seasonality and momentum are visible only at monthly grain.
-- WHEN: Monthly performance review.
-- WHAT: One revenue figure per calendar month.
-- POWER BI IMPACT: The primary time-series line chart source.
-- DASHBOARD: Sales, Finance
-- INTERVIEW TIP: Tests correct chronological ordering (Year then Month).
-- ============================================================
SELECT
    d.Year,                                              -- WHAT: year
    d.MonthNumber,                                       -- WHAT: month number (sort)
    d.MonthName,                                         -- WHAT: month label
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2)) AS Revenue  -- WHAT: monthly revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
GROUP BY d.Year, d.MonthNumber, d.MonthName
ORDER BY d.Year, d.MonthNumber;


-- ============================================================
-- QUERY #27: HAVING — high-value stores only
-- ============================================================
-- BUSINESS PROBLEM: "Which stores exceed $5M in revenue?"
-- SOLUTION: GROUP BY store, filter aggregate with HAVING.
-- SQL CONCEPTS: GROUP BY, HAVING (post-aggregate filter)
-- WHY: Focuses attention on the material stores for exec review.
-- WHEN: Quarterly store performance review.
-- WHAT: Stores whose total revenue exceeds the $5M threshold.
-- POWER BI IMPACT: Mirrors a visual-level filter "Revenue > 5M".
-- DASHBOARD: Store
-- INTERVIEW TIP: Tests HAVING vs WHERE distinction (aggregate filter).
-- ============================================================
SELECT
    s.StoreName,                                            -- WHAT: store
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2)) AS Revenue     -- WHAT: revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimStore s ON fs.StoreSK = s.StoreSK
WHERE s.StoreSK <> -1                                       -- WHY: exclude online/unknown
GROUP BY s.StoreName
HAVING SUM(fs.LineTotal) > 5000000                          -- WHY: only material stores
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #28: Units, orders and revenue by segment
-- ============================================================
-- BUSINESS PROBLEM: "How do customer segments compare on spend?"
-- SOLUTION: JOIN fact→DimCustomer, group by Segment, several measures.
-- SQL CONCEPTS: JOIN, multi-measure GROUP BY
-- WHY: Segment economics guide targeting budgets.
-- WHEN: Quarterly customer strategy.
-- WHAT: Orders, units, revenue, AOV per segment.
-- POWER BI IMPACT: Segment comparison matrix.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests several aggregates in one grouped query.
-- ============================================================
SELECT
    c.Segment,                                                                   -- WHAT: segment
    COUNT(DISTINCT fs.OrderID)                                    AS Orders,      -- WHAT: orders
    SUM(fs.Quantity)                                             AS Units,        -- WHAT: units
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))                     AS Revenue,      -- WHAT: revenue
    CAST(SUM(fs.LineTotal) / NULLIF(COUNT(DISTINCT fs.OrderID),0)
         AS DECIMAL(12,2))                                       AS AOV           -- WHAT: AOV
FROM warehouse.FactSales fs
JOIN warehouse.DimCustomer c ON fs.CustomerSK = c.CustomerSK
WHERE c.CustomerSK <> -1
GROUP BY c.Segment
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #29: Average discount by category
-- ============================================================
-- BUSINESS PROBLEM: "Which categories rely most on discounting?"
-- SOLUTION: AVG(DiscountPercent) grouped by category.
-- SQL CONCEPTS: AVG, JOIN, GROUP BY
-- WHY: Heavy-discount categories are margin risks.
-- WHEN: Pricing strategy review.
-- WHAT: Average discount depth per category.
-- POWER BI IMPACT: Feeds a "discount pressure" heat visual.
-- DASHBOARD: Finance, Product
-- INTERVIEW TIP: Tests AVG on a measure grouped by a dimension.
-- ============================================================
SELECT
    c.CategoryName,                                          -- WHAT: category
    CAST(AVG(fs.DiscountPercent) AS DECIMAL(5,2)) AS AvgDiscountPct, -- WHAT: avg discount
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))      AS Revenue -- WHAT: revenue context
FROM warehouse.FactSales fs
JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
GROUP BY c.CategoryName
ORDER BY AvgDiscountPct DESC;


-- ============================================================
-- QUERY #30: Revenue by store type and size
-- ============================================================
-- BUSINESS PROBLEM: "Do larger-format stores earn more?"
-- SOLUTION: Group by the StoreType + StoreSize derived attributes.
-- SQL CONCEPTS: JOIN, GROUP BY on computed columns
-- WHY: Validates the format strategy (big-box vs express).
-- WHEN: Real-estate / format planning.
-- WHAT: Revenue and avg per store by type & size band.
-- POWER BI IMPACT: Format-comparison clustered bar.
-- DASHBOARD: Store
-- INTERVIEW TIP: Tests grouping on PERSISTED computed dimension columns.
-- ============================================================
SELECT
    s.StoreType,                                                                  -- WHAT: format
    s.StoreSize,                                                                  -- WHAT: size band
    COUNT(DISTINCT s.StoreSK)                                    AS Stores,        -- WHAT: store count
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))                     AS Revenue,       -- WHAT: revenue
    CAST(SUM(fs.LineTotal) / NULLIF(COUNT(DISTINCT s.StoreSK),0)
         AS DECIMAL(18,2))                                       AS RevenuePerStore-- WHAT: per-store
FROM warehouse.FactSales fs
JOIN warehouse.DimStore s ON fs.StoreSK = s.StoreSK
WHERE s.StoreSK <> -1
GROUP BY s.StoreType, s.StoreSize
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #31: Return rate by category (units returned / sold)
-- ============================================================
-- BUSINESS PROBLEM: "Which categories get returned most?"
-- SOLUTION: Aggregate sold units and returned units separately, then divide.
-- SQL CONCEPTS: two aggregates via subqueries/joins, ratio
-- WHY: High return categories hurt margin and signal quality issues.
-- WHEN: Monthly returns/quality review.
-- WHAT: Return rate % per category.
-- POWER BI IMPACT: Return-rate KPI by category with target line.
-- DASHBOARD: Sales (Returns), Product
-- INTERVIEW TIP: Tests combining two fact tables at a common grain.
-- ============================================================
SELECT
    c.CategoryName,                                                          -- WHAT: category
    SUM(sold.Units)                                          AS UnitsSold,    -- WHAT: sold units
    ISNULL(SUM(ret.Units),0)                                AS UnitsReturned, -- WHAT: returned units
    CAST(ISNULL(SUM(ret.Units),0) * 100.0
         / NULLIF(SUM(sold.Units),0) AS DECIMAL(5,2))       AS ReturnRatePct -- WHAT: return rate
FROM warehouse.DimCategory c
LEFT JOIN (SELECT CategorySK, SUM(Quantity) AS Units          -- WHAT: sold per category
           FROM warehouse.FactSales GROUP BY CategorySK) sold ON sold.CategorySK = c.CategorySK
LEFT JOIN (SELECT CategorySK, SUM(OriginalQuantity) AS Units  -- WHAT: returned per category
           FROM warehouse.FactReturns GROUP BY CategorySK) ret ON ret.CategorySK = c.CategorySK
WHERE c.CategorySK <> -1
GROUP BY c.CategoryName
ORDER BY ReturnRatePct DESC;


-- ============================================================
-- QUERY #32: Supplier performance — revenue and rating
-- ============================================================
-- BUSINESS PROBLEM: "Which suppliers back our revenue, and are they reliable?"
-- SOLUTION: Join fact→DimSupplier, group by supplier + rating/lead time.
-- SQL CONCEPTS: JOIN, GROUP BY
-- WHY: Vendor management — concentrate on high-revenue, high-rated suppliers.
-- WHEN: Quarterly vendor review.
-- WHAT: Revenue by supplier with rating and lead-time category.
-- POWER BI IMPACT: Supplier scorecard table.
-- DASHBOARD: Product, Finance
-- INTERVIEW TIP: Tests joining facts to a supplier dimension with attributes.
-- ============================================================
SELECT
    sup.SupplierName,                                        -- WHAT: supplier
    sup.Rating,                                              -- WHAT: reliability rating
    sup.LeadTimeCategory,                                    -- WHAT: speed band
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2)) AS Revenue      -- WHAT: revenue backed
FROM warehouse.FactSales fs
JOIN warehouse.DimSupplier sup ON fs.SupplierSK = sup.SupplierSK
WHERE sup.SupplierSK <> -1
GROUP BY sup.SupplierName, sup.Rating, sup.LeadTimeCategory
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #33: Quarterly revenue with GROUPING SETS subtotals
-- ============================================================
-- BUSINESS PROBLEM: "Give me revenue by quarter AND by year totals in one query."
-- SOLUTION: GROUPING SETS to produce both grains + grand total together.
-- SQL CONCEPTS: GROUPING SETS, GROUPING()
-- WHY: One query feeds a report needing detail + subtotals (no extra round-trips).
-- WHEN: Quarterly finance packs.
-- WHAT: Rows per (Year,Quarter), per (Year), and grand total.
-- POWER BI IMPACT: Power BI does subtotals natively, but shows SQL rollup mastery.
-- DASHBOARD: Finance
-- INTERVIEW TIP: Tests advanced GROUP BY (GROUPING SETS / ROLLUP).
-- ============================================================
SELECT
    d.Year,                                                                     -- WHAT: year (NULL on grand total)
    d.Quarter,                                                                  -- WHAT: quarter (NULL on year subtotal)
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))                       AS Revenue,   -- WHAT: revenue
    GROUPING(d.Quarter)                                           AS IsYearSubtotal -- WHAT: 1 => subtotal row
FROM warehouse.FactSales fs
JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
GROUP BY GROUPING SETS ((d.Year, d.Quarter), (d.Year), ())                      -- WHY: detail + subtotals + total
ORDER BY d.Year, d.Quarter;


-- ============================================================
-- QUERY #34: Employee sales productivity (in-store only)
-- ============================================================
-- BUSINESS PROBLEM: "Who are our top-selling associates?"
-- SOLUTION: Join fact→DimEmployee, exclude online (EmployeeSK=-1), rank by revenue.
-- SQL CONCEPTS: JOIN, GROUP BY, filter Unknown
-- WHY: Recognition, coaching and staffing decisions.
-- WHEN: Monthly store-ops review.
-- WHAT: Revenue attributed to each associate.
-- POWER BI IMPACT: Associate leaderboard with a revenue-per-associate KPI.
-- DASHBOARD: Store
-- INTERVIEW TIP: Tests excluding the online Unknown employee from staff metrics.
-- ============================================================
SELECT TOP (15)
    e.FullName,                                              -- WHAT: associate
    e.Role,                                                  -- WHAT: role context
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2)) AS Revenue      -- WHAT: revenue sold
FROM warehouse.FactSales fs
JOIN warehouse.DimEmployee e ON fs.EmployeeSK = e.EmployeeSK
WHERE e.EmployeeSK <> -1                                     -- WHY: exclude online orders
GROUP BY e.FullName, e.Role
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #35: Fiscal-year revenue (retail Jul–Jun calendar)
-- ============================================================
-- BUSINESS PROBLEM: "What is revenue by our FISCAL year, not calendar year?"
-- SOLUTION: Group by the pre-computed FiscalYear on DimDate.
-- SQL CONCEPTS: JOIN, GROUP BY on fiscal attribute
-- WHY: Retail reports on a Jul–Jun fiscal calendar for seasonality alignment.
-- WHEN: Fiscal close and planning.
-- WHAT: Revenue per fiscal year.
-- POWER BI IMPACT: Fiscal hierarchy in the date table for time intelligence.
-- DASHBOARD: Finance, Executive
-- INTERVIEW TIP: Tests fiscal vs calendar awareness in a date dimension.
-- ============================================================
SELECT
    d.FiscalYear,                                            -- WHAT: fiscal year
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2)) AS Revenue      -- WHAT: revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
GROUP BY d.FiscalYear
ORDER BY d.FiscalYear;


-- #############################################################################
-- SECTION 3 — JOINs (INNER / LEFT / FULL / SELF / MULTI-TABLE)  (Q36–Q50)
-- Goal: navigate the star schema like a professional.
-- #############################################################################

-- ============================================================
-- QUERY #36: INNER JOIN — sales enriched with product + category
-- ============================================================
-- BUSINESS PROBLEM: "Show sales with product and category names for reporting."
-- SOLUTION: INNER JOIN fact to DimProduct and DimCategory.
-- SQL CONCEPTS: INNER JOIN (multi-table)
-- WHY: Facts store keys, not names — joins produce human-readable output.
-- WHEN: Any detailed report/drillthrough.
-- WHAT: A denormalized sample of enriched sales lines.
-- POWER BI IMPACT: The relationships that replace these joins in the model.
-- DASHBOARD: Sales, Product
-- INTERVIEW TIP: Tests basic star-schema navigation via INNER JOIN.
-- ============================================================
SELECT TOP (20)
    fs.OrderID,                       -- WHAT: order
    p.ProductName,                    -- WHAT: product name
    c.CategoryName,                   -- WHAT: category name
    fs.Quantity,                      -- WHAT: units
    fs.LineTotal                      -- WHAT: line revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimProduct  p ON fs.ProductSK  = p.ProductSK   -- WHY: get product name
JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK  -- WHY: get category name
ORDER BY fs.LineTotal DESC;


-- ============================================================
-- QUERY #37: LEFT JOIN — all products incl. those never sold
-- ============================================================
-- BUSINESS PROBLEM: "Which catalog products have ZERO sales?"
-- SOLUTION: LEFT JOIN DimProduct→FactSales, keep NULL matches.
-- SQL CONCEPTS: LEFT JOIN, IS NULL, anti-pattern for "missing"
-- WHY: Dead SKUs tie up catalog/inventory and should be delisted.
-- WHEN: Assortment rationalization.
-- WHAT: Products with no matching sales line.
-- POWER BI IMPACT: "No-sale SKU" list; needs LEFT-join semantics preserved.
-- DASHBOARD: Product, Inventory
-- INTERVIEW TIP: Tests LEFT JOIN + IS NULL to find non-participants.
-- ============================================================
SELECT
    p.ProductID,                      -- WHAT: product id
    p.ProductName                     -- WHAT: product name
FROM warehouse.DimProduct p
LEFT JOIN warehouse.FactSales fs ON fs.ProductSK = p.ProductSK  -- WHY: keep unsold products
WHERE p.ProductSK <> -1
  AND fs.ProductSK IS NULL;           -- WHY: no sales => never sold


-- ============================================================
-- QUERY #38: Multi-table join — full sales context (4 dims)
-- ============================================================
-- BUSINESS PROBLEM: "Give a 360° view: who bought what, where, and when."
-- SOLUTION: Join fact to Customer, Product, Store, Date dimensions.
-- SQL CONCEPTS: 4+ table JOIN
-- WHY: Rich context enables drillthrough and root-cause analysis.
-- WHEN: Ad-hoc investigations / drillthrough pages.
-- WHAT: One fully enriched sample of transactions.
-- POWER BI IMPACT: Equivalent of the vw_FactSales_WithDimensions view.
-- DASHBOARD: Sales (drillthrough)
-- INTERVIEW TIP: Tests composing many joins without losing the fact grain.
-- ============================================================
SELECT TOP (20)
    d.FullDate,                       -- WHAT: order date
    cu.FullName      AS Customer,     -- WHAT: buyer
    p.ProductName    AS Product,      -- WHAT: product
    s.StoreName      AS Store,        -- WHAT: store (or Unknown/Online)
    fs.Quantity,                      -- WHAT: units
    fs.LineTotal                      -- WHAT: revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimDate     d  ON fs.OrderDateKey = d.DateKey
JOIN warehouse.DimCustomer cu ON fs.CustomerSK   = cu.CustomerSK
JOIN warehouse.DimProduct  p  ON fs.ProductSK    = p.ProductSK
JOIN warehouse.DimStore    s  ON fs.StoreSK      = s.StoreSK
ORDER BY fs.LineTotal DESC;


-- ============================================================
-- QUERY #39: SELF JOIN — employee → manager hierarchy
-- ============================================================
-- BUSINESS PROBLEM: "Who reports to whom?"
-- SOLUTION: Self-join DimEmployee on ManagerID = EmployeeID.
-- SQL CONCEPTS: SELF JOIN
-- WHY: Org structure underpins hierarchical RLS and rollups.
-- WHEN: HR reporting; RLS design.
-- WHAT: Each employee paired with their manager's name.
-- POWER BI IMPACT: Basis for a PATH() org hierarchy in DAX.
-- DASHBOARD: Store / HR
-- INTERVIEW TIP: Tests the self-join pattern (aliasing the same table twice).
-- ============================================================
SELECT TOP (25)
    e.EmployeeID,                     -- WHAT: employee id
    e.FullName    AS Employee,        -- WHAT: employee
    e.Role,                           -- WHAT: role
    m.FullName    AS Manager          -- WHAT: manager (NULL for top)
FROM warehouse.DimEmployee e
LEFT JOIN warehouse.DimEmployee m ON e.ManagerID = m.EmployeeID  -- WHY: link to manager row
WHERE e.EmployeeSK <> -1
ORDER BY e.EmployeeID;


-- ============================================================
-- QUERY #40: FULL OUTER JOIN — sold vs returned product reconciliation
-- ============================================================
-- BUSINESS PROBLEM: "Reconcile products that sold vs products that were returned."
-- SOLUTION: FULL OUTER JOIN aggregated sales and returns per product.
-- SQL CONCEPTS: FULL OUTER JOIN, COALESCE
-- WHY: Surfaces products returned but with mismatched sales attribution.
-- WHEN: Data-quality / returns reconciliation.
-- WHAT: Products appearing in either or both streams.
-- POWER BI IMPACT: Reconciliation table for the returns page.
-- DASHBOARD: Sales (Returns)
-- INTERVIEW TIP: Tests FULL OUTER JOIN + COALESCE to unify two key sets.
-- ============================================================
SELECT
    COALESCE(sl.ProductSK, rt.ProductSK)          AS ProductSK,  -- WHAT: unified key
    ISNULL(sl.Units, 0)                           AS UnitsSold,   -- WHAT: sold
    ISNULL(rt.Units, 0)                           AS UnitsReturned-- WHAT: returned
FROM (SELECT ProductSK, SUM(Quantity)         AS Units FROM warehouse.FactSales   GROUP BY ProductSK) sl
FULL OUTER JOIN
     (SELECT ProductSK, SUM(OriginalQuantity) AS Units FROM warehouse.FactReturns GROUP BY ProductSK) rt
     ON sl.ProductSK = rt.ProductSK
ORDER BY UnitsReturned DESC;


-- ============================================================
-- QUERY #41: Store revenue with region + size context
-- ============================================================
-- BUSINESS PROBLEM: "Rank stores with their region and format for context."
-- SOLUTION: Join fact→DimStore (which already carries Region + StoreSize).
-- SQL CONCEPTS: JOIN, GROUP BY, ORDER BY
-- WHY: Context makes a raw ranking actionable.
-- WHEN: Store performance review.
-- WHAT: Store revenue with region and size attributes.
-- POWER BI IMPACT: Store table with region slicer.
-- DASHBOARD: Store, Regional
-- INTERVIEW TIP: Tests pulling multiple dimension attributes in one grouping.
-- ============================================================
SELECT
    s.StoreName,                                            -- WHAT: store
    s.Region,                                               -- WHAT: region
    s.StoreSize,                                            -- WHAT: size band
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2)) AS Revenue     -- WHAT: revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimStore s ON fs.StoreSK = s.StoreSK
WHERE s.StoreSK <> -1
GROUP BY s.StoreName, s.Region, s.StoreSize
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #42: Customer orders with store details (channel mix per customer)
-- ============================================================
-- BUSINESS PROBLEM: "For each customer, how do they split store vs online?"
-- SOLUTION: Join fact→Customer, conditionally sum by Channel.
-- SQL CONCEPTS: JOIN, conditional aggregation
-- WHY: Omni-channel behavior informs CRM and personalization.
-- WHEN: Customer 360 analysis.
-- WHAT: Store vs online revenue per customer.
-- POWER BI IMPACT: Channel-mix columns on a customer detail page.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests pivoting a category into columns with SUM(CASE).
-- ============================================================
SELECT TOP (20)
    cu.FullName,                                                                  -- WHAT: customer
    CAST(SUM(CASE WHEN fs.Channel = 'Store'      THEN fs.LineTotal ELSE 0 END) AS DECIMAL(18,2)) AS StoreRevenue,  -- WHAT: in-store
    CAST(SUM(CASE WHEN fs.Channel = 'E-commerce' THEN fs.LineTotal ELSE 0 END) AS DECIMAL(18,2)) AS OnlineRevenue, -- WHAT: online
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))                                                     AS TotalRevenue   -- WHAT: total
FROM warehouse.FactSales fs
JOIN warehouse.DimCustomer cu ON fs.CustomerSK = cu.CustomerSK
WHERE cu.CustomerSK <> -1
GROUP BY cu.FullName
ORDER BY TotalRevenue DESC;


-- ============================================================
-- QUERY #43: Manager rollup — team revenue by manager
-- ============================================================
-- BUSINESS PROBLEM: "How much revenue does each manager's team generate?"
-- SOLUTION: Join sales→employee, self-join to manager, group by manager.
-- SQL CONCEPTS: multi-join incl. self-join, GROUP BY
-- WHY: Manager-level accountability and incentive plans.
-- WHEN: Monthly performance/commission cycles.
-- WHAT: Revenue aggregated to the managing employee.
-- POWER BI IMPACT: Hierarchical rollup a PATH()-based measure would replicate.
-- DASHBOARD: Store / HR
-- INTERVIEW TIP: Tests combining a fact join with a dimension self-join.
-- ============================================================
SELECT
    m.FullName                                    AS Manager,     -- WHAT: manager
    COUNT(DISTINCT e.EmployeeID)                  AS TeamSize,     -- WHAT: reports
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))      AS TeamRevenue   -- WHAT: team revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimEmployee e ON fs.EmployeeSK = e.EmployeeSK
JOIN warehouse.DimEmployee m ON e.ManagerID   = m.EmployeeID      -- WHY: attribute to manager
WHERE e.EmployeeSK <> -1
GROUP BY m.FullName
ORDER BY TeamRevenue DESC;


-- ============================================================
-- QUERY #44: Cross-fact join — sales vs current inventory per product
-- ============================================================
-- BUSINESS PROBLEM: "Are best-sellers adequately stocked right now?"
-- SOLUTION: Aggregate sales and latest inventory per product, join them.
-- SQL CONCEPTS: multiple aggregated subqueries, JOIN, latest-snapshot filter
-- WHY: Prevents stockouts on high-velocity SKUs (lost sales).
-- WHEN: Weekly replenishment planning.
-- WHAT: Units sold vs current on-hand per product.
-- POWER BI IMPACT: "Sell-through vs stock" scatter for replenishment.
-- DASHBOARD: Inventory, Product
-- INTERVIEW TIP: Tests joining a transactional fact to a snapshot fact correctly.
-- ============================================================
SELECT TOP (20)
    p.ProductName,                                          -- WHAT: product
    sold.UnitsSold,                                         -- WHAT: demand
    inv.OnHand                                              -- WHAT: current supply
FROM warehouse.DimProduct p
JOIN (SELECT ProductSK, SUM(Quantity) AS UnitsSold          -- WHAT: total demand
      FROM warehouse.FactSales GROUP BY ProductSK) sold ON sold.ProductSK = p.ProductSK
JOIN (SELECT ProductSK, SUM(QuantityOnHand) AS OnHand       -- WHAT: latest-snapshot supply
      FROM warehouse.FactInventory
      WHERE SnapshotDateKey = (SELECT MAX(SnapshotDateKey) FROM warehouse.FactInventory)
      GROUP BY ProductSK) inv ON inv.ProductSK = p.ProductSK
ORDER BY sold.UnitsSold DESC;


-- ============================================================
-- QUERY #45: Customers who never returned anything (LEFT anti-join)
-- ============================================================
-- BUSINESS PROBLEM: "Which customers have a perfect no-return history?"
-- SOLUTION: LEFT JOIN customer→returns, keep NULLs.
-- SQL CONCEPTS: LEFT JOIN anti-pattern
-- WHY: Loyal, low-hassle customers are ideal for premium offers.
-- WHEN: Loyalty targeting.
-- WHAT: Customers with zero returns.
-- POWER BI IMPACT: A "no-return" segment flag.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests anti-join reasoning again on the customer grain.
-- ============================================================
SELECT COUNT(*) AS CustomersWithNoReturns             -- WHAT: count of clean customers
FROM warehouse.DimCustomer c
LEFT JOIN warehouse.FactReturns r ON r.CustomerSK = c.CustomerSK
WHERE c.CustomerSK <> -1
  AND r.CustomerSK IS NULL;                            -- WHY: no return rows => never returned


-- ============================================================
-- QUERY #46: Region × category revenue matrix
-- ============================================================
-- BUSINESS PROBLEM: "Which categories over/under-index by region?"
-- SOLUTION: Join fact→Region and →Category, group by both.
-- SQL CONCEPTS: multi-dim GROUP BY
-- WHY: Regional assortment tuning (local preferences).
-- WHEN: Regional merchandising planning.
-- WHAT: Revenue at region×category grain.
-- POWER BI IMPACT: Matrix visual with region rows / category columns.
-- DASHBOARD: Regional, Product
-- INTERVIEW TIP: Tests two-dimension grouping producing a matrix shape.
-- ============================================================
SELECT
    r.RegionName,                                           -- WHAT: region
    c.CategoryName,                                         -- WHAT: category
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2)) AS Revenue     -- WHAT: revenue
FROM warehouse.FactSales fs
JOIN warehouse.DimRegion   r ON fs.RegionSK   = r.RegionSK
JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
GROUP BY r.RegionName, c.CategoryName
ORDER BY r.RegionName, Revenue DESC;


-- ============================================================
-- QUERY #47: Orders with shipping details (warehouse × staging bridge)
-- ============================================================
-- BUSINESS PROBLEM: "Attach shipping performance to each order."
-- SOLUTION: Join FactSales' OrderID to staging.Shipping (no shipping fact yet).
-- SQL CONCEPTS: JOIN across layers, DISTINCT to order grain
-- WHY: Shipping is modeled only in staging; bridge to report on it.
-- WHEN: Logistics/shipping analysis.
-- WHAT: Per-order carrier, mode and transit days.
-- POWER BI IMPACT: Feeds vw_ShippingPerformance (staging-sourced).
-- DASHBOARD: Shipping
-- INTERVIEW TIP: Tests joining across schema layers on a degenerate key.
-- ============================================================
SELECT DISTINCT TOP (20)
    fs.OrderID,                       -- WHAT: order
    sh.Carrier,                       -- WHAT: carrier
    sh.ShipMode,                      -- WHAT: service level
    sh.TransitDays                    -- WHAT: delivery speed
FROM warehouse.FactSales fs
JOIN staging.Shipping sh ON sh.OrderID = fs.OrderID   -- WHY: shipping lives in staging
ORDER BY sh.TransitDays DESC;


-- ============================================================
-- QUERY #48: New customers per join-year cohort
-- ============================================================
-- BUSINESS PROBLEM: "How fast is our customer base growing by signup year?"
-- SOLUTION: GROUP BY the JoinYear persisted column on DimCustomer.
-- SQL CONCEPTS: GROUP BY on computed column
-- WHY: Acquisition pace and cohort sizing for retention analysis.
-- WHEN: Growth reviews.
-- WHAT: New customers acquired per year.
-- POWER BI IMPACT: Acquisition bar chart; cohort base.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests grouping on a derived year attribute.
-- ============================================================
SELECT
    JoinYear,                         -- WHAT: signup year
    COUNT(*) AS NewCustomers          -- WHAT: acquisitions
FROM warehouse.DimCustomer
WHERE CustomerSK <> -1
GROUP BY JoinYear
ORDER BY JoinYear;


-- ============================================================
-- QUERY #49: Profit contribution by department (share of profit)
-- ============================================================
-- BUSINESS PROBLEM: "Which departments contribute most of our PROFIT (not sales)?"
-- SOLUTION: Group profit by department, compute % of total with window SUM.
-- SQL CONCEPTS: JOIN, GROUP BY, SUM() OVER ()
-- WHY: Revenue leaders aren't always profit leaders — margin matters.
-- WHEN: Profitability reviews.
-- WHAT: Profit and % of total profit per department.
-- POWER BI IMPACT: Profit-contribution donut; % via DIVIDE over ALL.
-- DASHBOARD: Finance
-- INTERVIEW TIP: Tests "% of total" using a window over a grouped aggregate.
-- ============================================================
SELECT
    c.Department,                                                                -- WHAT: department
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))                    AS Profit,      -- WHAT: profit
    CAST(SUM(fs.GrossProfit) * 100.0
         / SUM(SUM(fs.GrossProfit)) OVER () AS DECIMAL(5,2))      AS PctOfProfit  -- WHAT: profit share
FROM warehouse.FactSales fs
JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
GROUP BY c.Department
ORDER BY Profit DESC;


-- ============================================================
-- QUERY #50: Store staffing vs revenue (headcount join)
-- ============================================================
-- BUSINESS PROBLEM: "Are stores staffed in line with their revenue?"
-- SOLUTION: Count employees per store (via StoreID) and join to store revenue.
-- SQL CONCEPTS: two aggregates joined, business-key join
-- WHY: Labor efficiency — revenue per head by store.
-- WHEN: Workforce planning.
-- WHAT: Headcount and revenue-per-employee per store.
-- POWER BI IMPACT: Labor-productivity KPI on the store page.
-- DASHBOARD: Store
-- INTERVIEW TIP: Tests joining on a business key (StoreID) across dim + fact aggregates.
-- ============================================================
SELECT
    s.StoreName,                                                                  -- WHAT: store
    hc.HeadCount,                                                                 -- WHAT: staff count
    CAST(rev.Revenue AS DECIMAL(18,2))                            AS Revenue,      -- WHAT: revenue
    CAST(rev.Revenue / NULLIF(hc.HeadCount,0) AS DECIMAL(18,2))   AS RevenuePerHead-- WHAT: productivity
FROM warehouse.DimStore s
JOIN (SELECT StoreID, COUNT(*) AS HeadCount                       -- WHAT: staff per store
      FROM warehouse.DimEmployee WHERE EmployeeSK <> -1 GROUP BY StoreID) hc ON hc.StoreID = s.StoreID
JOIN (SELECT s2.StoreID, SUM(fs.LineTotal) AS Revenue             -- WHAT: revenue per store
      FROM warehouse.FactSales fs JOIN warehouse.DimStore s2 ON fs.StoreSK = s2.StoreSK
      WHERE s2.StoreSK <> -1 GROUP BY s2.StoreID) rev ON rev.StoreID = s.StoreID
WHERE s.StoreSK <> -1
ORDER BY RevenuePerHead DESC;


-- #############################################################################
-- SECTION 4 — SUBQUERIES & CTEs  (Q51–Q70)
-- Goal: composable logic, correlated filters, and recursion.
-- #############################################################################

-- ============================================================
-- QUERY #51: Scalar subquery — products priced above catalog average
-- ============================================================
-- BUSINESS PROBLEM: "Which products are priced above the catalog average?"
-- SOLUTION: Compare UnitPrice to a scalar subquery of AVG(UnitPrice).
-- SQL CONCEPTS: scalar subquery in WHERE
-- WHY: Identifies premium SKUs for positioning.
-- WHEN: Pricing analysis.
-- WHAT: Products above the average price line.
-- POWER BI IMPACT: A calculated "above avg price" flag.
-- DASHBOARD: Product, Finance
-- INTERVIEW TIP: Tests scalar subquery comparison.
-- ============================================================
SELECT
    ProductName,                                              -- WHAT: product
    UnitPrice                                                 -- WHAT: price
FROM warehouse.DimProduct
WHERE ProductSK <> -1
  AND UnitPrice > (SELECT AVG(UnitPrice)                      -- WHY: benchmark = catalog average
                   FROM warehouse.DimProduct WHERE ProductSK <> -1)
ORDER BY UnitPrice DESC;


-- ============================================================
-- QUERY #52: WHERE IN subquery — customers who bought Electronics
-- ============================================================
-- BUSINESS PROBLEM: "Who has ever purchased in the Electronics department?"
-- SOLUTION: Filter customers whose SK appears in a subquery of Electronics sales.
-- SQL CONCEPTS: IN subquery
-- WHY: Category-affinity targeting for cross-sell.
-- WHEN: Campaign audience building.
-- WHAT: Distinct customers with any Electronics purchase.
-- POWER BI IMPACT: Audience segment; equivalent to a measure filter.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests IN-subquery membership filtering.
-- ============================================================
SELECT
    cu.FullName                                              -- WHAT: customer
FROM warehouse.DimCustomer cu
WHERE cu.CustomerSK IN (                                     -- WHY: only Electronics buyers
    SELECT DISTINCT fs.CustomerSK
    FROM warehouse.FactSales fs
    JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
    WHERE c.Department = 'Electronics'
)
ORDER BY cu.FullName;


-- ============================================================
-- QUERY #53: Correlated subquery — each customer's top order value
-- ============================================================
-- BUSINESS PROBLEM: "What is each customer's single largest order?"
-- SOLUTION: Correlated subquery returning MAX order total for that customer.
-- SQL CONCEPTS: correlated subquery
-- WHY: Peak spend indicates capacity for premium offers.
-- WHEN: CLV / upsell analysis.
-- WHAT: Max order value per customer.
-- POWER BI IMPACT: A MAXX-based customer measure.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests correlated subquery referencing the outer row.
-- ============================================================
SELECT TOP (20)
    cu.FullName,                                                         -- WHAT: customer
    (SELECT MAX(orderTot.OrderTotal)                                     -- WHY: correlated per customer
     FROM (SELECT fs.OrderID, SUM(fs.LineTotal) AS OrderTotal
           FROM warehouse.FactSales fs
           WHERE fs.CustomerSK = cu.CustomerSK                           -- correlation point
           GROUP BY fs.OrderID) orderTot) AS LargestOrder
FROM warehouse.DimCustomer cu
WHERE cu.CustomerSK <> -1
ORDER BY LargestOrder DESC;


-- ============================================================
-- QUERY #54: EXISTS — stores that have any low-stock item now
-- ============================================================
-- BUSINESS PROBLEM: "Which stores currently have at least one low-stock SKU?"
-- SOLUTION: EXISTS against the latest inventory snapshot with IsLowStock=1.
-- SQL CONCEPTS: EXISTS, correlated existence check
-- WHY: Prioritize replenishment visits/actions.
-- WHEN: Daily inventory ops.
-- WHAT: Stores flagged for low stock.
-- POWER BI IMPACT: Alert list on the inventory page.
-- DASHBOARD: Inventory, Store
-- INTERVIEW TIP: Tests EXISTS vs IN (existence semantics, short-circuit).
-- ============================================================
SELECT
    s.StoreName                                                      -- WHAT: store
FROM warehouse.DimStore s
WHERE s.StoreSK <> -1
  AND EXISTS (                                                       -- WHY: any low-stock item?
      SELECT 1
      FROM warehouse.FactInventory i
      WHERE i.StoreSK = s.StoreSK
        AND i.IsLowStock = 1
        AND i.SnapshotDateKey = (SELECT MAX(SnapshotDateKey) FROM warehouse.FactInventory)
  )
ORDER BY s.StoreName;


-- ============================================================
-- QUERY #55: CTE — above-average-spend customers
-- ============================================================
-- BUSINESS PROBLEM: "Which customers spend more than the average customer?"
-- SOLUTION: CTE of per-customer spend, then compare to its average.
-- SQL CONCEPTS: CTE (WITH), aggregate + benchmark
-- WHY: Identifies high-value customers for retention focus.
-- WHEN: CRM segmentation.
-- WHAT: Customers whose total spend exceeds the mean.
-- POWER BI IMPACT: "Above-average spender" flag/segment.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests CTE readability vs nested subqueries.
-- ============================================================
WITH CustomerSpend AS (                                              -- WHAT: per-customer spend
    SELECT fs.CustomerSK, SUM(fs.LineTotal) AS Spend
    FROM warehouse.FactSales fs
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK
)
SELECT
    cu.FullName,                                                     -- WHAT: customer
    CAST(cs.Spend AS DECIMAL(18,2)) AS Spend                         -- WHAT: total spend
FROM CustomerSpend cs
JOIN warehouse.DimCustomer cu ON cu.CustomerSK = cs.CustomerSK
WHERE cs.Spend > (SELECT AVG(Spend) FROM CustomerSpend)             -- WHY: above the average
ORDER BY cs.Spend DESC;


-- ============================================================
-- QUERY #56: Multi-CTE — monthly revenue + running total
-- ============================================================
-- BUSINESS PROBLEM: "Show monthly revenue and the cumulative year total."
-- SOLUTION: One CTE aggregates by month; outer query adds a running SUM window.
-- SQL CONCEPTS: CTE feeding a window function
-- WHY: Cumulative pacing vs plan is a standard finance view.
-- WHEN: Monthly finance pacing.
-- WHAT: Monthly revenue plus cumulative-to-date.
-- POWER BI IMPACT: TOTALYTD measure equivalent.
-- DASHBOARD: Finance
-- INTERVIEW TIP: Tests layering a window function on a CTE result.
-- ============================================================
WITH Monthly AS (                                                   -- WHAT: revenue per month
    SELECT d.Year, d.MonthNumber, d.MonthName,
           SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.MonthNumber, d.MonthName
)
SELECT
    Year, MonthName,
    CAST(Revenue AS DECIMAL(18,2))                                              AS Revenue,      -- WHAT: month
    CAST(SUM(Revenue) OVER (PARTITION BY Year ORDER BY MonthNumber)
         AS DECIMAL(18,2))                                                      AS RunningYTD    -- WHAT: cumulative
FROM Monthly
ORDER BY Year, MonthNumber;


-- ============================================================
-- QUERY #57: Recursive CTE — full employee org chart with levels
-- ============================================================
-- BUSINESS PROBLEM: "Produce the org chart with each employee's depth/level."
-- SOLUTION: Recursive CTE anchored on top managers (ManagerID IS NULL).
-- SQL CONCEPTS: recursive CTE, hierarchy level
-- WHY: Powers hierarchical RLS and org rollups.
-- WHEN: HR org design; RLS setup.
-- WHAT: Each employee with hierarchy level and path.
-- POWER BI IMPACT: Feeds PATH()/PATHCONTAINS hierarchical security.
-- DASHBOARD: Store / HR
-- INTERVIEW TIP: The classic recursive-CTE interview question.
-- ============================================================
WITH OrgChart AS (
    -- Anchor: top of the tree (no manager)
    SELECT EmployeeID, FullName, ManagerID,
           0 AS Lvl,                                            -- WHAT: root level
           CAST(FullName AS VARCHAR(1000)) AS OrgPath           -- WHAT: path from root
    FROM warehouse.DimEmployee
    WHERE ManagerID IS NULL AND EmployeeSK <> -1
    UNION ALL
    -- Recursive member: attach reports to their manager
    SELECT e.EmployeeID, e.FullName, e.ManagerID,
           oc.Lvl + 1,                                          -- WHY: one level deeper
           CAST(oc.OrgPath + ' > ' + e.FullName AS VARCHAR(1000))
    FROM warehouse.DimEmployee e
    JOIN OrgChart oc ON e.ManagerID = oc.EmployeeID
    WHERE e.EmployeeSK <> -1
)
SELECT TOP (30) EmployeeID, Lvl, FullName, OrgPath              -- WHAT: hierarchy output
FROM OrgChart
ORDER BY Lvl, EmployeeID
OPTION (MAXRECURSION 1000);                                    -- WHY: allow deep trees


-- ============================================================
-- QUERY #58: Correlated subquery — products above their category avg price
-- ============================================================
-- BUSINESS PROBLEM: "Which products are premium WITHIN their own category?"
-- SOLUTION: Correlated subquery comparing to the category's average price.
-- SQL CONCEPTS: correlated subquery with a matching predicate
-- WHY: Relative (not absolute) premium positioning per category.
-- WHEN: Category pricing review.
-- WHAT: Products priced above their category mean.
-- POWER BI IMPACT: Category-relative price index measure.
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests correlation on a grouping attribute (CategoryID).
-- ============================================================
SELECT
    p.ProductName, p.CategoryName, p.UnitPrice                  -- WHAT: product + price
FROM warehouse.DimProduct p
WHERE p.ProductSK <> -1
  AND p.UnitPrice > (SELECT AVG(p2.UnitPrice)                  -- WHY: category benchmark
                     FROM warehouse.DimProduct p2
                     WHERE p2.CategoryID = p.CategoryID         -- correlation on category
                       AND p2.ProductSK <> -1)
ORDER BY p.CategoryName, p.UnitPrice DESC;


-- ============================================================
-- QUERY #59: Derived table — average basket size per order
-- ============================================================
-- BUSINESS PROBLEM: "How many items are in a typical order?"
-- SOLUTION: Derived table of units per order, then average it.
-- SQL CONCEPTS: derived table (subquery in FROM)
-- WHY: Basket size drives cross-sell and bundling strategy.
-- WHEN: Merchandising analysis.
-- WHAT: Average units per order across the business.
-- POWER BI IMPACT: AVERAGEX(orders, units) measure.
-- DASHBOARD: Sales
-- INTERVIEW TIP: Tests aggregating an already-aggregated set (two-step).
-- ============================================================
SELECT
    CAST(AVG(CAST(ob.Units AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS AvgBasketUnits -- WHAT: avg items/order
FROM (SELECT OrderID, SUM(Quantity) AS Units                    -- WHAT: units per order
      FROM warehouse.FactSales
      GROUP BY OrderID) ob;


-- ============================================================
-- QUERY #60: CTE + NOT IN — customers who never bought a returned-heavy product
-- ============================================================
-- BUSINESS PROBLEM: "Which customers avoided our most-returned products?"
-- SOLUTION: CTE of high-return products, then customers with no such purchase.
-- SQL CONCEPTS: CTE, NOT IN / NOT EXISTS
-- WHY: Behavior segmentation and quality-perception analysis.
-- WHEN: Quality / loyalty analysis.
-- WHAT: Customers who never purchased a top-returned SKU.
-- POWER BI IMPACT: Behavioral segment flag.
-- DASHBOARD: Customer, Product
-- INTERVIEW TIP: Tests combining a CTE with NOT EXISTS for exclusion.
-- ============================================================
WITH HighReturnProducts AS (                                    -- WHAT: worst-return SKUs
    SELECT TOP (20) ProductSK
    FROM warehouse.FactReturns
    GROUP BY ProductSK
    ORDER BY SUM(OriginalQuantity) DESC
)
SELECT COUNT(*) AS CustomersAvoidingReturnHeavy                 -- WHAT: count
FROM warehouse.DimCustomer cu
WHERE cu.CustomerSK <> -1
  AND NOT EXISTS (                                              -- WHY: never bought such a product
      SELECT 1 FROM warehouse.FactSales fs
      WHERE fs.CustomerSK = cu.CustomerSK
        AND fs.ProductSK IN (SELECT ProductSK FROM HighReturnProducts)
  );


-- ============================================================
-- QUERY #61: CTE — first and latest order date per customer (recency base)
-- ============================================================
-- BUSINESS PROBLEM: "When did each customer first and last buy?"
-- SOLUTION: CTE aggregating MIN/MAX order date via DimDate join.
-- SQL CONCEPTS: CTE, MIN/MAX, JOIN
-- WHY: Foundation of recency and lifecycle (new/active/lapsed).
-- WHEN: Retention analysis.
-- WHAT: First/last purchase dates and active-span per customer.
-- POWER BI IMPACT: Recency measure input; feeds RFM.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests date aggregation per entity via a CTE.
-- ============================================================
WITH CustomerDates AS (                                         -- WHAT: order dates per customer
    SELECT fs.CustomerSK,
           MIN(d.FullDate) AS FirstOrder,
           MAX(d.FullDate) AS LastOrder
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK
)
SELECT TOP (20)
    cu.FullName, cd.FirstOrder, cd.LastOrder,                   -- WHAT: lifecycle dates
    DATEDIFF(DAY, cd.FirstOrder, cd.LastOrder) AS ActiveSpanDays-- WHAT: engagement window
FROM CustomerDates cd
JOIN warehouse.DimCustomer cu ON cu.CustomerSK = cd.CustomerSK
ORDER BY ActiveSpanDays DESC;


-- ============================================================
-- QUERY #62: Subquery in SELECT — category share of grand total
-- ============================================================
-- BUSINESS PROBLEM: "What % of ALL revenue does each category represent?"
-- SOLUTION: Divide category revenue by a scalar subquery grand total.
-- SQL CONCEPTS: scalar subquery in SELECT
-- WHY: Contribution analysis for portfolio decisions.
-- WHEN: Category strategy.
-- WHAT: Category revenue and its share of the whole.
-- POWER BI IMPACT: % of total measure (DIVIDE over ALL).
-- DASHBOARD: Product, Executive
-- INTERVIEW TIP: Tests a scalar subquery used as a divisor in SELECT.
-- ============================================================
SELECT
    c.CategoryName,                                                              -- WHAT: category
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))                       AS Revenue,    -- WHAT: revenue
    CAST(SUM(fs.LineTotal) * 100.0
         / (SELECT SUM(LineTotal) FROM warehouse.FactSales) AS DECIMAL(5,2))  AS PctOfTotal -- WHAT: share
FROM warehouse.FactSales fs
JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
GROUP BY c.CategoryName
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #63: CTE — repeat vs one-time customers
-- ============================================================
-- BUSINESS PROBLEM: "What share of customers are repeat buyers?"
-- SOLUTION: CTE of order counts per customer, bucket into repeat vs one-time.
-- SQL CONCEPTS: CTE, CASE bucketing, ratio
-- WHY: Repeat rate is a core loyalty/retention KPI.
-- WHEN: Monthly customer review.
-- WHAT: Count and % of repeat vs one-time customers.
-- POWER BI IMPACT: Repeat-rate KPI card.
-- DASHBOARD: Customer, Executive
-- INTERVIEW TIP: Tests deriving a behavioral flag from an order count.
-- ============================================================
WITH Orders AS (                                                -- WHAT: distinct orders per customer
    SELECT CustomerSK, COUNT(DISTINCT OrderID) AS OrderCount
    FROM warehouse.FactSales
    WHERE CustomerSK <> -1
    GROUP BY CustomerSK
)
SELECT
    CASE WHEN OrderCount > 1 THEN 'Repeat' ELSE 'One-time' END  AS CustomerType, -- WHAT: bucket
    COUNT(*)                                                   AS Customers,       -- WHAT: count
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS Pct          -- WHAT: share
FROM Orders
GROUP BY CASE WHEN OrderCount > 1 THEN 'Repeat' ELSE 'One-time' END;


-- ============================================================
-- QUERY #64: ANY/ALL — products cheaper than ALL premium products
-- ============================================================
-- BUSINESS PROBLEM: "Which products are below the ENTIRE premium tier's price?"
-- SOLUTION: Compare UnitPrice < ALL (subquery of premium prices).
-- SQL CONCEPTS: ALL quantified comparison
-- WHY: Cleanly separates value tier from premium tier.
-- WHEN: Pricing tier design.
-- WHAT: Products below every premium-tier price.
-- POWER BI IMPACT: Tier classification logic.
-- DASHBOARD: Product, Finance
-- INTERVIEW TIP: Tests the rarely-used but powerful ALL/ANY operators.
-- ============================================================
SELECT
    ProductName, UnitPrice                                     -- WHAT: product + price
FROM warehouse.DimProduct
WHERE ProductSK <> -1
  AND UnitPrice < ALL (SELECT UnitPrice                        -- WHY: below every premium price
                       FROM warehouse.DimProduct
                       WHERE PriceRange = 'Premium ($500+)' AND ProductSK <> -1)
ORDER BY UnitPrice DESC;


-- ============================================================
-- QUERY #65: CTE — monthly orders and average revenue per order
-- ============================================================
-- BUSINESS PROBLEM: "How does monthly order volume and AOV move together?"
-- SOLUTION: CTE aggregating orders + revenue per month, derive AOV.
-- SQL CONCEPTS: CTE, COUNT DISTINCT, division
-- WHY: Distinguishes growth from volume vs basket-value.
-- WHEN: Monthly performance analysis.
-- WHAT: Orders, revenue and AOV per month.
-- POWER BI IMPACT: Dual-axis chart (orders vs AOV).
-- DASHBOARD: Sales
-- INTERVIEW TIP: Tests combining two measures at a shared grain.
-- ============================================================
WITH MonthlyStats AS (                                          -- WHAT: monthly aggregates
    SELECT d.Year, d.MonthNumber, d.MonthName,
           COUNT(DISTINCT fs.OrderID) AS Orders,
           SUM(fs.LineTotal)          AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.MonthNumber, d.MonthName
)
SELECT Year, MonthName, Orders,
       CAST(Revenue AS DECIMAL(18,2))                       AS Revenue,  -- WHAT: revenue
       CAST(Revenue / NULLIF(Orders,0) AS DECIMAL(12,2))    AS AOV       -- WHAT: avg order value
FROM MonthlyStats
ORDER BY Year, MonthNumber;


-- ============================================================
-- QUERY #66: Nested subquery — top store in each region
-- ============================================================
-- BUSINESS PROBLEM: "Which store leads each region?"
-- SOLUTION: Correlated subquery matching each store to its region's max revenue.
-- SQL CONCEPTS: correlated subquery, per-group max
-- WHY: Regional benchmarking / best-practice sharing.
-- WHEN: Regional reviews.
-- WHAT: The single top store per region.
-- POWER BI IMPACT: "Regional leader" callout (also doable with RANK).
-- DASHBOARD: Regional, Store
-- INTERVIEW TIP: Tests per-group max via correlation (pre-window approach).
-- ============================================================
WITH StoreRev AS (                                              -- WHAT: revenue per store
    SELECT s.StoreSK, s.StoreName, s.Region, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimStore s ON fs.StoreSK = s.StoreSK
    WHERE s.StoreSK <> -1
    GROUP BY s.StoreSK, s.StoreName, s.Region
)
SELECT Region, StoreName, CAST(Revenue AS DECIMAL(18,2)) AS Revenue
FROM StoreRev sr
WHERE Revenue = (SELECT MAX(Revenue) FROM StoreRev sr2 WHERE sr2.Region = sr.Region) -- WHY: region leader
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #67: CTE — inventory value by category (latest snapshot)
-- ============================================================
-- BUSINESS PROBLEM: "How much capital is tied up in stock by category?"
-- SOLUTION: CTE isolating latest snapshot, group inventory value by category.
-- SQL CONCEPTS: CTE, snapshot filter, JOIN
-- WHY: Working-capital and shrink-risk management.
-- WHEN: Inventory/finance review.
-- WHAT: On-hand inventory value per category (current).
-- POWER BI IMPACT: Inventory-value treemap (semi-additive, latest date only).
-- DASHBOARD: Inventory, Finance
-- INTERVIEW TIP: Tests correct latest-snapshot handling for semi-additive facts.
-- ============================================================
WITH Latest AS (                                                -- WHAT: newest snapshot only
    SELECT * FROM warehouse.FactInventory
    WHERE SnapshotDateKey = (SELECT MAX(SnapshotDateKey) FROM warehouse.FactInventory)
)
SELECT
    c.CategoryName,                                             -- WHAT: category
    CAST(SUM(l.InventoryValue) AS DECIMAL(18,2)) AS InventoryValue -- WHAT: capital tied up
FROM Latest l
JOIN warehouse.DimCategory c ON l.CategorySK = c.CategorySK
WHERE c.CategorySK <> -1
GROUP BY c.CategoryName
ORDER BY InventoryValue DESC;


-- ============================================================
-- QUERY #68: Subquery — orders larger than the overall average order
-- ============================================================
-- BUSINESS PROBLEM: "How many orders exceed the average order value?"
-- SOLUTION: CTE of order totals, compare each to the average of that set.
-- SQL CONCEPTS: CTE, aggregate benchmark, COUNT
-- WHY: Sizes the "big basket" opportunity segment.
-- WHEN: Merchandising / promo design.
-- WHAT: Count and share of above-average orders.
-- POWER BI IMPACT: "Big order" KPI.
-- DASHBOARD: Sales
-- INTERVIEW TIP: Tests order-grain aggregation then benchmarking.
-- ============================================================
WITH OrderTotals AS (                                           -- WHAT: revenue per order
    SELECT OrderID, SUM(LineTotal) AS OrderTotal
    FROM warehouse.FactSales
    GROUP BY OrderID
)
SELECT
    COUNT(*)                                                        AS AboveAvgOrders, -- WHAT: big orders
    (SELECT COUNT(*) FROM OrderTotals)                              AS TotalOrders,    -- WHAT: all orders
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM OrderTotals) AS DECIMAL(5,2)) AS Pct -- WHAT: share
FROM OrderTotals
WHERE OrderTotal > (SELECT AVG(OrderTotal) FROM OrderTotals);   -- WHY: above the mean


-- ============================================================
-- QUERY #69: CTE chain — category profitability ranking prep
-- ============================================================
-- BUSINESS PROBLEM: "Rank categories by margin %, not just revenue."
-- SOLUTION: CTE computes revenue/profit per category; outer derives margin.
-- SQL CONCEPTS: CTE, derived ratio
-- WHY: Margin-first ranking prevents chasing low-profit revenue.
-- WHEN: Profitability strategy.
-- WHAT: Category margin % ranked.
-- POWER BI IMPACT: Margin ranking table with data bars.
-- DASHBOARD: Finance, Product
-- INTERVIEW TIP: Tests separating aggregation (CTE) from ratio logic (outer).
-- ============================================================
WITH CatPnl AS (                                                -- WHAT: revenue/profit per category
    SELECT c.CategoryName,
           SUM(fs.LineTotal)   AS Revenue,
           SUM(fs.GrossProfit) AS Profit
    FROM warehouse.FactSales fs
    JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
    GROUP BY c.CategoryName
)
SELECT
    CategoryName,
    CAST(Revenue AS DECIMAL(18,2))                               AS Revenue,   -- WHAT: revenue
    CAST(Profit  AS DECIMAL(18,2))                               AS Profit,    -- WHAT: profit
    CAST(Profit * 100.0 / NULLIF(Revenue,0) AS DECIMAL(5,2))     AS MarginPct  -- WHAT: margin %
FROM CatPnl
ORDER BY MarginPct DESC;


-- ============================================================
-- QUERY #70: Correlated EXISTS — active products (sold in latest year)
-- ============================================================
-- BUSINESS PROBLEM: "Which products actually sold in the most recent year?"
-- SOLUTION: EXISTS check tying product to a sale in MAX(Year).
-- SQL CONCEPTS: correlated EXISTS with a date filter
-- WHY: Distinguishes live assortment from dormant SKUs.
-- WHEN: Assortment refresh.
-- WHAT: Count of products with a sale in the latest year.
-- POWER BI IMPACT: "Active SKU" count measure.
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests EXISTS combined with a subquery-derived latest year.
-- ============================================================
SELECT COUNT(*) AS ActiveProductsLatestYear                    -- WHAT: live SKUs
FROM warehouse.DimProduct p
WHERE p.ProductSK <> -1
  AND EXISTS (                                                 -- WHY: sold in most recent year?
      SELECT 1
      FROM warehouse.FactSales fs
      JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
      WHERE fs.ProductSK = p.ProductSK
        AND d.Year = (SELECT MAX(Year) FROM warehouse.DimDate d2
                      JOIN warehouse.FactSales f2 ON f2.OrderDateKey = d2.DateKey)
  );


-- #############################################################################
-- SECTION 5 — WINDOW FUNCTIONS  (Q71–Q90)
-- Goal: ranking, period-over-period, running totals, percentiles.
-- #############################################################################

-- ============================================================
-- QUERY #71: ROW_NUMBER — de-duplicate to one row per order
-- ============================================================
-- BUSINESS PROBLEM: "Pick a single representative line per order."
-- SOLUTION: ROW_NUMBER partitioned by OrderID, keep rn=1.
-- SQL CONCEPTS: ROW_NUMBER, PARTITION BY
-- WHY: Standard de-dupe / pick-one pattern for reporting.
-- WHEN: Building order-grain extracts.
-- WHAT: One highest-value line per order.
-- POWER BI IMPACT: Mirrors de-dupe done in Power Query.
-- DASHBOARD: Sales
-- INTERVIEW TIP: Tests ROW_NUMBER for "top row per group".
-- ============================================================
WITH Ranked AS (
    SELECT OrderID, OrderDetailID, LineTotal,
           ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY LineTotal DESC) AS rn -- WHAT: rank lines in order
    FROM warehouse.FactSales
)
SELECT TOP (20) OrderID, OrderDetailID, LineTotal
FROM Ranked
WHERE rn = 1                                                    -- WHY: keep the top line only
ORDER BY LineTotal DESC;


-- ============================================================
-- QUERY #72: RANK vs DENSE_RANK — product revenue ranking
-- ============================================================
-- BUSINESS PROBLEM: "Rank products by revenue, handling ties correctly."
-- SOLUTION: Show RANK and DENSE_RANK side by side.
-- SQL CONCEPTS: RANK, DENSE_RANK
-- WHY: Tie handling changes 'Top N' membership; must be intentional.
-- WHEN: Any ranked leaderboard.
-- WHAT: Products with both ranking styles for comparison.
-- POWER BI IMPACT: RANKX behavior mirrors these; choose ties/dense.
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests knowing the gap difference between RANK and DENSE_RANK.
-- ============================================================
WITH ProdRev AS (
    SELECT p.ProductName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimProduct p ON fs.ProductSK = p.ProductSK
    GROUP BY p.ProductName
)
SELECT TOP (20)
    ProductName,
    CAST(Revenue AS DECIMAL(18,2))                              AS Revenue,
    RANK()       OVER (ORDER BY Revenue DESC)                   AS RankWithGaps,   -- WHAT: 1,2,2,4...
    DENSE_RANK() OVER (ORDER BY Revenue DESC)                   AS DenseRank       -- WHAT: 1,2,2,3...
FROM ProdRev
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #73: Top 3 products PER category (partitioned ranking)
-- ============================================================
-- BUSINESS PROBLEM: "Show the 3 best products in EACH category."
-- SOLUTION: ROW_NUMBER partitioned by category, filter <=3.
-- SQL CONCEPTS: ROW_NUMBER with PARTITION BY, outer filter
-- WHY: Category-level merchandising highlights.
-- WHEN: Category planning.
-- WHAT: Top-3 SKUs within every category.
-- POWER BI IMPACT: TOPN per category (RANKX in a category filter context).
-- DASHBOARD: Product
-- INTERVIEW TIP: The signature "top N per group" window question.
-- ============================================================
WITH RankedInCat AS (
    SELECT c.CategoryName, p.ProductName,
           SUM(fs.LineTotal) AS Revenue,
           ROW_NUMBER() OVER (PARTITION BY c.CategoryName ORDER BY SUM(fs.LineTotal) DESC) AS rnk -- WHAT: rank per category
    FROM warehouse.FactSales fs
    JOIN warehouse.DimProduct  p ON fs.ProductSK  = p.ProductSK
    JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
    GROUP BY c.CategoryName, p.ProductName
)
SELECT CategoryName, ProductName, CAST(Revenue AS DECIMAL(18,2)) AS Revenue, rnk
FROM RankedInCat
WHERE rnk <= 3                                                  -- WHY: top 3 per category
ORDER BY CategoryName, rnk;


-- ============================================================
-- QUERY #74: LAG — month-over-month revenue growth
-- ============================================================
-- BUSINESS PROBLEM: "How did each month compare to the prior month?"
-- SOLUTION: LAG the monthly revenue to compute delta and growth %.
-- SQL CONCEPTS: LAG, period-over-period
-- WHY: MoM momentum is a core operating metric.
-- WHEN: Monthly performance review.
-- WHAT: Revenue, prior-month, delta and growth %.
-- POWER BI IMPACT: MoM% via DATEADD/PREVIOUSMONTH measures.
-- DASHBOARD: Sales, Executive
-- INTERVIEW TIP: The classic LAG interview question.
-- ============================================================
WITH Monthly AS (
    SELECT d.Year, d.MonthNumber, d.MonthName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.MonthNumber, d.MonthName
)
SELECT
    Year, MonthName,
    CAST(Revenue AS DECIMAL(18,2))                                              AS Revenue,
    CAST(LAG(Revenue) OVER (ORDER BY Year, MonthNumber) AS DECIMAL(18,2))       AS PrevMonth, -- WHAT: prior month
    CAST((Revenue - LAG(Revenue) OVER (ORDER BY Year, MonthNumber)) * 100.0
         / NULLIF(LAG(Revenue) OVER (ORDER BY Year, MonthNumber),0) AS DECIMAL(6,2)) AS MoM_GrowthPct -- WHAT: growth %
FROM Monthly
ORDER BY Year, MonthNumber;


-- ============================================================
-- QUERY #75: LEAD — days until each customer's next order
-- ============================================================
-- BUSINESS PROBLEM: "What is the gap between a customer's consecutive orders?"
-- SOLUTION: LEAD the order date within each customer, diff the dates.
-- SQL CONCEPTS: LEAD, PARTITION BY, DATEDIFF
-- WHY: Purchase cadence drives churn prediction and reorder timing.
-- WHEN: Retention/churn modeling.
-- WHAT: Days to next order per customer order.
-- POWER BI IMPACT: Inter-purchase interval measure.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests LEAD for forward-looking gaps.
-- ============================================================
WITH CustOrders AS (
    SELECT fs.CustomerSK, fs.OrderID, MIN(d.FullDate) AS OrderDate
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK, fs.OrderID
)
SELECT TOP (30)
    CustomerSK, OrderID, OrderDate,
    LEAD(OrderDate) OVER (PARTITION BY CustomerSK ORDER BY OrderDate)            AS NextOrderDate, -- WHAT: next order
    DATEDIFF(DAY, OrderDate,
             LEAD(OrderDate) OVER (PARTITION BY CustomerSK ORDER BY OrderDate))  AS DaysToNext     -- WHAT: gap
FROM CustOrders
ORDER BY CustomerSK, OrderDate;


-- ============================================================
-- QUERY #76: SUM OVER — running total of daily revenue
-- ============================================================
-- BUSINESS PROBLEM: "Show cumulative revenue across the timeline."
-- SOLUTION: SUM() OVER (ORDER BY date) as a running total.
-- SQL CONCEPTS: windowed running SUM
-- WHY: Pacing toward targets; cumulative curves.
-- WHEN: Finance pacing dashboards.
-- WHAT: Daily revenue plus cumulative-to-date.
-- POWER BI IMPACT: TOTALYTD / running-total measures.
-- DASHBOARD: Finance
-- INTERVIEW TIP: Tests default window frame semantics of running SUM.
-- ============================================================
WITH Daily AS (
    SELECT d.FullDate, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY d.FullDate
)
SELECT TOP (60)
    FullDate,
    CAST(Revenue AS DECIMAL(18,2))                                     AS DailyRevenue,
    CAST(SUM(Revenue) OVER (ORDER BY FullDate
          ROWS UNBOUNDED PRECEDING) AS DECIMAL(18,2))                  AS RunningTotal -- WHAT: cumulative
FROM Daily
ORDER BY FullDate;


-- ============================================================
-- QUERY #77: NTILE — customer spend quartiles
-- ============================================================
-- BUSINESS PROBLEM: "Split customers into 4 value tiers."
-- SOLUTION: NTILE(4) over total spend per customer.
-- SQL CONCEPTS: NTILE, PARTITIONless window
-- WHY: Quartile tiers drive differentiated service/offers.
-- WHEN: CRM tiering.
-- WHAT: Each customer's spend quartile (1=top).
-- POWER BI IMPACT: Value-tier column for slicing.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests NTILE for equal-sized bucketing.
-- ============================================================
WITH CustSpend AS (
    SELECT CustomerSK, SUM(LineTotal) AS Spend
    FROM warehouse.FactSales WHERE CustomerSK <> -1
    GROUP BY CustomerSK
)
SELECT TOP (40)
    cu.FullName,
    CAST(cs.Spend AS DECIMAL(18,2))                              AS Spend,
    NTILE(4) OVER (ORDER BY cs.Spend DESC)                       AS SpendQuartile -- WHAT: 1=top 25%
FROM CustSpend cs
JOIN warehouse.DimCustomer cu ON cu.CustomerSK = cs.CustomerSK
ORDER BY cs.Spend DESC;


-- ============================================================
-- QUERY #78: FIRST_VALUE / LAST_VALUE — best & worst month in each year
-- ============================================================
-- BUSINESS PROBLEM: "For each year, which month was best and worst?"
-- SOLUTION: FIRST_VALUE/LAST_VALUE over monthly revenue partitioned by year.
-- SQL CONCEPTS: FIRST_VALUE, LAST_VALUE, frame specification
-- WHY: Seasonality peaks/troughs for planning.
-- WHEN: Annual planning.
-- WHAT: Peak and trough month labels per year.
-- POWER BI IMPACT: FIRSTNONBLANK/max-month callouts.
-- DASHBOARD: Sales, Finance
-- INTERVIEW TIP: Tests LAST_VALUE frame pitfall (needs full-partition frame).
-- ============================================================
WITH Monthly AS (
    SELECT d.Year, d.MonthName, d.MonthNumber, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.MonthName, d.MonthNumber
)
SELECT DISTINCT
    Year,
    FIRST_VALUE(MonthName) OVER (PARTITION BY Year ORDER BY Revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS BestMonth,  -- WHAT: peak
    LAST_VALUE(MonthName)  OVER (PARTITION BY Year ORDER BY Revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS WorstMonth  -- WHAT: trough
FROM Monthly
ORDER BY Year;


-- ============================================================
-- QUERY #79: PERCENT_RANK — product revenue percentile
-- ============================================================
-- BUSINESS PROBLEM: "Where does each product rank as a percentile of revenue?"
-- SOLUTION: PERCENT_RANK() over product revenue.
-- SQL CONCEPTS: PERCENT_RANK
-- WHY: Percentile framing is clearer than raw rank across a big catalog.
-- WHEN: Assortment tiering.
-- WHAT: Each product's revenue percentile (0–1).
-- POWER BI IMPACT: Percentile bands for A/B/C tiering.
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests distribution-based window ranking.
-- ============================================================
WITH ProdRev AS (
    SELECT p.ProductName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimProduct p ON fs.ProductSK = p.ProductSK
    GROUP BY p.ProductName
)
SELECT TOP (30)
    ProductName,
    CAST(Revenue AS DECIMAL(18,2))                              AS Revenue,
    CAST(PERCENT_RANK() OVER (ORDER BY Revenue) AS DECIMAL(5,4)) AS RevenuePercentile -- WHAT: 0..1
FROM ProdRev
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #80: Moving average — 3-month rolling revenue
-- ============================================================
-- BUSINESS PROBLEM: "Smooth out monthly noise to see the trend."
-- SOLUTION: AVG() OVER a 3-row moving window on monthly revenue.
-- SQL CONCEPTS: windowed AVG with ROWS frame
-- WHY: Rolling averages reveal trend under seasonal noise.
-- WHEN: Trend monitoring.
-- WHAT: Monthly revenue + 3-month moving average.
-- POWER BI IMPACT: Rolling-average measure with DATESINPERIOD.
-- DASHBOARD: Sales, Finance
-- INTERVIEW TIP: Tests explicit ROWS-frame moving windows.
-- ============================================================
WITH Monthly AS (
    SELECT d.Year, d.MonthNumber, d.MonthName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.MonthNumber, d.MonthName
)
SELECT
    Year, MonthName,
    CAST(Revenue AS DECIMAL(18,2))                                     AS Revenue,
    CAST(AVG(Revenue) OVER (ORDER BY Year, MonthNumber
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS DECIMAL(18,2))  AS MA3Month -- WHAT: 3-mo avg
FROM Monthly
ORDER BY Year, MonthNumber;


-- ============================================================
-- QUERY #81: Store rank within region (partitioned ranking)
-- ============================================================
-- BUSINESS PROBLEM: "Rank each store within its own region."
-- SOLUTION: RANK() PARTITION BY region ORDER BY revenue.
-- SQL CONCEPTS: partitioned RANK
-- WHY: Fair intra-region benchmarking.
-- WHEN: Regional store reviews.
-- WHAT: Store rank inside each region.
-- POWER BI IMPACT: RANKX within region filter context.
-- DASHBOARD: Store, Regional
-- INTERVIEW TIP: Tests PARTITION BY changing the ranking scope.
-- ============================================================
WITH StoreRev AS (
    SELECT s.Region, s.StoreName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimStore s ON fs.StoreSK = s.StoreSK
    WHERE s.StoreSK <> -1
    GROUP BY s.Region, s.StoreName
)
SELECT
    Region, StoreName,
    CAST(Revenue AS DECIMAL(18,2))                              AS Revenue,
    RANK() OVER (PARTITION BY Region ORDER BY Revenue DESC)     AS RankInRegion -- WHAT: intra-region rank
FROM StoreRev
ORDER BY Region, RankInRegion;


-- ============================================================
-- QUERY #82: Contribution % via window SUM — category within department
-- ============================================================
-- BUSINESS PROBLEM: "What % of a department's revenue is each category?"
-- SOLUTION: category revenue / SUM OVER (PARTITION BY department).
-- SQL CONCEPTS: windowed share within partition
-- WHY: Intra-department mix analysis.
-- WHEN: Category planning.
-- WHAT: Category share of its department.
-- POWER BI IMPACT: % of parent (department) measure.
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests partitioned "% of subtotal" without a self-join.
-- ============================================================
WITH CatRev AS (
    SELECT c.Department, c.CategoryName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
    GROUP BY c.Department, c.CategoryName
)
SELECT
    Department, CategoryName,
    CAST(Revenue AS DECIMAL(18,2))                                              AS Revenue,
    CAST(Revenue * 100.0
         / SUM(Revenue) OVER (PARTITION BY Department) AS DECIMAL(5,2))         AS PctOfDept -- WHAT: share of dept
FROM CatRev
ORDER BY Department, PctOfDept DESC;


-- ============================================================
-- QUERY #83: LAG over years — YoY growth per category
-- ============================================================
-- BUSINESS PROBLEM: "How is each category growing year over year?"
-- SOLUTION: LAG revenue over years, partitioned by category.
-- SQL CONCEPTS: LAG with PARTITION BY
-- WHY: Category-level growth/decline detection.
-- WHEN: Annual category strategy.
-- WHAT: Category revenue vs prior year and YoY %.
-- POWER BI IMPACT: SAMEPERIODLASTYEAR measure per category.
-- DASHBOARD: Product, Finance
-- INTERVIEW TIP: Tests partitioned LAG for entity-level trends.
-- ============================================================
WITH CatYear AS (
    SELECT c.CategoryName, d.Year, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY c.CategoryName, d.Year
)
SELECT
    CategoryName, Year,
    CAST(Revenue AS DECIMAL(18,2))                                              AS Revenue,
    CAST(LAG(Revenue) OVER (PARTITION BY CategoryName ORDER BY Year) AS DECIMAL(18,2)) AS PrevYear,
    CAST((Revenue - LAG(Revenue) OVER (PARTITION BY CategoryName ORDER BY Year)) * 100.0
         / NULLIF(LAG(Revenue) OVER (PARTITION BY CategoryName ORDER BY Year),0) AS DECIMAL(6,2)) AS YoYPct
FROM CatYear
ORDER BY CategoryName, Year;


-- ============================================================
-- QUERY #84: CUME_DIST — cumulative distribution of order values
-- ============================================================
-- BUSINESS PROBLEM: "What fraction of orders fall at or below a given value?"
-- SOLUTION: CUME_DIST() over per-order totals.
-- SQL CONCEPTS: CUME_DIST
-- WHY: Understand the order-value distribution for thresholds (e.g., free shipping).
-- WHEN: Policy design (thresholds, tiers).
-- WHAT: Cumulative share for sampled order values.
-- POWER BI IMPACT: Distribution/threshold analysis visuals.
-- DASHBOARD: Sales, Finance
-- INTERVIEW TIP: Tests CUME_DIST vs PERCENT_RANK understanding.
-- ============================================================
WITH OrderTotals AS (
    SELECT OrderID, SUM(LineTotal) AS OrderTotal
    FROM warehouse.FactSales GROUP BY OrderID
)
SELECT TOP (30)
    OrderID,
    CAST(OrderTotal AS DECIMAL(18,2))                          AS OrderTotal,
    CAST(CUME_DIST() OVER (ORDER BY OrderTotal) AS DECIMAL(6,4)) AS CumulativeShare -- WHAT: <= share
FROM OrderTotals
ORDER BY OrderTotal;


-- ============================================================
-- QUERY #85: ROW_NUMBER — each customer's first-ever order
-- ============================================================
-- BUSINESS PROBLEM: "Identify every customer's first purchase (acquisition)."
-- SOLUTION: ROW_NUMBER by date ascending per customer, keep rn=1.
-- SQL CONCEPTS: ROW_NUMBER earliest-per-group
-- WHY: First-order date anchors cohort and acquisition analysis.
-- WHEN: Cohort building.
-- WHAT: First order id/date per customer.
-- POWER BI IMPACT: Cohort-assignment column.
-- DASHBOARD: Customer
-- INTERVIEW TIP: Tests earliest-per-group via ascending ROW_NUMBER.
-- ============================================================
WITH FirstOrder AS (
    SELECT fs.CustomerSK, fs.OrderID, MIN(d.FullDate) AS OrderDate,
           ROW_NUMBER() OVER (PARTITION BY fs.CustomerSK ORDER BY MIN(d.FullDate)) AS rn -- WHAT: order sequence
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK, fs.OrderID
)
SELECT TOP (20) CustomerSK, OrderID, OrderDate
FROM FirstOrder WHERE rn = 1                                    -- WHY: first order only
ORDER BY OrderDate;


-- ============================================================
-- QUERY #86: Windowed AVG benchmark — store vs region average
-- ============================================================
-- BUSINESS PROBLEM: "Is each store above or below its region's average?"
-- SOLUTION: Compare store revenue to AVG() OVER (PARTITION BY region).
-- SQL CONCEPTS: window AVG as inline benchmark
-- WHY: Contextual performance (beats peers?) not just absolute value.
-- WHEN: Store reviews.
-- WHAT: Store revenue, region average, variance.
-- POWER BI IMPACT: "vs region avg" KPI with conditional formatting.
-- DASHBOARD: Store, Regional
-- INTERVIEW TIP: Tests using a window aggregate as a per-row benchmark.
-- ============================================================
WITH StoreRev AS (
    SELECT s.Region, s.StoreName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimStore s ON fs.StoreSK = s.StoreSK
    WHERE s.StoreSK <> -1
    GROUP BY s.Region, s.StoreName
)
SELECT
    Region, StoreName,
    CAST(Revenue AS DECIMAL(18,2))                                              AS Revenue,
    CAST(AVG(Revenue) OVER (PARTITION BY Region) AS DECIMAL(18,2))              AS RegionAvg,   -- WHAT: peer avg
    CAST(Revenue - AVG(Revenue) OVER (PARTITION BY Region) AS DECIMAL(18,2))    AS VsRegionAvg  -- WHAT: variance
FROM StoreRev
ORDER BY Region, VsRegionAvg DESC;


-- ============================================================
-- QUERY #87: LAG — return-rate trend by month
-- ============================================================
-- BUSINESS PROBLEM: "Is our return rate improving or worsening monthly?"
-- SOLUTION: Monthly return-rate CTE, LAG to compare to prior month.
-- SQL CONCEPTS: cross-fact monthly ratio + LAG
-- WHY: Early warning on quality/logistics regressions.
-- WHEN: Monthly quality review.
-- WHAT: Monthly return rate and MoM change.
-- POWER BI IMPACT: Return-rate trend with prior-month delta.
-- DASHBOARD: Sales (Returns)
-- INTERVIEW TIP: Tests combining two facts then applying LAG.
-- ============================================================
WITH MonthlyReturns AS (
    SELECT d.Year, d.MonthNumber,
           (SELECT SUM(f2.Quantity) FROM warehouse.FactSales f2
             JOIN warehouse.DimDate d2 ON f2.OrderDateKey = d2.DateKey
             WHERE d2.Year = d.Year AND d2.MonthNumber = d.MonthNumber) AS SoldUnits,
           SUM(r.OriginalQuantity) AS ReturnedUnits
    FROM warehouse.FactReturns r
    JOIN warehouse.DimDate d ON r.ReturnDateKey = d.DateKey
    GROUP BY d.Year, d.MonthNumber
)
SELECT
    Year, MonthNumber,
    CAST(ReturnedUnits * 100.0 / NULLIF(SoldUnits,0) AS DECIMAL(5,2))           AS ReturnRatePct, -- WHAT: rate
    CAST(LAG(ReturnedUnits * 100.0 / NULLIF(SoldUnits,0))
         OVER (ORDER BY Year, MonthNumber) AS DECIMAL(5,2))                     AS PrevRatePct    -- WHAT: prior
FROM MonthlyReturns
ORDER BY Year, MonthNumber;


-- ============================================================
-- QUERY #88: Deciles — product revenue split into 10 groups
-- ============================================================
-- BUSINESS PROBLEM: "Group products into 10 revenue deciles."
-- SOLUTION: NTILE(10) over product revenue.
-- SQL CONCEPTS: NTILE(10)
-- WHY: Finer-grained tiering than quartiles for large catalogs.
-- WHEN: Assortment/long-tail analysis.
-- WHAT: Each product's revenue decile.
-- POWER BI IMPACT: Decile slicer for tail analysis.
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests NTILE parameterization for arbitrary buckets.
-- ============================================================
WITH ProdRev AS (
    SELECT p.ProductName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimProduct p ON fs.ProductSK = p.ProductSK
    GROUP BY p.ProductName
)
SELECT TOP (40)
    ProductName,
    CAST(Revenue AS DECIMAL(18,2))                              AS Revenue,
    NTILE(10) OVER (ORDER BY Revenue DESC)                      AS RevenueDecile -- WHAT: 1=top decile
FROM ProdRev
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #89: Running count — cumulative new customers over time
-- ============================================================
-- BUSINESS PROBLEM: "Show cumulative customer base growth by join month."
-- SOLUTION: Monthly new customers + running COUNT via window.
-- SQL CONCEPTS: COUNT aggregate + running SUM window
-- WHY: Visualizes base growth (the "up and to the right" curve).
-- WHEN: Growth reporting.
-- WHAT: New and cumulative customers per month.
-- POWER BI IMPACT: Cumulative-customers area chart.
-- DASHBOARD: Customer, Executive
-- INTERVIEW TIP: Tests running total over a COUNT metric.
-- ============================================================
WITH NewByMonth AS (
    SELECT YEAR(JoinDate) AS y, MONTH(JoinDate) AS m, COUNT(*) AS NewCustomers
    FROM warehouse.DimCustomer WHERE CustomerSK <> -1
    GROUP BY YEAR(JoinDate), MONTH(JoinDate)
)
SELECT
    y AS JoinYear, m AS JoinMonth, NewCustomers,
    SUM(NewCustomers) OVER (ORDER BY y, m ROWS UNBOUNDED PRECEDING) AS CumulativeCustomers -- WHAT: base size
FROM NewByMonth
ORDER BY y, m;


-- ============================================================
-- QUERY #90: Gaps & islands — consecutive active-sales days
-- ============================================================
-- BUSINESS PROBLEM: "Find streaks of consecutive days with sales."
-- SOLUTION: ROW_NUMBER trick (date - rownumber = constant per streak).
-- SQL CONCEPTS: gaps-and-islands, ROW_NUMBER, DATEADD
-- WHY: Operational continuity / anomaly detection (missing days).
-- WHEN: Ops monitoring; data-completeness checks.
-- WHAT: Contiguous selling streaks with start/end and length.
-- POWER BI IMPACT: Hard in DAX — showcases SQL strength for the pipeline layer.
-- DASHBOARD: Data Quality / Ops
-- INTERVIEW TIP: A senior-level pattern that impresses interviewers.
-- ============================================================
WITH SalesDays AS (
    SELECT DISTINCT d.FullDate
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
),
Grouped AS (
    SELECT FullDate,
           DATEADD(DAY,
                   -ROW_NUMBER() OVER (ORDER BY FullDate),      -- WHAT: island key
                   FullDate) AS GrpKey
    FROM SalesDays
)
SELECT TOP (20)
    MIN(FullDate)                    AS StreakStart,             -- WHAT: streak start
    MAX(FullDate)                    AS StreakEnd,               -- WHAT: streak end
    COUNT(*)                         AS ConsecutiveDays          -- WHAT: streak length
FROM Grouped
GROUP BY GrpKey
ORDER BY ConsecutiveDays DESC;


-- #############################################################################
-- SECTION 6 — ADVANCED ANALYTICS  (Q91–Q100)
-- Goal: the analyses that separate senior analysts (PIVOT, cohort, RFM, Pareto).
-- #############################################################################

-- ============================================================
-- QUERY #91: PIVOT — revenue by category (rows) × year (columns)
-- ============================================================
-- BUSINESS PROBLEM: "Cross-tab revenue: category down, years across."
-- SOLUTION: PIVOT the year dimension into columns.
-- SQL CONCEPTS: PIVOT
-- WHY: Executive-friendly cross-tab in one grid.
-- WHEN: Board decks / finance packs.
-- WHAT: Category × year revenue matrix.
-- POWER BI IMPACT: A matrix visual does this natively; shows SQL parity.
-- DASHBOARD: Finance, Executive
-- INTERVIEW TIP: Tests the PIVOT syntax and fixed-column limitation.
-- ============================================================
SELECT CategoryName, [2023], [2024], [2025], [2026]            -- WHAT: year columns
FROM (
    SELECT c.CategoryName, d.Year, fs.LineTotal
    FROM warehouse.FactSales fs
    JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
) src
PIVOT (SUM(LineTotal) FOR Year IN ([2023],[2024],[2025],[2026])) pvt -- WHY: years become columns
ORDER BY CategoryName;


-- ============================================================
-- QUERY #92: Year-over-Year comparison (current vs prior by month)
-- ============================================================
-- BUSINESS PROBLEM: "Compare each month to the same month last year."
-- SOLUTION: Self-join monthly aggregates on (month, year-1).
-- SQL CONCEPTS: self-join on shifted year, YoY %
-- WHY: Seasonally fair growth measurement.
-- WHEN: Monthly exec reporting.
-- WHAT: This-year vs last-year revenue per month and YoY %.
-- POWER BI IMPACT: SAMEPERIODLASTYEAR measure equivalent.
-- DASHBOARD: Executive, Finance
-- INTERVIEW TIP: Tests YoY via join (vs the LAG approach in Q83).
-- ============================================================
WITH MonthYear AS (
    SELECT d.Year, d.MonthNumber, d.MonthName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.MonthNumber, d.MonthName
)
SELECT
    cur.Year, cur.MonthName,
    CAST(cur.Revenue AS DECIMAL(18,2))                                          AS ThisYear,
    CAST(pri.Revenue AS DECIMAL(18,2))                                          AS LastYear,
    CAST((cur.Revenue - pri.Revenue) * 100.0
         / NULLIF(pri.Revenue,0) AS DECIMAL(6,2))                               AS YoYPct
FROM MonthYear cur
LEFT JOIN MonthYear pri
       ON pri.MonthNumber = cur.MonthNumber
      AND pri.Year = cur.Year - 1                              -- WHY: same month, prior year
ORDER BY cur.Year, cur.MonthNumber;


-- ============================================================
-- QUERY #93: Cohort analysis — retention by acquisition month
-- ============================================================
-- BUSINESS PROBLEM: "Do customers acquired together keep buying?"
-- SOLUTION: Assign each customer a cohort (first-order month), count active by months-since.
-- SQL CONCEPTS: cohort assignment, DATEDIFF month offset
-- WHY: Retention curves are the gold standard of customer health.
-- WHEN: Retention deep-dives.
-- WHAT: Active customers per cohort per month-offset.
-- POWER BI IMPACT: Cohort heatmap (matrix with cohort rows / offset columns).
-- DASHBOARD: Customer
-- INTERVIEW TIP: Cohort analysis is a senior-analyst signature question.
-- ============================================================
WITH FirstPurchase AS (                                         -- WHAT: cohort = first-order month
    SELECT fs.CustomerSK,
           MIN(d.FullDate) AS FirstDate
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK
),
Activity AS (                                                   -- WHAT: months since acquisition per order
    SELECT fp.CustomerSK,
           CONVERT(CHAR(7), fp.FirstDate, 126) AS CohortMonth,
           DATEDIFF(MONTH, fp.FirstDate, d.FullDate) AS MonthOffset
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    JOIN FirstPurchase fp ON fp.CustomerSK = fs.CustomerSK
    WHERE fs.CustomerSK <> -1
)
SELECT TOP (40)
    CohortMonth, MonthOffset,
    COUNT(DISTINCT CustomerSK) AS ActiveCustomers               -- WHAT: retained customers
FROM Activity
GROUP BY CohortMonth, MonthOffset
ORDER BY CohortMonth, MonthOffset;


-- ============================================================
-- QUERY #94: RFM segmentation — Recency, Frequency, Monetary scoring
-- ============================================================
-- BUSINESS PROBLEM: "Score every customer on RFM and segment them."
-- SOLUTION: Compute R/F/M, NTILE(5) each, combine into a segment label.
-- SQL CONCEPTS: multiple NTILE, CTE layering, scoring
-- WHY: RFM is the workhorse of retail CRM targeting.
-- WHEN: Campaign design / lifecycle marketing.
-- WHAT: Each customer's R/F/M scores and a Champions/At-Risk label.
-- POWER BI IMPACT: Feeds vw_CustomerRFM and a segment slicer.
-- DASHBOARD: Customer
-- INTERVIEW TIP: RFM demonstrates end-to-end analytical thinking.
-- ============================================================
WITH RFM AS (                                                   -- WHAT: raw R/F/M per customer
    SELECT
        fs.CustomerSK,
        DATEDIFF(DAY, MAX(d.FullDate),
                 (SELECT MAX(FullDate) FROM warehouse.DimDate d2
                  JOIN warehouse.FactSales f2 ON f2.OrderDateKey = d2.DateKey)) AS Recency, -- days since last buy
        COUNT(DISTINCT fs.OrderID)  AS Frequency,               -- WHAT: order count
        SUM(fs.LineTotal)           AS Monetary                 -- WHAT: total spend
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK
),
Scored AS (                                                     -- WHAT: quintile scores (5=best)
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency ASC)      AS R,         -- lower recency = better
        NTILE(5) OVER (ORDER BY Frequency DESC)   AS F,
        NTILE(5) OVER (ORDER BY Monetary DESC)    AS M
    FROM RFM
)
SELECT TOP (40)
    cu.FullName, s.Recency, s.Frequency,
    CAST(s.Monetary AS DECIMAL(18,2))                          AS Monetary,
    s.R, s.F, s.M,
    CASE                                                        -- WHAT: segment label
        WHEN s.R >= 4 AND s.F >= 4 AND s.M >= 4 THEN 'Champions'
        WHEN s.R >= 4 AND s.F >= 3               THEN 'Loyal'
        WHEN s.R >= 4                            THEN 'Recent'
        WHEN s.R <= 2 AND s.F >= 3               THEN 'At Risk'
        WHEN s.R <= 2                            THEN 'Lapsed'
        ELSE 'Developing'
    END AS RFM_Segment
FROM Scored s
JOIN warehouse.DimCustomer cu ON cu.CustomerSK = s.CustomerSK
ORDER BY s.Monetary DESC;


-- ============================================================
-- QUERY #95: ABC / Pareto analysis — the 80/20 of products
-- ============================================================
-- BUSINESS PROBLEM: "Which products make up 80% of revenue (Class A)?"
-- SOLUTION: Cumulative revenue % via running SUM, classify A/B/C.
-- SQL CONCEPTS: running SUM, cumulative %, CASE classification
-- WHY: Focus inventory/attention on the vital few (A) items.
-- WHEN: Inventory strategy / assortment.
-- WHAT: Each product's cumulative revenue share and ABC class.
-- POWER BI IMPACT: Feeds vw_ProductABC and a Pareto chart.
-- DASHBOARD: Product, Inventory
-- INTERVIEW TIP: Pareto/ABC is a classic senior inventory-analytics question.
-- ============================================================
WITH ProdRev AS (
    SELECT p.ProductSK, p.ProductName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimProduct p ON fs.ProductSK = p.ProductSK
    GROUP BY p.ProductSK, p.ProductName
),
Cumulative AS (
    SELECT ProductName, Revenue,
           SUM(Revenue) OVER (ORDER BY Revenue DESC ROWS UNBOUNDED PRECEDING) AS RunningRev, -- WHAT: cumulative $
           SUM(Revenue) OVER ()                                              AS TotalRev      -- WHAT: grand total
    FROM ProdRev
)
SELECT TOP (40)
    ProductName,
    CAST(Revenue AS DECIMAL(18,2))                                          AS Revenue,
    CAST(RunningRev * 100.0 / TotalRev AS DECIMAL(5,2))                     AS CumulativePct, -- WHAT: 0..100
    CASE                                                                    -- WHAT: ABC class
        WHEN RunningRev * 100.0 / TotalRev <= 80 THEN 'A (top 80%)'
        WHEN RunningRev * 100.0 / TotalRev <= 95 THEN 'B (next 15%)'
        ELSE 'C (last 5%)'
    END AS ABC_Class
FROM Cumulative
ORDER BY Revenue DESC;


-- ============================================================
-- QUERY #96: Basket affinity — products frequently bought together
-- ============================================================
-- BUSINESS PROBLEM: "Which product pairs co-occur in the same order?"
-- SOLUTION: Self-join order lines on OrderID with ProductSK_a < ProductSK_b.
-- SQL CONCEPTS: self-join on degenerate key, pair de-dup
-- WHY: Cross-sell, bundling and placement decisions.
-- WHEN: Merchandising / recommendation seeding.
-- WHAT: Top co-purchased product pairs by basket count.
-- POWER BI IMPACT: Market-basket visual (hard in DAX — SQL wins).
-- DASHBOARD: Product
-- INTERVIEW TIP: Tests self-join to build pairs without duplicates.
-- ============================================================
SELECT TOP (20)
    p1.ProductName AS ProductA,                                 -- WHAT: first product
    p2.ProductName AS ProductB,                                 -- WHAT: second product
    COUNT(*)       AS TimesBoughtTogether                       -- WHAT: co-occurrence count
FROM warehouse.FactSales a
JOIN warehouse.FactSales b
     ON a.OrderID = b.OrderID                                   -- WHY: same basket
    AND a.ProductSK < b.ProductSK                               -- WHY: unordered unique pairs
JOIN warehouse.DimProduct p1 ON a.ProductSK = p1.ProductSK
JOIN warehouse.DimProduct p2 ON b.ProductSK = p2.ProductSK
GROUP BY p1.ProductName, p2.ProductName
ORDER BY TimesBoughtTogether DESC;


-- ============================================================
-- QUERY #97: Customer lifetime value (CLV) ranking with tiers
-- ============================================================
-- BUSINESS PROBLEM: "Rank customers by lifetime value and tier them."
-- SOLUTION: Sum lifetime spend, RANK and NTILE for tiers.
-- SQL CONCEPTS: aggregate + RANK + NTILE combined
-- WHY: CLV prioritizes retention spend on the right customers.
-- WHEN: CRM budgeting.
-- WHAT: Lifetime spend, global rank, and value tier per customer.
-- POWER BI IMPACT: CLV card + tier slicer.
-- DASHBOARD: Customer, Executive
-- INTERVIEW TIP: Tests combining several window functions meaningfully.
-- ============================================================
WITH CLV AS (
    SELECT fs.CustomerSK,
           SUM(fs.LineTotal)          AS LifetimeValue,
           COUNT(DISTINCT fs.OrderID) AS Orders
    FROM warehouse.FactSales fs
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK
)
SELECT TOP (30)
    cu.FullName,
    CAST(clv.LifetimeValue AS DECIMAL(18,2))                    AS LifetimeValue,
    clv.Orders,
    RANK()   OVER (ORDER BY clv.LifetimeValue DESC)            AS CLV_Rank,   -- WHAT: global rank
    NTILE(4) OVER (ORDER BY clv.LifetimeValue DESC)            AS CLV_Tier    -- WHAT: 1=platinum
FROM CLV clv
JOIN warehouse.DimCustomer cu ON cu.CustomerSK = clv.CustomerSK
ORDER BY clv.LifetimeValue DESC;


-- ============================================================
-- QUERY #98: Weighted metric — margin-weighted average discount
-- ============================================================
-- BUSINESS PROBLEM: "What's our discount weighted by revenue (not simple average)?"
-- SOLUTION: SUM(discount$)/SUM(revenue) — a weighted rate.
-- SQL CONCEPTS: weighted average via ratio of sums
-- WHY: Simple AVG(discount%) misleads; revenue-weighting is the true rate.
-- WHEN: Margin/pricing analysis.
-- WHAT: Revenue-weighted discount rate per department.
-- POWER BI IMPACT: DIVIDE(SUM disc, SUM gross) weighted measure.
-- DASHBOARD: Finance
-- INTERVIEW TIP: Tests the weighted-average subtlety (ratio of sums vs avg of ratios).
-- ============================================================
SELECT
    c.Department,                                                              -- WHAT: department
    CAST(SUM(fs.DiscountAmount) AS DECIMAL(18,2))                 AS TotalDiscount$, -- WHAT: $ given away
    CAST(SUM(fs.DiscountAmount) * 100.0
         / NULLIF(SUM(fs.LineTotal + fs.DiscountAmount),0)
         AS DECIMAL(5,2))                                        AS WeightedDiscountPct -- WHAT: true rate
FROM warehouse.FactSales fs
JOIN warehouse.DimCategory c ON fs.CategorySK = c.CategorySK
GROUP BY c.Department
ORDER BY WeightedDiscountPct DESC;


-- ============================================================
-- QUERY #99: Inventory turnover proxy — sell-through vs stock
-- ============================================================
-- BUSINESS PROBLEM: "How efficiently is stock converting into sales?"
-- SOLUTION: Units sold / current on-hand per category (turnover proxy).
-- SQL CONCEPTS: cross-fact ratio, latest snapshot
-- WHY: High turnover = efficient capital; low = overstock risk.
-- WHEN: Inventory efficiency review.
-- WHAT: Sell-through ratio per category.
-- POWER BI IMPACT: Turnover KPI on the inventory page.
-- DASHBOARD: Inventory, Finance
-- INTERVIEW TIP: Tests blending transactional + snapshot facts into a ratio.
-- ============================================================
WITH Sold AS (
    SELECT CategorySK, SUM(Quantity) AS UnitsSold
    FROM warehouse.FactSales GROUP BY CategorySK
),
Stock AS (
    SELECT CategorySK, SUM(QuantityOnHand) AS OnHand
    FROM warehouse.FactInventory
    WHERE SnapshotDateKey = (SELECT MAX(SnapshotDateKey) FROM warehouse.FactInventory)
    GROUP BY CategorySK
)
SELECT
    c.CategoryName,
    s.UnitsSold, k.OnHand,
    CAST(s.UnitsSold * 1.0 / NULLIF(k.OnHand,0) AS DECIMAL(10,2)) AS SellThroughRatio -- WHAT: turnover proxy
FROM warehouse.DimCategory c
JOIN Sold  s ON s.CategorySK = c.CategorySK
JOIN Stock k ON k.CategorySK = c.CategorySK
WHERE c.CategorySK <> -1
ORDER BY SellThroughRatio DESC;


-- ============================================================
-- QUERY #100: Executive one-row scorecard (grand finale)
-- ============================================================
-- BUSINESS PROBLEM: "Give me the whole business on a single line."
-- SOLUTION: Scalar subqueries assembling every headline KPI into one row.
-- SQL CONCEPTS: scalar subqueries, safe division, cross-fact
-- WHY: The CEO snapshot — everything at a glance.
-- WHEN: Daily executive briefing.
-- WHAT: Revenue, profit, margin, AOV, orders, customers, return rate, etc.
-- POWER BI IMPACT: Powers the Executive KPI-card row (vw_ExecutiveKPIs).
-- DASHBOARD: Executive
-- INTERVIEW TIP: Tests synthesizing many metrics cleanly in one statement.
-- ============================================================
SELECT
    (SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales)                              AS TotalOrders,       -- WHAT: orders
    (SELECT COUNT(*) FROM warehouse.DimCustomer WHERE CustomerSK <> -1)                    AS TotalCustomers,    -- WHAT: customers
    CAST((SELECT SUM(LineTotal)   FROM warehouse.FactSales) AS DECIMAL(18,2))              AS TotalRevenue,      -- WHAT: revenue
    CAST((SELECT SUM(GrossProfit) FROM warehouse.FactSales) AS DECIMAL(18,2))              AS TotalGrossProfit,  -- WHAT: profit
    CAST((SELECT SUM(GrossProfit)*100.0 / NULLIF(SUM(LineTotal),0)
          FROM warehouse.FactSales) AS DECIMAL(5,2))                                       AS GrossMarginPct,    -- WHAT: margin %
    CAST((SELECT SUM(LineTotal) FROM warehouse.FactSales)
          / NULLIF((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales),0)
          AS DECIMAL(12,2))                                                                AS AvgOrderValue,     -- WHAT: AOV
    CAST((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactReturns)*100.0
          / NULLIF((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales),0)
          AS DECIMAL(5,2))                                                                 AS ReturnRatePct;     -- WHAT: return rate


-- =============================================================================
-- END OF 100-QUERY PORTFOLIO
-- Next: pair these with the analytics views (SQL/Views) and the Power BI guide
-- (Documentation/PowerBI_Implementation_Guide.md) to complete the BI story.
-- =============================================================================
