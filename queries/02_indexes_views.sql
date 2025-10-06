-- Indexes for performance
CREATE INDEX idx_fact_time     ON fact_table (time_key);
CREATE INDEX idx_fact_item     ON fact_table (item_key);
CREATE INDEX idx_fact_customer ON fact_table (customer_key);
CREATE INDEX idx_fact_store    ON fact_table (store_key);
CREATE INDEX idx_fact_payment  ON fact_table (payment_key);
CREATE INDEX idx_fact_time_item ON fact_table (time_key, item_key);

CREATE INDEX idx_time_date ON time_dim (date);

-- Materialized view: monthly item sales (refresh periodically)
CREATE MATERIALIZED VIEW mv_month_item_sales AS
SELECT t.year, t.month, i.item_key, i.item_name,
       SUM(f.quantity) AS qty_sold,
       SUM(f.total_price) AS revenue
FROM fact_table f
JOIN time_dim t ON f.time_key = t.time_key
JOIN item_dim i ON f.item_key = i.item_key
GROUP BY t.year, t.month, i.item_key, i.item_name
WITH DATA;

-- Refresh command (run on schedule)
-- REFRESH MATERIALIZED VIEW mv_month_item_sales;
