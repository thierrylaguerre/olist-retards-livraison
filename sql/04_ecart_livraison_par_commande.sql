-- 04 — Écart en jours entre la livraison réelle et la date promise
-- Convention : positif = retard, 0 = livré le jour prévu, négatif = en avance.
-- DATE() retire l'heure : la date promise n'en a pas, on compare donc des jours.
SELECT
  order_id,
  DATE(order_estimated_delivery_date) AS date_estimee,
  DATE(order_delivered_customer_date) AS date_reelle,
  DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date), DAY) AS ecart_jours
FROM `olist.orders`
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
LIMIT 10;
