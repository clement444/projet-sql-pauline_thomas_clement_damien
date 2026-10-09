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
