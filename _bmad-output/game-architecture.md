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
| 0 — Fondations | Story 0.1 faite (installeurs retirés). Stories 0.2 à 0.8 écrites, en attente de relecture | Cinq lancements enchaînés sur une sauvegarde d'essai avec une horloge simulée (fermé lundi 12 h, rouvert mardi, jeudi, horloge reculée au mercredi, retour au jeudi) : montants exacts, aucun double paiement |
| 1 — Bocal et widget | Les neuf stories sont écrites, en attente de relecture | 84 tests hors écran. Bocal plein pour les trois tailles : au repos, tas au bord ou un peu au-dessus (1,0 à 1,25 fois la hauteur selon les essais). Contenu identique après relance. Parcours scripté : secouer, trois formats de widget, opacité, retour à la maison |
| 2 — Maison | Les huit stories sont écrites, en décor provisoire dessiné par le code, en attente de relecture | Voir « Epic 2 » ci-dessous |

**Mesures de l'epic 1**, sur le PC de Victor (Ryzen 7 5700X3D, Radeon RX 6700 XT, 16 cœurs logiques) :

| Situation | Processeur | Mémoire |
|---|---|---|
| Widget pastille ou bandeau | 0,6 à 1,6 % d'un cœur | 190 Mo |
| Widget mini-bocal, pièces au repos | 0,6 % d'un cœur | 215 Mo |
| Widget mini-bocal, salaire qui tombe (2 000 € net) | 3,9 % d'un cœur | 211 Mo |
| Maison, pièces au repos | 1,6 % d'un cœur | 217 Mo |
| Maison, salaire qui tombe | 9,0 % d'un cœur | 214 Mo |
| 264 objets en mouvement, sans synchronisation verticale | 539 images/s | — |

La cible du GDD (2 % d'un processeur 4 cœurs, soit 8 % d'un cœur) est tenue en widget sur cette machine.

**Epic 2 — La maison (décor provisoire).** Les huit stories sont écrites, en attente de relecture. 112 tests hors écran. Vérifié par captures et par un parcours scripté (`--tour`) sur une sauvegarde d'essai : balayage d'un bout à l'autre, les cinq ambiances de lumière (aube, jour, heure dorée, heure bleue, nuit), les cinq météos, les quatre saisons, les six gros plans, l'aller-retour du bocal entre comptoir, gros plan et mini-bocal, une fenêtre 16:10 et une fenêtre ultra-large, un jour marqué « congé », le pointage manuel. Les deux adresses d'Open-Meteo ont été appelées pour de bon : relevé météo de Paris et recherche de « Lyon » (cinq réponses).

**Après le premier essai de Victor (2026-10-08).** Il a redemandé deux choses de la v1 : fusionner l'argent à la main et secouer le bocal entier. Écrites le jour même (décisions D28 et D29, ADR-013 et ADR-014). 125 tests hors écran. Un essai joué avec de vrais événements souris (`--gestures`) passe sur un Pot à 43 % et sur un Pot plein, salaire arrêté puis salaire qui tombe : aucune pièce hors du bocal après les secousses, valeur inchangée au centime après les fusions, affichage conforme à l'état. Charge inchangée (maison au repos 2 %, salaire qui tombe sur un pot qui déborde 24 % d'un cœur).

**Mesures de l'epic 2**, même machine, deux fils de travail (voir ADR-011) :

| Situation | Processeur | Mémoire |
|---|---|---|
| Maison, rien ne tombe (nuit, lampes allumées) | 0,9 à 1,4 % d'un cœur | 240 Mo |
| Maison, salaire qui tombe, pot à moitié (2 000 € net) | 7,3 % d'un cœur | 232 Mo |
| Maison, salaire qui tombe, pot qui déborde (114 objets) | 15 à 22 % d'un cœur | 235 Mo |
| Maison, pot à moitié, il pleut | 12,3 % d'un cœur | 232 Mo |
| Widget mini-bocal, pot à moitié | 5,2 % d'un cœur | 219 Mo |
| Widget mini-bocal, pot qui déborde | 11,8 % d'un cœur | 221 Mo |
| Widget pastille | 0,2 % d'un cœur | 205 Mo |

Avant ADR-011, avec un fil de travail par cœur, la maison coûtait de 28 à 56 % d'un cœur dès que le salaire tombait : ces mesures-là remplacent le « 9 % » de l'epic 1, pris avec un bocal peu rempli.

Ce qui coûte encore : chaque pièce qui tombe réveille tout le tas (le bocal simule et se redessine 45 % du temps à 2 000 € net, 25 opérations en 40 s). Piste non suivie, à reprendre si le portable de la destinataire peine : figer le tas au repos et ne libérer que ce qui se trouve au-dessus d'une fusion (voir ADR-009, qui l'avait écarté sous sa forme simple).

**Non vérifié :**

- le flux GitHub `game-tests.yml` n'a encore jamais tourné (rien n'est poussé) ;
- les performances sur un portable de bureau ;
- les gestes à la souris, pour partie. Depuis le 2026-10-08, un essai (`--gestures`) envoie de vrais événements souris au jeu et constate : bocal secoué sur le comptoir sans que le gros plan s'ouvre, gros plan ouvert d'un clic, fusion à deux et à trois en faisant glisser une pièce (même valeur au centime, affichage conforme à l'état), bocal saisi par la paroi, clic droit à travers le mini-bocal. Restent écrits mais jamais exercés : tapoter, lancer une pièce, déplacer le widget à la souris (et donc le balancement du mini-bocal par un vrai déplacement de fenêtre), la molette, le survol des objets de la maison, le balayage par les bords de l'écran, la saisie au clavier dans les feuilles. Et aucune main humaine n'a encore dit si ces gestes sont agréables ;
- l'icône de la zone de notification : créée selon le moteur, pas vue à l'écran ;
- les sons : joués sans erreur, jamais écoutés ;
- le repli hors ligne de la météo : écrit (une requête qui échoue garde la dernière météo connue), pas essayé réseau coupé ;
- la justesse du relevé météo lui-même : le jeu a reçu un code et l'a traduit, personne n'a comparé avec le ciel du jour.

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
| Météo | Open-Meteo, sans clé, par `HTTPRequest` | API v1 (relevé et recherche de ville appelés le 2026-10-08) | 2, 5 | Gratuit, sans compte |
| Fils de travail | Deux, au lieu d'un par cœur | Godot 4.7.2 | 1, 2 | Mesuré : la charge triple sinon dès qu'une pièce tombe (ADR-011) |
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
│   │   ├── world/                     # daylight (soleil, ambiances), weather (états, codes météo)
│   │   ├── text/                      # entries : lire une heure ou une somme écrite à la main
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
│   │   └── window_modes.gd  atmosphere.gd  sound.gd  events.gd
│   ├── data/                          # contenu public (JSON)
│   │   ├── balance.json               # tous les nombres réglables du GDD
│   │   ├── denominations.json  products.json  utensils.json  catalog.json
│   │   ├── books/                     # un fichier par livre
│   │   ├── quests.json  chips_routine.json  street_scenes.json  secrets.json
│   │   └── dialogue/honore.json
│   ├── content_private/               # ignoré par git : mots doux, secrets personnels
│   ├── scenes/
│   │   ├── boot/                      # démarrage, chargement, reprise de la v1
│   │   ├── home/                      # la maison : home (scène principale), home_layout, home_decor, home_prop
│   │   ├── jar/                       # le bocal 2.5D
│   │   ├── street/  grocery/          # la rue, l'épicerie
│   │   ├── closeups/                  # closeup_layer, paper ; fiche de paie, calendrier, ticket, baromètre,
│   │   │                              # cadre du widget ; plus tard livre, bloc-notes, livret, carnet, four
│   │   ├── widget/                    # les trois formats
│   │   ├── actors/                    # Chips, Honoré
│   │   ├── shared/                    # parallax_plane ; plus tard draggable, kraft_label
│   │   └── workbench/                 # ancien écran de travail, gardé comme banc d'essai du bocal
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
| 2 — Maison | `scenes/home`, `scenes/closeups`, `scenes/shared`, `core/world`, `core/text` | `Atmosphere`, `WindowModes` |
| 3 — Fournée | `core/kitchen`, `core/time/focus_timer`, `scenes/closeups`, `data/books` | `Game`, `WindowModes` |
| 4 — Vitrine | `core/display`, `scenes/shared/draggable` | `Game` |
| 5 — Rue et banque | `scenes/street`, `core/money/bank_account`, `core/money/ledger` | `Scenes`, `Atmosphere` |
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
| `WindowModes` | Maison ↔ widget, position, opacité, mode discret | `Game` |
| `Atmosphere` | Ambiance lumineuse, météo, saison visuelle. (Il devait s'appeler `Sky` : le nom est déjà pris par une classe du moteur, comme `Plane`.) | `Clock`, `Game`, `Events` |
| `Scenes` | Changement de lieu avec fondu (à l'epic 5 ; d'ici là, la maison ouvre elle-même ses gros plans) | — |
| `Sound` | Bus, ambiances, musique | `Atmosphere`, `Game` |

En place au 2026-10-08 : `Events`, `Clock`, `Game`, `WindowModes`, `Atmosphere`.

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

Écrit à l'epic 1, complété le 2026-10-08 (fusion à la main, bocal qu'on secoue) : le modèle dans `core/money/jar.gd` (19 tests) et `core/money/denominations.gd` (7 tests), la scène dans `scenes/jar/`.

**Le modèle décide, la scène joue — sauf pour ce que fait la main.**

- `Jar` connaît la taille, le contenu (nombre d'objets par coupure) et les repères de salaire. Plein à ras bord, un bocal vaut un jour (Pot), une semaine (Bocal) ou un mois (Bonbonne) de salaire.
- Le nombre d'objets ne dépasse pas ce que demande le niveau : `niveau × objets-quand-plein` (90, 160, 240), 12 au minimum, 24 de plus au maximum quand le bocal déborde. Calculé en entiers.
- Chaque ajout renvoie une liste d'**opérations** : `tomber` (ces coupures tombent), `fusionner` (celles-ci n'en font plus qu'une), `casser` (celle-ci en donne de plus petites).
- **Quelle fusion ?** Celle dont l'ingrédient principal « encombre » le plus : nombre d'objets de cette coupure ÷ sa part dans `PROFILE`. Le profil donne beaucoup de pièces de 1 et 2 €, de la petite monnaie, peu de billets. Une casse suit la même mesure, en sens inverse.
- Un centime qui tombe déclenche au plus une fusion. **Une casse ne touche que ce qui vient de tomber** (un rattrapage arrivé en gros billets) : ce qui était déjà là, la joueuse l'a peut-être fusionné exprès. Seuls un changement de capacité ou de taille recomposent tout le bocal.
- `Events.jar_changed(opérations)` porte ces opérations à la scène. Après les avoir jouées, l'écran compare le contenu de la scène à celui du modèle ; en cas d'écart, il refait le bocal et écrit un avertissement.
- **Fusion à la main :** ici c'est la scène qui décide, parce qu'elle seule sait quelles coupures se touchent. `Denominations.hand_merge(tenue, touchée, contenu)` dit ce que le geste donne (la table de casse lue à l'envers, plus « trois pareilles rendent la monnaie ») ; la scène joue la fusion, émet `merged_by_hand(entrées, sorties)`, et `Game.exchange_in_jar()` l'inscrit dans le modèle par `Jar.exchange()`, qui vérifie que les coupures y sont et que la valeur est conservée. Après des fusions à la main, le bocal compte moins d'objets que sa cible : les centimes suivants tombent sans fusionner jusqu'à ce que le compte y soit.

**La scène.**

- Le bocal est un monde 3D séparé, rendu dans une vignette transparente posée dans la scène 2D.
- **Tranche mince :** profondeur 0,42 (1 unité ≈ 3 cm). Les pièces (diamètre 0,50 à 0,80) ne peuvent pas se coucher à plat : elles restent tournées vers la joueuse, s'inclinent et se recouvrent.
- **Bocal ouvert, posé sur un comptoir.** Intérieur : 3,7 × 3,25 (Pot), 4,8 × 4,4 (Bocal), 5,9 × 5,4 (Bonbonne), réglé pour qu'un bocal plein arrive au bord. Parois de verre minces (0,14) ; comptoir de 2 unités de chaque côté, fermé par des butées. Trop plein, le tas dépasse et des pièces roulent dehors.
- **Une pièce** = un cylindre pour la tranche + deux faces carrées portant le dessin. **Un billet** = une plaque + deux faces. Maillages et matériaux partagés par coupure.
- **Faces :** l'illustration de `assets/art/money/` si elle existe, sinon une face provisoire dessinée par shader. Une illustration arrive sur fond blanc : `art_face.gdshader` la détoure par sa forme et retire le blanc dans la bande du bord, en gardant le trait de contour.
- **Deux couches de collision :** parois (1), objets (2). Le clic ne vise que la couche 2, sinon il s'arrête sur la vitre.
- **Deux corps pour les parois.** Un corps fixe : le comptoir, ses butées, les deux faces de la tranche. Un corps animé (`AnimatableBody3D`), le bocal lui-même : un fond qui affleure le comptoir et deux parois de verre prolongées sous le fond, pour que rien ne roule sous un bocal soulevé.
- **La main** passe par trois fonctions, `press_at()`, `drag_to()`, `release()`, que la vignette appelle pour ses propres événements et que la maison appelle quand c'est elle qui reçoit les clics (bocal sur le comptoir). La position de la souris vient des événements, jamais d'une lecture du curseur : un essai peut donc rejouer les gestes avec de vrais événements.
  - Sur une paroi (à 0,22 unité près), ou dans un vide du bocal : on saisit le bocal. Il suit la main sur 0,8 unité de chaque côté et 1 vers le haut, à 7 et 4,5 unités/s au plus, puis retourne à sa place. Relâché sans avoir bougé, c'est un tapotement.
  - Sur une coupure : on l'attrape. Après 0,35 unité de trajet, si elle touche une coupure avec qui elle peut fusionner, la fusion se fait dans la main et la nouvelle coupure y reste.
  - En mini-bocal, la vignette laisse passer ce qu'elle ne prend pas : clic droit, molette, double-clic et appui dans le vide reviennent au widget. Déplacer la fenêtre pousse le contenu en sens inverse de son accélération (`sway()`).
- **Pendant une secousse, la physique passe de 60 à 180 pas par seconde.** À 60, une pièce en l'air et une paroi qui vient à sa rencontre se croisent en un seul pas, et la pièce se retrouve dehors à travers le verre (constaté sur capture).
- **Une pièce tombée dehors** retourne dans le bocal après 3 s au repos, tant que le tas est sous 80 % de la hauteur : elle s'éclipse et retombe d'en haut.
- **Le verre** est dessiné en 2D, derrière et devant la vignette, à partir de la projection des coins du bocal : il suit la parallaxe et la taille.
- **Cadrage :** la caméra se règle sur la taille du bocal et la forme de la vignette ; cadrage serré (`compact`) dans le widget.
- **Chute :** 40 objets par seconde, davantage quand il y en a beaucoup, pour que tout soit tombé en 8 s.
- **Fusion :** les objets concernés (les plus proches les uns des autres) glissent vers leur barycentre en rétrécissant, puis le résultat y apparaît avec un sursaut, en 0,18 s.

**Garde de mise au repos.** Toutes les 0,25 s, un objet resté sous 0,6 unité/s et 2 rad/s depuis 1 s reçoit un amortissement fort (4 en translation, 8 en rotation) ; il le perd dès qu'il accélère. Le seuil de sommeil du moteur physique est relevé à 0,25 unité/s. Raison : une seule pièce qui vibre tient tout le tas éveillé. (Figer les objets a été écarté : un objet figé reste en l'air quand ce qui le portait s'en va.)

**Dessin à la demande.** La vignette n'est redessinée que si un objet bouge, apparaît ou disparaît, ou si la caméra se déplace ; sinon une dernière image est rendue et gardée. Le verre n'est redessiné que si le bocal a bougé à l'écran.

**En widget bandeau ou pastille :** le monde du bocal est mis en pause et son rendu coupé. Ce qui est gagné attend dans la file et tombe au retour. En mini-bocal, la vignette est déplacée dans le widget et continue de vivre.

**Sauvegarde :** la taille, le montant et le contenu, pas les positions. Le montant fait foi : si le contenu ne tombe pas juste, le bocal est recomposé. Au lancement, tout retombe.

### 2. Horloge et rattrapage

**But :** un salaire exact quoi qu'il arrive à l'application.

Écrit et testé à l'epic 0, complété à l'epic 2 : `core/money/payroll.gd`, 27 tests.

- `Clock` est le seul à lire l'horloge du PC. Tout le reste reçoit l'instant en paramètre, en **secondes locales** (l'heure qu'affiche le PC, heure d'été comprise) : les tests fournissent l'heure qu'ils veulent.
- Pour chaque jour : `centimes = (secondes_travaillées × net_mensuel + reste) ÷ secondes_mensuelles`, en division entière ; le reste passe au jour suivant.
- **Une seule opération, `advance(maintenant)`,** sert à la fois chaque seconde et au lancement. Elle renvoie les centimes nouvellement gagnés.
- **Jour en cours :** on recalcule ce qui est dû depuis le matin avec les réglages du moment et on verse la différence avec ce qui est déjà tombé. Une différence négative ne reprend rien.
- **Changement de date :** le jour en cours est clos (son reste de journée est versé) et inscrit au journal ; les jours entiers manqués sont payés un par un, 31 au plus ; le nouveau jour s'ouvre.
- **Journal :** une ligne par jour clos — secondes travaillées, centimes, nature (`travaille`, `repos`, `conge`, `ferie`, `sans_solde`). Une ligne n'est jamais modifiée.
- **Horloge reculée :** la journée en cours est rangée au journal telle quelle. Quand une date déjà inscrite redevient le jour en cours, elle repart de ce qui lui a été versé : aucune date n'est payée deux fois.
- **Pointage manuel :** le temps ne compte qu'entre arrivée et départ, 16 h au plus par jour ; un pointage oublié s'arrête à minuit. Passer de l'horaire au pointage en cours de journée garde le temps déjà compté ; revenir à l'horaire dépointe, et rien n'est repris.
- `is_working_at(maintenant)` dit si le temps compte à cet instant : c'est ce qu'affiche le chevalet du bureau.

### 3. Fenêtre à deux visages

| | Maison | Widget |
|---|---|---|
| Bordure | Oui | Non |
| Premier plan | Non | Oui |
| Fond | Opaque | Transparent |
| Taille de conception | 1920 × 1080 | Celle du format : pastille 180 × 64, bandeau 320 × 96, mini-bocal 240 × 300 |
| Images par seconde | 60 au plus | 30 au plus |
| Bocal | Simulé et rendu | En pause, sauf en mini-bocal |

Écrit à l'epic 1 : `services/window_modes.gd`.

- Séquence validée : fenêtrée → sans bordure → non redimensionnable → premier plan → transparente → taille de conception → taille → position.
- Le retour applique la séquence inverse et restaure taille, position et mode.
- L'état du jeu vit dans les services : changer de visage ne recharge rien.
- `WindowModes` ne connaît aucune scène : il émet `changed`, l'écran s'arrange (il déplace le bocal dans le widget en mini-bocal).
- Format, position et opacité sont retenus dans la sauvegarde. Une position qui ne touche plus aucun écran revient en bas à droite de l'écran courant.
- **Mode économie du moteur** dans les deux visages : il ne redessine que si quelque chose change. Activé après le chargement, pas avant : les faces provisoires ont besoin d'être dessinées, et une attente sur « image dessinée » ne reviendrait jamais.
- Icône de la zone de notification : un clic bascule entre les deux visages. Pas de menu (avec un menu, le moteur ne signale plus le clic).

### 4. Objets diégétiques

Écrit à l'epic 2 : `scenes/home/home_prop.gd`, `scenes/closeups/`.

- **Objet cliquable** (`home_prop.gd`) : une zone posée dans le plan de la pièce, qui émet `activated(kind)`. Au survol : éclaircissement et léger grossissement. En décor provisoire, l'objet se dessine lui-même ; avec les illustrations, il n'en restera que la zone et son image.
- **Gros plan :** `closeup_layer.gd` assombrit la maison et centre une feuille (`paper.gd` leur donne le même papier, la même encre, la même écriture). Échap, clic droit ou clic hors de l'objet le ferme. C'est la maison qui ouvre ses gros plans ; un service `Scenes` viendra quand il y aura plusieurs lieux.
- **Le bocal change de place, pas de nature :** la même vignette est posée sur le comptoir, agrandie en gros plan ou installée dans le mini-bocal. Sur le comptoir, c'est une zone cliquable posée devant qui répond ; en gros plan, c'est le bocal lui-même (attraper, tapoter).
- **Un réglage, un objet :** fiche de paie (salaire, horaires, pointage), calendrier mural (jours marqués), baromètre (ville, météo), cadre posé sur le bureau (format du widget), chevalet (pointage du jour), caisse (ticket du soir).
- Règle : un gros plan lit et modifie l'état par `Game`, jamais directement un autre gros plan.
- **Ce qu'on écrit se lit comme on l'écrit** (`core/text/entries.gd`) : « 9 h 30 », « 2 000,50 ». Ce qui est ambigu (« 9,5 », « 2.000 ») est refusé et signalé en rouge, jamais deviné.

### 4 bis. La maison : plans, balayage, lumière

Écrit à l'epic 2 : `scenes/home/`, `scenes/shared/parallax_plane.gd`, `services/atmosphere.gd`, `core/world/`.

- **Quatre plans**, du plus loin au plus près : le dehors (défile à 0,6), la pièce (1), les lumières (1, en ajout de couleur), le premier plan (1,25). La souris les décale encore de 3 à 12 px.
- **Le décor fait 3840 × 1080.** On le balaie en approchant la souris d'un bord, ou avec Q/D et les flèches. Il remplit toujours la hauteur de la fenêtre : sur un écran moins allongé que le 16:9 il est agrandi, sur un écran plus large on en voit davantage.
- **Le plan du dehors ne porte que des bandes horizontales** (ciel, collines, haie, trottoir) : il défile moins vite que la pièce, donc ce qu'on voit par la porte change avec le balayage, et un chemin dessiné vers la porte se décalerait.
- **Toute la mise en place vit dans `home_layout.gd`** : c'est le seul fichier à retoucher quand les illustrations remplaceront les formes.
- **Lumière :** `core/world/daylight.gd` calcule la hauteur du soleil (formules simplifiées de la NOAA, latitude et longitude de la ville, centre de la France par défaut) et en tire le poids de cinq ambiances. `Atmosphere` mélange leurs teintes toutes les 20 s et émet `changed`. La pièce est teintée d'un bloc ; les sources chaudes (guirlande, lustre, lampe, four) et le jour qui entre sont des halos en ajout de couleur, par-dessus.
- **Les objets gardent une part de clarté propre** (18 % pour ce qui se clique, 50 % pour le bocal et l'ardoise) : la nuit, on les repère et on les lit encore.
- **Météo :** cinq états. Réelle (relevé Open-Meteo toutes les 30 min au plus, seulement si une ville est réglée) ou choisie à la main. La pluie et la neige tombent dans le plan du dehors ; elles s'arrêtent en widget.

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
- Entre lieux et services : signaux de `Events`, liste fermée — `cents_earned`, `jar_changed`, `settings_changed`, `preferences_changed`, `jar_deposited`, `purchase_paid`, `focus_started`, `focus_ended`, `break_ended`, `batch_finished`, `batch_failed`, `piece_placed`, `gift_given`, `quest_completed`, `day_changed`.
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
    "focus_minutes": 25, "short_break_minutes": 5, "long_break_minutes": 15,
    "strict_focus": true, "price_factor": 1.0, "copy_assist": false,
    "volumes": {"music": 0.6, "ambience": 0.8, "kitchen": 0.8, "chips": 1.0, "street": 0.7, "objects": 0.9},
    "accessibility": {"text_scale": 1.0, "plain_handwriting": false, "reduced_motion": false}
  },
  "preferences": {"widget": {"format": "bandeau", "position": [3096, 1272], "opacity": 1.0},
                  "discreet": false, "sound": true},
  "world": {"city": {"name": "Lyon", "latitude": 45.8, "longitude": 4.8},
            "weather": {"mode": "reelle", "manual": "clair", "last": "pluie", "last_at": 1791459000}},
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
  "stats": {"focus_completed": 31, "deposits": 4, "first_day": "2026-10-06", "ticket_seen_day": "2026-10-07"}
}
```

- **En place depuis l'epic 0 :** `version`, `saved_at`, `settings` (salaire, horaires, pointage, marques de jours), `payroll`, `ledger`, `jar` (taille et centimes), `stats.first_day`.
- **Depuis l'epic 1 :** `preferences` (widget, mode discret, son), `jar.composition`.
- **Depuis l'epic 2 :** `world` (ville et météo ; `city` est vide tant qu'aucune ville n'est réglée, `last_at` vaut 0 tant qu'aucun relevé n'a réussi), `stats.ticket_seen_day` (dernier ticket du soir lu).
- Les autres blocs arrivent avec leur epic. Aucun de ces ajouts n'a demandé de migration : un champ absent prend sa valeur par défaut.
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
func set_pay(net_monthly_cents: int, schedule_values: Dictionary) -> void   # peut porter "manual_clocking"
func set_clocked_in(clocked_in: bool) -> void     # pointage manuel : commence ou termine la journée
func exchange_in_jar(inputs: Array, outputs: Array) -> bool   # fusion à la main, déjà jouée par la scène
func set_day_mark(day: String, kind: String) -> bool   # "conge", "ferie", "sans_solde", "" pour retirer
func set_city(city_name: String, latitude: float, longitude: float) -> void
func clear_city() -> void
func set_weather(mode: String, manual_state: String) -> void   # "reelle" ou "manuelle"
func mark_ticket_seen(day: String) -> void
func request_save() -> void
func save_now() -> bool

# Events — en place
signal cents_earned(cents: int)
signal jar_changed(ops: Array[Dictionary])
signal settings_changed                           # salaire, horaires, pointage, jours marqués
signal preferences_changed                        # mode discret, son
signal world_changed                              # ville ou météo

# Atmosphere — en place
signal changed                                    # lumière, météo ou saison
signal cities_found(results: Array[Dictionary])   # [{ name, region, latitude, longitude }]
var ambience: String                              # "aube", "jour", "heure_doree", "heure_bleue", "nuit"
var weather: String                               # "clair", "nuageux", "pluie", "neige", "brouillard"
var season: String
var room_tint: Color                              # et outside_tint, sky_top, sky_bottom, sunlight_color
var lamps: float                                  # 0 à 1 ; sunlight de même
func start() -> void                              # une fois l'état chargé
func search_city(city_name: String) -> void       # réponse par cities_found

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

# WindowModes — en place
signal changed                                    # visage, format ou opacité
var in_widget: bool
var format: String                                # "pastille", "bandeau", "mini_bocal"
var opacity: float
func restore(state: GameState) -> void
func toggle() -> void
func show_home() -> void
func show_widget(format: String = "") -> void
func cycle_format() -> void
func choose_format(new_format: String) -> void    # depuis le cadre posé sur le bureau
func nudge_opacity(direction: int) -> void
func move_widget_to(position: Vector2i) -> void
func end_move() -> void
func setup_tray(icon: Texture2D) -> void

# Game — préférences, en place
func set_discreet(enabled: bool) -> void
func set_sound_enabled(enabled: bool) -> void
func remember_widget(format: String, position: Vector2i, opacity: float) -> void

# Scenes — à venir à l'epic 5
func go_to(place: String) -> void                 # "home", "street", "grocery"
```

### Open-Meteo

- Recherche de ville : `GET https://geocoding-api.open-meteo.com/v1/search?name=<ville>&count=5&language=fr`
- Météo : `GET https://api.open-meteo.com/v1/forecast?latitude=<lat>&longitude=<lon>&current=weather_code`
- Le lever et le coucher du soleil ne sont pas demandés : la hauteur du soleil est calculée par le jeu, qui marche donc aussi sans réseau.
- Les codes météo sont ramenés aux 5 états du GDD dans `core/world/weather.gd`.
- Les deux adresses ont été appelées le 2026-10-08 : relevé pour Paris, recherche de « Lyon » (cinq villes, noms de régions et de pays en français).
- Délai de 5 s. Un relevé réussi par demi-heure au plus ; après un échec, pas de nouvel essai avant une demi-heure tant que le jeu reste ouvert. Un échec ne dit rien et garde la dernière météo connue.

## Security Architecture

- **Aucune donnée ne quitte la machine**, hormis la latitude et la longitude de la ville, arrondies au dixième de degré, envoyées à Open-Meteo si la météo réelle est activée.
- Aucun compte, aucune télémétrie, aucune mise à jour silencieuse.
- Le contenu JSON est lu comme des données : aucun script n'est exécuté depuis `data/`, `content_private/` ou la sauvegarde.
- `content_private/` et `export_presets.cfg` sont ignorés par git (`game/.gitignore`).
- Le salaire n'apparaît ni dans le journal, ni dans le titre de la fenêtre ; le mode discret le masque à l'écran.

## Performance Considerations

| Cible du GDD | Moyen |
|---|---|
| 60 images/s à la maison | Rendu Compatibility ; 264 objets au plus dans le bocal ; garde de mise au repos ; vignette du bocal redessinée seulement quand quelque chose bouge ; deux fils de travail (ADR-011) |
| ≤ 2 % de processeur en widget | Mode économie du moteur, 30 images/s au plus, bocal en pause en pastille et en bandeau ; pluie et neige arrêtées en widget. Tenu en pastille et en bandeau ; le mini-bocal coûte de 5 à 12 % d'un cœur quand le salaire tombe |
| ≤ 250 Mo de mémoire | Un seul lieu chargé à la fois ; décors en 1920 × 1080 par plan |
| Démarrage ≤ 4 s | Le widget démarre sans charger la maison ; chargement des lieux en arrière-plan |
| Changement de lieu ≤ 0,7 s | Préchargement du lieu voisin dès le survol de la porte |
| Sauvegarde ≤ 50 ms | Fichier de quelques dizaines de ko ; écriture regroupée |
| Minuteur exact | Échéance stockée en heure système, relue à chaque seconde |

Les valeurs mesurées sont dans « État d'avancement ». **À mesurer sur la machine de la destinataire** : toutes les mesures actuelles viennent d'un PC de jeu.

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

**ADR-008 — Le bocal joue des opérations, il ne recalcule pas son contenu.**
Contexte : recomposer le contenu idéal à chaque centime changeait de 2 à 18 objets d'un coup (mesuré sur une journée). Décision : le modèle garde son contenu et le fait évoluer d'une fusion à la fois, guidée par un profil. Conséquence : le contenu fait partie de la sauvegarde.

**ADR-009 — Mise au repos par amortissement, pas par gel.**
Options : figer les objets posés (comme la v1) ou les amortir. Décision : amortir. Raison : un objet figé reste en l'air quand ce qui le portait disparaît dans une fusion, ce qui arrive à chaque centime.

**ADR-013 — La fusion à la main se décide dans la scène, et le bocal ne la défait pas.**
Contexte : Victor a redemandé la fusion de la v1, où tout ce qui se touchait fusionnait. Reprise telle quelle, elle viderait la jauge : un Pot plein tiendrait en trois billets. Décision : seule la coupure tenue par la joueuse fusionne, avec celle qu'elle touche. C'est la scène qui décide (elle seule connaît les contacts) et le modèle qui enregistre, à l'inverse du reste du bocal. Conséquence : le modèle ne casse plus que ce qui vient de tomber, sans quoi il aurait recassé les billets de la joueuse au centime suivant pour retrouver son compte d'objets.

**ADR-014 — Le bocal secoué est un vrai corps qui bouge, pas un tremblement d'image.**
Options : faire trembler l'image et pousser les pièces (la v1), ou déplacer les parois. Décision : un corps animé (fond et parois) qui suit la main, sur un comptoir qui reste fixe. Raisons : les pièces sont brassées par le verre, celles qui sont dehors restent sur le comptoir, et le geste marche pareil sur le comptoir, en gros plan et dans les essais. Prix : la physique à 180 pas par seconde le temps de la secousse, et une vitesse plafonnée.

**ADR-010 — Mobile plus tard : le calcul reste hors du moteur.**
Contexte : Victor envisage une application Android et iOS avec widget d'écran d'accueil. Le jeu s'exporte sur mobile, mais un widget d'écran d'accueil est un composant natif (Kotlin, Swift) qui ne peut pas faire tourner le moteur. Décision, sans coût aujourd'hui : garder la paie dans `core/`, calculée uniquement à partir de l'heure et des réglages, et garder ces réglages dans un fichier JSON simple. Un widget natif pourra refaire le même calcul sans que le jeu soit lancé. Non étudié : les limites de rafraîchissement des widgets de chaque système, l'adaptation de l'écran au tactile et au format portrait.

**ADR-011 — Deux fils de travail, pas un par cœur.**
Contexte : à l'epic 2, la maison coûtait de 28 à 56 % d'un cœur dès que le salaire tombait, contre 1 % au repos. La scène n'y était pour rien (l'ancien écran de travail coûtait autant) : à chaque pas de physique, le moteur réveillait ses seize fils de travail pour une centaine de pièces. Décision : `threading/worker_pool/max_threads = 2`. Mesuré le même jour simulé, bocal qui déborde : 45 à 52 % en automatique, 15 à 22 % avec un ou deux fils. Deux plutôt qu'un pour laisser un fil aux chargements en arrière-plan à venir.

**ADR-012 — Le soleil est calculé, pas demandé.**
Options : demander lever et coucher à Open-Meteo, ou calculer la hauteur du soleil. Décision : la calculer (`core/world/daylight.gd`, testée contre les solstices et l'équinoxe à Paris). Raisons : la lumière fonctionne sans réseau et sans ville ; les cinq ambiances se fondent selon une hauteur continue plutôt que selon deux heures butoirs ; un service de moins dont dépendre.

## Risques ouverts

| Risque | Gravité | Réponse |
|---|---|---|
| Performance inconnue sur un portable de bureau | Haute | Mesure sur la machine de la destinataire ; repli : moins d'objets, vignette à demi-résolution, tas figé au repos (voir « Mesures de l'epic 2 ») |
| Décor provisoire : toute la mise en place est à l'œil | Basse | Les rectangles de `home_layout.gd` sont à reprendre quand les illustrations arrivent ; les proportions des objets changeront |
| Mise au repos des pièces | Basse | Traitée à l'epic 1 par amortissement ; à revérifier sur un portable de bureau |
| Sons fabriqués par calcul, jamais écoutés | Moyenne | Écoute par Victor ; vrais enregistrements à l'epic 9 ; touche M pour couper |
| Gestes à la souris non exercés par les essais | Moyenne | Essai à la main par Victor ; essais par événements simulés à ajouter |
| Cohérence des illustrations générées | Moyenne | Feuille de style et image de référence dans chaque prompt (`art-direction.md`) |
| Radios en ligne | Basse | Étude 9.4 ; la musique locale couvre le besoin |
| Fenêtre transparente selon les pilotes graphiques | Basse | Repli sur un widget opaque à coins carrés |
| Scènes `.tscn` écrites par un agent | Basse | Scènes simples construites dans l'éditeur par Victor, comportement en script |

---

_Generated by BMAD Decision Architecture Workflow v1.0_
_Date: 2026-10-08_
_For: Victor_
