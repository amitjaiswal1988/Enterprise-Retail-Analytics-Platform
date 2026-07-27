# Power BI Service Deployment Guide

> **Audience:** BI developers and analysts who have built a report in Power BI Desktop and now need to publish, refresh, secure, and share it in the Power BI Service (the cloud).
>
> **How this guide is written:** Every section uses a **WHAT / WHY / WHEN / HOW** format in simple English, with real examples from the **ShopStar Retail** project ($719M revenue, 9 dashboards, 98 DAX measures, `RetailDW` SQL Server star schema).

---

## Quick Terms (read first)

| Term | 1-line meaning |
|------|----------------|
| **Power BI Desktop** | The free Windows app where you build the model and report. |
| **Power BI Service** | The cloud website (app.powerbi.com) where you publish and share. |
| **Dataset (Semantic model)** | The data model + DAX measures that a report sits on. |
| **Report** | The pages and visuals users interact with. |
| **Workspace** | A folder in the Service that holds datasets, reports, and dashboards. |
| **Gateway** | A small program that lets the cloud read your on-premises SQL Server. |
| **Refresh** | Reloading data from the source into the published dataset. |

---

## 1. Workspace Setup

**WHAT:** A workspace is a shared container in the Power BI Service that holds related datasets, reports, dashboards, and dataflows. It is like a project folder in the cloud.

**WHY:** It keeps all ShopStar content in one place, lets a team collaborate, and controls who can edit vs who can only view. Publishing to a proper workspace (not "My Workspace") is required for scheduled refresh, apps, and deployment pipelines.

**WHEN:** Create the workspace once, before the first publish. Do it at the start of the deployment phase.

**HOW:**
1. Go to **app.powerbi.com** → left menu → **Workspaces** → **New workspace**.
2. Name it clearly. Naming convention for this project: **`ShopStar Retail Analytics`** (add environment suffix if you use pipelines: `ShopStar Retail Analytics [DEV]`, `[TEST]`, `[PROD]`).
3. Add a description and the ShopStar logo image.
4. Set the license mode (Pro or Premium/Fabric capacity) — see refresh limits in Section 3.

**Workspace roles (who can do what):**

| Role | Can do | Give this to |
|------|--------|--------------|
| **Admin** | Everything: add/remove people, delete the workspace, publish apps. | You (the owner), lead BI developer. |
| **Member** | Publish, edit, share content; cannot delete the workspace. | Other developers on the team. |
| **Contributor** | Create and edit content; cannot share or manage access. | Analysts building reports. |
| **Viewer** | Read-only: view reports and dashboards. | Business users (VPs, managers) — though most viewers should get the **App**, see Section 6. |

> **Rule of thumb:** Developers get Member/Contributor in the workspace. Business users never touch the workspace — they consume the published **App**.

---

## 2. Publishing

**WHAT:** Publishing uploads your Power BI Desktop file (`.pbix` / `.pbip`) to a workspace in the Service. Both the **dataset** (model + measures) and the **report** (pages + visuals) are uploaded together.

**WHY:** Reports only become shareable, schedulable, and secure once they live in the Service. The Desktop file on your laptop cannot be scheduled or shared.

**WHEN:** Publish after the model is validated in Desktop and after "View as Role" testing (see the RLS guide). Re-publish every time the model or report changes.

**HOW:**
1. In Power BI Desktop, open `ShopStar_Retail.pbip`.
2. Click **Home → Publish**.
3. Sign in and choose the workspace **`ShopStar Retail Analytics`**.
4. Wait for "Success". Click the link to open it in the Service.

**What gets published:**
- The **semantic model** `ShopStar_Retail` (all tables + 98 DAX measures).
- The **report** `ShopStar_Retail` (all 9 dashboard pages + slicers).
- Any **RLS roles** defined in the model (members are assigned in the Service afterward).

> **Note:** The first publish also uploads the data. After that, the Service holds a copy and you must set up **scheduled refresh** to keep it current.

---

## 3. Scheduled Refresh

**WHAT:** Scheduled refresh tells the Service to automatically reload data from `RetailDW` on a set timetable (for example, every morning at 6 AM).

**WHY:** ShopStar leadership opens dashboards each morning. A nightly/early-morning refresh means they always see yesterday's completed numbers without anyone clicking "refresh" manually.

**WHEN:** Set it up right after the first publish and after the gateway is connected (Section 4).

**HOW:**
1. In the workspace, find the dataset → **⋯ (More options) → Settings**.
2. Under **Gateway connection**, bind it to the On-premises data gateway (Section 4).
3. Expand **Scheduled refresh** → toggle **On**.
4. Set **Refresh frequency** = Daily, add a time **6:00 AM**, pick the time zone.
5. Add your email under **Send refresh failure notifications** so you are told if it breaks.

**Pro vs Premium refresh limits:**

| Capability | Power BI Pro | Premium / Fabric capacity |
|------------|--------------|---------------------------|
| Max scheduled refreshes per day | **8** | **48** |
| Max dataset size | 1 GB | 10 GB+ (up to capacity limit) |
| Incremental refresh | Yes | Yes (plus advanced partitioning) |
| Deployment pipelines | No | Yes |

> **For ShopStar:** One daily 6 AM refresh fits comfortably inside the Pro limit of 8/day. If the business later wants hourly sales, you would move to Premium (48/day).

---

## 4. On-Premises Data Gateway

**WHAT:** The gateway is a small Windows service that acts as a secure bridge between the Power BI Service (cloud) and your local SQL Server (`localhost / RetailDW`). The cloud cannot reach a database on your machine directly; the gateway makes the connection for it.

**WHY:** ShopStar's warehouse `RetailDW` runs on an on-premises SQL Server. Without a gateway, scheduled refresh cannot reach the data and every refresh fails.

**WHEN:** Install it once, before configuring scheduled refresh. Needed whenever the data source is on-premises (not a cloud database).

**Standard vs Personal mode:**

| Mode | WHAT | Best for |
|------|------|----------|
| **Standard (recommended)** | Runs as a service, shared across the team, supports multiple datasets and DirectQuery. | Production / shared ShopStar deployment. |
| **Personal** | Tied to one user, only for scheduled refresh (no DirectQuery), runs under your account. | A single developer testing on their own machine. |

**HOW to install (Standard):**
1. Download the **On-premises data gateway (standard)** from powerbi.microsoft.com.
2. Run the installer → choose **Standard mode** → sign in with your work account.
3. Register the gateway with a clear name, for example **`ShopStar-Gateway-Prod`**.
4. In the Service → **Settings → Manage connections and gateways** → add a **data source**:
   - Type: **SQL Server**
   - Server: `localhost` (or the server name)
   - Database: `RetailDW`
   - Authentication: Windows or a SQL login with read access.
5. In the dataset settings, bind the dataset to this gateway (Section 3, step 2).

**Troubleshooting connection failures:**

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Unable to connect to the data source" | Gateway offline or SQL Server stopped | Check the gateway service is running; start SQL Server. |
| "Credentials are invalid" | Wrong SQL login/password in the data source | Re-enter credentials in Manage connections and gateways. |
| Refresh works in Desktop but fails in Service | Data source in Service not mapped to the gateway | Map the exact same server/database name that Desktop uses. |
| Timeout on large tables | Refresh too slow for the window | Enable incremental refresh (Section 5). |
| "Server name mismatch" | Desktop used `localhost`, gateway uses machine name | Make the server string identical in both places. |

---

## 5. Incremental Refresh

**WHAT:** Incremental refresh reloads only **new or changed rows** (for example, the last 7 days of sales) instead of reloading the entire fact table every time.

**WHY:** ShopStar's production `FactSales` has ~2 million rows. A full refresh reloads all of them and can take ~10 minutes. Incremental refresh reloads only recent partitions and finishes in ~30 seconds — faster, cheaper, and less load on SQL Server.

**WHEN:** Use it on large, date-based fact tables (`FactSales`, `FactInventory`, `FactReturns`) once they grow beyond a few hundred thousand rows. Not needed on small dimension tables.

**HOW:**
1. In Power BI Desktop → **Transform data (Power Query)** → create two date parameters named exactly **`RangeStart`** and **`RangeEnd`** (type Date/Time). These names are required.
2. Filter the fact table's date column between `RangeStart` and `RangeEnd`:
   `[OrderDate] >= RangeStart and [OrderDate] < RangeEnd`
3. Right-click the table → **Incremental refresh** → configure the policy:
   - **Archive data starting:** 5 years before refresh date (historical, refreshed once).
   - **Incrementally refresh data in the last:** 7 days (the "hot" window that changes).
   - Optionally tick **Detect data changes** (uses a `_LoadedAt` column) and **Only refresh complete days**.
4. Publish to the Service. The first refresh builds the partitions; later refreshes only touch the last 7 days.

**Limitations:**
- The partitioning only takes effect **in the Service after publishing** — Desktop still does a full load.
- Once published with incremental refresh, downloading the `.pbix` back is blocked.
- The date filter must fold to the source (SQL Server folds well, so ShopStar is fine).

---

## 6. Apps

**WHAT:** An App is a clean, published, read-only package of selected reports and dashboards that you hand to business users. The workspace is the developer's kitchen; the App is the finished dish served to guests.

**WHY:** VPs and managers should not see draft reports, other developers' work-in-progress, or edit buttons. The App gives them a simple, curated experience and lets you control exactly which pages they see.

**WHEN:** Publish the App once the dashboards are final, then re-publish (update the App) whenever you want users to receive changes.

**App vs Workspace:**

| | Workspace | App |
|--|-----------|-----|
| Who uses it | Developers | Business users |
| Access | Edit content | View only |
| Content shown | Everything (drafts included) | Only what you choose to include |
| Updates | Live as you edit | Only when you click "Update app" |

**HOW:**
1. In the workspace → **Create app** (or **Update app**).
2. **Setup:** app name **`ShopStar Retail Analytics`**, description, logo, theme color (navy `#1B365D`).
3. **Content:** pick which reports/pages are included.
4. **Audience:** add the business users or a security group; set their permission to view.
5. Click **Publish app** and share the app link.

---

## 7. Data Alerts & Subscriptions

**WHAT:**
- A **Data alert** emails you when a KPI crosses a threshold (for example, Return Rate goes above 5%).
- A **Subscription** emails a snapshot (image/PDF) of a report or dashboard on a schedule.

**WHY:** Leaders do not want to open the dashboard every hour. Alerts push a warning only when something needs attention; subscriptions deliver the morning numbers straight to the inbox.

**WHEN:** Set alerts on KPIs with clear targets (Return Rate < 5%, Gross Margin %, Low Stock count). Set subscriptions for daily/weekly executive summaries.

**HOW — Data alert:**
1. Pin a KPI card (for example, **Return Rate %**) to a **dashboard** (alerts work on dashboard tiles, not report visuals).
2. On the tile → **⋯ → Manage alerts → Add alert rule**.
3. Condition: **above 5%**; frequency: at most once per day; tick **email me**.

**HOW — Subscription:**
1. Open the report/dashboard → **Subscribe to report**.
2. Add recipients, set **Daily at 7:00 AM**, choose the page, and attach as **PDF**.
3. Save. The Service emails the PDF automatically every morning.

---

## 8. Deployment Pipelines

**WHAT:** A deployment pipeline moves content through three stages — **Dev → Test → Prod** — with one click, so untested changes never reach business users. This is a **Premium / Fabric** feature.

**WHY:** It prevents mistakes. Developers build in Dev, QA validates in Test, and only approved content is promoted to Prod where VPs consume it. Data source rules can be swapped automatically per stage (Dev points at a test DB, Prod at the real `RetailDW`).

**WHEN:** Use it once the project is on a Premium/Fabric capacity and multiple people are contributing. For a single-developer Pro project, manual re-publish is acceptable.

**HOW:**
1. In the Service → **Deployment pipelines → Create pipeline**.
2. Assign three workspaces: `ShopStar ... [DEV]`, `[TEST]`, `[PROD]`.
3. Build and validate in **Dev** → click **Deploy to Test** → validate → **Deploy to Prod**.
4. Configure **deployment rules** so each stage uses its own gateway/data source and parameters.

---

## 9. Usage Metrics

**WHAT:** Usage metrics show who viewed which report, how often, on what device, and how the report performs.

**WHY:** It proves the platform delivers value ("the Executive Overview was opened 240 times this month by 18 leaders"), finds unused reports to retire, and flags slow pages to optimize.

**WHEN:** Review monthly, and whenever you want to justify the platform's impact or plan improvements.

**HOW:**
1. In the workspace, open a report → **⋯ (More options) → Open usage metrics report**.
2. Review views per day, unique viewers, top reports, and load times.
3. Optionally save the underlying dataset to build your own custom adoption dashboard.

---

## Deployment Checklist (ShopStar)

- [ ] Workspace `ShopStar Retail Analytics` created, roles assigned.
- [ ] `ShopStar_Retail.pbip` published to the workspace.
- [ ] On-premises gateway `ShopStar-Gateway-Prod` installed and mapped to `RetailDW`.
- [ ] Scheduled refresh set to **Daily 6:00 AM** with failure emails on.
- [ ] Incremental refresh policy on `FactSales` (7-day hot window, 5-year archive).
- [ ] RLS role members assigned (see the Row-Level Security guide).
- [ ] App `ShopStar Retail Analytics` published to business users.
- [ ] Data alert on **Return Rate % > 5%**; daily 7 AM executive PDF subscription.
- [ ] Usage metrics reviewed after the first month.
