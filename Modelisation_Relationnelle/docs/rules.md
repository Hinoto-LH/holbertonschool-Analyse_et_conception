# Audit du Legacy et Règles de Gestion – MegaShop-B2B

## 1. Sujets identifiés (futures entités)

| Entité | Colonnes du CSV | Identifiant |
|---|---|---|
| **Client** | client_nom, client_contact, adr_livraison | aucun dans le CSV → création d'un `id_client` |
| **Commande** | id_cmd, date_achat, statut_cmd | `id_cmd` |
| **Produit** | code_prod, designation, prix_unitaire_ht | `code_prod` |

La colonne `qte` ne décrit ni une commande seule, ni un produit seul : elle décrit **un produit dans une commande**. Elle appartient donc au lien entre Commande et Produit.

## 2. Règles de gestion

### Client ↔ Commande
- **RG1** : Un client peut passer zéro, une ou plusieurs commandes.
- **RG2** : Une commande est passée par un et un seul client.

### Commande ↔ Produit
- **RG3** : Une commande contient au moins un produit et peut en contenir plusieurs.
- **RG4** : Un produit peut figurer dans zéro, une ou plusieurs commandes.
- **RG5** : Pour chaque produit d'une commande, on enregistre une quantité commandée.
- **RG6** : Le prix unitaire est figé au moment de la commande, afin qu'un changement de prix du catalogue ne modifie pas les commandes passées.

## 3. Cardinalités

| Règle | Question posée | Min | Max | Cardinalité |
|---|---|---|---|---|
| RG1 – Client → Commande | Un client peut-il exister sans commande ? Oui. Peut-il en passer plusieurs ? Oui. | 0 | n | **(0,n)** |
| RG2 – Commande → Client | Une commande peut-elle exister sans client ? Non. Peut-elle avoir plusieurs clients ? Non. | 1 | 1 | **(1,1)** |
| RG3 – Commande → Produit | Une commande peut-elle exister sans produit ? Non. Peut-elle en contenir plusieurs ? Oui. | 1 | n | **(1,n)** |
| RG4 – Produit → Commande | Un produit peut-il exister sans être commandé ? Oui. Peut-il être dans plusieurs commandes ? Oui. | 0 | n | **(0,n)** |

Types de relation :
- Client ↔ Commande : **1,n** (un à plusieurs)
- Commande ↔ Produit : **n,n** (plusieurs à plusieurs), porteuse de la quantité et du prix figé

## 4. Données calculées (non modélisées)

- `total_ligne` n'est **ni un sujet, ni une règle de gestion** : c'est le résultat d'un calcul (`qte × prix_unitaire_ht`). Le stocker créerait une redondance et un risque d'incohérence (ex. : quantité modifiée sans mise à jour du total). Il sera calculé à la demande.

## 5. Choix et hypothèses

- **Identifiant client** : le CSV n'en contient pas. Le nom n'est pas fiable (homonymes possibles, changement de raison sociale), on crée donc un `id_client`.
- **Adresse de livraison** : rattachée au client, conformément au contexte (« si Acme Corp change d'adresse, nous devons modifier de multiples lignes »).
- **Statut de commande** : valeurs observées `LIVREE` et `EN_COURS`.