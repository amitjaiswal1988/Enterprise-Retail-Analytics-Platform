# Pilot — Project Build Log

## Enterprise Retail Analytics Platform (ShopStar Retail)

> **Purpose:** A chronological, step-by-step record of everything performed on this
> project from the very beginning (Phase 1) up to the current state. This is the
> "pilot run" journal — capturing actions taken, problems encountered, and how each
> was resolved, so the work is fully reproducible.

| Field | Value |
|-------|-------|
| **Document** | Pilot — Project Build Log |
| **Project** | Enterprise Retail Analytics Platform |
| **Business Scenario** | ShopStar Retail (simulated multi-channel retailer) |
| **Environment** | Windows + Git Bash + VS Code + Python 3.10.11 (`.venv`) |
| **Date** | July 20, 2026 |
| **Status** | Phase 1 & 2 Complete |

---

## Table of Contents

1. [Phase 1 — Business Understanding](#phase-1--business-understanding)
2. [Phase 0/1 — Environment Setup](#phase-01--environment-setup)
3. [Phase 2 — Dataset Generation](#phase-2--dataset-generation)
4. [Data Quality Testing](#data-quality-testing)
5. [Branding Rename (NovaMart → ShopStar)](#branding-rename-novamart--shopstar)
6. [Git & GitHub Workflow](#git--github-workflow)
7. [Issues Encountered & Resolutions](#issues-encountered--resolutions)
8. [Current State](#current-state)
9. [Next Phase](#next-phase)

---

## Phase 1 — Business Understanding

**Goal:** Understand the business scenario and requirements before touching any code.

- Reviewed the **Business Requirement Document (BRD)** end-to-end
  (`Documentation/Business_Requirement_Document_BRD.md`).
- Confirmed the business scenario: **ShopStar Retail**, a simulated multi-channel
  retailer (Brick-and-Mortar 60% + E-commerce 40% of revenue).
- Extracted the key modeling inputs for later phases:
  - **Fact entities:** Orders, Order Details, Returns, Inventory Snapshots
  - **Dimension entities:** Products, Customers, Stores, Employees, Suppliers,
    Regions, Calendar (derived), Categories
  - **KPIs with formulas** (Financial, Operational, Customer, Employee) — these map
    directly to future DAX measures
  - **Row-Level Security model:** Executive → all, Regional Mgr → region,
    Store Mgr → own store
- **Outcome:** BRD is solid and provides everything needed to begin data modeling.

---

## Phase 0/1 — Environment Setup

**Goal:** Prepare a clean, reproducible local Python environment.

| Step | Action | Result |
|------|--------|--------|
| 0.1 | Confirmed Python virtual environment `.venv` active | `(.venv)` shown in prompt |
| 0.6 | `python -m pip install --upgrade pip` | Update was accidentally cancelled |
| 0.6a | `python -m ensurepip --upgrade` (recovery) | **pip 26.1.2** restored |
| 0.7 | VS Code → `Python: Select Interpreter` | Selected `.venv (3.10.11)` |
| — | Created project folder structure | `Dataset/`, `SQL/{Landing,Staging,Warehouse,Stored Procedures,Views}`, `Python/` |
| — | Created `requirements.txt` and `.gitignore` | Committed to repo |
| — | Installed Python packages | `pandas`, `numpy`, `Faker`, `openpyxl`, `SQLAlchemy`, `pyodbc` |

**Environment confirmed:** venv type, Python 3.10.11, interpreter path
`.venv/Scripts/python.exe`.

---

## Phase 2 — Dataset Generation

**Goal:** Generate a deterministic, enterprise-scale synthetic dataset with
intentional data-quality defects for the ETL/Staging demonstration.

- Generator script: `Python/generate_dataset.py`
- Command used:
  ```bash
  python Python/generate_dataset.py --profile development
  ```
- **12 CSV files** produced in `Dataset/` (development profile):

  | # | File | Rows |
  |---|------|------|
  | 1 | regions.csv | 4 |
  | 2 | categories.csv | 25 |
  | 3 | suppliers.csv | 100 |
  | 4 | products.csv | 2,000 |
  | 5 | stores.csv | 50 |
  | 6 | employees.csv | 1,000 |
  | 7 | customers.csv | 20,000 |
  | 8 | orders.csv | 50,250 (incl. 250 intentional duplicates) |
  | 9 | order_details.csv | 201,473 |
  | 10 | returns.csv | 8,578 |
  | 11 | shipping.csv | 22,504 |
  | 12 | inventory.csv | 400,000 |

- **Intentional defects injected** (for Staging cleanup demo): NULL emails,
  duplicate orders, future dates, orphan products, inconsistent casing,
  negative quantities.

---

## Data Quality Testing

**Goal:** Automatically validate the generated dataset.

- Test suite: `tests/test_data_quality.py`
- Command:
  ```bash
  python -m pytest tests/test_data_quality.py -v
  ```
- **Result:** ✅ **68 tests passed** across categories:
  - File Existence & Non-Empty
  - Schema (column) validation
  - Volume (row-count) checks
  - Referential Integrity (FK validity)
  - Defect Injection verification (DEF-01 … DEF-06)
  - Business Rules (channel split, e-commerce null store, price > cost, return rate)
  - Reproducibility (deterministic seed)

---

## Branding Rename (NovaMart → ShopStar)

**Goal:** Rebrand the entire project from the placeholder "NovaMart" to
"ShopStar Retail" for consistency.

Files updated (via editor edits and `sed` in-place replacements):

| File | Change |
|------|--------|
| `README.md` | `NovaMart Retail` → `ShopStar Retail` |
| `Documentation/Business_Requirement_Document_BRD.md` | title, exec summary, company profile, ASCII banner (`NOVAMART` uppercase), strategy section |
| `Documentation/Data_Generation_Spec.md` | title + `novamart.com` → `shopstar.com` |
| `Python/generate_dataset.py` | banner print, carrier `ShopStar Logistics`, `StoreName` prefix `ShopStar #NNNN`, argparse description |
| `Documentation/Developer_Setup_Guide.md` | generator banner reference |
| `Guides/00_Project_Overview.md` | scenario description |
| `Guides/09_Phase_Summary.md` | summary + changelog entry |

- After renaming store names/carrier in the generator, the **dataset was
  regenerated** so the CSV contents matched the code.
- Final verification: `grep -rn -i "novamart"` → **NONE remaining**.

---

## Git & GitHub Workflow

Key operations performed:

- Staged and committed rename work:
  ```bash
  git add -A
  git commit -m "fix: rename to ShopStar Retail across all documents"
  ```
- Completed full rename + regeneration commit:
  ```bash
  git commit -m "fix: complete ShopStar rename and regenerate dataset - Phase 2 complete"
  git push origin main          # 0060a51..bec720e
  ```
- Pulled remote updates (new guide files added upstream):
  ```bash
  git pull origin main          # bec720e..78c88d4 (fast-forward)
  ```
- Repeatedly verified sync: working tree clean, local == `origin/main`.

---

## Issues Encountered & Resolutions

| # | Issue | Symptom | Root Cause | Fix |
|---|-------|---------|-----------|-----|
| 1 | pip update cancelled | pip partially uninstalled | Interrupted upgrade | `python -m ensurepip --upgrade` → pip 26.1.2 |
| 2 | Generator crash | `UnicodeEncodeError: '\u2192'` | Windows console default `cp1252` can't encode `→` | Added `sys.stdout.reconfigure(encoding="utf-8")` in `generate_dataset.py`; also `PYTHONUTF8=1` for tests |
| 3 | venv command failure | Exit code 106 | venv already existed / in use | Non-blocking; env activates & works fine |
| 4 | Bracketed-paste error | Exit code 127, `[200~export ...~` | Terminal pasted bracketed-paste markers literally | Re-ran command cleanly without paste artifacts |
| 5 | PowerShell in Git Bash | `Get-Content`/`Set-Content`/`Remove-Item` fail | Wrong shell syntax | Converted to Git Bash: `sed -i`, `rm -f` |
| 6 | Redundant re-runs | "nothing to commit" | Work already committed & pushed | Verified state instead of re-running expensive regeneration |

---

## Current State

- **Phase 1 (Business Understanding):** ✅ Complete
- **Phase 2 (Dataset Generation):** ✅ Complete
- **Dataset:** 12 CSVs generated (ShopStar branding), all defects present
- **Tests:** 68/68 passing
- **Branding:** 100% ShopStar (no `NovaMart` anywhere)
- **Git:** Working tree clean, synced with `origin/main`
- **Environment:** `.venv` (Python 3.10.11), all packages installed

---

## Next Phase

**Phase 3 — Database Design (SQL Server Star Schema):**

1. **Landing** layer — raw CSV ingestion tables (as-is, all defects preserved)
2. **Staging** layer — cleaned/validated tables (defect treatments applied)
3. **Warehouse** layer — Kimball star schema:
   - Dimension tables: DimProduct, DimCustomer, DimStore, DimEmployee,
     DimSupplier, DimRegion, DimCategory, DimDate (derived calendar)
   - Fact tables: FactOrders, FactOrderDetails, FactReturns, FactInventory
4. Stored procedures for ETL orchestration
5. Reporting views for the Power BI semantic model

---

*End of Pilot log — updated as new phases complete.*
