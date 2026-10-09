-- Palier 2 : Fonctions de fenetre

-- Q2.1 : Classement des regles selon le nombre d'alertes par niveau de severite
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


-- ============================================================================
-- PALIER 3 : CTE et recursivite
-- ============================================================================

-- Q3.1 : Analystes dont le temps moyen de resolution est superieur a la moyenne globale (2 CTE enchainees)
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
WITH RECURSIVE hierarchie_soc AS (
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
