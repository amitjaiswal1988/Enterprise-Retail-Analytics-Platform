# 06 — SQL Server Setup

## Connecting and Configuring SQL Server for This Project

---

## What Is SQL Server?

The **database engine** where all our retail data lives after being cleaned.


## Why SQL Server (Not MySQL/PostgreSQL)?

| Reason | Explanation |
|--------|------------|
| Enterprise standard | Used by 70%+ of Fortune 500 BI teams |
| Power BI integration | Native DirectQuery + Import from SQL Server |
| Free Developer Edition | All enterprise features at no cost |
| SSMS tooling | Industry-best management GUI |
| Interview relevance | Most BI roles require SQL Server knowledge |

---

## Step 1: Verify SQL Server is Running

### What
Check that the database engine service is active on your machine.

### Why
SSMS is just a client (GUI) — it needs the engine running to connect.

### How (PowerShell)

```powershell
Get-Service | Where-Object {$_.Name -like '*SQL*'} | Select-Object Name, Status
```

### Expected Output

```
Name            Status
----            ------
MSSQLSERVER     Running    ← Default instance → server name = localhost
SQLBrowser      Running    ← Helps with named instances
SQLSERVERAGENT  Running    ← Job scheduler (optional)
```

### If Status = "Stopped"

```powershell
Start-Service MSSQLSERVER
```

---

## Step 2: Determine Your Server Name

| Service Running | Server Name to Use in SSMS |
|----------------|---------------------------|
| `MSSQLSERVER` | `localhost` |
| `MSSQL$SQLEXPRESS` | `.\SQLEXPRESS` |
| `MSSQL$DEV` | `.\DEV` |
| None of above | Try `(localdb)\MSSQLLocalDB` |

---

## Step 3: Connect via SSMS

1. Open **SQL Server Management Studio**
2. "Connect to Server" dialog:

| Field | Value |
|-------|-------|
| Server type | **Database Engine** |
| Server name | `localhost` (or your instance) |
| Authentication | **Windows Authentication** |

3. Click **Connect**

### Success
Left panel (Object Explorer) shows:
```
📁 localhost (SQL Server 17.x)
  📁 Databases
  📁 Security
  📁 Server Objects
  📁 Replication
  📁 Management
```

---

## Step 4: Create the RetailDW Database (Phase 3)

This will be done in Phase 3. Preview:

```sql
-- This script will come in Phase 3
CREATE DATABASE RetailDW;
GO
```

---

## Step 5: Understanding the 3-Layer Architecture

```
RetailDW Database
├── landing schema    → Raw data (exact CSV copy)
├── staging schema    → Cleaned data (defects fixed)
└── warehouse schema  → Star Schema (Facts + Dimensions)
```

| Layer | Purpose | Data Quality |
|-------|---------|-------------|
| **Landing** | Store raw CSV data as-is | Defects present (NULLs, dupes, bad dates) |
| **Staging** | Clean and validate | Defects fixed, business rules applied |
| **Warehouse** | Business-ready Star Schema | Perfect data for reporting |

---

## Copilot Prompts

```
@terminal Check if SQL Server service is running
@terminal Show all SQL Server related services and their status
```

---

*Next Guide: [07_VS_Code_And_Copilot.md](./07_VS_Code_And_Copilot.md)*
