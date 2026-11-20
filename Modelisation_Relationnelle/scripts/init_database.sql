-- =============================================================
-- Script d'initialisation de la base MegaShop-B2B
-- SGBD    : PostgreSQL 15+
-- Auteur  : Axel Masseron
-- Rôle    : crée le schéma relationnel issu du MCD (docs/mcd.md)
-- Idempotent : peut être relancé autant de fois que nécessaire.
-- =============================================================

BEGIN;

-- -------------------------------------------------------------
-- 1. Nettoyage (ordre inverse des dépendances)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS ligne_commande CASCADE;
DROP TABLE IF EXISTS commande CASCADE;
DROP TABLE IF EXISTS produit CASCADE;
DROP TABLE IF EXISTS client CASCADE;

-- -------------------------------------------------------------
-- 2. Tables sans clé étrangère
-- -------------------------------------------------------------

-- CLIENT : identifiant créé (absent du CSV legacy)
CREATE TABLE client (
    id_client  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nom        VARCHAR(150)  NOT NULL,
    contact    VARCHAR(255)  NOT NULL UNIQUE,  -- email : un contact = un client
    adresse    VARCHAR(255)  NOT NULL
);

-- PRODUIT : existe indépendamment des commandes (cardinalité 0,n)
CREATE TABLE produit (
    code_prod          VARCHAR(20)    PRIMARY KEY,
    designation        VARCHAR(150)   NOT NULL,
    prix_catalogue_ht  DECIMAL(10,2)  NOT NULL CHECK (prix_catalogue_ht >= 0)
);

-- -------------------------------------------------------------
-- 3. Tables avec clés étrangères
-- -------------------------------------------------------------

-- COMMANDE : passée par un et un seul client (cardinalité 1,1)
CREATE TABLE commande (
    id_cmd      VARCHAR(20)  PRIMARY KEY,
    date_achat  DATE         NOT NULL DEFAULT CURRENT_DATE,
    statut      VARCHAR(20)  NOT NULL DEFAULT 'EN_COURS'
                CHECK (statut IN ('EN_COURS', 'LIVREE')),
    id_client   UUID         NOT NULL,
    CONSTRAINT fk_commande_client
        FOREIGN KEY (id_client) REFERENCES client (id_client)
        ON DELETE RESTRICT  -- on ne supprime pas un client qui a des commandes
);

-- LIGNE_COMMANDE : table de liaison issue de l'association porteuse "Contient"
CREATE TABLE ligne_commande (
    id_cmd            VARCHAR(20)    NOT NULL,
    code_prod         VARCHAR(20)    NOT NULL,
    quantite          INTEGER        NOT NULL CHECK (quantite > 0),
    prix_unitaire_ht  DECIMAL(10,2)  NOT NULL CHECK (prix_unitaire_ht >= 0), -- prix figé à la commande
    CONSTRAINT pk_ligne_commande PRIMARY KEY (id_cmd, code_prod),
    CONSTRAINT fk_ligne_commande
        FOREIGN KEY (id_cmd) REFERENCES commande (id_cmd)
        ON DELETE CASCADE,  -- supprimer une commande supprime ses lignes
    CONSTRAINT fk_ligne_produit
        FOREIGN KEY (code_prod) REFERENCES produit (code_prod)
        ON DELETE RESTRICT  -- on ne supprime pas un produit déjà commandé
);

-- -------------------------------------------------------------
-- 4. Index sur les clés étrangères (performances des jointures)
-- -------------------------------------------------------------
CREATE INDEX idx_commande_client       ON commande (id_client);
CREATE INDEX idx_ligne_commande_produit ON ligne_commande (code_prod);

-- Note : total_ligne n'est pas stocké (donnée calculée).
-- Il s'obtient par : quantite * prix_unitaire_ht

COMMIT;