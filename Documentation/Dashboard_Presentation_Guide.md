# ShopStar Retail — Dashboard Presentation Guide (VP / CEO Edition)

> **Purpose of this document:** This is a *learning + presentation* guide. Its job is to help you confidently present each dashboard to a VP or CEO — what to show, why to show it, and how to answer tough questions if they come up.
>
> **How to read this:** Every dashboard follows a fixed format — **WHO, WHAT, WHY, WHEN, HOW to explain (script), KEY VISUALS, BUSINESS INSIGHTS, VP QUESTIONS & ANSWERS, HOW THIS WAS BUILT.** Every technical term is explained in one plain line.
>
> **Golden rule for a VP demo:** Say the *number* first, then the *"so what"* (what it means), then the *action* (what we should do). A VP does not want the name of a chart — they want a decision.

---

## Quick Glossary (learn these before you speak)

| Term | 1-line meaning |
|------|----------------|
| **Revenue** | Total sales money earned (before cost). Here **$719.2M**. |
| **COGS** (Cost of Goods Sold) | The cost to make or buy the products. Here **$598.2M**. |
| **Gross Profit** | Revenue − COGS = what is left. Here **$121.0M**. |
| **Gross Margin %** | Profit ÷ Revenue. How much money is kept from every $1 of sales. Here **16.8%**. |
| **AOV** (Average Order Value) | The average size of one order. Here **$14,384**. |
| **Channel** | Where the sale happened — Store (physical) or E-commerce (online). |
| **Segment** | The type of customer — Enterprise, Small Business, Consumer Premium/Standard. |
| **Return Rate %** | How many items were returned. Here **~4.3%** (target < 5%, which is good). |
| **Measure** | A calculation (a DAX formula) such as "Total Revenue". It produces a number. |
| **Slicer** | A filter button or dropdown — pick a Year/Region and the whole page filters. |
| **KPI card** | A single big number box (such as Revenue). "KPI" = Key Performance Indicator. |
| **Star schema** | A data design — facts (sales) in the middle, dimensions (product, customer) around them. Fast and clean. |

---

## Dashboard 1: Executive Overview

**WHO (audience):** CEO, VP of Sales, Board members. The most senior people who need the whole company's health in 30 seconds.

**WHAT (what it shows):** On a single screen, the company's top-line health — total Revenue, Gross Margin %, total Orders, and Active Customers — plus the revenue trend over time and the breakdown by category, region, and channel.

**WHY (business value):** This is the "cockpit view". A VP can tell at a glance whether the company is growing and whether profit is healthy — without going into the detail.

**WHEN (when to use):** The *first* slide of a monthly leadership review. Or whenever an outsider (an investor) asks for a 2-minute summary.

**HOW to explain — VP script (say this):**
> "Starting from the top-left: our total revenue is **$719 million** and gross margin is **16.8%**. We have **50,000 orders** and **18,400 active customers**. The trend line below shows how revenue moved month over month. The category chart shows Office Supplies and Technology are the top revenue drivers, and the channel donut shows that **60% comes from Store and 40% from online**. The overall picture is stable — margin is a little thin, and we will look at that in detail on the Finance page."

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Total Revenue | KPI card | `Total Revenue` | Company total sales = $719M |
| Gross Margin % | KPI card | `Gross Margin %` | Profitability = 16.8% |
| Total Orders | KPI card | `Total Orders` | 50,000 orders |
| Active Customers | KPI card | `Active Customers` | 18,431 active buyers |
| Revenue Trend | Line chart | YearMonth × Total Revenue | Flow of revenue over time |
| Revenue by Category | Column chart | CategoryName × Total Revenue | Which category is on top |
| Revenue by Region | Bar chart | RegionName × Total Revenue | Which region is on top (East) |
| Revenue by Channel | Donut chart | Channel × Total Revenue | Store vs Online split |

**BUSINESS INSIGHTS (real data):**
- Revenue is **$719.2M**, but gross margin is only **16.8%** — this means high volume but thin profit. This is the biggest talking point.
- **Store channel is 60%** and E-commerce is 40% — physical stores are still the backbone, and online is the growth opportunity.
- Top categories (Office Supplies $147.8M, Technology $145.2M, Electronics $142.9M) all sit at **16–17% margin** — there is no single "cash cow"; they are all similar.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "Why is margin only 16.8%?" | "Retail is a volume business; COGS is $598M. The Finance page has category-wise margin and discount leakage in detail." |
| "Which channel should we grow?" | "E-commerce is at 40% but has a lower cost-to-serve. Pushing online can improve margin." |
| "How fresh is the data?" | "The warehouse refreshes through a nightly ETL; this is a full-year snapshot." |
| "Are the numbers reliable?" | "All measures come from one single star-schema warehouse — one source of truth." |

**HOW THIS WAS BUILT:** The 4 KPI cards come from DAX measures in the `_Measures` table, and the 4 charts cross `DimDate`, `DimCategory`, `DimRegion`, and `FactSales[Channel]` with the `Total Revenue` measure. Everything sits on a Power BI star schema (facts + dimensions). *(Star schema = sales facts in the middle, dimensions around them.)*

---

## Dashboard 2: Sales Performance

**WHO:** VP of Sales, Regional Sales Managers.

**WHAT:** The depth of sales — Revenue, Quantity Sold, Orders, Average Order Value, plus revenue by Region, Channel, Store Type, and the monthly trend.

**WHY:** It shows *where sales are coming from* and whether *order size* is healthy. AOV tells you how much a customer spends per order.

**WHEN:** Weekly or monthly sales review. When target vs actual is being discussed.

**HOW to explain — VP script:**
> "We sold **1.5 million units** and earned **$719M** across **50,000 orders**. The average order value is **$14,400** — this is high because our mix is B2B (Enterprise and Small Business), not only retail consumers. By region, East leads; by channel, Store is ahead; and the trend line shows steady month-over-month growth."

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Total Revenue | KPI card | `Total Revenue` | $719M |
| Total Quantity Sold | KPI card | `Total Quantity Sold` | 1.5M units |
| Total Orders | KPI card | `Total Orders` | 50,000 |
| Average Order Value | KPI card | `Average Order Value` | $14,384 |
| Revenue by Region | Bar chart | RegionName × Revenue | East on top |
| Revenue by Channel | Donut chart | Channel × Revenue | Store 60% |
| Revenue by Store Type | Column chart | StoreType × Revenue | Which format is best |
| Revenue Trend | Line chart | YearMonth × Revenue | Growth over time |

**BUSINESS INSIGHTS:**
- **AOV of $14,384** is high — a sign of B2B / bulk buyers. Frame it as "mixed B2B + retail" (otherwise the VP may think it is an error).
- East is the strongest region (**$150.5M store sales**), North is the weakest (**$68.4M**) — a targeted push is needed in North.
- The store-type breakdown shows which store format brings in the most revenue — useful for expansion decisions.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "AOV is $14k? Is that correct?" | "Yes. Our customer base includes Enterprise and Small Business who buy in bulk, so the average is high." |
| "Why is North weak?" | "North store revenue is $68M, half of East's $150M. Store count/footfall may be low — we will drill into it on the Store Performance page." |
| "Why is online behind?" | "Online is at 40% but growing fast. The trend line shows an uptick in recent months." |

**HOW THIS WAS BUILT:** The 4 KPI cards use revenue/quantity/orders/AOV measures; the charts cross `DimRegion`, `FactSales[Channel]`, `DimStore[StoreType]`, and `DimDate` with `Total Revenue`. The AOV measure = Revenue ÷ Orders (using DAX DIVIDE, a safe divide so a zero does not cause an error).

---

## Dashboard 3: Customer Analytics

**WHO:** VP of Marketing, Customer Success, CMO.

**WHAT:** The health of the customer base — Active Customers, Customer Lifetime Value (CLV), New Customers, Retention Rate — plus revenue by Segment and customers by Region.

**WHY:** Are new customers coming in? Are existing ones staying? Which segment is most valuable? The marketing budget is decided from here.

**WHEN:** Marketing review, retention/loyalty campaign planning.

**HOW to explain — VP script:**
> "We have **18,400 active customers** out of 20,000 — that is **92% active**, so retention is strong. There are four segments — Enterprise, Small Business, Consumer Premium, and Consumer Standard — each roughly equal at about 25%. By revenue, no single segment dominates, so risk is spread out. The new-customer trend and CLV together show we are maintaining both growth and value."

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Active Customers | KPI card | `Active Customers` | 18,431 |
| Customer Lifetime Value | KPI card | `Customer Lifetime Value` | Average value per customer |
| New Customers | KPI card | `New Customers` | New buyers |
| Retention Rate % | KPI card | `Customer Retention Rate %` | How many stayed |
| Revenue by Segment | Column chart | Segment × Revenue | Which segment is on top |
| Customers by Region | Bar chart | Region × Active Customers | Regional spread |
| New Customer Trend | Line chart | YearMonth × New Customers | Acquisition over time |
| Revenue Share by Segment | Donut chart | Segment × Revenue | Segment split % |

**BUSINESS INSIGHTS:**
- **92% active rate** (18,431 / 20,000) — very healthy, low churn.
- 4 segments at **~25% each** — a well-balanced portfolio, no over-dependence on any one.
- Looking at CLV and New Customers together shows the "acquire vs retain" balance.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "Which segment is most valuable?" | "Revenue is roughly equal, but Enterprise has the highest AOV — high-touch account management is worth it." |
| "How much churn?" | "Retention is ~92%, so churn is ~8% — strong for retail." |
| "Are new customers falling?" | "The trend line shows it month by month; if there is a dip, we adjust marketing spend." |

**HOW THIS WAS BUILT:** The cards use CLV/retention/new-customer measures (DAX with `DISTINCTCOUNT` and date logic). The charts sit on `DimCustomer[Segment]` and `DimCustomer[Region]`. *(DISTINCTCOUNT = counts unique customers and does not count duplicates.)*

---

## Dashboard 4: Inventory & Supply Chain

**WHO:** VP of Operations, Supply Chain Head, Warehouse managers.

**WHAT:** The health of stock — Inventory Turnover, Total Stock on Hand, Low Stock Items, Inventory Value — plus inventory value by Store Type and Region, and out-of-stock by Category.

**WHY:** Too much stock = cash blocked. Too little stock = missed sales (out of stock). This dashboard balances the two.

**WHEN:** Operations review, reorder planning, before a season.

**HOW to explain — VP script:**
> "We have **99.7 million units** on hand. **42,953 items are low-stock** and only **752 are out-of-stock** — which means availability is strong. Inventory value is distributed across store type and region. The out-of-stock chart shows which category needs an urgent reorder. The turnover metric shows how quickly stock sells."

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Inventory Turnover | KPI card | `Inventory Turnover` | How many times stock sold |
| Total Stock on Hand | KPI card | `Total Stock on Hand` | 99.7M units |
| Low Stock Items | KPI card | `Low Stock Items Count` | 42,953 |
| Inventory Value | KPI card | `Inventory Value` | Blocked capital |
| Value by Store Type | Donut chart | StoreType × Inventory Value | Where stock is highest |
| Value by Region | Bar chart | RegionName × Inventory Value | Stock by region |
| Out of Stock by Category | Column chart | CategoryName × Out of Stock Count | Reorder priority |
| Value by Category | Column chart | CategoryName × Inventory Value | Which category has cash tied up |

**BUSINESS INSIGHTS:**
- **752 out-of-stock** items out of a huge base — availability is excellent, lost-sale risk is low.
- **42,953 low-stock** — a signal to reorder proactively, before a stockout happens.
- Viewing inventory value by category lets us free up cash in over-stocked categories.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "How much cash is tied up in stock?" | "The Inventory Value card shows the total; the category chart shows where it is highest — that is where we increase turnover." |
| "Are we missing sales from stockouts?" | "Only 752 OOS items — negligible. The 42,953 low-stock items are triggered by the reorder point." |
| "Is turnover good?" | "Turnover = COGS ÷ average inventory. Higher is better; comparing by category helps us catch slow movers." |

**HOW THIS WAS BUILT:** Built on `FactInventory` snapshots (400,000 rows). The low/OOS flags come from boolean columns; I also created a **`StockStatus`** calculated column (In Stock / Low Stock / Out of Stock) to make filtering easy. Charts sit on `DimStore`, `DimRegion`, and `DimCategory`. *(Calculated column = a new column in a table built from a DAX formula.)*

---

## Dashboard 5: Store Performance

**WHO:** VP of Retail Operations, Store District Managers.

**WHAT:** Store-level performance — Total Orders, Revenue, Sales Per Associate, Revenue Per Store — plus revenue by Store Type, Store Size, individual Store Name, and Region.

**WHY:** Which store is profitable, which one under-performs. Staffing and expansion decisions come from here.

**WHEN:** Retail ops review, store benchmarking, new-store planning.

**HOW to explain — VP script:**
> "This page compares each store. **Revenue Per Store** and **Sales Per Associate** show productivity — how much each staff member and each store earns. Looking by store type and size shows which format is most efficient. The store-name chart shows both top and bottom performers — the bottom ones are improvement candidates."

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Total Orders | KPI card | `Total Orders` | Store orders |
| Total Revenue | KPI card | `Total Revenue` | Store revenue |
| Sales Per Associate | KPI card | `Sales Per Associate` | Staff productivity |
| Revenue Per Store | KPI card | `Revenue Per Store` | Store efficiency |
| Revenue by Store Type | Bar chart | StoreType × Revenue | Format comparison |
| Revenue by Store Size | Donut chart | StoreSize × Revenue | Size impact |
| Revenue by Store | Column chart | StoreName × Revenue | Top/bottom stores |
| Revenue by Region | Column chart | Region × Revenue | Region comparison |

**BUSINESS INSIGHTS:**
- If **Sales Per Associate** is low, it points to overstaffing or a training gap — an actionable HR insight.
- **Revenue Per Store** identifies under-performing stores — candidates for a turnaround or closure.
- Store size vs revenue shows whether larger stores earn proportionally more.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "Which store should we close?" | "Look at the bottom Revenue-Per-Store stores; but first weigh it against location and lease cost." |
| "Add staff or reduce staff?" | "The Sales Per Associate metric shows it — low stores have a training/mix issue, high stores may need added capacity." |
| "Does a bigger store mean more profit?" | "Not necessarily — the Store Size donut and Revenue Per Store together show the real efficiency." |

**HOW THIS WAS BUILT:** Built by joining `FactSales` to `DimStore`. Per-store and per-associate measures use DAX (Revenue ÷ store count / associate count, with safe DIVIDE). Charts sit on `DimStore[StoreType]`, `[StoreSize]`, `[StoreName]`, and `[Region]`.

---

## Dashboard 6: Product & Category

**WHO:** VP of Merchandising, Category Managers, Buyers.

**WHAT:** Product/category profitability — Revenue, Gross Margin %, Quantity Sold, High Margin Products Count — plus margin by Category, revenue by Brand, revenue by Category, and Price Range.

**WHY:** Which product/category makes money vs just volume. Assortment (which items to stock) decisions come from here.

**WHEN:** Merchandising review, pricing/assortment planning.

**HOW to explain — VP script:**
> "This page looks at products from a profitability angle. Total margin is **16.8%**, and we have **860 high-margin products** (those with 30%+ margin). The category-margin chart shows all categories sit at a thin margin (16–17%) — no clear winner. The brand and price-range charts show which brand and which price band bring in the most revenue."

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Total Revenue | KPI card | `Total Revenue` | $719M |
| Gross Margin % | KPI card | `Gross Margin %` | 16.8% |
| Total Quantity Sold | KPI card | `Total Quantity Sold` | 1.5M units |
| High Margin Products | KPI card | `High Margin Products Count` | 860 products (>30% margin) |
| Margin by Category | Column chart | CategoryName × Gross Margin % | Which category is profitable |
| Revenue by Brand | Bar chart | Brand × Revenue | Top brands |
| Revenue by Category | Column chart | CategoryName × Revenue | Volume leaders |
| Revenue by Price Range | Donut chart | PriceRange × Revenue | Price band mix |

**BUSINESS INSIGHTS:**
- All categories sit at **16–17% margin** — not a single high-margin hero. Opportunity: push premium / private-label.
- **860 products at 30%+ margin** — promoting these can lift the overall margin.
- **Data-quality finding:** "Furniture" and "FURNITURE" appear as duplicates (a case difference) — I flagged this as a real finding. It shows that you look at data critically.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "How do we increase margin?" | "Increase the mix of the 860 high-margin products, and renegotiate pricing/suppliers on the thin categories." |
| "Which brand should we drop?" | "Low-revenue + low-margin brands (bottom bar) are candidates; but some strategic brands must be kept." |
| "What is this FURNITURE duplicate?" | "A data-entry inconsistency — the same category under two names. I flagged it; it should be standardized in the ETL." |

**HOW THIS WAS BUILT:** The `Gross Margin %` measure = Gross Profit ÷ Revenue. `High Margin Products Count` = DISTINCTCOUNT of products with margin > 30% (the threshold was 40% at first, but the maximum product margin is 39.4%, so I set it to 30% to stop the card showing blank — this was a real debugging fix). Charts sit on `DimCategory`, `DimProduct[Brand]`, and `DimProduct[PriceRange]`.

---

## Dashboard 7: Finance & Profitability

**WHO:** CFO, VP Finance, FP&A team.

**WHAT:** A financial deep-dive — Net Revenue, Gross Margin %, Total COGS, Gross Profit — plus margin by Region, profit trend, discount by Channel, and profit by Category.

**WHY:** This is the "real money" story — cost, discount leakage, and the source of profit. The CFO's favourite page.

**WHEN:** Monthly financial close review, budget planning, margin improvement initiatives.

**HOW to explain — VP script:**
> "Financially: against Net Revenue, COGS is **$598M**, which gives Gross Profit of **$121M** and a margin of **16.8%**. The profit-trend line shows profit month by month. The discount-by-channel donut is important — it shows where margin is leaking due to discounts. The category-profit chart shows where real profit comes from (profit, not revenue)."

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Net Revenue | KPI card | `Net Revenue` | Revenue after returns/discount |
| Gross Margin % | KPI card | `Gross Margin %` | 16.8% |
| Total COGS | KPI card | `Total COGS` | $598.2M |
| Gross Profit | KPI card | `Gross Profit` | $121.0M |
| Margin by Region | Bar chart | RegionName × Gross Margin % | Which region is profitable |
| Profit Trend | Line chart | YearMonth × Gross Profit | Profit over time |
| Discount by Channel | Donut chart | Channel × Total Discount | Discount leakage |
| Profit by Category | Column chart | CategoryName × Gross Profit | Profit source |

**BUSINESS INSIGHTS:**
- **Gross Profit of $121M on $719M revenue = 16.8%** — a thin margin, so cost control is critical.
- **Discount by channel** shows where margin is being eroded by discounts — a direct action item.
- Revenue leaders and profit leaders can be different — a high-revenue category can give low profit. This distinction impresses a VP.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "What is the biggest cost lever?" | "COGS at $598M — 83% of revenue. Supplier renegotiation and a mix shift will move margin." |
| "Is discount under control?" | "The channel-wise discount donut shows where it is highest; we tighten the promo policy there." |
| "Which region is profit-heavy?" | "The margin-by-region bar shows it; a high-revenue region does not necessarily have a high margin." |

**HOW THIS WAS BUILT:** The finance measures — `Net Revenue`, `Total COGS`, `Gross Profit`, `Gross Margin %` — are layered in DAX (Gross Profit = Revenue − COGS; Margin = Gross Profit ÷ Revenue with a safe DIVIDE). Charts sit on `DimRegion`, `DimDate`, `FactSales[Channel]`, and `DimCategory`.

---

## Dashboard 8: Regional Comparison

**WHO:** VP of Sales, Regional Directors, expansion/strategy team.

**WHAT:** A region-vs-region battle card — Active Customers, Gross Margin %, Revenue, Orders — plus margin, orders, and revenue by Region, and the revenue trend.

**WHY:** It benchmarks one region against another. Used to spread best practices and fix weak regions.

**WHEN:** Regional business review (QBR — Quarterly Business Review), expansion planning.

**HOW to explain — VP script:**
> "This page places the regions side by side. **East leads at $150M store revenue, and North is last at $68M.** You can compare each region's margin, orders, and revenue. The trend line shows which region is growing or slowing. The idea is to replicate East's winning tactics in North."

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Active Customers | KPI card | `Active Customers` | Region customers |
| Gross Margin % | KPI card | `Gross Margin %` | 16.8% |
| Total Revenue | KPI card | `Total Revenue` | $719M |
| Total Orders | KPI card | `Total Orders` | 50,000 |
| Margin by Region | Bar chart | RegionName × Gross Margin % | Profit comparison |
| Orders by Region | Column chart | RegionName × Total Orders | Volume comparison |
| Revenue Trend | Line chart | YearMonth × Revenue | Growth over time |
| Revenue by Region | Column chart | RegionName × Total Revenue | Revenue ranking |

**BUSINESS INSIGHTS:**
- **East $150.5M > West $138.8M > South $77.3M > North $68.4M** (store revenue). A clear gap.
- Margin-by-region shows whether a high-revenue region is also high-profit.
- North's gap = the biggest growth opportunity. This is a strong strategic recommendation.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "Invest in North or double-down on East?" | "North's absolute gap is large (untapped), and East's efficiency is already high — a mix of both, but North is the quick win." |
| "Is this store revenue only?" | "Yes, region attribution is on store sales; e-commerce region needs to be modeled separately (a roadmap item)." |
| "Are the regions comparable?" | "Same measures, same time period — apples-to-apples. There is also a per-customer metric for customer-base differences." |

**HOW THIS WAS BUILT:** All visuals cross `DimRegion[RegionName]` with different measures (Revenue, Orders, Margin, Customers). One dimension with multiple measures is the classic comparison pattern.

---

## Dashboard 9: Returns Analysis

**WHO:** VP of Operations, Customer Experience Head, Quality team.

**WHAT:** The full returns story — Avg Days to Return, Total Refund Amount, Total Returns Count, Return Rate % — plus returns by Category, refund by Condition, refund by Reason, and returns by Condition.

**WHY:** Returns = lost revenue + cost. By understanding why and what is coming back, we fix the root cause.

**WHEN:** Quality/ops review, product-issue investigation, post-season analysis.

**HOW to explain — VP script:**
> "Our **return rate is ~4.3%** — below the industry target of 5%, which is good. Total refund is **$22.9M** (3.2% of revenue). The reason chart shows why items came back (defect, wrong item, etc.), and the condition chart shows what state they came back in. The category chart shows which products are returned most — that is where we fix quality or the description. Avg-days-to-return shows how quickly a customer returns."

> **Note:** This page was originally planned as "Returns & Shipping", but shipping data is not yet in the model — so it is purely **Returns Analysis**. Shipping is an honest roadmap item (state this to the VP with confidence).

**KEY VISUALS:**

| Visual | Type | Field | What it shows |
|--------|------|-------|---------------|
| Avg Days to Return | KPI card | `Avg Days to Return` | How many days to return |
| Total Refund Amount | KPI card | `Total Refund Amount` | $22.87M |
| Total Returns Count | KPI card | `Total Returns Count` | 8,578 returns |
| Return Rate % | KPI card | `Return Rate %` | ~4.3% |
| Returns by Category | Bar chart | CategoryName × Returns Count | Which category returns most |
| Refund by Condition | Donut chart | Condition × Refund Amount | In what condition |
| Refund by Reason | Column chart | Reason × Refund Amount | Why returned |
| Returns by Condition | Column chart | Condition × Returns Count | Condition volume |

**BUSINESS INSIGHTS:**
- **Return rate 4.3% (< 5% target)** — healthy and well-controlled.
- **Refund $22.87M = 3.18% of revenue** — manageable, but can be reduced further by looking reason-wise.
- Crossing Category + Reason shows which product is returned and why — a targeted quality fix.

**VP QUESTIONS & ANSWERS:**

| The VP will ask | Your answer |
|-----------------|-------------|
| "Is the return rate under control?" | "Yes, 4.3% is below the industry benchmark of 5%. The trend is stable." |
| "What is the biggest return reason?" | "The reason chart's top bar shows it; crossing it with category gives the root cause." |
| "Where is the shipping data?" | "Shipping is not yet in the warehouse model — a transparent roadmap item; for now the focus is returns." |
| "Isn't $22.9M in refunds a lot?" | "It is only 3.2% of revenue — normal for retail. There is a plan to reduce it reason-by-reason." |

**HOW THIS WAS BUILT:** Built on `FactReturns`. Return Rate % = Returns ÷ Sales lines. Charts sit on `DimCategory` and `FactReturns[Reason]` / `[Condition]`. Both refund and count measures are provided so that both "how many" and "how much money" are visible.

---

## Section 10: How to Present to a VP/CEO (10 practical tips)

1. **Number → So-what → Action.** "Revenue $719M *(number)*, margin only 16.8% *(so-what: thin)*, so we should review pricing *(action)*." Just saying a number bores a VP.
2. **Start top-left, go clockwise.** On every page, start with the top-left KPI, then the charts. Predictable = professional.
3. **One page = one story.** Every dashboard has one main message. Say it first in one line: "This page tells us that..."
4. **Round the big numbers.** "$719 million", "East is highest", "~4%". A VP does not want decimals.
5. **Admit the weakness first.** Margin is thin, FURNITURE is a duplicate, shipping is not modeled — say these yourself. It builds credibility.
6. **"I don't know" is OK.** "That is not in the data yet, I will check and get back to you" — better than guessing.
7. **Use the slicers live.** If the VP says "show only East", click the Region slicer and show it instantly. This is the "wow" moment.
8. **Keep a reason ready for every chart.** "Why a donut? Because there are only two channels — a donut is best for part-to-whole." (See Section 12.)
9. **Do not waste time.** A VP has 5–10 minutes. Executive Overview → 1–2 pages in their area → questions. Keep the rest as backup.
10. **End with a recommendation.** "My three recommendations: (1) push online, (2) invest in North, (3) increase the high-margin product mix." A VP wants action.

---

## Section 11: Common VP Questions & Answer Frameworks

These are ready-made frameworks — useful on any page.

| Question type | What the VP asks | Answer framework |
|---------------|------------------|------------------|
| **Trust/data** | "Are these numbers correct?" | "All from one single warehouse (one source of truth), on a star-schema, refreshed by a nightly ETL — consistent and auditable." |
| **Freshness** | "How old is the data?" | "The warehouse refreshed last night; the measures come from the live model." |
| **Why this chart** | "Why a line chart?" | "A line for time trend, a donut for part-to-whole, a bar/column for category comparison." |
| **Drill-down** | "Show me the detail" | "I filter with a slicer" or "this measure can drill further — this is the summary view for now." |
| **Benchmark** | "Is this good or bad?" | Always give a reference: "Return rate 4.3% vs the 5% industry target — good." |
| **Money impact** | "How much benefit is that?" | Convert to a number: "1% of margin = ~$7M on $719M revenue." |
| **Action** | "What do we do now?" | 2–3 concrete steps: pricing / mix / region / channel. |
| **Limitation** | "Why isn't this here?" | Honestly: "Shipping / e-commerce-region is not modeled yet — a roadmap item." |
| **Comparison** | "Versus last year?" | "This is a single snapshot for now; time-intelligence (YoY) is being added in the next phase." |
| **Confidence check** | "How do you know?" | "The measure's DAX logic is X, the source table is Y — I can show it." |

**The 1% rule (remember this):** On $719M of revenue, a **1% margin improvement ≈ $7.2M** of extra profit. Saying this helps the VP grasp the scale.

---

## Section 12: How I Built This (Portfolio / Interview Explanation)

This section is for interviews — when the interviewer asks "how did you build this project?"

**Architecture in one line:** CSV data → SQL Server warehouse (star schema) → Power BI semantic model (DAX measures) → 9 dashboards.

**End-to-end flow (the order to say it in):**
1. **Data generation** — I used Python (`generate_dataset.py`) to create realistic retail data (customers, orders, products, returns, inventory) — 12 CSV files.
2. **Landing → Staging → Warehouse** — a 3-layer ETL in SQL. Landing (raw), Staging (clean), Warehouse (star schema: `Fact*` + `Dim*` tables). *(ETL = Extract, Transform, Load — moving and cleaning data.)*
3. **Star schema** — `FactSales`, `FactReturns`, `FactInventory` in the middle; `DimDate`, `DimProduct`, `DimCustomer`, `DimStore`, `DimRegion`, `DimCategory` around them. Fast queries and a clean model.
4. **Kimball -1 members** — each dimension has an "Unknown" row (SK = -1) so that orphan records (with no match) are still counted — a standard data-warehouse practice.
5. **Semantic model** — in Power BI I built **98 DAX measures** using the TMDL format (text-based model files) — Revenue, Margin, CLV, Retention, Inventory Turnover, Return Rate, and more.
6. **9 dashboards** — each page has 4 KPI cards + 4 charts on a consistent grid layout. A custom brand theme (navy `#1B365D` + orange `#F7941D`) and the ShopStar logo.
7. **Slicers** — every page has interactive filters (Year, Quarter, Region + page-specific) so a VP can filter live.
8. **Source control** — the whole project is versioned on Git/GitHub in the PBIP (text-based Power BI) format so changes can be diffed.

**Chart selection logic (interview gold):**
| Chart | When I used it | Why |
|-------|----------------|-----|
| **KPI card** | A single big number (Revenue) | Instant focus, no clutter |
| **Line chart** | Time trend (YearMonth) | Best for time — shows the flow |
| **Column chart** | Category/segment comparison (vertical) | Compares discrete categories |
| **Bar chart** | Region/brand comparison (horizontal) | Long labels (region names) fit well |
| **Donut chart** | Part-to-whole (Channel, Segment) | Shows the share of 2–5 slices |

**Real problems I solved (be sure to mention these — they show depth):**
- **Blank KPI bug:** The "High Margin Products" card was coming up blank because the threshold was 40% but the maximum product margin is 39.4%. I verified this against the data and set the threshold to 30% → 860 products. *(Lesson: always verify assumptions against the data.)*
- **"(Blank)" & "Unknown" labels:** The Kimball -1 member had a NULL Brand and an "Unknown" Category — I fixed it in both Power Query (M) and SQL ("Unbranded" / "Uncategorized").
- **Data-quality find:** "Furniture" vs "FURNITURE" duplicate (a case mismatch) — a real dataset issue I caught on the dashboard.
- **Theme error:** The custom theme was missing the `reportVersionAtImport` property — I debugged it from the Power BI Desktop error and added it.

**Tech stack (say it in one breath):** Python (Pandas, Pillow) · SQL Server (T-SQL, star schema, stored-procedure ETL) · Power BI (TMDL, DAX, PBIP) · Git/GitHub.

**Skills this project demonstrates:** data engineering (ETL), dimensional modeling (Kimball star schema), DAX (98 measures), data visualization (design principles), debugging, and business storytelling.

> **One-line pitch (memorize it):** *"I built an end-to-end retail analytics platform — synthetic data with Python, a star-schema warehouse in SQL Server, and 98 DAX measures with 9 interactive dashboards in Power BI — that presents a $719M revenue business to executives as a single cockpit view."*
