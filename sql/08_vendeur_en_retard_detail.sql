-- 08 — Contrôle ligne à ligne de l'attribution du retard
-- Permet de vérifier la logique avant de la généraliser : un vendeur peut être en retard
-- alors que la commande arrive quand même en avance chez le client.
WITH limites AS (
  SELECT
    order_id,
    MAX(shipping_limit_date) AS date_limite_commande
  FROM `olist.order_items`
  GROUP BY order_id
)
SELECT
  o.order_id,
  DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) AS ecart_jours,
  l.date_limite_commande,
  o.order_delivered_carrier_date,
  o.order_delivered_carrier_date > l.date_limite_commande AS vendeur_en_retard
FROM `olist.orders` AS o
JOIN limites AS l ON o.order_id = l.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
LIMIT 10;
