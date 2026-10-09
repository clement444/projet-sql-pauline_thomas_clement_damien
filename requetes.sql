-- Q2.1 : Classement des regles selon le nombre d'alertes par niveau de severite
-- Question metier : Pour chaque severite, quelles sont les regles qui declenchent le plus souvent ?
SELECT
    severite,
    regle_id,
    total_alertes,
    RANK() OVER (PARTITION BY severite ORDER BY total_alertes DESC) AS rang,
    DENSE_RANK() OVER (PARTITION BY severite ORDER BY total_alertes DESC) AS rang_dense
FROM (
    SELECT
        severite,
        regle_id,
        COUNT(*) AS total_alertes
    FROM alertes
    GROUP BY severite, regle_id
) t
ORDER BY severite, rang;


-- Q2.2 : Top 3 des machines les plus ciblees dans chaque zone reseau
-- Question metier : Quels sont les 3 equipements les plus touches dans chaque segment reseau ?
WITH stats_equipements AS (
    SELECT
        e.zone_reseau,
        e.nom_hote,
        COUNT(a.alerte_id) AS nb_alertes,
        DENSE_RANK() OVER (
            PARTITION BY e.zone_reseau
            ORDER BY COUNT(a.alerte_id) DESC
        ) AS rang_zone
    FROM equipements e
    JOIN alertes a ON e.equipement_id = a.equipement_id
    GROUP BY e.zone_reseau, e.nom_hote
)
SELECT
    zone_reseau,
    nom_hote,
    nb_alertes,
    rang_zone
FROM stats_equipements
WHERE rang_zone <= 3
ORDER BY zone_reseau, rang_zone;


-- Q2.3 : Cumul du volume de donnees suspectes (Ko) mois par mois
-- Question metier : Comment evolue le cumul de donnees transferees au fil des mois ?
SELECT
    TO_CHAR(date_tronquee, 'YYYY-MM') AS mois,
    volume_mensuel_ko,
    SUM(volume_mensuel_ko) OVER (ORDER BY date_tronquee) AS cumul_volume_ko
FROM (
    SELECT
        DATE_TRUNC('month', horodatage) AS date_tronquee,
        SUM(charge_utile_taille_ko) AS volume_mensuel_ko
    FROM alertes
    GROUP BY DATE_TRUNC('month', horodatage)
) mensuel
ORDER BY date_tronquee;


-- Q2.4 : Evolution mensuelle du nombre d'alertes avec LAG en pourcentage
-- Question metier : Quel est le pourcentage de variation du volume d'alertes d'un mois a l'autre ?
WITH alertes_par_mois AS (
    SELECT
        DATE_TRUNC('month', horodatage) AS mois_date,
        COUNT(*) AS total_alertes
    FROM alertes
    GROUP BY DATE_TRUNC('month', horodatage)
)
SELECT
    TO_CHAR(mois_date, 'YYYY-MM') AS mois,
    total_alertes,
    LAG(total_alertes) OVER (ORDER BY mois_date) AS alertes_mois_precedent,
    ROUND(
        ( (total_alertes - LAG(total_alertes) OVER (ORDER BY mois_date))::numeric
          / NULLIF(LAG(total_alertes) OVER (ORDER BY mois_date), 0)::numeric ) * 100.0,
        2
    ) AS variation_pct
FROM alertes_par_mois
ORDER BY mois_date;


-- Q2.5 : Poids de chaque regle sur le total et ecart a la moyenne de sa categorie
-- Question metier : Quelle part du total represente chaque regle et son score moyen est-il au-dessus de sa categorie ?
SELECT
    r.categorie,
    r.nom_regle,
    COUNT(a.alerte_id) AS nb_alertes,
    ROUND(
        (COUNT(a.alerte_id)::numeric / SUM(COUNT(a.alerte_id)) OVER ()) * 100.0,
        2
    ) AS part_total_global_pct,
    ROUND(AVG(a.score_confiance), 2) AS confiance_moyenne_regle,
    ROUND(
        AVG(a.score_confiance) - AVG(AVG(a.score_confiance)) OVER (PARTITION BY r.categorie),
        2
    ) AS ecart_moyenne_categorie
FROM regles_detection r
JOIN alertes a ON r.regle_id = a.regle_id
GROUP BY r.categorie, r.nom_regle
ORDER BY r.categorie, nb_alertes DESC;


-- Q2.6 : Moyenne mobile du nombre d'alertes sur 7 jours et decoupage en quartiles
-- Question metier : Quelle est la tendance lissee sur une semaine et comment se repartissent les journees de forte charge ?
WITH alertes_journalieres AS (
    SELECT
        DATE_TRUNC('day', horodatage)::date AS jour,
        COUNT(*) AS total_alertes
    FROM alertes
    GROUP BY DATE_TRUNC('day', horodatage)::date
)
SELECT
    jour,
    total_alertes,
    ROUND(
        AVG(total_alertes) OVER (
            ORDER BY jour
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moyenne_mobile_7j,
    NTILE(4) OVER (ORDER BY total_alertes DESC) AS quartile_charge
FROM alertes_journalieres
ORDER BY jour;

-- Q3.1 : Analystes dont le temps moyen de resolution est superieur a la moyenne globale (2 CTE enchainees)
-- Question metier : Quels analystes mettent plus de temps que la moyenne globale a resoudre leurs incidents ?
WITH stats_par_analyste AS (
    SELECT
        a.analyste_id,
        a.nom || ' ' || a.prenom AS analyste,
        a.niveau,
        COUNT(i.incident_id) AS incidents_resolus,
        AVG(i.temps_resolution_min) AS avg_resolution_min
    FROM analystes a
    JOIN incidents i ON a.analyste_id = i.analyste_id
    WHERE i.temps_resolution_min IS NOT NULL
    GROUP BY a.analyste_id, a.nom, a.prenom, a.niveau
),
seuil_global AS (
    SELECT
        AVG(avg_resolution_min) AS moyenne_generale_min
    FROM stats_par_analyste
)
SELECT
    s.analyste,
    s.niveau,
    s.incidents_resolus,
    ROUND(s.avg_resolution_min::numeric, 1) AS temps_moyen_min,
    ROUND(g.moyenne_generale_min::numeric, 1) AS seuil_global_min,
    ROUND((s.avg_resolution_min - g.moyenne_generale_min)::numeric, 1) AS ecart_min
FROM stats_par_analyste s
CROSS JOIN seuil_global g
WHERE s.avg_resolution_min > g.moyenne_generale_min
ORDER BY s.avg_resolution_min DESC;


-- Q3.2 : Machines critiques ayant recu plus d'alertes que le 75eme centile (2 CTE enchainees)
-- Question metier : Quelles machines sensibles (HAUTE/CRITIQUE) subissent une charge anormale par rapport au reste du parc ?
WITH charge_par_asset AS (
    SELECT
        e.equipement_id,
        e.nom_hote,
        e.zone_reseau,
        e.criticite,
        COUNT(a.alerte_id) AS total_alertes
    FROM equipements e
    JOIN alertes a ON e.equipement_id = a.equipement_id
    GROUP BY e.equipement_id, e.nom_hote, e.zone_reseau, e.criticite
),
seuil_p75 AS (
    SELECT
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_alertes) AS limite_p75
    FROM charge_par_asset
)
SELECT
    c.nom_hote,
    c.zone_reseau,
    c.criticite,
    c.total_alertes,
    ROUND(s.limite_p75::numeric, 1) AS seuil_p75
FROM charge_par_asset c
CROSS JOIN seuil_p75 s
WHERE c.total_alertes >= s.limite_p75 AND c.criticite IN ('HAUTE', 'CRITIQUE')
ORDER BY c.total_alertes DESC;


-- Q3.3 : Organigramme de l'equipe SOC avec niveau hierarchique et chemin complet
-- Question metier : Comment s'organise la hierarchie du SOC du CISO jusqu'aux analystes N1 ?
WITH RECURSIVE hierarchie_soc AS (
    -- Point de depart : le CISO (celui qui n'a pas de manager)
    SELECT
        analyste_id,
        nom,
        prenom,
        niveau,
        manager_id,
        1 AS niveau_arbre,
        CAST(nom || ' ' || prenom AS TEXT) AS chemin
    FROM analystes
    WHERE manager_id IS NULL

    UNION ALL

    -- On descend sur les personnes managees
    SELECT
        a.analyste_id,
        a.nom,
        a.prenom,
        a.niveau,
        a.manager_id,
        h.niveau_arbre + 1,
        h.chemin || ' -> ' || (a.nom || ' ' || a.prenom)
    FROM analystes a
    JOIN hierarchie_soc h ON a.manager_id = h.analyste_id
)
SELECT
    niveau_arbre,
    REPEAT('  ', niveau_arbre - 1) || nom || ' ' || prenom AS membre,
    niveau,
    chemin
FROM hierarchie_soc
ORDER BY chemin;


-- Q3.4 : Verification des jours sans alerte avec generate_series et LEFT JOIN
-- Question metier : Y a-t-il des jours sans aucune activite enregistree dans le SIEM (potentielle coupure de logs) ?
SELECT
    cal.jour::date AS date_jour,
    COALESCE(COUNT(a.alerte_id), 0) AS total_alertes,
    CASE
        WHEN COUNT(a.alerte_id) = 0 THEN 'Trou dans les logs'
        ELSE 'OK'
    END AS etat
FROM generate_series(
    DATE '2026-05-01',
    DATE '2026-08-31',
    INTERVAL '1 day'
) AS cal(jour)
LEFT JOIN alertes a ON DATE_TRUNC('day', a.horodatage) = cal.jour
GROUP BY cal.jour
ORDER BY cal.jour;

-- Q4.1 : Tableau croise des categories d'attaques par zone reseau avec FILTER
-- Question metier : Comment se repartissent les types de menaces selon les differentes zones reseau ?
SELECT
    r.categorie AS categorie_menace,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE e.zone_reseau = 'DMZ') AS dmz,
    COUNT(*) FILTER (WHERE e.zone_reseau = 'LAN_PROD') AS lan_prod,
    COUNT(*) FILTER (WHERE e.zone_reseau = 'LAN_CORP') AS lan_corp,
    COUNT(*) FILTER (WHERE e.zone_reseau = 'CLOUD') AS cloud,
    COUNT(*) FILTER (WHERE e.zone_reseau = 'VPN') AS vpn
FROM alertes a
JOIN equipements e ON a.equipement_id = e.equipement_id
JOIN regles_detection r ON a.regle_id = r.regle_id
GROUP BY r.categorie
ORDER BY total DESC;


-- Q4.2 : Rapport avec sous-totaux par zone et severite avec ROLLUP et GROUPING
-- Question metier : Quel est le nombre d'alertes par zone et severite avec les sous-totaux et total general ?
SELECT
    CASE
        WHEN GROUPING(e.zone_reseau) = 1 THEN 'TOTAL GENERAL'
        ELSE e.zone_reseau
    END AS zone_reseau,
    CASE
        WHEN GROUPING(a.severite) = 1 AND GROUPING(e.zone_reseau) = 0 THEN 'Sous-total zone'
        WHEN GROUPING(a.severite) = 1 AND GROUPING(e.zone_reseau) = 1 THEN 'Toutes severites'
        ELSE a.severite
    END AS severite,
    COUNT(*) AS nb_alertes,
    ROUND(AVG(a.score_confiance), 1) AS score_moyen,
    SUM(a.charge_utile_taille_ko) AS volume_total_ko
FROM alertes a
JOIN equipements e ON a.equipement_id = e.equipement_id
GROUP BY ROLLUP(e.zone_reseau, a.severite)
ORDER BY e.zone_reseau NULLS LAST, a.severite NULLS LAST;


-- Q4.3 : Comparaison moyenne vs mediane sur la taille des charges utiles (Ko)
-- Question metier : La moyenne de taille de paquets est-elle tiree vers le haut par des valeurs extremes ?
SELECT
    r.categorie,
    COUNT(*) AS nb_alertes,
    ROUND(AVG(a.charge_utile_taille_ko)::numeric, 2) AS taille_moyenne_ko,
    ROUND(
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.charge_utile_taille_ko))::numeric,
        2
    ) AS taille_mediane_ko,
    ROUND(
        AVG(a.charge_utile_taille_ko)::numeric -
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.charge_utile_taille_ko))::numeric,
        2
    ) AS ecart_moyenne_mediane
FROM alertes a
JOIN regles_detection r ON a.regle_id = r.regle_id
GROUP BY r.categorie
ORDER BY taille_moyenne_ko DESC;


-- Q4.4 : Tableau de bord de synthese par zone (CTE + fonctions de fenetre + filtres)
-- Question metier : Vue recapitulatif par zone avec proportion du trafic, part critique et faux positifs
WITH stats_zone AS (
    SELECT
        e.zone_reseau,
        COUNT(a.alerte_id) AS total_alertes,
        COUNT(a.alerte_id) FILTER (WHERE a.severite IN ('HIGH', 'CRITICAL')) AS alertes_critiques,
        ROUND(AVG(i.temps_resolution_min)::numeric, 1) AS temps_resol_moyen_min,
        ROUND(
            (COUNT(a.alerte_id) FILTER (WHERE a.statut = 'FAUX_POSITIF')::numeric /
             NULLIF(COUNT(a.alerte_id), 0)) * 100.0,
            1
        ) AS pct_faux_positifs
    FROM equipements e
    LEFT JOIN alertes a ON e.equipement_id = a.equipement_id
    LEFT JOIN incidents i ON a.alerte_id = i.alerte_id
    GROUP BY e.zone_reseau
)
SELECT
    zone_reseau,
    total_alertes,
    ROUND((total_alertes::numeric / SUM(total_alertes) OVER ()) * 100.0, 1) AS pct_du_total,
    alertes_critiques,
    COALESCE(temps_resol_moyen_min, 0) AS temps_resol_moyen_min,
    COALESCE(pct_faux_positifs, 0.0) AS pct_faux_positifs,
    DENSE_RANK() OVER (ORDER BY alertes_critiques DESC) AS priorite_zone
FROM stats_zone
ORDER BY priorite_zone;

-- Bonus 1 : Creation d'une vue de synthese par machine
CREATE OR REPLACE VIEW v_kpi_machines AS
SELECT
    e.equipement_id,
    e.nom_hote,
    e.zone_reseau,
    e.criticite,
    COUNT(a.alerte_id) AS total_alertes,
    COUNT(a.alerte_id) FILTER (WHERE a.severite = 'CRITICAL') AS alertes_critiques,
    ROUND(AVG(a.score_confiance), 1) AS confiance_moyenne,
    MAX(a.horodatage) AS derniere_alerte
FROM equipements e
LEFT JOIN alertes a ON e.equipement_id = a.equipement_id
GROUP BY e.equipement_id, e.nom_hote, e.zone_reseau, e.criticite;

-- Consultation de la vue pour les machines avec au moins une alerte critique
SELECT * FROM v_kpi_machines WHERE alertes_critiques > 0 ORDER BY alertes_critiques DESC;


-- Bonus 2 : Test EXPLAIN ANALYZE avant et apres index
-- Requete sans index dedie
EXPLAIN ANALYZE
SELECT horodatage, equipement_id, severite, score_confiance
FROM alertes
WHERE horodatage >= '2026-06-01' AND severite = 'CRITICAL';

-- Ajout d'un index composite
CREATE INDEX IF NOT EXISTS idx_alertes_severite_date
ON alertes (severite, horodatage DESC);

-- Meme requete avec l'index actif
EXPLAIN ANALYZE
SELECT horodatage, equipement_id, severite, score_confiance
FROM alertes
WHERE horodatage >= '2026-06-01' AND severite = 'CRITICAL';



