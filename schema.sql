DROP VIEW IF EXISTS bilan_mensuel;
DROP TABLE IF EXISTS reservations, cours, adherents, coachs, categories CASCADE;

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(60) NOT NULL UNIQUE,
    parent_id INT REFERENCES categories(id),
    CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE TABLE coachs (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(60) NOT NULL,
    specialite VARCHAR(60) NOT NULL
);

CREATE TABLE adherents (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(60) NOT NULL,
    abonnement VARCHAR(20) NOT NULL CHECK (abonnement IN ('basic', 'premium')),
    date_inscription DATE NOT NULL
);

CREATE TABLE cours (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(60) NOT NULL,
    categorie_id INT NOT NULL REFERENCES categories(id),
    coach_id INT NOT NULL REFERENCES coachs(id),
    prix NUMERIC(8,2) NOT NULL CHECK (prix >= 0)
);

CREATE TABLE reservations (
    id SERIAL PRIMARY KEY,
    adherent_id INT NOT NULL REFERENCES adherents(id),
    cours_id INT NOT NULL REFERENCES cours(id),
    date_reservation DATE NOT NULL,
    montant NUMERIC(8,2) NOT NULL CHECK (montant >= 0)
);
