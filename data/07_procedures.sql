---Top N products for a year/month---
CREATE OR REPLACE FUNCTION top_n_products_month(p_year INT, p_month INT, p_n INT)
RETURNS TABLE(item_key BIGINT, item_name TEXT, total_qty BIGINT, total_revenue NUMERIC) AS $$
BEGIN
  RETURN QUERY
  SELECT i.item_key, i.item_name, SUM(f.quantity) AS total_qty, SUM(f.total_price) AS total_revenue
  FROM fact_table f
  JOIN item_dim i ON f.item_key = i.item_key
  JOIN time_dim t ON f.time_key = t.time_key
  WHERE t.year = p_year AND t.month = p_month
  GROUP BY i.item_key, i.item_name
  ORDER BY total_revenue DESC
  LIMIT p_n;
END;
$$ LANGUAGE plpgsql;

---Monthly KPI function (returns rows of metric/value)---
CREATE OR REPLACE FUNCTION monthly_kpis(p_start DATE, p_end DATE)
RETURNS TABLE(kpi_name TEXT, kpi_value NUMERIC) AS $$
BEGIN
  RETURN QUERY
  SELECT 'total_revenue', COALESCE(SUM(f.total_price),0)::NUMERIC
  FROM fact_table f
  JOIN time_dim t ON f.time_key = t.time_key
  WHERE t.date BETWEEN p_start AND p_end;

  RETURN QUERY
  SELECT 'total_transactions', COUNT(*)::NUMERIC
  FROM fact_table f
  JOIN time_dim t ON f.time_key = t.time_key
  WHERE t.date BETWEEN p_start AND p_end;

  RETURN QUERY
  SELECT 'unique_customers', COUNT(DISTINCT f.customer_key)::NUMERIC
  FROM fact_table f
  JOIN time_dim t ON f.time_key = t.time_key
  WHERE t.date BETWEEN p_start AND p_end;

  RETURN QUERY
  SELECT 'average_order_value', COALESCE(AVG(f.total_price),0)::NUMERIC
  FROM fact_table f
  JOIN time_dim t ON f.time_key = t.time_key
  WHERE t.date BETWEEN p_start AND p_end;
END;
$$ LANGUAGE plpgsql;