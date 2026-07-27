# ShopStar Retail — Dashboard Specifications

These specifications describe the **nine report pages as actually built** in
`Power BI/ShopStar_Retail.pbip` (Enhanced Report / PBIR format). Every page uses
the ShopStar theme (Navy + Orange), a 1280×720 canvas, a top row of 4 KPI cards,
and a 2×2 grid of charts below. Measures come from the `_Measures` table (98 DAX
measures). Items labelled **Roadmap** are planned but not yet implemented.

> Data scale (full dataset): **$719M revenue · $121M gross profit · 16.8% margin ·
> 50K orders · 60/40 store-vs-online**. See `Business_Insights_Report.md`.

Layout legend for every page:
- **Row 1 (KPI cards):** four cards, left → right.
- **Charts:** four visuals — top-left, top-right, bottom-left, bottom-right.

---

## 1. Executive Overview
- **Audience:** CEO, CFO — sees all data.
- **Purpose:** 30-second health check of the whole business.
- **KPI cards:** Total Revenue · Gross Margin % · Total Orders · Active Customers.
- **Charts:** Revenue by Month (line) · Revenue by Category (column) · Revenue by
  Region (bar) · Revenue by Channel (donut).
- **Why these visuals:** a line shows trend/seasonality at a glance; column/bar
  rank categories and regions; the donut communicates the store-vs-online mix in
  one look. Cards give the four numbers a CEO asks for first.
- **Interview point:** "This is the boardroom page — one screen answers *are we
  growing, where, and through which channel*. Everything else is a drill-down."
- **Roadmap:** filled-map region visual, Year/Quarter/Region slicers, YoY cards,
  nav buttons.
- **Status:** validated in Power BI Desktop.

## 2. Sales Performance
- **Audience:** VP Sales, Sales Managers.
- **Purpose:** track sales momentum and find category winners.
- **KPI cards:** Total Revenue · Total Orders · Average Order Value · Total Quantity Sold.
- **Charts:** Revenue by Month (line) · Revenue by Store Type (column) · Revenue by
  Region (bar) · Revenue by Channel (donut).
- **Why:** a monthly line exposes momentum; store-type and region breakdowns show
  *where* volume comes from; the donut keeps channel context.
- **Interview point:** "Sales leadership lives here daily — momentum plus the mix
  of formats and regions driving it."
- **Roadmap:** MTD/QTD/YTD cards, vs-target gauge, moving-average line, Top-10
  product table, drill-through to a product-detail page.

## 3. Customer Analytics
- **Audience:** CMO, Marketing.
- **Purpose:** understand who buys, retention, and value.
- **KPI cards:** Active Customers · New Customers · Customer Retention Rate % ·
  Customer Lifetime Value.
- **Charts:** Revenue by Segment (column) · New Customers by Month (line) · Active
  Customers by Region (bar) · Revenue by Segment (donut).
- **Why:** segment column/donut reveal which customer types drive revenue; the
  monthly new-customer line tracks acquisition; region bar shows geographic reach.
- **Interview point:** "Marketing sees which segments grow revenue and whether the
  acquisition engine is healthy — the four near-equal segments (~25% each) mean
  revenue isn't over-dependent on any one group."
- **Roadmap:** RFM scatter, cohort-retention matrix, CLV histogram.

## 4. Inventory & Supply Chain
- **Audience:** VP Supply Chain, Warehouse Managers.
- **Purpose:** stock health, reorder alerts, capital efficiency.
- **KPI cards:** Total Stock on Hand · Inventory Value · Inventory Turnover ·
  Low Stock Items Count.
- **Charts:** Inventory Value by Category (column) · Inventory Value by Region (bar)
  · Out of Stock Items by Category (column) · Inventory Value by Store Type (donut).
- **Why:** value-by-category/region shows where working capital is tied up;
  out-of-stock-by-category flags availability risk.
- **Interview point:** "Supply chain protects sales by preventing stockouts while
  freeing trapped capital — only 752 out-of-stock snapshots but ~43K low-stock,
  so the reorder policy is the lever."
- **Roadmap:** conditional red/amber alert table, stock-coverage gauge,
  stockout-rate trend, stock-status slicer.

## 5. Store Performance
- **Audience:** Regional & Store Managers.
- **Purpose:** how is my store doing versus the company?
- **KPI cards:** Total Revenue · Revenue Per Store · Sales Per Associate · Total Orders.
- **Charts:** Revenue by Store (column) · Revenue by Store Type (bar) · Revenue by
  Region (column) · Revenue by Store Size (donut).
- **Why:** per-store column ranks all 51 stores; store-type/size cuts compare
  formats; region column rolls up to leadership view.
- **Interview point:** "Managers see rank and format context — the productivity
  metrics (per store, per associate) normalise for size so a small store isn't
  unfairly compared to a flagship."
- **Roadmap:** Row-Level Security so a manager sees only their store; rank card;
  revenue-per-sq-ft; conditional-formatted ranking table.

## 6. Product & Category
- **Audience:** Category Managers, Product team.
- **Purpose:** find winners, losers, and discontinuation candidates.
- **KPI cards:** Total Revenue · Gross Margin % · High Margin Products Count ·
  Total Quantity Sold.
- **Charts:** Revenue by Category (column) · Revenue by Brand (bar) · Gross Margin %
  by Category (column) · Revenue by Price Range (donut).
- **Why:** revenue-by-category/brand ranks performance; margin-by-category exposes
  profitability differences; price-range donut shows the assortment mix.
- **Interview point:** "Category managers balance volume against margin — note all
  categories sit in a tight 16–17% margin band, so mix and pricing, not category
  choice, move profit."
- **Roadmap:** ABC/Pareto chart, revenue-vs-margin scatter, top/bottom-10 tables,
  drill-through to product history.

## 7. Finance & Profitability
- **Audience:** CFO, Finance.
- **Purpose:** P&L view, margin analysis.
- **KPI cards:** Gross Profit · Gross Margin % · Total COGS · Net Revenue.
- **Charts:** Gross Profit by Month (line) · Gross Profit by Category (column) ·
  Gross Margin % by Region (bar) · Total Discount Amount by Channel (donut).
- **Why:** the profit line tracks the bottom line over time; category profit and
  regional margin locate where margin is made; discount-by-channel shows leakage.
- **Interview point:** "Finance tracks where margin is earned and lost — with a
  thin 16.8% blended margin, discount discipline by channel is the swing factor."
- **Roadmap:** monthly P&L waterfall, revenue-vs-budget bullet chart.

## 8. Regional Comparison
- **Audience:** VP Sales, Regional Managers.
- **Purpose:** geographic performance comparison.
- **KPI cards:** Total Revenue · Total Orders · Active Customers · Gross Margin %.
- **Charts:** Revenue by Region (column) · Gross Margin % by Region (bar) · Orders
  by Region (column) · Revenue by Month (line).
- **Why:** parallel region cuts of revenue, margin, and orders make imbalances
  obvious; the monthly line adds a time dimension.
- **Interview point:** "Leadership spots where to invest or intervene — East
  ($150M) and West ($139M) lead store revenue, while North/South trail."
- **Roadmap:** filled US map, Region→State→City→Store drill, region-growth %.

## 9. Returns & Shipping
- **Audience:** VP Supply Chain, Logistics / Customer Service.
- **Purpose:** returns behaviour and refund exposure.
- **KPI cards:** Total Returns Count · Total Refund Amount · Return Rate % ·
  Avg Days to Return.
- **Charts:** Refund Amount by Reason (column) · Returns Count by Category (bar) ·
  Returns Count by Condition (column) · Refund Amount by Condition (donut).
- **Why:** reason/condition breakdowns pinpoint *why* product comes back and its
  resale state; category view flags problem lines.
- **Interview point:** "Returns run at 4.26% — inside the 5% target — but $22.9M of
  refunds is real margin, so reason analysis drives the biggest savings."
- **Roadmap / scope note:** carrier on-time %, delivery-days, and shipping-cost
  analytics require modelling `Dataset/shipping.csv` as a **FactShipping** table;
  that fact is **not yet in the semantic model**, so true delivery KPIs are future
  work. This page currently covers the **Returns** side of post-purchase.

---

### Cross-cutting design rationale (interview-ready)
- **Cards for headline numbers** — instant reading, no interpretation needed.
- **Line for time** — trend and seasonality.
- **Column/Bar for ranking** — compare categories, regions, stores.
- **Donut for part-to-whole** — channel, segment, condition mix (kept to ≤6 slices).
- **One theme, one grid** — every page is visually consistent, so an executive
  learns the layout once and reads any page in seconds.
