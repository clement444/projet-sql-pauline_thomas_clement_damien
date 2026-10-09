-- TP2 SQL Avance - Projet SOC Analytics
-- Schema de la base de donnees

DROP TABLE IF EXISTS incidents CASCADE;
DROP TABLE IF EXISTS alertes CASCADE;
DROP TABLE IF EXISTS regles_detection CASCADE;
DROP TABLE IF EXISTS equipements CASCADE;
DROP TABLE IF EXISTS analystes CASCADE;

-- Equipe du SOC (table hierarchique avec manager_id qui pointe sur analyste_id)
CREATE TABLE analystes (
    analyste_id SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    niveau VARCHAR(10) NOT NULL CHECK (niveau IN ('N1', 'N2', 'N3', 'LEAD', 'CISO')),
    manager_id INT REFERENCES analystes(analyste_id) ON DELETE SET NULL,
    date_embauche DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Parc des machines surveillees par le SOC
CREATE TABLE equipements (
    equipement_id SERIAL PRIMARY KEY,
    nom_hote VARCHAR(100) NOT NULL UNIQUE,
    adresse_ip INET NOT NULL UNIQUE,
    zone_reseau VARCHAR(20) NOT NULL CHECK (zone_reseau IN ('DMZ', 'LAN_PROD', 'LAN_CORP', 'CLOUD', 'VPN')),
    criticite VARCHAR(10) NOT NULL CHECK (criticite IN ('BASSE', 'MOYENNE', 'HAUTE', 'CRITIQUE')),
    est_actif BOOLEAN NOT NULL DEFAULT TRUE
);

-- Regles SIEM configurees pour lever des alertes
CREATE TABLE regles_detection (
    regle_id SERIAL PRIMARY KEY,
    code_regle VARCHAR(20) NOT NULL UNIQUE,
    nom_regle VARCHAR(150) NOT NULL,
    categorie VARCHAR(50) NOT NULL CHECK (categorie IN ('AUTHENTICATION', 'BRUTE_FORCE', 'MALWARE', 'EXFILTRATION', 'PRIV_ESC', 'LATERAL_MOVE')),
    severite_defaut VARCHAR(10) NOT NULL CHECK (severite_defaut IN ('INFO', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

-- Table d'evenements : alertes brutes recues par le SIEM
CREATE TABLE alertes (
    alerte_id SERIAL PRIMARY KEY,
    horodatage TIMESTAMP WITH TIME ZONE NOT NULL,
    equipement_id INT NOT NULL REFERENCES equipements(equipement_id) ON DELETE CASCADE,
    regle_id INT NOT NULL REFERENCES regles_detection(regle_id) ON DELETE CASCADE,
    severite VARCHAR(10) NOT NULL CHECK (severite IN ('INFO', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    score_confiance NUMERIC(4,1) NOT NULL CHECK (score_confiance >= 0.0 AND score_confiance <= 100.0),
    charge_utile_taille_ko INT NOT NULL CHECK (charge_utile_taille_ko >= 0),
    statut VARCHAR(20) NOT NULL DEFAULT 'NOUVELLE' CHECK (statut IN ('NOUVELLE', 'EN_COURS', 'RESOLUE', 'FAUX_POSITIF'))
);

-- Incidents ouverts suite a une alerte critique
CREATE TABLE incidents (
    incident_id SERIAL PRIMARY KEY,
    alerte_id INT NOT NULL UNIQUE REFERENCES alertes(alerte_id) ON DELETE CASCADE,
    analyste_id INT NOT NULL REFERENCES analystes(analyste_id) ON DELETE RESTRICT,
    date_assignation TIMESTAMP WITH TIME ZONE NOT NULL,
    date_cloture TIMESTAMP WITH TIME ZONE,
    temps_resolution_min INT CHECK (temps_resolution_min IS NULL OR temps_resolution_min >= 0),
    escalade_necessaire BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT check_cloture_coherence CHECK (date_cloture IS NULL OR date_cloture >= date_assignation)
);



