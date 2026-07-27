# ShopStar Retail — Complete Dashboard Explanation Guide

> **WHAT:** A page-by-page explanation of all 9 dashboards. For every page it tells you the business problem it solves, who looks at it, what each visual shows, why that chart was chosen, the exact talking script, the insights, the likely questions, and the technical build.
>
> **WHY:** So that after reading this **once**, you can explain any dashboard to **anyone** — a VP, a colleague, or an interviewer — with confidence and real numbers.
>
> **WHEN:** Read it before a presentation, an interview, or a demo. Keep it open as your "cheat sheet" while you present.
>
> **How to use it:** Say the **number** first, then the **so-what** (what it means), then the **action** (what to do). A leader wants a decision, not a chart name.

---

## The numbers you must memorize (whole project)

| Metric | Value | One-line meaning |
|--------|-------|------------------|
| **Revenue** | **$719.2M** | Total sales money earned. |
| **COGS** | **$598.2M** | Cost to buy/make the goods. |
| **Gross Profit** | **$121.0M** | Revenue − COGS. |
| **Gross Margin %** | **16.8%** | Profit kept from each $1 of sales (thin). |
| **Orders** | **50,000** | Number of orders. |
| **AOV** | **$14,384** | Average value of one order (high → B2B mix). |
| **Units sold** | **1.5M** | Total items sold. |
| **Channel split** | **Store 60% / Online 40%** | Where sales happen. |
| **Top region (store)** | **East $150.5M** | Best region; North weakest at $68.4M. |
| **Active customers** | **18,431 / 20,000 (92%)** | Strong retention. |
| **Return rate** | **~4.3%** (refund $22.87M) | Below the 5% target — healthy. |
| **Inventory** | **99.7M units**, 752 out-of-stock, 42,953 low-stock | High availability. |

**The 1% rule:** on $719M revenue, a **1% margin gain ≈ $7.2M** more profit. Use this to show scale.

---

## Page 1: Executive Overview

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Management's question:** "In 30 seconds, is the company healthy — are we growing, and are we profitable?"
- **Decision after seeing it:** Whether to dig deeper into a weak area (margin, a region, a channel) or stay the course.
- **Money impact:** This is the steering view. Spotting the thin 16.8% margin here — where a **1% improvement ≈ $7.2M** — is the single biggest lever it surfaces.

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** CEO, VP of Sales, Board members.
- **Frequency:** Monthly leadership review (first slide); ad-hoc for investor summaries.
- **Scenario:** *"The VP opens this page at the start of the monthly review to get the whole company's health before anyone presents detail."*

### 3. PAGE LAYOUT EXPLANATION (top → bottom, left → right)
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| Header row | Logo + Slicers | Brand + filters (Year, Quarter, Region, Channel, Category) | Filter the whole page live | Dimensions |
| KPI 1 (top) | KPI Card | Total Revenue **$719M** | Big number = instant read | `Total Revenue` = SUM(FactSales[LineTotal]) |
| KPI 2 | KPI Card | Gross Margin **16.8%** | Profit health at a glance | `Gross Margin %` = Gross Profit ÷ Revenue |
| KPI 3 | KPI Card | Total Orders **50,000** | Volume of business | `Total Orders` = DISTINCTCOUNT(order) |
| KPI 4 | KPI Card | Active Customers **18,431** | Size of live customer base | `Active Customers` |
| Middle-left | Line Chart | Revenue by month | Line = trend over time | DimDate[YearMonth] × Revenue |
| Middle-right | Column Chart | Revenue by Category | Compare categories | DimCategory × Revenue |
| Bottom-left | Bar Chart | Revenue by Region | Long labels → horizontal | DimRegion × Revenue |
| Bottom-right | Donut Chart | Revenue by Channel | Part-of-whole (2 slices) | FactSales[Channel] × Revenue |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Click one year | "Show only 2024." |
| Quarter | Header | Q1–Q4 | Narrow to a quarter | "How was Q3?" |
| Region | Header | East/West/North/South | One or many | "How is East doing?" |
| Channel | Header | Store / Online | Pick a channel | "Online only." |
| Category | Header | Electronics/Furniture/… | Pick a category | "Electronics only." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *is the company healthy and growing?*"
2. "Top KPIs: revenue is **$719 million**, margin **16.8%**, **50,000 orders**, **18,400 active customers**."
3. "The trend line shows revenue is steady month over month."
4. "By category, Office Supplies and Technology lead; by channel, **60% is Store, 40% Online**."
5. "My recommendation: margin is thin — we should review pricing and push the higher-margin online channel."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single big number | VP needs an instant answer | A chart would add clutter |
| Line Chart | Shows trend/flow over time | Dates on the X-axis | A bar chart hides the flow |
| Column Chart | Compare short labels | Categories, months | Bar wastes width here |
| Bar Chart | Compare long labels | Region names | Column makes labels overlap |
| Donut Chart | Part-of-whole | 2–5 slices (Store/Online) | Many slices become unreadable |

### 7. BUSINESS INSIGHTS
- **Revenue $719M but margin only 16.8%** → high volume, thin profit. The #1 talking point.
- **Store 60% vs Online 40%** → stores are the backbone; online is the growth (and higher-margin) lever.
- **Top categories all 16–17% margin** → no single "cash cow"; margin must be won across the board.

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "Why is margin only 16.8%?" | "Retail is volume; COGS is $598M. Detail is on the Finance page." | Margin KPI + Finance page |
| "Compare with last year?" | "Use the Year slicer to switch." | Year slicer → trend line |
| "Which channel to grow?" | "Online — 40% share, lower cost to serve." | Channel donut |

### 9. TECHNICAL BUILD
- **DAX:** `Total Revenue`, `Gross Margin %`, `Total Orders`, `Active Customers`.
- **Tables:** `FactSales` + `DimDate`, `DimCategory`, `DimRegion`.
- **Relationships:** FactSales → DimDate/DimCategory/DimRegion fire on load.
- **Performance:** Import mode + star schema + integer keys → the page renders instantly.

---

## Page 2: Sales Performance

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Question:** "Where is our revenue coming from, and is order size healthy?"
- **Decision:** Where to focus the sales team — which region, channel, and store format.
- **Money impact:** Closing the North gap (North $68M vs East $150M store revenue) is a multi-million-dollar opportunity.

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** VP of Sales, Regional Sales Managers.
- **Frequency:** Weekly/monthly sales review.
- **Scenario:** *"The VP opens this when discussing target vs actual and which region is lagging."*

### 3. PAGE LAYOUT EXPLANATION
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| KPI 1 | KPI Card | Total Revenue **$719M** | Headline sales | `Total Revenue` |
| KPI 2 | KPI Card | Quantity Sold **1.5M units** | Volume | `Total Quantity Sold` |
| KPI 3 | KPI Card | Orders **50,000** | Order count | `Total Orders` |
| KPI 4 | KPI Card | AOV **$14,384** | Avg order size | `Average Order Value` |
| Middle-left | Bar Chart | Revenue by Region | Long labels → horizontal | DimRegion × Revenue |
| Middle-right | Donut Chart | Revenue by Channel | Store vs Online share | FactSales[Channel] × Revenue |
| Bottom-left | Column Chart | Revenue by Store Type | Compare formats | DimStore[StoreType] × Revenue |
| Bottom-right | Line Chart | Revenue trend | Growth over time | DimDate × Revenue |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Filter to a year | "2024 sales only." |
| Quarter | Header | Q1–Q4 | Filter to a quarter | "Q4 push." |
| Region | Header | 4 regions | Compare/focus | "East vs West." |
| Channel | Header | Store/Online | Channel focus | "Online growth." |
| Store Type | Header | Formats | Format focus | "Flagship stores." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *where do sales come from?*"
2. "We sold **1.5 million units** across **50,000 orders**, worth **$719M**."
3. "AOV is **$14,384** — high because our mix includes B2B (Enterprise + Small Business)."
4. "By region, East leads and North lags; by channel, Store is ahead; the trend is steady growth."
5. "Recommendation: run a targeted push in North and grow online."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single metric | Revenue, AOV | No chart needed |
| Bar Chart | Compare regions | Long region labels | Column overlaps labels |
| Donut Chart | Store vs Online | 2 slices | Bar overkill for 2 items |
| Column Chart | Store-type compare | Short labels | Bar wastes width |
| Line Chart | Trend | Time on X-axis | Bar hides direction |

### 7. BUSINESS INSIGHTS
- **AOV $14,384 is high** → B2B/bulk buyers; frame it as "mixed B2B + retail" so it's not read as an error.
- **East $150.5M vs North $68.4M** → North is half of East; targeted investment needed.
- **Store-type breakdown** → shows the best-performing format for expansion decisions.

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "AOV $14k — correct?" | "Yes — Enterprise & Small Business buy in bulk." | AOV KPI |
| "Why is North weak?" | "$68M vs East's $150M; footfall/store count. See Store page." | Region bar |
| "Is online catching up?" | "40% and growing; the trend shows an uptick." | Channel donut + trend |

### 9. TECHNICAL BUILD
- **DAX:** `Total Revenue`, `Total Quantity Sold`, `Total Orders`, `Average Order Value` (Revenue ÷ Orders with safe DIVIDE).
- **Tables:** `FactSales` + `DimRegion`, `DimStore`, `DimDate`.
- **Relationships:** FactSales → DimRegion/DimStore/DimDate.
- **Performance:** Integer keys + columnstore on the fact → fast aggregation.

---

## Page 3: Customer Analytics

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Question:** "Are new customers coming in, are existing ones staying, and which segment is most valuable?"
- **Decision:** Where to spend the marketing budget (acquire vs retain).
- **Money impact:** Retention drives lifetime value; a 92% active base is the profit engine to protect.

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** VP of Marketing, CMO, Customer Success.
- **Frequency:** Marketing review; campaign planning.
- **Scenario:** *"The CMO opens this before deciding a loyalty/retention campaign."*

### 3. PAGE LAYOUT EXPLANATION
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| KPI 1 | KPI Card | Active Customers **18,431** | Live base | `Active Customers` |
| KPI 2 | KPI Card | Customer Lifetime Value | Avg value per customer | `Customer Lifetime Value` |
| KPI 3 | KPI Card | New Customers | Acquisition | `New Customers` |
| KPI 4 | KPI Card | Retention Rate **~92%** | How many stayed | `Customer Retention Rate %` |
| Middle-left | Column Chart | Revenue by Segment | Compare segments | DimCustomer[Segment] × Revenue |
| Middle-right | Bar Chart | Customers by Region | Regional spread | DimCustomer[Region] × Active Customers |
| Bottom-left | Line Chart | New customer trend | Acquisition over time | DimDate × New Customers |
| Bottom-right | Donut Chart | Revenue share by Segment | Segment split % | Segment × Revenue |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Filter year | "2024 cohort." |
| Quarter | Header | Q1–Q4 | Filter quarter | "Q1 acquisition." |
| Region | Header | 4 regions | Focus region | "East customers." |
| Segment | Header | 4 segments | Focus segment | "Enterprise only." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *who is buying and are they staying?*"
2. "We have **18,400 active customers** out of 20,000 — that's **92% active**, so retention is strong."
3. "There are four segments — Enterprise, Small Business, Consumer Premium, Consumer Standard — each ~25%."
4. "Revenue is balanced across segments, so we're not over-dependent on any one."
5. "Recommendation: keep high-touch on Enterprise (highest AOV) while nurturing the rest."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single metric | Active, CLV, retention | No chart needed |
| Column Chart | Segment compare | 4 segments | Bar wastes width |
| Bar Chart | Region compare | Long labels | Column overlaps |
| Line Chart | Acquisition trend | Time on X-axis | Bar hides trend |
| Donut Chart | Segment share | 4 slices ≈ 100% | Column doesn't show share |

### 7. BUSINESS INSIGHTS
- **92% active** (18,431 / 20,000) → very low churn.
- **4 segments ~25% each** → balanced portfolio, spread risk.
- **CLV + New Customers together** → shows the acquire-vs-retain balance.

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "Most valuable segment?" | "Revenue is even, but Enterprise has the highest AOV." | Segment column/donut |
| "How much churn?" | "~8% (retention ~92%) — strong for retail." | Retention KPI |
| "Are new customers falling?" | "The trend line shows it month by month." | New-customer trend |

### 9. TECHNICAL BUILD
- **DAX:** `Active Customers`, `Customer Lifetime Value`, `New Customers`, `Customer Retention Rate %` (use `DISTINCTCOUNT` + date logic).
- **Tables:** `FactSales` + `DimCustomer` (Segment, Region).
- **Relationships:** FactSales → DimCustomer → DimDate.
- **Performance:** DISTINCTCOUNT on an integer customer key is fast.

---

## Page 4: Inventory & Supply Chain

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Question:** "Do we have the right amount of stock — not too much (cash blocked), not too little (lost sales)?"
- **Decision:** What to reorder and where to free up cash.
- **Money impact:** Only 752 out-of-stock items means very little lost-sale risk; freeing cash from over-stocked categories improves working capital.

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** VP of Operations, Supply Chain Head, Warehouse Managers.
- **Frequency:** Operations review; reorder planning; before a season.
- **Scenario:** *"Ops opens this to decide this week's reorders and to spot stockout risk."*

### 3. PAGE LAYOUT EXPLANATION
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| KPI 1 | KPI Card | Inventory Turnover | How fast stock sells | `Inventory Turnover` |
| KPI 2 | KPI Card | Stock on Hand **99.7M** | Total units | `Total Stock on Hand` |
| KPI 3 | KPI Card | Low Stock **42,953** | Reorder signal | `Low Stock Items Count` |
| KPI 4 | KPI Card | Inventory Value | Cash tied up | `Inventory Value` |
| Middle-left | Donut Chart | Value by Store Type | Where stock sits | DimStore[StoreType] × Value |
| Middle-right | Bar Chart | Value by Region | Regional stock | DimRegion × Value |
| Bottom-left | Column Chart | Out of Stock by Category | Reorder priority | DimCategory × OOS count |
| Bottom-right | Column Chart | Value by Category | Cash by category | DimCategory × Value |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Filter year | "This year's stock." |
| Quarter | Header | Q1–Q4 | Filter quarter | "Pre-season Q4." |
| Region | Header | 4 regions | Focus region | "East warehouses." |
| Category | Header | Categories | Focus category | "Electronics stock." |
| Stock Status | Header | In/Low/Out | Filter by status | "Show only Low Stock." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *is our stock balanced?*"
2. "We hold **99.7M units**. Only **752 are out-of-stock** and **42,953 are low-stock**, so availability is strong."
3. "Inventory value is spread across store type and region."
4. "The out-of-stock-by-category chart shows the urgent reorders."
5. "Recommendation: reorder the low-stock categories proactively and free cash from over-stocked ones."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single metric | Turnover, value | No chart needed |
| Donut Chart | Value share | Store types | Bar overkill |
| Bar Chart | Region compare | Long labels | Column overlaps |
| Column Chart | Category compare | Short labels | Bar wastes width |

### 7. BUSINESS INSIGHTS
- **752 out-of-stock** on a huge base → excellent availability, low lost-sale risk.
- **42,953 low-stock** → a proactive reorder signal before a stockout.
- **Value by category** → shows where cash is tied up so we can raise turnover.

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "How much cash is tied up?" | "Inventory Value KPI; the category chart shows where it's highest." | Value KPI + category chart |
| "Are we losing sales to stockouts?" | "Only 752 OOS — negligible." | OOS-by-category |
| "Is turnover good?" | "Turnover = COGS ÷ avg inventory; higher is better; compare by category." | Turnover KPI |

### 9. TECHNICAL BUILD
- **DAX:** `Inventory Turnover`, `Total Stock on Hand`, `Low Stock Items Count`, `Inventory Value`.
- **Tables:** `FactInventory` (400,000 snapshots) + `DimStore`, `DimRegion`, `DimCategory`.
- **Modeling note:** a **`StockStatus`** calculated column (In/Low/Out) makes filtering easy.
- **Performance:** inventory is semi-additive (don't SUM across dates) — measures use the latest snapshot logic.

---

## Page 5: Store Performance

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Question:** "Which stores make money and which under-perform?"
- **Decision:** Staffing (add/reduce), turnaround, or closure; where to open next.
- **Money impact:** Fixing or closing the bottom stores and right-sizing staff directly improves profit.

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** VP of Retail Operations, District Managers.
- **Frequency:** Retail ops review; store benchmarking; new-store planning.
- **Scenario:** *"The ops VP opens this to rank stores and decide staffing."*

### 3. PAGE LAYOUT EXPLANATION
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| KPI 1 | KPI Card | Total Orders | Store orders | `Total Orders` |
| KPI 2 | KPI Card | Total Revenue | Store revenue | `Total Revenue` |
| KPI 3 | KPI Card | Sales Per Associate | Staff productivity | `Sales Per Associate` |
| KPI 4 | KPI Card | Revenue Per Store | Store efficiency | `Revenue Per Store` |
| Middle-left | Bar Chart | Revenue by Store Type | Format compare | DimStore[StoreType] × Revenue |
| Middle-right | Donut Chart | Revenue by Store Size | Size impact | DimStore[StoreSize] × Revenue |
| Bottom-left | Column Chart | Revenue by Store | Top/bottom stores | DimStore[StoreName] × Revenue |
| Bottom-right | Column Chart | Revenue by Region | Region compare | DimRegion × Revenue |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Filter year | "This year." |
| Quarter | Header | Q1–Q4 | Filter quarter | "Q3 stores." |
| Region | Header | 4 regions | Focus region | "West stores." |
| Store Type | Header | Formats | Focus format | "Flagship only." |
| Store Size | Header | Small/Med/Large | Focus size | "Large stores." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *which store is efficient?*"
2. "**Revenue Per Store** and **Sales Per Associate** show productivity — per store and per staff member."
3. "By type and size we see the most efficient format."
4. "The store-name chart shows the top and bottom performers."
5. "Recommendation: coach or turn around the bottom stores; replicate what the top stores do."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single metric | Per-store/associate | No chart needed |
| Bar Chart | Type compare | Long labels | Column overlaps |
| Donut Chart | Size share | Few sizes | Bar overkill |
| Column Chart | Store ranking | Many stores | Bar too tall |

### 7. BUSINESS INSIGHTS
- **Low Sales Per Associate** → overstaffing or a training gap (an HR action).
- **Revenue Per Store** → flags under-performing stores for turnaround/closure.
- **Store size vs revenue** → shows whether bigger really means more profit.

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "Which store to close?" | "Bottom Revenue-Per-Store stores — but weigh lease/location." | Store column chart |
| "Add or cut staff?" | "Sales Per Associate shows it store by store." | Sales-Per-Associate KPI |
| "Does bigger = more profit?" | "Not always — size donut + Revenue-Per-Store together." | Size donut |

### 9. TECHNICAL BUILD
- **DAX:** `Total Orders`, `Total Revenue`, `Sales Per Associate`, `Revenue Per Store` (safe DIVIDE by counts).
- **Tables:** `FactSales` + `DimStore` (Type, Size, Name, Region).
- **Relationships:** FactSales → DimStore.
- **Performance:** aggregation on an integer store key → fast.

---

## Page 6: Product & Category

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Question:** "Which products/categories actually make money — not just volume?"
- **Decision:** Assortment (what to stock), pricing, and which brands to grow or drop.
- **Money impact:** Shifting the mix toward the **860 high-margin products** lifts the overall 16.8% margin.

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** VP of Merchandising, Category Managers, Buyers.
- **Frequency:** Merchandising review; pricing/assortment planning.
- **Scenario:** *"A category manager opens this to decide which lines to promote or drop."*

### 3. PAGE LAYOUT EXPLANATION
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| KPI 1 | KPI Card | Total Revenue **$719M** | Category revenue | `Total Revenue` |
| KPI 2 | KPI Card | Gross Margin **16.8%** | Profitability | `Gross Margin %` |
| KPI 3 | KPI Card | Quantity Sold **1.5M** | Volume | `Total Quantity Sold` |
| KPI 4 | KPI Card | High-Margin Products **860** | Products >30% margin | `High Margin Products Count` |
| Middle-left | Column Chart | Margin by Category | Which is profitable | DimCategory × Margin % |
| Middle-right | Bar Chart | Revenue by Brand | Top brands | DimProduct[Brand] × Revenue |
| Bottom-left | Column Chart | Revenue by Category | Volume leaders | DimCategory × Revenue |
| Bottom-right | Donut Chart | Revenue by Price Range | Price-band mix | DimProduct[PriceRange] × Revenue |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Filter year | "2024 assortment." |
| Quarter | Header | Q1–Q4 | Filter quarter | "Holiday quarter." |
| Region | Header | 4 regions | Focus region | "East demand." |
| Category | Header | Categories | Focus category | "Electronics." |
| Brand | Header | Brands | Focus brand | "One brand." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *which products make money?*"
2. "Total margin is **16.8%**, and we have **860 high-margin products** (30%+ margin)."
3. "The margin-by-category chart shows all categories sit at a thin 16–17% — no clear winner."
4. "Brand and price-range charts show where revenue concentrates."
5. "Recommendation: push the 860 high-margin products and renegotiate the thin categories."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single metric | Revenue, margin, count | No chart needed |
| Column Chart | Category compare | Short labels | Bar wastes width |
| Bar Chart | Brand compare | Long brand names | Column overlaps |
| Donut Chart | Price-band share | Few bands | Bar overkill |

### 7. BUSINESS INSIGHTS
- **All categories 16–17% margin** → no high-margin hero; opportunity in premium/private-label.
- **860 products at 30%+ margin** → promoting these lifts the blended margin.
- **Data-quality find:** "Furniture" vs "FURNITURE" appear as duplicates (a case difference) — flagged as a real finding (shows critical thinking).

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "How do we raise margin?" | "More high-margin mix + renegotiate thin categories." | High-margin KPI + margin chart |
| "Which brand to drop?" | "Low-revenue + low-margin brands (bottom bar)." | Brand bar |
| "What's the FURNITURE duplicate?" | "A case mismatch — I flagged it to fix in the ETL." | Category charts |

### 9. TECHNICAL BUILD
- **DAX:** `Gross Margin %` (Gross Profit ÷ Revenue), `High Margin Products Count` (DISTINCTCOUNT of products >30% margin).
- **Real fix:** threshold was 40% but the max product margin is 39.4%, so the card was blank → set to 30% → 860 products.
- **Tables:** `FactSales` + `DimProduct`, `DimCategory`.
- **Performance:** margin math is done in measures, not columns → stays fast.

---

## Page 7: Finance & Profitability

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Question:** "Where does profit really come from, and where is margin leaking?"
- **Decision:** Cost control, discount policy, and category-level profit focus.
- **Money impact:** COGS is 83% of revenue; a small cost/discount improvement moves millions ($7.2M per 1% margin).

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** CFO, VP Finance, FP&A.
- **Frequency:** Monthly close; budget planning; margin initiatives.
- **Scenario:** *"The CFO opens this at month-end to review cost and discount leakage."*

### 3. PAGE LAYOUT EXPLANATION
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| KPI 1 | KPI Card | Net Revenue | After returns/discount | `Net Revenue` |
| KPI 2 | KPI Card | Gross Margin **16.8%** | Profitability | `Gross Margin %` |
| KPI 3 | KPI Card | Total COGS **$598.2M** | Cost of goods | `Total COGS` |
| KPI 4 | KPI Card | Gross Profit **$121.0M** | Money left | `Gross Profit` |
| Middle-left | Bar Chart | Margin by Region | Which region is profitable | DimRegion × Margin % |
| Middle-right | Line Chart | Profit trend | Profit over time | DimDate × Gross Profit |
| Bottom-left | Donut Chart | Discount by Channel | Discount leakage | Channel × Total Discount |
| Bottom-right | Column Chart | Profit by Category | Profit source | DimCategory × Gross Profit |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Filter year | "FY2024 close." |
| Quarter | Header | Q1–Q4 | Filter quarter | "Q4 profit." |
| Region | Header | 4 regions | Focus region | "East margin." |
| Channel | Header | Store/Online | Focus channel | "Online discounts." |
| Category | Header | Categories | Focus category | "Electronics profit." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *are we profitable and where is margin leaking?*"
2. "Against revenue, COGS is **$598M**, leaving **$121M gross profit** — a **16.8%** margin."
3. "The profit trend shows month-by-month profit."
4. "The discount-by-channel donut shows where margin is leaking to discounts."
5. "Recommendation: tighten discounts where they're highest and renegotiate COGS."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single metric | Revenue, COGS, profit | No chart needed |
| Bar Chart | Region margin | Long labels | Column overlaps |
| Line Chart | Profit trend | Time on X-axis | Bar hides direction |
| Donut Chart | Discount share | Few channels | Bar overkill |
| Column Chart | Category profit | Short labels | Bar wastes width |

### 7. BUSINESS INSIGHTS
- **$121M profit on $719M = 16.8%** → thin margin; cost control is critical.
- **Discount-by-channel** → shows exactly where margin erodes (a direct action).
- **Revenue leaders ≠ profit leaders** → a high-revenue category can be low-profit (impresses a VP).

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "Biggest cost lever?" | "COGS at $598M — 83% of revenue. Supplier + mix." | COGS KPI |
| "Is discount under control?" | "The channel donut shows where it's highest." | Discount donut |
| "Which region is profit-heavy?" | "Margin-by-region bar — high revenue ≠ high margin." | Margin bar |

### 9. TECHNICAL BUILD
- **DAX:** `Net Revenue`, `Total COGS`, `Gross Profit` (Revenue − COGS), `Gross Margin %` (safe DIVIDE).
- **Tables:** `FactSales` + `DimRegion`, `DimDate`, `DimCategory`.
- **Relationships:** FactSales → DimRegion/DimDate/DimCategory.
- **Performance:** layered measures reuse each other → one calculation path.

---

## Page 8: Regional Comparison

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Question:** "How does each region compare, and where should we invest?"
- **Decision:** Spread best practices; fix weak regions; plan expansion.
- **Money impact:** North's gap (vs East) is the biggest single growth opportunity.

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** VP of Sales, Regional Directors, Strategy team.
- **Frequency:** Quarterly Business Review (QBR); expansion planning.
- **Scenario:** *"The VP opens this in the QBR to rank regions side by side."*

### 3. PAGE LAYOUT EXPLANATION
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| KPI 1 | KPI Card | Active Customers | Region customers | `Active Customers` |
| KPI 2 | KPI Card | Gross Margin **16.8%** | Profitability | `Gross Margin %` |
| KPI 3 | KPI Card | Total Revenue **$719M** | Region revenue | `Total Revenue` |
| KPI 4 | KPI Card | Total Orders **50,000** | Region orders | `Total Orders` |
| Middle-left | Bar Chart | Margin by Region | Profit compare | DimRegion × Margin % |
| Middle-right | Column Chart | Orders by Region | Volume compare | DimRegion × Orders |
| Bottom-left | Line Chart | Revenue trend | Growth over time | DimDate × Revenue |
| Bottom-right | Column Chart | Revenue by Region | Revenue ranking | DimRegion × Revenue |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Filter year | "2024 QBR." |
| Quarter | Header | Q1–Q4 | Filter quarter | "Q3 regions." |
| Region | Header | 4 regions | Focus/compare | "East vs North." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *how do regions compare?*"
2. "**East leads at $150M store revenue; North is last at $68M.**"
3. "We can compare each region's margin, orders, and revenue side by side."
4. "The trend shows which region is growing or slowing."
5. "Recommendation: replicate East's tactics in North — the quick win."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single metric | Revenue, margin | No chart needed |
| Bar Chart | Margin compare | Long region labels | Column overlaps |
| Column Chart | Orders/revenue compare | Few regions | Bar wastes width |
| Line Chart | Trend | Time on X-axis | Bar hides direction |

### 7. BUSINESS INSIGHTS
- **East $150.5M > West $138.8M > South $77.3M > North $68.4M** (store revenue) → a clear gap.
- **Margin-by-region** → shows whether a high-revenue region is also high-profit.
- **North's gap = the biggest growth opportunity** → a strong strategic recommendation.

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "Invest in North or double East?" | "North is the quick win (big untapped gap); East is already efficient." | Revenue-by-region |
| "Is this store revenue only?" | "Yes — e-commerce region is a roadmap item." | (context) |
| "Are regions comparable?" | "Same measures, same period — apples-to-apples." | All visuals |

### 9. TECHNICAL BUILD
- **DAX:** `Total Revenue`, `Total Orders`, `Gross Margin %`, `Active Customers` — all crossed by region.
- **Tables:** `FactSales` + `DimRegion`, `DimDate`, `DimCustomer`.
- **Pattern:** one dimension (`DimRegion`) × many measures = the classic comparison layout.
- **Performance:** shared measures + a single dimension → light and fast.

---

## Page 9: Returns Analysis

### 1. BUSINESS PROBLEM THIS PAGE SOLVES
- **Question:** "What is coming back, why, and is it under control?"
- **Decision:** Fix the root cause — product quality or product description.
- **Money impact:** Refunds are $22.87M (3.2% of revenue); reducing them reason-by-reason recovers real money.

### 2. WHO LOOKS AT THIS PAGE AND WHEN
- **Role:** VP of Operations, Customer Experience Head, Quality team.
- **Frequency:** Quality/ops review; product-issue investigation; post-season.
- **Scenario:** *"Quality opens this when a product's returns spike."*

### 3. PAGE LAYOUT EXPLANATION
| Position | Visual | What it shows | Why this visual | Data source |
|----------|--------|---------------|-----------------|-------------|
| KPI 1 | KPI Card | Avg Days to Return | Speed of return | `Avg Days to Return` |
| KPI 2 | KPI Card | Total Refund **$22.87M** | Money refunded | `Total Refund Amount` |
| KPI 3 | KPI Card | Returns Count **8,578** | How many returned | `Total Returns Count` |
| KPI 4 | KPI Card | Return Rate **~4.3%** | Share returned | `Return Rate %` |
| Middle-left | Bar Chart | Returns by Category | Which returns most | DimCategory × Returns |
| Middle-right | Donut Chart | Refund by Condition | In what condition | FactReturns[Condition] × Refund |
| Bottom-left | Column Chart | Refund by Reason | Why returned | FactReturns[Reason] × Refund |
| Bottom-right | Column Chart | Returns by Condition | Condition volume | FactReturns[Condition] × Returns |

### 4. SLICERS ON THIS PAGE
| Slicer | Position | Values | How to use | Business scenario |
|--------|----------|--------|-----------|-------------------|
| Year | Header | 2021–2025 | Filter year | "2024 returns." |
| Quarter | Header | Q1–Q4 | Filter quarter | "Post-holiday Q1." |
| Region | Header | 4 regions | Focus region | "East returns." |
| Category | Header | Categories | Focus category | "Electronics returns." |
| Reason | Header | Return reasons | Focus reason | "Defective only." |
| Condition | Header | Damaged/New/… | Focus condition | "Damaged only." |

### 5. HOW TO EXPLAIN THIS PAGE (script)
1. "This page answers: *are returns under control and why do they happen?*"
2. "Return rate is **~4.3%** — below the 5% industry target, which is good."
3. "Total refund is **$22.9M** (3.2% of revenue)."
4. "The reason chart shows why items came back; the condition chart shows their state; the category chart shows which products return most."
5. "Recommendation: fix the top return reason for the top-returning category."

### 6. CHART SELECTION REASONING
| Chart used | WHY this chart | WHEN to use | NOT this chart because |
|-----------|---------------|-------------|------------------------|
| KPI Card | Single metric | Rate, refund, count | No chart needed |
| Bar Chart | Category compare | Long labels | Column overlaps |
| Donut Chart | Condition share | Few conditions | Bar overkill |
| Column Chart | Reason compare | Short labels | Bar wastes width |

### 7. BUSINESS INSIGHTS
- **Return rate 4.3% (< 5% target)** → healthy and controlled.
- **Refund $22.87M = 3.18% of revenue** → manageable; reduce it reason-by-reason.
- **Category × Reason** → the root cause of returns (targeted fix).

### 8. QUESTIONS SOMEONE WILL ASK
| Question | Your answer | Where on the page |
|----------|-------------|-------------------|
| "Is the rate under control?" | "Yes — 4.3% vs the 5% benchmark." | Return-rate KPI |
| "Biggest reason?" | "The reason chart's top bar; cross with category for the root cause." | Reason chart |
| "Where's shipping data?" | "Shipping isn't in the model yet — an honest roadmap item." | (context) |
| "Isn't $22.9M a lot?" | "Only 3.2% of revenue — normal for retail." | Refund KPI |

### 9. TECHNICAL BUILD
- **DAX:** `Avg Days to Return`, `Total Refund Amount`, `Total Returns Count`, `Return Rate %` (Returns ÷ Sales lines).
- **Tables:** `FactReturns` + `DimCategory` (and Reason/Condition columns on the fact).
- **Note:** the page was planned as "Returns & Shipping"; shipping isn't modeled yet, so it's purely Returns — an honest roadmap item.
- **Performance:** FactReturns is small vs FactSales → the page is very fast.

---

## Section 10: Master Chart Selection Guide

> **WHAT:** A lookup table — given a business question, which chart to use and why. **WHY:** So you can justify every chart in an interview. **WHEN:** Whenever someone asks "why this chart?"

| Business question | Best chart | Why | Example from our dashboard |
|-------------------|-----------|-----|----------------------------|
| "What is the total?" | KPI Card | One number, instant | Revenue **$719M** |
| "How is it trending?" | Line Chart | Shows direction over time | Monthly revenue trend |
| "How do categories compare?" | Bar / Column | Side-by-side compare | Revenue by Category |
| "What is the split/share?" | Donut / Pie | Part-to-whole % | Store 60% vs Online 40% |
| "Where are the outliers?" | Scatter Plot | Two measures at once | Revenue vs Margin per product |
| "How does the mix change over time?" | Stacked Bar/Column | Shows composition | Channel split by quarter |
| "What is the ranking?" | Horizontal Bar | Sorted comparison | Top brands / stores |
| "Where is it geographically?" | Map | Location-based | Revenue by state (roadmap) |

**Bar vs Column rule:** long labels (region/brand names) → **horizontal bar**; short labels (months, types) → **vertical column**.

**Donut vs Pie:** same idea (part-to-whole), but a **donut** has a hole in the middle for a total label — cleaner. Use for **2–5 slices** only.

---

## Section 11: Master Slicer Usage Guide

> **WHAT:** How the filters (slicers) work and how to use them well. **WHY:** Slicers are what make a dashboard interactive; misusing them is the #1 cause of "the numbers look wrong." **WHEN:** Every demo.

**What is a slicer?** A filter control (dropdown, list, or buttons). Click a value (e.g. "East") and **every visual on the page** filters to it.

| Slicer style | When to use |
|--------------|-------------|
| **Dropdown** | Many values (e.g. Brand, Store) — saves space. |
| **List / buttons** | Few values you switch often (e.g. Channel: Store/Online). |
| **Date range (between)** | Continuous dates — pick a start and end. |

**Sync slicers across pages:** our common slicers (Year, Quarter, Region) are **synced**, so choosing a year on one page keeps it selected on the next — a consistent story.

**How to clear/reset:** open the slicer and click **Clear selection** (the eraser icon), or Ctrl-click the selected value to unselect. This resets the page to "all data."

> **Common mistake:** forgetting a slicer is still active. If a number looks wrong ("revenue is too low!"), **check the slicers first** — a Region or Year filter may still be on. Always clear filters before reading a total.

---

## Section 12: How I Would Present All 9 Pages in 10 Minutes

> **WHAT:** A timed script to present the whole dashboard. **WHY:** VPs give you 10 minutes — this keeps you on message. **WHEN:** Any executive demo.

| Time | Page | What to say (headline) |
|------|------|------------------------|
| 0–2 min | 1. Executive Overview | "Revenue **$719M**, margin **16.8%**, 50K orders, 18.4K customers — healthy but thin margin." |
| 2–4 min | 2. Sales Performance | "Sales come mostly from Store (60%) and East region; North lags at $68M." |
| 4–5 min | 3. Customer Analytics | "92% active customers, four balanced segments — strong retention." |
| 5–6 min | 7. Finance & Profitability | "COGS is $598M (83%); profit $121M; discounts leak margin in one channel." |
| 6–7 min | 8. Regional Comparison | "East leads, North is the biggest growth gap — replicate East there." |
| 7–8 min | 4. Inventory & Supply Chain | "99.7M units, only 752 out-of-stock — availability is strong." |
| 8–9 min | 9. Returns Analysis | "Return rate 4.3%, below the 5% target — quality is controlled." |
| 9–10 min | Recommendations | "Three actions: (1) push higher-margin online, (2) invest in North, (3) grow the 860 high-margin products." |

**Tip:** keep Pages 5 (Store) and 6 (Product) as backup for deep-dive questions; don't force them into the 10 minutes.

---

## Section 13: Common Interview Questions About Dashboards

> **WHAT:** The dashboard-design questions interviewers ask, with strong answers. **WHY:** These separate a builder from a designer. **WHEN:** Before any BI interview.

| Question | Strong answer |
|----------|---------------|
| "Why did you choose this chart type?" | "I match the chart to the question: line for time trends (shows direction), donut for part-to-whole (Store vs Online), bar for long labels (regions), column for short labels (months)." |
| "How do you handle too much data on one page?" | "Max ~8 visuals per page, a clear grid, slicers for filtering, and drill-through for detail — so the page stays readable." |
| "How do you ensure dashboard performance?" | "Import mode, star schema, integer surrogate keys, columnstore indexes on facts, remove unused columns, measures instead of calculated columns, and limit visuals per page." |
| "How do you handle mobile users?" | "A separate mobile layout in Power BI with a vertical arrangement of the key KPIs." |
| "How do you know if the dashboard is used?" | "Usage Metrics in the Power BI Service — who viewed, when, and which page." |
| "How do you keep numbers consistent?" | "One semantic model = one source of truth. Every visual uses the same DAX measures, so a KPI means the same thing everywhere." |
| "How do you design for a VP vs an analyst?" | "VP pages lead with KPIs and one headline; analyst pages allow drill-through and more detail." |
| "What makes a good color choice?" | "A limited brand palette (navy + orange here), green/red only for good/bad, and enough contrast for accessibility." |

---

## One-line pitch (memorize)

> *"I built an end-to-end retail analytics platform — synthetic data in Python, a star-schema warehouse in SQL Server, and 98 DAX measures with 9 interactive dashboards in Power BI — that presents a **$719M** revenue business to executives as a single cockpit view, with real insights and honest data-quality findings."*
