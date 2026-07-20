# 08 — Troubleshooting

## Every Error We Faced & Exact Fix

---

## Quick Diagnosis

| Error Message | Jump To |
|--------------|---------|
| `python: command not found` | [Issue 1](#issue-1-python-command-not-found) |
| `No module named pytest` | [Issue 2](#issue-2-no-module-named-x) |
| `pytest: command not found` | [Issue 2](#issue-2-no-module-named-x) |
| `Please move or remove files before merge` | [Issue 3](#issue-3-git-pull-conflict) |
| `No such file or directory` | [Issue 4](#issue-4-file-not-found) |
| `.venv\Scripts\activate` not working | [Issue 5](#issue-5-venv-activation-fails) |
| SSMS cannot connect | [Issue 6](#issue-6-ssms-connection-failed) |
| `running scripts is disabled` | [Issue 7](#issue-7-powershell-execution-policy) |


---

## Issue 1: `python: command not found`

### When This Happens
Running any Python command in terminal.

### Why
Python was not added to system PATH during installation.

### Fix

**Option A: Reinstall Python**
1. Uninstall Python (Settings → Apps → Python → Uninstall)
2. Download fresh from python.org
3. During install: CHECK ✅ **"Add Python to PATH"**

**Option B: Manual PATH fix**
```powershell
# Find where Python is installed
where python
# If not found, add manually:
# Settings → System → About → Advanced → Environment Variables
# Add to PATH: C:\Users\YourName\AppData\Local\Programs\Python\Python312\
```

---

## Issue 2: `No module named X` / `pytest: command not found`

### When This Happens
Running `pytest` or `python -m pytest` and getting import errors.

### Why
Package not installed, OR virtual environment not activated.

### Fix

```bash
# Step 1: Make sure venv is activated (look for (.venv) in prompt)
# PowerShell:
.venv\Scripts\Activate.ps1
# Git Bash:
source .venv/Scripts/activate

# Step 2: Install the package
pip install pytest
# Or install all:
pip install numpy pandas faker pytest

# Step 3: Use python -m prefix (always works)
python -m pytest tests/test_data_quality.py -v
```

---

## Issue 3: Git Pull Conflict — "Please move or remove files before merge"

### When This Happens
Running `git pull origin main` when local has untracked files that conflict with remote.

### Why
You (or VS Code) created local files/folders that also exist on GitHub. Git doesn't know which to keep.

### Fix

```bash
# Remove ALL untracked files (safe — Git-tracked files are untouched)
git clean -fd .

# Now pull successfully
git pull origin main
```

### Nuclear Option (if nothing else works)
```bash
# WARNING: Deletes ALL local changes. Matches GitHub exactly.
git fetch origin
git reset --hard origin/main
```

---

## Issue 4: `No such file or directory` (generate_dataset.py)

### When This Happens
Running `python Python/generate_dataset.py` and file not found.

### Why
Either:
1. You're not in the project root directory
2. The file hasn't been pulled from GitHub yet (PR not merged)

### Fix

```bash
# Fix 1: Navigate to project root
cd C:\Users\Amit\Documents\Enterprise-Retail-Analytics-Platform

# Fix 2: Verify file exists
dir Python\generate_dataset.py

# Fix 3: If file doesn't exist, pull latest
git pull origin main
```

---

## Issue 5: venv Activation Fails

### When — Git Bash
Error: `.venv\Scripts\activate: No such file or directory`

**Fix:** Use forward slashes and `source`:
```bash
source .venv/Scripts/activate
```

### When — PowerShell
Error: `cannot be loaded because running scripts is disabled`

**Fix:** See [Issue 7](#issue-7-powershell-execution-policy) below.

### When — venv Deleted
Error: `.venv` folder doesn't exist

**Fix:** Recreate it:
```bash
python -m venv .venv
source .venv/Scripts/activate  # or .venv\Scripts\Activate.ps1
pip install -r Python/requirements.txt
```

---

## Issue 6: SSMS Connection Failed

### When This Happens
Clicking "Connect" in SSMS and getting timeout/error.

### Why
Either SQL Server service isn't running, or wrong server name used.

### Fix

```powershell
# Step 1: Check if service is running
Get-Service | Where-Object {$_.Name -like '*SQL*'}

# Step 2: Start if stopped
Start-Service MSSQLSERVER
# OR for Express:
Start-Service 'MSSQL$SQLEXPRESS'

# Step 3: Try these server names in SSMS:
# localhost
# .\SQLEXPRESS
# (localdb)\MSSQLLocalDB
```

---

## Issue 7: PowerShell Execution Policy

### When This Happens
Running `.venv\Scripts\Activate.ps1` in PowerShell.

Error: `cannot be loaded because running scripts is disabled on this system`

### Why
Windows PowerShell blocks unsigned scripts by default (security feature).

### Fix

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Type `Y` when prompted. Then try activation again.

---

## Prevention Tips

| Tip | Avoids |
|-----|--------|
| Always activate venv before installing packages | "No module" errors |
| Always `cd` to project root before running scripts | "File not found" errors |
| Use `python -m pytest` not `pytest` | Command not found |
| Pull before starting work each day | Merge conflicts |
| Use PowerShell (not Git Bash) for Python work | Path/activation issues |

---

*Next Guide: [09_Phase_Summary.md](./09_Phase_Summary.md)*
