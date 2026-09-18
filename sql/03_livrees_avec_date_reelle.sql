-- 03 — Commandes livrées : combien ont réellement une date de livraison client ?
-- COUNT(*) compte toutes les lignes, COUNT(colonne) ignore les valeurs NULL :
-- l'écart entre les deux donne le nombre de dates manquantes.
-- Résultat : 96 478 livrées, 96 470 avec date réelle → 8 anomalies, exclues de l'analyse.
SELECT
  COUNT(*) AS nombre_commandes_livrees,
  COUNT(order_delivered_customer_date) AS livrees_avec_date_reelle
FROM `olist.orders`
WHERE order_status = 'delivered';
