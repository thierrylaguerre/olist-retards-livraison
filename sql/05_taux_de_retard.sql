-- 05 — Taux de retard sur l'ensemble des commandes livrées
-- Résultat : 96 470 commandes, 6 534 en retard, soit 6,77 %.
SELECT
  COUNT(order_delivered_customer_date) AS livrees_avec_date_reelle,
  COUNTIF(DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date), DAY) > 0) AS livrees_en_retard,
  ROUND(COUNTIF(DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date), DAY) > 0) / COUNT(*) * 100, 2) AS pourcentage_retard
FROM `olist.orders`
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
