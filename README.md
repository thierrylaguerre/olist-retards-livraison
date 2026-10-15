# D'où viennent les retards de livraison d'une marketplace, et que coûtent-ils ?

> 📊 **Nouveau : le dashboard Power BI** — 4 pages, chiffres recontrôlés contre le SQL. [Voir la section 8](#8-v2--dashboard-power-bi) · [Télécharger le .pbix](https://github.com/thierrylaguerre/olist-retards-livraison/releases/tag/v2.0)

---

## Sommaire

1. [Contexte et objectif](#1-contexte-et-objectif)
2. [Structure des données](#2-structure-des-données)
3. [Résumé](#3-résumé)
4. [Analyse approfondie](#4-analyse-approfondie)
   - [4.1 Le retard est rare, mais il arrive par crises](#41-le-retard-est-rare-mais-il-arrive-par-crises)
   - [4.2 Près de trois retards sur quatre se jouent après la remise au transporteur](#42-près-de-trois-retards-sur-quatre-se-jouent-après-la-remise-au-transporteur)
   - [4.3 La date promise est si large qu'elle masque les retards des vendeurs](#43-la-date-promise-est-si-large-quelle-masque-les-retards-des-vendeurs)
   - [4.4 La distance explique l'essentiel des écarts entre régions](#44-la-distance-explique-lessentiel-des-écarts-entre-régions)
   - [4.5 Un retard coûte deux étoiles, quel qu'en soit le responsable](#45-un-retard-coûte-deux-étoiles-quel-quen-soit-le-responsable)
5. [Recommandations](#5-recommandations)
6. [Limites](#6-limites)
7. [Reproduire l'analyse](#7-reproduire-lanalyse)
8. [v2 — Dashboard Power BI](#8-v2--dashboard-power-bi)

---

## 1. Contexte et objectif

Olist est une marketplace brésilienne : des vendeurs indépendants y proposent leurs produits, et chaque commande passe successivement entre deux mains. **Le vendeur** prépare le colis et le remet à un transporteur avant une date limite contractuelle. **Le transporteur** l'achemine ensuite jusqu'au client, avant la date annoncée lors de l'achat.

Quand le colis arrive en retard, le client, lui, ne voit qu'une chose : un engagement non tenu. Mais pour la marketplace, la réponse conditionne l'action. **Un retard vendeur se corrige par la relation fournisseur ; un retard transporteur se corrige par la logistique.** Les deux leviers n'ont ni le même coût, ni le même délai d'effet.

Mon expérience de facteur m'a montré un réflexe constant : dès qu'un courrier ou un recommandé arrive en retard, c'est le livreur qu'on accuse. Pourtant, la plupart du temps, le retard est déjà pris avant lui : le pli est arrivé tard au centre, et aucune tournée ne rattrape ce temps-là.

Le client se plaint du livreur parce que c'est la seule personne qu'il voit. Le reste de la chaîne lui est invisible.

J'ai voulu confronter ce réflexe à des données : quand une livraison arrive en retard, est-ce vraiment la faute de celui qu'on accuse ?

**La question posée : quand une livraison arrive en retard, l'origine est-elle le vendeur ou le transport, et que coûte ce retard en satisfaction client ?**

Données source : [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Analyse réalisée en SQL sur Google BigQuery ; les requêtes sont dans le dossier [`sql/`](sql/). Les résultats sont ensuite restitués dans un dashboard Power BI ([section 8](#8-v2--dashboard-power-bi)).

---

## 2. Structure des données

**99 441 commandes · 9 tables relationnelles · 27 états brésiliens · de septembre 2016 à août 2018**

Le jeu de données décrit le cycle de vie complet d'une commande, réparti sur plusieurs tables reliées par des identifiants.

| Table | Lignes | Rôle |
|---|---|---|
| `orders` | 99 441 | **Table pivot** : une ligne par commande, avec les quatre dates du cycle de vie |
| `order_items` | 112 650 | Une ligne par **article**, avec la date limite de remise au transporteur |
| `order_reviews` | 99 224 | Avis client, note de 1 à 5 |
| `customers` | 99 441 | Ville et état du client |
| `products`, `sellers`, `order_payments`, `geolocation`, `category_translation` | — | Non utilisées dans l'analyse SQL ; `products`, `sellers` et `category_translation` servent au dashboard Power BI |

Les quatre dates de `orders` structurent toute l'analyse :

| Colonne | Étape du parcours |
|---|---|
| `order_purchase_timestamp` | Achat par le client |
| `order_delivered_carrier_date` | Remise du colis au transporteur |
| `order_delivered_customer_date` | Livraison effective chez le client |
| `order_estimated_delivery_date` | Date promise au client lors de l'achat |

**Une ligne par commande, ou une ligne par article : la distinction conditionne tous les comptages.** `orders` compte une ligne par commande, mais `order_items` en compte une par article : 112 650 lignes pour seulement 98 666 commandes, avec jusqu'à 21 lignes pour une même commande. Joindre les deux tables sans précaution comptabiliserait près de 14 000 commandes plusieurs fois. Le même piège existe sur `order_reviews`, où
