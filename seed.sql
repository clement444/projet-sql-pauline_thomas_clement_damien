-- TP2 SQL Avance - Donneees de test
-- On fixe la graine pour avoir toujours les memes resultats a la presentation
SELECT setseed(0.1337);

-- 1. Analystes (16 personnes avec la hierarchie CISO -> Lead -> N3 -> N2 -> N1)
INSERT INTO analystes (analyste_id, nom, prenom, email, niveau, manager_id, date_embauche) VALUES
(1,  'Valadier',  'Marc',     'marc.valadier@cybercorp.intra',     'CISO', NULL, '2022-01-15'),
(2,  'Guillaume', 'Claire',   'claire.guillaume@cybercorp.intra', 'LEAD', 1,    '2022-06-01'),
(3,  'Benali',    'Karim',    'karim.benali@cybercorp.intra',     'LEAD', 1,    '2022-09-15'),
(4,  'Lemoine',   'Sarah',    'sarah.lemoine@cybercorp.intra',    'N3',   2,    '2023-02-01'),
(5,  'Dubois',    'Alexandre','alexandre.dubois@cybercorp.intra', 'N3',   2,    '2023-04-10'),
(6,  'Roussel',   'Camille',  'camille.roussel@cybercorp.intra',  'N3',   3,    '2023-05-18'),
(7,  'Garnier',   'Thomas',   'thomas.garnier@cybercorp.intra',   'N2',   4,    '2023-09-01'),
(8,  'Vidal',     'Lucas',    'lucas.vidal@cybercorp.intra',      'N2',   4,    '2023-11-15'),
(9,  'Fontaine',  'Julie',    'julie.fontaine@cybercorp.intra',   'N2',   5,    '2024-01-10'),
(10, 'Chevalier', 'Maxime',   'maxime.chevalier@cybercorp.intra', 'N2',   5,    '2024-02-20'),
(11, 'Perrin',    'Elena',    'elena.perrin@cybercorp.intra',     'N2',   6,    '2024-03-01'),
(12, 'Moreau',    'Nicolas',  'nicolas.moreau@cybercorp.intra',   'N1',   7,    '2024-06-15'),
(13, 'Girard',    'Ines',     'ines.girard@cybercorp.intra',      'N1',   8,    '2024-07-01'),
(14, 'Mercier',   'Hugo',     'hugo.mercier@cybercorp.intra',     'N1',   9,    '2024-08-01'),
(15, 'Blanc',     'Lea',      'lea.blanc@cybercorp.intra',        'N1',   10,   '2024-09-01'),
(16, 'Faure',     'Romain',   'romain.faure@cybercorp.intra',     'N1',   11,   '2024-10-01');

SELECT setval('analystes_analyste_id_seq', (SELECT MAX(analyste_id) FROM analystes));

-- 2. Equipements surveilles
INSERT INTO equipements (equipement_id, nom_hote, adresse_ip, zone_reseau, criticite, est_actif) VALUES
(1,  'fw-edge-01.dmz',        '192.168.10.1',  'DMZ',      'CRITIQUE', TRUE),
(2,  'srv-web-public.dmz',    '192.168.10.20', 'DMZ',      'HAUTE',    TRUE),
(3,  'srv-mail-relay.dmz',    '192.168.10.25', 'DMZ',      'HAUTE',    TRUE),
(4,  'dc-primary.prod',       '10.0.1.10',     'LAN_PROD', 'CRITIQUE', TRUE),
(5,  'dc-backup.prod',        '10.0.1.11',     'LAN_PROD', 'CRITIQUE', TRUE),
(6,  'srv-db-core01.prod',    '10.0.2.15',     'LAN_PROD', 'CRITIQUE', TRUE),
(7,  'srv-db-core02.prod',    '10.0.2.16',     'LAN_PROD', 'CRITIQUE', TRUE),
(8,  'srv-app-billing.prod',  '10.0.3.30',     'LAN_PROD', 'HAUTE',    TRUE),
(9,  'srv-erp-prod.prod',     '10.0.3.40',     'LAN_PROD', 'CRITIQUE', TRUE),
(10, 'srv-files-corp.lan',    '10.10.5.2',     'LAN_CORP', 'MOYENNE',  TRUE),
(11, 'ws-admin-01.lan',       '10.10.100.12',  'LAN_CORP', 'HAUTE',    TRUE),
(12, 'ws-dev-42.lan',         '10.10.102.42',  'LAN_CORP', 'BASSE',    TRUE),
(13, 'ws-compta-04.lan',      '10.10.105.14',  'LAN_CORP', 'MOYENNE',  TRUE),
(14, 'k8s-ingress.cloud',     '172.16.0.5',    'CLOUD',    'HAUTE',    TRUE),
(15, 'k8s-worker-pool1.cloud','172.16.1.101',  'CLOUD',    'MOYENNE',  TRUE),
(16, 'aws-s3-proxy.cloud',    '172.16.2.20',   'CLOUD',    'HAUTE',    TRUE),
(17, 'vpn-gw-paris.vpn',      '192.168.200.1', 'VPN',      'CRITIQUE', TRUE),
(18, 'vpn-gw-lyon.vpn',       '192.168.200.2', 'VPN',      'HAUTE',    TRUE);

SELECT setval('equipements_equipement_id_seq', (SELECT MAX(equipement_id) FROM equipements));

-- 3. Regles de detection SIEM
INSERT INTO regles_detection (regle_id, code_regle, nom_regle, categorie, severite_defaut) VALUES
(1,  'SEC-AUTH-001', 'Multiple Kerberos Pre-Auth Failures',   'AUTHENTICATION', 'HIGH'),
(2,  'SEC-AUTH-002', 'Admin Login Outside Working Hours',     'AUTHENTICATION', 'MEDIUM'),
(3,  'SEC-AUTH-003', 'Concurrent Session from Distinct IPs',  'AUTHENTICATION', 'HIGH'),
(4,  'SEC-BRUTE-01', 'SSH Automated Password Spraying',       'BRUTE_FORCE',    'HIGH'),
(5,  'SEC-BRUTE-02', 'RDP Repeated Failed Attempts',          'BRUTE_FORCE',    'CRITICAL'),
(6,  'SEC-MALW-001', 'Cobalt Strike Beacon HTTP Pattern',     'MALWARE',        'CRITICAL'),
(7,  'SEC-MALW-002', 'Suspicious PowerShell Encoded Payload', 'MALWARE',        'HIGH'),
(8,  'SEC-MALW-003', 'Ransomware Canary File Modification',    'MALWARE',        'CRITICAL'),
(9,  'SEC-EXFIL-01', 'Unusual Volume DNS Tunneling Query',    'EXFILTRATION',   'CRITICAL'),
(10, 'SEC-EXFIL-02', 'Massive Outbound S3 Data Transfer',     'EXFILTRATION',   'HIGH'),
(11, 'SEC-EXFIL-03', 'Encrypted Archive Creation on Staging', 'EXFILTRATION',   'MEDIUM'),
(12, 'SEC-PRIV-001', 'SeDebugPrivilege Assigned to Non-Admin', 'PRIV_ESC',       'CRITICAL'),
(13, 'SEC-PRIV-002', 'Sudoers File Direct Modification',      'PRIV_ESC',       'HIGH'),
(14, 'SEC-LAT-001',  'PsExec Remote Service Invocation',       'LATERAL_MOVE',   'HIGH'),
(15, 'SEC-LAT-002',  'WMI Process Creation on DC Subnet',      'LATERAL_MOVE',   'CRITICAL');

SELECT setval('regles_detection_regle_id_seq', (SELECT MAX(regle_id) FROM regles_detection));

-- 4. 240 alertes generees sur 4 mois (mai a aout 2026)
INSERT INTO alertes (alerte_id, horodatage, equipement_id, regle_id, severite, score_confiance, charge_utile_taille_ko, statut)
SELECT
    g AS alerte_id,
    TIMESTAMP WITH TIME ZONE '2026-05-01 00:00:00+02' 
      + ((g * 122.0 / 240.0) * INTERVAL '1 day')
      + ((floor(random() * 86400)) * INTERVAL '1 second') AS horodatage,
    1 + floor(random() * 18)::int AS equipement_id,
    1 + floor(random() * 15)::int AS regle_id,
    (ARRAY['INFO', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'])[
        CASE 
            WHEN random() < 0.15 THEN 1
            WHEN random() < 0.35 THEN 2
            WHEN random() < 0.65 THEN 3
            WHEN random() < 0.88 THEN 4
            ELSE 5
        END
    ] AS severite,
    ROUND((40.0 + random() * 59.9)::numeric, 1) AS score_confiance,
    10 + floor(random() * 4500)::int AS charge_utile_taille_ko,
    (ARRAY['NOUVELLE', 'EN_COURS', 'RESOLUE', 'FAUX_POSITIF'])[
        CASE 
            WHEN random() < 0.20 THEN 1
            WHEN random() < 0.40 THEN 2
            WHEN random() < 0.85 THEN 3
            ELSE 4
        END
    ] AS statut
FROM generate_series(1, 240) AS g;

SELECT setval('alertes_alerte_id_seq', (SELECT MAX(alerte_id) FROM alertes));

-- 5. Incidents associes aux alertes HIGH et CRITICAL
INSERT INTO incidents (alerte_id, analyste_id, date_assignation, date_cloture, temps_resolution_min, escalade_necessaire)
SELECT
    a.alerte_id,
    4 + floor(random() * 13)::int AS analyste_id, -- assignation aux analystes du N1 au N3
    a.horodatage + (INTERVAL '5 minutes' * (1 + floor(random() * 12)::int)) AS date_assignation,
    CASE 
        WHEN a.statut IN ('RESOLUE', 'FAUX_POSITIF') 
        THEN a.horodatage + (INTERVAL '15 minutes' * (2 + floor(random() * 30)::int))
        ELSE NULL
    END AS date_cloture,
    CASE 
        WHEN a.statut IN ('RESOLUE', 'FAUX_POSITIF') 
        THEN 20 + floor(random() * 420)::int
        ELSE NULL
    END AS temps_resolution_min,
    (random() > 0.75) AS escalade_necessaire
FROM alertes a
WHERE a.severite IN ('HIGH', 'CRITICAL')
ORDER BY a.alerte_id
LIMIT 65;



