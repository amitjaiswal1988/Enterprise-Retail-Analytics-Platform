# Row-Level Security (RLS) Guide

> **Audience:** BI developers who need to make sure each user only sees the rows of data they are allowed to see.
>
> **Format:** Every section uses **WHAT / WHY / WHEN / HOW** in simple English, with real examples from the **ShopStar Retail** model (`RetailDW` star schema, 9 dashboards, 98 DAX measures).

---

## Why security matters here

ShopStar has one dataset but many kinds of users:
- The **CEO** should see all regions and all stores.
- A **Regional Director** should see only their region (East, West, North, or South).
- A **Store Manager** should see only their own store.
- The **Finance team** can see `UnitCost`; the **Sales team** should not.

Row-Level Security (RLS) and Object-Level Security (OLS) let one shared model serve all of them safely — no need to build a separate report per person.

---

## Quick Terms

| Term | 1-line meaning |
|------|----------------|
| **Role** | A named security rule (for example, "Region East"). |
| **RLS** | Row-Level Security — hides **rows** based on the user. |
| **OLS** | Object-Level Security — hides whole **columns/tables**. |
| **`USERPRINCIPALNAME()`** | A DAX function that returns the signed-in user's email. |
| **Security table** | A small table mapping each user's email to what they can see. |
| **Static RLS** | One fixed filter per role (one role per region). |
| **Dynamic RLS** | One role that filters differently for every user, using their email. |

---

## 1. Static RLS

**WHAT:** A role with a fixed DAX filter. Each region gets its own role. Example: the "Region East" role always filters `DimRegion[RegionName] = "East"`.

**WHY:** It is the simplest form of RLS and easy to understand and test. Good when there are only a few groups (ShopStar has 4 regions).

**WHEN:** Use when the number of groups is small and stable, and you do not mind creating one role per group.

**HOW:**
1. In Power BI Desktop → **Modeling → Manage roles**.
2. Create a role named **`Region - East`**.
3. Add a table filter on `DimRegion`:
   ```DAX
   [RegionName] = "East"
   ```
4. Repeat for West, North, South.
5. Publish, then in the Service assign users/groups to each role.

**How the filter spreads:** The filter is on `DimRegion`. Because `DimRegion` has a one-to-many relationship to `FactSales`, `FactReturns`, and `FactInventory`, filtering the region automatically filters all the facts — so an East director sees only East sales, returns, and inventory.

**In this project (real TMDL):** Four static region roles are wired into the model under `ShopStar_Retail.SemanticModel/definition/roles/`:

| Role name | Filter |
|-----------|--------|
| `Region - East` | `DimRegion[RegionName] = "East"` |
| `Region - West` | `DimRegion[RegionName] = "West"` |
| `Region - North` | `DimRegion[RegionName] = "North"` |
| `Region - South` | `DimRegion[RegionName] = "South"` |

TMDL definition (one role shown):
```tmdl
role 'Region - East'
	modelPermission: read

	tablePermission DimRegion = DimRegion[RegionName] = "East"
```

---

## 2. Dynamic RLS

**WHAT:** A single role that filters data differently for each user by matching the signed-in email against a **security table**.

**WHY:** ShopStar has 120+ stores. Creating one static role per store would be unmanageable. Dynamic RLS handles all users with **one** role — you just add a row to the security table when a new manager joins.

**WHEN:** Use when there are many groups/users, or when the mapping changes often. This is the enterprise-standard approach.

**HOW:**
1. Add a **security table** to the model that maps each user's email to what they can see. For ShopStar, `SecurityUserStore`:

   | UserEmail | StoreID |
   |-----------|---------|
   | manager.a@shopstar.com | 12 |
   | manager.b@shopstar.com | 45 |
   | director.east@shopstar.com | (all East stores) |

   Source it from a SQL table `warehouse.SecurityUserStore` so IT can maintain it.
2. Create **one** role, `Dynamic Store Security`.
3. Filter the store dimension with a DAX rule that reads the current user's email:
   ```DAX
   DimStore[StoreID] =
       LOOKUPVALUE(
           SecurityUserStore[StoreID],
           SecurityUserStore[UserEmail], USERPRINCIPALNAME()
       )
   ```
   `USERPRINCIPALNAME()` returns the signed-in email; `LOOKUPVALUE` finds that user's allowed `StoreID`; the filter keeps only matching store rows, which then filters the facts.
4. For a many-stores-per-user case (a director owning several stores), filter with a relationship or `PATH`/`CONTAINS` pattern instead of a single `LOOKUPVALUE`.
5. Publish and assign **all** business users to the single `Dynamic Store Security` role.

> **Note:** A dynamic role needs the `SecurityUserStore` table to exist in the model. It is documented here as the recommended design; it is **not** wired into the shipped TMDL because the source table `warehouse.SecurityUserStore` is not part of the current warehouse build (adding a role that points at a missing table would break the model). Create the SQL table first, load it, then add the role.

---

## 3. Object-Level Security (OLS)

**WHAT:** OLS hides an entire **column or table** from a role, so the users in that role cannot see it or even know it exists.

**WHY:** Some fields are sensitive. Finance needs `DimProduct[UnitCost]` and margin details; the Sales team should not see cost. OLS removes the column for the Sales role — it disappears from the field list and any visual using it.

**WHEN:** Use for confidential columns (cost, salary, personal data) that only some roles may see.

**HOW:** OLS cannot be set in the Power BI Desktop UI. Use **Tabular Editor** (free) or the **XMLA endpoint**:
1. Open the published model in **Tabular Editor** via the XMLA endpoint (Premium) or the local model.
2. Select the role (for example, `Sales Team`).
3. On `DimProduct[UnitCost]` set **Object Level Security = None** for that role (None = hidden).
4. Save back to the model.

> **Important:** If a visual uses a column that OLS hides for a user, the whole visual shows an error for that user. Design report pages so restricted columns are only on pages that restricted users do not open.

---

## 4. Hierarchical RLS

**WHAT:** Security that follows an org chart: the CEO sees everything, a VP sees their region, a manager sees their store — all from one hierarchy.

**WHY:** Real companies are layered. Instead of many flat roles, one hierarchy rule grants each person their level and everything beneath it.

**WHEN:** Use when access should "roll up" an organizational tree (CEO → VP → Manager).

**HOW:** Store the org hierarchy as a parent-child table (each employee has a `ManagerEmail`) and flatten it with `PATH`:
1. Add an org security table with `EmployeeEmail`, `ManagerEmail`, `RegionOrStore` scope.
2. Create a calculated column that builds the chain:
   ```DAX
   PeoplePath = PATH( OrgSecurity[EmployeeEmail], OrgSecurity[ManagerEmail] )
   ```
3. In the role, allow a row if the current user appears anywhere in that row's path:
   ```DAX
   PATHCONTAINS( OrgSecurity[PeoplePath], USERPRINCIPALNAME() )
   ```
   `PATH` builds the manager chain for each person; `PATHCONTAINS` returns true if the signed-in user is that person or any manager above them — so a VP automatically sees all managers below.

---

## 5. Testing RLS

**WHAT:** Confirming that each role sees exactly the right rows before real users get access.

**WHY:** A wrong filter can leak data (a director seeing another region) or block everything (an empty report). Always test before sharing.

**WHEN:** Test in Desktop after creating roles, and again in the Service after publishing and assigning members.

**HOW — in Desktop:**
1. **Modeling → View as** → tick a role (for example, `Region - East`).
2. For dynamic RLS, also tick **Other user** and type an email to simulate that person.
3. Check the visuals now show only that slice ($719M drops to just East's revenue).

**HOW — in the Service:**
1. Dataset → **Security** → open the role → add users/groups → **Save**.
2. Use **Test as role** in the Service to confirm.

**Common mistakes:**

| Mistake | Result | Fix |
|---------|--------|-----|
| Created the role but assigned no members | Users get an error or see nothing | Assign users/groups in the Service **Security** dialog. |
| Filtered a fact table directly | Slow and can miss related tables | Filter the **dimension**; let relationships spread it. |
| Bi-directional relationship left on | Filter leaks the wrong way | Keep dimension→fact single-direction for RLS tables. |
| `USERPRINCIPALNAME()` not matching emails | Dynamic role shows nothing | Ensure the security table emails exactly match sign-in emails (case/spacing). |
| Admin tests and sees all data | Workspace admins bypass RLS | Test with **View as / Test as role**, not your admin login. |

---

## Summary

| Type | One role or many | Best for ShopStar |
|------|------------------|-------------------|
| Static RLS | One role per region | 4 region directors (shipped in TMDL) |
| Dynamic RLS | One role for everyone | 120+ store managers (recommended design) |
| OLS | Per column | Hide `UnitCost` from Sales |
| Hierarchical | One org tree | CEO → VP → Manager roll-up |
