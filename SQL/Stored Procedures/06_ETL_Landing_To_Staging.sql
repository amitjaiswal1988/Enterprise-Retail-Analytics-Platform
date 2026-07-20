-- =============================================================================
-- Enterprise Retail Analytics Platform - ETL: Landing → Staging
-- =============================================================================
-- Script:      06_ETL_Landing_To_Staging.sql
-- Purpose:     Stored procedures to clean and transform landing data into staging
-- Schema:      [staging]
-- Author:      BI Development Team
-- Created:     2026-07-20
--
-- ETL OPERATIONS PERFORMED:
--   1. Data type casting (VARCHAR → proper types)
--   2. Deduplication (DEF-02: duplicate orders)
--   3. NULL handling (DEF-01: missing emails flagged)
--   4. Date validation (DEF-03: future dates quarantined)
--   5. Category standardization (DEF-05: casing normalized)
--   6. Negative quantity correction (DEF-06: ABS applied)
--   7. Orphan product flagging (DEF-04: marked for review)
--
-- EXECUTION ORDER:
--   1. Load dimensions first (Regions, Categories, Suppliers, Stores, Employees)
--   2. Load Customers, Products
--   3. Load Orders (depends on Customers)
--   4. Load OrderDetails (depends on Orders, Products)
--   5. Load Returns, Shipping (depends on Orders/OrderDetails)
--   6. Load Inventory (depends on Stores, Products)
--
-- MASTER PROCEDURE: EXEC staging.usp_LoadAll_LandingToStaging
-- =============================================================================

USE RetailDW;
GO

-- Procedures capture SET options at creation time; ensure correct settings
-- for computed columns / indexed access across all clients.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- =============================================================================
-- PROCEDURE 1: staging.usp_Load_Regions
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Regions', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Regions;
GO

CREATE PROCEDURE staging.usp_Load_Regions
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Regions;
    
    INSERT INTO staging.Regions (RegionID, RegionName)
    SELECT 
        CAST(RegionID AS INT),
        LTRIM(RTRIM(RegionName))
    FROM landing.Regions
    WHERE RegionID IS NOT NULL 
      AND RegionName IS NOT NULL;
    
    PRINT 'staging.Regions loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 2: staging.usp_Load_Categories
-- Handles DEF-05: Inconsistent casing → normalized to canonical names
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Categories', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Categories;
GO

CREATE PROCEDURE staging.usp_Load_Categories
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Categories;
    
    INSERT INTO staging.Categories (CategoryID, CategoryName, SubCategoryName, Department)
    SELECT 
        CAST(CategoryID AS INT),
        -- DEF-05 FIX: Normalize category names using canonical mapping
        CASE UPPER(LTRIM(RTRIM(CategoryName)))
            WHEN 'ELECTRONICS'              THEN 'Electronics'
            WHEN 'HOME & KITCHEN'           THEN 'Home & Kitchen'
            WHEN 'OFFICE SUPPLIES'          THEN 'Office Supplies'
            WHEN 'FURNITURE'                THEN 'Furniture'
            WHEN 'TECHNOLOGY ACCESSORIES'   THEN 'Technology Accessories'
            ELSE LTRIM(RTRIM(CategoryName))  -- Keep as-is if unknown
        END,
        LTRIM(RTRIM(SubCategoryName)),
        ISNULL(LTRIM(RTRIM(Department)), 'Retail')
    FROM landing.Categories
    WHERE CategoryID IS NOT NULL;
    
    PRINT 'staging.Categories loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows (casing normalized)';
END;
GO

-- =============================================================================
-- PROCEDURE 3: staging.usp_Load_Suppliers
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Suppliers', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Suppliers;
GO

CREATE PROCEDURE staging.usp_Load_Suppliers
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Suppliers;
    
    INSERT INTO staging.Suppliers (SupplierID, SupplierName, Country, LeadTimeDays, Rating, ContactEmail)
    SELECT 
        CAST(SupplierID AS INT),
        LTRIM(RTRIM(SupplierName)),
        LTRIM(RTRIM(Country)),
        CAST(LeadTimeDays AS INT),
        CAST(Rating AS DECIMAL(3,1)),
        LTRIM(RTRIM(ContactEmail))
    FROM landing.Suppliers
    WHERE SupplierID IS NOT NULL
      AND TRY_CAST(LeadTimeDays AS INT) IS NOT NULL
      AND TRY_CAST(Rating AS DECIMAL(3,1)) IS NOT NULL;
    
    PRINT 'staging.Suppliers loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 4: staging.usp_Load_Products
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Products', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Products;
GO

CREATE PROCEDURE staging.usp_Load_Products
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Products;
    
    INSERT INTO staging.Products (ProductID, ProductName, CategoryID, Category, SubCategory, Brand, UnitCost, UnitPrice, SupplierID)
    SELECT 
        CAST(ProductID AS INT),
        LTRIM(RTRIM(ProductName)),
        CAST(CategoryID AS INT),
        -- Normalize category name here too
        CASE UPPER(LTRIM(RTRIM(Category)))
            WHEN 'ELECTRONICS'              THEN 'Electronics'
            WHEN 'HOME & KITCHEN'           THEN 'Home & Kitchen'
            WHEN 'OFFICE SUPPLIES'          THEN 'Office Supplies'
            WHEN 'FURNITURE'                THEN 'Furniture'
            WHEN 'TECHNOLOGY ACCESSORIES'   THEN 'Technology Accessories'
            ELSE LTRIM(RTRIM(Category))
        END,
        LTRIM(RTRIM(SubCategory)),
        LTRIM(RTRIM(Brand)),
        CAST(UnitCost AS DECIMAL(10,2)),
        CAST(UnitPrice AS DECIMAL(10,2)),
        CAST(SupplierID AS INT)
    FROM landing.Products
    WHERE ProductID IS NOT NULL
      AND TRY_CAST(UnitCost AS DECIMAL(10,2)) IS NOT NULL
      AND TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NOT NULL;
    
    PRINT 'staging.Products loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 5: staging.usp_Load_Stores
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Stores', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Stores;
GO

CREATE PROCEDURE staging.usp_Load_Stores
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Stores;
    
    INSERT INTO staging.Stores (StoreID, StoreName, City, State, Region, StoreType, OpenDate, SquareFootage)
    SELECT 
        CAST(StoreID AS INT),
        LTRIM(RTRIM(StoreName)),
        LTRIM(RTRIM(City)),
        LTRIM(RTRIM(State)),
        LTRIM(RTRIM(Region)),
        LTRIM(RTRIM(StoreType)),
        CAST(OpenDate AS DATE),
        CAST(SquareFootage AS INT)
    FROM landing.Stores
    WHERE StoreID IS NOT NULL
      AND TRY_CAST(OpenDate AS DATE) IS NOT NULL
      AND TRY_CAST(SquareFootage AS INT) IS NOT NULL;
    
    PRINT 'staging.Stores loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 6: staging.usp_Load_Employees
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Employees', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Employees;
GO

CREATE PROCEDURE staging.usp_Load_Employees
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Employees;
    
    INSERT INTO staging.Employees (EmployeeID, FirstName, LastName, Department, Role, StoreID, HireDate, Salary, ManagerID)
    SELECT 
        CAST(EmployeeID AS INT),
        LTRIM(RTRIM(FirstName)),
        LTRIM(RTRIM(LastName)),
        LTRIM(RTRIM(Department)),
        LTRIM(RTRIM(Role)),
        CAST(StoreID AS INT),
        CAST(HireDate AS DATE),
        CAST(Salary AS INT),
        -- ManagerID arrives as a float-formatted string (e.g. '5.0') because the
        -- source column is nullable. NULLIF maps '' -> NULL (TRY_CAST('' AS FLOAT)
        -- would give 0), then FLOAT->INT turns '5.0' -> 5. NULL = top-level manager.
        TRY_CAST(TRY_CAST(NULLIF(LTRIM(RTRIM(ManagerID)), '') AS FLOAT) AS INT)  -- NULL for top-level managers (valid)
    FROM landing.Employees
    WHERE EmployeeID IS NOT NULL
      AND TRY_CAST(HireDate AS DATE) IS NOT NULL
      AND TRY_CAST(Salary AS INT) IS NOT NULL;
    
    PRINT 'staging.Employees loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 7: staging.usp_Load_Customers
-- Handles DEF-01: NULL emails → flagged with _IsEmailMissing = 1
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Customers', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Customers;
GO

CREATE PROCEDURE staging.usp_Load_Customers
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Customers;
    
    INSERT INTO staging.Customers (CustomerID, FirstName, LastName, Email, Segment, JoinDate, City, State, Region, _IsEmailMissing)
    SELECT 
        CAST(CustomerID AS INT),
        LTRIM(RTRIM(FirstName)),
        LTRIM(RTRIM(LastName)),
        LTRIM(RTRIM(Email)),          -- Keep NULL as NULL
        LTRIM(RTRIM(Segment)),
        CAST(JoinDate AS DATE),
        LTRIM(RTRIM(City)),
        LTRIM(RTRIM(State)),
        LTRIM(RTRIM(Region)),
        -- DEF-01 FLAG: Mark rows where email is missing
        CASE WHEN Email IS NULL OR LTRIM(RTRIM(Email)) = '' THEN 1 ELSE 0 END
    FROM landing.Customers
    WHERE CustomerID IS NOT NULL
      AND TRY_CAST(JoinDate AS DATE) IS NOT NULL;

    -- Capture the INSERT row count FIRST: the SELECT COUNT(*) below is a scalar
    -- assignment that would reset @@ROWCOUNT to 1 before we can print it.
    DECLARE @RowsLoaded INT = @@ROWCOUNT;
    DECLARE @MissingEmails INT = (SELECT COUNT(*) FROM staging.Customers WHERE _IsEmailMissing = 1);
    PRINT 'staging.Customers loaded: ' + CAST(@RowsLoaded AS VARCHAR) + ' rows (' 
          + CAST(@MissingEmails AS VARCHAR) + ' with missing email flagged)';
END;
GO

-- =============================================================================
-- PROCEDURE 8: staging.usp_Load_Orders
-- Handles DEF-02: Duplicate rows → deduplicated via ROW_NUMBER()
-- Handles DEF-03: Future dates → quarantined
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Orders', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Orders;
GO

CREATE PROCEDURE staging.usp_Load_Orders
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Orders;
    
    DECLARE @MaxValidDate DATE = '2025-12-31';
    DECLARE @QuarantinedRows INT = 0;
    
    -- DEF-03: Quarantine rows with future dates
    INSERT INTO staging.Quarantine (SourceTable, SourceRowData, DefectType, DefectDetail)
    SELECT 
        'Orders',
        CONCAT('OrderID=', OrderID, ', CustomerID=', CustomerID, ', OrderDate=', OrderDate),
        'DEF-03',
        'Future date: ' + OrderDate
    FROM landing.Orders
    WHERE TRY_CAST(OrderDate AS DATE) > @MaxValidDate;
    
    SET @QuarantinedRows = @@ROWCOUNT;
    
    -- DEF-02: Deduplicate using ROW_NUMBER (keep first occurrence)
    ;WITH Deduplicated AS (
        SELECT 
            CAST(OrderID AS INT) AS OrderID,
            CAST(CustomerID AS INT) AS CustomerID,
            CAST(OrderDate AS DATE) AS OrderDate,
            -- StoreID/EmployeeID are float-formatted strings ('48.0') because they
            -- are nullable at source (NULL for e-commerce). NULLIF maps the empty
            -- string to NULL (note: TRY_CAST('' AS FLOAT) would give 0, not NULL),
            -- then FLOAT->INT turns '48.0' -> 48. Result: real IDs for store orders,
            -- NULL for e-commerce (the staging contract).
            TRY_CAST(TRY_CAST(NULLIF(LTRIM(RTRIM(StoreID)), '') AS FLOAT) AS INT) AS StoreID,
            TRY_CAST(TRY_CAST(NULLIF(LTRIM(RTRIM(EmployeeID)), '') AS FLOAT) AS INT) AS EmployeeID,
            LTRIM(RTRIM(Channel)) AS Channel,
            LTRIM(RTRIM(Status)) AS Status,
            ROW_NUMBER() OVER (
                PARTITION BY OrderID, CustomerID, OrderDate, Channel
                ORDER BY _LoadedAt
            ) AS rn
        FROM landing.Orders
        WHERE TRY_CAST(OrderDate AS DATE) IS NOT NULL
          AND TRY_CAST(OrderDate AS DATE) <= @MaxValidDate
          AND OrderID IS NOT NULL
    )
    INSERT INTO staging.Orders (OrderID, CustomerID, OrderDate, StoreID, EmployeeID, Channel, Status)
    SELECT OrderID, CustomerID, OrderDate, StoreID, EmployeeID, Channel, Status
    FROM Deduplicated
    WHERE rn = 1;
    
    -- Capture the INSERT row count before the scalar SELECT below resets @@ROWCOUNT.
    DECLARE @RowsLoaded INT = @@ROWCOUNT;
    DECLARE @DuplicatesRemoved INT;
    SET @DuplicatesRemoved = (
        SELECT COUNT(*) - COUNT(DISTINCT CONCAT(OrderID, '-', CustomerID, '-', OrderDate))
        FROM landing.Orders
        WHERE TRY_CAST(OrderDate AS DATE) <= @MaxValidDate
    );
    
    PRINT 'staging.Orders loaded: ' + CAST(@RowsLoaded AS VARCHAR) + ' rows';
    PRINT '  → Duplicates removed (DEF-02): ' + CAST(@DuplicatesRemoved AS VARCHAR);
    PRINT '  → Future dates quarantined (DEF-03): ' + CAST(@QuarantinedRows AS VARCHAR);
END;
GO

-- =============================================================================
-- PROCEDURE 9: staging.usp_Load_OrderDetails
-- Handles DEF-04: Orphan products → flagged
-- Handles DEF-06: Negative quantities → corrected to ABS
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_OrderDetails', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_OrderDetails;
GO

CREATE PROCEDURE staging.usp_Load_OrderDetails
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.OrderDetails;
    
    INSERT INTO staging.OrderDetails (
        OrderDetailID, OrderID, ProductID, Quantity, UnitPrice, 
        Discount, LineTotal, _IsQuantityCorrected, _IsOrphanProduct
    )
    SELECT 
        CAST(od.OrderDetailID AS INT),
        CAST(od.OrderID AS INT),
        CAST(od.ProductID AS INT),
        -- DEF-06 FIX: Convert negative quantities to positive
        CASE 
            WHEN TRY_CAST(od.Quantity AS INT) < 0 THEN ABS(CAST(od.Quantity AS INT))
            ELSE CAST(od.Quantity AS INT)
        END,
        CAST(od.UnitPrice AS DECIMAL(10,2)),
        CAST(od.Discount AS DECIMAL(5,2)),
        ABS(CAST(od.LineTotal AS DECIMAL(12,2))),  -- Ensure positive total
        -- DEF-06 FLAG
        CASE WHEN TRY_CAST(od.Quantity AS INT) < 0 THEN 1 ELSE 0 END,
        -- DEF-04 FLAG: Check if product exists in staging.Products
        CASE WHEN p.ProductID IS NULL THEN 1 ELSE 0 END
    FROM landing.OrderDetails od
    LEFT JOIN staging.Products p ON TRY_CAST(od.ProductID AS INT) = p.ProductID
    WHERE od.OrderDetailID IS NOT NULL
      AND TRY_CAST(od.OrderID AS INT) IS NOT NULL
      AND TRY_CAST(od.UnitPrice AS DECIMAL(10,2)) IS NOT NULL
      AND TRY_CAST(od.Quantity AS INT) IS NOT NULL;
    
    -- Capture the INSERT row count before the scalar SELECTs below reset @@ROWCOUNT.
    DECLARE @RowsLoaded INT = @@ROWCOUNT;
    DECLARE @QtyCorrected INT = (SELECT COUNT(*) FROM staging.OrderDetails WHERE _IsQuantityCorrected = 1);
    DECLARE @OrphanProds INT = (SELECT COUNT(*) FROM staging.OrderDetails WHERE _IsOrphanProduct = 1);
    
    PRINT 'staging.OrderDetails loaded: ' + CAST(@RowsLoaded AS VARCHAR) + ' rows';
    PRINT '  → Negative quantities corrected (DEF-06): ' + CAST(@QtyCorrected AS VARCHAR);
    PRINT '  → Orphan products flagged (DEF-04): ' + CAST(@OrphanProds AS VARCHAR);
END;
GO

-- =============================================================================
-- PROCEDURE 10: staging.usp_Load_Returns
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Returns', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Returns;
GO

CREATE PROCEDURE staging.usp_Load_Returns
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Returns;
    
    INSERT INTO staging.Returns (ReturnID, OrderDetailID, ReturnDate, Reason, RefundAmount, Condition)
    SELECT 
        CAST(ReturnID AS INT),
        CAST(OrderDetailID AS INT),
        CAST(ReturnDate AS DATE),
        LTRIM(RTRIM(Reason)),
        CAST(RefundAmount AS DECIMAL(10,2)),
        LTRIM(RTRIM(Condition))
    FROM landing.Returns
    WHERE ReturnID IS NOT NULL
      AND TRY_CAST(ReturnDate AS DATE) IS NOT NULL
      AND TRY_CAST(RefundAmount AS DECIMAL(10,2)) IS NOT NULL;
    
    PRINT 'staging.Returns loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 11: staging.usp_Load_Shipping
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Shipping', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Shipping;
GO

CREATE PROCEDURE staging.usp_Load_Shipping
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Shipping;
    
    INSERT INTO staging.Shipping (ShippingID, OrderID, ShipDate, DeliveryDate, Carrier, ShipMode, ShippingCost, TrackingNumber)
    SELECT 
        CAST(ShippingID AS INT),
        CAST(OrderID AS INT),
        CAST(ShipDate AS DATE),
        CAST(DeliveryDate AS DATE),
        LTRIM(RTRIM(Carrier)),
        LTRIM(RTRIM(ShipMode)),
        CAST(ShippingCost AS DECIMAL(8,2)),
        LTRIM(RTRIM(TrackingNumber))
    FROM landing.Shipping
    WHERE ShippingID IS NOT NULL
      AND TRY_CAST(ShipDate AS DATE) IS NOT NULL
      AND TRY_CAST(DeliveryDate AS DATE) IS NOT NULL
      AND TRY_CAST(ShippingCost AS DECIMAL(8,2)) IS NOT NULL;
    
    PRINT 'staging.Shipping loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- PROCEDURE 12: staging.usp_Load_Inventory
-- =============================================================================
IF OBJECT_ID('staging.usp_Load_Inventory', 'P') IS NOT NULL DROP PROCEDURE staging.usp_Load_Inventory;
GO

CREATE PROCEDURE staging.usp_Load_Inventory
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE staging.Inventory;
    
    INSERT INTO staging.Inventory (InventoryID, ProductID, StoreID, SnapshotDate, QuantityOnHand, ReorderPoint, ReorderQuantity)
    SELECT 
        CAST(InventoryID AS INT),
        CAST(ProductID AS INT),
        CAST(StoreID AS INT),
        CAST(SnapshotDate AS DATE),
        CAST(QuantityOnHand AS INT),
        CAST(ReorderPoint AS INT),
        CAST(ReorderQuantity AS INT)
    FROM landing.Inventory
    WHERE InventoryID IS NOT NULL
      AND TRY_CAST(SnapshotDate AS DATE) IS NOT NULL
      AND TRY_CAST(QuantityOnHand AS INT) IS NOT NULL;
    
    PRINT 'staging.Inventory loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
END;
GO

-- =============================================================================
-- MASTER PROCEDURE: staging.usp_LoadAll_LandingToStaging
-- Orchestrates all 12 loads in correct dependency order
-- =============================================================================
IF OBJECT_ID('staging.usp_LoadAll_LandingToStaging', 'P') IS NOT NULL DROP PROCEDURE staging.usp_LoadAll_LandingToStaging;
GO

CREATE PROCEDURE staging.usp_LoadAll_LandingToStaging
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    
    PRINT '============================================================';
    PRINT '  ETL: Landing → Staging (Start: ' + CONVERT(VARCHAR, @StartTime, 120) + ')';
    PRINT '============================================================';
    
    -- Reset the Quarantine log so a re-run does not accumulate duplicate
    -- defect rows (each load proc INSERTs into it but never clears it).
    -- Keeps the whole ETL idempotent / safely re-runnable.
    TRUNCATE TABLE staging.Quarantine;
    
    -- Layer 1: Reference/Static dimensions (no dependencies)
    EXEC staging.usp_Load_Regions;
    EXEC staging.usp_Load_Categories;
    EXEC staging.usp_Load_Suppliers;
    
    -- Layer 2: Entity dimensions (depend on Layer 1)
    EXEC staging.usp_Load_Stores;
    EXEC staging.usp_Load_Employees;
    EXEC staging.usp_Load_Products;
    EXEC staging.usp_Load_Customers;
    
    -- Layer 3: Transaction facts (depend on Layer 2)
    EXEC staging.usp_Load_Orders;
    EXEC staging.usp_Load_OrderDetails;
    
    -- Layer 4: Related facts (depend on Layer 3)
    EXEC staging.usp_Load_Returns;
    EXEC staging.usp_Load_Shipping;
    EXEC staging.usp_Load_Inventory;
    
    DECLARE @EndTime DATETIME2 = GETDATE();
    DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, @EndTime);

    DECLARE @QuarantineCount INT;
    SELECT @QuarantineCount = COUNT(*) FROM staging.Quarantine WHERE ResolvedAt IS NULL;

    PRINT '============================================================';
    PRINT '  ETL Complete (Duration: ' + CAST(@Duration AS VARCHAR) + ' seconds)';
    PRINT '  Quarantine rows: ' + CAST(@QuarantineCount AS VARCHAR);
    PRINT '============================================================';
END;
GO

PRINT '============================================================';
PRINT '  ETL Stored Procedures Created — 12 + 1 Master';
PRINT '  Execute: EXEC staging.usp_LoadAll_LandingToStaging';
PRINT '============================================================';
GO
