-- =============================================================================
-- Enterprise Retail Analytics Platform - Indexes and Foreign Keys
-- =============================================================================
-- Script:      05_Indexes_And_ForeignKeys.sql
-- Purpose:     Performance indexes and referential integrity constraints
-- Schema:      [warehouse]
-- Author:      BI Development Team
-- Created:     2026-07-20
--
-- INDEX STRATEGY:
--   1. Clustered indexes on surrogate PKs (already via PRIMARY KEY)
--   2. Non-clustered indexes on fact table FK columns (dimension lookups)
--   3. Non-clustered indexes on date keys (time intelligence queries)
--   4. Covering indexes for common Power BI query patterns
--   5. Columnstore index on FactSales (analytical workload optimization)
--
-- FK STRATEGY:
--   All fact table FKs reference dimension surrogate keys.
--   ON DELETE NO ACTION / ON UPDATE NO ACTION (prevent cascading deletes).
--
-- WHY INDEXES MATTER:
--   - Power BI sends DAX queries that JOIN facts to dims via FK columns
--   - Without indexes: full table scans on 2M+ row fact tables
--   - With indexes: seeks on indexed columns → sub-second query response
--   - Columnstore: 10x compression, batch mode for aggregations
--
-- EXECUTION: Run after 03_Dimension_Tables.sql and 04_Fact_Tables.sql
-- =============================================================================

USE RetailDW;
GO

-- Required for filtered / computed-column indexes across all clients.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- =============================================================================
-- SECTION 1: FOREIGN KEY CONSTRAINTS
-- =============================================================================

PRINT '--- Creating Foreign Key Constraints ---';
GO

-- ---------------------------------------------------------------------------
-- FactSales Foreign Keys
-- ---------------------------------------------------------------------------
ALTER TABLE warehouse.FactSales
    ADD CONSTRAINT FK_FactSales_DimDate
    FOREIGN KEY (OrderDateKey) REFERENCES warehouse.DimDate(DateKey);
GO

ALTER TABLE warehouse.FactSales
    ADD CONSTRAINT FK_FactSales_DimCustomer
    FOREIGN KEY (CustomerSK) REFERENCES warehouse.DimCustomer(CustomerSK);
GO

ALTER TABLE warehouse.FactSales
    ADD CONSTRAINT FK_FactSales_DimProduct
    FOREIGN KEY (ProductSK) REFERENCES warehouse.DimProduct(ProductSK);
GO

ALTER TABLE warehouse.FactSales
    ADD CONSTRAINT FK_FactSales_DimStore
    FOREIGN KEY (StoreSK) REFERENCES warehouse.DimStore(StoreSK);
GO

ALTER TABLE warehouse.FactSales
    ADD CONSTRAINT FK_FactSales_DimEmployee
    FOREIGN KEY (EmployeeSK) REFERENCES warehouse.DimEmployee(EmployeeSK);
GO

ALTER TABLE warehouse.FactSales
    ADD CONSTRAINT FK_FactSales_DimSupplier
    FOREIGN KEY (SupplierSK) REFERENCES warehouse.DimSupplier(SupplierSK);
GO

ALTER TABLE warehouse.FactSales
    ADD CONSTRAINT FK_FactSales_DimCategory
    FOREIGN KEY (CategorySK) REFERENCES warehouse.DimCategory(CategorySK);
GO

ALTER TABLE warehouse.FactSales
    ADD CONSTRAINT FK_FactSales_DimRegion
    FOREIGN KEY (RegionSK) REFERENCES warehouse.DimRegion(RegionSK);
GO

PRINT 'FactSales: 8 Foreign Keys created';
GO

-- ---------------------------------------------------------------------------
-- FactReturns Foreign Keys
-- ---------------------------------------------------------------------------
ALTER TABLE warehouse.FactReturns
    ADD CONSTRAINT FK_FactReturns_DimDate_Return
    FOREIGN KEY (ReturnDateKey) REFERENCES warehouse.DimDate(DateKey);
GO

ALTER TABLE warehouse.FactReturns
    ADD CONSTRAINT FK_FactReturns_DimDate_Order
    FOREIGN KEY (OrderDateKey) REFERENCES warehouse.DimDate(DateKey);
GO

ALTER TABLE warehouse.FactReturns
    ADD CONSTRAINT FK_FactReturns_DimCustomer
    FOREIGN KEY (CustomerSK) REFERENCES warehouse.DimCustomer(CustomerSK);
GO

ALTER TABLE warehouse.FactReturns
    ADD CONSTRAINT FK_FactReturns_DimProduct
    FOREIGN KEY (ProductSK) REFERENCES warehouse.DimProduct(ProductSK);
GO

ALTER TABLE warehouse.FactReturns
    ADD CONSTRAINT FK_FactReturns_DimStore
    FOREIGN KEY (StoreSK) REFERENCES warehouse.DimStore(StoreSK);
GO

ALTER TABLE warehouse.FactReturns
    ADD CONSTRAINT FK_FactReturns_DimCategory
    FOREIGN KEY (CategorySK) REFERENCES warehouse.DimCategory(CategorySK);
GO

ALTER TABLE warehouse.FactReturns
    ADD CONSTRAINT FK_FactReturns_DimRegion
    FOREIGN KEY (RegionSK) REFERENCES warehouse.DimRegion(RegionSK);
GO

PRINT 'FactReturns: 7 Foreign Keys created';
GO

-- ---------------------------------------------------------------------------
-- FactInventory Foreign Keys
-- ---------------------------------------------------------------------------
ALTER TABLE warehouse.FactInventory
    ADD CONSTRAINT FK_FactInventory_DimDate
    FOREIGN KEY (SnapshotDateKey) REFERENCES warehouse.DimDate(DateKey);
GO

ALTER TABLE warehouse.FactInventory
    ADD CONSTRAINT FK_FactInventory_DimProduct
    FOREIGN KEY (ProductSK) REFERENCES warehouse.DimProduct(ProductSK);
GO

ALTER TABLE warehouse.FactInventory
    ADD CONSTRAINT FK_FactInventory_DimStore
    FOREIGN KEY (StoreSK) REFERENCES warehouse.DimStore(StoreSK);
GO

ALTER TABLE warehouse.FactInventory
    ADD CONSTRAINT FK_FactInventory_DimSupplier
    FOREIGN KEY (SupplierSK) REFERENCES warehouse.DimSupplier(SupplierSK);
GO

ALTER TABLE warehouse.FactInventory
    ADD CONSTRAINT FK_FactInventory_DimCategory
    FOREIGN KEY (CategorySK) REFERENCES warehouse.DimCategory(CategorySK);
GO

ALTER TABLE warehouse.FactInventory
    ADD CONSTRAINT FK_FactInventory_DimRegion
    FOREIGN KEY (RegionSK) REFERENCES warehouse.DimRegion(RegionSK);
GO

PRINT 'FactInventory: 6 Foreign Keys created';
GO

-- =============================================================================
-- SECTION 2: NON-CLUSTERED INDEXES ON FACT TABLES
-- =============================================================================

PRINT '--- Creating Non-Clustered Indexes ---';
GO

-- ---------------------------------------------------------------------------
-- FactSales Indexes (most important — largest table)
-- ---------------------------------------------------------------------------

-- Date-based queries (YTD, MTD, QTD, time intelligence)
CREATE NONCLUSTERED INDEX IX_FactSales_OrderDateKey
    ON warehouse.FactSales (OrderDateKey)
    INCLUDE (LineTotal, GrossProfit, Quantity);
GO

-- Customer analysis (CLV, retention, segmentation)
CREATE NONCLUSTERED INDEX IX_FactSales_CustomerSK
    ON warehouse.FactSales (CustomerSK)
    INCLUDE (OrderDateKey, LineTotal, Quantity);
GO

-- Product analysis (top N, ABC, category performance)
CREATE NONCLUSTERED INDEX IX_FactSales_ProductSK
    ON warehouse.FactSales (ProductSK)
    INCLUDE (OrderDateKey, LineTotal, GrossProfit, Quantity);
GO

-- Store performance (regional, store-level KPIs)
CREATE NONCLUSTERED INDEX IX_FactSales_StoreSK
    ON warehouse.FactSales (StoreSK)
    INCLUDE (OrderDateKey, LineTotal, GrossProfit);
GO

-- Employee performance (sales per associate)
CREATE NONCLUSTERED INDEX IX_FactSales_EmployeeSK
    ON warehouse.FactSales (EmployeeSK)
    INCLUDE (OrderDateKey, LineTotal, Quantity);
GO

-- Channel analysis (Store vs E-commerce)
CREATE NONCLUSTERED INDEX IX_FactSales_Channel
    ON warehouse.FactSales (Channel)
    INCLUDE (OrderDateKey, LineTotal, GrossProfit);
GO

-- Composite: Date + Store (regional time-series)
CREATE NONCLUSTERED INDEX IX_FactSales_Date_Store
    ON warehouse.FactSales (OrderDateKey, StoreSK)
    INCLUDE (LineTotal, GrossProfit, Quantity);
GO

-- Composite: Date + Product (product time-series)
CREATE NONCLUSTERED INDEX IX_FactSales_Date_Product
    ON warehouse.FactSales (OrderDateKey, ProductSK)
    INCLUDE (LineTotal, GrossProfit, Quantity);
GO

PRINT 'FactSales: 8 Non-Clustered indexes created';
GO

-- ---------------------------------------------------------------------------
-- FactReturns Indexes
-- ---------------------------------------------------------------------------

CREATE NONCLUSTERED INDEX IX_FactReturns_ReturnDateKey
    ON warehouse.FactReturns (ReturnDateKey)
    INCLUDE (RefundAmount, OriginalLineTotal);
GO

CREATE NONCLUSTERED INDEX IX_FactReturns_ProductSK
    ON warehouse.FactReturns (ProductSK)
    INCLUDE (ReturnDateKey, RefundAmount, Reason);
GO

CREATE NONCLUSTERED INDEX IX_FactReturns_CustomerSK
    ON warehouse.FactReturns (CustomerSK)
    INCLUDE (ReturnDateKey, RefundAmount);
GO

PRINT 'FactReturns: 3 Non-Clustered indexes created';
GO

-- ---------------------------------------------------------------------------
-- FactInventory Indexes
-- ---------------------------------------------------------------------------

CREATE NONCLUSTERED INDEX IX_FactInventory_SnapshotDateKey
    ON warehouse.FactInventory (SnapshotDateKey)
    INCLUDE (QuantityOnHand, InventoryValue, IsOutOfStock);
GO

CREATE NONCLUSTERED INDEX IX_FactInventory_ProductSK
    ON warehouse.FactInventory (ProductSK)
    INCLUDE (SnapshotDateKey, QuantityOnHand, InventoryValue);
GO

CREATE NONCLUSTERED INDEX IX_FactInventory_StoreSK
    ON warehouse.FactInventory (StoreSK)
    INCLUDE (SnapshotDateKey, QuantityOnHand, IsLowStock);
GO

-- Low stock alert query optimization
-- NOTE: Filtered index predicates do NOT support OR, so this is a plain
-- composite index. Queries filtering on either flag still benefit.
CREATE NONCLUSTERED INDEX IX_FactInventory_LowStock
    ON warehouse.FactInventory (IsLowStock, IsOutOfStock)
    INCLUDE (SnapshotDateKey, ProductSK, StoreSK, QuantityOnHand);
GO

PRINT 'FactInventory: 4 Non-Clustered indexes created (including filtered)';
GO

-- =============================================================================
-- SECTION 3: COLUMNSTORE INDEX (Analytical Performance)
-- =============================================================================

PRINT '--- Creating Columnstore Indexes ---';
GO

-- Columnstore on FactSales — massive performance boost for aggregations
-- Power BI DAX queries use SUM, AVERAGE, COUNT — all benefit from columnstore
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCIX_FactSales_Analytical
    ON warehouse.FactSales (
        OrderDateKey, CustomerSK, ProductSK, StoreSK, EmployeeSK,
        RegionSK, CategorySK, Channel, OrderStatus,
        Quantity, UnitPrice, UnitCost, DiscountAmount,
        LineTotal, LineCOGS, GrossProfit
    );
GO

PRINT 'FactSales: Columnstore index created (analytical optimization)';
GO

-- Columnstore on FactInventory — periodic snapshot aggregations
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCIX_FactInventory_Analytical
    ON warehouse.FactInventory (
        SnapshotDateKey, ProductSK, StoreSK, CategorySK, RegionSK,
        QuantityOnHand, ReorderPoint, InventoryValue,
        IsLowStock, IsOutOfStock
    );
GO

PRINT 'FactInventory: Columnstore index created';
GO

-- =============================================================================
-- SECTION 4: DIMENSION TABLE INDEXES (Natural Key Lookups)
-- =============================================================================

PRINT '--- Creating Dimension Lookup Indexes ---';
GO

-- ETL uses natural/business keys to look up surrogate keys
CREATE UNIQUE NONCLUSTERED INDEX IX_DimCustomer_BusinessKey
    ON warehouse.DimCustomer (CustomerID);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DimProduct_BusinessKey
    ON warehouse.DimProduct (ProductID);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DimStore_BusinessKey
    ON warehouse.DimStore (StoreID);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DimEmployee_BusinessKey
    ON warehouse.DimEmployee (EmployeeID);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DimSupplier_BusinessKey
    ON warehouse.DimSupplier (SupplierID);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DimCategory_BusinessKey
    ON warehouse.DimCategory (CategoryID);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_DimRegion_BusinessKey
    ON warehouse.DimRegion (RegionID);
GO

PRINT 'Dimensions: 7 Business Key lookup indexes created';
GO

-- =============================================================================
-- Summary
-- =============================================================================
PRINT '============================================================';
PRINT '  Indexes & Foreign Keys Complete';
PRINT '  Foreign Keys:   21 (8 + 7 + 6)';
PRINT '  NC Indexes:     15 (8 + 3 + 4)';
PRINT '  Columnstore:     2 (FactSales + FactInventory)';
PRINT '  Dim Lookups:     7 (unique on business keys)';
PRINT '  Total:          45 index/constraint objects';
PRINT '============================================================';
GO
