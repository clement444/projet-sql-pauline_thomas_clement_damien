# TP2 SQL Avance - Projet analytique SOC

Projet de SQL avance realise dans le cadre du module PostgreSQL.

## Theme choisi

Nous avons choisi le theme d'un **SOC (Security Operations Center)** d'entreprise.
Le systeme supervise des machines connectees au reseau et collecte les alertes de securite remontees par un SIEM. Lorsqu'une alerte est critique, un incident est ouvert et assigne a un membre de l'equipe d'analystes.

Ce theme permet d'avoir :
- Une **table d'evenements temporels** (`alertes`) avec dates, volumes de donnees et criticite.
- Une **table hierarchique** (`analystes`) avec les managers et les differents niveaux (N1, N2, N3, LEAD, CISO).
- Des relations directes avec les regles de detection et le parc des equipements surveilles.

---

## Schema de la base

```
 analystes (hierarchique)
   |-- analyste_id (PK)
   |-- nom, prenom, email (UNIQUE)
   |-- niveau (CHECK N1..CISO)
   |-- manager_id (FK -> analystes.analyste_id)
   \-- date_embauche
         |
         | 1:N
         v
 incidents
   |-- incident_id (PK)
   |-- alerte_id (FK -> alertes.alerte_id, UNIQUE)
   |-- analyste_id (FK -> analystes.analyste_id)
   |-- date_assignation, date_cloture
   |-- temps_resolution_min
   \-- escalade_necessaire
         ^
         | 1:1
 alertes (table d'evenements)
   |-- alerte_id (PK)
   |-- horodatage (TIMESTAMPTZ)
   |-- equipement_id (FK -> equipements.equipement_id)
   |-- regle_id (FK -> regles_detection.regle_id)
   |-- severite (CHECK INFO..CRITICAL)
   |-- score_confiance
   |-- charge_utile_taille_ko
   \-- statut (CHECK NOUVELLE..FAUX_POSITIF)
         |                     |
     N:1 |                 N:1 |
         v                     v
 equipements            regles_detection
   |-- equipement_id      |-- regle_id
   |-- nom_hote (UNIQUE)  |-- code_regle (UNIQUE)
   |-- adresse_ip (INET)  |-- nom_regle
   |-- zone_reseau        |-- categorie
   |-- criticite          \-- severite_defaut
   \-- est_actif
```

---

## Comment charger la base

Dans un terminal avec PostgreSQL / `psql` :

```bash
# 1. Creer la base si besoin
createdb soc_analytics

# 2. Creer les tables
psql -d soc_analytics -f schema.sql

# 3. Inserer les donnees
psql -d soc_analytics -f seed.sql

# 4. Executer les requetes analytiques
psql -d soc_analytics -f requetes.sql
```

Verification rapide du volume d'evenements :
```sql
SELECT COUNT(*), MIN(horodatage), MAX(horodatage) FROM alertes;
```
Le seed genere 240 alertes entre debut mai et fin aout 2026 (soit 4 mois complets).

---

## Organisation des fichiers

- `schema.sql` : creation des 5 tables, contraintes PK, FK, CHECK et UNIQUE.
- `seed.sql` : insertions reproductibles avec `setseed()` et `generate_series`.
- `requetes.sql` : requetes des paliers 2 a 5 commentees avec la question metier.
- `JOURNAL.md` : journal de bord (explications, moyenne vs mediane, problemes rencontres).
