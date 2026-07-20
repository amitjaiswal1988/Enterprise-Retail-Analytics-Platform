# 05 — Data Quality Testing

## Running and Understanding the 68 Automated Tests

---

## What Is Data Quality Testing?

Automated checks that verify generated data is correct BEFORE it enters the database.


## Why Test Data?

| Without Testing | With Testing |
|----------------|-------------|
| Bad data enters warehouse silently | Errors caught immediately |
| Reports show wrong numbers | Only validated data flows through |
| Hours spent debugging dashboards | Root cause found in seconds |
| No confidence in data | Full confidence — 68 checks passed |

> Enterprise practice: Amazon runs 10,000+ data quality checks daily.

---

## Step 1: Run All Tests

### Prerequisites
- Dataset generated (see Guide 04)
- pytest installed (`pip install pytest`)

### Command

```bash
python -m pytest tests/test_data_quality.py -v
```

### Breakdown

| Part | Meaning |
|------|---------|
| `python -m pytest` | Run pytest through Python (always works) |
| `tests/test_data_quality.py` | Path to test file |
| `-v` | Verbose — show each test name and PASSED/FAILED |

---

## Step 2: Understand the Output

### Success (All 68 Pass):
```
tests/test_data_quality.py::TestFileExistence::test_file_exists[orders.csv] PASSED
tests/test_data_quality.py::TestSchema::test_orders_columns PASSED
tests/test_data_quality.py::TestVolumes::test_orders_count PASSED
...
============================= 68 passed in 46s ==============================
```

### If Something Fails:
```
tests/test_data_quality.py::TestFileExistence::test_file_exists[orders.csv] FAILED
E   AssertionError: Missing file: .../Dataset/orders.csv
```
→ This means you need to generate the dataset first!

---

## Step 3: Test Categories Explained

### Category 1: File Existence (12 tests)
**What:** Do all 12 CSV files exist and are they non-empty?

**Why:** If generation failed silently, catch it here.

```bash
# Run only this category
python -m pytest tests/test_data_quality.py::TestFileExistence -v
```

---

### Category 2: Schema Compliance (12 tests)
**What:** Does each file have the correct column names?

**Why:** If columns are renamed or missing, SQL import will fail.

Example check: `orders.csv` must have columns: `OrderID, CustomerID, OrderDate, StoreID, EmployeeID, Channel, Status`

---

### Category 3: Volume Ranges (12 tests)
**What:** Are row counts within expected bounds?

**Why:** Catches generation bugs (e.g., empty file, or 10x too many rows).

Example: `orders.csv` should have 50,000–51,000 rows (50K + ~250 duplicates).

---

### Category 4: Referential Integrity (6 tests)
**What:** Do foreign keys reference valid parent records?

**Why:** Orphan records cause JOIN failures in the warehouse.

Example: Every `CustomerID` in orders.csv exists in customers.csv.

---

### Category 5: Defect Injection (6 tests)
**What:** Are intentional defects present at expected rates?

**Why:** Confirms our generator is working correctly — defects exist for ETL demo.

Example: ~5% of customer emails should be NULL.

---

### Category 6: Business Rules (7 tests)
**What:** Does data follow business logic?

**Why:** Ensures realism — e.g., Store orders have StoreID, E-commerce orders don't.

---

### Category 7: Reproducibility (1 test)
**What:** Does running the generator twice produce identical output?

**Why:** Deterministic seed guarantee — critical for team collaboration.

---

## Step 4: Run Specific Tests

```bash
# Only file existence
python -m pytest tests/test_data_quality.py::TestFileExistence -v

# Only defect checks
python -m pytest tests/test_data_quality.py::TestDefectInjection -v

# Only business rules
python -m pytest tests/test_data_quality.py::TestBusinessRules -v

# Single specific test
python -m pytest tests/test_data_quality.py::TestDefectInjection::test_def01_null_emails -v
```

---

## Interview Questions This Prepares You For

| Question | Your Answer |
|----------|-------------|
| "How do you validate data quality?" | "Automated pytest suite checking schema, volumes, FK integrity, business rules" |
| "What's referential integrity?" | "Every FK value must exist as a PK in the parent table" |
| "How do you catch data issues early?" | "Shift-left testing — validate at source before loading to warehouse" |
| "What if tests fail?" | "Pipeline halts, error logged, team notified — bad data never reaches reports" |

---

## Copilot Prompts

```
@terminal Run all data quality tests with verbose output
@terminal Run only the defect injection tests
@terminal Show me which tests failed and why
```

---

*Next Guide: [06_SQL_Server_Setup.md](./06_SQL_Server_Setup.md)*
