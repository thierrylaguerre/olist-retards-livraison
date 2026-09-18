# D'où viennent les retards de livraison d'une marketplace, et que coûtent-ils ?

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

---

## 1. Contexte et objectif

Olist est une marketplace brésilienne : des vendeurs indépendants y proposent leurs produits, et chaque commande passe successivement entre deux mains. **Le vendeur** prépare le colis et le remet à un transporteur avant une date limite contractuelle. **Le transporteur** l'achemine ensuite jusqu'au client, avant la date annoncée lors de l'achat.

Quand le colis arrive en retard, le client, lui, ne voit qu'une chose : un engagement non tenu. Mais pour la marketplace, la réponse conditionne l'action. **Un retard vendeur se corrige par la relation fournisseur ; un retard transporteur se corrige par la logistique.** Les deux leviers n'ont ni le même coût, ni le même délai d'effet.

Mon expérience de facteur m'a montré un réflexe constant : dès qu'un courrier ou un recommandé arrive en retard, c'est le livreur qu'on accuse. Pourtant, la plupart du temps, le retard est déjà pris avant lui : le pli est arrivé tard au centre, et aucune tournée ne rattrape ce temps-là.

Le client se plaint du livreur parce que c'est la seule personne qu'il voit. Le reste de la chaîne lui est invisible.

J'ai voulu confronter ce réflexe à des données : quand une livraison arrive en retard, est-ce vraiment la faute de celui qu'on accuse ?

**La question posée : quand une livraison arrive en retard, l'origine est-elle le vendeur ou le transport, et que coûte ce retard en satisfaction client ?**

Données source : [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Analyse réalisée en SQL sur Google BigQuery ; les requêtes sont dans le dossier [`sql/`](sql/).

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
| `products`, `sellers`, `order_payments`, `geolocation`, `category_translation` | — | Non utilisées ici |

Les quatre dates de `orders` structurent toute l'analyse :

| Colonne | Étape du parcours |
|---|---|
| `order_purchase_timestamp` | Achat par le client |
| `order_delivered_carrier_date` | Remise du colis au transporteur |
| `order_delivered_customer_date` | Livraison effective chez le client |
| `order_estimated_delivery_date` | Date promise au client lors de l'achat |

**Une ligne par commande, ou une ligne par article : la distinction conditionne tous les comptages.** `orders` compte une ligne par commande, mais `order_items` en compte une par article : 112 650 lignes pour seulement 98 666 commandes, avec jusqu'à 21 lignes pour une même commande. Joindre les deux tables sans précaution comptabiliserait près de 14 000 commandes plusieurs fois. Le même piège existe sur `order_reviews`, où certaines commandes reçoivent plusieurs avis.

Ces deux tables sont donc **ramenées à une ligne par commande avant toute jointure** — date limite la plus tardive pour les articles, note moyenne pour les avis — et le nombre de commandes est recontrôlé après chaque jointure.

### Périmètre retenu

| Étape | Commandes |
|---|---|
| Total du jeu de données | 99 441 |
| Statut `delivered` uniquement | 96 478 |
| Dont date de livraison réelle renseignée | **96 470** |

Seules les commandes livrées possèdent une date de livraison réelle, sans laquelle aucun retard ne peut être mesuré. Les 1 107 commandes au statut `shipped` — expédiées mais jamais arrivées — sont écartées, tout comme 8 commandes marquées « livrées » sans date de livraison, anomalie de données conservée en mémoire plutôt que corrigée en silence.

---

## 3. Résumé

| Indicateur | Valeur |
|---|---|
| Commandes analysées | **96 470** |
| Commandes livrées en retard | **6 534 — 6,77 %** |
| Retard médian, quand il y a retard | **7 jours** |
| Part des retards imputables au **transport** | **72,2 %** |
| Part des retards imputables au **vendeur** | 27,8 % |
| Délai réel médian, de l'achat à la livraison | 10 jours |
| Délai promis médian lors de l'achat | 23 jours |
| Note moyenne — livraison à l'heure | **4,29 / 5** |
| Note moyenne — livraison en retard | **2,27 / 5** |

Vu de loin, la performance paraît bonne : **93 % des commandes arrivent à la date promise ou en avance**, avec une médiane de 12 jours d'avance.

L'analyse qui suit montre que ce confort tient surtout à une promesse très large — 23 jours annoncés pour 10 jours réels — et non à une maîtrise fine des délais. Cette marge absorbe la quasi-totalité des retards des vendeurs, mais elle cède lors des pics d'activité, où le transport décroche. Et quand elle cède, la sanction client est immédiate et sans nuance.

---

## 4. Analyse approfondie

### 4.1 Le retard est rare, mais il arrive par crises

Le taux de retard global de 6,77 % ne se répartit pas uniformément dans le temps. Il oscille entre 3 % et 5 % en régime normal, puis explose sur trois mois.

| Mois | Commandes | Taux de retard |
|---|---|---|
| Régime normal (moyenne des autres mois) | — | 3 à 5 % |
| Novembre 2017 | 7 288 | **12,4 %** |
| Février 2018 | 6 555 | **14,1 %** |
| Mars 2018 | 7 003 | **19,0 %** |
| Juin 2018 | 6 096 | 1,2 % |

> **Insight.** Ces trois mois représentent 21,6 % des commandes mais **48,3 % de tous les retards de la période**. Novembre 2017 correspond au Black Friday brésilien : le volume de commandes double d'un mois sur l'autre et le taux de retard triple. Le retard n'est pas un bruit de fond régulier, c'est un phénomène de saturation qui se déclenche quand le volume dépasse la capacité d'écoulement.

À l'opposé, juin 2018 affiche 1,2 % de retard pour un volume comparable : la chaîne sait très bien fonctionner quand elle n'est pas saturée.

**→ Recommandation A — Dimensionner la capacité de transport sur les pics, pas sur la moyenne annuelle.** Un plan de charge saisonnier négocié en amont avec les transporteurs sur les périodes à risque toucherait près de la moitié des retards annuels.

---

### 4.2 Près de trois retards sur quatre se jouent après la remise au transporteur

Chaque commande en retard est attribuée en comparant la remise réelle au transporteur (`order_delivered_carrier_date`) à la date limite contractuelle du vendeur (`shipping_limit_date`).

| Origine du retard | Commandes | Part |
|---|---|---|
| **Transporteur** — colis remis à temps, acheminement trop long | **4 719** | **72,2 %** |
| **Vendeur** — colis remis après la date limite | 1 814 | 27,8 % |
| Indéterminé — date de remise absente | 1 | — |

Le détail des délais médians montre où le temps se perd :

| Catégorie | Préparation vendeur | Transport | Total |
|---|---|---|---|
| Livrée à l'heure ou en avance | 2,1 jours | **6,9 jours** | 9,8 jours |
| Retard imputé au transporteur | 2,4 jours | **28,8 jours** | 31,8 jours |
| Retard imputé au vendeur | **10,9 jours** | 15,3 jours | 29,9 jours |

> **Insight.** Quand le transport décroche, il ne décroche pas un peu : la durée d'acheminement médiane passe de 6,9 à 28,8 jours, soit **plus de quatre fois la normale**, et un dixième de ces commandes dépasse 47 jours de transport. Il ne s'agit pas d'un étalement progressif des délais, mais de colis qui sortent du circuit normal — perdus, bloqués, oubliés. Un colis en retard de transport est un colis en anomalie, pas un colis lent.

**→ Recommandation B — Détecter les colis sortis du circuit plutôt que suivre le délai moyen.** Une alerte automatique au-delà de 15 jours de transport, soit le double de la normale, isolerait ces cas pendant qu'une action est encore possible, au lieu de les constater à la livraison.

---

### 4.3 La date promise est si large qu'elle masque les retards des vendeurs

La date annoncée au client lors de l'achat est, en médiane, à **23 jours**, alors que la livraison prend réellement **10 jours**. Cette marge de treize jours a une conséquence directe sur la lecture des retards vendeurs.

| Indicateur | Valeur |
|---|---|
| Commandes dont le vendeur a dépassé sa date limite | **8 711 — 9,0 %** |
| Parmi elles, commandes livrées **quand même à l'heure** | **6 897 — 79,2 %** |
| Retard vendeur médian, quand il y en a un | 4 jours |

> **Insight.** Un vendeur sur onze rate sa date limite, mais dans près de 8 cas sur 10 le client n'en saura jamais rien : la marge de la promesse absorbe le retard. C'est confortable à court terme, mais cela prive la marketplace d'un signal précieux — **le retard vendeur est un indicateur avancé du retard client**, invisible dans les tableaux de bord qui ne suivent que la satisfaction finale. Le jour où la chaîne se tend, comme en mars 2018, cette marge disparaît et les retards vendeurs se transforment en retards clients.

**→ Recommandation C — Suivre le respect de la date limite vendeur comme indicateur à part entière**, indépendamment du résultat final. Un vendeur qui rate régulièrement sa date limite est un risque latent, même si ses clients sont pour l'instant livrés à temps.

---

### 4.4 La distance explique l'essentiel des écarts entre régions

Les commandes se concentrent autour de São Paulo, qui pèse 42 % du volume. Le taux de retard suit l'éloignement de ce centre de gravité logistique.

| État | Commandes | Taux de retard | Transport médian |
|---|---|---|---|
| **SP** — São Paulo | 40 494 | **4,5 %** | **4,3 jours** |
| PR — Paraná | 4 923 | 4,0 % | 7,1 jours |
| MG — Minas Gerais | 11 354 | 4,6 % | 7,1 jours |
| DF — District fédéral | 2 080 | 5,7 % | 8,0 jours |
| RS — Rio Grande do Sul | 5 344 | 6,1 % | 10,0 jours |
| GO — Goiás | 1 957 | 6,5 % | 10,9 jours |
| SC — Santa Catarina | 3 546 | 8,2 % | 9,6 jours |
| PE — Pernambouc | 1 593 | 9,6 % | 12,9 jours |
| ES — Espírito Santo | 1 995 | 10,7 % | 10,0 jours |
| **RJ** — Rio de Janeiro | 12 350 | **12,1 %** | **8,3 jours** |
| BA — Bahia | 3 256 | 12,2 % | 13,8 jours |
| **CE** — Ceará | 1 279 | **13,8 %** | 14,8 jours |

*États comptant au moins 1 000 commandes livrées, classés par durée de transport croissante.*

> **Insight.** Le lien entre durée de transport et taux de retard est net : de São Paulo (4,3 jours, 4,5 %) jusqu'au Ceará, à l'autre bout du pays (14,8 jours, 13,8 %), les deux colonnes progressent ensemble. Une exception saute aux yeux : **Rio de Janeiro**. Avec 8,3 jours de transport médian, à peine plus que Minas Gerais, l'état affiche 12,1 % de retard, soit presque le triple, et se hisse au niveau des états les plus éloignés du pays. Ce n'est donc pas la distance qui pénalise Rio, mais la **variabilité** : la moitié des livraisons s'y passe normalement, l'autre dérape. Rio étant le deuxième marché du pays avec 12 350 commandes, c'est aussi le gisement de retards le plus concentré.

**→ Recommandation D — Traiter Rio de Janeiro comme un cas à part.** Ni la distance ni le volume n'expliquent son taux de retard : la cause est locale — densité urbaine, accès aux quartiers, partenaire de livraison. C'est le seul endroit où une analyse terrain vaut mieux qu'une analyse de données.

---

### 4.5 Un retard coûte deux étoiles, quel qu'en soit le responsable

| Catégorie | Commandes | Note moyenne | Part de notes 1 ou 2 |
|---|---|---|---|
| Livrée à l'heure ou en avance | 89 936 | **4,29 / 5** | 9,2 % |
| Retard imputé au vendeur | 1 814 | **2,27 / 5** | 63,1 % |
| Retard imputé au transporteur | 4 719 | **2,27 / 5** | 62,1 % |

> **Insight.** Les deux notes moyennes sont rigoureusement identiques, à deux centièmes près. **Le client ne fait aucune différence entre un retard vendeur et un retard transporteur** : il note l'engagement non tenu, pas le maillon fautif. Une livraison à l'heure obtient 9 % de notes basses ; une livraison en retard, plus de 62 %. Le retard multiplie donc par près de sept la probabilité d'un avis très négatif.

**→ Recommandation E — Découpler la gestion interne de la communication client.** La distinction vendeur/transporteur sert à corriger la chaîne, pas à s'expliquer auprès du client : pour lui, la marketplace est seule responsable. Prévenir avant la date promise, plutôt que justifier après, est le seul levier disponible une fois le retard acquis.

---

## 5. Recommandations

### Priorité 1 — Dimensionner le transport sur les pics *(recommandation A)*

**Le plus fort levier de volume.** Trois mois concentrent 48 % des retards annuels. Un plan de charge saisonnier négocié en amont, sur des périodes connues à l'avance comme le Black Friday, agit sur la moitié du problème.

| | |
|---|---|
| Effort | Moyen — négociation transporteurs, anticipation |
| Gain | Jusqu'à la moitié des retards annuels |
| Prérequis | Prévision de volume par mois |

### Priorité 2 — Alerter sur les colis sortis du circuit *(recommandation B)*

**Le plus simple à mettre en place.** Un retard de transport n'est pas un délai allongé, c'est une anomalie : 28,9 jours contre 6,9 en temps normal. Une alerte au-delà de 15 jours de transport ne demande aucune décision de gestion, juste une règle.

| | |
|---|---|
| Effort | Faible — une règle de seuil sur les données existantes |
| Gain | Traitement des cas graves avant la livraison |

### Priorité 3 — Suivre la ponctualité des vendeurs pour elle-même *(recommandation C)*

9 % des commandes partent en retard du vendeur, et la marge de la promesse en masque 79 %. C'est un indicateur avancé gratuit, qui deviendra un indicateur de crise dès que la chaîne se tendra.

| | |
|---|---|
| Effort | Faible — indicateur déjà calculable |
| Gain | Détection des vendeurs à risque avant l'incident client |

### Priorité 4 — Enquêter sur Rio de Janeiro *(recommandation D)*

Deuxième marché du pays, taux de retard presque triple de celui de São Paulo sans que la distance l'explique. Le diagnostic demande du terrain, pas du SQL.

| | |
|---|---|
| Effort | Moyen — analyse locale |
| Gain | Le gisement de retards le plus concentré géographiquement |

### Priorité 5 — Prévenir le client plutôt que lui expliquer *(recommandation E)*

**À traiter en continu.** Le retard fait chuter la note de 4,29 à 2,27, sans distinction de responsable. Une notification avant la date promise ne supprime pas le retard, mais c'est le seul levier restant une fois qu'il est acquis.

| | |
|---|---|
| Effort | Faible — communication automatisée |
| Gain | Limitation de la casse sur les avis |

---

## 6. Limites

- **L'absence du destinataire n'est pas mesurable.** C'est pourtant une cause fréquente de retard sur le terrain : le colis est présenté, personne n'ouvre, il repart pour un nouveau passage. Les données ne distinguent pas ce cas d'un retard de transport, qui se trouve donc mécaniquement surestimé.
- **La responsabilité partagée n'est pas traitée.** Un colis remis en retard d'un jour par le vendeur puis livré avec dix jours de retard est intégralement imputé au vendeur.
- **Les commandes jamais livrées sont exclues** : 1 107 commandes au statut `shipped`, sans doute les cas les plus graves, sortent du périmètre faute de date de livraison.
- **Une commande, plusieurs vendeurs.** Quand les articles d'une commande ont des dates limites différentes, la plus tardive est retenue. Le cas ne concerne que 336 commandes (0,3 %), mais il rend le jugement légèrement favorable aux vendeurs.
- **Portée des résultats.** Données de 2016 à 2018, sur une seule marketplace brésilienne : les mécanismes se transposent, pas les ordres de grandeur.

---

## 7. Reproduire l'analyse

1. Télécharger les fichiers CSV du jeu de données Olist sur Kaggle.
2. Créer un dataset `olist` dans BigQuery et importer les tables. Pour `order_reviews`, cocher **Allow quoted newlines** : certains commentaires contiennent des retours à la ligne et l'import échoue sans cette option.
3. Exécuter les scripts du dossier [`sql/`](sql/) dans l'ordre.

| Fichier | Ce qu'il produit |
|---|---|
| `01_verification_import.sql` | Contrôle du nombre de lignes des 9 tables |
| `02_statuts_commandes.sql` | Répartition des commandes par statut |
| `03_livrees_avec_date_reelle.sql` | Détection des livraisons sans date réelle |
| `04_ecart_livraison_par_commande.sql` | Écart en jours entre livraison et promesse |
| `05_taux_de_retard.sql` | Taux de retard global |
| `06_doublons_order_items.sql` | Mesure des doublons avant jointure |
| `07_date_limite_par_commande.sql` | Une date limite par commande |
| `08_vendeur_en_retard_detail.sql` | Contrôle ligne à ligne de l'attribution |
| `09_origine_des_retards.sql` | Répartition vendeur / transporteur |
| `10_impact_satisfaction.sql` | Note moyenne par catégorie de retard |
| `11_retards_par_mois.sql` | Saisonnalité du taux de retard |
| `12_delais_par_categorie.sql` | Délais médians de préparation et de transport |
| `13_retards_par_etat.sql` | Taux de retard et transport par état |
| `14_marge_de_la_promesse.sql` | Retards vendeurs absorbés par la marge |

---

## À propos

**Thierry Laguerre** · Candidat Data Analyst junior · Paris — Île-de-France

Master Big Data — Université Paris 8 · Licence Informatique — Sorbonne Paris Nord

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Thierry_Laguerre-blue?logo=linkedin)](https://www.linkedin.com/in/thierry-laguerre-ba1267257/)
[![GitHub](https://img.shields.io/badge/GitHub-thierrylaguerre-black?logo=github)](https://github.com/thierrylaguerre)
[![Email](https://img.shields.io/badge/Email-thierrylaguerre81@gmail.com-red?logo=gmail)](mailto:thierrylaguerre81@gmail.com)
