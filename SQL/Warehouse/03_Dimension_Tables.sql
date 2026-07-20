-- =============================================================================
-- Enterprise Retail Analytics Platform - Warehouse Layer: Dimension Tables
-- =============================================================================
-- Script:      03_Dimension_Tables.sql
-- Purpose:     Star Schema dimension tables (Kimball methodology)
-- Schema:      [warehouse]
-- Author:      BI Development Team
-- Created:     2026-07-20
--
-- STAR SCHEMA DESIGN:
--
--                        ┌──────────┐
--                        │ DimDate  │
--                        └────┬─────┘
--                             │
--   ┌──────────┐    ┌────────┴────────┐    ┌───────────┐
--   │DimProduct│────│   FactSales     │────│DimCustomer│
--   └──────────┘    └────────┬────────┘    └───────────┘
--                             │
--                   ┌─────────┼─────────┐
--                   │         │         │
--              ┌────┴───┐ ┌───┴────┐ ┌──┴────────┐
--              │DimStore│ │DimEmpl.│ │DimSupplier│
--              └────────┘ └────────┘ └───────────┘
--
-- DIMENSION TYPES:
--   - DimDate: Role-playing dimension (conformed, generated not from source)
--   - DimCustomer: Type 1 SCD (overwrite on change)
--   - DimProduct: Type 1 SCD with junk attributes
--   - DimStore: Type 1 SCD
--   - DimEmployee: Type 1 SCD
--   - DimSupplier: Type 1 SCD
--   - DimRegion: Static reference
--   - DimCategory: Static reference
--
-- SURROGATE KEYS:
--   All dimensions use surrogate keys (SK) as primary key.
--   Natural/business keys are stored separately for ETL lookups.
--   SK = -1 reserved for "Unknown" member (handles orphan FKs).
--
-- EXECUTION: Run in SSMS after 02_Staging_Tables.sql
-- =============================================================================

USE RetailDW;
GO

-- ---------------------------------------------------------------------------
-- Dimension 1: warehouse.DimDate (Role-Playing Date Dimension)
-- Generated independently — NOT from source CSV
-- Grain: One row per calendar day (2020-01-01 to 2026-12-31)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.DimDate', 'U') IS NOT NULL DROP TABLE warehouse.DimDate;
GO

CREATE TABLE warehouse.DimDate (
    DateKey             INT             NOT NULL PRIMARY KEY,  -- YYYYMMDD format
    FullDate            DATE            NOT NULL,
    DayOfWeek           TINYINT         NOT NULL,  -- 1=Sun, 7=Sat
    DayName             VARCHAR(10)     NOT NULL,
    DayOfMonth          TINYINT         NOT NULL,
    DayOfYear           SMALLINT        NOT NULL,
    WeekOfYear          TINYINT         NOT NULL,
    MonthNumber         TINYINT         NOT NULL,
    MonthName           VARCHAR(10)     NOT NULL,
    MonthShort          CHAR(3)         NOT NULL,  -- Jan, Feb, etc.
    Quarter             TINYINT         NOT NULL,
    QuarterName         CHAR(2)         NOT NULL,  -- Q1, Q2, Q3, Q4
    Year                SMALLINT        NOT NULL,
    YearMonth           CHAR(7)         NOT NULL,  -- 2023-01
    YearQuarter         CHAR(7)         NOT NULL,  -- 2023-Q1
    IsWeekend           BIT             NOT NULL,
    IsWeekday           BIT             NOT NULL,
    -- Fiscal Year (Jul-Jun for retail)
    FiscalYear          SMALLINT        NOT NULL,
    FiscalQuarter       TINYINT         NOT NULL,
    FiscalMonth         TINYINT         NOT NULL,
    -- Relative flags (useful for DAX filtering)
    IsCurrentMonth      BIT             DEFAULT 0,
    IsCurrentQuarter    BIT             DEFAULT 0,
    IsCurrentYear       BIT             DEFAULT 0,
    -- Holiday flag (simplified)
    IsHoliday           BIT             DEFAULT 0,
    HolidayName         VARCHAR(50)     NULL
);
GO

PRINT 'Created: warehouse.DimDate (role-playing calendar dimension)';
GO

-- ---------------------------------------------------------------------------
-- Dimension 2: warehouse.DimRegion
-- Grain: One row per region (4 rows)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.DimRegion', 'U') IS NOT NULL DROP TABLE warehouse.DimRegion;
GO

CREATE TABLE warehouse.DimRegion (
    RegionSK            INT             IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RegionID            INT             NOT NULL,  -- Business/Natural key
    RegionName          VARCHAR(50)     NOT NULL,
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

-- Insert Unknown member for orphan FK handling
SET IDENTITY_INSERT warehouse.DimRegion ON;
INSERT INTO warehouse.DimRegion (RegionSK, RegionID, RegionName, _LoadedAt)
VALUES (-1, -1, 'Unknown', GETDATE());
SET IDENTITY_INSERT warehouse.DimRegion OFF;
GO

PRINT 'Created: warehouse.DimRegion (with Unknown member)';
GO

-- ---------------------------------------------------------------------------
-- Dimension 3: warehouse.DimCategory
-- Grain: One row per sub-category
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.DimCategory', 'U') IS NOT NULL DROP TABLE warehouse.DimCategory;
GO

CREATE TABLE warehouse.DimCategory (
    CategorySK          INT             IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CategoryID          INT             NOT NULL,  -- Business key
    CategoryName        NVARCHAR(100)   NOT NULL,
    SubCategoryName     NVARCHAR(100)   NOT NULL,
    Department          VARCHAR(50)     NOT NULL,
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

SET IDENTITY_INSERT warehouse.DimCategory ON;
INSERT INTO warehouse.DimCategory (CategorySK, CategoryID, CategoryName, SubCategoryName, Department, _LoadedAt)
VALUES (-1, -1, 'Unknown', 'Unknown', 'Unknown', GETDATE());
SET IDENTITY_INSERT warehouse.DimCategory OFF;
GO

PRINT 'Created: warehouse.DimCategory (with Unknown member)';
GO

-- ---------------------------------------------------------------------------
-- Dimension 4: warehouse.DimSupplier
-- Grain: One row per supplier
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.DimSupplier', 'U') IS NOT NULL DROP TABLE warehouse.DimSupplier;
GO

CREATE TABLE warehouse.DimSupplier (
    SupplierSK          INT             IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SupplierID          INT             NOT NULL,  -- Business key
    SupplierName        NVARCHAR(200)   NOT NULL,
    Country             VARCHAR(50)     NOT NULL,
    LeadTimeDays        INT             NOT NULL,
    Rating              DECIMAL(3,1)    NOT NULL,
    ContactEmail        NVARCHAR(200)   NULL,
    -- Derived attributes
    LeadTimeCategory    AS (CASE 
                            WHEN LeadTimeDays <= 7 THEN 'Fast (1-7 days)'
                            WHEN LeadTimeDays <= 21 THEN 'Standard (8-21 days)'
                            ELSE 'Slow (22+ days)'
                        END) PERSISTED,
    RatingCategory      AS (CASE
                            WHEN Rating >= 4.5 THEN 'Excellent'
                            WHEN Rating >= 3.5 THEN 'Good'
                            WHEN Rating >= 2.5 THEN 'Average'
                            ELSE 'Poor'
                        END) PERSISTED,
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

SET IDENTITY_INSERT warehouse.DimSupplier ON;
INSERT INTO warehouse.DimSupplier (SupplierSK, SupplierID, SupplierName, Country, LeadTimeDays, Rating, _LoadedAt)
VALUES (-1, -1, 'Unknown', 'Unknown', 0, 0.0, GETDATE());
SET IDENTITY_INSERT warehouse.DimSupplier OFF;
GO

PRINT 'Created: warehouse.DimSupplier (with derived categories)';
GO

-- ---------------------------------------------------------------------------
-- Dimension 5: warehouse.DimStore
-- Grain: One row per store
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.DimStore', 'U') IS NOT NULL DROP TABLE warehouse.DimStore;
GO

CREATE TABLE warehouse.DimStore (
    StoreSK             INT             IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StoreID             INT             NOT NULL,  -- Business key
    StoreName           NVARCHAR(100)   NOT NULL,
    City                NVARCHAR(100)   NOT NULL,
    State               NVARCHAR(50)    NOT NULL,
    Region              VARCHAR(50)     NOT NULL,
    StoreType           VARCHAR(50)     NOT NULL,
    OpenDate            DATE            NOT NULL,
    SquareFootage       INT             NOT NULL,
    -- Derived attributes
    StoreSize           AS (CASE
                            WHEN SquareFootage >= 40000 THEN 'Large'
                            WHEN SquareFootage >= 20000 THEN 'Medium'
                            ELSE 'Small'
                        END) PERSISTED,
    YearsOpen           AS (DATEDIFF(YEAR, OpenDate, GETDATE())) PERSISTED,
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

SET IDENTITY_INSERT warehouse.DimStore ON;
INSERT INTO warehouse.DimStore (StoreSK, StoreID, StoreName, City, State, Region, StoreType, OpenDate, SquareFootage, _LoadedAt)
VALUES (-1, -1, 'Unknown/Online', 'N/A', 'N/A', 'N/A', 'N/A', '1900-01-01', 0, GETDATE());
SET IDENTITY_INSERT warehouse.DimStore OFF;
GO

PRINT 'Created: warehouse.DimStore (with derived size/age)';
GO

-- ---------------------------------------------------------------------------
-- Dimension 6: warehouse.DimEmployee
-- Grain: One row per employee
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.DimEmployee', 'U') IS NOT NULL DROP TABLE warehouse.DimEmployee;
GO

CREATE TABLE warehouse.DimEmployee (
    EmployeeSK          INT             IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EmployeeID          INT             NOT NULL,  -- Business key
    FirstName           NVARCHAR(100)   NOT NULL,
    LastName            NVARCHAR(100)   NOT NULL,
    FullName            NVARCHAR(201)   NOT NULL,
    Department          VARCHAR(50)     NOT NULL,
    Role                VARCHAR(100)    NOT NULL,
    StoreID             INT             NOT NULL,
    HireDate            DATE            NOT NULL,
    Salary              INT             NOT NULL,
    ManagerID           INT             NULL,
    -- Derived attributes
    TenureYears         AS (DATEDIFF(YEAR, HireDate, GETDATE())) PERSISTED,
    SalaryBand          AS (CASE
                            WHEN Salary >= 100000 THEN 'Senior ($100K+)'
                            WHEN Salary >= 60000 THEN 'Mid ($60-100K)'
                            ELSE 'Entry (< $60K)'
                        END) PERSISTED,
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

SET IDENTITY_INSERT warehouse.DimEmployee ON;
INSERT INTO warehouse.DimEmployee (EmployeeSK, EmployeeID, FirstName, LastName, FullName, Department, Role, StoreID, HireDate, Salary, _LoadedAt)
VALUES (-1, -1, 'Unknown', 'Unknown', 'Unknown', 'N/A', 'N/A', -1, '1900-01-01', 0, GETDATE());
SET IDENTITY_INSERT warehouse.DimEmployee OFF;
GO

PRINT 'Created: warehouse.DimEmployee (with tenure/salary bands)';
GO

-- ---------------------------------------------------------------------------
-- Dimension 7: warehouse.DimCustomer
-- Grain: One row per customer
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.DimCustomer', 'U') IS NOT NULL DROP TABLE warehouse.DimCustomer;
GO

CREATE TABLE warehouse.DimCustomer (
    CustomerSK          INT             IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID          INT             NOT NULL,  -- Business key
    FirstName           NVARCHAR(100)   NOT NULL,
    LastName            NVARCHAR(100)   NOT NULL,
    FullName            NVARCHAR(201)   NOT NULL,
    Email               NVARCHAR(200)   NULL,
    Segment             VARCHAR(50)     NOT NULL,
    JoinDate            DATE            NOT NULL,
    City                NVARCHAR(100)   NOT NULL,
    State               NVARCHAR(50)    NOT NULL,
    Region              VARCHAR(50)     NOT NULL,
    -- Derived attributes
    CustomerTenureYears AS (DATEDIFF(YEAR, JoinDate, GETDATE())) PERSISTED,
    JoinYear            AS (YEAR(JoinDate)) PERSISTED,
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

SET IDENTITY_INSERT warehouse.DimCustomer ON;
INSERT INTO warehouse.DimCustomer (CustomerSK, CustomerID, FirstName, LastName, FullName, Email, Segment, JoinDate, City, State, Region, _LoadedAt)
VALUES (-1, -1, 'Unknown', 'Unknown', 'Unknown', NULL, 'Unknown', '1900-01-01', 'N/A', 'N/A', 'N/A', GETDATE());
SET IDENTITY_INSERT warehouse.DimCustomer OFF;
GO

PRINT 'Created: warehouse.DimCustomer (with tenure/join year)';
GO

-- ---------------------------------------------------------------------------
-- Dimension 8: warehouse.DimProduct
-- Grain: One row per product
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.DimProduct', 'U') IS NOT NULL DROP TABLE warehouse.DimProduct;
GO

CREATE TABLE warehouse.DimProduct (
    ProductSK           INT             IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID           INT             NOT NULL,  -- Business key
    ProductName         NVARCHAR(200)   NOT NULL,
    CategoryID          INT             NOT NULL,
    CategoryName        NVARCHAR(100)   NOT NULL,
    SubCategoryName     NVARCHAR(100)   NOT NULL,
    Brand               NVARCHAR(100)   NULL,
    UnitCost            DECIMAL(10,2)   NOT NULL,
    UnitPrice           DECIMAL(10,2)   NOT NULL,
    SupplierID          INT             NOT NULL,
    -- Derived attributes
    GrossMargin         AS (UnitPrice - UnitCost) PERSISTED,
    MarginPercent       AS (CASE WHEN UnitPrice > 0 
                            THEN ROUND((UnitPrice - UnitCost) / UnitPrice * 100, 2) 
                            ELSE 0 END) PERSISTED,
    PriceRange          AS (CASE
                            WHEN UnitPrice >= 500 THEN 'Premium ($500+)'
                            WHEN UnitPrice >= 100 THEN 'Mid-Range ($100-499)'
                            WHEN UnitPrice >= 25 THEN 'Value ($25-99)'
                            ELSE 'Budget (< $25)'
                        END) PERSISTED,
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

SET IDENTITY_INSERT warehouse.DimProduct ON;
INSERT INTO warehouse.DimProduct (ProductSK, ProductID, ProductName, CategoryID, CategoryName, SubCategoryName, UnitCost, UnitPrice, SupplierID, _LoadedAt)
VALUES (-1, -1, 'Unknown Product', -1, 'Unknown', 'Unknown', 0, 0, -1, GETDATE());
SET IDENTITY_INSERT warehouse.DimProduct OFF;
GO

PRINT 'Created: warehouse.DimProduct (with margin/price range)';
GO

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------
PRINT '============================================================';
PRINT '  Warehouse Dimensions Complete — 8 Tables Created';
PRINT '  Schema: [warehouse]';
PRINT '  DimDate, DimRegion, DimCategory, DimSupplier,';
PRINT '  DimStore, DimEmployee, DimCustomer, DimProduct';
PRINT '  All have Unknown member (SK = -1) for orphan handling';
PRINT '  Derived/computed columns for Power BI slicers';
PRINT '============================================================';
GO
