# 01 — Environment Setup

## Complete Machine Setup from Scratch

---

## What This Guide Covers

Everything you need to install on a **fresh Windows machine** to work on this project.

**Total time:** ~45 minutes (mostly download/install waiting)

---

## Step 1: Install Python 3.10+

### What
Python is the programming language we use to generate synthetic retail data.

### Why
Our `generate_dataset.py` script needs Python to run. It uses libraries like `pandas` (data tables) and `faker` (fake names/emails).

### When
Once — during initial machine setup.

### How

1. **Download:** https://www.python.org/downloads/
2. **Run installer**
3. **CRITICAL:** Check ✅ **"Add Python to PATH"** at the bottom of the first screen
4. Choose **"Install Now"** (default path is fine)
5. Wait for installation to complete
6. Click **"Close"**

### Verify

Open any terminal (PowerShell/CMD):
```powershell
python --version
```

**Expected:**
```
Python 3.12.x  (or any 3.10+)
```

### If `python` Not Found (Troubleshooting)

```
Cause: PATH not set during installation
Fix: Uninstall Python → Reinstall → CHECK "Add to PATH" this time
```

---

## Step 2: Install Git

### What
Git is a version control system — it tracks all changes to your code and syncs with GitHub.

### Why
- Download project code from GitHub
- Track your changes
- Collaborate with team
- Create branches and PRs

### When
Once — during initial setup.

### How

1. **Download:** https://git-scm.com/download/win
2. **Run installer**
3. **Most defaults are fine**, but when asked:
   - Default editor: **VS Code** (if available in dropdown)
   - Branch naming: **main** (not master)
   - PATH: **"Git from the command line and also from 3rd-party software"**
4. Finish installation

### Verify

```powershell
git --version
```

**Expected:**
```
git version 2.45.x  (any 2.x is fine)
```

---

## Step 3: Install VS Code

### What
Visual Studio Code — our code editor where we write Python, SQL, view files, and run terminal commands.

### Why
- Free and lightweight
- Built-in terminal
- Git integration
- Extension marketplace (Python, SQL, Copilot)
- Industry standard for developers

### When
Once — during initial setup.

### How

1. **Download:** https://code.visualstudio.com/
2. **Run installer**
3. Check ✅ **"Add to PATH"** option
4. Check ✅ **"Register Code as an editor for supported file types"**
5. Finish installation

### Essential Extensions to Install

Open VS Code → `Ctrl+Shift+X` (Extensions panel) → Search & Install:

| Extension | Publisher | What It Does |
|-----------|----------|-------------|
| **Python** | Microsoft | Python syntax, IntelliSense, debugging |
| **GitLens** | GitKraken | See who changed what, git history |
| **SQL Server (mssql)** | Microsoft | SQL file editing |
| **Markdown Preview** | Microsoft (built-in) | Preview .md files |
| **GitHub Copilot** | GitHub | AI code assistant (needs subscription) |

---

## Step 4: Install SQL Server 2022 Developer Edition

### What
SQL Server is the database engine where we'll build our data warehouse (RetailDW).

### Why
- Enterprise standard (used by most Fortune 500 companies)
- Developer Edition is FREE and has ALL enterprise features
- SSMS provides visual management

### When
Once — during initial setup. Needed from Phase 3 onwards.

### How

1. **Download:** https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2. Choose **"Developer"** → Free edition (NOT Express — Developer has more features)
3. Run installer → Choose **"Basic"** installation type
4. Accept license → Choose install location (default fine) → Install
5. Wait ~10 minutes for download + install
6. Note the **Connection String** shown at the end

### Verify Service is Running

```powershell
Get-Service | Where-Object {$_.Name -like '*SQL*'} | Select-Object Name, Status
```

**Expected:**
```
Name            Status
----            ------
MSSQLSERVER     Running    ← This means server name = localhost
```

### If Service Not Running

```powershell
Start-Service MSSQLSERVER
```

---

## Step 5: Install SSMS (SQL Server Management Studio)

### What
SSMS is the GUI tool for SQL Server — like VS Code but specifically for databases.

### Why
- Write and execute SQL scripts visually
- Browse database objects (tables, views, stored procedures)
- Design and debug queries
- Test Row-Level Security

### When
Once — during initial setup.

### How

1. **Download:** https://learn.microsoft.com/en-us/ssms/download-sql-server-management-studio-ssms
2. Run installer → Next → Install → Finish
3. Open SSMS → "Connect to Server" dialog appears

### Connect to SQL Server

| Field | Value |
|-------|-------|
| Server type | Database Engine |
| Server name | `localhost` |
| Authentication | Windows Authentication |
| Click | **Connect** |

### If Connection Fails — Try These Server Names

| Try This | When |
|----------|------|
| `localhost` | Default instance (MSSQLSERVER service) |
| `.\SQLEXPRESS` | Express edition installed |
| `.\DEV` | Custom named instance |
| `(localdb)\MSSQLLocalDB` | LocalDB (minimal installation) |

### Success Looks Like

Left panel shows **Object Explorer** with:
```
📁 Databases
📁 Security
📁 Server Objects
📁 Replication
📁 Management
```

---

## Step 6: Create GitHub Account (If Not Done)

### What
GitHub hosts our code repository online.

### Why
- Portfolio showcase for interviews
- Backup of all code
- PR-based workflow (professional practice)
- Collaboration tool

### How
1. Go to https://github.com
2. Sign up with email
3. Choose free plan
4. Verify email

---

## Final Checklist

| # | Software | Installed? | Verify Command |
|---|----------|-----------|----------------|
| 1 | Python 3.10+ | ⬜ | `python --version` |
| 2 | Git | ⬜ | `git --version` |
| 3 | VS Code | ⬜ | `code --version` |
| 4 | SQL Server 2022 | ⬜ | `Get-Service MSSQLSERVER` |
| 5 | SSMS 22 | ⬜ | Open & connect to localhost |
| 6 | GitHub Account | ⬜ | Login at github.com |

---

## What's Next?

After all software is installed:
→ Go to [02_Git_And_GitHub_Workflow.md](./02_Git_And_GitHub_Workflow.md)

---

*Next Guide: [02_Git_And_GitHub_Workflow.md](./02_Git_And_GitHub_Workflow.md)*
