# 11 — AI Prompt Playbook

## Complete Log of AI Prompts Used During Project Development

---

| Document Control | Details |
|-----------------|---------|
| **Document ID** | PLAY-PROMPTS-2026-001 |
| **Version** | 1.0 |
| **Author** | Amit Jaiswal |
| **Last Updated** | July 20, 2026 |
| **Purpose** | Track every AI prompt used, when, why, and the result |
| **Tools** | Kiro (Browser), GitHub Copilot (VS Code) |

---

## Why This Document Exists

1. **Reproducibility** — Any developer can follow these exact prompts to replicate the setup
2. **Learning** — Shows the thought process behind each AI interaction
3. **Interview** — Demonstrates AI-assisted development workflow
4. **Debugging** — If something breaks, trace back to which prompt caused it

---

## Prompt Categories

| Category | Icon | Description |
|----------|------|-------------|
| Setup | ⚙️ | Environment configuration, installs |
| Git | 🔀 | Version control operations |
| Data | 📊 | Dataset generation, validation |
| Fix | 🔧 | Error resolution, debugging |
| Docs | 📝 | Documentation updates |
| Rename | ✏️ | Naming/branding changes |

---

## Phase 1 — Business Understanding

### Prompt P-001: Project Kickoff (Kiro)

| Field | Details |
|-------|---------|
| **When** | Day 1, Session Start |
| **Tool** | Kiro (Browser) |
| **Category** | 📝 Docs |
| **What I Asked** | Full enterprise BI project prompt (14 phases, HPE scenario) |
| **What I Got** | Phase 1 business understanding, KPIs, BRD structure |
| **Result** | BRD document created, company background defined |

---

### Prompt P-002: Generate BRD (Kiro)

| Field | Details |
|-------|---------|
| **When** | Day 1, After Phase 1 review |
| **Tool** | Kiro (Browser) |
| **Category** | 📝 Docs |
| **What I Asked** | "1" (confirming to generate formal BRD) |
| **What I Got** | 400+ line Business Requirement Document + project folder structure |
| **Result** | `Documentation/Business_Requirement_Document_BRD.md` created |

---

## Phase 2 — Dataset Selection & Generation

### Prompt P-003: Push to GitHub (Kiro)

| Field | Details |
|-------|---------|
| **When** | Day 1, After BRD creation |
| **Tool** | Kiro (Browser) |
| **Category** | 🔀 Git |
| **What I Asked** | "i want to keep all above detail in Github" |
| **What I Got** | Repo name suggestions, setup instructions |
| **Result** | GitHub repo `Enterprise-Retail-Analytics-Platform` created, initial push done |

---

### Prompt P-004: Dataset Generator Branch (Kiro)

| Field | Details |
|-------|---------|
| **When** | Day 1, After repo setup |
| **Tool** | Kiro (Browser) |
| **Category** | 📊 Data |
| **What I Asked** | Proceed with dataset generator on feat/dataset-generator branch, .gitignore, tests |
| **What I Got** | Complete generator (653 lines), 68 tests, .gitignore, Data Gen Spec doc |
| **Result** | PR #1 created and merged |

---

### Prompt P-005: pip upgrade (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, Local setup |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | ⚙️ Setup |
| **Prompt** | `@terminal python -m pip install --upgrade pip` |
| **Result** | pip upgraded successfully |

---

### Prompt P-006: Install packages (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After venv creation |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | ⚙️ Setup |
| **Prompt** | `@terminal pip install numpy pandas faker pytest` |
| **Result** | All packages installed in .venv |

---

### Prompt P-007: Merge PR on GitHub (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After PR #1 review |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 🔀 Git |
| **Prompt** | `@terminal merge the open PR on GitHub` |
| **Result** | Copilot gave link, merged manually on GitHub |

---

### Prompt P-008: Pull latest from main (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After merge |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 🔀 Git |
| **Prompt** | `@terminal pull latest from main` |
| **Result** | ⚠️ Failed — "Please move or remove files before merge" |

---

### Prompt P-009: Fix git conflict (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After pull failure |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 🔧 Fix |
| **Prompt** | `@terminal git clean -fd . && git pull origin main` |
| **Result** | ⚠️ Partially worked — cleaned SQL/ but .gitignore, Dataset/ still conflicting |

---

### Prompt P-010: Clean ALL untracked files (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, Second attempt |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 🔧 Fix |
| **Prompt** | `@terminal git clean -fd .` then `@terminal git pull origin main` |
| **Result** | ⚠️ Cleaned everything including .venv! Had to recreate venv |

---

### Prompt P-011: Recreate venv (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After .venv deleted |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | ⚙️ Setup |
| **Prompt** | `@terminal Create a new Python virtual environment and install required packages: 1. rm -rf .venv 2. python -m venv .venv 3. source .venv/Scripts/activate 4. pip install numpy pandas faker pytest` |
| **Result** | ✅ venv recreated, packages installed |

---

### Prompt P-012: Generate dataset (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After venv ready |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 📊 Data |
| **Prompt** | `@terminal python Python/generate_dataset.py --profile development` |
| **Result** | ✅ 12 CSV files generated successfully |

---

### Prompt P-013: Run tests (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After dataset generation |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 📊 Data |
| **Prompt** | `@terminal python -m pytest tests/test_data_quality.py -v` |
| **Result** | ⚠️ 67 passed, 1 failed (UnicodeDecodeError: charmap codec) |

---

### Prompt P-014: Fix encoding error (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After test failure |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 🔧 Fix |
| **Prompt** | `@terminal Set UTF-8 encoding for Python and then run the tests again` |
| **Result** | Copilot suggested `export PYTHONUTF8=1` — ⚠️ Failed (bash command in PowerShell) |

---

### Prompt P-015: Fix encoding PowerShell (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, Second encoding attempt |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 🔧 Fix |
| **Prompt** | `@terminal $env:PYTHONUTF8="1"; python -m pytest tests/test_data_quality.py -v` |
| **Result** | ⚠️ Test still failed — needed code fix (PR #4), not just env variable |

---

### Prompt P-016: Rename NovaMart to ShopStar (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After company name decision |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | ✏️ Rename |
| **Prompt** | `@workspace In README.md, replace all occurrences of "NovaMart Retail" with "ShopStar Retail"...` |
| **Result** | ✅ Copilot renamed in files |

---

### Prompt P-017: Discard local + pull fix (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, After PR #4 merge |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 🔀 Git |
| **Prompt** | `@terminal Discard local changes and pull from remote: git checkout -- . && git pull origin main` |
| **Result** | ✅ 14 files pulled successfully, all PRs merged |

---

### Prompt P-018: Complete Phase 2 — All-in-One (Copilot — VS Code)

| Field | Details |
|-------|---------|
| **When** | Day 1, Final Phase 2 step |
| **Tool** | GitHub Copilot (VS Code) |
| **Category** | 📊 Data + ✏️ Rename + 🔀 Git |
| **Prompt** | See below |
| **Result** | ✅ Pending execution |

**Full Prompt:**
```powershell
(Get-Content README.md) -replace 'NovaMart Retail','ShopStar Retail' -replace 'NovaMart','ShopStar' -replace 'novamart.com','shopstar.com' | Set-Content README.md
(Get-Content "Documentation/Business_Requirement_Document_BRD.md") -replace 'NovaMart Retail','ShopStar Retail' -replace 'NovaMart','ShopStar' -replace 'novamart.com','shopstar.com' | Set-Content "Documentation/Business_Requirement_Document_BRD.md"
Remove-Item Dataset\*.csv -ErrorAction SilentlyContinue
python Python/generate_dataset.py --profile development
python -m pytest tests/test_data_quality.py -v
git add -A
git commit -m "fix: complete ShopStar rename - Phase 2 done"
git push origin main
```

---

## Phase 3-5 — Database, ETL & Warehouse (GitHub Copilot Agent, VS Code)

### Prompt P-019: Build Database Schema & Tables

| Field | Details |
|-------|---------|
| **When** | Day 2, Start of Phase 3 |
| **Tool** | GitHub Copilot (VS Code, Agent) |
| **Category** | 📊 Data |
| **Prompt** | "Create the RetailDW database with landing/staging/warehouse schemas and all DDL (landing, staging, star-schema dims + facts, indexes, FKs)" |
| **Result** | ✅ Scripts 00–05 created; landing 12 / staging 13 / warehouse 11 tables verified |

---

### Prompt P-020: Load CSVs into Landing (Python)

| Field | Details |
|-------|---------|
| **When** | Day 2, Phase 4 start |
| **Tool** | GitHub Copilot (VS Code, Agent) |
| **Category** | 📊 Data |
| **Prompt** | "Write a Python bulk loader for the 12 CSVs into landing.* using pandas + SQLAlchemy + pyodbc, idempotent" |
| **Result** | ✅ `Python/load_landing.py` — 705,984 rows in ~30s |

---

### Prompt P-021: Staging ETL + Fix Bugs

| Field | Details |
|-------|---------|
| **When** | Day 2, Phase 4 |
| **Tool** | GitHub Copilot (VS Code, Agent) |
| **Category** | 🔧 Fix + 📊 Data |
| **Prompt** | "please check from github and fix fast and start next step, if you are writing query then create documents when/why/what mode with comments, everything I want in documented, as your are BI engineer and analytics" |
| **Result** | ✅ 12 staging procs; fixed ISS-010 (@@ROWCOUNT) & ISS-011 (Quarantine); 705,735 staging rows. Commit `8b70dea` |

---

### Prompt P-022: Warehouse Star-Schema ETL

| Field | Details |
|-------|---------|
| **When** | Day 2, Phase 5 |
| **Tool** | GitHub Copilot (VS Code, Agent) |
| **Category** | 📊 Data + 🔧 Fix |
| **Prompt** | "yes" (approval to build warehouse-load procedures) |
| **Result** | ✅ `07_ETL_Staging_To_Warehouse.sql` (DimDate + 7 dims + 3 facts). Caught & fixed ISS-012 (nullable-int float bug). Revenue $720M. Commit `1031b1b` |

---

### Prompt P-023: Analytics Views

| Field | Details |
|-------|---------|
| **When** | Day 2, Phase 5 |
| **Tool** | GitHub Copilot (VS Code, Agent) |
| **Category** | 📊 Data + 📝 Docs |
| **Prompt** | "yes" (approval to build the SQL analytics views) |
| **Result** | ✅ `08_Analytics_Views.sql` — 10 views mapped to 9 dashboards + `Phase3_Analytics_Views.md`. Commit `10f10aa` |

---

### Prompt P-024: Project Rules & Doc Sync

| Field | Details |
|-------|---------|
| **When** | Day 2, After Phase 5 |
| **Tool** | GitHub Copilot (VS Code, Agent) |
| **Category** | 📝 Docs |
| **Prompt** | "IMPORTANT RULES FOR ALL FUTURE WORK... parallel documentation, comments on every SQL line, phase status, git discipline, Power BI flow. Update README now." |
| **Result** | ✅ README phases 3/4/5 → Complete; Guides 09/10/11 updated; pushed to GitHub |

---

## Prompt Success Rate

| Category | Total | Succeeded | Failed | Success Rate |
|----------|-------|-----------|--------|-------------|
| ⚙️ Setup | 3 | 3 | 0 | 100% |
| 🔀 Git | 5 | 3 | 2 | 60% |
| 📊 Data | 3 | 2 | 1 | 67% |
| 🔧 Fix | 3 | 1 | 2 | 33% |
| ✏️ Rename | 2 | 2 | 0 | 100% |
| 📝 Docs | 2 | 2 | 0 | 100% |
| **Total** | **18** | **13** | **5** | **72%** |

---

## Key Learnings from Prompts

| # | Learning | Applies To |
|---|---------|-----------|
| 1 | `export` doesn't work in PowerShell — use `$env:VAR="value"` | P-014 |
| 2 | `git clean -fd .` is too aggressive — also deletes .venv | P-010 |
| 3 | Code fix (PR) > environment variable workaround | P-015 |
| 4 | Always merge PRs BEFORE `git pull` on local | P-008 |
| 5 | Copilot needs terminal type context ("in PowerShell...") | P-014 |
| 6 | Multi-step prompts work better with numbered lists | P-018 |
| 7 | `@workspace` for file edits, `@terminal` for commands | P-016 |

---

### Prompt P-025: 100 SQL Queries + Views + Power BI Guide

| Field | Details |
|-------|---------|
| **When** | Phase 5.5 — interview-prep + Power BI readiness |
| **Tool** | GitHub Copilot |
| **Category** | 📊 Data / 📝 Docs |
| **Prompt** | `add 100 SQL practice queries + 15 analytics views + Power BI implementation guide` |
| **Result** | ✅ Success — SQL_100_Queries_Portfolio.sql (100 queries, validated EXIT=0), 07_Analytics_Views.sql (15 views live), PowerBI_Implementation_Guide.md, SQL_Practice_Guide.md. Fixed Q08 (PERCENTILE_CONT window fn cannot mix with scalar aggregates — isolated median in a subquery). |

---

### Prompt P-026: Complete Power BI Implementation (Phase 6-7)

| Field | Details |
|-------|---------|
| **When** | Day 3 — Phase 6-7 (Power BI Data Model + Advanced DAX) |
| **Tool** | GitHub Copilot (VS Code, Agent) |
| **Category** | 📊 Data / 📝 Docs |
| **Prompt** | "As Senior BI Engineer, create the COMPLETE Power BI implementation for RetailDW — 100 DAX measures (5 files), Power Query M code, Power BI Service guide, Data Modeling best practices; every line commented WHAT/WHY/WHEN; all 15 BRD KPIs with RAG vs targets." |
| **Result** | ✅ Success — 100 DAX measures (25+15+20+20+20) matched to exact `warehouse.*` columns; `PowerQuery_M_Code_Complete.md`; `PowerBI_Service_Complete_Guide.md`; `Data_Modeling_Best_Practices.md`; README + Phase Summary updated. |

---

## Template for Future Prompts

```markdown
### Prompt P-XXX: [Short Description]

| Field | Details |
|-------|---------|
| **When** | [Phase, Day, Context] |
| **Tool** | [Kiro / GitHub Copilot / Manual] |
| **Category** | [⚙️/🔀/📊/🔧/✏️/📝] |
| **Prompt** | `actual prompt text` |
| **Result** | ✅ Success / ⚠️ Partial / ❌ Failed — [details] |
```

---

*This document will be updated as new prompts are used in subsequent phases.*
