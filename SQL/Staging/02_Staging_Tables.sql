-- =============================================================================
-- Enterprise Retail Analytics Platform - Staging Layer Tables
-- =============================================================================
-- Script:      02_Staging_Tables.sql
-- Purpose:     Cleaned, validated tables with proper data types and constraints
-- Schema:      [staging]
-- Author:      BI Development Team
-- Created:     2026-07-20
--
-- DESIGN PRINCIPLES:
--   1. Correct SQL data types (INT, DECIMAL, DATE, NVARCHAR)
--   2. NOT NULL on required business fields
--   3. CHECK constraints for business rule validation
--   4. Primary Keys on all tables (for deduplication guarantee)
--   5. Audit columns: _LoadedAt, _IsValid, _ValidationNote
--
-- WHAT HAPPENS BETWEEN LANDING → STAGING:
--   - Data type casting (VARCHAR → INT, DECIMAL, DATE)
--   - NULL handling (DEF-01: missing emails flagged)
--   - Deduplication (DEF-02: duplicate orders removed)
--   - Date validation (DEF-03: future dates quarantined)
--   - Referential check (DEF-04: orphan products flagged)
--   - Standardization (DEF-05: category casing normalized)
--   - Business rules (DEF-06: negative quantities corrected)
--
-- EXECUTION: Run in SSMS after 01_Landing_Tables.sql
-- =============================================================================

USE RetailDW;
GO

-- ---------------------------------------------------------------------------
-- Table 1: staging.Regions
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Regions', 'U') IS NOT NULL DROP TABLE staging.Regions;
GO

CREATE TABLE staging.Regions (
    RegionID        INT             NOT NULL PRIMARY KEY,
    RegionName      VARCHAR(50)     NOT NULL,
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Regions';
GO

-- ---------------------------------------------------------------------------
-- Table 2: staging.Categories
-- Note: CategoryName standardized to proper Title Case
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Categories', 'U') IS NOT NULL DROP TABLE staging.Categories;
GO

CREATE TABLE staging.Categories (
    CategoryID      INT             NOT NULL PRIMARY KEY,
    CategoryName    NVARCHAR(100)   NOT NULL,
    SubCategoryName NVARCHAR(100)   NOT NULL,
    Department      VARCHAR(50)     NOT NULL DEFAULT 'Retail',
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Categories';
GO

-- ---------------------------------------------------------------------------
-- Table 3: staging.Suppliers
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Suppliers', 'U') IS NOT NULL DROP TABLE staging.Suppliers;
GO

CREATE TABLE staging.Suppliers (
    SupplierID      INT             NOT NULL PRIMARY KEY,
    SupplierName    NVARCHAR(200)   NOT NULL,
    Country         VARCHAR(50)     NOT NULL,
    LeadTimeDays    INT             NOT NULL CHECK (LeadTimeDays >= 0),
    Rating          DECIMAL(3,1)    NOT NULL CHECK (Rating BETWEEN 0.0 AND 5.0),
    ContactEmail    NVARCHAR(200)   NULL,
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Suppliers';
GO

-- ---------------------------------------------------------------------------
-- Table 4: staging.Products
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Products', 'U') IS NOT NULL DROP TABLE staging.Products;
GO

CREATE TABLE staging.Products (
    ProductID       INT             NOT NULL PRIMARY KEY,
    ProductName     NVARCHAR(200)   NOT NULL,
    CategoryID      INT             NOT NULL,
    Category        NVARCHAR(100)   NOT NULL,
    SubCategory     NVARCHAR(100)   NOT NULL,
    Brand           NVARCHAR(100)   NULL,
    UnitCost        DECIMAL(10,2)   NOT NULL CHECK (UnitCost >= 0),
    UnitPrice       DECIMAL(10,2)   NOT NULL CHECK (UnitPrice >= 0),
    SupplierID      INT             NOT NULL,
    GrossMargin     AS (UnitPrice - UnitCost) PERSISTED,
    MarginPercent   AS (CASE WHEN UnitPrice > 0 
                        THEN ROUND((UnitPrice - UnitCost) / UnitPrice * 100, 2) 
                        ELSE 0 END) PERSISTED,
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Products (with computed margin columns)';
GO

-- ---------------------------------------------------------------------------
-- Table 5: staging.Stores
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Stores', 'U') IS NOT NULL DROP TABLE staging.Stores;
GO

CREATE TABLE staging.Stores (
    StoreID         INT             NOT NULL PRIMARY KEY,
    StoreName       NVARCHAR(100)   NOT NULL,
    City            NVARCHAR(100)   NOT NULL,
    State           NVARCHAR(50)    NOT NULL,
    Region          VARCHAR(50)     NOT NULL,
    StoreType       VARCHAR(50)     NOT NULL,
    OpenDate        DATE            NOT NULL,
    SquareFootage   INT             NOT NULL CHECK (SquareFootage > 0),
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Stores';
GO

-- ---------------------------------------------------------------------------
-- Table 6: staging.Employees
-- Note: ManagerID NULL is valid for top-level managers
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Employees', 'U') IS NOT NULL DROP TABLE staging.Employees;
GO

CREATE TABLE staging.Employees (
    EmployeeID      INT             NOT NULL PRIMARY KEY,
    FirstName       NVARCHAR(100)   NOT NULL,
    LastName        NVARCHAR(100)   NOT NULL,
    FullName        AS (FirstName + ' ' + LastName) PERSISTED,
    Department      VARCHAR(50)     NOT NULL,
    Role            VARCHAR(100)    NOT NULL,
    StoreID         INT             NOT NULL,
    HireDate        DATE            NOT NULL,
    Salary          INT             NOT NULL CHECK (Salary > 0),
    ManagerID       INT             NULL,  -- NULL = top-level (valid, not defect)
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Employees (with computed FullName)';
GO

-- ---------------------------------------------------------------------------
-- Table 7: staging.Customers
-- Note: Email may be NULL (DEF-01) — flagged with _IsEmailMissing
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Customers', 'U') IS NOT NULL DROP TABLE staging.Customers;
GO

CREATE TABLE staging.Customers (
    CustomerID      INT             NOT NULL PRIMARY KEY,
    FirstName       NVARCHAR(100)   NOT NULL,
    LastName        NVARCHAR(100)   NOT NULL,
    FullName        AS (FirstName + ' ' + LastName) PERSISTED,
    Email           NVARCHAR(200)   NULL,
    Segment         VARCHAR(50)     NOT NULL,
    JoinDate        DATE            NOT NULL,
    City            NVARCHAR(100)   NOT NULL,
    State           NVARCHAR(50)    NOT NULL,
    Region          VARCHAR(50)     NOT NULL,
    _IsEmailMissing BIT             DEFAULT 0,  -- Flag for DEF-01
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Customers (with email missing flag)';
GO

-- ---------------------------------------------------------------------------
-- Table 8: staging.Orders
-- Note: Duplicates removed (DEF-02), future dates excluded (DEF-03)
-- Note: StoreID/EmployeeID NULL for E-commerce (valid business rule)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Orders', 'U') IS NOT NULL DROP TABLE staging.Orders;
GO

CREATE TABLE staging.Orders (
    OrderID         INT             NOT NULL PRIMARY KEY,
    CustomerID      INT             NOT NULL,
    OrderDate       DATE            NOT NULL,
    StoreID         INT             NULL,      -- NULL = E-commerce order
    EmployeeID      INT             NULL,      -- NULL = E-commerce order
    Channel         VARCHAR(20)     NOT NULL CHECK (Channel IN ('Store', 'E-commerce')),
    Status          VARCHAR(20)     NOT NULL CHECK (Status IN ('Completed', 'Shipped', 'Processing', 'Cancelled')),
    OrderYear       AS (YEAR(OrderDate)) PERSISTED,
    OrderMonth      AS (MONTH(OrderDate)) PERSISTED,
    OrderQuarter    AS (DATEPART(QUARTER, OrderDate)) PERSISTED,
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Orders (deduplicated, with computed date parts)';
GO

-- ---------------------------------------------------------------------------
-- Table 9: staging.OrderDetails
-- Note: Orphan ProductIDs flagged (DEF-04), negative quantities corrected (DEF-06)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.OrderDetails', 'U') IS NOT NULL DROP TABLE staging.OrderDetails;
GO

CREATE TABLE staging.OrderDetails (
    OrderDetailID   INT             NOT NULL PRIMARY KEY,
    OrderID         INT             NOT NULL,
    ProductID       INT             NOT NULL,
    Quantity        INT             NOT NULL CHECK (Quantity > 0),  -- Negatives corrected
    UnitPrice       DECIMAL(10,2)   NOT NULL CHECK (UnitPrice >= 0),
    Discount        DECIMAL(5,2)    NOT NULL CHECK (Discount BETWEEN 0 AND 1),
    LineTotal       DECIMAL(12,2)   NOT NULL,
    _IsQuantityCorrected BIT        DEFAULT 0,  -- Flag for DEF-06
    _IsOrphanProduct     BIT        DEFAULT 0,  -- Flag for DEF-04
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.OrderDetails (with correction flags)';
GO

-- ---------------------------------------------------------------------------
-- Table 10: staging.Returns
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Returns', 'U') IS NOT NULL DROP TABLE staging.Returns;
GO

CREATE TABLE staging.Returns (
    ReturnID        INT             NOT NULL PRIMARY KEY,
    OrderDetailID   INT             NOT NULL,
    ReturnDate      DATE            NOT NULL,
    Reason          NVARCHAR(100)   NOT NULL,
    RefundAmount    DECIMAL(10,2)   NOT NULL CHECK (RefundAmount >= 0),
    Condition       VARCHAR(50)     NOT NULL,
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Returns';
GO

-- ---------------------------------------------------------------------------
-- Table 11: staging.Shipping
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Shipping', 'U') IS NOT NULL DROP TABLE staging.Shipping;
GO

CREATE TABLE staging.Shipping (
    ShippingID      INT             NOT NULL PRIMARY KEY,
    OrderID         INT             NOT NULL,
    ShipDate        DATE            NOT NULL,
    DeliveryDate    DATE            NOT NULL,
    Carrier         VARCHAR(50)     NOT NULL,
    ShipMode        VARCHAR(50)     NOT NULL,
    ShippingCost    DECIMAL(8,2)    NOT NULL CHECK (ShippingCost >= 0),
    TrackingNumber  VARCHAR(50)     NOT NULL,
    TransitDays     AS (DATEDIFF(DAY, ShipDate, DeliveryDate)) PERSISTED,
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Shipping (with computed TransitDays)';
GO

-- ---------------------------------------------------------------------------
-- Table 12: staging.Inventory
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Inventory', 'U') IS NOT NULL DROP TABLE staging.Inventory;
GO

CREATE TABLE staging.Inventory (
    InventoryID     INT             NOT NULL PRIMARY KEY,
    ProductID       INT             NOT NULL,
    StoreID         INT             NOT NULL,
    SnapshotDate    DATE            NOT NULL,
    QuantityOnHand  INT             NOT NULL CHECK (QuantityOnHand >= 0),
    ReorderPoint    INT             NOT NULL CHECK (ReorderPoint >= 0),
    ReorderQuantity INT             NOT NULL CHECK (ReorderQuantity >= 0),
    IsLowStock      AS (CASE WHEN QuantityOnHand <= ReorderPoint THEN 1 ELSE 0 END) PERSISTED,
    IsOutOfStock    AS (CASE WHEN QuantityOnHand = 0 THEN 1 ELSE 0 END) PERSISTED,
    _LoadedAt       DATETIME2       DEFAULT GETDATE(),
    _IsValid        BIT             DEFAULT 1
);
GO

PRINT 'Created: staging.Inventory (with computed stock flags)';
GO

-- ---------------------------------------------------------------------------
-- Quarantine Table: staging.Quarantine
-- Purpose: Rows that fail validation go here for review
-- ---------------------------------------------------------------------------
IF OBJECT_ID('staging.Quarantine', 'U') IS NOT NULL DROP TABLE staging.Quarantine;
GO

CREATE TABLE staging.Quarantine (
    QuarantineID    INT             IDENTITY(1,1) PRIMARY KEY,
    SourceTable     VARCHAR(50)     NOT NULL,
    SourceRowData   NVARCHAR(MAX)   NOT NULL,  -- JSON of the offending row
    DefectType      VARCHAR(50)     NOT NULL,  -- e.g., 'DEF-03', 'DEF-04'
    DefectDetail    NVARCHAR(500)   NULL,
    QuarantinedAt   DATETIME2       DEFAULT GETDATE(),
    ResolvedAt      DATETIME2       NULL,
    ResolvedBy      VARCHAR(100)    NULL,
    Resolution      VARCHAR(50)     NULL       -- 'Fixed', 'Deleted', 'Accepted'
);
GO

PRINT 'Created: staging.Quarantine (error capture table)';
GO

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------
PRINT '============================================================';
PRINT '  Staging Layer Complete — 12 Tables + 1 Quarantine Table';
PRINT '  Schema: [staging]';
PRINT '  Design: Proper data types, PKs, CHECK constraints';
PRINT '  Computed: GrossMargin, FullName, TransitDays, StockFlags';
PRINT '  Audit: _LoadedAt, _IsValid, defect flag columns';
PRINT '============================================================';
GO
