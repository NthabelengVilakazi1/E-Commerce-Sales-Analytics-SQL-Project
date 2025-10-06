---A. Revenue by month---
SELECT t.year, t.month, SUM(f.total_price) AS revenue
FROM fact_table f
JOIN time_dim t ON f.time_key = t.time_key
GROUP BY t.year, t.month
ORDER BY t.year, t.month;

---B. Top 5 products per month---
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

---C. Repeat customer rate---
WITH orders_per_customer AS (
  SELECT customer_key, COUNT(*) AS orders_count
  FROM fact_table
  GROUP BY customer_key
)
SELECT
  SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END)::decimal / COUNT(*) AS repeat_customer_rate
FROM orders_per_customer;

---D. Running total per customer---
SELECT f.customer_key, t.date, f.payment_key, f.total_price,
       SUM(f.total_price) OVER (PARTITION BY f.customer_key ORDER BY t.date, f.payment_key) AS running_total
FROM fact_table f
JOIN time_dim t ON f.time_key = t.time_key
ORDER BY f.customer_key, t.date;

---E. Average Order Value (AOV) per month---
SELECT t.year, t.month, 
       SUM(f.total_price)/COUNT(DISTINCT f.payment_key) AS avg_order_value
FROM fact_table f
JOIN time_dim t ON f.time_key = t.time_key
GROUP BY t.year, t.month
ORDER BY t.year, t.month;

---F. Revenue by store district---
SELECT s.district, SUM(f.total_price) AS total_revenue
FROM fact_table f
JOIN store_dim s ON f.store_key = s.store_key
GROUP BY s.district
ORDER BY total_revenue DESC
LIMIT 10;
