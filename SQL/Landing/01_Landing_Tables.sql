-- =============================================================================
-- Enterprise Retail Analytics Platform - Landing Layer Tables
-- =============================================================================
-- Script:      01_Landing_Tables.sql
-- Purpose:     Create raw ingestion tables that mirror CSV file structure exactly
-- Schema:      [landing]
-- Author:      BI Development Team
-- Created:     2026-07-20
--
-- DESIGN PRINCIPLES:
--   1. ALL columns are VARCHAR/NVARCHAR — no data type validation at this layer
--   2. NO constraints (no PK, FK, NOT NULL) — accept everything from source
--   3. Every table has _LoadedAt metadata column (audit trail)
--   4. Table names match CSV file names (minus extension)
--   5. Column names match CSV headers exactly
--
-- WHY ALL VARCHAR?
--   - Source CSVs may have dirty data (text in numeric fields, bad dates)
--   - Landing layer should NEVER reject a row — capture everything
--   - Data type validation happens in Staging layer
--   - This is standard enterprise ETL practice (ELT pattern)
--
-- EXECUTION: Run in SSMS after 00_Create_Database.sql
-- =============================================================================

USE RetailDW;
GO

-- ---------------------------------------------------------------------------
-- Table 1: landing.Regions
-- Source: Dataset/regions.csv (4 rows)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Regions', 'U') IS NOT NULL DROP TABLE landing.Regions;
GO

CREATE TABLE landing.Regions (
    RegionID        VARCHAR(10),
    RegionName      VARCHAR(50),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'regions.csv'
);
GO

PRINT 'Created: landing.Regions';
GO

-- ---------------------------------------------------------------------------
-- Table 2: landing.Categories
-- Source: Dataset/categories.csv (25-50 rows)
-- Note: CategoryName may have inconsistent casing (DEF-05)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Categories', 'U') IS NOT NULL DROP TABLE landing.Categories;
GO

CREATE TABLE landing.Categories (
    CategoryID      VARCHAR(10),
    CategoryName    NVARCHAR(100),
    SubCategoryName NVARCHAR(100),
    Department      VARCHAR(50),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'categories.csv'
);
GO

PRINT 'Created: landing.Categories';
GO

-- ---------------------------------------------------------------------------
-- Table 3: landing.Suppliers
-- Source: Dataset/suppliers.csv (100-500 rows)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Suppliers', 'U') IS NOT NULL DROP TABLE landing.Suppliers;
GO

CREATE TABLE landing.Suppliers (
    SupplierID      VARCHAR(10),
    SupplierName    NVARCHAR(200),
    Country         VARCHAR(50),
    LeadTimeDays    VARCHAR(10),
    Rating          VARCHAR(10),
    ContactEmail    NVARCHAR(200),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'suppliers.csv'
);
GO

PRINT 'Created: landing.Suppliers';
GO

-- ---------------------------------------------------------------------------
-- Table 4: landing.Products
-- Source: Dataset/products.csv (2,000-10,000 rows)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Products', 'U') IS NOT NULL DROP TABLE landing.Products;
GO

CREATE TABLE landing.Products (
    ProductID       VARCHAR(10),
    ProductName     NVARCHAR(200),
    CategoryID      VARCHAR(10),
    Category        NVARCHAR(100),
    SubCategory     NVARCHAR(100),
    Brand           NVARCHAR(100),
    UnitCost        VARCHAR(20),
    UnitPrice       VARCHAR(20),
    SupplierID      VARCHAR(10),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'products.csv'
);
GO

PRINT 'Created: landing.Products';
GO

-- ---------------------------------------------------------------------------
-- Table 5: landing.Stores
-- Source: Dataset/stores.csv (50-120 rows)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Stores', 'U') IS NOT NULL DROP TABLE landing.Stores;
GO

CREATE TABLE landing.Stores (
    StoreID         VARCHAR(10),
    StoreName       NVARCHAR(100),
    City            NVARCHAR(100),
    State           NVARCHAR(50),
    Region          VARCHAR(50),
    StoreType       VARCHAR(50),
    OpenDate        VARCHAR(20),
    SquareFootage   VARCHAR(10),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'stores.csv'
);
GO

PRINT 'Created: landing.Stores';
GO

-- ---------------------------------------------------------------------------
-- Table 6: landing.Employees
-- Source: Dataset/employees.csv (1,000-5,000 rows)
-- Note: ManagerID is NULL for top-level managers (DEF-07 — valid)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Employees', 'U') IS NOT NULL DROP TABLE landing.Employees;
GO

CREATE TABLE landing.Employees (
    EmployeeID      VARCHAR(10),
    FirstName       NVARCHAR(100),
    LastName        NVARCHAR(100),
    Department      VARCHAR(50),
    Role            VARCHAR(100),
    StoreID         VARCHAR(10),
    HireDate        VARCHAR(20),
    Salary          VARCHAR(20),
    ManagerID       VARCHAR(10),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'employees.csv'
);
GO

PRINT 'Created: landing.Employees';
GO

-- ---------------------------------------------------------------------------
-- Table 7: landing.Customers
-- Source: Dataset/customers.csv (20,000-200,000 rows)
-- Note: Email is NULL for ~5% of rows (DEF-01)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Customers', 'U') IS NOT NULL DROP TABLE landing.Customers;
GO

CREATE TABLE landing.Customers (
    CustomerID      VARCHAR(10),
    FirstName       NVARCHAR(100),
    LastName        NVARCHAR(100),
    Email           NVARCHAR(200),
    Segment         VARCHAR(50),
    JoinDate        VARCHAR(20),
    City            NVARCHAR(100),
    State           NVARCHAR(50),
    Region          VARCHAR(50),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'customers.csv'
);
GO

PRINT 'Created: landing.Customers';
GO

-- ---------------------------------------------------------------------------
-- Table 8: landing.Orders
-- Source: Dataset/orders.csv (50,000-500,000 rows)
-- Note: Contains ~0.5% duplicate rows (DEF-02)
-- Note: Contains ~0.1% future dates (DEF-03)
-- Note: StoreID/EmployeeID are NULL for E-commerce orders (valid)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Orders', 'U') IS NOT NULL DROP TABLE landing.Orders;
GO

CREATE TABLE landing.Orders (
    OrderID         VARCHAR(10),
    CustomerID      VARCHAR(10),
    OrderDate       VARCHAR(20),
    StoreID         VARCHAR(10),
    EmployeeID      VARCHAR(10),
    Channel         VARCHAR(20),
    Status          VARCHAR(20),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'orders.csv'
);
GO

PRINT 'Created: landing.Orders';
GO

-- ---------------------------------------------------------------------------
-- Table 9: landing.OrderDetails
-- Source: Dataset/order_details.csv (200,000-2,000,000 rows)
-- Note: ~0.2% orphan ProductID references (DEF-04)
-- Note: ~0.1% negative quantities (DEF-06)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.OrderDetails', 'U') IS NOT NULL DROP TABLE landing.OrderDetails;
GO

CREATE TABLE landing.OrderDetails (
    OrderDetailID   VARCHAR(10),
    OrderID         VARCHAR(10),
    ProductID       VARCHAR(10),
    Quantity        VARCHAR(10),
    UnitPrice       VARCHAR(20),
    Discount        VARCHAR(10),
    LineTotal       VARCHAR(20),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'order_details.csv'
);
GO

PRINT 'Created: landing.OrderDetails';
GO

-- ---------------------------------------------------------------------------
-- Table 10: landing.Returns
-- Source: Dataset/returns.csv (8,500-85,000 rows)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Returns', 'U') IS NOT NULL DROP TABLE landing.Returns;
GO

CREATE TABLE landing.Returns (
    ReturnID        VARCHAR(10),
    OrderDetailID   VARCHAR(10),
    ReturnDate      VARCHAR(20),
    Reason          NVARCHAR(100),
    RefundAmount    VARCHAR(20),
    Condition       VARCHAR(50),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'returns.csv'
);
GO

PRINT 'Created: landing.Returns';
GO

-- ---------------------------------------------------------------------------
-- Table 11: landing.Shipping
-- Source: Dataset/shipping.csv (22,000-220,000 rows)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Shipping', 'U') IS NOT NULL DROP TABLE landing.Shipping;
GO

CREATE TABLE landing.Shipping (
    ShippingID      VARCHAR(10),
    OrderID         VARCHAR(10),
    ShipDate        VARCHAR(20),
    DeliveryDate    VARCHAR(20),
    Carrier         VARCHAR(50),
    ShipMode        VARCHAR(50),
    ShippingCost    VARCHAR(20),
    TrackingNumber  VARCHAR(50),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'shipping.csv'
);
GO

PRINT 'Created: landing.Shipping';
GO

-- ---------------------------------------------------------------------------
-- Table 12: landing.Inventory
-- Source: Dataset/inventory.csv (400,000-4,000,000 rows)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('landing.Inventory', 'U') IS NOT NULL DROP TABLE landing.Inventory;
GO

CREATE TABLE landing.Inventory (
    InventoryID     VARCHAR(10),
    ProductID       VARCHAR(10),
    StoreID         VARCHAR(10),
    SnapshotDate    VARCHAR(20),
    QuantityOnHand  VARCHAR(10),
    ReorderPoint    VARCHAR(10),
    ReorderQuantity VARCHAR(10),
    _LoadedAt       DATETIME2 DEFAULT GETDATE(),
    _SourceFile     VARCHAR(255) DEFAULT 'inventory.csv'
);
GO

PRINT 'Created: landing.Inventory';
GO

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------
PRINT '============================================================';
PRINT '  Landing Layer Complete — 12 Tables Created';
PRINT '  Schema: [landing]';
PRINT '  Design: All VARCHAR, no constraints, metadata columns';
PRINT '============================================================';
GO
