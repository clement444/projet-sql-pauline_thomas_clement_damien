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
