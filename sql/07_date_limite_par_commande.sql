-- 07 — Une seule date limite par commande
-- Choix méthodologique : quand les articles d'une commande ont des dates limites différentes,
-- on retient la plus tardive (MAX), car il n'existe qu'une seule remise au transporteur
-- par commande. Ce cas ne concerne que 336 commandes (0,3 %).
SELECT
  order_id,
  MAX(shipping_limit_date) AS date_limite_commande
FROM `olist.order_items`
GROUP BY order_id
LIMIT 10;
