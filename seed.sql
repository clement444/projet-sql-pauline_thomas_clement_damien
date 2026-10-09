-- Seed data initial
SELECT setseed(0.1337);

INSERT INTO analystes (analyste_id, nom, prenom, email, niveau, manager_id, date_embauche) VALUES
(1, 'Valadier', 'Marc', 'marc.valadier@cybercorp.intra', 'CISO', NULL, '2022-01-15'),
(2, 'Guillaume', 'Claire', 'claire.guillaume@cybercorp.intra', 'LEAD', 1, '2022-06-01'),
(3, 'Benali',    'Karim',    'karim.benali@cybercorp.intra',     'LEAD', 1,    '2022-09-15');
