# 00 — Project Overview

## Enterprise Retail Analytics Platform — The Big Picture

---

## What Is This Project?

This is an **end-to-end Enterprise Business Intelligence (BI) project** that demonstrates how Fortune 500 companies (like Walmart, Amazon, Target) build analytics platforms.

---

## The Story (Business Scenario)

**NovaMart Retail** is a simulated multi-channel retailer:
- 120+ physical stores across 35 US states
- E-commerce platform generating 40% of revenue
- 5,000+ employees
- $2.5 Billion annual revenue

Management wants a **centralized analytics platform** to make better decisions.

---

## How Everything Connects

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PROJECT FLOW                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [Python Script]  ──generates──▶  [12 CSV Files]                   │
│  generate_dataset.py               Dataset/ folder                  │
│                                                                     │
│         │                              │                            │
│         │                              ▼                            │
│         │                                                           │
│         │                     [SQL Server Database]                  │
│         │                     RetailDW                               │
│         │                     ├── Landing (raw)                     │
│         │                     ├── Staging (cleaned)                 │
│         │                     └── Warehouse (Star Schema)           │
│         │                              │                            │
│         │                              ▼                            │
│         │                                                           │
│         │                     [Power BI]                            │
│         │                     ├── Data Model                        │
│         │                     ├── DAX Measures (100+)               │
│         │                     └── Dashboards (9)                    │
│         │                              │                            │
│         │                              ▼                            │
│         │                                                           │
│         │                     [Power BI Service]                    │
│         │                     ├── Workspace                         │
│         │                     ├── Scheduled Refresh                 │
│         │                     └── Row-Level Security                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack — Why Each Tool?

| Tool | Role in Project | Why This Tool? |
|------|----------------|----------------|
| **Python** | Generate fake but realistic data | Flexible, powerful for data manipulation |
| **CSV Files** | Raw data format | Universal, every system can read/write |
| **SQL Server** | Store and transform data | Enterprise standard, free Developer edition |
| **SSMS** | Run SQL scripts visually | Microsoft's official GUI for SQL Server |
| **Power BI** | Create dashboards | Industry leader for BI visualization |
| **DAX** | Business calculations | Power BI's formula language |
| **Git/GitHub** | Version control & collaboration | Industry standard for code management |
| **VS Code** | Write code | Free, extensible, Git-integrated |
| **pytest** | Validate data quality | Python standard for automated testing |

---

## Project Phases (14 Total)

| Phase | Name | What Happens | Output |
|-------|------|-------------|--------|
| 1 | Business Understanding | Define KPIs, requirements, stakeholders | BRD document |
| 2 | Dataset Selection | Design & generate synthetic data | 12 CSV files + tests |
| 3 | Database Design | Create SQL Server tables (3 layers) | DDL scripts |
| 4 | Data Cleaning | Fix quality issues in staging | ETL scripts |
| 5 | Data Warehouse | Build Star Schema (Facts + Dims) | DML scripts |
| 6 | Power BI Model | Connect & design semantic model | .pbix file |
| 7 | Advanced DAX | 100+ business measures | DAX documentation |
| 8 | Dashboards | 9 interactive reports | Power BI pages |
| 9 | Deployment | Publish to Power BI Service | Live dashboards |
| 10 | Security | Row-Level Security (RLS) | Role definitions |
| 11 | Optimization | Performance tuning | Before/after metrics |
| 12 | Documentation | Full docs suite | TDD, User Guide |
| 13 | GitHub Repo | Clean, professional repository | Portfolio-ready |
| 14 | Interview Prep | Q&A for each phase | Study material |

---

## Folder Structure

```
Enterprise-Retail-Analytics-Platform/
│
├── Guides/                 ← YOU ARE HERE (step-by-step guides)
├── Dataset/                ← Generated CSV data (git-ignored)
├── Python/                 ← Data generation scripts
├── SQL/                    ← Database scripts (Landing/Staging/Warehouse)
├── Power BI/               ← Report files
├── DAX/                    ← DAX measures documentation
├── Documentation/          ← Formal documents (BRD, TDD)
├── tests/                  ← Automated validation tests
├── Architecture/           ← Diagrams
├── Images/                 ← Screenshots
└── Dashboard Screenshots/  ← Final dashboard images
```

---

## Key Concept: Three-Layer Architecture

```
LANDING (Raw)        →  Exact copy of source CSV, no changes
STAGING (Cleaned)    →  Duplicates removed, NULLs handled, dates validated
WAREHOUSE (Star)     →  Facts (metrics) + Dimensions (context) = Ready for BI
```

**Why 3 layers?**
- If something goes wrong, we can trace back to the raw data
- Each layer has a clear responsibility
- Enterprise standard practice (used at every Fortune 500)

---

## Key Concept: Star Schema

```
                    ┌──────────┐
                    │ DimDate  │
                    └────┬─────┘
                         │
┌──────────┐    ┌────────┴────────┐    ┌───────────┐
│DimProduct│────│   FactSales     │────│DimCustomer│
└──────────┘    └────────┬────────┘    └───────────┘
                         │
                    ┌────┴─────┐
                    │ DimStore │
                    └──────────┘
```

**FactSales** = "What happened" (orders, revenue, quantity)
**Dim tables** = "Context" (who bought, what product, when, where)

---

## Interview Significance

This project demonstrates:
- ✅ Business understanding (not just technical skills)
- ✅ End-to-end delivery (source → warehouse → dashboard)
- ✅ Enterprise practices (3-layer architecture, RLS, documentation)
- ✅ Data quality mindset (tests, defect handling)
- ✅ Scale (500K+ orders, not toy datasets)
- ✅ Professional Git workflow (branches, PRs, commits)

---

*Next Guide: [01_Environment_Setup.md](./01_Environment_Setup.md)*
