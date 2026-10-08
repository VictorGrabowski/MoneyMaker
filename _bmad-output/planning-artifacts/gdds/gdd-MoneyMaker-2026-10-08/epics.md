---
title: 'MoneyMaker — Epics de la refonte'
created: '2026-10-08'
updated: '2026-10-08'
status: 'validé par Victor le 2026-10-08'
source: 'gdd.md (même dossier)'
---

# MoneyMaker — Epics de la refonte

Chaque epic livre une tranche jouable seule. Les stories sont au niveau « quoi », pas « comment » : le découpage fin se fait avec `gds-create-epics-and-stories` puis `gds-create-story`.

**Jalons**

| Jalon | Fin de l'epic | Signification |
|---|---|---|
| Parité v1 | 1 | Le jeu Godot fait ce que faisait l'app Electron |
| Tranche verticale | 6 | La boucle gagner → déposer → acheter → cuire → exposer est jouable |
| Version cadeau | 11 | Installable, complète, offerte |

**Ordre et dépendances**

```
0 ─▶ 1 ─▶ 2 ─▶ 3 ─▶ 4
               │    
               ├─▶ 5 ─▶ 6 ─▶ 8 ─▶ 10 ─▶ 11
               └─▶ 7        9 (dès que 2 est fini)
```

---

## Epic 0 — Fondations

**Objectif :** un socle où l'argent et le temps sont exacts et sauvegardés. Sert M1.
**Jouable quand :** un écran sans décor affiche le gagné du jour, au centime ; fermer le jeu, mettre le PC en veille ou changer d'horaires ne fausse rien.

| Story | Contenu |
|---|---|
| 0.1 | Retirer du dépôt les deux installeurs `potato_rotato` et le `.crdownload` |
| 0.2 | Créer le projet de jeu à côté de l'app v1, avec ses tests automatiques |
| 0.3 | Horloge : heure, jour (bascule à 4 h), saison ; remplaçable par une horloge de test |
| 0.4 | Salaire en centimes entiers : formule, jours travaillés, horaires, pause déjeuner |
| 0.5 | Journal des jours et rattrapage hors ligne, plafonné à 31 jours ; horloge reculée sans perte |
| 0.6 | Jours particuliers : congé, férié, sans solde ; pointage manuel |
| 0.7 | Sauvegarde locale versionnée, 3 copies de secours, en moins de 50 ms |
| 0.8 | Reprise des réglages de salaire de la v1 au premier lancement |

---

## Epic 1 — Le bocal et le widget

**Objectif :** voir et manipuler son argent, travailler avec le widget. Sert M2, M13.
**Jouable quand :** les pièces dessinées tombent au rythme du salaire, on peut les attraper et secouer le bocal ; le widget tient dans un coin de l'écran pendant qu'on travaille.
**Jalon :** Parité v1.

| Story | Contenu |
|---|---|
| 1.1 | Les 17 coupures et la table de fusion |
| 1.2 | Chute, collisions et repos des espèces en 2.5D ; 60 images/s à 200 objets |
| 1.3 | Trois tailles de bocal, jauge de remplissage, fusion paresseuse |
| 1.4 | Attraper et lancer une pièce, secouer, tapoter ; effet « coussin » |
| 1.5 | Débordement sur le comptoir (24 objets au plus) |
| 1.6 | Pluie de rattrapage ; bocal retrouvé à l'identique au lancement |
| 1.7 | Widget : trois formats, premier plan, fond transparent, position et opacité mémorisées |
| 1.8 | Bascule maison ↔ widget, mode discret, icône de la zone de notification |
| 1.9 | Tintements selon la coupure, 8 simultanés au plus |

---

## Epic 2 — La maison

**Objectif :** un lieu où l'on a envie de rester. Sert M12, pilier 4.
**Jouable quand :** on balaie la maison d'un bout à l'autre, les objets réagissent au survol, la lumière et la météo suivent le monde réel.

| Story | Contenu |
|---|---|
| 2.1 | Décor en plans séparés, 2 écrans de large, parallaxe à la souris |
| 2.2 | Objets interactifs : survol, clic, gros plan, retour |
| 2.3 | Cinq ambiances de lumière fondues selon l'heure et le soleil ; halos des sources chaudes |
| 2.4 | Météo de la ville saisie, choix manuel, repli hors ligne |
| 2.5 | Habillage des quatre saisons |
| 2.6 | Le bocal posé sur le comptoir et son gros plan |
| 2.7 | Calendrier mural et ticket du soir |
| 2.8 | Fiche de paie complète, ville, format du widget : tous les réglages sont des objets |

---

## Epic 3 — La fournée

**Objectif :** un focus fabrique une pâtisserie. Sert M4 (livres), M8.
**Jouable quand :** on ouvre un livre, on lance les cookies, on travaille 25 min avec le widget, on défourne.

| Story | Contenu |
|---|---|
| 3.1 | Les 6 recettes de la v1 reprises, avec ingrédients chiffrés et ustensiles |
| 3.2 | Livre lisible : double page, feuilletage en 0,25 s |
| 3.3 | Garde-manger et kit de départ |
| 3.4 | Minuteur de focus et de pause : réglages, mise en attente, exact après une veille |
| 3.5 | Lancer une recette : conditions, préparation en 3 à 5 gestes, saut |
| 3.6 | Focus en widget avec phrases d'ambiance ; mode strict ou libre |
| 3.7 | Fin de focus, pause, phase suivante, pause longue après 4 focus |
| 3.8 | Défourner ; maîtrise ★ à ★★★ ; dorure parfaite ; part à offrir |
| 3.9 | Fournée ratée : ingrédients perdus, nettoyage d'un geste |
| 3.10 | Minuteur seul, avec la théière |

---

## Epic 4 — La vitrine

**Objectif :** montrer ce qu'on a fait, à sa façon. Sert M9.
**Jouable quand :** chaque recette réussie devient une pièce qu'on glisse d'une étagère à une cloche.

| Story | Contenu |
|---|---|
| 4.1 | Surfaces et emplacements : 3 cloches, 2 étagères, largeurs 1 à 3 |
| 4.2 | Glisser-déposer : soulever, accrocher, échanger, revenir |
| 4.3 | Pièces de vitrine en trois niveaux de maîtrise ; étiquette kraft |
| 4.4 | Buffet pour les pièces retirées |
| 4.5 | Arrangement conservé |
| 4.6 | Objets de décoration plaçables de la même manière |

---

## Epic 5 — La rue et la banque

**Objectif :** sortir de chez soi et rendre son argent dépensable. Sert M3, M5.
**Jouable quand :** on verse le bocal dans la sacoche, on sort, un clic sur le guichet de la banque et le livret affiche le dépôt.

| Story | Contenu |
|---|---|
| 5.1 | La rue : une vue fixe depuis le seuil de la pâtisserie, avec la banque et l'épicerie en face |
| 5.2 | Passages maison ↔ rue ↔ épicerie en moins de 0,7 s |
| 5.3 | Verser le bocal dans la sacoche |
| 5.4 | Guichet de la banque : dépôt en un clic, compte |
| 5.5 | Livret : opérations, tickets du soir, compteurs |
| 5.6 | Douze petites scènes de rue, une par sortie |
| 5.7 | Lumière, météo et saisons dans la rue |
| 5.8 | Passage du facteur après 10 dépôts |

---

## Epic 6 — L'épicerie et Honoré

**Objectif :** dépenser son argent pour ce que demandent les recettes, auprès de quelqu'un. Sert M4 (bloc-notes), M6, M7.
**Jouable quand :** on écrit sa liste, on remplit le panier, Honoré commente, on paie, le garde-manger est plein au retour.
**Jalon :** Tranche verticale.

| Story | Contenu |
|---|---|
| 6.1 | Bloc-notes : écriture libre, barrer, pages, aide « recopier » |
| 6.2 | Rayons, panier, total ; 24 ingrédients aux prix du GDD |
| 6.3 | Paiement en un geste ; panier mis de côté si le compte ne suffit pas ; cabas |
| 6.4 | Dialogues : répliques conditionnelles, choix, sujets |
| 6.5 | Honoré : salutations selon l'heure, la météo, la saison, l'affinité et le panier ; 5 expressions |
| 6.6 | Affinité, quatre paliers, rayons débloqués |
| 6.7 | Offrir une part : une réaction par recette |
| 6.8 | Après 20 h : la sonnette |
| 6.9 | Ustensiles et produits éphémères |

---

## Epic 7 — Chips

**Objectif :** un compagnon qui vit sa vie et annonce les pauses. Sert M11.
**Jouable quand :** Chips n'est jamais deux fois au même endroit dans la journée et saute sur le plan de travail à la fin d'un focus.

| Story | Contenu |
|---|---|
| 7.1 | Routine horaire sur 7 créneaux |
| 7.2 | Événements prioritaires : fin de focus et empreintes de farine, four, pluie, débordement, sacoche, fin de journée |
| 7.3 | Caresse, ronronnement, gamelle |
| 7.4 | Chips guide le premier lancement par le regard |
| 7.5 | Les pattes de Chips sur le widget pendant les pauses |
| 7.6 | Objets rapportés, un par semaine au plus |

---

## Epic 8 — Le carnet de commandes

**Objectif :** des buts choisis, jamais imposés. Sert M10.
**Jouable quand :** cinq petits mots attendent chaque matin sur le tableau, on en garde trois, on reçoit un tampon et une récompense.

| Story | Contenu |
|---|---|
| 8.1 | 40 modèles de petits mots en 6 familles |
| 8.2 | Tirage quotidien et tableau de liège |
| 8.3 | Épingler et désépingler, trois au plus |
| 8.4 | Avancement et tampon |
| 8.5 | Récompenses : page volante, décoration, disque, carte postale, affinité, mot doux |

---

## Epic 9 — Sons et musique

**Objectif :** une ambiance qu'on règle comme un poste. Sert l'audio du GDD.
**Jouable quand :** chaque famille de sons a son curseur et la pluie s'entend derrière la porte.

| Story | Contenu |
|---|---|
| 9.1 | Six familles et leurs curseurs, portés par le poste de musique |
| 9.2 | Ambiances par lieu, heure et météo ; extérieur étouffé porte fermée |
| 9.3 | Disques et dossier de musique personnel |
| 9.4 | Étude : radios en ligne |
| 9.5 | Sons de cuisine et d'objets (≈ 90) |

---

## Epic 10 — Contenu et secrets

**Objectif :** de quoi jouer plusieurs mois, et la couche intime du cadeau. Sert M6 (catalogue), piliers 3 et 4.
**Jouable quand :** on commande un meuble livré le lendemain, on ouvre le livre 2, on trouve un mot doux derrière un cadre.

| Story | Contenu |
|---|---|
| 10.1 | Catalogue : commande, livraison le lendemain, colis |
| 10.2 | Livres 2 et 3 : 12 recettes |
| 10.3 | Recettes et produits de saison |
| 10.4 | 20 secrets du décor ; pack de contenu privé hors dépôt |
| 10.5 | Lettres de complétude |
| 10.6 | Répliques et anecdotes d'Honoré (≈ 250 lignes) |

---

## Epic 11 — Finition et sortie

**Objectif :** un cadeau qu'on installe en un clic et un dépôt qu'on peut montrer.
**Jouable quand :** une personne qui ne connaît pas le jeu l'installe, règle son salaire et lance sa première fournée en 5 minutes.

| Story | Contenu |
|---|---|
| 11.1 | Premier lancement en 5 minutes |
| 11.2 | Accessibilité : tailles de texte, écriture lisible, mouvements réduits |
| 11.3 | Tenue des sept cibles de performance |
| 11.4 | Installeur Windows, lancement au démarrage, instance unique |
| 11.5 | Dépôt public : présentation, licences, publication automatique |
| 11.6 | Retrait de l'app Electron du dépôt |

---

## Après la version cadeau

| Epic | Contenu |
|---|---|
| Jardin | Plantes, soin, herbier (repris de la v1) |
| Grands projets | Objectifs d'épargne qui transforment la maison ou la rue |
| Le village | Autres commerces, autres personnages |
| Radios en ligne | Selon le résultat de l'étude 9.4 |
| Ouverture | Anglais, Linux, macOS |
