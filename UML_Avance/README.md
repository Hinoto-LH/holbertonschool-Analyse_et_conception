# UML Avancé – Module de Paiement Asynchrone (MegaShop-B2B)

Modélisation **« As-Code »** (Mermaid.js) du comportement et de l'architecture du nouveau module de paiement par carte bancaire de MegaShop-B2B, **avant** l'écriture du code applicatif.

## Contexte

MegaShop-B2B, grossiste en matériel de bureau, intègre un paiement par carte bancaire. L'API de la banque partenaire est lente (jusqu'à **15 secondes** par appel). Bloquer l'application web pendant ce temps dégraderait l'expérience utilisateur et saturerait les serveurs.

La solution retenue est un **flux asynchrone** : l'API accepte la demande immédiatement (HTTP 202), délègue le paiement à un **Worker** via un **Message Broker** (RabbitMQ), et la commande suit un cycle de vie contrôlé.

Spécifications complètes : [`specs/cahier_des_charges_paiement.md`](specs/cahier_des_charges_paiement.md)

## Arborescence

```text
UML_Avance/
├── README.md
├── specs/
│   └── cahier_des_charges_paiement.md   # Règles métier du flux de paiement
└── architecture/
    ├── 01_class_diagram.md              # Structure statique : Repository & inversion des dépendances
    ├── 02_sequence_diagram.md           # Chorégraphie asynchrone : API, Broker, Worker, Banque
    └── 03_state_machine.md              # Cycle de vie d'une commande (FSM)
```

## Objectifs d'apprentissage

| # | Objectif | Où il est traité |
|---|---|---|
| 1 | Maîtriser la syntaxe **Mermaid.js** pour générer de l'UML « As-Code » | Tous les diagrammes (`classDiagram`, `sequenceDiagram`, `stateDiagram-v2`) |
| 2 | Différencier sémantiquement l'**Agrégation** de la **Composition** (OOP) | `01_class_diagram.md` |
| 3 | Appliquer l'**Inversion des Dépendances** (le « D » de SOLID) via le **Pattern Repository** | `01_class_diagram.md` |
| 4 | Modéliser une **chorégraphie asynchrone** impliquant une API, un Message Broker et un Worker | `02_sequence_diagram.md` |
| 5 | Concevoir une **Machine à États Finis** (FSM) pour sécuriser le cycle de vie d'une entité métier | `03_state_machine.md` |

## Notions clés

### Agrégation vs Composition
- **Agrégation** (`o--`, losange vide) : relation « utilise ». La partie existe **indépendamment** du tout. Exemple : `OrderService` reçoit un `IOrderRepository` injecté de l'extérieur.
- **Composition** (`*--`, losange plein) : relation « possède ». La partie **naît et meurt** avec le tout. Exemple : une ligne de commande n'existe pas sans sa commande.

### Inversion des Dépendances & Pattern Repository
- Le **métier** (`OrderService`) dépend d'une **abstraction** (`IOrderRepository`), jamais d'une technologie.
- L'**infrastructure** (`PostgresOrderRepository`) réalise cette abstraction.
- Le repository est fourni par **injection de dépendances** (constructeur).
- Bénéfices : code métier **testable sans base de données** et **indépendant** du moteur de persistance.

### Flux asynchrone
- L'API ne fait **pas** attendre l'utilisateur : elle enregistre l'intention (`PENDING_PAYMENT`), publie un `ProcessPaymentEvent` et répond **HTTP 202 Accepted**.
- Le `PaymentWorker` consomme le message en arrière-plan et appelle la banque.
- Les fragments UML `alt` / `opt` / `loop` modélisent les alternatives (succès / échec) et les répétitions.

### Machine à États Finis (FSM)
Le statut d'une commande ne peut changer que par des **transitions autorisées** :

| Depuis | Vers | Déclencheur |
|---|---|---|
| `PENDING_PAYMENT` | `PAID` | La banque valide le paiement |
| `PENDING_PAYMENT` | `FAILED` | La banque refuse le paiement |
| `FAILED` | `PENDING_PAYMENT` | Nouvelle tentative de paiement |
| `PAID` | `SHIPPED` | Expédition de la commande |

Toute autre transition (ex. `FAILED → PAID`, `SHIPPED → PENDING_PAYMENT`) est **interdite**.

## Prérequis

- **Éditeur** : Visual Studio Code ou IntelliJ IDEA
- **Extension VS Code** : « Markdown Preview Mermaid Support » ou « Mermaid Preview »
- **Documentation** : [mermaid.js.org](https://mermaid.js.org/)

## Visualiser les diagrammes

1. Ouvrir un fichier du dossier `architecture/` dans VS Code.
2. Lancer l'aperçu Markdown : `Cmd+Shift+V` (macOS) ou `Ctrl+Shift+V` (Windows/Linux).

GitHub affiche aussi les blocs Mermaid directement dans les fichiers `.md`.

## Auteur

Hinoto – Holberton School