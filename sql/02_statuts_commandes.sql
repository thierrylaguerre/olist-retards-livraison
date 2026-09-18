-- 02 — Répartition des commandes par statut
-- Résultat : delivered 96 478 (97 %) · shipped 1 107 · canceled 625 · unavailable 609
--            invoiced 314 · processing 301 · created 5 · approved 2
SELECT
  order_status AS statut,
  COUNT(*) AS nombre_commandes
FROM `olist.orders`
GROUP BY order_status
ORDER BY nombre_commandes DESC;
