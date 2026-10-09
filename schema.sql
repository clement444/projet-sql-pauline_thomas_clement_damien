-- Schema initial
CREATE TABLE analystes (
    analyste_id SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    niveau VARCHAR(10) NOT NULL,
    manager_id INT REFERENCES analystes(analyste_id),
    date_embauche DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE equipements (
    equipement_id SERIAL PRIMARY KEY,
    nom_hote VARCHAR(100) NOT NULL UNIQUE,
    adresse_ip VARCHAR(50) NOT NULL,
    zone_reseau VARCHAR(20) NOT NULL,
    criticite VARCHAR(10) NOT NULL,
    est_actif BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE regles_detection (
    regle_id SERIAL PRIMARY KEY,
    code_regle VARCHAR(20) NOT NULL UNIQUE,
    nom_regle VARCHAR(150) NOT NULL,
    categorie VARCHAR(50) NOT NULL,
    severite_defaut VARCHAR(10) NOT NULL
);

CREATE TABLE alertes (
    alerte_id SERIAL PRIMARY KEY,
    horodatage TIMESTAMP WITH TIME ZONE NOT NULL,
    equipement_id INT NOT NULL REFERENCES equipements(equipement_id),
    regle_id INT NOT NULL REFERENCES regles_detection(regle_id),
    severite VARCHAR(10) NOT NULL,
    score_confiance NUMERIC(4,1) NOT NULL,
    charge_utile_taille_ko INT NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'NOUVELLE'
);
