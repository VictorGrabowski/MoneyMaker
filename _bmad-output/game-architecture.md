---
title: 'MoneyMaker — Architecture de la refonte'
project: 'MoneyMaker'
engine: 'Godot 4.7.2'
author: 'Victor'
created: '2026-10-08'
updated: '2026-10-08'
status: 'en vigueur — GDD validé par Victor le 2026-10-08'
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - 'planning-artifacts/gdds/gdd-MoneyMaker-2026-10-08/gdd.md'
  - 'planning-artifacts/gdds/gdd-MoneyMaker-2026-10-08/epics.md'
  - 'prototype dans game/ (mesuré le 2026-10-08)'
supersedes: 'archive-v1-electron/game-architecture.md'
---

# Architecture

## Executive Summary

MoneyMaker est refait dans Godot 4.7 en GDScript typé : des scènes 2D en plans superposés, un bocal dont les pièces sont de vrais volumes 3D rendus dans une vignette (le « 2.5D »), et un cœur de règles sans aucun nœud Godot, testé hors écran. Toute la progression tient dans un fichier de sauvegarde local versionné ; le temps et l'argent sont calculés à partir de l'horloge système en entiers, donc exacts après une veille ou une fermeture.

Un prototype dans `game/` a validé le 8 octobre 2026 les trois paris techniques : le bocal 2.5D, la fenêtre widget transparente et le calcul du salaire au centime.

## Project Initialization

Pas de modèle de départ : le projet est créé à la main dans `game/`, à côté de l'app Electron qui reste en place jusqu'au jalon « Parité v1 ».

```powershell
# Tests du cœur (hors écran)
.\game\tools\godot.ps1 -Tests

# Lancer le prototype
& "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path game

# Ouvrir le projet dans l'éditeur
& "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path game --editor
```

`game/tools/godot.ps1` lit le chemin de Godot dans la variable d'environnement `GODOT`, sinon prend l'installation Steam ci-dessus.

### Ce que le prototype a établi

| Pari | Résultat mesuré | Reste à faire |
|---|---|---|
| Salaire exact | 13 jours complets à 2 000 € net = 1 200,00 € pile, sans reste | Fait à l'epic 0 : voir « État d'avancement » |
| Bocal 2.5D | 240 objets : 750 à 770 images/s sans synchronisation verticale, sur Ryzen 7 5700X3D + Radeon RX 6700 XT | Mesurer sur le portable de la destinataire : cette machine n'est pas représentative |
| Mise au repos des pièces | 90 objets : au repos en moins de 9 s, 3 essais sur 3. 240 objets : 2 essais sur 3 | Garde de mise au repos (voir « Bocal 2.5D ») |
| Widget | Fenêtre 320 × 96 sans bordure, au premier plan, fond transparent : les trois drapeaux sont actifs, le coin de l'image a une opacité de 0 | Vérifier à l'œil sur le bureau ; clic traversant hors de l'étiquette |
| Monnaie provisoire | 15 faces dessinées par un shader (encre + lavis), sans aucun fichier image | Remplacer par les illustrations |

Captures : `planning-artifacts/prototype/`.

### État d'avancement

| Epic | État au 2026-10-08 | Preuve |
|---|---|---|
| 0 — Fondations | Stories 0.2 à 0.8 écrites, en attente de relecture. Story 0.1 (retrait des installeurs) en attente d'une décision de Victor | 64 tests hors écran ; cinq lancements enchaînés sur une sauvegarde d'essai avec une horloge simulée (fermé lundi 12 h, rouvert mardi, jeudi, horloge reculée au mercredi, retour au jeudi) : montants exacts, aucun double paiement |
| 1 — Bocal et widget | Prototype seulement | Voir le tableau ci-dessus |

Non vérifié : le flux GitHub `game-tests.yml` n'a encore jamais tourné (rien n'est poussé).

## Decision Summary

| Category | Decision | Version | Affects Epics | Rationale |
|---|---|---|---|---|
| Moteur | Godot, éditeur Steam | 4.7.2 stable (vérifié par `--version` le 2026-10-08) | Tous | Déjà installé ; scènes, 2D et 3D mêlées, fenêtres transparentes, export Windows |
| Langage | GDScript à typage statique partout | Godot 4.7.2 | Tous | Itération la plus rapide, meilleur support des outils et des agents |
| Rendu | Compatibility (OpenGL 3.3) | Godot 4.7.2 | 1, 2, 5, 6 | Le plus léger pour un portable de bureau ; suffit au 2D et au bocal |
| Mise à l'échelle | Résolution de conception 1920 × 1080, étirement `canvas_items`, aspect `expand` | — | 2, 5, 6 | Net à toutes les tailles de fenêtre |
| Bocal | Monde 3D propre dans une vignette, tranche mince, caméra en perspective | — | 1 | Vraie profondeur et vraie parallaxe ; faces dessinées à plat, les plus simples à illustrer |
| Physique | Jolt, intégré au moteur | Godot 4.7.2 | 1 | Empilements stables de cylindres, mise en sommeil |
| Règles du jeu | Classes `RefCounted` sans nœud dans `core/`, dépendances passées au constructeur | — | 0, 3, 4, 6, 8 | Testable hors écran, indépendant de l'affichage |
| Argent | Centimes entiers ; reste de division reporté d'un jour sur l'autre | — | 0, 1, 5, 6 | Aucune dérive |
| Temps | Service `Clock` remplaçable ; échéances stockées en heure système | — | 0, 3, 7, 8 | Exact après veille ou fermeture |
| Contenu | Fichiers JSON dans `game/data/`, validés par des tests | — | 3, 6, 8, 10 | Lisibles, comparables, faciles à écrire à la main ou par un agent |
| Dialogues | Répliques conditionnelles en JSON, sélecteur maison ; aucune extension | — | 6, 10 | Honoré réagit surtout au contexte ; pas de dépendance à suivre |
| Sauvegarde | Un fichier JSON versionné dans `user://`, écriture atomique, 3 copies | — | 0 | Simple, réparable à la main, migrable |
| Fenêtre | Une seule fenêtre dont on change la taille et les drapeaux | — | 1 | Validé par le prototype ; pas de synchronisation entre fenêtres |
| Scènes | `.tscn` pour tout ce qui se règle à l'œil ; scripts pour le comportement | — | 2 à 7 | Victor peut déplacer un objet dans l'éditeur sans toucher au code |
| Audio | Bus de mixage du moteur, un par famille de sons | Godot 4.7.2 | 9 | Natif |
| Musique | Fichiers locaux (OGG) ; radios en ligne à l'étude | — | 9 | Le moteur ne lit pas un flux radio sans extension |
| Météo | Open-Meteo, sans clé, par `HTTPRequest` | API v1 (non appelée pendant cette session) | 2, 5 | Gratuit, sans compte |
| Tests | Lanceur maison `tests/run_tests.gd`, hors écran | — | Tous | Zéro dépendance ; détecte les erreurs de script |
| Textes | Aucun texte visible dans le code ; tout vit dans `data/` | — | Tous | Traduction ultérieure par duplication des fichiers |
| Images | WebP (sans perte pour les objets détourés, qualité 90 pour les décors) | — | 2 à 7 | Dépôt léger sans stockage externe |
| Contenu privé | Dossier `game/content_private/`, ignoré par git, superposé au contenu public | — | 10 | Dépôt publiable |
| Emplacement | `game/` à côté de l'app v1 ; retrait de la v1 en fin de projet | — | 0, 11 | Aucune rupture pendant la refonte |

## Project Structure

```
MoneyMaker/
├── game/                              # le jeu Godot
│   ├── project.godot
│   ├── core/                          # règles pures : aucun nœud, aucun accès aux services
│   │   ├── money/                     # denominations, jar_composition, salary_engine, payroll, bank_account
│   │   ├── time/                      # work_schedule, game_calendar, focus_timer
│   │   ├── kitchen/                   # recipe, pantry, batch (machine à états de la fournée), mastery
│   │   ├── shop/                      # catalog, basket, mail_order
│   │   ├── display/                   # display_layout (surfaces et emplacements)
│   │   ├── quests/                    # quest_board, quest_progress
│   │   ├── companion/                 # chips_routine
│   │   ├── social/                    # affinity, line_selector (répliques conditionnelles)
│   │   ├── state/                     # game_state : tout ce qui est sauvegardé
│   │   └── save/                      # save_files, migrations, v1_import
│   ├── services/                      # services globaux (autoloads)
│   │   ├── clock.gd  content.gd  game.gd  scenes.gd
│   │   └── window_modes.gd  sky.gd  sound.gd  events.gd
│   ├── data/                          # contenu public (JSON)
│   │   ├── balance.json               # tous les nombres réglables du GDD
│   │   ├── denominations.json  products.json  utensils.json  catalog.json
│   │   ├── books/                     # un fichier par livre
│   │   ├── quests.json  chips_routine.json  street_scenes.json  secrets.json
│   │   └── dialogue/honore.json
│   ├── content_private/               # ignoré par git : mots doux, secrets personnels
│   ├── scenes/
│   │   ├── boot/                      # démarrage, chargement, reprise de la v1
│   │   ├── home/                      # la maison et ses objets
│   │   ├── jar/                       # le bocal 2.5D
│   │   ├── street/  grocery/          # la rue, l'épicerie
│   │   ├── closeups/                  # livre, bloc-notes, livret, carnet, garde-manger, four
│   │   ├── widget/                    # les trois formats
│   │   ├── actors/                    # Chips, Honoré
│   │   ├── shared/                    # interactable, parallax_plane, draggable, kraft_label
│   │   └── prototype/                 # prototype du 2026-10-08, à démonter pendant l'epic 1
│   ├── assets/
│   │   ├── art/{home,street,grocery,money,pastries,products,chips,honore,props,paper}/
│   │   ├── audio/{music,ambience,kitchen,chips,street,objects}/
│   │   ├── fonts/  shaders/
│   ├── tests/
│   │   ├── run_tests.gd  test_case.gd
│   │   ├── unit/                      # une suite par classe de core/
│   │   └── content/                   # cohérence des fichiers de data/
│   └── tools/                         # godot.ps1, préparation des images
├── _bmad-output/                      # documents de conception
└── src/, electron/, package.json…     # app Electron v1.1.2, retirée à l'epic 11
```

## Epic to Architecture Mapping

| Epic | Dossiers principaux | Services |
|---|---|---|
| 0 — Fondations | `core/money`, `core/time`, `core/save`, `scenes/boot`, `tests/` | `Clock`, `Game`, `Content` |
| 1 — Bocal et widget | `scenes/jar`, `scenes/widget`, `core/money/jar_composition` | `WindowModes`, `Sound` |
| 2 — Maison | `scenes/home`, `scenes/shared` | `Sky`, `Scenes` |
| 3 — Fournée | `core/kitchen`, `core/time/focus_timer`, `scenes/closeups`, `data/books` | `Game`, `WindowModes` |
| 4 — Vitrine | `core/display`, `scenes/shared/draggable` | `Game` |
| 5 — Rue et banque | `scenes/street`, `core/money/bank_account`, `core/money/ledger` | `Scenes`, `Sky` |
| 6 — Épicerie et Honoré | `scenes/grocery`, `scenes/actors`, `core/shop`, `core/social`, `data/dialogue` | `Content`, `Game` |
| 7 — Chips | `core/companion`, `scenes/actors`, `data/chips_routine.json` | `Clock`, `Events` |
| 8 — Carnet de commandes | `core/quests`, `data/quests.json`, `scenes/closeups` | `Events`, `Game` |
| 9 — Sons et musique | `assets/audio` | `Sound` |
| 10 — Contenu et secrets | `data/`, `content_private/`, `core/shop/mail_order` | `Content` |
| 11 — Finition et sortie | `scenes/boot`, `tools/`, `.github/workflows` | Tous |

## Technology Stack Details

### Core Technologies

- **Godot 4.7.2**, rendu Compatibility, physique 3D Jolt, GDScript typé.
- **Services globaux**, dans cet ordre de chargement :

| Service | Rôle | Dépend de |
|---|---|---|
| `Events` | Signaux transverses (liste fermée, voir plus bas) | — |
| `Clock` | Heure, jour de jeu (bascule à 4 h), saison ; battement d'une seconde | — |
| `Content` | Charge et valide `data/`, puis superpose `content_private/` | — |
| `Game` | Possède l'état (objets de `core/`), charge et sauvegarde | `Clock`, `Content`, `Events` |
| `Sky` | Ambiance lumineuse, météo, saison visuelle | `Clock` |
| `Scenes` | Changement de lieu avec fondu, ouverture des gros plans | — |
| `WindowModes` | Maison ↔ widget, position, opacité, mode discret | `Game` |
| `Sound` | Bus, ambiances, musique | `Sky`, `Game` |

- **Outils présents sur la machine de Victor :** Godot 4.7.2 (Steam), Blender 5.2 (Steam), uv 0.12.17 avec Python 3.14.

### Integration Points

| Point | Usage | Défaillance |
|---|---|---|
| Open-Meteo | Météo de la ville, toutes les 30 min, à la maison uniquement | Dernière météo connue, sinon « clair » ; jamais de message |
| Système de fichiers | `user://save/`, `user://logs/`, dossier de musique choisi par la joueuse | Copie de secours précédente |
| Fenêtre Windows | Drapeaux sans bordure, premier plan, transparent ; icône de la zone de notification | Widget opaque si la transparence est indisponible |
| Réglages de la v1 | Lecture unique du fichier de réglages Electron au premier lancement | Ignoré s'il est absent ou illisible |
| Démarrage de Windows | Raccourci dans le dossier Démarrage, sur demande de la joueuse | Option grisée |

## Novel Pattern Designs

### 1. Bocal 2.5D

**But :** de l'argent dessiné qui a une vraie profondeur.

- Le bocal est un monde 3D séparé, rendu dans une vignette transparente posée dans la scène 2D.
- **Tranche mince :** 6 × 7 unités, profondeur 0,42 (1 unité ≈ 3 cm). Les pièces (diamètre 0,50 à 0,80) ne peuvent pas se coucher à plat : elles restent tournées vers la joueuse, s'inclinent et se recouvrent.
- **Une pièce** = un cylindre pour la tranche + deux faces carrées à découpe alpha portant le dessin. **Un billet** = une plaque + deux faces. Maillages et matériaux partagés par coupure.
- **Deux couches de collision :** parois (1), objets (2). Le clic ne vise que la couche 2, sinon il s'arrête sur la vitre.
- **Le verre** est dessiné en 2D, derrière et devant la vignette, à partir de la projection des coins du bocal : il suit la parallaxe.
- **Parallaxe :** la caméra du bocal se décale avec la souris (± 0,9 en largeur, ± 0,45 en hauteur) en visant toujours le même point.
- **Chute :** 40 objets par seconde au plus ; au-delà, les objets attendent.

**États d'un objet**

```
en attente ──▶ en chute ──▶ posé (endormi) ──▶ figé
                  ▲              │                │
                  └── secousse, saisie, choc ◀────┘
```

**Garde de mise au repos** (à écrire pendant la story 1.2) : un objet resté sous 0,6 unité/s pendant 2 s est figé (corps statique). Une secousse, une saisie ou un choc à moins de 1,6 unité le libère. Raison : dans le prototype, une seule pièce qui vibre tient tout le tas éveillé.

**En widget bandeau ou pastille :** le monde du bocal est mis en pause et son rendu coupé. Les espèces gagnées s'accumulent en attente et tombent au retour.

**Sauvegarde :** la composition (nombre d'objets par coupure), pas les positions. Au lancement, les objets retombent en pluie de 8 s au plus.

**Fusion :** `JarComposition` décide ; la scène retire les objets fusionnés et fait apparaître le résultat à leur barycentre.

### 2. Horloge et rattrapage

**But :** un salaire exact quoi qu'il arrive à l'application.

Écrit et testé à l'epic 0 : `core/money/payroll.gd`, 23 tests.

- `Clock` est le seul à lire l'horloge du PC. Tout le reste reçoit l'instant en paramètre, en **secondes locales** (l'heure qu'affiche le PC, heure d'été comprise) : les tests fournissent l'heure qu'ils veulent.
- Pour chaque jour : `centimes = (secondes_travaillées × net_mensuel + reste) ÷ secondes_mensuelles`, en division entière ; le reste passe au jour suivant.
- **Une seule opération, `advance(maintenant)`,** sert à la fois chaque seconde et au lancement. Elle renvoie les centimes nouvellement gagnés.
- **Jour en cours :** on recalcule ce qui est dû depuis le matin avec les réglages du moment et on verse la différence avec ce qui est déjà tombé. Une différence négative ne reprend rien.
- **Changement de date :** le jour en cours est clos (son reste de journée est versé) et inscrit au journal ; les jours entiers manqués sont payés un par un, 31 au plus ; le nouveau jour s'ouvre.
- **Journal :** une ligne par jour clos — secondes travaillées, centimes, nature (`travaille`, `repos`, `conge`, `ferie`, `sans_solde`). Une ligne n'est jamais modifiée.
- **Horloge reculée :** la journée en cours est rangée au journal telle quelle. Quand une date déjà inscrite redevient le jour en cours, elle repart de ce qui lui a été versé : aucune date n'est payée deux fois.
- **Pointage manuel :** le temps ne compte qu'entre arrivée et départ, 16 h au plus par jour ; un pointage oublié s'arrête à minuit.

### 3. Fenêtre à deux visages

| | Maison | Widget |
|---|---|---|
| Bordure | Oui | Non |
| Premier plan | Non | Oui |
| Fond | Opaque | Transparent |
| Taille de conception | 1920 × 1080 | Celle du format (320 × 96, 180 × 64, 240 × 300) |
| Économie de processeur | Non | Oui |
| Bocal | Simulé et rendu | En pause (sauf format mini-bocal) |

- Séquence validée : fenêtrée → sans bordure → non redimensionnable → premier plan → transparente → taille de conception → taille → position.
- Le retour applique la séquence inverse et restaure taille, position et mode.
- L'état du jeu vit dans les services : changer de visage ne recharge rien.

### 4. Objets diégétiques

- `Interactable` : zone cliquable posée sur un objet du décor. Signaux `hovered`, `unhovered`, `activated`. Au survol : éclaircissement et léger rebond.
- **Gros plan :** une scène dans `scenes/closeups/`, ouverte par `Scenes.open_closeup(id)` au-dessus du lieu assombri. Échap, clic droit ou clic hors de l'objet la ferme.
- Règle : un gros plan lit et modifie l'état par `Game`, jamais directement un autre gros plan.

### 5. Surfaces de vitrine

- `DisplayLayout` (dans `core/`) connaît les surfaces, leurs emplacements et ce qui les occupe.
- Une surface est une ligne dans la scène, découpée en emplacements de 96 px.
- `Draggable` soulève l'objet, demande à `DisplayLayout` l'emplacement libre le plus proche du curseur, y pose l'objet ou le renvoie.
- Mêmes classes pour les pièces de vitrine et la décoration.

### 6. Chips

- `ChipsRoutine` (dans `core/`) prend l'heure, l'état du jeu et les événements récents, et renvoie un endroit et une posture.
- Priorité : événement en cours > créneau horaire. Changement de créneau au plus toutes les 20 min.
- Les endroits sont des repères nommés dans les scènes ; `data/chips_routine.json` associe créneaux et repères.
- La scène de Chips ne décide rien : elle affiche la posture et joue le bond.

### 7. Répliques conditionnelles

- Chaque réplique porte des conditions (`créneau`, `météo`, `saison`, `palier`, `panier contient`, `drapeau`), un poids et, au besoin, une suite ou des choix.
- `LineSelector` filtre les répliques éligibles, écarte les 5 dernières dites, tire selon les poids.
- Un choix peut poser un drapeau ou ajouter de l'affinité. Rien d'autre.

### 8. Contenu en couches

- `Content` charge `data/`, puis, s'il existe, `content_private/` : mêmes fichiers, fusionnés par identifiant.
- Sans contenu privé, les secrets et lettres affichent leur version neutre.

## Implementation Patterns

These patterns ensure consistent implementation across all AI agents:

**Règles pures d'abord.** Toute règle chiffrée du GDD est une méthode de `core/`, avec son test, avant d'être branchée à une scène.

```gdscript
# core/ : pas de Node, pas de service global, dépendances reçues en paramètre
extends RefCounted
const WorkSchedule := preload("res://core/time/work_schedule.gd")

static func earned_today(schedule: WorkSchedule, net_monthly_cents: int, weekday: int, second_of_day: int, carry: int = 0) -> int:
```

**Scripts référencés par `preload`, pas par nom de classe global.** Les tests hors écran tournent sans cache de classes.

**Communication.**

- Un parent appelle ses enfants ; un enfant prévient par signal.
- Entre lieux et services : signaux de `Events`, liste fermée — `cents_earned`, `settings_changed`, `jar_deposited`, `purchase_paid`, `focus_started`, `focus_ended`, `break_ended`, `batch_finished`, `batch_failed`, `piece_placed`, `gift_given`, `quest_completed`, `day_changed`.
- Un nouveau signal transverse s'ajoute à cette liste dans ce document avant d'être écrit.

**État.**

- `Game` est le seul à posséder l'état. Les scènes le lisent et demandent des actions (`Game.deposit_jar()`, `Game.pay_basket()`).
- Chaque action qui change l'état déclenche une sauvegarde différée de 2 s, regroupée.

**Nombres réglables.** Aucun nombre du GDD en dur dans une scène : ils sont dans `data/balance.json`, lus par `Content`.

**Formats.**

| Donnée | Format |
|---|---|
| Argent | `int`, centimes |
| Quantités | `int`, en grammes, millilitres ou pièces |
| Instant | `int`, secondes Unix (heure système) |
| Jour | `String` `AAAA-MM-JJ`, jour de jeu (bascule à 4 h) |
| Identifiant | `snake_case` ASCII, stable une fois publié |
| Durées réglables | Minutes entières |

**Cycle de vie.** `boot` : charger le contenu → charger la sauvegarde (ou la créer, ou reprendre la v1) → rattrapage → ouvrir la maison ou le widget.

**Tests.** Une suite par classe de `core/` dans `tests/unit/`. Une suite `tests/content/` vérifie que chaque ingrédient de recette existe en rayon, que chaque casse conserve la valeur, que chaque identifiant est unique.

## Consistency Rules

### Naming Conventions

| Élément | Règle | Exemple |
|---|---|---|
| Fichiers et dossiers | `snake_case` | `salary_engine.gd`, `jar_view.tscn` |
| Constantes de script préchargé | `PascalCase` | `const JarComposition := preload(…)` |
| Fonctions, variables | `snake_case` | `worked_seconds_at` |
| Constantes | `MAJUSCULES` | `POT_FULL_OBJECTS` |
| Signaux | Participe passé | `focus_ended` |
| Membres privés | Préfixe `_` | `_queue` |
| Identifiants de contenu | `snake_case` français sans accent | `tarte_citron_meringuee` |
| Images | `<famille>_<nom>[_variante].webp` | `chips_pain.webp`, `coin_100_face.webp` |
| Code | Noms en anglais | — |
| Commentaires, contenu, documents | Français | — |

### Code Organization

- `core/` n'importe rien de `scenes/` ni de `services/`.
- `scenes/` peut appeler `services/` et `core/`.
- `services/` peut appeler `core/`.
- Une scène = un dossier avec son `.tscn`, son script et ses sous-scènes.
- Typage statique obligatoire : paramètres, retours et variables membres.

### Error Handling

- **Jamais de fenêtre d'erreur.** Le jeu continue avec une valeur de repli et écrit dans le journal.
- Contenu invalide au chargement : l'entrée fautive est écartée, les autres sont gardées, les tests de contenu échouent.
- Sauvegarde illisible : essayer les 3 copies de la plus récente à la plus ancienne ; si toutes échouent, renommer le dossier et repartir d'une sauvegarde neuve.
- Réseau : délai de 5 s, aucune relance avant 30 min.

### Logging Strategy

- `push_warning` et `push_error` du moteur, plus un fichier `user://logs/moneymaker.log` limité à 1 Mo, en rotation sur 3 fichiers.
- Aucun montant ni contenu du bloc-notes dans le journal.

## Data Architecture

### Sauvegarde (`user://save/save.json`)

```json
{
  "version": 1,
  "saved_at": 1791460000,
  "settings": {
    "net_monthly_cents": 200000,
    "manual_clocking": false,
    "schedule": {"working_days": [1,2,3,4,5], "start_minute": 540, "end_minute": 1020,
                 "lunch_start_minute": 720, "lunch_duration_minutes": 60},
    "day_marks": {"2026-10-20": "conge"},
    "city": {"name": "Lyon", "latitude": 45.8, "longitude": 4.8},
    "focus_minutes": 25, "short_break_minutes": 5, "long_break_minutes": 15,
    "strict_focus": true, "price_factor": 1.0, "copy_assist": false,
    "widget": {"format": "bandeau", "position": [3096, 1272], "opacity": 1.0},
    "volumes": {"music": 0.6, "ambience": 0.8, "kitchen": 0.8, "chips": 1.0, "street": 0.7, "objects": 0.9},
    "accessibility": {"text_scale": 1.0, "plain_handwriting": false, "reduced_motion": false}
  },
  "payroll": {"open_day": "2026-10-08", "open_day_credited": 3956, "open_day_worked": 10800,
              "carry_numerator": 420000, "carry_denominator": 546000, "total_earned_cents": 13186,
              "clocked_in_at": -1, "manual_worked_today": 0},
  "ledger": {"2026-10-07": {"worked_seconds": 25200, "cents": 9230, "kind": "travaille"}},
  "jar": {"size": "pot", "cents": 3956, "composition": {"1": 1, "5": 1, "50": 3, "500": 2}},
  "bank": {"balance_cents": 9230,
           "operations": [{"at": 1791380000, "kind": "deposit", "label": "Dépôt", "cents": 9230, "balance_cents": 9230}]},
  "pantry": {"farine": 780, "oeufs": 5},
  "utensils": ["saladier", "fouet", "plaque", "mug"],
  "books": ["premieres_fournees"],
  "recipes": {"cookies": {"batches": 3, "perfect": 2, "first_day": "2026-10-06"}},
  "batch": {"recipe": "brioche_tressee", "phase": 1, "state": "focusing", "ends_at": 1791461500,
            "held_seconds_left": null, "perfect": true, "focus_in_a_row": 2},
  "display": {"surfaces": ["cloches", "etagere_1", "etagere_2"],
              "pieces": [{"id": "cookies", "surface": "etagere_1", "slot": 2}], "decor": []},
  "gift_box": ["cookies", "cookies"],
  "honore": {"affinity": 12, "last_visit_day": "2026-10-07", "last_gift_day": "2026-10-07",
             "flags": ["rencontre"], "recent_lines": [], "set_aside_basket": null},
  "quests": {"day": "2026-10-08", "board": ["deux_avant_midi"], "pinned": [{"id": "part_pour_honore", "progress": 0}],
             "stamps": 7, "completed": ["premier_depot"]},
  "chips": {"spot": "rebord_fenetre", "since": 1791458000, "bowl_portions": 14, "found": ["bouton"]},
  "mail_order": {"item": "etagere_murale", "ordered_day": "2026-10-08"},
  "ephemerals": {"bouquet": {"until_day": "2026-10-15"}, "cafe": {"doses": 12}},
  "notepad": {"pages": [[{"text": "farine", "struck": false}]]},
  "secrets_found": [],
  "stats": {"focus_completed": 31, "deposits": 4, "first_day": "2026-10-06"}
}
```

- **En place depuis l'epic 0 :** `version`, `saved_at`, `settings` (salaire, horaires, marques de jours), `payroll`, `ledger`, `jar` (taille et centimes), `stats.first_day`. Les autres blocs arrivent avec leur epic.
- **Écriture atomique :** écrire `save.tmp`, supprimer `save.json`, renommer. Une coupure entre les deux laisse `save.tmp`, que la lecture sait reprendre.
- **Copies de secours :** `save.1.json` à `save.3.json` tournent **une fois par lancement**, après une lecture réussie du fichier principal. Ce sont donc les états des trois derniers lancements.
- **Cadence :** écriture 2 s après une action de la joueuse, toutes les 60 s s'il y a du nouveau, et à la fermeture. Les centimes qui tombent ne déclenchent pas d'écriture : le rattrapage les recalcule.
- **Sauvegarde illisible ou plus récente que le jeu :** déplacée dans `illisible-<date>/`, jamais supprimée.
- **Migrations :** une fonction par passage de version dans `core/save/migrations.gd`, testée avec un fichier d'exemple par version.
- **Le journal** est tronqué à 400 jours ; le cumul est conservé dans `payroll.total_earned_cents`.

### Contenu (`game/data/`)

```json
// books/premieres_fournees.json — une recette
{
  "id": "cookies", "title": "Cookies aux pépites de chocolat", "kind": "biscuit",
  "description": "Croustillants dehors, moelleux dedans.",
  "utensils": ["saladier", "plaque"],
  "ingredients": [{"id": "beurre", "amount": 120}, {"id": "sucre", "amount": 100}, {"id": "oeufs", "amount": 1}],
  "display": {"width": 1},
  "phases": [{
    "id": "cookies_tout", "name": "Préparation et cuisson", "rest_after": false,
    "gestures": ["verser", "casser", "melanger"],
    "ambience": ["Mélange du beurre mou et du sucre…", "Pluie de pépites de chocolat !"],
    "instructions": ["Mélanger 120 g de beurre mou avec 100 g de sucre."]
  }]
}
```

```json
// products.json
{"id": "farine", "name": "Farine de blé", "unit": "g", "pack_amount": 1000, "price_cents": 120,
 "shelf": "epicerie_seche", "min_tier": 0, "seasons": []}
```

```json
// quests.json
{"id": "deux_avant_midi", "family": "fournee", "from": "mme_lucie", "weight": 3,
 "text": "Deux fournées avant midi, vous croyez que c'est possible ?",
 "goal": {"event": "batch_finished", "count": 2, "before_minute": 720},
 "requires": {"min_day": 2}, "reward": {"kind": "postcard", "id": "carte_lucie_1"}}
```

```json
// dialogue/honore.json
{"id": "pluie_matin_1", "when": {"slot": "matin", "weather": "pluie"}, "weight": 2,
 "text": "Entrez vite, vous allez prendre l'eau !", "expression": "attendri"}
```

Les 6 recettes de `src/data/recipes.ts` sont converties vers ce format à la story 3.1 ; leurs phrases d'ambiance et instructions sont reprises telles quelles, les ingrédients sont chiffrés à partir des instructions.

## API Contracts

### Services (extraits)

```gdscript
# Clock — en place
signal second_ticked(now_local: int)
func now_local() -> int                           # secondes locales
func pretend_it_is(text: String) -> void          # essais uniquement

# Game — en place
var state: GameState                              # state.payroll, state.jar_cents
var started_from: String                          # "sauvegarde", "reprise_v1", "nouvelle_partie"
func boot(profile: String = "") -> void           # inerte tant que boot() n'est pas appelé
func set_pay(net_monthly_cents: int, schedule_values: Dictionary) -> void
func request_save() -> void
func save_now() -> bool

# Game — à venir avec les epics suivants
func pour_jar_into_bag() -> bool
func deposit_bag() -> int                         # centimes déposés
func pay_basket() -> Dictionary                   # { "ok": bool, "missing_cents": int }
func can_start_recipe(recipe_id: String) -> Dictionary   # { "ok": bool, "missing": Array[String] }
func start_recipe(recipe_id: String) -> void
func hold_or_resume_focus() -> void
func abandon_batch() -> void
func place_piece(piece_id: String, surface_id: String, near_slot: int) -> int   # emplacement obtenu, -1 si refusé
func pin_quest(quest_id: String) -> bool

# WindowModes
func show_home() -> void
func show_widget(format: String = "") -> void
func set_discreet(enabled: bool) -> void

# Scenes
func go_to(place: String) -> void                 # "home", "street", "grocery"
func open_closeup(id: String) -> void
func close_closeup() -> void
```

### Open-Meteo

- Recherche de ville : `GET https://geocoding-api.open-meteo.com/v1/search?name=<ville>&count=5&language=fr`
- Météo : `GET https://api.open-meteo.com/v1/forecast?latitude=<lat>&longitude=<lon>&current=weather_code,is_day&daily=sunrise,sunset&timezone=auto`
- Les codes météo sont ramenés aux 5 états du GDD dans `services/sky.gd`.
- Ces deux adresses n'ont pas été appelées pendant cette session : à vérifier à la story 2.4.

## Security Architecture

- **Aucune donnée ne quitte la machine**, hormis la latitude et la longitude de la ville, arrondies au dixième de degré, envoyées à Open-Meteo si la météo réelle est activée.
- Aucun compte, aucune télémétrie, aucune mise à jour silencieuse.
- Le contenu JSON est lu comme des données : aucun script n'est exécuté depuis `data/`, `content_private/` ou la sauvegarde.
- `content_private/` et `export_presets.cfg` sont ignorés par git (`game/.gitignore`).
- Le salaire n'apparaît ni dans le journal, ni dans le titre de la fenêtre ; le mode discret le masque à l'écran.

## Performance Considerations

| Cible du GDD | Moyen |
|---|---|
| 60 images/s à la maison | Rendu Compatibility ; 240 objets au plus dans le bocal ; objets figés une fois posés ; vignette du bocal mise à jour seulement quand un objet bouge ou que la souris se déplace |
| ≤ 2 % de processeur en widget | Mode économie du moteur, 15 images/s, bocal en pause, aucune scène de lieu chargée |
| ≤ 250 Mo de mémoire | Un seul lieu chargé à la fois ; décors en 1920 × 1080 par plan |
| Démarrage ≤ 4 s | Le widget démarre sans charger la maison ; chargement des lieux en arrière-plan |
| Changement de lieu ≤ 0,7 s | Préchargement du lieu voisin dès le survol de la porte |
| Sauvegarde ≤ 50 ms | Fichier de quelques dizaines de ko ; écriture regroupée |
| Minuteur exact | Échéance stockée en heure système, relue à chaque seconde |

**À mesurer sur la machine de la destinataire** dès la fin de l'epic 1 : toutes les mesures actuelles viennent d'un PC de jeu.

## Deployment Architecture

- **Export Windows** par les modèles d'export de Godot 4.7.2 (à installer depuis l'éditeur avant le premier export).
- **Intégration continue** (story 0.2) : tests hors écran à chaque poussée. Le flux actuel `.github/workflows/release.yml` publie l'app Electron ; il reste en place jusqu'à l'epic 11.
- **Publication** (story 11.5) : archive et installeur attachés à une version GitHub, déclenchés par une étiquette `v2.*`.
- **Versions :** `2.0.0` pour la version cadeau. La v1 est étiquetée `v1.1.2-electron` avant son retrait.
- **Mise à jour :** au lancement, pas de vérification réseau en v1.0.

## Development Environment

### Prerequisites

- Windows 10 ou 11.
- Godot 4.7.2 (présent : `D:\SteamLibrary\steamapps\common\Godot Engine\`).
- Blender 5.2 (présent), pour d'éventuels maillages.
- uv (présent), pour les scripts BMAD et la préparation des images.

### AI Tooling (MCP Servers)

Le module BMAD recense des serveurs MCP communautaires pour Godot (GoPeak, entre autres) qui laissent un agent inspecter l'arbre de scène et lancer le jeu. **Aucun n'est installé.** Le prototype a été piloté en ligne de commande (`--script`, arguments après `--`, capture d'écran enregistrée par le jeu), ce qui suffit pour l'instant. À réévaluer si l'édition de scènes `.tscn` par un agent devient pénible.

### Setup Commands

```bash
git clone https://github.com/VictorGrabowski/MoneyMaker
```

```powershell
$env:GODOT = "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
.\game\tools\godot.ps1 -Tests
```

## Architecture Decision Records (ADRs)

**ADR-001 — Godot plutôt qu'Electron + PixiJS.**
Contexte : le 8 octobre 2026, le projet a gagné un personnage à dialogues, un trajet, des lieux et du placement d'objets. Décision : Godot 4.7. Conséquences : réécriture complète ; perte de la lecture de radios en ligne, native dans un navigateur ; gain d'un éditeur de scènes, de la 3D pour le bocal et d'un exécutable sans navigateur embarqué.

**ADR-002 — Bocal en 3D mince plutôt qu'en 2D.**
Contexte : « argent en 2.5D, dessiné ». Options : sprites 2D en plusieurs plans, ou volumes 3D à faces dessinées. Décision : 3D. Raisons : profondeur et parallaxe réelles ; les illustrations demandées sont des vues de face, les plus faciles à obtenir cohérentes. Risque : mise au repos, traitée par la garde décrite plus haut.

**ADR-003 — Une fenêtre, deux visages.**
Décision : changer les drapeaux d'une fenêtre unique. Raison : validé par le prototype ; évite deux fenêtres à synchroniser. Limite : la maison et le widget ne sont jamais visibles ensemble.

**ADR-004 — Contenu en JSON, pas d'extension de dialogue.**
Raison : les répliques d'Honoré sont surtout des réactions au contexte, pas des arbres. Un sélecteur de 200 lignes suffit et ne dépend d'aucun projet tiers.

**ADR-005 — Argent en centimes entiers avec report du reste.**
Raison : la v1 comptait en nombres flottants et recalculait le passé. Vérifié : 13 jours à 2 000 € net tombent pile.

**ADR-006 — Lanceur de tests maison.**
Raison : aucune dépendance à installer ; il détecte les erreurs de script grâce à un collecteur d'erreurs du moteur. À remplacer par GUT si des doublures ou des tests de scènes deviennent nécessaires.

**ADR-007 — `game/` à côté de la v1.**
Raison : l'app Electron reste utilisable jusqu'à la parité ; l'historique git est conservé.

## Risques ouverts

| Risque | Gravité | Réponse |
|---|---|---|
| Performance inconnue sur un portable de bureau | Haute | Mesure sur la machine de la destinataire en fin d'epic 1 ; repli : moins d'objets, vignette à demi-résolution |
| Mise au repos des pièces non garantie | Moyenne | Garde de mise au repos, story 1.2 |
| Cohérence des illustrations générées | Moyenne | Feuille de style et image de référence dans chaque prompt (`art-direction.md`) |
| Radios en ligne | Basse | Étude 9.4 ; la musique locale couvre le besoin |
| Fenêtre transparente selon les pilotes graphiques | Basse | Repli sur un widget opaque à coins carrés |
| Scènes `.tscn` écrites par un agent | Basse | Scènes simples construites dans l'éditeur par Victor, comportement en script |

---

_Generated by BMAD Decision Architecture Workflow v1.0_
_Date: 2026-10-08_
_For: Victor_
