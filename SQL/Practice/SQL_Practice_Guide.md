# SQL Practice Guide — 100 Interview Queries

> **Companion to:** [SQL_100_Queries_Portfolio.sql](SQL_100_Queries_Portfolio.sql) — 100 fully documented, DB-validated queries against the `RetailDW` warehouse.
> **Goal:** Turn this portfolio into a structured interview-prep plan, from Junior to Senior SQL.
> **Status:** All 100 queries run clean against the live database (validated end-to-end).

---

## 1. How to use the 100 queries

The portfolio file is one runnable script. Each query has a rich comment header:

```
QUERY #XX: Title
BUSINESS PROBLEM  -- the real question a stakeholder asks
SOLUTION          -- the approach in plain words
SQL CONCEPTS      -- techniques demonstrated (JOIN, CTE, window...)
WHY / WHEN / WHAT -- when to reach for this pattern
POWER BI IMPACT   -- how it feeds a view / visual
DASHBOARD         -- where the output lands
INTERVIEW TIP     -- what the interviewer is really testing
```

**Recommended workflow per query:**

1. **Read only the `BUSINESS PROBLEM`.** Cover the SQL. Try to write the query yourself first.
2. **Compare** your attempt to the provided solution.
3. **Run it** and read the result set:
   ```bash
   sqlcmd -S localhost -E -C -d RetailDW -b -i "SQL/Practice/SQL_100_Queries_Portfolio.sql"
   ```
   (To run a single query, copy it into a new `.sql` file or an SSMS window.)
4. **Explain out loud** what each clause does — this is what interviews actually test.
5. **Tweak it:** change the filter, add a column, break it and fix it. Mutation cements learning.

---

## 2. Skill progression: Junior → Mid → Senior

The 100 queries are ordered by increasing difficulty. Map your target level to the sections:

| Level | Sections | Query range | What you can claim |
|---|---|---|---|
| **Junior / Entry** | 1–2 | **Q1–Q35** | `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, basic aggregates, filtering, profiling. |
| **Mid / Analyst** | 3–4 | **Q36–Q70** | All `JOIN` types, self-joins, subqueries, **CTEs**, correlated subqueries, set logic. |
| **Senior / BI Engineer** | 5–6 | **Q71–Q100** | **Window functions**, running totals, ranking, `LAG`/`LEAD`, `NTILE`, `PIVOT`, cohort/RFM/ABC, recursive CTEs. |

### Section map

| Section | Queries | Theme | Key concepts |
|---|---|---|---|
| 1 | Q1–Q20 | EDA & Data Profiling | `COUNT`, `DISTINCT`, `NULL` checks, `MIN`/`MAX`, cardinality, dupes |
| 2 | Q21–Q35 | Aggregations & GROUP BY | `SUM`/`AVG`, `GROUP BY`, `HAVING`, multi-level grouping |
| 3 | Q36–Q50 | JOINs | `INNER`/`LEFT`/`FULL OUTER`, self-join org chart, multi-table joins |
| 4 | Q51–Q70 | Subqueries & CTEs | scalar/correlated subqueries, `CTE`, **recursive CTE** (Q57 org chart) |
| 5 | Q71–Q90 | Window Functions | `ROW_NUMBER`/`RANK`, `LAG`/`LEAD`, `NTILE`, running totals, gaps-and-islands (Q90) |
| 6 | Q91–Q100 | Advanced Analytics | `PIVOT` (Q91), YoY (Q92), Cohort (Q93), RFM (Q94), ABC/Pareto (Q95), Basket (Q96), CLV (Q97), Weighted Avg (Q98), Turnover (Q99), Exec Scorecard (Q100) |

---

## 3. Which queries match which interview level

Use this as a targeted drill list before a specific interview.

**If the JD says "SQL basics / reporting":** master **Q1–Q35**. You must write these fluently without hints.

**If the JD says "Data Analyst / Business Analyst":** master **Q1–Q70**. Expect a live JOIN + subquery/CTE exercise. Star queries to rehearse: Q40 (self-join), Q45 (FULL OUTER), Q54 (correlated subquery), Q60 (CTE), Q57 (recursive CTE).

**If the JD says "BI Engineer / Analytics Engineer / Senior":** master **Q71–Q100**. Window functions are non-negotiable. Star queries: Q72 (`ROW_NUMBER` dedupe), Q78 (`LAG` MoM growth), Q82 (running total), Q85 (`NTILE` quartiles), Q90 (gaps-and-islands), Q92 (YoY), Q94 (RFM), Q95 (ABC/Pareto).

---

## 4. Practice schedule (10 queries/day → 10 days)

A realistic two-week plan (weekdays):

| Day | Queries | Focus | Success check |
|---|---|---|---|
| 1 | Q1–Q10 | Profiling basics | Write any of them from memory |
| 2 | Q11–Q20 | Profiling + NULL handling | Explain `NULL` vs `0` |
| 3 | Q21–Q30 | Aggregations | `GROUP BY` vs `HAVING` fluently |
| 4 | Q31–Q40 | Grouping + first JOINs | Draw the join diagram |
| 5 | Q41–Q50 | All JOIN types | Predict LEFT vs FULL row counts |
| 6 | Q51–Q60 | Subqueries & CTEs | Rewrite a subquery as a CTE |
| 7 | Q61–Q70 | Correlated + recursive | Explain recursion in Q57 |
| 8 | Q71–Q80 | Window fundamentals | `PARTITION BY` vs `GROUP BY` |
| 9 | Q81–Q90 | Advanced windows | Build a running total unaided |
| 10 | Q91–Q100 | Analytics patterns | Explain RFM, ABC, cohort |

**Spaced repetition:** each day, before new queries, re-solve **2 random queries** from previous days. On Day 11+, do a full mock: pick 5 random queries and solve under a 30-minute timer.

---

## 5. Common interviewer patterns (and which query prepares you)

| Interviewer asks... | Real skill tested | Rehearse |
|---|---|---|
| "Find the 2nd highest salary / Nth per group" | `ROW_NUMBER`/`DENSE_RANK` + `PARTITION BY` | Q72, Q74 |
| "Remove duplicate rows, keep the latest" | `ROW_NUMBER` dedupe pattern | Q72 |
| "Month-over-month / Year-over-year growth" | `LAG`, self-join on date, `DIVIDE` | Q78, Q92 |
| "Running / cumulative total" | window frame `ROWS BETWEEN UNBOUNDED PRECEDING` | Q82 |
| "Top N customers making 80% of revenue" | cumulative % / Pareto | Q95 |
| "Customers who bought A also bought B" | self-join market-basket | Q96 |
| "Bucket customers into quartiles/deciles" | `NTILE` | Q85, Q94 |
| "Employees and their managers" | self-join / recursive CTE | Q40, Q57 |
| "Rows in table A missing in table B" | `LEFT JOIN ... IS NULL` / `NOT EXISTS` | Q42, Q54 |
| "Pivot months into columns" | `PIVOT` / conditional aggregation | Q91 |
| "Find consecutive streaks / gaps" | gaps-and-islands | Q90 |

### Answering framework (say this out loud)

1. **Restate** the question and confirm the grain ("per customer per month?").
2. **Name the pattern** ("this is a ranking-within-group problem → `ROW_NUMBER` with `PARTITION BY`").
3. **Write incrementally** — base query first, then add the window/CTE.
4. **State edge cases** — NULLs, ties, divide-by-zero (`DIVIDE`), empty groups.
5. **Mention performance** — indexes on join/filter keys, avoid `SELECT *`.

---

## 6. Interview-day checklist

- [ ] Can write Q1–Q35 with zero hints (Junior baseline).
- [ ] Can explain `WHERE` vs `HAVING`, `INNER` vs `LEFT`, `GROUP BY` vs `PARTITION BY`.
- [ ] Can write a `ROW_NUMBER` dedupe and a running total from memory.
- [ ] Can explain one advanced pattern end-to-end (RFM **or** ABC **or** cohort).
- [ ] Know how each query feeds a Power BI view (see the `POWER BI IMPACT` header).
- [ ] Have run the full script clean against `RetailDW` at least once.

---

**Related:** [SQL_100_Queries_Portfolio.sql](SQL_100_Queries_Portfolio.sql) · [Analytics views](../Views/07_Analytics_Views.sql) · [Power BI Implementation Guide](../../Documentation/PowerBI_Implementation_Guide.md)
