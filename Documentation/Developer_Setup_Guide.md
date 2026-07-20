# Developer Setup Guide

## Enterprise Retail Analytics Platform — Local Environment Configuration

---

| Document Control | Details |
|-----------------|---------|
| **Document ID** | GUIDE-SETUP-2026-001 |
| **Version** | 1.0 |
| **Author** | BI Development Team |
| **Last Updated** | July 20, 2026 |
| **Audience** | New developers joining the project |
| **Estimated Time** | 30–45 minutes |

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Software Installation](#2-software-installation)
3. [Repository Setup](#3-repository-setup)
4. [Python Environment Configuration](#4-python-environment-configuration)
5. [Dataset Generation](#5-dataset-generation)
6. [Data Quality Validation](#6-data-quality-validation)
7. [SQL Server Configuration](#7-sql-server-configuration)
8. [VS Code Configuration](#8-vs-code-configuration)
9. [Troubleshooting](#9-troubleshooting)
10. [Daily Workflow](#10-daily-workflow)

---

## 1. Prerequisites

### Required Software

| Software | Version | Purpose | License |
|----------|---------|---------|---------|
| Windows 10/11 | Latest | Operating System | — |
| VS Code | Latest | Code editor & terminal | Free |
| Python | 3.10+ | Data generation & automation | Free |
| Git | Latest | Version control | Free |
| SQL Server 2022 | Developer Edition | Data warehouse | Free |
| SSMS | 22.x | SQL Server GUI client | Free |
| GitHub Account | — | Repository hosting | Free |

### Recommended VS Code Extensions

| Extension | Publisher | Purpose |
|-----------|----------|---------|
| Python | Microsoft | IntelliSense, debugging, linting |
| GitLens | GitKraken | Git history, blame, diff |
| SQL Server (mssql) | Microsoft | SQL file editing & execution |
| Markdown Preview Enhanced | Yiyi Wang | Documentation preview |
| GitHub Copilot | GitHub | AI-assisted coding |

---

## 2. Software Installation

### 2.1 Install Python 3.10+

**Download:** https://www.python.org/downloads/

**During installation — IMPORTANT:**
- [x] Check **"Add Python to PATH"** (bottom of installer)
- [x] Choose **"Customize installation"**
- [x] Check all optional features
- [x] Check **"Add Python to environment variables"**

**Verify installation:**
```powershell
python --version
# Expected: Python 3.10.x or higher
```

---

### 2.2 Install Git

**Download:** https://git-scm.com/download/win

**During installation:**
- Default settings are fine
- Choose VS Code as default editor when prompted

**Verify:**
```powershell
git --version
# Expected: git version 2.x.x
```

---

### 2.3 Install SQL Server 2022 Developer Edition

**Download:** https://www.microsoft.com/en-us/sql-server/sql-server-downloads → Choose **"Developer"** (FREE — full enterprise features)

**Installation steps:**
1. Run installer → Choose **"Basic"** installation type
2. Accept license terms
3. Choose installation location (default is fine)
4. Wait for download & install (~10 minutes)
5. Note the **Instance Name** (usually `MSSQLSERVER` or `SQLEXPRESS`)

**Verify service is running:**
```powershell
Get-Service | Where-Object {$_.Name -like '*SQL*'} | Select-Object Name, Status
```

**Expected output:**
```
Name            Status
----            ------
MSSQLSERVER     Running
SQLBrowser      Running
```

---

### 2.4 Install SQL Server Management Studio (SSMS)

**Download:** https://learn.microsoft.com/en-us/ssms/download-sql-server-management-studio-ssms

**Installation:** Run installer → Next → Install → Finish

**Connect to SQL Server:**
1. Open SSMS
2. Server name: `localhost` (if MSSQLSERVER) or `.\SQLEXPRESS` (if Express)
3. Authentication: **Windows Authentication**
4. Click **Connect**

---

### 2.5 Install VS Code

**Download:** https://code.visualstudio.com/

**Post-installation — Install extensions:**
```
Ctrl+Shift+X → Search and install:
- Python (Microsoft)
- GitLens
- SQL Server (mssql)
- Markdown Preview Enhanced
- GitHub Copilot (if license available)
```

---

## 3. Repository Setup

### 3.1 Clone the Repository

**Open VS Code terminal** (`Ctrl + backtick`):

```powershell
cd C:\Users\YourName\Documents
git clone https://github.com/amitjaiswal1988/Enterprise-Retail-Analytics-Platform.git
cd Enterprise-Retail-Analytics-Platform
```

| Command | What it does |
|---------|-------------|
| `cd Documents` | Navigate to Documents folder |
| `git clone <url>` | Download the entire repository from GitHub to your machine |
| `cd Enterprise-...` | Enter the project folder |

---

### 3.2 Verify Repository Structure

```powershell
dir
```

**Expected output:**
```
Architecture/
Dashboard Screenshots/
Dataset/
DAX/
Documentation/
Images/
Power BI/
Python/
SQL/
tests/
.gitignore
LICENSE
README.md
```

---

### 3.3 Open Project in VS Code

```powershell
code .
```

Or: File → Open Folder → Select `Enterprise-Retail-Analytics-Platform`

---

## 4. Python Environment Configuration

### 4.1 Create Virtual Environment

**What:** A virtual environment isolates project packages from your system Python.

**Why:** Prevents version conflicts between different projects.

**PowerShell:**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

**Git Bash:**
```bash
python -m venv .venv
source .venv/Scripts/activate
```

**Success indicator:** Terminal prompt shows `(.venv)` prefix:
```
(.venv) C:\Users\Amit\Documents\Enterprise-Retail-Analytics-Platform>
```

---

### 4.2 Install Required Packages

```bash
pip install -r Python/requirements.txt
```

Or install directly:
```bash
pip install numpy pandas faker pytest
```

| Package | Version | Purpose |
|---------|---------|---------|
| `numpy` | >=1.24 | Fast mathematical operations, random number generation |
| `pandas` | >=2.0 | DataFrame operations, CSV file creation |
| `faker` | >=18.0 | Realistic fake data (names, emails, addresses) |
| `pytest` | >=7.4 | Automated testing framework |

**Verify installation:**
```bash
pip list | grep -E "numpy|pandas|faker|pytest"
```

---

### 4.3 VS Code Python Interpreter Selection

1. Press `Ctrl+Shift+P`
2. Type: **"Python: Select Interpreter"**
3. Choose: `.venv\Scripts\python.exe` (the one inside your project)

This ensures VS Code uses your virtual environment's Python.

---

## 5. Dataset Generation

### 5.1 Generate Development Dataset

**What:** Creates 12 synthetic CSV files in the `Dataset/` folder.

**Why:** This data simulates enterprise retail systems (POS, CRM, ERP, HR, Logistics).

**When:** First time setup, or whenever you need fresh test data.

```bash
python Python/generate_dataset.py --profile development
```

**Expected output:**
```
============================================================
  NovaMart Retail - Synthetic Data Generator
  Profile: development
  Output:  C:\...\Enterprise-Retail-Analytics-Platform\Dataset
============================================================

[1/12] Generating regions.csv ...        → 4 rows
[2/12] Generating categories.csv ...     → 25 rows
[3/12] Generating suppliers.csv ...      → 100 rows
[4/12] Generating products.csv ...       → 2000 rows
[5/12] Generating stores.csv ...         → 50 rows
[6/12] Generating employees.csv ...      → 1000 rows
[7/12] Generating customers.csv ...      → 20000 rows
[8/12] Generating orders.csv ...         → 50250 rows
[9/12] Generating order_details.csv ...  → ~201000 rows
[10/12] Generating returns.csv ...       → ~8500 rows
[11/12] Generating shipping.csv ...      → ~22500 rows
[12/12] Generating inventory.csv ...     → ~400000 rows

============================================================
  Generation complete.
============================================================
```

**Duration:** < 60 seconds

---

### 5.2 Generation Profiles

| Profile | Command | Orders | Details | Use Case |
|---------|---------|--------|---------|----------|
| Development | `--profile development` | 50,000 | ~200,000 | Daily development & testing |
| Production | `--profile production` | 500,000 | ~2,000,000 | Performance testing & final validation |

> **Note:** Production profile takes 5–10 minutes and generates ~300 MB of data.

---

### 5.3 Verify Generated Files

```bash
dir Dataset\*.csv
```

**Expected — 12 files:**
```
categories.csv      (~1 KB)
customers.csv       (~2 MB)
employees.csv       (~70 KB)
inventory.csv       (~14 MB)
order_details.csv   (~7 MB)
orders.csv          (~2 MB)
products.csv        (~150 KB)
regions.csv         (~50 bytes)
returns.csv         (~400 KB)
shipping.csv        (~1.5 MB)
stores.csv          (~4 KB)
suppliers.csv       (~6 KB)
```

---

### 5.4 Important: Generated Data is Git-Ignored

The `Dataset/*.csv` files are listed in `.gitignore`. They will NOT be committed to GitHub.

**Why:** Large generated files should not be in version control. Every developer generates their own locally.

---

## 6. Data Quality Validation

### 6.1 Run Automated Tests

**What:** 68 automated tests verify the generated dataset.

**Why:** Enterprise practice — never trust data without validation.

```bash
python -m pytest tests/test_data_quality.py -v
```

**Expected output:**
```
tests/test_data_quality.py::TestFileExistence::test_file_exists[orders.csv] PASSED
tests/test_data_quality.py::TestFileExistence::test_file_exists[customers.csv] PASSED
...
tests/test_data_quality.py::TestDefectInjection::test_def01_null_emails PASSED
tests/test_data_quality.py::TestDefectInjection::test_def02_duplicate_orders PASSED
...
tests/test_data_quality.py::TestBusinessRules::test_channel_distribution PASSED
tests/test_data_quality.py::TestReproducibility::test_orders_deterministic PASSED

============================= 68 passed in ~46s ==============================
```

---

### 6.2 What the Tests Validate

| Test Category | Tests | What it Checks |
|---------------|-------|---------------|
| File Existence | 12 | All 12 CSV files were created |
| Schema | 12 | Each file has correct column names |
| Volumes | 12 | Row counts are within expected ranges |
| Referential Integrity | 6 | Foreign keys reference valid parent records |
| Defect Injection | 6 | Intentional data quality issues exist at expected rates |
| Business Rules | 7 | Channel splits, status distributions are correct |
| Reproducibility | 1 | Same seed produces identical output |

---

### 6.3 Run Specific Test Category

```bash
# Only file existence tests
python -m pytest tests/test_data_quality.py::TestFileExistence -v

# Only defect injection tests
python -m pytest tests/test_data_quality.py::TestDefectInjection -v

# Only business rule tests
python -m pytest tests/test_data_quality.py::TestBusinessRules -v
```

---

## 7. SQL Server Configuration

### 7.1 Determine Your Server Name

**PowerShell:**
```powershell
Get-Service | Where-Object {$_.Name -like '*SQL*'} | Select-Object Name, Status
```

| Service Name | SQL Server Instance | Connection String |
|-------------|--------------------|--------------------|
| `MSSQLSERVER` | Default instance | `localhost` |
| `MSSQL$SQLEXPRESS` | Express instance | `.\SQLEXPRESS` |
| `MSSQL$DEV` | Custom instance | `.\DEV` |

---

### 7.2 Connect via SSMS

1. Open **SQL Server Management Studio**
2. Server type: **Database Engine**
3. Server name: `localhost` or `.\SQLEXPRESS`
4. Authentication: **Windows Authentication**
5. Click **Connect**

**Success:** Object Explorer shows your server with Databases, Security, etc.

---

### 7.3 Database Creation (Phase 3 — Coming Next)

The `RetailDW` database and all tables will be created via SQL scripts in the `SQL/` folder:

```
SQL/
├── Landing/          → Raw data ingestion tables
├── Staging/          → Cleaned & validated tables
├── Warehouse/        → Star Schema (Facts + Dimensions)
├── Stored Procedures/→ ETL automation
└── Views/            → Reporting layer
```

---

## 8. VS Code Configuration

### 8.1 Recommended Settings

Create `.vscode/settings.json` (auto-created when you set interpreter):

```json
{
    "python.defaultInterpreterPath": ".venv/Scripts/python.exe",
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": ["tests/"],
    "files.exclude": {
        "**/__pycache__": true,
        "**/.pytest_cache": true
    },
    "editor.formatOnSave": true
}
```

---

### 8.2 Terminal Configuration

**Recommended default terminal:** PowerShell (for Windows commands)

Change via: `Ctrl+Shift+P` → "Terminal: Select Default Profile" → **PowerShell**

| Terminal | When to Use |
|---------|------------|
| PowerShell | Python commands, pip, pytest, general work |
| Git Bash | Git-specific operations (optional) |
| CMD | Legacy compatibility (avoid) |

---

## 9. Troubleshooting

### Common Issues & Solutions

---

#### Issue: `python: command not found`

**Cause:** Python not added to PATH during installation.

**Fix:**
```powershell
# Check if Python exists
where python

# If not found, add to PATH manually:
# System Properties → Environment Variables → Path → Add:
# C:\Users\YourName\AppData\Local\Programs\Python\Python312\
```

---

#### Issue: `pip install` fails with permission error

**Cause:** Running without virtual environment.

**Fix:**
```powershell
# Activate venv first
.venv\Scripts\Activate.ps1
# Then install
pip install -r Python/requirements.txt
```

---

#### Issue: `pytest: command not found` or `No module named pytest`

**Cause:** pytest not installed in active environment.

**Fix:**
```powershell
# Always use python -m pytest (works even if PATH is wrong)
python -m pytest tests/test_data_quality.py -v
```

---

#### Issue: `git pull` — "Please move or remove files before you merge"

**Cause:** Local untracked files conflict with remote files.

**Fix:**
```powershell
# Option 1: Remove conflicting untracked files
git clean -fd .
git pull origin main

# Option 2: Full reset to match remote (CAUTION: loses local changes)
git fetch origin
git reset --hard origin/main
```

---

#### Issue: `.venv\Scripts\activate` fails in Git Bash

**Cause:** Backslash path separator doesn't work in Bash.

**Fix:**
```bash
# Git Bash uses forward slashes and 'source' command:
source .venv/Scripts/activate
```

---

#### Issue: SSMS cannot connect — "Server not found"

**Cause:** SQL Server service not running or wrong instance name.

**Fix:**
```powershell
# Check if service is running
Get-Service MSSQLSERVER

# Start if stopped
Start-Service MSSQLSERVER

# Try different server names:
# localhost
# .\SQLEXPRESS
# (localdb)\MSSQLLocalDB
```

---

#### Issue: `generate_dataset.py` — "No such file or directory"

**Cause:** Not in the project root directory.

**Fix:**
```powershell
# Navigate to project root first
cd C:\Users\Amit\Documents\Enterprise-Retail-Analytics-Platform

# Then run with relative path
python Python/generate_dataset.py --profile development
```

---

## 10. Daily Workflow

### Starting Your Work Day

```powershell
# 1. Open VS Code in project folder
cd C:\Users\Amit\Documents\Enterprise-Retail-Analytics-Platform
code .

# 2. Activate virtual environment
.venv\Scripts\Activate.ps1

# 3. Pull latest changes from team
git pull origin main

# 4. Create feature branch for today's work
git checkout -b feat/your-feature-name
```

---

### Ending Your Work Day

```powershell
# 1. Stage your changes
git add -A

# 2. Commit with descriptive message
git commit -m "feat: description of what you built"

# 3. Push to GitHub
git push origin feat/your-feature-name

# 4. Create Pull Request on GitHub (browser)
```

---

### Quick Reference Card

| Task | Command |
|------|---------|
| Activate venv (PowerShell) | `.venv\Scripts\Activate.ps1` |
| Activate venv (Git Bash) | `source .venv/Scripts/activate` |
| Generate dev data | `python Python/generate_dataset.py --profile development` |
| Run all tests | `python -m pytest tests/test_data_quality.py -v` |
| Pull latest code | `git pull origin main` |
| Create new branch | `git checkout -b feat/branch-name` |
| Check git status | `git status` |
| Stage all changes | `git add -A` |
| Commit | `git commit -m "message"` |
| Push branch | `git push origin branch-name` |

---

## Copilot Prompts (Ready to Use)

If using GitHub Copilot in VS Code, paste these prompts:

### Setup:
```
@terminal Create a Python virtual environment, activate it, and install project dependencies from Python/requirements.txt
```

### Generate Data:
```
@terminal Run the dataset generator with development profile
```

### Run Tests:
```
@terminal Run pytest on the data quality tests with verbose output
```

### Git Operations:
```
@terminal Pull latest from main, create a new branch called feat/my-feature
```

---

*End of Document*
