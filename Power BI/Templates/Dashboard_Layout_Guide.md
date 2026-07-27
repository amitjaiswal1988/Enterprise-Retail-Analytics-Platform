# ShopStar Retail — Dashboard Layout Guide

Design standards for every ShopStar report page. These match how the nine pages
in `ShopStar_Retail.pbip` are actually built, so new pages stay consistent.

---

## 1. Canvas & grid

- **Page size:** 1280 × 720 px (16:9), **Fit to page**.
- **Outer margin:** 16 px on all sides.
- **Gutter between visuals:** 16 px.
- **Row 1 (KPI band):** y = 76, height = 104.
- **Chart grid (2×2):** two rows starting at y = 196 and y = 458, height ≈ 248.
- Snap everything to a 4 px grid; align edges — no free-floating visuals.

**Standard coordinates used in the build**
| Slot | x | y | width | height |
|------|---|---|-------|--------|
| Card 1 | 16 | 76 | 300 | 104 |
| Card 2 | 328 | 76 | 300 | 104 |
| Card 3 | 640 | 76 | 300 | 104 |
| Card 4 | 952 | 76 | 300 | 104 |
| Chart TL | 16 | 196 | 616 | 250 |
| Chart TR | 648 | 196 | 616 | 250 |
| Chart BL | 16 | 458 | 616 | 246 |
| Chart BR | 648 | 458 | 616 | 246 |

Header band (title + logo) occupies y = 0–72.

---

## 2. KPI card standards

- Four cards, evenly spaced across Row 1.
- **Callout value:** Segoe UI Semibold, 26–30 pt, Navy `#1B365D`.
- **Category label:** Segoe UI, 11 pt, muted `#5A6B7B`.
- One metric per card; format numbers ($ #,0 M / % / #,0) at the measure level.
- Optional trend/target indicator sits under the value (Roadmap).

---

## 3. Colour-coding rules (Green / Amber / Red)

| State | Colour | Rule of thumb |
|-------|--------|---------------|
| Good | Green `#2ECC71` | at or above target |
| Watch | Orange `#F7941D` | within ~5% of target |
| Bad | Red `#E74C3C` | below target / breach |

Apply via conditional formatting on cards, tables, and KPI visuals. Example
thresholds: Gross Margin ≥ 16.8% green; Return Rate ≤ 5% green, > 5% red;
Inventory Turnover ≥ 8× green.

---

## 4. Typography

| Element | Face | Size |
|---------|------|------|
| Page / visual title | Segoe UI Semibold | 18 pt |
| Subtitle | Segoe UI | 12 pt |
| Body / axis / labels | Segoe UI | 10 pt |
| KPI callout | Segoe UI Semibold | 26–30 pt |

All fonts are inherited from `ShopStar_Theme.json` — do not override per-visual
unless a specific emphasis is required.

---

## 5. Chart selection standards

| Metric shape | Use | Notes |
|--------------|-----|-------|
| Value over time | Line | markers on, stroke 3 px |
| Ranking (categories/regions/stores) | Column or Bar | sort descending |
| Part-to-whole | Donut | ≤ 6 slices, else group "Other" |
| Detail / list | Table | navy header, zebra grid |
| Single number | Card | headline KPIs only |

Legends: top for line/column/bar, right for donut, 9 pt.

---

## 6. Navigation & slicers (standard, partly Roadmap)

- **Slicer panel:** top-right of the header band, or a collapsible left panel.
- Common slicers: Year, Quarter, Region, Category, Channel.
- **Navigation buttons:** bottom or left rail, one per dashboard, using page
  navigation actions; active page highlighted in Orange.
- **Drill-through:** product & store detail pages (Roadmap).
- **Bookmarks:** for reset-filters and show/hide slicer panel (Roadmap).

---

## 7. Header & branding

- Place `Images/ShopStar_Logo_Full.png` top-left in the header band (height ≈ 40 px,
  clear space = height of the "S").
- Page title in Navy Semibold 18 pt to the right of / below the logo.
- Keep the header identical on every page for a consistent product feel.

---

## 8. Tooltip pages (Roadmap)

- 320 × 240 px tooltip-type page.
- Show 1 KPI + 1 mini trend + context label.
- Assign per visual via **Format → Tooltip → Report page**.

---

## 9. Mobile layout (Roadmap)

- Use the Power BI **Mobile layout** view per page.
- Stack the 4 KPI cards vertically first, then charts single-column.
- Keep only the top 2–3 visuals per page for phone; hide dense tables.

---

## 10. Consistency checklist (before publishing a page)

- [ ] 16 px margins & gutters, everything aligned to grid.
- [ ] Exactly 4 KPI cards in Row 1.
- [ ] ShopStar theme applied (borders off, white surfaces, navy titles).
- [ ] Correct chart type per metric shape (section 5).
- [ ] Numbers formatted at the measure level.
- [ ] Logo + page title in the header band.
- [ ] Donuts ≤ 6 slices; legends placed per standard.
