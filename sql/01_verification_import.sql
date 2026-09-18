-- 01 — Vérification de l'import : nombre de lignes par table
-- Attendu : orders 99 441 · customers 99 441 · order_items 112 650 · order_payments 103 886
--           order_reviews 99 224 · products 32 951 · sellers 3 095 · geolocation 1 000 163
--           category_translation 71
SELECT 'category_translation' AS table_name, COUNT(*) AS total_rows FROM `olist.category_translation`
UNION ALL SELECT 'customers', COUNT(*) FROM `olist.customers`
UNION ALL SELECT 'geolocation', COUNT(*) FROM `olist.geolocation`
UNION ALL SELECT 'order_items', COUNT(*) FROM `olist.order_items`
UNION ALL SELECT 'order_payments', COUNT(*) FROM `olist.order_payments`
UNION ALL SELECT 'order_reviews', COUNT(*) FROM `olist.order_reviews`
UNION ALL SELECT 'orders', COUNT(*) FROM `olist.orders`
UNION ALL SELECT 'products', COUNT(*) FROM `olist.products`
UNION ALL SELECT 'sellers', COUNT(*) FROM `olist.sellers`;
