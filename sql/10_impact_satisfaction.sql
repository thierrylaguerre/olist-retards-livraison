-- 10 — Impact du retard sur la note client
-- Les avis sont d'abord ramenés à une ligne par commande (certaines en ont plusieurs).
-- LEFT JOIN : on garde les commandes sans avis, d'où l'écart entre COUNT(*)
-- et COUNT(note_moyenne).
-- Résultat : à l'heure 4,29/5 (9,2 % de notes ≤ 2) · retard vendeur 2,27 (63,1 %)
--            · retard transporteur 2,27 (62,1 %).
WITH limites AS (
  SELECT
    order_id,
    MAX(shipping_limit_date) AS date_limite_commande
  FROM `olist.order_items`
  GROUP BY order_id
),
avis AS (
  SELECT
    order_id,
    AVG(review_score) AS note_moyenne
  FROM `olist.order_reviews`
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
    a.note_moyenne
  FROM `olist.orders` AS o
  JOIN limites AS l ON o.order_id = l.order_id
  LEFT JOIN avis AS a ON o.order_id = a.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
  categorie,
  COUNT(*) AS commandes,
  COUNT(note_moyenne) AS commandes_avec_avis,
  ROUND(AVG(note_moyenne), 2) AS note_moyenne,
  ROUND(COUNTIF(note_moyenne <= 2) / COUNT(note_moyenne) * 100, 1) AS pct_notes_1_ou_2
FROM base
GROUP BY categorie
ORDER BY categorie;
