# ShopStar Retail — Business Insights Report

> **Data basis:** all figures are computed directly from the source dataset
> (`Dataset/*.csv`, 201,473 sales lines) and reconcile with the Power BI model
> measures. No figures are estimated or invented.
>
> **Reconciliation note:** if your Power BI **Total Revenue** card shows a smaller
> number than $719M, the model's `FactSales` is being limited by a load step or an
> active date/slicer filter — the full-data revenue is **$719.2M**.

---

## 1. Executive summary

| KPI | Value |
|-----|-------|
| Total Revenue | **$719.2M** |
| Cost of Goods Sold | $598.2M |
| Gross Profit | **$121.0M** |
| Gross Margin | **16.8%** |
| Orders | 50,000 |
| Average Order Value | $14,385 |
| Units Sold | 1,506,431 |
| Sales Lines | 201,473 |
| Return Rate | 4.26% (within 5% target) |
| Refunds | $22.9M (3.18% of revenue) |
| Customers | 20,000 total · 18,431 active (92%) |

ShopStar is a **mixed B2B/B2C retailer**: the four customer segments (Enterprise,
Small Business, Consumer Premium, Consumer Standard) each hold ~25% of the base,
and the presence of Enterprise & Small Business buyers explains the high
**$14.4K average order value** — many orders are bulk/business purchases, not
single-item consumer baskets.

---

## 2. Revenue distribution

**By channel**
| Channel | Revenue | Share |
|---------|---------|-------|
| Store | $435.1M | **60.5%** |
| E-commerce | $291.5M | **39.5%** *(40.5% of matched sales)* |

The business is **store-led (60/40)** — physical retail still drives the majority
of revenue, but e-commerce at ~40% is a substantial second channel worth
protecting and growing.

**By region** *(store channel; e-commerce orders are not tied to a store region)*
| Region | Revenue | Share of total |
|--------|---------|----------------|
| **East** | $150.5M | 20.9% |
| West | $138.8M | 19.3% |
| South | $77.3M | 10.8% |
| North | $68.4M | 9.5% |

**Top region: East.** East + West together are ~70% of *store* revenue; North and
South materially trail and are the clearest intervention/investment targets.

---

## 3. Category performance

| Category | Revenue | Margin % |
|----------|---------|----------|
| Office Supplies | $147.8M | 17.2% |
| Technology Accessories | $145.2M | 16.4% |
| Electronics | $142.9M | 16.3% |
| Home & Kitchen | $133.8M | 17.1% |
| Furniture | $122.3M | 16.9% |
| *FURNITURE (dupe)* | $26.6M | 16.1% |

**Key finding — margins are thin and uniform (16–17%).** Unlike the common
assumption that some categories carry premium margins, ShopStar's categories sit
in a tight band. That means **profit is driven by mix, pricing, and discount
discipline — not by category selection.** Revenue is also well-diversified: no
single category exceeds ~21% of sales, reducing concentration risk.

**Data-quality finding:** `Furniture` and `FURNITURE` appear as **two separate
categories** due to a casing inconsistency in the source data ($122.3M vs $26.6M).
Combined, Furniture is ~$148.9M — on par with Office Supplies. This should be
normalised in the staging layer.

---

## 4. Returns & post-purchase

- **Return rate 4.26%** (8,578 returns across 201,473 lines) — **inside the 5%
  target**, but at a level worth watching.
- **Refunds $22.9M** = 3.18% of revenue — a direct hit to the thin 16.8% margin.
- Reason and product-condition analysis (Dashboard 9) is where refund reduction
  pays off fastest.
- *Shipping/carrier delivery KPIs are future work — `shipping.csv` is not yet
  modelled as a fact table.*

---

## 5. Inventory efficiency

- **99.7M units** on hand across **400,000** daily snapshots.
- **Out-of-stock:** only 752 snapshots — availability is strong.
- **Low-stock:** 42,953 snapshots below reorder point — the reorder policy, not
  stockouts, is the main working-capital lever.
- Track **inventory turnover against the 8× target** on Dashboard 4; a large
  low-stock count alongside high on-hand units suggests **uneven distribution**
  (some SKUs/stores overstocked while others dip below reorder).

---

## 6. Customer insights

- **92% of customers are active** (18,431 / 20,000) — a healthy, engaged base.
- **Balanced segments** (~25% each): Small Business 25.4%, Consumer Premium 25.0%,
  Enterprise 24.9%, Consumer Standard 24.8%. Revenue is not hostage to one segment.
- Enterprise + Small Business (~50%) underpin the high AOV and are the retention
  priority — losing a business account costs far more than a single consumer.

---

## 7. Recommendations (data-driven)

1. **Fix the Furniture/FURNITURE split** in staging (case-normalise category
   names). It distorts category ranking and any category-level target.
2. **Grow North & South** — they lag East/West by ~2×. Targeted assortment,
   staffing, or marketing here has the highest upside.
3. **Defend the 40% e-commerce channel** — it's already large; small conversion
   or basket gains compound on a big base.
4. **Attack refunds via reason analysis** — with a thin 16.8% margin, cutting the
   $22.9M refund pool (Dashboard 9) flows almost directly to profit.
5. **Rebalance inventory, not just reorder** — 43K low-stock vs 752 out-of-stock
   points to distribution imbalance; redeploy overstock before buying more.

---

## 8. Dashboard navigation guide — which page answers which question

| Business question | Dashboard |
|-------------------|-----------|
| Are we growing, and where? | 1. Executive Overview |
| How is sales momentum / which categories win? | 2. Sales Performance |
| Who buys, and are we retaining them? | 3. Customer Analytics |
| Are we about to stock out / is capital tied up? | 4. Inventory & Supply Chain |
| How does my store rank? | 5. Store Performance |
| Which products/brands to grow or cut? | 6. Product & Category |
| Where is margin made and lost? | 7. Finance & Profitability |
| Which regions need intervention? | 8. Regional Comparison |
| Why is product coming back? | 9. Returns & Shipping |
