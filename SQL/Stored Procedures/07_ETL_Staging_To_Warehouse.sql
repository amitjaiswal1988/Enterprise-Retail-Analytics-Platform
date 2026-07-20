-- =============================================================================
-- Enterprise Retail Analytics Platform - Warehouse ETL: Staging -> Warehouse
-- =============================================================================
-- Script:   07_ETL_Staging_To_Warehouse.sql
-- Purpose:  Populate the star schema (warehouse.*) from the cleaned staging
--           layer. Generates DimDate, loads all 8 dimensions with surrogate
--           keys, then loads the 3 fact tables resolving business keys ->
--           surrogate keys (routing orphans to the -1 "Unknown" member).
-- Schema:   [warehouse]
-- Author:   BI Development Team
-- Created:  2026-07-21
--
-- WHEN:  Phase 3, final step. Runs AFTER the Landing->Staging ETL
--        (staging.usp_LoadAll_LandingToStaging) has populated staging.*.
--
-- WHY:   The warehouse is the analytics-ready Kimball star schema that Power BI
--        connects to. Facts must store surrogate keys (SKs), not business keys,
--        so we resolve every business key against its dimension here. Orphan
--        keys (e.g. DEF-04 orphan products) are steered to the SK = -1 Unknown
--        member instead of being dropped, so fact totals stay complete.
--
-- WHAT:  1 DimDate generator + 7 dimension loaders + 3 fact loaders + 1 master
--        orchestrator (staging.usp_LoadAll_StagingToWarehouse).
--
-- MODE / HOW:  T-SQL stored procedures, executed via sqlcmd.
--        EXEC staging.usp_LoadAll_StagingToWarehouse;
--
-- DESIGN NOTES:
--   * Dimensions are Type-1 (overwrite). Reload pattern = DELETE WHERE SK<>-1
--     then re-INSERT. We cannot TRUNCATE because (a) the tables are referenced
--     by fact FKs, and (b) TRUNCATE would wipe the -1 Unknown member that was
--     seeded via IDENTITY_INSERT in script 03.
--   * The master proc clears the fact tables FIRST (FK dependency order) so the
--     dimension reloads are unblocked.
--   * All fact SK lookups use LEFT JOIN + ISNULL(sk, -1). This is the canonical
--     Kimball technique: an unmatched business key resolves to the Unknown
--     member rather than causing a row to be lost or an FK to fail.
--   * DateKeys are computed directly as YYYYMMDD (CONVERT style 112). Every
--     fact date must exist in DimDate, so DimDate is generated wide enough to
--     cover all source dates (2020-2026).
-- =============================================================================

USE RetailDW;
GO

-- Consistent SET options for computed columns / filtered indexes across clients.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- =============================================================================
-- PROCEDURE 1: warehouse.usp_Load_DimDate
-- Generates one row per calendar day for 2020-01-01 .. 2026-12-31.
-- DimDate is NOT sourced from a CSV - it is a conformed, generated dimension.
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_DimDate', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_DimDate;
GO

CREATE PROCEDURE warehouse.usp_Load_DimDate
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear existing rows (facts are cleared first by the master proc, so no
    -- FK conflict). DimDate has a natural PK (DateKey), no IDENTITY to reseed.
    DELETE FROM warehouse.DimDate;

    DECLARE @Start DATE = '2020-01-01';
    DECLARE @End   DATE = '2026-12-31';
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    -- Tally CTE: one row per day between @Start and @End (MAXRECURSION 0 lifts
    -- the default 100-row recursion cap; ~2557 days here).
    ;WITH Days AS (
        SELECT @Start AS d
        UNION ALL
        SELECT DATEADD(DAY, 1, d) FROM Days WHERE d < @End
    )
    INSERT INTO warehouse.DimDate (
        DateKey, FullDate, DayOfWeek, DayName, DayOfMonth, DayOfYear, WeekOfYear,
        MonthNumber, MonthName, MonthShort, Quarter, QuarterName, Year,
        YearMonth, YearQuarter, IsWeekend, IsWeekday,
        FiscalYear, FiscalQuarter, FiscalMonth,
        IsCurrentMonth, IsCurrentQuarter, IsCurrentYear, IsHoliday, HolidayName
    )
    SELECT
        CONVERT(INT, CONVERT(CHAR(8), d, 112))                       AS DateKey,      -- YYYYMMDD
        d                                                            AS FullDate,
        -- Deterministic day-of-week (1=Sun..7=Sat) independent of @@DATEFIRST.
        -- 1900-01-07 was a Sunday, so days since then mod 7 gives the weekday.
        CAST((DATEDIFF(DAY, '19000107', d) % 7) + 1 AS TINYINT)      AS DayOfWeek,
        DATENAME(WEEKDAY, d)                                         AS DayName,
        CAST(DAY(d) AS TINYINT)                                      AS DayOfMonth,
        CAST(DATEPART(DAYOFYEAR, d) AS SMALLINT)                     AS DayOfYear,
        CAST(DATEPART(WEEK, d) AS TINYINT)                           AS WeekOfYear,
        CAST(MONTH(d) AS TINYINT)                                    AS MonthNumber,
        DATENAME(MONTH, d)                                           AS MonthName,
        CAST(LEFT(DATENAME(MONTH, d), 3) AS CHAR(3))                 AS MonthShort,
        CAST(DATEPART(QUARTER, d) AS TINYINT)                        AS Quarter,
        CAST('Q' + CAST(DATEPART(QUARTER, d) AS VARCHAR(1)) AS CHAR(2)) AS QuarterName,
        CAST(YEAR(d) AS SMALLINT)                                    AS Year,
        CAST(CAST(YEAR(d) AS CHAR(4)) + '-' + RIGHT('0' + CAST(MONTH(d) AS VARCHAR(2)), 2) AS CHAR(7)) AS YearMonth,
        CAST(CAST(YEAR(d) AS CHAR(4)) + '-Q' + CAST(DATEPART(QUARTER, d) AS VARCHAR(1)) AS CHAR(7))    AS YearQuarter,
        CASE WHEN (DATEDIFF(DAY, '19000107', d) % 7) + 1 IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
        CASE WHEN (DATEDIFF(DAY, '19000107', d) % 7) + 1 IN (1, 7) THEN 0 ELSE 1 END AS IsWeekday,
        -- Retail fiscal year runs Jul -> Jun. Jul becomes fiscal month 1.
        CAST(CASE WHEN MONTH(d) >= 7 THEN YEAR(d) + 1 ELSE YEAR(d) END AS SMALLINT)  AS FiscalYear,
        CAST(((CASE WHEN MONTH(d) >= 7 THEN MONTH(d) - 6 ELSE MONTH(d) + 6 END) - 1) / 3 + 1 AS TINYINT) AS FiscalQuarter,
        CAST(CASE WHEN MONTH(d) >= 7 THEN MONTH(d) - 6 ELSE MONTH(d) + 6 END AS TINYINT) AS FiscalMonth,
        CASE WHEN YEAR(d) = YEAR(@Today) AND MONTH(d) = MONTH(@Today) THEN 1 ELSE 0 END AS IsCurrentMonth,
        CASE WHEN YEAR(d) = YEAR(@Today) AND DATEPART(QUARTER, d) = DATEPART(QUARTER, @Today) THEN 1 ELSE 0 END AS IsCurrentQuarter,
        CASE WHEN YEAR(d) = YEAR(@Today) THEN 1 ELSE 0 END           AS IsCurrentYear,
        -- Simplified fixed-date holiday flags (US retail calendar).
        CASE WHEN (MONTH(d) = 1  AND DAY(d) = 1)
               OR (MONTH(d) = 7  AND DAY(d) = 4)
               OR (MONTH(d) = 12 AND DAY(d) = 25)
              THEN 1 ELSE 0 END                                      AS IsHoliday,
        CASE WHEN MONTH(d) = 1  AND DAY(d) = 1  THEN 'New Year''s Day'
             WHEN MONTH(d) = 7  AND DAY(d) = 4  THEN 'Independence Day'
             WHEN MONTH(d) = 12 AND DAY(d) = 25 THEN 'Christmas Day'
             ELSE NULL END                                          AS HolidayName
    FROM Days
    OPTION (MAXRECURSION 0);

    PRINT 'warehouse.DimDate loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' days';
END;
GO

-- =============================================================================
-- PROCEDURE 2: warehouse.usp_Load_DimRegion   (source: staging.Regions)
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_DimRegion', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_DimRegion;
GO

CREATE PROCEDURE warehouse.usp_Load_DimRegion
AS
BEGIN
    SET NOCOUNT ON;
    -- Keep the -1 Unknown member; refresh all real rows.
    DELETE FROM warehouse.DimRegion WHERE RegionSK <> -1;

    INSERT INTO warehouse.DimRegion (RegionID, RegionName)
    SELECT RegionID, RegionName
    FROM staging.Regions;

    PRINT 'warehouse.DimRegion loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 3: warehouse.usp_Load_DimCategory  (source: staging.Categories)
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_DimCategory', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_DimCategory;
GO

CREATE PROCEDURE warehouse.usp_Load_DimCategory
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.DimCategory WHERE CategorySK <> -1;

    INSERT INTO warehouse.DimCategory (CategoryID, CategoryName, SubCategoryName, Department)
    SELECT CategoryID, CategoryName, SubCategoryName, Department
    FROM staging.Categories;

    PRINT 'warehouse.DimCategory loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 4: warehouse.usp_Load_DimSupplier  (source: staging.Suppliers)
-- LeadTimeCategory / RatingCategory are PERSISTED computed cols - not inserted.
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_DimSupplier', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_DimSupplier;
GO

CREATE PROCEDURE warehouse.usp_Load_DimSupplier
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.DimSupplier WHERE SupplierSK <> -1;

    INSERT INTO warehouse.DimSupplier (SupplierID, SupplierName, Country, LeadTimeDays, Rating, ContactEmail)
    SELECT SupplierID, SupplierName, Country, LeadTimeDays, Rating, ContactEmail
    FROM staging.Suppliers;

    PRINT 'warehouse.DimSupplier loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 5: warehouse.usp_Load_DimStore     (source: staging.Stores)
-- StoreSize / YearsOpen are computed cols - not inserted.
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_DimStore', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_DimStore;
GO

CREATE PROCEDURE warehouse.usp_Load_DimStore
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.DimStore WHERE StoreSK <> -1;

    INSERT INTO warehouse.DimStore (StoreID, StoreName, City, State, Region, StoreType, OpenDate, SquareFootage)
    SELECT StoreID, StoreName, City, State, Region, StoreType, OpenDate, SquareFootage
    FROM staging.Stores;

    PRINT 'warehouse.DimStore loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 6: warehouse.usp_Load_DimEmployee  (source: staging.Employees)
-- FullName exists in staging as a computed col; DimEmployee stores it directly.
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_DimEmployee', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_DimEmployee;
GO

CREATE PROCEDURE warehouse.usp_Load_DimEmployee
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.DimEmployee WHERE EmployeeSK <> -1;

    INSERT INTO warehouse.DimEmployee (EmployeeID, FirstName, LastName, FullName, Department, Role, StoreID, HireDate, Salary, ManagerID)
    SELECT EmployeeID, FirstName, LastName, FullName, Department, Role, StoreID, HireDate, Salary, ManagerID
    FROM staging.Employees;

    PRINT 'warehouse.DimEmployee loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 7: warehouse.usp_Load_DimCustomer  (source: staging.Customers)
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_DimCustomer', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_DimCustomer;
GO

CREATE PROCEDURE warehouse.usp_Load_DimCustomer
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.DimCustomer WHERE CustomerSK <> -1;

    INSERT INTO warehouse.DimCustomer (CustomerID, FirstName, LastName, FullName, Email, Segment, JoinDate, City, State, Region)
    SELECT CustomerID, FirstName, LastName, FullName, Email, Segment, JoinDate, City, State, Region
    FROM staging.Customers;

    PRINT 'warehouse.DimCustomer loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 8: warehouse.usp_Load_DimProduct   (source: staging.Products)
-- staging.Category/SubCategory map to DimProduct.CategoryName/SubCategoryName.
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_DimProduct', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_DimProduct;
GO

CREATE PROCEDURE warehouse.usp_Load_DimProduct
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.DimProduct WHERE ProductSK <> -1;

    INSERT INTO warehouse.DimProduct (ProductID, ProductName, CategoryID, CategoryName, SubCategoryName, Brand, UnitCost, UnitPrice, SupplierID)
    SELECT ProductID, ProductName, CategoryID, Category, SubCategory, Brand, UnitCost, UnitPrice, SupplierID
    FROM staging.Products;

    PRINT 'warehouse.DimProduct loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 9: warehouse.usp_Load_FactSales
-- Grain: one row per order line item (staging.OrderDetails).
-- Joins Orders (header), Products (cost/supplier/category), and every
-- dimension to translate business keys -> surrogate keys. Orphans -> -1.
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_FactSales', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_FactSales;
GO

CREATE PROCEDURE warehouse.usp_Load_FactSales
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.FactSales;

    INSERT INTO warehouse.FactSales (
        OrderDateKey, CustomerSK, ProductSK, StoreSK, EmployeeSK, SupplierSK, CategorySK, RegionSK,
        OrderID, OrderDetailID, Channel, OrderStatus,
        Quantity, UnitPrice, UnitCost, DiscountPercent, DiscountAmount, LineTotal, LineCOGS, GrossProfit
    )
    SELECT
        CONVERT(INT, CONVERT(CHAR(8), o.OrderDate, 112))          AS OrderDateKey,
        ISNULL(dc.CustomerSK, -1)                                 AS CustomerSK,
        ISNULL(dp.ProductSK, -1)                                  AS ProductSK,
        ISNULL(ds.StoreSK, -1)                                    AS StoreSK,      -- -1 = online/unknown
        ISNULL(de.EmployeeSK, -1)                                 AS EmployeeSK,   -- -1 = online/unknown
        ISNULL(dsup.SupplierSK, -1)                               AS SupplierSK,
        ISNULL(dcat.CategorySK, -1)                               AS CategorySK,
        ISNULL(dr.RegionSK, -1)                                   AS RegionSK,
        od.OrderID,
        od.OrderDetailID,
        o.Channel,
        o.Status                                                  AS OrderStatus,
        od.Quantity,
        od.UnitPrice,
        ISNULL(p.UnitCost, 0)                                     AS UnitCost,
        od.Discount * 100                                         AS DiscountPercent,   -- staging stores 0..1 fraction
        CAST(od.Quantity * od.UnitPrice * od.Discount AS DECIMAL(10,2)) AS DiscountAmount,
        od.LineTotal,                                                                   -- revenue (post-discount)
        CAST(od.Quantity * ISNULL(p.UnitCost, 0) AS DECIMAL(12,2)) AS LineCOGS,
        CAST(od.LineTotal - (od.Quantity * ISNULL(p.UnitCost, 0)) AS DECIMAL(12,2)) AS GrossProfit
    FROM staging.OrderDetails od
    INNER JOIN staging.Orders o        ON od.OrderID   = o.OrderID
    LEFT  JOIN staging.Products p      ON od.ProductID = p.ProductID
    LEFT  JOIN warehouse.DimProduct dp ON od.ProductID = dp.ProductID
    LEFT  JOIN warehouse.DimCustomer dc ON o.CustomerID = dc.CustomerID
    LEFT  JOIN warehouse.DimStore ds   ON o.StoreID    = ds.StoreID
    LEFT  JOIN warehouse.DimEmployee de ON o.EmployeeID = de.EmployeeID
    LEFT  JOIN warehouse.DimSupplier dsup ON p.SupplierID = dsup.SupplierID
    LEFT  JOIN warehouse.DimCategory dcat ON p.CategoryID = dcat.CategoryID
    LEFT  JOIN warehouse.DimCustomer dcust ON o.CustomerID = dcust.CustomerID
    LEFT  JOIN warehouse.DimRegion dr  ON dcust.Region = dr.RegionName;

    PRINT 'warehouse.FactSales loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 10: warehouse.usp_Load_FactReturns
-- Grain: one row per returned line item (staging.Returns -> OrderDetails -> Orders).
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_FactReturns', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_FactReturns;
GO

CREATE PROCEDURE warehouse.usp_Load_FactReturns
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.FactReturns;

    INSERT INTO warehouse.FactReturns (
        ReturnDateKey, OrderDateKey, CustomerSK, ProductSK, StoreSK, CategorySK, RegionSK,
        ReturnID, OrderDetailID, OrderID, Reason, Condition,
        RefundAmount, OriginalQuantity, OriginalLineTotal, DaysToReturn
    )
    SELECT
        CONVERT(INT, CONVERT(CHAR(8), r.ReturnDate, 112))         AS ReturnDateKey,
        CONVERT(INT, CONVERT(CHAR(8), o.OrderDate, 112))          AS OrderDateKey,
        ISNULL(dc.CustomerSK, -1)                                 AS CustomerSK,
        ISNULL(dp.ProductSK, -1)                                  AS ProductSK,
        ISNULL(ds.StoreSK, -1)                                    AS StoreSK,
        ISNULL(dcat.CategorySK, -1)                               AS CategorySK,
        ISNULL(dr.RegionSK, -1)                                   AS RegionSK,
        r.ReturnID,
        r.OrderDetailID,
        o.OrderID,
        r.Reason,
        r.Condition,
        r.RefundAmount,
        od.Quantity                                               AS OriginalQuantity,
        od.LineTotal                                              AS OriginalLineTotal,
        DATEDIFF(DAY, o.OrderDate, r.ReturnDate)                  AS DaysToReturn
    FROM staging.Returns r
    INNER JOIN staging.OrderDetails od ON r.OrderDetailID = od.OrderDetailID
    INNER JOIN staging.Orders o        ON od.OrderID      = o.OrderID
    LEFT  JOIN staging.Products p      ON od.ProductID    = p.ProductID
    LEFT  JOIN warehouse.DimProduct dp ON od.ProductID    = dp.ProductID
    LEFT  JOIN warehouse.DimCustomer dc ON o.CustomerID   = dc.CustomerID
    LEFT  JOIN warehouse.DimStore ds   ON o.StoreID       = ds.StoreID
    LEFT  JOIN warehouse.DimCategory dcat ON p.CategoryID = dcat.CategoryID
    LEFT  JOIN warehouse.DimRegion dr  ON dc.Region       = dr.RegionName;

    PRINT 'warehouse.FactReturns loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 11: warehouse.usp_Load_FactInventory
-- Grain: one row per product/store/snapshot date (periodic snapshot).
-- =============================================================================
IF OBJECT_ID('warehouse.usp_Load_FactInventory', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_Load_FactInventory;
GO

CREATE PROCEDURE warehouse.usp_Load_FactInventory
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM warehouse.FactInventory;

    INSERT INTO warehouse.FactInventory (
        SnapshotDateKey, ProductSK, StoreSK, SupplierSK, CategorySK, RegionSK,
        InventoryID, QuantityOnHand, ReorderPoint, ReorderQuantity, UnitCost, InventoryValue,
        IsLowStock, IsOutOfStock
    )
    SELECT
        CONVERT(INT, CONVERT(CHAR(8), i.SnapshotDate, 112))       AS SnapshotDateKey,
        ISNULL(dp.ProductSK, -1)                                  AS ProductSK,
        ISNULL(ds.StoreSK, -1)                                    AS StoreSK,
        ISNULL(dsup.SupplierSK, -1)                               AS SupplierSK,
        ISNULL(dcat.CategorySK, -1)                               AS CategorySK,
        ISNULL(dr.RegionSK, -1)                                   AS RegionSK,
        i.InventoryID,
        i.QuantityOnHand,
        i.ReorderPoint,
        i.ReorderQuantity,
        ISNULL(p.UnitCost, 0)                                     AS UnitCost,
        CAST(i.QuantityOnHand * ISNULL(p.UnitCost, 0) AS DECIMAL(14,2)) AS InventoryValue,
        i.IsLowStock,
        i.IsOutOfStock
    FROM staging.Inventory i
    LEFT JOIN staging.Products p       ON i.ProductID = p.ProductID
    LEFT JOIN warehouse.DimProduct dp  ON i.ProductID = dp.ProductID
    LEFT JOIN warehouse.DimStore ds    ON i.StoreID   = ds.StoreID
    LEFT JOIN warehouse.DimSupplier dsup ON p.SupplierID = dsup.SupplierID
    LEFT JOIN warehouse.DimCategory dcat ON p.CategoryID = dcat.CategoryID
    LEFT JOIN warehouse.DimRegion dr   ON ds.Region   = dr.RegionName;

    PRINT 'warehouse.FactInventory loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- MASTER PROCEDURE: staging.usp_LoadAll_StagingToWarehouse
-- Orchestrates the full warehouse rebuild in FK-safe order:
--   1. Clear facts   2. Load dimensions   3. Load facts
-- =============================================================================
IF OBJECT_ID('warehouse.usp_LoadAll_StagingToWarehouse', 'P') IS NOT NULL DROP PROCEDURE warehouse.usp_LoadAll_StagingToWarehouse;
GO

CREATE PROCEDURE warehouse.usp_LoadAll_StagingToWarehouse
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = GETDATE();

    PRINT '============================================================';
    PRINT '  ETL: Staging -> Warehouse (Start: ' + CONVERT(VARCHAR, @StartTime, 120) + ')';
    PRINT '============================================================';

    -- Step 1: clear fact tables FIRST so dimension reloads are not blocked by FKs.
    DELETE FROM warehouse.FactSales;
    DELETE FROM warehouse.FactReturns;
    DELETE FROM warehouse.FactInventory;
    PRINT '  Facts cleared.';

    -- Step 2: load dimensions (DimDate generated; others sourced from staging).
    EXEC warehouse.usp_Load_DimDate;
    EXEC warehouse.usp_Load_DimRegion;
    EXEC warehouse.usp_Load_DimCategory;
    EXEC warehouse.usp_Load_DimSupplier;
    EXEC warehouse.usp_Load_DimStore;
    EXEC warehouse.usp_Load_DimEmployee;
    EXEC warehouse.usp_Load_DimCustomer;
    EXEC warehouse.usp_Load_DimProduct;

    -- Step 3: load facts (business keys resolved to surrogate keys).
    EXEC warehouse.usp_Load_FactSales;
    EXEC warehouse.usp_Load_FactReturns;
    EXEC warehouse.usp_Load_FactInventory;

    DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, GETDATE());
    PRINT '============================================================';
    PRINT '  Warehouse load complete (Duration: ' + CAST(@Duration AS VARCHAR) + ' seconds)';
    PRINT '============================================================';
END;
GO

PRINT '============================================================';
PRINT '  Warehouse ETL Stored Procedures Created - 11 + 1 Master';
PRINT '  Execute: EXEC warehouse.usp_LoadAll_StagingToWarehouse';
PRINT '============================================================';
GO
