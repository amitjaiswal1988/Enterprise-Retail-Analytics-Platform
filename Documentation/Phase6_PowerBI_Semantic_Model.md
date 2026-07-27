# Phase 6 — Power BI Semantic Model (Journey Log)

> Yeh document Phase 6 ka poora hands-on journey capture karta hai — humne kya banaya, kaunse errors aaye, kaise fix kiye, aur key concepts ka matlab (Hinglish mein, taaki revise karna easy ho).

---

## 1. Semantic Model kya hota hai?

**Semantic Model** = Power BI ke andar ka "brain" / data layer jo raw tables ko **business-friendly meaning** deta hai.

SQL Warehouse mein sirf **tables + columns** hote hain (technical). Semantic model unke upar ek layer banata hai jisme:

| Cheez | Kya add karta hai |
|-------|-------------------|
| **Relationships** | Tables aapas mein kaise jude hain (Fact ↔ Dim) |
| **Hierarchies** | Drill-down paths (Year→Month→Day) |
| **Measures (DAX)** | Business calculations (Total Sales, Profit %) |
| **Formatting** | Currency, %, date formats |
| **Hidden columns** | Keys chhupao jo report mein nahi chahiye |
| **Sort order** | MonthName ko MonthNumber se sort karna |

**Ek line mein:** Semantic model raw data ko aise shape deta hai ki business user (jo SQL nahi jaanta) bhi easily report bana sake. Isko "Data Model" ya "Tabular Model" bhi kehte hain.

**Analogy:** SQL warehouse = kaccha raashan (aata, sabzi). Semantic model = bana banaya menu jise koi bhi order kar sake.

---

## 2. Kya-kya Banaya (Phase 6 Deliverables)

### 2.1 Tables Load (Import Mode)
- **8 Dimensions:** DimCategory, DimCustomer, DimDate, DimEmployee, DimProduct, DimRegion, DimStore, DimSupplier
- **3 Facts:** FactSales (201,282 rows), FactInventory, FactReturns
- Connection: `localhost` → database `RetailDW` (Windows auth, Import mode)

### 2.2 Relationships (21 total)
- FactSales → 8 relationships
- FactInventory → 6 relationships
- FactReturns → 7 relationships
- Star schema: har Fact table apni Dimensions se juda (one-to-many, single direction)

### 2.3 Hierarchies (3)
| Hierarchy | Table | Levels (drill path) |
|-----------|-------|---------------------|
| **Calendar** | DimDate | Year → Quarter → MonthName → DayOfMonth |
| **Product Hierarchy** | DimProduct | CategoryName → SubCategoryName → Brand → ProductName |
| **Region Hierarchy** | DimStore | Region → State → City → StoreName |

### 2.4 DimDate Special Setup
- **Marked as Date Table** (on `FullDate` column) → Time Intelligence DAX enable
- **MonthName** sorted by **MonthNumber** (Jan→Dec, alphabet nahi)
- **DayName** sorted by **DayOfWeek** (Mon→Sun)
- **DateKey** column hidden (report mein nahi dikhta)
- **Auto date/time OFF** → 4 hidden clutter tables removed

### 2.5 Version Control (PBIP format)
- File format: **PBIP** (Power BI Project) = TMDL text files → Git-friendly
- `.gitignore` mein `**/.pbi/` add kiya (local cache exclude)
- Commits pushed to GitHub

---

## 3. Errors / Issues aur unke Fixes

### Issue 1 — Encrypted Connection Error (CRITICAL)
- **Error:** Power BI SQL Server se connect nahi ho raha tha (encryption error).
- **Fix:** Connection dialog mein **"Use encrypted connection" uncheck** kiya + Database naam **`RetailDW`** manually type kiya.

### Issue 2 — DateKey Column Accidentally Removed
- **Problem:** Power Query cleanup ke dauran DimDate se `DateKey` galti se remove ho gaya.
- **Fix:** Power Query mein "Removed Columns" step edit karke `DateKey` wapas add kiya.
- **Learning:** Fact ka `OrderDateKey` join hota hai Dim ke `DateKey` se — naam alag, values same.

### Issue 3 — Galat Relationship (CRITICAL BUG)
- **Bug:** `FactReturns[CategorySK] → DimCustomer[CustomerSK]` — galat column join tha.
- **Fix:** Sahi kiya → `FactReturns[CustomerSK] → DimCustomer[CustomerSK]`.

### Issue 4 — Active/Inactive Date Relationship Ulta tha
- **Bug:** FactReturns mein `OrderDateKey` active tha, `ReturnDateKey` inactive.
- **Fix:** Ulta kiya → **ReturnDateKey = Active**, OrderDateKey = Inactive.
- **Kyun:** Returns analysis return date pe hona chahiye, order date pe nahi.

### Issue 5 — PBIX (binary) vs PBIP (text) Save
- **Problem:** Pehli baar galti se `.pbix` (binary) format mein save ho gaya.
- **Fix:** `.pbip` format mein save kiya → TMDL text files → Git diff readable.

### Issue 6 — In-Memory Fix Disk pe Save Nahi Hua
- **Problem:** Relationship fix sirf memory mein tha, TMDL file purani thi.
- **Fix:** **Ctrl+S** press karke persist kiya.
- **Learning:** PBIP ka fayda — TMDL text inspect karke pata chal jaata hai save hua ya nahi.

### Issue 7 — Hierarchy Rename Save Pending
- **Problem:** UI mein "Calendar" dikh raha tha par file mein "Year Hierarchy" tha.
- **Fix:** Ctrl+S se rename persist hua.

### Issue 8 — Auto date/time Galat Jagah OFF kiya
- **Problem:** Pehle **GLOBAL → Data Load** mein dekha (wo "new files" ke liye hai).
- **Fix:** **CURRENT FILE → Data Load** mein Auto date/time uncheck kiya → 4 clutter tables (`LocalDateTable_*`, `DateTableTemplate_*`) removed.

---

## 4. Key Concepts — Kyun Zaroori (Quick Revision)

| Step | Kyun karte hain |
|------|-----------------|
| **Sort by column** | Months/days calendar order mein dikhein (Jan→Dec), alphabet order mein nahi |
| **Hierarchy** | Ek click drill-down (Year→Day), har level alag field drag nahi karni padti |
| **Mark as Date Table** | Time Intelligence DAX chale (YTD, SamePeriodLastYear, etc.) |
| **Auto date/time OFF** | Fazool hidden calendar tables + file bloat hatao (humaare paas already DimDate hai) |
| **Hide keys (DateKey)** | Report user ko technical keys nahi dikhein, sirf meaningful fields |
| **PBIP format** | TMDL text files → Git version control + code review possible |

---

## 5. Phase 6 Status — COMPLETE

- [x] 8 Dims + 3 Facts loaded (Import mode)
- [x] 21 relationships (2 critical bugs fixed)
- [x] 3 hierarchies (Calendar, Product, Region)
- [x] DimDate marked as date table + sort + hidden keys
- [x] Auto date/time OFF (clutter removed)
- [x] PBIP committed + pushed to GitHub

**Next:** Phase 7 — Advanced DAX Measures (100+ business calculations).

---

*Yeh document Phase 6 ke hands-on kaam ka record hai. Har error aur fix future reference ke liye documented hai.*
