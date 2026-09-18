-- 13 — Taux de retard et durée de transport par état du client
-- Le HAVING écarte les états de moins de 1 000 commandes, dont les taux seraient
-- trop instables pour être interprétés.
-- Résultat : SP 4,5 % / 4,3 j · RJ 12,1 % / 8,3 j · BA 12,2 % / 13,8 j · CE 13,8 % / 14,8 j.
WITH base AS (
  SELECT
    cu.customer_state AS etat,
    DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) > 0 AS en_retard,
    TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date, HOUR) / 24 AS jours_transport
  FROM `olist.orders` AS o
  JOIN `olist.customers` AS cu ON o.customer_id = cu.customer_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
  etat,
  COUNT(*) AS commandes,
  ROUND(COUNTIF(en_retard) / COUNT(*) * 100, 1) AS taux_retard_pct,
  ROUND(APPROX_QUANTILES(jours_transport, 2)[OFFSET(1)], 1) AS mediane_transport
FROM base
GROUP BY etat
HAVING COUNT(*) >= 1000
ORDER BY commandes DESC;
