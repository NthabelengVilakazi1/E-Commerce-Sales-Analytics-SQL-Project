# E-Commerce Sales Analytics (SQL Project)

## 1. Project Overview

This project simulates an **E-Commerce Sales Data Warehouse** built in PostgreSQL.
It demonstrates advanced SQL skills such as schema design, complex joins, window functions, CTEs, stored procedures, and query optimization.

The dataset is modeled in a **star schema** with one fact table (`fact_table`) and multiple dimensions (`customer_dim`, `item_dim`, `store_dim`, `payment_dim`, `time_dim`).

---

## 2. Motivation

E-commerce is a flagship use case for SQL because it touches on:

* **Customers** (repeat purchase behavior, churn, segmentation)
* **Products** (top sellers, revenue trends, inventory analysis)
* **Time** (daily/weekly/monthly performance)
* **Payments & Stores** (multi-channel revenue insights)

By building this end-to-end, I showcase SQL as a powerful tool for analytics, business intelligence, and reporting.

---

## 3. Tech Stack

* **Database:** PostgreSQL 15
* **Environment:** Local Postgres instance (Docker optional, but not required)

---

## 4. Repository Structure

```
├── 01_schema.sql          # CREATE TABLE statements (fact + dimensions) with PKs/FKs & constraints
├── 02_indexes_views.sql   # Index creation, materialized views for aggregated analytics
├── 06_queries.sql         # Annotated queries (KPIs, joins, window functions, cohorts)
├── 07_procedures.sql      # Stored procedures / functions (automated reporting)
├── 08_checks.sql          # Data validation & integrity checks
├── README.md              # Documentation (this file)
└── erd.png                # ER diagram (schema overview)
```

---

## 5. Quick Start

```bash
# 1. Create the schema
psql -U <username> -d ecommerce -f 01_schema.sql

# 2. Add indexes & materialized views
psql -U <username> -d ecommerce -f 02_indexes_views.sql

# 3. Run example queries
psql -U <username> -d ecommerce -f 06_queries.sql
```

---

## 6. Key Queries (from `06_queries.sql`)

These queries demonstrate KPIs, advanced SQL functions, and analytical insights

**A. Revenue by month**

```sql
SELECT t.year, t.month, SUM(f.total_price) AS revenue
FROM fact_table f
JOIN time_dim t ON f.time_key = t.time_key
GROUP BY t.year, t.month
ORDER BY t.year, t.month;
```

**B. Top 5 products per month**

```sql
WITH monthly_sales AS (
  SELECT t.year, t.month, i.item_key, i.item_name, SUM(f.total_price) AS revenue
  FROM fact_table f
  JOIN time_dim t ON f.time_key = t.time_key
  JOIN item_dim i ON f.item_key = i.item_key
  GROUP BY t.year, t.month, i.item_key, i.item_name
)
SELECT year, month, item_key, item_name, revenue
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY revenue DESC) rn
  FROM monthly_sales
) s
WHERE rn <= 5
ORDER BY year, month, revenue DESC;
```

**C. Repeat customer rate**

```sql
WITH orders_per_customer AS (
  SELECT customer_key, COUNT(*) AS orders_count
  FROM fact_table
  GROUP BY customer_key
)
SELECT
  SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END)::decimal / COUNT(*) AS repeat_customer_rate
FROM orders_per_customer;
```

**D. Running total per customer**

```sql
SELECT f.customer_key, t.date, f.payment_key, f.total_price,
       SUM(f.total_price) OVER (PARTITION BY f.customer_key ORDER BY t.date, f.payment_key) AS running_total
FROM fact_table f
JOIN time_dim t ON f.time_key = t.time_key
ORDER BY f.customer_key, t.date;
```

**E. Average Order Value (AOV) per month**

```sql
SELECT t.year, t.month, 
       SUM(f.total_price)/COUNT(DISTINCT f.payment_key) AS avg_order_value
FROM fact_table f
JOIN time_dim t ON f.time_key = t.time_key
GROUP BY t.year, t.month
ORDER BY t.year, t.month;
```

**F. Revenue by store district**

```sql
SELECT s.district, SUM(f.total_price) AS total_revenue
FROM fact_table f
JOIN store_dim s ON f.store_key = s.store_key
GROUP BY s.district
ORDER BY total_revenue DESC
LIMIT 10;
```

---

## 7. Data Validation (from `08_checks.sql`)

Example check: validate all customer_keys in fact table exist in dimension table.

```sql
SELECT COUNT(*) 
FROM fact_table f
LEFT JOIN customer_dim c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;
```

**Orphaned item_key in fact table**
```sql
SELECT COUNT(*)
FROM fact_table f
LEFT JOIN item_dim i ON f.item_key = i.item_key
WHERE i.item_key IS NULL;
```

**Orphaned store_key in fact table**
```sql
SELECT COUNT(*)
FROM fact_table f
LEFT JOIN store_dim s ON f.store_key = s.store_key
WHERE s.store_key IS NULL;
```

**Validate total_price calculation**
```sql
SELECT COUNT(*)
FROM fact_table
WHERE total_price <> quantity * unit_price;
```

---

## 8. Insights & Suggested Visualizations (from `insights.sql`) 



1. **Seasonality:** 
    ```sql
    SELECT t.year, t.quarter, SUM(f.total_price) AS total_revenue
    FROM fact_table f
    JOIN time_dim t ON f.time_key = t.time_key
    GROUP BY t.year, t.quarter
    ORDER BY t.year, t.quarter;
    ```
    Analyzing total revenue by quarter shows consistent peaks in Q3 and Q4, indicating seasonal spikes likely driven by holidays and promotions. Businesses can leverage this insight for inventory planning, targeted marketing, and staff allocation.

    **Suggested Visualization:**
    * Line chart: Quarter vs Total Revenue
    * Optional: Highlight peak quarters with annotations for holidays or promotions.

2. **Top Sellers:** 
    ```sql
    WITH product_revenue AS (
        SELECT i.item_key, i.item_name, SUM(f.total_price) AS revenue
        FROM fact_table f
        JOIN item_dim i ON f.item_key = i.item_key
        GROUP BY i.item_key, i.item_name
    ),
    ranked AS (
        SELECT *,
            SUM(revenue) OVER (ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
            / SUM(revenue) OVER () AS cumulative_pct
        FROM product_revenue
    )
    SELECT item_key, item_name, revenue, cumulative_pct
    FROM ranked
    WHERE cumulative_pct <= 0.80
    ORDER BY revenue DESC;
    ```
    The top-selling products (e.g., Red Bull 12oz, K Cups variants) account for roughly the first ~20% of products but drive over 75% of revenue. This highlights a classic Pareto distribution, suggesting focus on high-performing SKUs for marketing and inventory strategies.

    **Suggested Visualization:**
    * Stacked bar chart or cumulative revenue curve: Top products contributing to total revenue.
    * Optional: Cumulative % revenue to visually demonstrate Pareto effect.

3. **Customer Loyalty:** 
    ```sql
    WITH orders_per_customer AS (
        SELECT customer_key, COUNT(*) AS orders_count
        FROM fact_table
        GROUP BY customer_key
    )
    SELECT
    SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END)::decimal / COUNT(*) AS repeat_customer_rate
    FROM orders_per_customer;
    ```
    Analysis of repeat purchases shows that 100% of customers in the dataset have made multiple purchases. This indicates extremely high customer retention in the sample data, which could be used to model loyalty programs, retention campaigns, and personalized marketing. (Note: because synthetic data is used, this is expected — in real-world data, this would likely be lower.)

    **Suggested Visualization:**
    * Heatmap or bar chart: Customer cohorts vs repeat purchase rate
    * Optional: Track changes in repeat behavior over time.

## 9. License & Contact

Open-sourced under MIT License.
For questions or collaboration, contact: **Nthabeleng Vilakazi | www.linkedin.com/in/nthabelengvilakazi**
