-- =============================================================================
-- Enterprise Retail Analytics Platform - Warehouse Layer: Fact Tables
-- =============================================================================
-- Script:      04_Fact_Tables.sql
-- Purpose:     Star Schema fact tables (transactional grain)
-- Schema:      [warehouse]
-- Author:      BI Development Team
-- Created:     2026-07-20
--
-- FACT TABLES:
--   1. FactSales       — Grain: One row per order line item
--   2. FactReturns     — Grain: One row per returned line item
--   3. FactInventory   — Grain: One row per product/store/snapshot date
--
-- DESIGN PRINCIPLES:
--   - Surrogate key FKs reference dimension tables
--   - DateKey (INT YYYYMMDD) references DimDate
--   - Measures are additive (SUM-able across all dimensions)
--   - No VARCHAR columns in facts — only keys and measures
--   - Degenerate dimensions (OrderID) stored directly in fact
--
-- =============================================================================

USE RetailDW;
GO

-- ---------------------------------------------------------------------------
-- Fact 1: warehouse.FactSales
-- Grain: One row per order line item (OrderDetail level)
-- Measures: Quantity, UnitPrice, Discount, LineTotal, COGS, GrossProfit
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.FactSales', 'U') IS NOT NULL DROP TABLE warehouse.FactSales;
GO

CREATE TABLE warehouse.FactSales (
    -- Surrogate Key
    SalesFactID         BIGINT          IDENTITY(1,1) NOT NULL PRIMARY KEY,
    
    -- Dimension Foreign Keys (Surrogate)
    OrderDateKey        INT             NOT NULL,   -- → DimDate.DateKey
    CustomerSK          INT             NOT NULL,   -- → DimCustomer.CustomerSK
    ProductSK           INT             NOT NULL,   -- → DimProduct.ProductSK
    StoreSK             INT             NOT NULL,   -- → DimStore.StoreSK (-1 for online)
    EmployeeSK          INT             NOT NULL,   -- → DimEmployee.EmployeeSK (-1 for online)
    SupplierSK          INT             NOT NULL,   -- → DimSupplier.SupplierSK
    CategorySK          INT             NOT NULL,   -- → DimCategory.CategorySK
    RegionSK            INT             NOT NULL,   -- → DimRegion.RegionSK
    
    -- Degenerate Dimensions (no separate dim table needed)
    OrderID             INT             NOT NULL,
    OrderDetailID       INT             NOT NULL,
    Channel             VARCHAR(20)     NOT NULL,   -- Store / E-commerce
    OrderStatus         VARCHAR(20)     NOT NULL,   -- Completed/Shipped/etc.
    
    -- Measures (Additive)
    Quantity            INT             NOT NULL,
    UnitPrice           DECIMAL(10,2)   NOT NULL,
    UnitCost            DECIMAL(10,2)   NOT NULL,
    DiscountPercent     DECIMAL(5,2)    NOT NULL,
    DiscountAmount      DECIMAL(10,2)   NOT NULL,
    LineTotal           DECIMAL(12,2)   NOT NULL,   -- Revenue (after discount)
    LineCOGS            DECIMAL(12,2)   NOT NULL,   -- Cost of Goods Sold
    GrossProfit         DECIMAL(12,2)   NOT NULL,   -- Revenue - COGS
    
    -- Audit
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

PRINT 'Created: warehouse.FactSales (grain: order line item)';
GO

-- ---------------------------------------------------------------------------
-- Fact 2: warehouse.FactReturns
-- Grain: One row per returned line item
-- Measures: RefundAmount, OriginalLineTotal
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.FactReturns', 'U') IS NOT NULL DROP TABLE warehouse.FactReturns;
GO

CREATE TABLE warehouse.FactReturns (
    -- Surrogate Key
    ReturnFactID        BIGINT          IDENTITY(1,1) NOT NULL PRIMARY KEY,
    
    -- Dimension Foreign Keys
    ReturnDateKey       INT             NOT NULL,   -- → DimDate.DateKey
    OrderDateKey        INT             NOT NULL,   -- → DimDate.DateKey (original order)
    CustomerSK          INT             NOT NULL,   -- → DimCustomer.CustomerSK
    ProductSK           INT             NOT NULL,   -- → DimProduct.ProductSK
    StoreSK             INT             NOT NULL,   -- → DimStore.StoreSK
    CategorySK          INT             NOT NULL,   -- → DimCategory.CategorySK
    RegionSK            INT             NOT NULL,   -- → DimRegion.RegionSK
    
    -- Degenerate Dimensions
    ReturnID            INT             NOT NULL,
    OrderDetailID       INT             NOT NULL,
    OrderID             INT             NOT NULL,
    Reason              NVARCHAR(100)   NOT NULL,
    Condition           VARCHAR(50)     NOT NULL,
    
    -- Measures (Additive)
    RefundAmount        DECIMAL(10,2)   NOT NULL,
    OriginalQuantity    INT             NOT NULL,
    OriginalLineTotal   DECIMAL(12,2)   NOT NULL,
    DaysToReturn        INT             NOT NULL,   -- Days between order and return
    
    -- Audit
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

PRINT 'Created: warehouse.FactReturns (grain: returned line item)';
GO

-- ---------------------------------------------------------------------------
-- Fact 3: warehouse.FactInventory
-- Grain: One row per product/store/snapshot date (periodic snapshot)
-- Measures: QuantityOnHand, ReorderPoint, InventoryValue
-- ---------------------------------------------------------------------------
IF OBJECT_ID('warehouse.FactInventory', 'U') IS NOT NULL DROP TABLE warehouse.FactInventory;
GO

CREATE TABLE warehouse.FactInventory (
    -- Surrogate Key
    InventoryFactID     BIGINT          IDENTITY(1,1) NOT NULL PRIMARY KEY,
    
    -- Dimension Foreign Keys
    SnapshotDateKey     INT             NOT NULL,   -- → DimDate.DateKey
    ProductSK           INT             NOT NULL,   -- → DimProduct.ProductSK
    StoreSK             INT             NOT NULL,   -- → DimStore.StoreSK
    SupplierSK          INT             NOT NULL,   -- → DimSupplier.SupplierSK
    CategorySK          INT             NOT NULL,   -- → DimCategory.CategorySK
    RegionSK            INT             NOT NULL,   -- → DimRegion.RegionSK
    
    -- Degenerate Dimensions
    InventoryID         INT             NOT NULL,
    
    -- Measures (Semi-additive — additive across all dims EXCEPT date)
    QuantityOnHand      INT             NOT NULL,
    ReorderPoint        INT             NOT NULL,
    ReorderQuantity     INT             NOT NULL,
    UnitCost            DECIMAL(10,2)   NOT NULL,
    InventoryValue      DECIMAL(14,2)   NOT NULL,   -- QtyOnHand * UnitCost
    
    -- Flags
    IsLowStock          BIT             NOT NULL DEFAULT 0,
    IsOutOfStock        BIT             NOT NULL DEFAULT 0,
    
    -- Audit
    _LoadedAt           DATETIME2       DEFAULT GETDATE()
);
GO

PRINT 'Created: warehouse.FactInventory (grain: product/store/snapshot, periodic)';
GO

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------
PRINT '============================================================';
PRINT '  Warehouse Fact Tables Complete — 3 Tables Created';
PRINT '  Schema: [warehouse]';
PRINT '  FactSales:     Grain = Order Line Item (transactional)';
PRINT '  FactReturns:   Grain = Returned Line Item (transactional)';
PRINT '  FactInventory: Grain = Product/Store/Date (periodic snapshot)';
PRINT '  All FKs use surrogate keys referencing dimensions';
PRINT '============================================================';
GO
