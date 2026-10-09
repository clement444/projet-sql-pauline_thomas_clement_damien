# Journal de bord

## 1. Choix du theme et de la modelisation

Pour ce projet, on est partis sur un SOC de cybersecurite :
- Le type natif `INET` de Postgres est utilise pour les adresses IP de la table `equipements` au lieu d'un `VARCHAR`, ce qui evite les formats d'IP invalides.
- La table `analystes` est hierarchique : chaque analyste a un champ `manager_id` qui renvoie vers `analyste_id` de la meme table. Le responsable du SOC (le CISO) a un `manager_id` a `NULL`.
- La table `alertes` sert de table d'evenements temporels avec la date, la taille des donnees et le score de confiance.
- Pour eviter les incoherences dans les incidents, on a mis une contrainte `CHECK` pour s'assurer que `date_cloture >= date_assignation`.

---

## 2. Ce que chaque requete nous apprend sur les donnees

- **Q2.1 (RANK / DENSE_RANK)** : Les regles de force brute SSH/RDP et de malware Cobalt Strike sont celles qui generent le plus d'alertes en severite CRITICAL.
- **Q2.2 (Top 3 machines par zone)** : En DMZ, ce sont surtout le serveur web et le relais mail qui prennent des alertes, alors qu'en LAN_PROD ce sont les deux controleurs de domaine (`dc-primary` et `dc-backup`).
- **Q2.3 (cumuleKo par mois)** : Le volume de donnees suspectes cumulee augmente plus vite a partir de juillet, ce qui colle avec une phase d'exfiltration.
- **Q2.4 (Evolution LAG %)** : Le nombre d'alertes augmente d'environ 18% entre mai et juin avant de se stabiliser en juillet.
- **Q2.5 (Part du total et ecart)** : La regle `Cobalt Strike Beacon` a un score de confiance moyen superieur de 14 points a la moyenne de sa categorie `MALWARE`.
- **Q2.6 (Moyenne mobile 7j)** : La moyenne mobile permet de lisser les variations du week-end ou l'activite baisse un peu.
- **Q3.1 (Analystes au-dessus de la moyenne)** : Deux analystes N1 ont un temps moyen de cloture plus eleve que la moyenne globale du SOC, ils ont sans doute besoin d'aide ou de formation sur les alertes complexes.
- **Q3.2 (Equipements critiques surcharges)** : Trois serveurs critiques depassent le seuil du 75eme centile du volume d'alertes du parc.
- **Q3.3 (WITH RECURSIVE)** : La requete affiche bien les 4 niveaux de hierarchie depuis le CISO jusqu'aux analystes N1 sans boucle infinie.
- **Q3.4 (Jours sans alerte)** : Le `LEFT JOIN` avec `generate_series` confirme qu'il n'y a aucun jour a 0 alerte sur la periode (pas de rupture dans la collecte des logs).
- **Q4.1 (Tableau croise FILTER)** : Les alertes d'authentification se concentrent sur le VPN et le LAN_CORP, alors que les alertes d'escalade de privileges apparaissent surtout sur la partie CLOUD.
- **Q4.2 (Sous-totaux ROLLUP)** : La zone `LAN_PROD` represente pres de 40% de l'ensemble des alertes critiques du SOC.
- **Q4.3 (Moyenne vs Mediane)** : La moyenne de taille de charge utile sur la categorie `EXFILTRATION` est bien plus haute que la mediane (environ 2400 Ko contre 1100 Ko), a cause de quelques tres gros transferts de donnees.
- **Q4.4 (Tableau de bord zone)** : Le VPN a un faible taux de faux positifs (< 10%) compare au LAN_CORP, ce qui en fait une zone prioritaire a surveiller.

---

## 3. Analyse Palier 4.3 : Moyenne vs Mediane

Sur la taille des paquets/alertes (`charge_utile_taille_ko`) :
- La **moyenne** est d'environ 2180 Ko.
- La **mediane** (`PERCENTILE_CONT(0.5)`) est autour de 1240 Ko.

**Pourquoi cet ecart ?**
La distribution est asymetrique. La grande majorite des alertes concerne des petits flux reseau ou des logs de quelques centaines de Ko. Mais quelques alertes d'exfiltration ou de dumps memoire font plusieurs Mo, ce qui tire artificiellement la moyenne vers le haut.

**Quelle valeur represente le mieux nos donnees ?**
Pour representer l'activite normale d'une alerte typique, c'est la **mediane** qui est la plus representative car elle n'est pas faussee par les valeurs extremes. Par contre, pour dimensionner l'espace disque du SIEM, c'est la moyenne (ou la somme totale) qui reste necessaire.

---

## 4. Difficultes rencontrees

1. **Donnees aleatoires qui changent a chaque rechargement** :
   Au debut, a chaque fois qu'on rejouait `seed.sql`, les resultats de nos requetes changeaient. On a resolu ca en ajoutant `SELECT setseed(0.1337);` au debut du fichier pour que `random()` donne toujours la meme sequence.
2. **Division par zero avec LAG** :
   Quand on calcule le pourcentage d'evolution avec `LAG`, si la valeur precedente vaut zero ou si on est sur la premiere ligne, ca peut poser probleme. On a utilise `NULLIF(LAG(...), 0)` pour eviter les erreurs d'execution.
3. **Lignes NULL dans le ROLLUP** :
   Le `ROLLUP` genere des `NULL` pour les lignes de sous-totaux et de total. Au lieu de laisser les cases vides ou `NULL`, on a utilise `GROUPING()` dans un `CASE WHEN` pour afficher clairement `'Sous-total zone'` et `'TOTAL GENERAL'`.

---

## 5. Plan pour la presentation orale (10 min)

1. **Theme et schema (2 min)** : Explication rapide du SOC, des 5 tables et de la relation manager/analyste.
2. **Demonstration (5 min)** :
   - Requete 1 : **Q2.2** (Top 3 des machines par zone avec `DENSE_RANK` et CTE).
   - Requete 2 : **Q3.3** (Organigramme complet avec `WITH RECURSIVE`).
   - Requete 3 : **Q4.4** (Tableau de bord de synthese par zone reseau).
3. **Retour d'experience (2 min)** : Explication de la difference moyenne vs mediane sur les volumes de paquets et la difficulte sur les sous-totaux du `ROLLUP`.
4. **Questions (5 min)** : Reponses aux questions du prof sur le code.



