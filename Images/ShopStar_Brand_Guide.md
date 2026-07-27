# ShopStar Retail — Brand Guide

**Company:** ShopStar Retail
**Tagline:** *Smart Shopping, Smarter Analytics*
**Domain:** Enterprise retail business intelligence

---

## 1. Logo

| Asset | File | Use |
|-------|------|-----|
| Full lockup | `Images/ShopStar_Logo_Full.png` | Report headers, README, decks, cover pages |
| Square icon | `Images/ShopStar_Logo_Icon.png` | App icon, favicon, slide corners, watermark |

**Design:** Navy wordmark — "Shop" in navy, "Star" in orange — with an orange
"smile / growth" swoosh that sweeps beneath the mark and ends in a star tip. The
swoosh signals upward growth and a positive shopping experience. The square icon
places a white **S** monogram over a navy rounded tile with the same orange smile.

> The logo is an **original** mark rendered with `Python/generate_logo.py` (Pillow,
> 4× supersampled). It is inspired by the clean wordmark-plus-swoosh *style* of
> modern retail brands; it does not reuse any third-party trademark.

**Logo rules**
- Keep clear space around the mark equal to the height of the "S".
- Do not recolour, stretch, rotate, or add effects.
- On dark backgrounds use the icon (navy tile already provides contrast); for the
  full lockup on dark, place it on a white/`#F8F9FA` panel.
- Minimum width for the full lockup: 160 px.

---

## 2. Colour palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Primary | Navy Blue | `#1B365D` | Titles, KPI values, table headers, primary series |
| Secondary | Orange | `#F7941D` | Accent series, highlights, call-to-action, logo swoosh |
| Accent | Green | `#2ECC71` | Positive KPI / above target |
| Alert | Red | `#E74C3C` | Negative KPI / below target / alerts |
| Background | Light Gray | `#F8F9FA` | Page canvas / outspace |
| Surface | White | `#FFFFFF` | Visual cards |
| Text | Dark Charcoal | `#2C3E50` | Body text and labels |

**Chart data-colour order:** Navy → Orange → Green → Blue `#5B8DEF` → Red →
Amber `#F5B041` → … (defined in the theme's `dataColors`).

**Conditional (KPI) colour logic**
- Green `#2ECC71` — metric **at or above** target (good).
- Orange `#F7941D` — metric **near** target / watch (neutral).
- Red `#E74C3C` — metric **below** target / breach (bad).

---

## 3. Typography

**Font family:** Segoe UI (Microsoft standard — no install needed on Windows / Power BI).

| Level | Face | Size |
|-------|------|------|
| Visual / page title | Segoe UI Semibold | 18 pt |
| KPI callout value | Segoe UI Semibold | 26–30 pt |
| Section header | Segoe UI Semibold | 12 pt |
| Body / axis / label | Segoe UI | 10 pt |

---

## 4. Power BI theme

Machine-readable theme: **`Power BI/Templates/ShopStar_Theme.json`**.
It is already **registered and applied** to the report
(`ShopStar_Retail.Report/definition/report.json` → `themeCollection.customTheme`),
with a copy in `StaticResources/RegisteredResources/`.

The theme applies: brand `dataColors`, Segoe UI text classes, white visual
surfaces, borders **off**, a subtle drop shadow, light-gray page background, navy
KPI callouts, and navy table headers.

**To re-apply manually** (if needed): Power BI Desktop → **View → Themes →
Browse for themes** → select `Power BI/Templates/ShopStar_Theme.json`.
