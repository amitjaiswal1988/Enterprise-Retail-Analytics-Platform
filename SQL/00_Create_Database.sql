-- =============================================================================
-- Enterprise Retail Analytics Platform - Database Creation Script
-- =============================================================================
-- Script:      00_Create_Database.sql
-- Purpose:     Create RetailDW database and three-layer schema architecture
-- Author:      BI Development Team
-- Created:     2026-07-20
-- Database:    RetailDW
-- Execution:   Run in SSMS connected to master database
-- =============================================================================
--
-- ARCHITECTURE:
--   [landing]   - Raw CSV ingestion (VARCHAR columns, no constraints)
--   [staging]   - Cleaned & validated (proper data types, constraints)
--   [warehouse] - Star Schema (Facts + Dimensions, indexes, FKs)
--
-- WHY 3 LAYERS?
--   1. Landing: Exact copy of source — if ETL breaks, raw data is preserved
--   2. Staging: Apply quality rules — NULLs handled, dupes removed, dates validated
--   3. Warehouse: Business-ready star schema — optimized for Power BI queries
--
-- =============================================================================

USE master;
GO

-- ---------------------------------------------------------------------------
-- Step 1: Create Database (if not exists)
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'RetailDW')
BEGIN
    CREATE DATABASE RetailDW
    ON PRIMARY (
        NAME = N'RetailDW',
        FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\RetailDW.mdf',
        SIZE = 512MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 256MB
    )
    LOG ON (
        NAME = N'RetailDW_log',
        FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\RetailDW_log.ldf',
        SIZE = 128MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 128MB
    );
    PRINT 'Database RetailDW created successfully.';
END
ELSE
BEGIN
    PRINT 'Database RetailDW already exists. Skipping creation.';
END
GO

-- ---------------------------------------------------------------------------
-- Step 2: Switch to RetailDW
-- ---------------------------------------------------------------------------
USE RetailDW;
GO

-- ---------------------------------------------------------------------------
-- Step 3: Create Schemas
-- ---------------------------------------------------------------------------

-- LANDING schema: Raw data from CSV files (no transformations)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'landing')
    EXEC('CREATE SCHEMA landing');
GO
PRINT 'Schema [landing] ready.';
GO

-- STAGING schema: Cleaned, validated, standardized data
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'staging')
    EXEC('CREATE SCHEMA staging');
GO
PRINT 'Schema [staging] ready.';
GO

-- WAREHOUSE schema: Star Schema (Facts + Dimensions)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'warehouse')
    EXEC('CREATE SCHEMA warehouse');
GO
PRINT 'Schema [warehouse] ready.';
GO

-- ---------------------------------------------------------------------------
-- Step 4: Database Configuration
-- ---------------------------------------------------------------------------

-- Set recovery model to SIMPLE (for development/portfolio — reduces log size)
ALTER DATABASE RetailDW SET RECOVERY SIMPLE;
GO

-- Enable snapshot isolation (prevents blocking for Power BI reads)
ALTER DATABASE RetailDW SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

-- Set compatibility level to SQL Server 2022
ALTER DATABASE RetailDW SET COMPATIBILITY_LEVEL = 160;
GO

PRINT '============================================================';
PRINT '  RetailDW Database Setup Complete';
PRINT '  Schemas: [landing], [staging], [warehouse]';
PRINT '  Recovery: SIMPLE';
PRINT '  Snapshot Isolation: ON';
PRINT '============================================================';
GO
