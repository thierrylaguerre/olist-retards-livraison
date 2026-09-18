-- 09 — Origine des retards : vendeur ou transporteur
-- Les deux premières colonnes servent de contrôle : elles doivent redonner
-- les 96 470 commandes et les 6 534 retards de la requête 05.
-- Résultat : vendeur 1 814 (27,76 %) · transporteur 4 719 (72,22 %) · indéterminé 1.
-- Note : NOT NULL vaut NULL, donc une date de remise manquante n'est comptée
-- dans aucune des deux catégories : elle est isolée dans « indetermine ».
WITH limites AS (
  SELECT
    order_id,
    MAX(shipping_limit_date) AS date_limite_commande
  FROM `olist.order_items`
  GROUP BY order_id
),
base AS (
  SELECT
    DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) > 0 AS commande_en_retard,
    o.order_delivered_carrier_date > l.date_limite_commande AS vendeur_en_retard,
    o.order_delivered_carrier_date IS NULL AS date_transporteur_manquante
  FROM `olist.orders` AS o
  JOIN limites AS l ON o.order_id = l.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
  COUNT(*) AS commandes_livrees,
  COUNTIF(commande_en_retard) AS commandes_en_retard,
  COUNTIF(commande_en_retard AND vendeur_en_retard) AS retard_vendeur,
  COUNTIF(commande_en_retard AND NOT vendeur_en_retard) AS retard_transporteur,
  COUNTIF(commande_en_retard AND date_transporteur_manquante) AS indetermine,
  ROUND(COUNTIF(commande_en_retard AND vendeur_en_retard) / COUNTIF(commande_en_retard) * 100, 2) AS pct_vendeur,
  ROUND(COUNTIF(commande_en_retard AND NOT vendeur_en_retard) / COUNTIF(commande_en_retard) * 100, 2) AS pct_transporteur
FROM base;
