---Seasonality---
SELECT t.year, t.quarter, SUM(f.total_price) AS total_revenue
FROM fact_table f
JOIN time_dim t ON f.time_key = t.time_key
GROUP BY t.year, t.quarter
ORDER BY t.year, t.quarter;

---Top Sellers---
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

---Customer Loyalty---
WITH orders_per_customer AS (
    SELECT customer_key, COUNT(*) AS orders_count
    FROM fact_table
    GROUP BY customer_key
)
SELECT
  SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END)::decimal / COUNT(*) AS repeat_customer_rate
FROM orders_per_customer;

