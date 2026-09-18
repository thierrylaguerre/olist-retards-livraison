-- 12 — Délais médians de préparation et de transport, par catégorie de retard
-- APPROX_QUANTILES(x, 2)[OFFSET(1)] renvoie la médiane, moins sensible que la moyenne
-- aux quelques commandes extrêmes (jusqu'à 188 jours de retard).
-- Résultat : à l'heure 2,1 / 6,9 jours · retard transporteur 2,4 / 28,8
--            · retard vendeur 10,9 / 15,3.
WITH limites AS (
  SELECT
    order_id,
    MAX(shipping_limit_date) AS date_limite_commande
  FROM `olist.order_items`
  GROUP BY order_id
),
base AS (
  SELECT
    CASE
      WHEN DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) <= 0 THEN '1 - a l heure ou en avance'
      WHEN o.order_delivered_carrier_date IS NULL THEN '4 - indetermine'
      WHEN o.order_delivered_carrier_date > l.date_limite_commande THEN '2 - retard vendeur'
      ELSE '3 - retard transporteur'
    END AS categorie,
    TIMESTAMP_DIFF(o.order_delivered_carrier_date, o.order_purchase_timestamp, HOUR) / 24 AS jours_preparation,
    TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date, HOUR) / 24 AS jours_transport,
    TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, HOUR) / 24 AS jours_total,
    TIMESTAMP_DIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp, HOUR) / 24 AS jours_promis
  FROM `olist.orders` AS o
  JOIN limites AS l ON o.order_id = l.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
  categorie,
  COUNT(*) AS commandes,
  ROUND(APPROX_QUANTILES(jours_preparation, 2)[OFFSET(1)], 1) AS mediane_preparation,
  ROUND(APPROX_QUANTILES(jours_transport, 2)[OFFSET(1)], 1) AS mediane_transport,
  ROUND(APPROX_QUANTILES(jours_total, 2)[OFFSET(1)], 1) AS mediane_total,
  ROUND(APPROX_QUANTILES(jours_promis, 2)[OFFSET(1)], 1) AS mediane_promise
FROM base
GROUP BY categorie
ORDER BY categorie;
