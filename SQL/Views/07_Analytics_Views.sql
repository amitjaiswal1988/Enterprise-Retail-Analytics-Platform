-- =============================================================================
-- ShopStar Retail — Enterprise Analytics Platform
-- Power BI Consumption Views  (Database: RetailDW)
-- =============================================================================
-- File:     SQL/Views/07_Analytics_Views.sql
-- Author:   BI Development Team
-- Created:  2026-07-21
-- Schema:   [warehouse]
--
-- PURPOSE
--   15 purpose-built views that Power BI imports DIRECTLY. Each view pre-joins
--   facts to dimensions and/or pre-aggregates measures so the Power BI model
--   stays small, relationships stay simple, and dashboards load fast.
--
-- WHY VIEWS (vs importing raw tables)
--   * Fewer relationships in the model = simpler, faster engine.
--   * Pre-aggregation shrinks 200K+ fact rows to a few thousand for trend pages.
--   * A single source of truth for KPI math (SQL, unit-testable) — not scattered DAX.
--   * Query folding: Import mode folds the view's SQL back to SQL Server so only
--     the needed rows/columns travel over the wire.
--
-- HOW TO RUN
--   sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Views/07_Analytics_Views.sql"
--
-- NOTE ON NUMBERING
--   08_Analytics_Views.sql already ships 10 semantic views. THIS file (07) adds a
--   Power BI-optimized consumption set (pre-joined, pre-aggregated, RLS, YoY,
--   RFM, ABC). Where names overlap, both scripts DROP-then-CREATE so the last
--   run wins; definitions are kept consistent.
--
-- EACH VIEW DOCUMENTS:
--   WHY THIS VIEW / POWER BI USAGE / PERFORMANCE / INCREMENTAL REFRESH / RLS
-- =============================================================================

USE RetailDW;
GO
SET QUOTED_IDENTIFIER ON;   -- WHAT: ANSI quoting | WHY: view creation consistency
SET ANSI_NULLS ON;          -- WHAT: ANSI nulls   | WHY: predictable NULL logic
GO


-- =============================================================================
-- VIEW 1: warehouse.vw_FactSales_WithDimensions
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      One wide, pre-joined sales table so Power BI needs no
--                     fact→dim joins for detail/drillthrough pages.
-- POWER BI USAGE:     Sales dashboard detail table + drillthrough page.
-- PERFORMANCE:        Joins run once in SQL Server (indexed) instead of being
--                     recomputed by the Power BI engine on every visual.
-- INCREMENTAL REFRESH:Carries OrderDateKey/OrderDate so it can be partitioned
--                     by date if imported as the detail fact.
-- ROW LEVEL SECURITY: Exposes StoreID/Region so RLS filters (DimStore[Region])
--                     apply directly on this flattened table.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_FactSales_WithDimensions','V') IS NOT NULL
    DROP VIEW warehouse.vw_FactSales_WithDimensions;
GO
CREATE VIEW warehouse.vw_FactSales_WithDimensions
AS
SELECT
    fs.SalesFactID,                              -- WHAT: fact PK | WHY: unique row id
    fs.OrderID,                                  -- WHAT: order (degenerate dim)
    fs.OrderDetailID,                            -- WHAT: line id
    d.DateKey        AS OrderDateKey,            -- WHAT: date key | WHY: incremental partition
    d.FullDate       AS OrderDate,               -- WHAT: order date
    d.Year, d.Quarter, d.MonthNumber, d.MonthName, d.YearMonth,  -- WHAT: date parts for slicing
    cu.CustomerID, cu.FullName AS CustomerName, cu.Segment,       -- WHAT: customer attributes
    cu.Region        AS CustomerRegion,          -- WHAT: RLS-relevant region
    p.ProductID, p.ProductName, p.Brand,         -- WHAT: product attributes
    c.Department, c.CategoryName, c.SubCategoryName,  -- WHAT: category hierarchy
    s.StoreID, s.StoreName, s.Region AS StoreRegion, s.StoreType, -- WHAT: store attributes (RLS)
    e.EmployeeID, e.FullName AS EmployeeName,     -- WHAT: selling associate
    fs.Channel, fs.OrderStatus,                   -- WHAT: channel/status
    fs.Quantity,                                  -- WHAT: units (measure)
    fs.LineTotal,                                 -- WHAT: revenue (measure)
    fs.LineCOGS,                                  -- WHAT: COGS (measure)
    fs.GrossProfit,                               -- WHAT: profit (measure)
    fs.DiscountAmount                             -- WHAT: discount $ (measure)
FROM warehouse.FactSales fs
JOIN warehouse.DimDate     d  ON fs.OrderDateKey = d.DateKey      -- WHY: date attributes
JOIN warehouse.DimCustomer cu ON fs.CustomerSK   = cu.CustomerSK  -- WHY: customer attributes
JOIN warehouse.DimProduct  p  ON fs.ProductSK    = p.ProductSK    -- WHY: product attributes
JOIN warehouse.DimCategory c  ON fs.CategorySK   = c.CategorySK   -- WHY: category attributes
JOIN warehouse.DimStore    s  ON fs.StoreSK      = s.StoreSK      -- WHY: store attributes
JOIN warehouse.DimEmployee e  ON fs.EmployeeSK   = e.EmployeeSK;  -- WHY: employee attributes
GO
PRINT 'Created: warehouse.vw_FactSales_WithDimensions';
GO


-- =============================================================================
-- VIEW 2: warehouse.vw_SalesMonthly_Aggregated
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Monthly rollup so trend visuals scan ~dozens of rows, not 200K+.
-- POWER BI USAGE:     Executive & Sales trend charts, KPI cards.
-- PERFORMANCE:        Pre-aggregation is the single biggest dashboard speed-up.
-- INCREMENTAL REFRESH:Grain is month; typically full-refreshed (small). Use the
--                     daily view (V3) for incremental partitions.
-- ROW LEVEL SECURITY: Aggregated across stores — pair with a non-RLS exec role,
--                     or add Region to the GROUP BY if regional RLS is needed.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_SalesMonthly_Aggregated','V') IS NOT NULL
    DROP VIEW warehouse.vw_SalesMonthly_Aggregated;
GO
CREATE VIEW warehouse.vw_SalesMonthly_Aggregated
AS
SELECT
    d.Year,                                                          -- WHAT: year
    d.MonthNumber,                                                   -- WHAT: month sort key
    d.MonthName,                                                     -- WHAT: month label
    d.YearMonth,                                                     -- WHAT: 2025-01 label
    COUNT(DISTINCT fs.OrderID)                       AS Orders,      -- WHAT: order count
    SUM(fs.Quantity)                                 AS Units,       -- WHAT: units
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))       AS Revenue,     -- WHAT: revenue
    CAST(SUM(fs.LineCOGS)    AS DECIMAL(18,2))       AS COGS,        -- WHAT: cost
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))       AS GrossProfit, -- WHAT: profit
    CAST(SUM(fs.GrossProfit)*100.0
         / NULLIF(SUM(fs.LineTotal),0) AS DECIMAL(5,2)) AS GrossMarginPct, -- WHAT: margin
    CAST(SUM(fs.LineTotal)
         / NULLIF(COUNT(DISTINCT fs.OrderID),0) AS DECIMAL(12,2)) AS AvgOrderValue -- WHAT: AOV
FROM warehouse.FactSales fs
JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
GROUP BY d.Year, d.MonthNumber, d.MonthName, d.YearMonth;
GO
PRINT 'Created: warehouse.vw_SalesMonthly_Aggregated';
GO


-- =============================================================================
-- VIEW 3: warehouse.vw_SalesDaily_ForIncremental
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Date-grained fact designed for Power BI incremental refresh.
-- POWER BI USAGE:     The imported sales fact when the model uses incremental refresh.
-- PERFORMANCE:        Daily grain balances detail vs size; folds a date filter to SQL.
-- INCREMENTAL REFRESH:Exposes OrderDate (a real DATE) so RangeStart/RangeEnd
--                     parameters can filter OrderDate >= RangeStart AND < RangeEnd.
-- ROW LEVEL SECURITY: Carries StoreRegion for regional RLS on the fact.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_SalesDaily_ForIncremental','V') IS NOT NULL
    DROP VIEW warehouse.vw_SalesDaily_ForIncremental;
GO
CREATE VIEW warehouse.vw_SalesDaily_ForIncremental
AS
SELECT
    d.FullDate                                       AS OrderDate,   -- WHAT: DATE | WHY: incremental filter column
    d.DateKey                                        AS OrderDateKey,-- WHAT: int key
    s.Region                                         AS StoreRegion, -- WHAT: RLS dimension
    fs.Channel,                                                     -- WHAT: channel
    COUNT(DISTINCT fs.OrderID)                       AS Orders,      -- WHAT: orders
    SUM(fs.Quantity)                                 AS Units,       -- WHAT: units
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))       AS Revenue,     -- WHAT: revenue
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))       AS GrossProfit  -- WHAT: profit
FROM warehouse.FactSales fs
JOIN warehouse.DimDate  d ON fs.OrderDateKey = d.DateKey
JOIN warehouse.DimStore s ON fs.StoreSK      = s.StoreSK
GROUP BY d.FullDate, d.DateKey, s.Region, fs.Channel;
GO
PRINT 'Created: warehouse.vw_SalesDaily_ForIncremental';
GO


-- =============================================================================
-- VIEW 4: warehouse.vw_CustomerRFM
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Ships Recency/Frequency/Monetary + segment so the model
--                     doesn't need heavy DAX quantile logic.
-- POWER BI USAGE:     Customer dashboard segment slicer & scatter.
-- PERFORMANCE:        NTILE runs once in SQL vs recomputing RANKX in DAX per visual.
-- INCREMENTAL REFRESH:Customer grain (~20K) — full refresh is cheap.
-- ROW LEVEL SECURITY: Carries Region for regional CRM RLS.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_CustomerRFM','V') IS NOT NULL
    DROP VIEW warehouse.vw_CustomerRFM;
GO
CREATE VIEW warehouse.vw_CustomerRFM
AS
WITH RFM AS (
    SELECT
        fs.CustomerSK,
        DATEDIFF(DAY, MAX(d.FullDate),
                 (SELECT MAX(FullDate) FROM warehouse.DimDate d2
                  JOIN warehouse.FactSales f2 ON f2.OrderDateKey = d2.DateKey)) AS Recency, -- WHAT: days since last buy
        COUNT(DISTINCT fs.OrderID) AS Frequency,                    -- WHAT: order count
        SUM(fs.LineTotal)          AS Monetary                      -- WHAT: total spend
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK
),
Scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency ASC)    AS R,               -- WHAT: recency score (5=best)
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F,               -- WHAT: frequency score
        NTILE(5) OVER (ORDER BY Monetary DESC)  AS M                -- WHAT: monetary score
    FROM RFM
)
SELECT
    cu.CustomerID, cu.FullName, cu.Segment, cu.Region,              -- WHAT: customer attributes
    s.Recency, s.Frequency,
    CAST(s.Monetary AS DECIMAL(18,2)) AS Monetary,                  -- WHAT: spend
    s.R, s.F, s.M,                                                  -- WHAT: RFM scores
    CASE                                                            -- WHAT: named segment
        WHEN s.R >= 4 AND s.F >= 4 AND s.M >= 4 THEN 'Champions'
        WHEN s.R >= 4 AND s.F >= 3               THEN 'Loyal'
        WHEN s.R >= 4                            THEN 'Recent'
        WHEN s.R <= 2 AND s.F >= 3               THEN 'At Risk'
        WHEN s.R <= 2                            THEN 'Lapsed'
        ELSE 'Developing'
    END AS RFM_Segment
FROM Scored s
JOIN warehouse.DimCustomer cu ON cu.CustomerSK = s.CustomerSK;
GO
PRINT 'Created: warehouse.vw_CustomerRFM';
GO


-- =============================================================================
-- VIEW 5: warehouse.vw_ProductABC
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Pre-computes ABC/Pareto class so the Product page can slice
--                     A/B/C instantly.
-- POWER BI USAGE:     Product dashboard ABC slicer + Pareto chart.
-- PERFORMANCE:        Running-total window runs once in SQL, not per DAX visual.
-- INCREMENTAL REFRESH:Product grain (~2K) — full refresh trivial.
-- ROW LEVEL SECURITY: Product-level; no store filter needed (global assortment).
-- =============================================================================
IF OBJECT_ID('warehouse.vw_ProductABC','V') IS NOT NULL
    DROP VIEW warehouse.vw_ProductABC;
GO
CREATE VIEW warehouse.vw_ProductABC
AS
WITH ProdRev AS (
    SELECT p.ProductID, p.ProductName, p.CategoryName,
           SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimProduct p ON fs.ProductSK = p.ProductSK
    GROUP BY p.ProductID, p.ProductName, p.CategoryName
),
Cumulative AS (
    SELECT *,
        SUM(Revenue) OVER (ORDER BY Revenue DESC ROWS UNBOUNDED PRECEDING) AS RunningRev, -- WHAT: cumulative $
        SUM(Revenue) OVER ()                                              AS TotalRev
    FROM ProdRev
)
SELECT
    ProductID, ProductName, CategoryName,
    CAST(Revenue AS DECIMAL(18,2))                              AS Revenue,
    CAST(RunningRev * 100.0 / NULLIF(TotalRev,0) AS DECIMAL(5,2)) AS CumulativePct, -- WHAT: 0..100
    CASE                                                        -- WHAT: ABC class
        WHEN RunningRev * 100.0 / NULLIF(TotalRev,0) <= 80 THEN 'A'
        WHEN RunningRev * 100.0 / NULLIF(TotalRev,0) <= 95 THEN 'B'
        ELSE 'C'
    END AS ABC_Class
FROM Cumulative;
GO
PRINT 'Created: warehouse.vw_ProductABC';
GO


-- =============================================================================
-- VIEW 6: warehouse.vw_InventoryAlerts
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Current low/out-of-stock rows only — an actionable alert list.
-- POWER BI USAGE:     Inventory dashboard alert table + stockout KPI cards.
-- PERFORMANCE:        Filters to the latest snapshot so Power BI imports ~current rows.
-- INCREMENTAL REFRESH:Snapshot fact; typically full-refresh of the latest snapshot.
-- ROW LEVEL SECURITY: Carries StoreRegion so store/regional managers see only theirs.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_InventoryAlerts','V') IS NOT NULL
    DROP VIEW warehouse.vw_InventoryAlerts;
GO
CREATE VIEW warehouse.vw_InventoryAlerts
AS
SELECT
    i.SnapshotDateKey,                                             -- WHAT: snapshot date
    p.ProductID, p.ProductName, c.CategoryName,                   -- WHAT: product context
    s.StoreID, s.StoreName, s.Region AS StoreRegion,              -- WHAT: store context (RLS)
    i.QuantityOnHand, i.ReorderPoint,                             -- WHAT: stock levels
    CAST(i.InventoryValue AS DECIMAL(18,2)) AS InventoryValue,    -- WHAT: capital at risk
    i.IsLowStock, i.IsOutOfStock                                  -- WHAT: alert flags
FROM warehouse.FactInventory i
JOIN warehouse.DimProduct  p ON i.ProductSK  = p.ProductSK
JOIN warehouse.DimCategory c ON i.CategorySK = c.CategorySK
JOIN warehouse.DimStore    s ON i.StoreSK    = s.StoreSK
WHERE i.SnapshotDateKey = (SELECT MAX(SnapshotDateKey) FROM warehouse.FactInventory) -- WHY: current only
  AND (i.IsLowStock = 1 OR i.IsOutOfStock = 1);                   -- WHY: only items needing action
GO
PRINT 'Created: warehouse.vw_InventoryAlerts';
GO


-- =============================================================================
-- VIEW 7: warehouse.vw_StorePerformance_KPIs
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Pre-calculated per-store KPIs (revenue, AOV, revenue/sqft).
-- POWER BI USAGE:     Store dashboard scorecard + map.
-- PERFORMANCE:        One aggregate per store (~50 rows) — instant visuals.
-- INCREMENTAL REFRESH:Small; full refresh.
-- ROW LEVEL SECURITY: Region/StoreID exposed for store-manager RLS.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_StorePerformance_KPIs','V') IS NOT NULL
    DROP VIEW warehouse.vw_StorePerformance_KPIs;
GO
CREATE VIEW warehouse.vw_StorePerformance_KPIs
AS
SELECT
    s.StoreID, s.StoreName, s.Region, s.StoreType, s.StoreSize,    -- WHAT: store attributes
    s.SquareFootage,                                              -- WHAT: size for productivity
    COUNT(DISTINCT fs.OrderID)                       AS Orders,    -- WHAT: orders
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))       AS Revenue,   -- WHAT: revenue
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))       AS GrossProfit,-- WHAT: profit
    CAST(SUM(fs.LineTotal)
         / NULLIF(COUNT(DISTINCT fs.OrderID),0) AS DECIMAL(12,2)) AS AvgOrderValue, -- WHAT: AOV
    CAST(SUM(fs.LineTotal)
         / NULLIF(s.SquareFootage,0) AS DECIMAL(12,2))           AS RevenuePerSqFt  -- WHAT: space productivity
FROM warehouse.FactSales fs
JOIN warehouse.DimStore s ON fs.StoreSK = s.StoreSK
WHERE s.StoreSK <> -1                                             -- WHY: exclude online/unknown
GROUP BY s.StoreID, s.StoreName, s.Region, s.StoreType, s.StoreSize, s.SquareFootage;
GO
PRINT 'Created: warehouse.vw_StorePerformance_KPIs';
GO


-- =============================================================================
-- VIEW 8: warehouse.vw_RegionalComparison
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Region-level revenue with a rank for league-table visuals.
-- POWER BI USAGE:     Regional dashboard ranking + map.
-- PERFORMANCE:        ~5 rows; rank precomputed.
-- INCREMENTAL REFRESH:Tiny; full refresh.
-- ROW LEVEL SECURITY: If regional RLS is on, a manager sees only their region row.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_RegionalComparison','V') IS NOT NULL
    DROP VIEW warehouse.vw_RegionalComparison;
GO
CREATE VIEW warehouse.vw_RegionalComparison
AS
SELECT
    r.RegionName,                                                 -- WHAT: region
    COUNT(DISTINCT fs.OrderID)                       AS Orders,   -- WHAT: orders
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))       AS Revenue,  -- WHAT: revenue
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))       AS GrossProfit, -- WHAT: profit
    RANK() OVER (ORDER BY SUM(fs.LineTotal) DESC)    AS RevenueRank, -- WHAT: league rank
    CAST(SUM(fs.LineTotal)*100.0
         / SUM(SUM(fs.LineTotal)) OVER () AS DECIMAL(5,2)) AS PctOfTotal -- WHAT: share
FROM warehouse.FactSales fs
JOIN warehouse.DimRegion r ON fs.RegionSK = r.RegionSK
GROUP BY r.RegionName;
GO
PRINT 'Created: warehouse.vw_RegionalComparison';
GO


-- =============================================================================
-- VIEW 9: warehouse.vw_EmployeeSalesMetrics
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Sales per associate (in-store only) for productivity views.
-- POWER BI USAGE:     Store dashboard associate leaderboard.
-- PERFORMANCE:        One row per selling employee.
-- INCREMENTAL REFRESH:Small; full refresh.
-- ROW LEVEL SECURITY: StoreID/Region exposed so managers see only their team.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_EmployeeSalesMetrics','V') IS NOT NULL
    DROP VIEW warehouse.vw_EmployeeSalesMetrics;
GO
CREATE VIEW warehouse.vw_EmployeeSalesMetrics
AS
SELECT
    e.EmployeeID, e.FullName, e.Role, e.Department,               -- WHAT: employee attributes
    e.StoreID,                                                   -- WHAT: store (RLS)
    st.Region,                                                   -- WHAT: region (RLS)
    COUNT(DISTINCT fs.OrderID)                       AS Orders,   -- WHAT: orders handled
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))       AS Revenue,  -- WHAT: revenue sold
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))       AS GrossProfit, -- WHAT: profit sold
    CAST(SUM(fs.LineTotal)
         / NULLIF(COUNT(DISTINCT fs.OrderID),0) AS DECIMAL(12,2)) AS AvgOrderValue -- WHAT: AOV per associate
FROM warehouse.FactSales fs
JOIN warehouse.DimEmployee e ON fs.EmployeeSK = e.EmployeeSK
LEFT JOIN warehouse.DimStore st ON e.StoreID = st.StoreID        -- WHY: region for RLS/context
WHERE e.EmployeeSK <> -1                                          -- WHY: exclude online orders
GROUP BY e.EmployeeID, e.FullName, e.Role, e.Department, e.StoreID, st.Region;
GO
PRINT 'Created: warehouse.vw_EmployeeSalesMetrics';
GO


-- =============================================================================
-- VIEW 10: warehouse.vw_ShippingPerformance
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      On-time % and avg transit by carrier/mode (sourced from staging).
-- POWER BI USAGE:     Shipping dashboard KPIs.
-- PERFORMANCE:        Aggregated to carrier×mode (dozens of rows).
-- INCREMENTAL REFRESH:Could partition on ShipDate if imported at order grain.
-- ROW LEVEL SECURITY: Order-level shipping is channel-agnostic; region via Orders join if needed.
-- NOTE:               Shipping is modeled only in staging (no shipping fact yet).
--                     On-time SLA assumption (no SLA table in source):
--                     Same Day<=1, Express<=2, Standard<=5, Economy<=8 transit days.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_ShippingPerformance','V') IS NOT NULL
    DROP VIEW warehouse.vw_ShippingPerformance;
GO
CREATE VIEW warehouse.vw_ShippingPerformance
AS
SELECT
    sh.Carrier,                                                  -- WHAT: carrier
    sh.ShipMode,                                                 -- WHAT: service level
    COUNT(*)                                          AS Shipments, -- WHAT: shipment count
    CAST(AVG(CAST(sh.TransitDays AS DECIMAL(6,2))) AS DECIMAL(6,2)) AS AvgTransitDays, -- WHAT: speed
    CAST(SUM(CASE WHEN sh.TransitDays <=                          -- WHAT: on-time count vs SLA
                CASE sh.ShipMode
                    WHEN 'Same Day' THEN 1
                    WHEN 'Express'  THEN 2
                    WHEN 'Standard' THEN 5
                    WHEN 'Economy'  THEN 8
                    ELSE 5 END
              THEN 1 ELSE 0 END) * 100.0
         / NULLIF(COUNT(*),0) AS DECIMAL(5,2))        AS OnTimePct, -- WHAT: on-time %
    CAST(SUM(sh.ShippingCost) AS DECIMAL(18,2))       AS TotalShippingCost -- WHAT: cost
FROM staging.Shipping sh
GROUP BY sh.Carrier, sh.ShipMode;
GO
PRINT 'Created: warehouse.vw_ShippingPerformance';
GO


-- =============================================================================
-- VIEW 11: warehouse.vw_ReturnAnalysis
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Return rate + refund by category and reason.
-- POWER BI USAGE:     Sales/Returns dashboard breakdowns.
-- PERFORMANCE:        Pre-joins returns to category and pre-aggregates.
-- INCREMENTAL REFRESH:Could partition on ReturnDateKey if imported at detail grain.
-- ROW LEVEL SECURITY: Carries Region so returns can be filtered per region.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_ReturnAnalysis','V') IS NOT NULL
    DROP VIEW warehouse.vw_ReturnAnalysis;
GO
CREATE VIEW warehouse.vw_ReturnAnalysis
AS
SELECT
    c.CategoryName,                                              -- WHAT: category
    rg.RegionName,                                              -- WHAT: region (RLS)
    r.Reason,                                                   -- WHAT: return reason
    COUNT(*)                                          AS Returns,-- WHAT: return count
    SUM(r.OriginalQuantity)                          AS UnitsReturned, -- WHAT: units back
    CAST(SUM(r.RefundAmount) AS DECIMAL(18,2))       AS TotalRefund,   -- WHAT: refunded $
    CAST(AVG(CAST(r.DaysToReturn AS DECIMAL(6,2))) AS DECIMAL(6,2)) AS AvgDaysToReturn -- WHAT: speed
FROM warehouse.FactReturns r
JOIN warehouse.DimCategory c  ON r.CategorySK = c.CategorySK
JOIN warehouse.DimRegion   rg ON r.RegionSK   = rg.RegionSK
GROUP BY c.CategoryName, rg.RegionName, r.Reason;
GO
PRINT 'Created: warehouse.vw_ReturnAnalysis';
GO


-- =============================================================================
-- VIEW 12: warehouse.vw_CustomerSegmentation
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Lifecycle label (New / Returning / Lapsed) per customer.
-- POWER BI USAGE:     Customer dashboard lifecycle slicer.
-- PERFORMANCE:        One row per customer with the label precomputed.
-- INCREMENTAL REFRESH:Customer grain — full refresh.
-- ROW LEVEL SECURITY: Region exposed for regional CRM RLS.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_CustomerSegmentation','V') IS NOT NULL
    DROP VIEW warehouse.vw_CustomerSegmentation;
GO
CREATE VIEW warehouse.vw_CustomerSegmentation
AS
WITH Activity AS (
    SELECT fs.CustomerSK,
           COUNT(DISTINCT fs.OrderID) AS Orders,
           MAX(d.FullDate)            AS LastOrder
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    WHERE fs.CustomerSK <> -1
    GROUP BY fs.CustomerSK
),
Anchor AS ( SELECT MAX(FullDate) AS MaxDate FROM warehouse.DimDate d
            JOIN warehouse.FactSales f ON f.OrderDateKey = d.DateKey )
SELECT
    cu.CustomerID, cu.FullName, cu.Segment, cu.Region,           -- WHAT: customer attributes
    a.Orders,                                                    -- WHAT: order count
    a.LastOrder,                                                 -- WHAT: recency anchor
    CASE                                                         -- WHAT: lifecycle label
        WHEN a.Orders = 1 THEN 'New'
        WHEN DATEDIFF(DAY, a.LastOrder, (SELECT MaxDate FROM Anchor)) > 180 THEN 'Lapsed'
        ELSE 'Returning'
    END AS Lifecycle
FROM Activity a
JOIN warehouse.DimCustomer cu ON cu.CustomerSK = a.CustomerSK;
GO
PRINT 'Created: warehouse.vw_CustomerSegmentation';
GO


-- =============================================================================
-- VIEW 13: warehouse.vw_ExecutiveKPIs
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Single-row headline scorecard for KPI cards.
-- POWER BI USAGE:     Executive dashboard card row.
-- PERFORMANCE:        One row — the cheapest possible import.
-- INCREMENTAL REFRESH:N/A (single aggregate row); full refresh.
-- ROW LEVEL SECURITY: Company-wide; assign to an exec role WITHOUT store RLS.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_ExecutiveKPIs','V') IS NOT NULL
    DROP VIEW warehouse.vw_ExecutiveKPIs;
GO
CREATE VIEW warehouse.vw_ExecutiveKPIs
AS
SELECT
    (SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales)                    AS TotalOrders,     -- WHAT: orders
    (SELECT SUM(Quantity)          FROM warehouse.FactSales)                     AS TotalUnits,      -- WHAT: units
    CAST((SELECT SUM(LineTotal)    FROM warehouse.FactSales) AS DECIMAL(18,2))   AS TotalRevenue,    -- WHAT: revenue
    CAST((SELECT SUM(GrossProfit)  FROM warehouse.FactSales) AS DECIMAL(18,2))   AS TotalGrossProfit,-- WHAT: profit
    CAST((SELECT SUM(GrossProfit)*100.0 / NULLIF(SUM(LineTotal),0)
          FROM warehouse.FactSales) AS DECIMAL(5,2))                             AS GrossMarginPct,  -- WHAT: margin
    CAST((SELECT SUM(LineTotal) FROM warehouse.FactSales)
          / NULLIF((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales),0)
          AS DECIMAL(12,2))                                                      AS AvgOrderValue,   -- WHAT: AOV
    (SELECT COUNT(*) FROM warehouse.DimCustomer WHERE CustomerSK <> -1)          AS TotalCustomers,  -- WHAT: customers
    (SELECT COUNT(*) FROM warehouse.DimStore    WHERE StoreSK    <> -1)          AS TotalStores,     -- WHAT: stores
    CAST((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactReturns)*100.0
          / NULLIF((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales),0)
          AS DECIMAL(5,2))                                                       AS ReturnRatePct;   -- WHAT: return rate
GO
PRINT 'Created: warehouse.vw_ExecutiveKPIs';
GO


-- =============================================================================
-- VIEW 14: warehouse.vw_YoY_Comparison
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      Current vs prior year by month, with YoY %.
-- POWER BI USAGE:     Executive/Finance YoY charts (no DAX time-intelligence needed).
-- PERFORMANCE:        Pre-joined self-comparison; dozens of rows.
-- INCREMENTAL REFRESH:Month grain; full refresh.
-- ROW LEVEL SECURITY: Company-wide; add Region to GROUP BY for regional YoY.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_YoY_Comparison','V') IS NOT NULL
    DROP VIEW warehouse.vw_YoY_Comparison;
GO
CREATE VIEW warehouse.vw_YoY_Comparison
AS
WITH MonthYear AS (
    SELECT d.Year, d.MonthNumber, d.MonthName, SUM(fs.LineTotal) AS Revenue
    FROM warehouse.FactSales fs
    JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.MonthNumber, d.MonthName
)
SELECT
    cur.Year, cur.MonthNumber, cur.MonthName,                                    -- WHAT: current period
    CAST(cur.Revenue AS DECIMAL(18,2))                          AS ThisYear,     -- WHAT: this-year revenue
    CAST(pri.Revenue AS DECIMAL(18,2))                          AS LastYear,     -- WHAT: prior-year revenue
    CAST((cur.Revenue - pri.Revenue) * 100.0
         / NULLIF(pri.Revenue,0) AS DECIMAL(6,2))               AS YoYPct        -- WHAT: growth %
FROM MonthYear cur
LEFT JOIN MonthYear pri
       ON pri.MonthNumber = cur.MonthNumber
      AND pri.Year = cur.Year - 1;                             -- WHY: same month, prior year
GO
PRINT 'Created: warehouse.vw_YoY_Comparison';
GO


-- =============================================================================
-- VIEW 15: warehouse.vw_RLS_StoreAccess
-- -----------------------------------------------------------------------------
-- WHY THIS VIEW:      A store-grained access surface for Row-Level Security mapping.
-- POWER BI USAGE:     Bridge/security dimension used by RLS DAX filters.
-- PERFORMANCE:        Tiny (one row per store); negligible.
-- INCREMENTAL REFRESH:Static-ish; full refresh.
-- ROW LEVEL SECURITY: THIS is the RLS anchor. In Power BI, create a security
--                     table mapping UserEmail→StoreID (or Region), then a DAX
--                     filter on this view:
--                       [StoreID] = LOOKUPVALUE(Security[StoreID],
--                                     Security[UserEmail], USERPRINCIPALNAME())
--                     For static RLS: filter [Region] = "East" in the role.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_RLS_StoreAccess','V') IS NOT NULL
    DROP VIEW warehouse.vw_RLS_StoreAccess;
GO
CREATE VIEW warehouse.vw_RLS_StoreAccess
AS
SELECT
    s.StoreID,                                                   -- WHAT: store key for RLS mapping
    s.StoreName,                                                 -- WHAT: label
    s.Region,                                                    -- WHAT: region for static/regional RLS
    s.State,                                                     -- WHAT: state (finer filter)
    s.StoreType                                                  -- WHAT: format context
FROM warehouse.DimStore s
WHERE s.StoreSK <> -1;                                           -- WHY: real stores only
GO
PRINT 'Created: warehouse.vw_RLS_StoreAccess';
GO


-- =============================================================================
-- SUMMARY
-- =============================================================================
PRINT '============================================================';
PRINT '  Power BI Consumption Views Complete — 15 Views';
PRINT '  vw_FactSales_WithDimensions, vw_SalesMonthly_Aggregated,';
PRINT '  vw_SalesDaily_ForIncremental, vw_CustomerRFM, vw_ProductABC,';
PRINT '  vw_InventoryAlerts, vw_StorePerformance_KPIs,';
PRINT '  vw_RegionalComparison, vw_EmployeeSalesMetrics,';
PRINT '  vw_ShippingPerformance, vw_ReturnAnalysis,';
PRINT '  vw_CustomerSegmentation, vw_ExecutiveKPIs,';
PRINT '  vw_YoY_Comparison, vw_RLS_StoreAccess';
PRINT '  -> Import these into Power BI (see PowerBI_Implementation_Guide.md)';
PRINT '============================================================';
GO
