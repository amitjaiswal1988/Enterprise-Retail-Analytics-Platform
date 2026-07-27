# Clear All Filters — Bookmark + Button Reference (PBIR)

Ready-to-use JSON for a global **Clear All Filters** button. Two ways to use it:

- **Recommended (reliable):** Do the 30-second Desktop recipe in Section 4. It records
  the *real* cleared state so the button actually resets every slicer.
- **Advanced (JSON scaffold):** Paste the files in Sections 1–3, then still run the
  one-click **Update bookmark (Data)** step (4.2) in Desktop to record the clearing state.

> **Why the Desktop step is required:** Microsoft's PBIR docs state that Power BI Desktop
> **strips** any hand-authored bookmark whose captured visual state doesn't match the page.
> A pasted bookmark below is schema-valid and won't corrupt anything, but it won't *clear*
> slicers until you re-record it in Desktop once (View > Bookmarks > right-click > Update).

---

## 1. `definition/bookmarks/bookmarks.json`

Create the folder `Power BI/ShopStar_Retail.Report/definition/bookmarks/` and add this file.

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/bookmarksMetadata/1.0.0/schema.json",
  "items": [
    { "name": "ClearAllFilters" }
  ]
}
```

---

## 2. `definition/bookmarks/ClearAllFilters.bookmark.json`

Same folder. `sections` lists all 9 pages by their folder id; `activeSection` is page 1.

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/bookmark/1.1.0/schema.json",
  "name": "ClearAllFilters",
  "displayName": "Clear All Filters",
  "explorationState": {
    "version": "1.0",
    "activeSection": "a4a5d6f0e14bbc1b035b",
    "filters": { "byName": {} },
    "sections": {
      "a4a5d6f0e14bbc1b035b": { "visualContainers": {} },
      "b1000000000000000002": { "visualContainers": {} },
      "b1000000000000000003": { "visualContainers": {} },
      "b1000000000000000004": { "visualContainers": {} },
      "b1000000000000000005": { "visualContainers": {} },
      "b1000000000000000006": { "visualContainers": {} },
      "b1000000000000000007": { "visualContainers": {} },
      "b1000000000000000008": { "visualContainers": {} },
      "b1000000000000000009": { "visualContainers": {} }
    }
  },
  "options": { "suppressData": false }
}
```

---

## 3. Button visual — one per page

For each page, create a new visual folder:
`definition/pages/<pageId>/visuals/cb00<pageId-tail>/visual.json`

The `name` must be unique within its page (word chars / hyphens only). Below the action is
wired to the bookmark; **set the button label in Desktop** (Format button > Text) since the
text-formatting object is easiest to author there.

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/1.4.0/schema.json",
  "name": "cb00clearallfilters01",
  "position": { "x": 1096, "y": 12, "z": 9000, "width": 168, "height": 50, "tabOrder": 9000 },
  "visual": {
    "visualType": "actionButton",
    "visualContainerObjects": {
      "visualLink": [
        {
          "properties": {
            "show":     { "expr": { "Literal": { "Value": "true" } } },
            "type":     { "expr": { "Literal": { "Value": "'Bookmark'" } } },
            "bookmark": { "expr": { "Literal": { "Value": "'ClearAllFilters'" } } }
          }
        }
      ]
    },
    "drillFilterOtherVisuals": true
  }
}
```

### Placement note (important)
`x: 1096` sits in the free header space **only on pages with 5 or fewer slicers**
(e.g. page 1: slicers end at x=1086). On the **6-slicer pages** the header is full
(slicers reach x=1264), so either:
- change `x` to a free spot for that page, **or**
- just drag the button to a clean position in Desktop after it appears.

Give each page's button a **unique `name`** (e.g. `cb00clearallfilters01`,
`...02`, ... `...09`).

---

## 4. Finalize in Power BI Desktop (required, ~30 sec)

### 4.1 Simplest path (no JSON needed at all)
1. Open `ShopStar_Retail.pbip`.
2. On any page, clear every slicer selection.
3. **View > Bookmarks > Add**. In the bookmark's ... menu, ensure **Data** is checked;
   uncheck **Display** if you only want it to reset filters. Rename it `Clear All Filters`.
4. **Insert > Buttons > Blank**. In the format pane: **Action = On**, **Type = Bookmark**,
   **Bookmark = Clear All Filters**. Type a label like "Clear All".
5. Copy the button (Ctrl+C / Ctrl+V) onto every page, or use **Format > Sync**.

### 4.2 If you pasted the JSON from Sections 1–3
1. Open the report — the button appears and the bookmark exists.
2. Clear all slicers on the active page.
3. **View > Bookmarks**, right-click **Clear All Filters > Update** (with **Data** on).
   This records the real cleared state so the button works everywhere.

---

## Reminder
You already have **per-slicer clear** — the eraser icon on each slicer's header clears
that slicer. This global button is a convenience add-on, not required for functionality.
