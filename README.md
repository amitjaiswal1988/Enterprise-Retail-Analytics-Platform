# Enterprise Retail Analytics Project

## HPE Retail Division - Business Intelligence Platform

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2019+-blue)](https://www.microsoft.com/sql-server)
[![Power BI](https://img.shields.io/badge/Power%20BI-Desktop%20%26%20Service-yellow)](https://powerbi.microsoft.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Project Overview

An end-to-end **Enterprise Business Intelligence solution** that demonstrates the complete lifecycle of a real-world retail analytics project. Built to mirror production implementations at Fortune 500 companies (HPE, Walmart, Amazon, Target).

### Business Scenario

HPE Retail Division operates through two sales channels:
- **Brick-and-Mortar Stores** (120+ locations, 35 states)
- **E-commerce Platform** (40% of revenue)

This project delivers a centralized analytics platform providing insights into Sales, Product Performance, Customer Behavior, Inventory, Returns, Profitability, and more.

---

## Technology Stack

| Technology | Purpose |
|-----------|---------|
| SQL Server 2019+ | Data Warehouse |
| Power BI Desktop | Report Development |
| Power BI Service | Enterprise Deployment |
| Power Query (M) | Data Transformation |
| DAX | Business Logic & Measures |
| Python | Data Generation & Automation |
| Star Schema | Data Modeling |

---

## Project Architecture

```
SOURCE (CSV/Kaggle) → LANDING (Raw) → STAGING (Cleaned) → WAREHOUSE (Star Schema) → POWER BI
```

---

## Repository Structure

```
Retail-Analytics-Project/
│
├── Dataset/                    # Source data files
├── SQL/
│   ├── Landing/               # Raw data ingestion scripts
│   ├── Staging/               # Data cleaning & transformation
│   ├── Warehouse/             # Star schema DDL & DML
│   ├── Stored Procedures/     # ETL procedures
│   └── Views/                 # Reporting views
│
├── Python/                    # Data generation & automation scripts
├── Power BI/
│   ├── PBIX/                  # Power BI report files
│   └── Templates/             # Reusable templates
│
├── DAX/                       # DAX measures documentation
├── Documentation/             # BRD, TDD, guides
├── Images/                    # Diagrams & visuals
├── Dashboard Screenshots/     # Report screenshots
├── Architecture/              # Architecture diagrams
├── README.md                  # This file
└── LICENSE                    # MIT License
```

---

## Phases

| Phase | Description | Status |
|-------|------------|--------|
| 1 | Business Understanding | Completed |
| 2 | Dataset Selection | In Progress |
| 3 | Database Design | Pending |
| 4 | Data Cleaning | Pending |
| 5 | Data Warehouse (Star Schema) | Pending |
| 6 | Power BI Data Model | Pending |
| 7 | Advanced DAX | Pending |
| 8 | Dashboard Development | Pending |
| 9 | Power BI Service Deployment | Pending |
| 10 | Security (RLS) | Pending |
| 11 | Performance Optimization | Pending |
| 12 | Documentation | Pending |
| 13 | GitHub Repository | Pending |
| 14 | Interview Preparation | Ongoing |

---

## Key Deliverables

- Production-ready SQL Server Data Warehouse
- Star Schema with Fact & Dimension tables
- 100+ Advanced DAX measures
- 9 Professional Power BI dashboards
- Row-Level Security implementation
- Incremental Refresh configuration
- Complete documentation suite
- Interview preparation materials

---

## Author

Enterprise BI Developer Portfolio Project

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
