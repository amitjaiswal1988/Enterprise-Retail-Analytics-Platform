# Data Generation Specification

## ShopStar Retail — Synthetic Dataset Generator

---

| Document Control | Details |
|-----------------|---------|
| **Document ID** | SPEC-DATAGEN-2026-001 |
| **Version** | 1.0 |
| **Author** | BI Development Team |
| **Date Created** | July 20, 2026 |
| **Script** | `Python/generate_dataset.py` |
| **Seed** | `MASTER_SEED = 42` (deterministic) |

---

## 1. Overview

This document specifies the synthetic data generation process for the Enterprise Retail Analytics Platform. The generator produces 12 CSV source files that simulate data arriving from multiple enterprise systems (POS, CRM, ERP, HR, Logistics).

Intentional data-quality defects are injected into the **raw output only**. These defects are cataloged below with their expected treatment in the SQL Server staging layer (Phase 4).

---

## 2. Generation Profiles

| Parameter | Development | Production |
|-----------|-------------|------------|
| `--profile` | `development` | `production` |
| Orders | 50,000 | 500,000 |
| Order Details | ~200,000 | ~2,000,000 |
| Customers | 20,000 | 200,000 |
| Products | 2,000 | 10,000 |
| Stores | 50 | 120 |
| Employees | 1,000 | 5,000 |
| Suppliers | 100 | 500 |
| Categories | 25 | 50 |
| Inventory rows | ~400,000 | ~4,000,000 |
| Returns | ~8,500 | ~85,000 |
| Shipping | ~22,000 | ~220,000 |
| Date Range | 2021-01-01 to 2025-12-31 | 2021-01-01 to 2025-12-31 |
| Seed | 42 | 42 |
| Approx. runtime | < 60 seconds | 5–10 minutes |
| Approx. disk | ~30 MB | ~300 MB |

Both profiles use the same `MASTER_SEED = 42` for full reproducibility.

---

## 3. Output Files

| # | File | Simulated Source System | Key Columns |
|---|------|------------------------|-------------|
| 1 | `regions.csv` | Master Data | RegionID, RegionName |
| 2 | `categories.csv` | Product Management | CategoryID, CategoryName, SubCategoryName, Department |
| 3 | `suppliers.csv` | Procurement | SupplierID, SupplierName, Country, LeadTimeDays, Rating, ContactEmail |
| 4 | `products.csv` | ERP / Product Master | ProductID, ProductName, CategoryID, Category, SubCategory, Brand, UnitCost, UnitPrice, SupplierID |
| 5 | `stores.csv` | Store Operations | StoreID, StoreName, City, State, Region, StoreType, OpenDate, SquareFootage |
| 6 | `employees.csv` | HR System | EmployeeID, FirstName, LastName, Department, Role, StoreID, HireDate, Salary, ManagerID |
| 7 | `customers.csv` | CRM | CustomerID, FirstName, LastName, Email, Segment, JoinDate, City, State, Region |
| 8 | `orders.csv` | POS + E-commerce | OrderID, CustomerID, OrderDate, StoreID, EmployeeID, Channel, Status |
| 9 | `order_details.csv` | POS + E-commerce | OrderDetailID, OrderID, ProductID, Quantity, UnitPrice, Discount, LineTotal |
| 10 | `returns.csv` | Returns System | ReturnID, OrderDetailID, ReturnDate, Reason, RefundAmount, Condition |
| 11 | `shipping.csv` | Logistics | ShippingID, OrderID, ShipDate, DeliveryDate, Carrier, ShipMode, ShippingCost, TrackingNumber |
| 12 | `inventory.csv` | Warehouse Management | InventoryID, ProductID, StoreID, SnapshotDate, QuantityOnHand, ReorderPoint, ReorderQuantity |

---

## 4. Business Rules Embedded in Data

| Rule | Implementation |
|------|---------------|
| Channel split | 60% Store / 40% E-commerce (weighted random) |
| Seasonality | Q4 (Oct–Dec) boosted by 15% additional orders |
| Order status | 85% Completed, 8% Shipped, 4% Processing, 3% Cancelled |
| Return rate | ~5% of completed order-detail lines |
| Discount distribution | 40% no discount, remainder 5%–35% in 5% increments |
| Store orders | Have StoreID + EmployeeID populated |
| E-commerce orders | StoreID and EmployeeID are NULL (valid business NULL) |
| Employee hierarchy | Top 5% have NULL ManagerID (top-level managers) |
| Product margins | 15%–65% markup over UnitCost |
| Inventory snapshots | Quarterly frequency per store-product pair |

---

## 5. Intentional Data-Quality Defects

### 5.1 Defect Catalog

| Defect ID | File | Defect Type | Injection Rate | Description |
|-----------|------|-------------|----------------|-------------|
| DEF-01 | `customers.csv` | NULL values | 5% of rows | `Email` column is NULL |
| DEF-02 | `orders.csv` | Duplicate rows | 0.5% of rows | Exact row duplicates appended to end of file |
| DEF-03 | `orders.csv` | Invalid dates | 0.1% of rows | `OrderDate` set to future date `2027-03-15` |
| DEF-04 | `order_details.csv` | Orphan FK reference | 0.2% of rows | `ProductID` references non-existent product (ID > max valid) |
| DEF-05 | `categories.csv` | Inconsistent casing | 3% of rows | `CategoryName` randomly uppercased, lowercased, or swapCased |
| DEF-06 | `order_details.csv` | Negative quantity | 0.1% of rows | `Quantity` is negative (invalid business rule) |
| DEF-07 | `employees.csv` | NULL ManagerID | 5% of rows | Top-level managers have no `ManagerID` (structural NULL — valid) |

### 5.2 Defect vs. Valid Business NULL

| Column | NULL Meaning | Is Defect? |
|--------|-------------|------------|
| `orders.StoreID` | E-commerce order (no physical store) | No — valid business rule |
| `orders.EmployeeID` | E-commerce order (no in-store associate) | No — valid business rule |
| `employees.ManagerID` | Top-level manager (no superior) | No — structural hierarchy |
| `customers.Email` | Missing contact information | **Yes — data quality issue** |

---

## 6. Expected Staging-Layer Treatments

Each defect above maps to a specific ETL transformation in the SQL Server staging layer (Phase 4):

### DEF-01: NULL Customer Emails

| Aspect | Details |
|--------|---------|
| **Detection** | `WHERE Email IS NULL` |
| **Treatment** | Replace with placeholder `'unknown@shopstar.com'` or flag with `IsEmailMissing = 1` |
| **Rationale** | Email is optional for in-store customers; analytics should not exclude these rows |
| **SQL Pattern** | `ISNULL(Email, 'unknown@shopstar.com')` |

### DEF-02: Duplicate Orders

| Aspect | Details |
|--------|---------|
| **Detection** | `ROW_NUMBER() OVER (PARTITION BY OrderID, CustomerID, OrderDate ORDER BY OrderID)` |
| **Treatment** | Keep first occurrence (`rn = 1`), discard duplicates |
| **Rationale** | POS systems occasionally transmit duplicate records during network retries |
| **SQL Pattern** | CTE with `ROW_NUMBER()` deduplication |

### DEF-03: Future/Invalid Dates

| Aspect | Details |
|--------|---------|
| **Detection** | `WHERE OrderDate > GETDATE()` or `OrderDate > '2025-12-31'` |
| **Treatment** | Move to error/quarantine table for manual review; exclude from warehouse load |
| **Rationale** | Dates beyond the reporting period indicate data entry errors or system clock issues |
| **SQL Pattern** | `CASE WHEN OrderDate > @MaxValidDate THEN NULL END` + error logging |

### DEF-04: Orphan Product References

| Aspect | Details |
|--------|---------|
| **Detection** | `LEFT JOIN Products ON od.ProductID = p.ProductID WHERE p.ProductID IS NULL` |
| **Treatment** | Route to quarantine; optionally map to "Unknown Product" surrogate dimension row |
| **Rationale** | Products may be deleted from master data before all historical references are cleaned |
| **SQL Pattern** | Surrogate key `-1` in DimProduct for "Unknown" with LEFT JOIN coalesce |

### DEF-05: Inconsistent Category Casing

| Aspect | Details |
|--------|---------|
| **Detection** | Compare `CategoryName` against canonical lookup after `UPPER()` normalization |
| **Treatment** | Standardize to title case using canonical mapping table |
| **Rationale** | Source systems often lack input validation; ETL must enforce consistency |
| **SQL Pattern** | `UPDATE stg SET CategoryName = lkp.CanonicalName FROM Staging JOIN Lookup` |

### DEF-06: Negative Quantities

| Aspect | Details |
|--------|---------|
| **Detection** | `WHERE Quantity < 0` |
| **Treatment** | Flag as anomaly; move to quarantine or convert to absolute value with audit flag |
| **Rationale** | Negative quantities are invalid for sales (returns have a separate table) |
| **SQL Pattern** | `CASE WHEN Quantity < 0 THEN ABS(Quantity) END` + `IsQuantityCorrected = 1` |

### DEF-07: NULL ManagerID (Structural)

| Aspect | Details |
|--------|---------|
| **Detection** | `WHERE ManagerID IS NULL` |
| **Treatment** | **No treatment required** — valid hierarchy terminator |
| **Rationale** | CEO/Regional Managers sit at top of reporting hierarchy; NULL is intentional |
| **SQL Pattern** | Keep as-is; self-referencing FK allows NULL |

---

## 7. Data Volume Estimates (Production Profile)

| File | Rows | Approx. Size | Notes |
|------|------|-------------|-------|
| `regions.csv` | 4 | < 1 KB | Static reference |
| `categories.csv` | 50 | < 3 KB | Static reference |
| `suppliers.csv` | 500 | ~30 KB | Slow-changing |
| `products.csv` | 10,000 | ~800 KB | Slow-changing |
| `stores.csv` | 120 | ~8 KB | Slow-changing |
| `employees.csv` | 5,000 | ~350 KB | Weekly refresh |
| `customers.csv` | 200,000 | ~18 MB | Daily append |
| `orders.csv` | ~502,500 | ~25 MB | Daily append (includes dupes) |
| `order_details.csv` | ~2,000,000 | ~80 MB | Daily append |
| `returns.csv` | ~85,000 | ~4 MB | Daily append |
| `shipping.csv` | ~220,000 | ~15 MB | Daily append |
| `inventory.csv` | ~4,000,000 | ~150 MB | Quarterly snapshot |
| **Total** | | **~290 MB** | |

---

## 8. Reproducibility

| Mechanism | Value |
|-----------|-------|
| Master seed | `MASTER_SEED = 42` |
| NumPy RNG | `np.random.default_rng(42)` |
| Faker seed | `Faker.seed(42)` |
| Determinism | Same profile + same seed = identical output every time |
| Version pinning | See `Python/requirements.txt` |

To verify reproducibility:
```bash
python generate_dataset.py --profile development
md5sum ../Dataset/orders.csv
# Run again — hash must match
python generate_dataset.py --profile development
md5sum ../Dataset/orders.csv
```

---

## 9. Extending the Generator

To add a new entity or defect:

1. Add a new method `_gen_<entity>(self)` to `RetailDataGenerator`
2. Add the call to `generate_all()` in the correct dependency position
3. If the entity has defects, add a rate parameter to the `Profile` dataclass
4. Document the defect in Section 5 of this spec
5. Document the staging treatment in Section 6

---

## 10. Relationship Diagram (Source Files)

```
regions.csv ─────────────────┐
                             │
categories.csv ──┐           │
                 ▼           ▼
suppliers.csv ──▶ products.csv ──┐
                                 │
stores.csv ──────────────────────┤
                                 │
employees.csv ───────────────────┤
                                 │
customers.csv ───────────────────┤
                                 ▼
                          orders.csv
                              │
                              ▼
                     order_details.csv ──┬──▶ returns.csv
                                        │
                     orders.csv ─────────┴──▶ shipping.csv
                                        
stores.csv + products.csv ──▶ inventory.csv
```

### Foreign Key Relationships

| Child File | Child Column | Parent File | Parent Column |
|-----------|-------------|-------------|---------------|
| products.csv | SupplierID | suppliers.csv | SupplierID |
| products.csv | CategoryID | categories.csv | CategoryID |
| stores.csv | Region | regions.csv | RegionName |
| employees.csv | StoreID | stores.csv | StoreID |
| employees.csv | ManagerID | employees.csv | EmployeeID |
| customers.csv | Region | regions.csv | RegionName |
| orders.csv | CustomerID | customers.csv | CustomerID |
| orders.csv | StoreID | stores.csv | StoreID |
| orders.csv | EmployeeID | employees.csv | EmployeeID |
| order_details.csv | OrderID | orders.csv | OrderID |
| order_details.csv | ProductID | products.csv | ProductID |
| returns.csv | OrderDetailID | order_details.csv | OrderDetailID |
| shipping.csv | OrderID | orders.csv | OrderID |
| inventory.csv | ProductID | products.csv | ProductID |
| inventory.csv | StoreID | stores.csv | StoreID |

---

*End of Document*
