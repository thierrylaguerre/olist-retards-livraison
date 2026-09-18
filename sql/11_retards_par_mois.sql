-- 11 — Saisonnalité : taux de retard par mois d'achat
-- Résultat : 2,8 à 4,6 % en régime normal, puis nov. 2017 12,4 %, fév. 2018 14,1 %,
-- mars 2018 19,0 %. Ces trois mois = 21,6 % des commandes mais 48,3 % des retards.
-- Les mois de 2016 portent sur très peu de commandes : à lire avec le volume.
WITH base AS (
  SELECT
    DATE_TRUNC(DATE(order_purchase_timestamp), MONTH) AS mois,
    DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_estimated_delivery_date), DAY) > 0 AS en_retard
  FROM `olist.orders`
  WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
)
SELECT
  mois,
  COUNT(*) AS commandes,
  COUNTIF(en_retard) AS commandes_en_retard,
  ROUND(COUNTIF(en_retard) / COUNT(*) * 100, 1) AS taux_retard_pct
FROM base
GROUP BY mois
ORDER BY mois;
