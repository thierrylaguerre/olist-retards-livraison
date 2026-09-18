-- 06 — Mesure des doublons avant jointure
-- order_items contient une ligne par article : une commande de 3 articles y apparaît 3 fois.
-- Résultat : 112 650 lignes pour 98 666 commandes distinctes (jusqu'à 21 lignes par commande).
SELECT
  COUNT(*) AS nombre_total,
  COUNT(DISTINCT order_id) AS nombre_sans_doublons
FROM `olist.order_items`;
