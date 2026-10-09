-- Schema initial
CREATE TABLE equipements (
    equipement_id SERIAL PRIMARY KEY,
    nom_hote VARCHAR(100) NOT NULL UNIQUE,
    adresse_ip VARCHAR(50) NOT NULL,
    zone_reseau VARCHAR(20) NOT NULL,
    criticite VARCHAR(10) NOT NULL
);

CREATE TABLE regles_detection (
    regle_id SERIAL PRIMARY KEY,
    code_regle VARCHAR(20) NOT NULL UNIQUE,
    nom_regle VARCHAR(150) NOT NULL,
    categorie VARCHAR(50) NOT NULL,
    severite_defaut VARCHAR(10) NOT NULL
);
