# Power BI Service — Complete Deployment & Administration Guide

> **Project:** Enterprise Retail Analytics Platform — ShopStar Retail
> **Author:** Amit Jaiswal — Senior BI Engineer
> **Phase:** Phase 9 — Power BI Service Deployment · Phase 10 — Security
> **Audience:** A junior BI developer publishing an enterprise model for the
> first time. Every section follows **WHAT → WHY → WHEN → HOW (numbered steps)**.

---

## Table of Contents

1. [Workspaces](#1--workspaces)
2. [Publishing from Desktop to Service](#2--publishing-from-desktop-to-service)
3. [Scheduled Refresh](#3--scheduled-refresh)
4. [On-Premises Data Gateway](#4--on-premises-data-gateway)
5. [Incremental Refresh](#5--incremental-refresh)
6. [Row-Level Security (RLS)](#6--row-level-security-rls)
7. [Apps](#7--apps)
8. [Data Alerts](#8--data-alerts)
9. [Subscriptions](#9--subscriptions)
10. [Deployment Pipelines](#10--deployment-pipelines)
11. [Usage Metrics](#11--usage-metrics)
12. [Premium vs Pro](#12--premium-vs-pro)
13. [Common Issues & Troubleshooting](#13--common-issues--troubleshooting)

---

## 1 — Workspaces

**WHAT:** A workspace is a container in the Power BI Service that holds related
datasets (semantic models), reports, dashboards, and dataflows.

**WHY:** It's the unit of **collaboration and security**. ShopStar Retail's BI
team shares one workspace so developers co-own content, while business users
consume a packaged **App** (see §7) rather than the raw workspace.

**WHEN:** Create it once, before your first publish.

**HOW:**
1. Sign in to `https://app.powerbi.com`.
2. Left nav → **Workspaces** → **+ New workspace**.
3. Name it `ShopStar Retail Analytics` and add a description.
4. Under **Advanced**, set the **License mode** (Pro, Premium Per User, or a
   Premium/Fabric capacity — see §12).
5. **Access** → add teammates with a role:
   - **Admin** — full control incl. delete + user management.
   - **Member** — publish/edit content, can't delete the workspace.
   - **Contributor** — create/edit content, can't manage access.
   - **Viewer** — read-only.
6. Follow least privilege: developers = Member; analysts = Contributor;
   stakeholders consume the **App**, not the workspace.

---

## 2 — Publishing from Desktop to Service

**WHAT:** Uploading your `.pbix` (model + report) into a workspace.

**WHY:** Only content in the Service can be shared, scheduled, and secured.

**WHEN:** After each meaningful change validated in Desktop.

**HOW:**
1. In Power BI **Desktop**: **Home → Publish**.
2. Sign in with your organizational account.
3. Choose the destination workspace `ShopStar Retail Analytics`.
4. Wait for **"Success"**, then click **Open in Power BI**.
5. In the Service you'll now see three artifacts: a **Semantic model**, a
   **Report**, and (optionally) a **Dashboard** you pin visuals to.
6. **Immediately configure the data source credentials** (see §3, step 2) or the
   first refresh will fail.

> **Tip:** Publish the model and reports **separately** in mature setups — a
> shared dataset with thin reports on top avoids duplicate models. Use **"Get
> data → Power BI semantic models"** to build reports against the published model.

---

## 3 — Scheduled Refresh

**WHAT:** Automatic dataset refresh on a defined cadence (daily at **06:00**).

**WHY:** Dashboards must show current data each morning before the business day.

**WHEN:** Configure right after publishing.

**HOW:**
1. Workspace → the **Semantic model** → **⋮ → Settings**.
2. **Data source credentials → Edit credentials**: set the SQL Server auth
   (and map to the gateway from §4 for an on-prem source).
3. Expand **Scheduled refresh** → toggle **On**.
4. **Refresh frequency:** Daily. **Time zone:** your local. **Add time:** `06:00`
   (add a second slot, e.g. `13:00`, if the business needs a mid-day update).
5. Enable **Send refresh failure notifications to** the dataset owner + a
   distribution list.
6. **Apply**. Use **Refresh now** once to confirm it works end-to-end.

> **Limits:** Pro = up to **8** refreshes/day; Premium/PPU = up to **48**.

---

## 4 — On-Premises Data Gateway

**WHAT:** A bridge service installed on-prem that lets the cloud Service reach a
local data source (our `localhost\RetailDW` SQL Server).

**WHY:** SQL Server sits behind the corporate firewall; the cloud can't connect
directly. The gateway makes a secure **outbound** connection — no inbound ports.

**WHEN:** Required whenever the source is on-prem (i.e. this project) and you want
scheduled refresh in the Service.

**HOW — Install:**
1. Download **On-premises data gateway (standard mode)** from Microsoft.
2. Install on a machine that is **always on** and can reach SQL Server (a server,
   not a developer laptop).
3. Sign in with the organizational account; choose **"Register a new gateway"**.
4. Name it `ShopStar-Gateway`; set a **recovery key** (store it in a vault).

**HOW — Configure the data source:**
1. In the Service → **Settings (gear) → Manage connections and gateways**.
2. Select `ShopStar-Gateway` → **+ New** data source.
3. Type = **SQL Server**; Server = `localhost` (or the real host); Database =
   `RetailDW`; set authentication.
4. Under the dataset's **Settings → Gateway connection**, **map** the dataset to
   this gateway data source.

**HOW — Troubleshoot:** see §13.

> **Standard vs Personal gateway:** Use **Standard** (multi-user, shareable) for
> enterprise. Personal mode is single-user and can't be shared.

---

## 5 — Incremental Refresh

**WHAT:** Refresh only recent partitions of a large fact instead of the whole
table (config authored in Desktop, applied in the Service).

**WHY:** The production fact (~2M rows) is slow and expensive to fully reload
daily. Incremental refresh cuts refresh time and gateway load dramatically.

**WHEN:** For any large, date-partitioned fact table (`FactSales`).

**HOW:**
1. In **Desktop**, create `RangeStart` and `RangeEnd` datetime parameters and a
   folding date filter (see `Power BI/PowerQuery_M_Code_Complete.md` §4).
2. Right-click `FactSales` → **Incremental refresh** → toggle **On**.
3. **Archive** data starting **5 years** before refresh date.
4. **Incrementally refresh** data **10 days** before refresh date.
5. (Optional) **Detect data changes** using `_LoadedAt` to skip unchanged
   partitions.
6. **Publish** to the Service. The **first refresh** is a full load that builds
   partitions; every subsequent refresh only touches the last 10 days.

**Description of what you see:** After the first Service refresh, the model's
storage shows one partition per historical year (frozen) plus daily partitions
for the recent window that actually reprocess.

---

## 6 — Row-Level Security (RLS)

RLS restricts **which rows** a user can see. We implement four patterns.

### 6.1 Static RLS (fixed role per region)

**WHAT:** A role with a hard-coded filter (e.g. West region only).

**WHY:** Simple when the mapping rarely changes and roles are few.

**WHEN:** Small, stable sets of regional viewers.

**HOW (in Desktop → Modeling → Manage roles):**
```dax
// Role name: "West Region"
// Table: DimRegion   Filter:
[RegionName] = "West"
```
1. **Modeling → Manage roles → Create** → name `West Region`.
2. Pick `DimRegion` and enter the DAX filter above.
3. Repeat per region. **Save**.
4. Test: **Modeling → View as → West Region**.
5. Publish, then in the Service → model → **Security** → add users/groups to the
   role.

### 6.2 Dynamic RLS (USERPRINCIPALNAME lookup)

**WHAT:** One role whose filter resolves per signed-in user via a mapping table.

**WHY:** Scales to hundreds of users without a role each — the recommended
enterprise pattern.

**WHEN:** Many users, data-driven mapping.

**HOW:**
1. Add a security/bridge table, e.g. `SecUserRegion(UserEmail, RegionName)`
   (from a SQL view). ShopStar can build this from `DimEmployee` + region.
2. Relate/lookup it to `DimRegion`.
3. Create **one** role `Dynamic Region` with a filter on the mapping table:
```dax
// Table: SecUserRegion   Filter:
[UserEmail] = USERPRINCIPALNAME ()
```
4. If the mapping table filters `DimRegion` (1-to-many, single direction), the
   region filter flows to the facts automatically.
5. Test with **View as → Dynamic Region + Other user →** `manager@shopstar.com`.
6. Publish; add **all** viewers to the single dynamic role.

> `USERPRINCIPALNAME()` returns the signed-in user's UPN (usually their email).

### 6.3 Object-Level Security (OLS)

**WHAT:** Hides entire **tables or columns** from a role (not just rows).

**WHY:** Some fields (e.g. `DimEmployee[Salary]`) must be invisible to most
roles, even in field lists.

**WHEN:** Sensitive columns/tables.

**HOW:** OLS isn't in the Desktop UI — use **Tabular Editor**:
1. Open the model in **Tabular Editor** (external tool).
2. Select the role → the column `DimEmployee[Salary]` → set **Object Level
   Security = None** for that role.
3. Save back to the model; publish.
4. Members of that role won't see the column anywhere (visuals referencing it
   break gracefully / are hidden).

### 6.4 Hierarchical RLS (PATH — CEO → VP → Manager → Store)

**WHAT:** A manager sees their own data **and everyone below them** in the org
tree.

**WHY:** Leadership needs roll-ups down their branch; peers stay hidden.

**WHEN:** Org-chart-based access (our `DimEmployee[ManagerID]` self-reference).

**HOW:**
1. Add a calculated column materializing the hierarchy path:
```dax
// Calculated column on DimEmployee
EmployeePath = PATH ( DimEmployee[EmployeeID], DimEmployee[ManagerID] )
```
2. Create role `Org Hierarchy` with this filter on `DimEmployee`:
```dax
// TRUE when the signed-in user is the employee OR any ancestor manager
PATHCONTAINS (
    [EmployeePath],
    LOOKUPVALUE (
        DimEmployee[EmployeeID],
        DimEmployee[Email], USERPRINCIPALNAME ()   // if Email retained for sec table
    )
)
```
3. `PATH` builds the ancestor chain; `PATHCONTAINS` returns TRUE for a manager
   over any descendant, so they see their whole sub-tree.
4. Test **View as → Org Hierarchy + Other user →** a VP vs a store associate.

### 6.5 Testing RLS (Desktop and Service)

- **Desktop:** **Modeling → View as →** tick a role (+ *Other user* for dynamic).
- **Service:** model → **Security → …→ Test as role**.
- Always verify a low-privilege user sees **fewer** rows and that totals shrink.

> **Gotcha:** RLS applies to **Viewers**. Workspace **Admins/Members/
> Contributors** bypass RLS unless you enforce it via the App/Viewer role.

---

## 7 — Apps

**WHAT:** A curated, read-only package of selected reports/dashboards published
to business users.

**WHY:** Separates the **development** workspace from the **consumption**
experience; users get a clean, stable app and never see work-in-progress.

**WHEN:** When content is validated and ready for the audience.

**HOW:**
1. Workspace → **Create app** (or **Update app**).
2. **Setup:** app name, description, logo, theme color.
3. **Content:** choose which reports/dashboards to include; set the landing page.
4. **Audience:** create audience groups (e.g. *Executives*, *Store Managers*),
   include the right content per group, and add users/security groups.
5. **RLS still applies** — the app respects the roles from §6.
6. **Publish app**; share the app link. Re-**Update app** after each release.

---

## 8 — Data Alerts

**WHAT:** An email/notification when a KPI crosses a threshold.

**WHY:** Push exceptions to people instead of making them watch a dashboard
(e.g. alert when **Stockout Rate % > 2%** or **Gross Margin % < 35%**).

**WHEN:** On dashboard tiles pinned from KPI Cards / Gauges.

**HOW:**
1. Pin a single-value KPI visual (e.g. `Gross Margin %`) to a **Dashboard**.
2. On the tile → **⋮ → Manage alerts → + Add alert rule**.
3. Condition: **Above / Below** a value (e.g. below `0.35`).
4. Cadence: check **hourly/daily**; tick **email me**.
5. (Optional) Trigger a **Power Automate** flow for Teams/ticketing.

> Alerts work only on **dashboard tiles** (not report visuals) and only for
> numeric single-value tiles.

---

## 9 — Subscriptions

**WHAT:** Scheduled email delivery of a report/dashboard snapshot (PDF/image).

**WHY:** Executives want the numbers in their inbox without opening Power BI.

**WHEN:** Daily leadership digest (e.g. 07:00 after the 06:00 refresh).

**HOW:**
1. Open the report/dashboard → **Subscribe to report**.
2. **+ New subscription** → name it *Daily Exec Digest*.
3. Set recipients, **frequency = Daily**, **time = 07:00**, choose the page.
4. Attach **full report as PDF** if needed.
5. **Save and close.** Recipients need at least Viewer access / the App.

---

## 10 — Deployment Pipelines

**WHAT:** A managed **Dev → Test → Prod** promotion flow for Premium/PPU content.

**WHY:** Prevents editing production directly; enables review/testing between
stages and controlled releases.

**WHEN:** Any governed enterprise deployment.

**HOW:**
1. **Power BI → Deployment pipelines → Create pipeline** (`ShopStar RDW`).
2. Assign a workspace to **Development**.
3. **Deploy** to **Test**, then **Test → Production**.
4. Configure **deployment rules** so each stage points at the right database:
   swap the `pServerName`/`pDatabaseName` parameters (Dev SQL → Prod SQL).
5. Use **Compare** to see what changed before each promotion.
6. Only promote after Test validation + stakeholder sign-off.

---

## 11 — Usage Metrics

**WHAT:** Built-in reports showing who viewed what, how often, and load times.

**WHY:** Justify the platform's value, find unused reports to retire, and spot
performance issues.

**WHEN:** Review monthly.

**HOW:**
1. Workspace → a report → **⋮ → Open usage metrics report** (or **View usage
   metrics** in newer UIs).
2. Explore **views, unique viewers, and performance** by report/page.
3. **Save a copy** to customize and pin key metrics.
4. Act on it: retire zero-view reports; optimize slow pages (see §13).

---

## 12 — Premium vs Pro

| Capability | **Pro** | **Premium / PPU / Fabric capacity** |
|-----------|---------|--------------------------------------|
| Share content with others | Yes (each recipient needs Pro) | Premium (capacity): viewers need **no** Pro license |
| Model size limit | ~1 GB | Up to 25 GB+ (capacity dependent) |
| Refreshes per day | **8** | **48** |
| Incremental refresh | Yes | Yes (better at scale) |
| Deployment pipelines | No | **Yes** |
| Paginated reports | No | **Yes** |
| XMLA endpoint (Tabular Editor, OLS) | Read | **Read/Write** |
| AI features, larger models, dataflows Gen2 | Limited | **Full** |

**Rule of thumb:** Use **Pro** for small teams where everyone is licensed. Use
**Premium capacity / Fabric** when you have many viewers, large models, need
pipelines, paginated reports, or OLS via the XMLA endpoint.

---

## 13 — Common Issues & Troubleshooting

| Symptom | Likely cause | Fix |
|--------|--------------|-----|
| Scheduled refresh fails: *"cannot connect"* | Gateway offline or data source not mapped | Confirm gateway service is running (§4); map dataset → gateway data source; re-enter credentials |
| Refresh is very slow / times out | Query folding broke; full reload of a huge table | Verify **View Native Query** folds; enable **incremental refresh** (§5) |
| RLS: viewer sees **all** rows | User is a workspace Admin/Member (bypasses RLS) | Move consumers to **Viewer** via the App; test with **View as role** |
| RLS: viewer sees **no** rows | Mapping table empty or `USERPRINCIPALNAME()` ≠ stored email | Check the security table values; UPN vs email casing |
| Dynamic RLS bidirectional filter leaks | Both-direction relationship crosses the security path | Keep security relationships **single-direction**; avoid bidi |
| "Credentials invalid" after password change | Stored data source creds stale | Model → **Settings → Data source credentials → Edit** |
| Alert never fires | Alert set on a report visual, not a dashboard tile | Pin the KPI to a **dashboard** and set the alert there (§8) |
| Users can't see the app | Not added to the app **audience** | **Update app → Audience →** add the user/security group (§7) |
| Model too big to publish (Pro) | Over ~1 GB | Remove unused columns; use INT keys; move to Premium/PPU (§12) |
| Time intelligence returns blanks | Date table not marked / has gaps | **Mark as date table** on `FullDate`; ensure contiguous dates |

---

## Deployment checklist

- [ ] Workspace created with least-privilege roles.
- [ ] `.pbix` published; data source credentials set.
- [ ] Gateway installed, online, and mapped to the dataset.
- [ ] Scheduled refresh at 06:00 with failure notifications.
- [ ] Incremental refresh enabled + first full refresh completed.
- [ ] RLS roles created, tested (**View as**), and users assigned.
- [ ] App published to the correct audiences.
- [ ] Alerts + subscriptions configured for key KPIs.
- [ ] Deployment pipeline (Dev→Test→Prod) with per-stage data source rules.
- [ ] Usage metrics reviewed after go-live.
