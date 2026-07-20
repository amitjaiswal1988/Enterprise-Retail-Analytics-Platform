# 04 — Dataset Generation

## How to Generate Synthetic Retail Data

---

## What Is This?

`Python/generate_dataset.py` creates **12 CSV files** containing fake but realistic retail data.


## Why Synthetic Data?

| Real Data | Synthetic Data (Ours) |
|-----------|----------------------|
| Hard to get (proprietary) | We control it completely |
| Privacy concerns (PII) | No real people involved |
| Can't add intentional defects | We inject defects for ETL demo |
| Fixed size | Any size we want (50K or 500K) |
| Can't share publicly | Share freely on GitHub |

---

## Step 1: Run the Generator

### Prerequisites
- Virtual environment activated (see Guide 03)
- Packages installed (numpy, pandas, faker)

### Command

```bash
python Python/generate_dataset.py --profile development
```

### Breakdown

| Part | Meaning |
|------|---------|
| `python` | Use Python interpreter |
| `Python/generate_dataset.py` | Path to our script |
| `--profile development` | Use small dataset (50K orders) for fast testing |

---

## Step 2: Choose a Profile

| Profile | Orders | Details | Time | Use Case |
|---------|--------|---------|------|----------|
| `development` | 50,000 | ~200,000 | < 60 sec | Daily dev/testing |
| `production` | 500,000 | ~2,000,000 | 5-10 min | Final validation |

```bash
# Fast development data
python Python/generate_dataset.py --profile development

# Full production data (run once for final testing)
python Python/generate_dataset.py --profile production
```

---

## Step 3: What Gets Generated

After running, `Dataset/` folder contains:

| # | File | Rows (Dev) | Simulates | Key Columns |
|---|------|-----------|-----------|-------------|
| 1 | `regions.csv` | 4 | Master Data | RegionID, RegionName |
| 2 | `categories.csv` | 25 | Product Management | CategoryID, CategoryName, SubCategoryName |
| 3 | `suppliers.csv` | 100 | Procurement System | SupplierID, SupplierName, Country, Rating |
| 4 | `products.csv` | 2,000 | ERP/Product Master | ProductID, ProductName, UnitCost, UnitPrice |
| 5 | `stores.csv` | 50 | Store Operations | StoreID, StoreName, City, State, Region |
| 6 | `employees.csv` | 1,000 | HR System | EmployeeID, Name, Department, Role, StoreID |
| 7 | `customers.csv` | 20,000 | CRM System | CustomerID, Name, Email, Segment, Region |
| 8 | `orders.csv` | ~50,250 | POS + E-commerce | OrderID, CustomerID, OrderDate, Channel |
| 9 | `order_details.csv` | ~201,000 | POS + E-commerce | OrderDetailID, OrderID, ProductID, Qty, Price |
| 10 | `returns.csv` | ~8,500 | Returns System | ReturnID, OrderDetailID, Reason, RefundAmount |
| 11 | `shipping.csv` | ~22,500 | Logistics System | ShippingID, OrderID, Carrier, DeliveryDate |
| 12 | `inventory.csv` | ~400,000 | Warehouse Mgmt | InventoryID, ProductID, StoreID, QtyOnHand |

---

## Step 4: Understand Intentional Defects

The generator **purposely injects data quality issues** to demonstrate ETL skills:

| Defect | Where | Rate | Purpose |
|--------|-------|------|---------|
| NULL emails | customers.csv | 5% | Show NULL handling in staging |
| Duplicate rows | orders.csv | 0.5% | Show deduplication logic |
| Future dates | orders.csv | 0.1% | Show date validation |
| Orphan FK refs | order_details.csv | 0.2% | Show referential integrity checks |
| Inconsistent casing | categories.csv | 3% | Show standardization |
| Negative quantities | order_details.csv | 0.1% | Show business rule validation |

**These defects are NOT bugs** — they're intentional. We fix them in Phase 4 (Data Cleaning).

---

## Step 5: Verify Output

```bash
# Check files exist
dir Dataset\*.csv

# Quick row count (PowerShell)
(Get-Content Dataset\orders.csv | Measure-Object -Line).Lines
```

---

## Key Concepts

### Deterministic Seed (MASTER_SEED = 42)
Every time you run the generator, you get **exactly the same data**. This is critical for:
- Tests always producing same results
- Team members having identical datasets
- Debugging reproducibility

### Why 42?
It's a tradition in computing (Hitchhiker's Guide to the Galaxy). Any number works.

---

## Important Notes

- `Dataset/*.csv` files are in `.gitignore` — they are NOT committed to GitHub
- Each developer generates their own data locally
- Production dataset is ~300 MB — don't commit it!
- Re-running the generator **overwrites** existing files

---

## Copilot Prompts

```
@terminal Generate the development dataset using the Python script
@terminal Show me the file sizes of all generated CSV files in the Dataset folder
@terminal Count the number of rows in Dataset/orders.csv
```

---

*Next Guide: [05_Data_Quality_Testing.md](./05_Data_Quality_Testing.md)*
