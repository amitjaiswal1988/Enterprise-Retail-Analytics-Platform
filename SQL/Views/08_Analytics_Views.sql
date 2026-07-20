-- =============================================================================
-- Enterprise Retail Analytics Platform - Presentation Layer: Analytics Views
-- =============================================================================
-- Script:   08_Analytics_Views.sql
-- Purpose:  Business-facing SQL views over the star schema. These are the
--           semantic layer Power BI (and analysts) connect to - every view
--           pre-joins facts to dimensions and pre-computes the BRD KPIs so the
--           report layer stays thin.
-- Schema:   [warehouse]
-- Author:   BI Development Team
-- Created:  2026-07-21
--
-- WHEN:  Phase 3 final step, AFTER the warehouse is loaded
--        (warehouse.usp_LoadAll_StagingToWarehouse).
--
-- WHY:   The BRD asks for 9 dashboards (Executive, Sales, Customer, Inventory,
--        Store, Product, Finance, Regional, Shipping) and 100+ DAX measures.
--        Encapsulating the joins + core KPI math in views gives a single source
--        of truth, keeps DAX simple, and lets us unit-test metrics in SQL.
--
-- WHAT:  10 views mapped to the dashboards / BRD KPIs:
--        1. vw_ExecutiveKPIs       - headline one-row scorecard (Executive)
--        2. vw_SalesByMonth        - monthly revenue/AOV/margin trend (Sales/Finance)  [FR-01, F-01/02/05]
--        3. vw_SalesByCategory     - category/department performance (Product)          [F-02]
--        4. vw_ProductPerformance  - per-product sales + return rate (Product)
--        5. vw_StorePerformance    - store productivity, sales/associate (Store)        [F-06, E-01]
--        6. vw_RegionalSales       - region x channel split (Regional)                  [OBJ-06]
--        7. vw_CustomerAnalysis    - per-customer RFM-style metrics (Customer)          [C-03/04]
--        8. vw_ReturnsAnalysis     - return rate + refund by category/reason            [O-05]
--        9. vw_InventoryHealth     - current stock, stockout/low-stock rate (Inventory) [O-03]
--       10. vw_ShippingPerformance - on-time %, avg transit by carrier/mode (Shipping)  [O-04, FR-10]
--
-- MODE / HOW:  Standard SQL views (no persistence). Refresh is implicit - each
--        query hits the current warehouse data.
--
-- MEASURE CONVENTIONS (consistent everywhere):
--   Revenue      = SUM(FactSales.LineTotal)      (net of discount)
--   COGS         = SUM(FactSales.LineCOGS)
--   GrossProfit  = SUM(FactSales.GrossProfit)
--   GrossMargin% = GrossProfit / Revenue * 100
--   Orders       = COUNT(DISTINCT FactSales.OrderID)   (degenerate dimension)
--   Units        = SUM(FactSales.Quantity)
--   AOV          = Revenue / Orders
--   NULLIF(...,0) guards every division against divide-by-zero.
-- =============================================================================

USE RetailDW;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- =============================================================================
-- VIEW 1: warehouse.vw_ExecutiveKPIs
-- One row of headline numbers for the Executive dashboard cards.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_ExecutiveKPIs', 'V') IS NOT NULL DROP VIEW warehouse.vw_ExecutiveKPIs;
GO
CREATE VIEW warehouse.vw_ExecutiveKPIs
AS
SELECT
    (SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales)                    AS TotalOrders,
    (SELECT SUM(Quantity)          FROM warehouse.FactSales)                     AS TotalUnitsSold,
    CAST((SELECT SUM(LineTotal)    FROM warehouse.FactSales) AS DECIMAL(18,2))   AS TotalRevenue,
    CAST((SELECT SUM(LineCOGS)     FROM warehouse.FactSales) AS DECIMAL(18,2))   AS TotalCOGS,
    CAST((SELECT SUM(GrossProfit)  FROM warehouse.FactSales) AS DECIMAL(18,2))   AS TotalGrossProfit,
    CAST((SELECT SUM(GrossProfit)*100.0 / NULLIF(SUM(LineTotal),0) FROM warehouse.FactSales) AS DECIMAL(5,2)) AS GrossMarginPct,
    -- F-05 Average Order Value
    CAST((SELECT SUM(LineTotal) FROM warehouse.FactSales)
         / NULLIF((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales),0) AS DECIMAL(10,2)) AS AvgOrderValue,
    (SELECT COUNT(*) FROM warehouse.DimCustomer WHERE CustomerSK <> -1)          AS TotalCustomers,
    (SELECT COUNT(*) FROM warehouse.DimStore    WHERE StoreSK    <> -1)          AS TotalStores,
    (SELECT COUNT(*) FROM warehouse.DimProduct  WHERE ProductSK  <> -1)          AS TotalProducts,
    -- O-05 Return Rate = returned orders / total orders
    CAST((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactReturns)*100.0
         / NULLIF((SELECT COUNT(DISTINCT OrderID) FROM warehouse.FactSales),0) AS DECIMAL(5,2)) AS ReturnRatePct,
    CAST((SELECT SUM(RefundAmount) FROM warehouse.FactReturns) AS DECIMAL(18,2)) AS TotalRefunds,
    -- F-06 Revenue per store (store-channel revenue only)
    CAST((SELECT SUM(LineTotal) FROM warehouse.FactSales WHERE StoreSK <> -1)
         / NULLIF((SELECT COUNT(*) FROM warehouse.DimStore WHERE StoreSK <> -1),0) AS DECIMAL(18,2)) AS RevenuePerStore;
GO
PRINT 'Created: warehouse.vw_ExecutiveKPIs';
GO

-- =============================================================================
-- VIEW 2: warehouse.vw_SalesByMonth
-- Monthly trend of revenue, orders, AOV, margin. Powers time-series visuals.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_SalesByMonth', 'V') IS NOT NULL DROP VIEW warehouse.vw_SalesByMonth;
GO
CREATE VIEW warehouse.vw_SalesByMonth
AS
SELECT
    d.Year,
    d.MonthNumber,
    d.MonthName,
    d.YearMonth,
    d.FiscalYear,
    COUNT(DISTINCT fs.OrderID)                                          AS Orders,
    SUM(fs.Quantity)                                                    AS UnitsSold,
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))                          AS Revenue,
    CAST(SUM(fs.LineCOGS)    AS DECIMAL(18,2))                          AS COGS,
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))                          AS GrossProfit,
    CAST(SUM(fs.GrossProfit)*100.0 / NULLIF(SUM(fs.LineTotal),0) AS DECIMAL(5,2)) AS GrossMarginPct,
    CAST(SUM(fs.LineTotal) / NULLIF(COUNT(DISTINCT fs.OrderID),0) AS DECIMAL(10,2)) AS AvgOrderValue
FROM warehouse.FactSales fs
JOIN warehouse.DimDate d ON fs.OrderDateKey = d.DateKey
GROUP BY d.Year, d.MonthNumber, d.MonthName, d.YearMonth, d.FiscalYear;
GO
PRINT 'Created: warehouse.vw_SalesByMonth';
GO

-- =============================================================================
-- VIEW 3: warehouse.vw_SalesByCategory
-- Revenue / margin / units by department and category, split by channel.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_SalesByCategory', 'V') IS NOT NULL DROP VIEW warehouse.vw_SalesByCategory;
GO
CREATE VIEW warehouse.vw_SalesByCategory
AS
SELECT
    dcat.Department,
    dcat.CategoryName,
    fs.Channel,
    COUNT(DISTINCT fs.OrderID)                                          AS Orders,
    SUM(fs.Quantity)                                                    AS UnitsSold,
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))                          AS Revenue,
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))                          AS GrossProfit,
    CAST(SUM(fs.GrossProfit)*100.0 / NULLIF(SUM(fs.LineTotal),0) AS DECIMAL(5,2)) AS GrossMarginPct
FROM warehouse.FactSales fs
JOIN warehouse.DimCategory dcat ON fs.CategorySK = dcat.CategorySK
GROUP BY dcat.Department, dcat.CategoryName, fs.Channel;
GO
PRINT 'Created: warehouse.vw_SalesByCategory';
GO

-- =============================================================================
-- VIEW 4: warehouse.vw_ProductPerformance
-- Per-product sales performance plus its return rate (units returned / sold).
-- LEFT JOIN to a returns rollup so products with zero returns still appear.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_ProductPerformance', 'V') IS NOT NULL DROP VIEW warehouse.vw_ProductPerformance;
GO
CREATE VIEW warehouse.vw_ProductPerformance
AS
SELECT
    dp.ProductID,
    dp.ProductName,
    dp.Brand,
    dp.CategoryName,
    dp.PriceRange,
    dp.UnitPrice,
    dp.UnitCost,
    dp.GrossMargin                                                      AS UnitGrossMargin,
    COUNT(DISTINCT fs.OrderID)                                          AS Orders,
    SUM(fs.Quantity)                                                    AS UnitsSold,
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))                          AS Revenue,
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))                          AS GrossProfit,
    ISNULL(r.UnitsReturned, 0)                                          AS UnitsReturned,
    CAST(ISNULL(r.UnitsReturned,0)*100.0 / NULLIF(SUM(fs.Quantity),0) AS DECIMAL(5,2)) AS ReturnRatePct
FROM warehouse.FactSales fs
JOIN warehouse.DimProduct dp ON fs.ProductSK = dp.ProductSK
LEFT JOIN (
    SELECT ProductSK, SUM(OriginalQuantity) AS UnitsReturned
    FROM warehouse.FactReturns
    GROUP BY ProductSK
) r ON r.ProductSK = dp.ProductSK
GROUP BY dp.ProductID, dp.ProductName, dp.Brand, dp.CategoryName, dp.PriceRange,
         dp.UnitPrice, dp.UnitCost, dp.GrossMargin, r.UnitsReturned;
GO
PRINT 'Created: warehouse.vw_ProductPerformance';
GO

-- =============================================================================
-- VIEW 5: warehouse.vw_StorePerformance
-- Store productivity. Store-channel sales only (StoreSK <> -1 excludes online).
-- Sales per associate (E-01) = revenue / distinct employees who rang up sales.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_StorePerformance', 'V') IS NOT NULL DROP VIEW warehouse.vw_StorePerformance;
GO
CREATE VIEW warehouse.vw_StorePerformance
AS
SELECT
    ds.StoreID,
    ds.StoreName,
    ds.City,
    ds.State,
    ds.Region,
    ds.StoreType,
    ds.StoreSize,
    ds.SquareFootage,
    COUNT(DISTINCT fs.OrderID)                                          AS Orders,
    SUM(fs.Quantity)                                                    AS UnitsSold,
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))                          AS Revenue,
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))                          AS GrossProfit,
    CAST(SUM(fs.LineTotal) / NULLIF(COUNT(DISTINCT fs.OrderID),0) AS DECIMAL(10,2)) AS AvgOrderValue,
    COUNT(DISTINCT fs.EmployeeSK)                                       AS ActiveAssociates,
    CAST(SUM(fs.LineTotal) / NULLIF(COUNT(DISTINCT fs.EmployeeSK),0) AS DECIMAL(18,2)) AS SalesPerAssociate,
    -- Revenue per square foot - classic retail productivity metric
    CAST(SUM(fs.LineTotal) / NULLIF(ds.SquareFootage,0) AS DECIMAL(12,2)) AS RevenuePerSqFt
FROM warehouse.FactSales fs
JOIN warehouse.DimStore ds ON fs.StoreSK = ds.StoreSK
WHERE ds.StoreSK <> -1
GROUP BY ds.StoreID, ds.StoreName, ds.City, ds.State, ds.Region, ds.StoreType,
         ds.StoreSize, ds.SquareFootage;
GO
PRINT 'Created: warehouse.vw_StorePerformance';
GO

-- =============================================================================
-- VIEW 6: warehouse.vw_RegionalSales
-- Region x channel revenue split - supports OBJ-06 cross-channel analysis.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_RegionalSales', 'V') IS NOT NULL DROP VIEW warehouse.vw_RegionalSales;
GO
CREATE VIEW warehouse.vw_RegionalSales
AS
SELECT
    dr.RegionName,
    fs.Channel,
    COUNT(DISTINCT fs.OrderID)                                          AS Orders,
    COUNT(DISTINCT fs.CustomerSK)                                       AS Customers,
    SUM(fs.Quantity)                                                    AS UnitsSold,
    CAST(SUM(fs.LineTotal)   AS DECIMAL(18,2))                          AS Revenue,
    CAST(SUM(fs.GrossProfit) AS DECIMAL(18,2))                          AS GrossProfit,
    CAST(SUM(fs.GrossProfit)*100.0 / NULLIF(SUM(fs.LineTotal),0) AS DECIMAL(5,2)) AS GrossMarginPct,
    CAST(SUM(fs.LineTotal) / NULLIF(COUNT(DISTINCT fs.OrderID),0) AS DECIMAL(10,2)) AS AvgOrderValue
FROM warehouse.FactSales fs
JOIN warehouse.DimRegion dr ON fs.RegionSK = dr.RegionSK
GROUP BY dr.RegionName, fs.Channel;
GO
PRINT 'Created: warehouse.vw_RegionalSales';
GO

-- =============================================================================
-- VIEW 7: warehouse.vw_CustomerAnalysis
-- Per-customer RFM-style metrics for the Customer dashboard.
-- Recency = days since last order relative to the latest order date in the data.
-- IsRepeatCustomer supports C-04 Repeat Purchase Rate.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_CustomerAnalysis', 'V') IS NOT NULL DROP VIEW warehouse.vw_CustomerAnalysis;
GO
CREATE VIEW warehouse.vw_CustomerAnalysis
AS
SELECT
    dc.CustomerID,
    dc.FullName,
    dc.Segment,
    dc.Region,
    dc.City,
    dc.State,
    dc.JoinDate,
    COUNT(DISTINCT fs.OrderID)                                          AS Orders,          -- Frequency
    SUM(fs.Quantity)                                                    AS UnitsBought,
    CAST(SUM(fs.LineTotal) AS DECIMAL(18,2))                            AS TotalSpend,      -- Monetary
    CAST(SUM(fs.LineTotal) / NULLIF(COUNT(DISTINCT fs.OrderID),0) AS DECIMAL(10,2)) AS AvgOrderValue,
    MIN(d.FullDate)                                                     AS FirstOrderDate,
    MAX(d.FullDate)                                                     AS LastOrderDate,
    DATEDIFF(DAY, MAX(d.FullDate),
             (SELECT MAX(FullDate) FROM warehouse.DimDate dd
              JOIN warehouse.FactSales f2 ON f2.OrderDateKey = dd.DateKey))  AS RecencyDays,
    CASE WHEN COUNT(DISTINCT fs.OrderID) > 1 THEN 1 ELSE 0 END          AS IsRepeatCustomer
FROM warehouse.FactSales fs
JOIN warehouse.DimCustomer dc ON fs.CustomerSK = dc.CustomerSK
JOIN warehouse.DimDate d      ON fs.OrderDateKey = d.DateKey
WHERE dc.CustomerSK <> -1
GROUP BY dc.CustomerID, dc.FullName, dc.Segment, dc.Region, dc.City, dc.State, dc.JoinDate;
GO
PRINT 'Created: warehouse.vw_CustomerAnalysis';
GO

-- =============================================================================
-- VIEW 8: warehouse.vw_ReturnsAnalysis
-- Return volume, refunds, and return rate by category and reason (O-05).
-- Return rate here = returned units / units sold in the same category.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_ReturnsAnalysis', 'V') IS NOT NULL DROP VIEW warehouse.vw_ReturnsAnalysis;
GO
CREATE VIEW warehouse.vw_ReturnsAnalysis
AS
SELECT
    dcat.Department,
    dcat.CategoryName,
    fr.Reason,
    fr.Condition,
    COUNT(*)                                                            AS ReturnLines,
    SUM(fr.OriginalQuantity)                                           AS UnitsReturned,
    CAST(SUM(fr.RefundAmount) AS DECIMAL(18,2))                        AS TotalRefund,
    CAST(AVG(CAST(fr.DaysToReturn AS DECIMAL(10,2))) AS DECIMAL(6,1))  AS AvgDaysToReturn
FROM warehouse.FactReturns fr
JOIN warehouse.DimCategory dcat ON fr.CategorySK = dcat.CategorySK
GROUP BY dcat.Department, dcat.CategoryName, fr.Reason, fr.Condition;
GO
PRINT 'Created: warehouse.vw_ReturnsAnalysis';
GO

-- =============================================================================
-- VIEW 9: warehouse.vw_InventoryHealth
-- Current stock health from the LATEST snapshot only (periodic snapshot fact).
-- Stockout rate (O-03) = out-of-stock SKUs / total SKUs.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_InventoryHealth', 'V') IS NOT NULL DROP VIEW warehouse.vw_InventoryHealth;
GO
CREATE VIEW warehouse.vw_InventoryHealth
AS
WITH Latest AS (
    -- Newest snapshot date across the whole fact (single periodic snapshot).
    SELECT MAX(SnapshotDateKey) AS MaxKey FROM warehouse.FactInventory
)
SELECT
    dcat.Department,
    dcat.CategoryName,
    COUNT(*)                                                            AS SKUCount,
    SUM(fi.QuantityOnHand)                                             AS UnitsOnHand,
    CAST(SUM(fi.InventoryValue) AS DECIMAL(18,2))                      AS InventoryValue,
    SUM(CAST(fi.IsOutOfStock AS INT))                                 AS OutOfStockSKUs,
    SUM(CAST(fi.IsLowStock AS INT))                                   AS LowStockSKUs,
    CAST(SUM(CAST(fi.IsOutOfStock AS INT))*100.0 / NULLIF(COUNT(*),0) AS DECIMAL(5,2)) AS StockoutRatePct,
    CAST(SUM(CAST(fi.IsLowStock AS INT))*100.0 / NULLIF(COUNT(*),0) AS DECIMAL(5,2))   AS LowStockRatePct
FROM warehouse.FactInventory fi
JOIN Latest l                   ON fi.SnapshotDateKey = l.MaxKey
JOIN warehouse.DimCategory dcat ON fi.CategorySK = dcat.CategorySK
GROUP BY dcat.Department, dcat.CategoryName;
GO
PRINT 'Created: warehouse.vw_InventoryHealth';
GO

-- =============================================================================
-- VIEW 10: warehouse.vw_ShippingPerformance
-- On-time delivery (O-04) and transit speed by carrier and ship mode.
-- Sourced from staging.Shipping joined to warehouse dims via staging.Orders,
-- because shipping is not modeled as its own fact in this warehouse.
-- SLA ASSUMPTION (no SLA table in source): a delivery is "on-time" if its
-- transit days are within the mode's expected window below. Replace with a
-- real carrier SLA table when available.
-- =============================================================================
IF OBJECT_ID('warehouse.vw_ShippingPerformance', 'V') IS NOT NULL DROP VIEW warehouse.vw_ShippingPerformance;
GO
CREATE VIEW warehouse.vw_ShippingPerformance
AS
SELECT
    s.Carrier,
    s.ShipMode,
    dr.RegionName,
    COUNT(*)                                                            AS Shipments,
    CAST(AVG(CAST(s.TransitDays AS DECIMAL(10,2))) AS DECIMAL(6,2))    AS AvgTransitDays,
    CAST(AVG(s.ShippingCost) AS DECIMAL(10,2))                         AS AvgShippingCost,
    SUM(CASE WHEN s.TransitDays <= (
            CASE s.ShipMode
                WHEN 'Same Day' THEN 1
                WHEN 'Express'  THEN 2
                WHEN 'Standard' THEN 5
                WHEN 'Economy'  THEN 8
                ELSE 7
            END) THEN 1 ELSE 0 END)                                    AS OnTimeShipments,
    CAST(SUM(CASE WHEN s.TransitDays <= (
            CASE s.ShipMode
                WHEN 'Same Day' THEN 1
                WHEN 'Express'  THEN 2
                WHEN 'Standard' THEN 5
                WHEN 'Economy'  THEN 8
                ELSE 7
            END) THEN 1 ELSE 0 END)*100.0 / NULLIF(COUNT(*),0) AS DECIMAL(5,2)) AS OnTimeRatePct
FROM staging.Shipping s
JOIN staging.Orders o          ON s.OrderID    = o.OrderID
LEFT JOIN warehouse.DimCustomer dc ON o.CustomerID = dc.CustomerID
LEFT JOIN warehouse.DimRegion dr   ON dc.Region    = dr.RegionName
GROUP BY s.Carrier, s.ShipMode, dr.RegionName;
GO
PRINT 'Created: warehouse.vw_ShippingPerformance';
GO

PRINT '============================================================';
PRINT '  Analytics Views Complete - 10 Views Created';
PRINT '  Schema: [warehouse]';
PRINT '  Connect Power BI to these views for the 9 dashboards.';
PRINT '============================================================';
GO
