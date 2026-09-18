-- 14 — Retards vendeurs absorbés par la marge de la date promise
-- Résultat : 8 711 commandes (9,0 %) partent en retard du vendeur,
-- dont 6 897 (79,2 %) arrivent quand même à l'heure chez le client.
-- Les 1 814 restantes sont les retards vendeurs de la requête 09.
WITH limites AS (
  SELECT
    order_id,
    MAX(shipping_limit_date) AS date_limite_commande
  FROM `olist.order_items`
  GROUP BY order_id
),
base AS (
  SELECT
    o.order_delivered_carrier_date > l.date_limite_commande AS vendeur_en_retard,
    DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) > 0 AS commande_en_retard
  FROM `olist.orders` AS o
  JOIN limites AS l ON o.order_id = l.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
  COUNT(*) AS commandes_livrees,
  COUNTIF(vendeur_en_retard) AS vendeur_en_retard,
  ROUND(COUNTIF(vendeur_en_retard) / COUNT(*) * 100, 1) AS pct_commandes_vendeur_en_retard,
  COUNTIF(vendeur_en_retard AND NOT commande_en_retard) AS dont_livrees_a_l_heure,
  ROUND(COUNTIF(vendeur_en_retard AND NOT commande_en_retard) / COUNTIF(vendeur_en_retard) * 100, 1) AS pct_absorbes_par_la_marge
FROM base;
