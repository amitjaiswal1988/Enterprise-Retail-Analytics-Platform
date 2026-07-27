# Project Documentation Index

> **Audience:** Anyone new to the ShopStar Retail Analytics Platform — a recruiter, an interviewer, a new team member, or your future self.
>
> **Purpose:** A single master map of every document in the project — what it is, who it is for, and where it fits. Start here, then jump to whatever you need.
>
> **Legend:** Phase = which project phase the document belongs to. Lines = approximate size.

---

## How to use this index

1. **Recruiter / interviewer (10 minutes):** Read the [README](../README.md), then the [Dashboard Presentation Guide](Dashboard_Presentation_Guide.md) (or the deeper [Dashboard Complete Explanation](Dashboard_Complete_Explanation.md)), then the [Interview Preparation Guide](Interview_Preparation_Complete_Guide.md).
2. **New developer setting up (1 hour):** Follow [Developer Setup Guide](Developer_Setup_Guide.md) → [Guides/01–06](../Guides/) in order.
3. **Reviewer checking the build:** Read the [Technical Design Document](Technical_Design_Document_Phase3.md) → [Data Modeling Best Practices](Data_Modeling_Best_Practices.md) → the SQL and Power BI folders.

---

## Category 1 — Business Documents

For business stakeholders and analysts: what the platform is for and what it found.

| Document | Purpose | Audience | Lines | Phase |
|----------|---------|----------|-------|-------|
| [Business_Requirement_Document_BRD.md](Business_Requirement_Document_BRD.md) | The full business requirements — goals, KPIs, scope, stakeholders. | Business + BI leads | 619 | 1 |
| [Business_Insights_Report.md](Business_Insights_Report.md) | Key findings from the data (revenue, margin, regions, returns). | Executives, analysts | 147 | 8 |
| [Dashboard_Specifications.md](Dashboard_Specifications.md) | The design spec for each of the 9 dashboards. | BI developers | 152 | 8 |
| [Dashboard_Presentation_Guide.md](Dashboard_Presentation_Guide.md) | How to present each dashboard to a VP/CEO (WHO/WHAT/WHY/WHEN + scripts + Q&A). | Presenter / job candidate | 492 | 8 |
| [Dashboard_Complete_Explanation.md](Dashboard_Complete_Explanation.md) | Full 9-page explanation — problem, layout, chart reasoning, script, insights, Q&A, build. | Presenter / job candidate | 729 | 14 |
| [Documentation_Audit_Report.md](Documentation_Audit_Report.md) | Audit of every doc/SQL/DAX file for WHAT/WHY/WHEN + comments. | Reviewer / architect | 179 | 14 |

---

## Category 2 — Technical Documents

For engineers: how the warehouse and model are built.

| Document | Purpose | Audience | Lines | Phase |
|----------|---------|----------|-------|-------|
| [Technical_Design_Document_Phase3.md](Technical_Design_Document_Phase3.md) | The technical design of the warehouse (schema, ETL, decisions). | Engineers | 265 | 3–5 |
| [Data_Generation_Spec.md](Data_Generation_Spec.md) | How synthetic data is generated + the catalog of intentional defects. | Data engineers | 281 | 2 |
| [Data_Modeling_Best_Practices.md](Data_Modeling_Best_Practices.md) | Star schema, cardinality, hierarchies, measure-table pattern. | Model designers | 322 | 6 |
| [Phase3_Warehouse_Load.md](Phase3_Warehouse_Load.md) | Log/notes of loading the warehouse. | Engineers | 125 | 5 |
| [Phase3_ETL_Run_Log.md](Phase3_ETL_Run_Log.md) | Record of ETL runs and results. | Engineers | 143 | 4 |
| [Phase3_Analytics_Views.md](Phase3_Analytics_Views.md) | The reporting/analytics SQL views. | Engineers, analysts | 114 | 5.5 |
| [Phase6_PowerBI_Semantic_Model.md](Phase6_PowerBI_Semantic_Model.md) | The Power BI semantic model design (tables, relationships). | BI developers | 127 | 6 |

---

## Category 3 — Power BI & Deployment

For BI developers taking the model from Desktop to production.

| Document | Purpose | Audience | Lines | Phase |
|----------|---------|----------|-------|-------|
| [PowerBI_Implementation_Guide.md](PowerBI_Implementation_Guide.md) | End-to-end: connect → model → RLS → tune. | BI developers | 394 | 6–7 |
| [PowerBI_Service_Complete_Guide.md](PowerBI_Service_Complete_Guide.md) | Deep reference for the Power BI Service. | BI developers | 415 | 9 |
| [PowerBI_Service_Deployment_Guide.md](PowerBI_Service_Deployment_Guide.md) | Publish, gateway, scheduled + incremental refresh, apps, alerts, pipelines. | BI developers | 253 | 9 |
| [Row_Level_Security_Guide.md](Row_Level_Security_Guide.md) | Static, dynamic, object-level, and hierarchical security. | BI developers | 185 | 10 |
| [Performance_Optimization_Guide.md](Performance_Optimization_Guide.md) | Tuning SQL → Power Query → model → DAX → visuals. | BI developers | 153 | 11 |
| [../Power BI/PowerQuery_M_Code_Complete.md](../Power%20BI/PowerQuery_M_Code_Complete.md) | The complete Power Query (M) ETL layer. | BI developers | — | 6 |

---

## Category 4 — Setup & Workflow Guides

Step-by-step guides in the `Guides/` folder for getting the environment running.

| Document | Purpose | Audience | Lines | Phase |
|----------|---------|----------|-------|-------|
| [../Guides/00_Project_Overview.md](../Guides/00_Project_Overview.md) | Big-picture overview of the whole project. | Everyone | 168 | 0 |
| [../Guides/01_Environment_Setup.md](../Guides/01_Environment_Setup.md) | Install and configure the tools. | New developer | 263 | 0 |
| [../Guides/02_Git_And_GitHub_Workflow.md](../Guides/02_Git_And_GitHub_Workflow.md) | Branching, commits, and GitHub workflow. | Developers | 355 | 0 |
| [../Guides/03_Python_Virtual_Environment.md](../Guides/03_Python_Virtual_Environment.md) | Setting up the Python `.venv`. | Developers | 239 | 2 |
| [../Guides/04_Dataset_Generation.md](../Guides/04_Dataset_Generation.md) | Running the data generator. | Developers | 145 | 2 |
| [../Guides/05_Data_Quality_Testing.md](../Guides/05_Data_Quality_Testing.md) | Running the pytest data-quality tests. | Developers, QA | 170 | 2 |
| [../Guides/06_SQL_Server_Setup.md](../Guides/06_SQL_Server_Setup.md) | Installing and configuring SQL Server. | Developers | 131 | 3 |
| [../Guides/07_VS_Code_And_Copilot.md](../Guides/07_VS_Code_And_Copilot.md) | VS Code + Copilot workflow. | Developers | 130 | 0 |
| [../Guides/08_Troubleshooting.md](../Guides/08_Troubleshooting.md) | Common problems and fixes. | Everyone | 215 | all |
| [../Guides/09_Phase_Summary.md](../Guides/09_Phase_Summary.md) | Summary of each phase. | Everyone | 243 | all |
| [../Guides/10_Issues_Resolution_Log.md](../Guides/10_Issues_Resolution_Log.md) | Log of real issues and how they were solved. | Developers | 562 | all |
| [Developer_Setup_Guide.md](Developer_Setup_Guide.md) | The complete developer onboarding guide. | New developer | 684 | 0 |

---

## Category 5 — Interview & Portfolio

For job preparation and showing the project off.

| Document | Purpose | Audience | Lines | Phase |
|----------|---------|----------|-------|-------|
| [Interview_Preparation_Complete_Guide.md](Interview_Preparation_Complete_Guide.md) | 50 interview questions across SQL, Power BI, business, and process. | Job candidate | — | 14 |
| [../Guides/11_AI_Prompt_Playbook.md](../Guides/11_AI_Prompt_Playbook.md) | Reusable AI prompts used to build the project. | Developers | 418 | all |
| [../Guides/12_Phase3_Interview_Guide.md](../Guides/12_Phase3_Interview_Guide.md) | Interview prep focused on the warehouse phase. | Job candidate | 517 | 3 |
| [../Guides/13_Phase3_SSMS_Execution_Guide.md](../Guides/13_Phase3_SSMS_Execution_Guide.md) | Running the SQL scripts in SSMS. | Developers | 473 | 3 |
| [../SQL/Practice/SQL_Practice_Guide.md](../SQL/Practice/SQL_Practice_Guide.md) | Guide to the 100 SQL practice queries. | Job candidate | 131 | 5.5 |
| [../Images/ShopStar_Brand_Guide.md](../Images/ShopStar_Brand_Guide.md) | Brand colors, logo, and theme rules. | Designers, BI devs | 81 | 8 |

---

## Document Dependency Map

Read documents in dependency order — each layer builds on the one before it.

```
                        ┌────────────────────────────┐
                        │  Business_Requirement (BRD) │   Phase 1: what the business needs
                        └──────────────┬──────────────┘
                                       ▼
                        ┌────────────────────────────┐
                        │   Data_Generation_Spec      │   Phase 2: source data + defects
                        └──────────────┬──────────────┘
                                       ▼
          ┌───────────────────────────────────────────────────────┐
          │ Technical_Design_Document → Phase3 ETL / Warehouse docs │   Phase 3–5: build warehouse
          └──────────────┬────────────────────────────────────────┘
                         ▼
          ┌───────────────────────────────────────────────┐
          │ Data_Modeling_Best_Practices → Phase6 Semantic  │   Phase 6: Power BI model
          │ Model → PowerQuery_M_Code_Complete              │
          └──────────────┬────────────────────────────────┘
                         ▼
          ┌───────────────────────────────────────────────┐
          │ Dashboard_Specifications → Business_Insights →  │   Phase 7–8: DAX + dashboards
          │ Dashboard_Presentation_Guide                    │
          └──────────────┬────────────────────────────────┘
                         ▼
   ┌──────────────────────────────────────────────────────────────┐
   │ Service Deployment → Row-Level Security → Performance Optimize │   Phase 9–11: production
   └──────────────┬───────────────────────────────────────────────┘
                  ▼
   ┌──────────────────────────────────────────────────────────────┐
   │ Project_Documentation_Index → Interview_Preparation_Guide      │   Phase 12–14: wrap-up
   └──────────────────────────────────────────────────────────────┘
```

---

## Quick counts

- **Total documented markdown files:** 30+ across Documentation, Guides, SQL, Power BI, and Images.
- **Total documentation lines:** ~9,000+ lines of written guidance.
- **Coverage:** Every phase (1–14) has at least one dedicated document.
