# 10 — Issues Resolution Log

## Environment Validation & Defect Resolution Register

---

| Document Control | Details |
|-----------------|---------|
| **Document ID** | LOG-ISSUES-2026-001 |
| **Version** | 1.0 |
| **Author** | BI Development Team |
| **Last Updated** | July 20, 2026 |
| **Purpose** | Track all issues encountered during setup, root cause, and resolution |
| **Audience** | Developers, QA, Future team members |

---

## Summary Dashboard

| Metric | Value |
|--------|-------|
| Total Issues Logged | 9 |
| Resolved | 9 |
| Open | 0 |
| Categories | Environment (4), Git (3), Encoding (1), Naming (1) |
| Severity Breakdown | Critical: 2, Major: 4, Minor: 3 |

---

## Issue Register

### ISS-001: Python Command Not Found

| Field | Details |
|-------|---------|
| **ID** | ISS-001 |
| **Severity** | Critical |
| **Category** | Environment Setup |
| **Phase** | Phase 2 — Dataset Generation |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved |

**Symptom:**
```
bash: python: command not found
```

**Root Cause:**
Python was not added to system PATH during installation. Windows does not automatically make Python accessible from all terminals.

**Resolution:**
Reinstall Python with ✅ "Add Python to PATH" checked at the bottom of the installer's first screen.

**Verification:**
```powershell
python --version
# Expected: Python 3.10+ 
```

**Prevention:**
Always check "Add to PATH" during Python installation. Document this in onboarding guide.

---

### ISS-002: `pytest: command not found`

| Field | Details |
|-------|---------|
| **ID** | ISS-002 |
| **Severity** | Major |
| **Category** | Environment Setup |
| **Phase** | Phase 2 — Data Quality Testing |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved |

**Symptom:**
```
bash: pytest: command not found
```

**Root Cause:**
`pytest` executable was not in the terminal's PATH. This happens when:
1. Virtual environment is not activated
2. pytest is installed in venv but PATH doesn't include venv's Scripts folder

**Resolution:**
Use `python -m pytest` instead of bare `pytest` command:
```bash
python -m pytest tests/test_data_quality.py -v
```

**Why This Works:**
`python -m` tells Python directly to find and run the pytest module — bypasses PATH entirely.

**Prevention:**
Always use `python -m pytest` pattern. Never rely on bare `pytest` command.

---

### ISS-003: `No module named pytest`

| Field | Details |
|-------|---------|
| **ID** | ISS-003 |
| **Severity** | Major |
| **Category** | Environment Setup |
| **Phase** | Phase 2 — Data Quality Testing |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved |

**Symptom:**
```
ModuleNotFoundError: No module named pytest
```

**Root Cause:**
pytest was not installed in the active Python environment. Packages were either:
1. Never installed, or
2. Installed in system Python but venv was active (or vice versa)

**Resolution:**
```bash
# Activate venv first
source .venv/Scripts/activate   # Git Bash
# OR
.venv\Scripts\Activate.ps1      # PowerShell

# Then install
pip install numpy pandas faker pytest
```

**Prevention:**
Always activate venv before installing or running anything. Look for `(.venv)` in terminal prompt.

---

### ISS-004: Git Pull Conflict — "Please move or remove files"

| Field | Details |
|-------|---------|
| **ID** | ISS-004 |
| **Severity** | Critical |
| **Category** | Git / Version Control |
| **Phase** | Phase 2 — Repository Sync |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved |

**Symptom:**
```
error: The following untracked working tree files would be overwritten by merge:
SQL/Landing/.gitkeep
SQL/Staging/.gitkeep
Dataset/.gitkeep
Python/.gitkeep
.gitignore
Please move or remove them before you merge.
Aborting
```

**Root Cause:**
Local machine had manually created folders/files (SQL/, Dataset/, Python/, .gitignore) that also existed in the remote branch. Git refuses to overwrite untracked local files with remote content.

**Resolution:**
```bash
# Remove all untracked files in project
git clean -fd .

# Then pull successfully
git pull origin main
```

**Alternative (Nuclear option):**
```bash
git fetch origin
git reset --hard origin/main
```

**Prevention:**
- Never manually create files that will come from GitHub
- Always `git pull` before creating local files
- If cloning a fresh repo, don't modify until first pull is done

---

### ISS-005: venv Activation Failed in Git Bash

| Field | Details |
|-------|---------|
| **ID** | ISS-005 |
| **Severity** | Major |
| **Category** | Environment Setup |
| **Phase** | Phase 2 — Python Environment |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved |

**Symptom:**
```
bash: .venv\Scripts\activate: No such file or directory
```

**Root Cause:**
Git Bash uses Unix-style paths (forward slashes `/`), but the command used Windows-style backslashes `\`. Also, Git Bash requires `source` command for activation scripts.

**Resolution:**
```bash
# Git Bash (Unix-style):
source .venv/Scripts/activate

# PowerShell (Windows-style):
.venv\Scripts\Activate.ps1

# CMD:
.venv\Scripts\activate.bat
```

**Prevention:**
- Use **PowerShell** as default terminal for Python projects on Windows
- If using Git Bash, always use forward slashes and `source` command
- Document both methods in setup guide

---

### ISS-006: `generate_dataset.py` — File Not Found

| Field | Details |
|-------|---------|
| **ID** | ISS-006 |
| **Severity** | Major |
| **Category** | Git / Version Control |
| **Phase** | Phase 2 — Dataset Generation |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved |

**Symptom:**
```
can't open file 'C:\Users\Amit\Documents\Enterprise-Retail-Analytics-Platform\Python\generate_dataset.py': 
[Errno 2] No such file or directory
```

**Root Cause:**
The file `generate_dataset.py` was on the `feat/dataset-generator` branch on GitHub. The PR had not been merged yet, so `main` branch (which user was on locally) didn't have this file.

**Resolution:**
1. Merge PR #1 on GitHub (browser)
2. Then pull locally:
```bash
git pull origin main
```

**Prevention:**
- Always merge PRs before expecting their files locally
- Understand that files on feature branches don't appear on `main` until merged

---

### ISS-007: `git clean -fd .` Deleted .venv

| Field | Details |
|-------|---------|
| **ID** | ISS-007 |
| **Severity** | Minor |
| **Category** | Git / Version Control |
| **Phase** | Phase 2 — Repository Sync |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved |

**Symptom:**
After running `git clean -fd .`, the `.venv` folder was deleted along with all installed packages:
```
Removing .venv/Scripts/pytest.exe
Removing .venv/Scripts/python.exe
Removing .venv/Lib/
```

**Root Cause:**
`git clean -fd .` removes ALL untracked files and directories. Since `.venv/` is in `.gitignore` (untracked by Git), it gets deleted too.

**Resolution:**
Recreate venv after the clean:
```bash
python -m venv .venv
source .venv/Scripts/activate
pip install numpy pandas faker pytest
```

**Prevention:**
- Before running `git clean -fd .`, consider using specific paths: `git clean -fd SQL/` (only clean SQL folder)
- Or use `git clean -fd -e .venv` to exclude venv from cleaning
- Add `.venv` awareness to troubleshooting docs

---

### ISS-008: UnicodeDecodeError — charmap Codec

| Field | Details |
|-------|---------|
| **ID** | ISS-008 |
| **Severity** | Major |
| **Category** | Encoding / Data |
| **Phase** | Phase 2 — Data Quality Testing |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved (PR #4) |

**Symptom:**
```
UnicodeDecodeError: 'charmap' codec can't encode character '\u2192' 
in position 8: character maps to <undefined>
FAILED tests/test_data_quality.py::TestDefectInjection::test_def05_inconsistent_casing
```

Test result: **67 passed, 1 failed**

**Root Cause:**
On Windows, Python defaults to `cp1252` encoding when reading/writing files. The `faker` library generated company names/addresses containing Unicode characters (arrows →, em-dashes —, accented letters) that `cp1252` cannot represent.

When pytest read the CSV files, it used the default Windows encoding which couldn't decode these characters.

**Resolution (Permanent — PR #4):**
Added `encoding='utf-8'` to ALL file operations:

Generator (`generate_dataset.py`):
```python
# Before (broken on Windows):
df.to_csv(self.output_dir / "suppliers.csv", index=False)

# After (works everywhere):
df.to_csv(self.output_dir / "suppliers.csv", index=False, encoding="utf-8")
```

Tests (`test_data_quality.py`):
```python
# Before:
pd.read_csv(DATASET_DIR / "suppliers.csv")

# After:
pd.read_csv(DATASET_DIR / "suppliers.csv", encoding="utf-8")
```

**Temporary Workaround (environment variable):**
```powershell
$env:PYTHONUTF8="1"
python -m pytest tests/test_data_quality.py -v
```

**Prevention:**
- ALWAYS specify `encoding='utf-8'` in all file I/O operations
- Never rely on system default encoding (varies by OS)
- Enterprise standard: UTF-8 everywhere

---

### ISS-009: Naming Inconsistency — HPE vs NovaMart vs ShopStar

| Field | Details |
|-------|---------|
| **ID** | ISS-009 |
| **Severity** | Minor |
| **Category** | Documentation / Naming |
| **Phase** | Phase 2 — Documentation |
| **Reported** | Day 1 |
| **Status** | ✅ Resolved (PR #4 + manual fix) |

**Symptom:**
GitHub Copilot flagged:
```
Naming inconsistency: README.md says "HPE Retail Division", 
but the BRD and the generator both use "NovaMart Retail". 
The README should be corrected to NovaMart for consistency.
```

Later, user chose "ShopStar" as the company name.

**Root Cause:**
- Phase 1 originally used "HPE" as the company name
- Phase 2 (PR #1) renamed to "NovaMart" in BRD and generator
- README.md was partially updated but some HPE references remained
- User later chose "ShopStar" as their preferred name

**Resolution:**
Global find-and-replace across all files:
1. `Ctrl+Shift+H` in VS Code (Global Find & Replace)
2. Replace `NovaMart Retail` → `ShopStar Retail`
3. Replace `NovaMart` → `ShopStar`
4. Replace `HPE Retail Division` → `ShopStar Retail`
5. Replace `HPE` → `ShopStar`
6. Replace `novamart.com` → `shopstar.com`

**Prevention:**
- Define the company name ONCE in a config/constant
- Reference it from all documents
- Run consistency checks before merging PRs
- Use Git grep to find all occurrences: `git grep -i "NovaMart"`

---

## Lessons Learned

| # | Lesson | Applied To |
|---|--------|-----------|
| 1 | Always add Python to PATH during installation | Guide 01 |
| 2 | Use `python -m pytest` not bare `pytest` | Guide 05 |
| 3 | Activate venv before ANY pip/python command | Guide 03 |
| 4 | Merge PRs before expecting files locally | Guide 02 |
| 5 | Use PowerShell (not Git Bash) for Python on Windows | Guide 07 |
| 6 | Always specify `encoding='utf-8'` in file I/O | Generator + Tests |
| 7 | `git clean -fd .` deletes venv — be careful | Guide 08 |
| 8 | Define naming conventions early and enforce globally | BRD Section |
| 9 | PRs create a clear audit trail of all changes | Git Workflow |

---

## Resolution Metrics

| Metric | Value |
|--------|-------|
| Average time to resolve | < 15 minutes |
| Issues requiring code change | 2 (ISS-008, ISS-009) |
| Issues requiring environment fix only | 5 |
| Issues requiring Git knowledge | 3 |
| PRs created for fixes | 1 (PR #4) |

---

*This document will be updated as new issues are encountered in future phases.*
