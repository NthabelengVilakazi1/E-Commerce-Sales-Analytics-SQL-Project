SELECT COUNT (*) 
FROM fact_table f 
LEFT JOIN customer_dim c 
ON f.customer_key = c.customer_key 
WHERE c.customer_key IS NULL;

---Orphaned item_key in fact table---
SELECT COUNT(*)
FROM fact_table f
LEFT JOIN item_dim i ON f.item_key = i.item_key
WHERE i.item_key IS NULL;

---Orphaned store_key in fact table---
SELECT COUNT(*)
FROM fact_table f
LEFT JOIN store_dim s ON f.store_key = s.store_key
WHERE s.store_key IS NULL;

---Validate total_price calculation---
SELECT COUNT(*)
FROM fact_table
WHERE total_price <> quantity * unit_price;
