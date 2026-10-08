---
title: 'MoneyMaker — Game Design Document (refonte)'
game_type: 'simulation'
game_type_secondary: ['idle-incremental', 'adventure']
platforms: ['Windows 10/11 x64']
engine: 'Godot 4.7'
author: 'Victor'
created: '2026-10-08'
updated: '2026-10-08'
status: 'validé par Victor le 2026-10-08'
supersedes: '_bmad-output/archive-v1-electron/gdd.md'
inputDocuments:
  - 'brainstorming-session-2026-10-08.md'
  - 'archive-v1-electron/game-brief.md'
  - 'archive-v1-electron/gdd.md'
  - 'réponses de Victor du 2026-10-08 (voir decision-log.md)'
---

# MoneyMaker - Game Design Document

**Author:** Victor
**Game Type:** Simulation cozy (principal) · Idle (gains passifs) · Aventure point-and-click (PNJ, exploration)
**Target Platform(s):** Windows 10/11 x64

> Ce document remplace le GDD de la v1 (Electron). Il décrit **ce que la joueuse vit**, pas comment c'est construit : l'architecture est dans `game-architecture.md`.
> Victor a validé ce document le 8 octobre 2026 (voir `decision-log.md`). Aucune hypothèse ne reste ouverte.
> Modifié le même jour après son premier essai : fusion à la main et bocal qu'on secoue en entier (M2, D28 et D29).

---

## Lexique

Chaque terme a un seul sens dans tout le document.

| Terme | Définition |
|---|---|
| **Espèces** | Pièces et billets présents dans le bocal. Non dépensables. |
| **Bocal** | Récipient en verre où tombent les espèces. Trois tailles : **Pot** (1 jour de salaire), **Bocal** (1 semaine), **Bonbonne** (1 mois). |
| **Sacoche** | Sac de toile dans lequel on verse le bocal pour l'emporter à la banque. |
| **Guichet** | Poste de dépôt sur la façade de la banque, dans la rue. Un clic y dépose la sacoche. |
| **Compte** | Solde bancaire. Seul argent dépensable. |
| **Livret** | Carnet bancaire posé à la maison : liste des dépôts, achats et tickets du soir. |
| **Garde-manger** | Stock d'ingrédients de la maison. |
| **Livre de recettes** | Objet lisible contenant 6 recettes. |
| **Phase** | Étape d'une recette. Une phase = un focus. |
| **Focus** | Bloc de concentration chronométré (25 min par défaut). |
| **Pause** | Bloc de repos entre deux focus (5 min, ou 15 min après 4 focus). |
| **Fournée** | Exécution complète d'une recette, de la première à la dernière phase. |
| **Vitrine** | L'ensemble des surfaces d'exposition : cloches du comptoir et étagères. |
| **Pièce de vitrine** | La pâtisserie exposée. Une par recette réussie au moins une fois. |
| **Part à offrir** | Exemplaire d'une fournée rangé dans la boîte à gâteaux, destiné à être offert. |
| **Bloc-notes** | Papier libre où la joueuse écrit sa liste de courses. |
| **Petit mot** | Une quête proposée. |
| **Carnet de commandes** | Carnet où sont épinglés les petits mots acceptés (3 maximum). |
| **Affinité** | Niveau de relation avec Honoré, l'épicier. |
| **Widget** | Petite fenêtre toujours visible, utilisée pendant le travail. |

---

## Executive Summary

### Core Concept

Le salaire réel de la joueuse tombe en temps réel, centime par centime, dans un bocal posé sur le comptoir de sa pâtisserie. Les pièces et les billets sont dessinés à la main et ont de la profondeur : on peut les attraper, les lancer, secouer le bocal.

Pour dépenser cet argent, elle verse le bocal dans une sacoche, sort sur le pas de sa porte et le dépose d'un clic au guichet de la banque, juste en face. Avec son compte, elle achète chez Honoré, l'épicier voisin de la banque, les ingrédients des recettes qu'elle a lues dans ses livres et notées elle-même sur son bloc-notes.

Chaque session de concentration (Pomodoro) est une fournée : la recette avance d'une phase par focus, et la pâtisserie terminée rejoint la vitrine, qu'elle arrange à la main.

**Fantasme central :** « Mon travail d'aujourd'hui tinte dans un bocal, et ce soir il sent le beurre chaud. »

### Target Audience

| | Profil | Usage type |
|---|---|---|
| **Principale** | La compagne de Victor. Joueuse occasionnelle, aime Animal Crossing, Valheim, l'univers Lo-Fi Girl. Travaille sur PC. | Jeu ouvert toute la journée de travail en widget. 4 à 8 visites de 2 à 5 min pendant les pauses. 10 à 20 min le soir, facultatif. |
| **Secondaire** | Victor, puis toute personne travaillant sur ordinateur qui trouve le dépôt public. | Identique, sans le contenu privé. |

Conséquence : le jeu contient deux couches de contenu. Le **contenu public** est dans le dépôt. Le **contenu privé** (mots doux, secrets personnels) vit dans un pack séparé, jamais publié.

### Unique Selling Points (USPs)

1. **L'argent du jeu est le vrai salaire, à l'euro près.** Aucune autre source de revenu n'existe dans le jeu.
2. **L'argent est une matière.** Pièces et billets dessinés, en 2.5D, avec poids, son et volume.
3. **Un Pomodoro fabrique quelque chose.** Chaque focus fait avancer une recette ; chaque recette finie devient un objet exposé.
4. **Aucune interface flottante.** Toute information est portée par un objet du décor.
5. **On planifie à la main.** La liste de courses est écrite par la joueuse, le jeu ne la vérifie pas.

---

## Goals and Context

### Project Goals

| # | Objectif | Critère |
|---|---|---|
| G1 | Cadeau réussi | La destinataire lance le jeu d'elle-même chaque jour travaillé pendant 4 semaines. |
| G2 | Refonte complète | Le jeu Godot remplace l'app Electron v1.1.2 ; la boucle gagner → déposer → acheter → cuire → exposer est jouable de bout en bout. |
| G3 | Dépôt publiable | Aucun contenu privé, aucun binaire tiers, licences d'assets identifiées. |
| G4 | Soutenable en solo | Chaque epic livre une tranche jouable seule. |

### Background and Rationale

La v1.1.2 (Electron + React) affiche le salaire et simule un bocal, mais la boucle de jeu n'est pas fermée : l'argent ne sert à rien, finir une recette ne produit rien, il n'y a ni quête ni sauvegarde de progression (diagnostic complet dans `brainstorming-session-2026-10-08.md`).

Le 8 octobre 2026, Victor a tranché : le projet devient un jeu, avec un épicier, un trajet jusqu'à sa boutique, une banque, des livres de recettes et une vitrine à arranger. Ces besoins (scènes, personnage, dialogues, placement d'objets, profondeur 2.5D) relèvent d'un moteur de jeu.

---

## Core Gameplay

### Game Pillars

| # | Pilier | Ce qu'il impose | Test de décision |
|---|---|---|---|
| 1 | **Sérénité productive** | Le travail réel passe avant le jeu. Le jeu se tait pendant un focus. Aucune pression de temps hors du minuteur choisi. | « Est-ce que ça peut interrompre ou culpabiliser quelqu'un qui travaille ? » Si oui, on coupe. |
| 2 | **Abondance tangible et honnête** | L'argent a un poids, un son, un volume, et vaut exactement le salaire réel. | « Cet euro existe-t-il dans la vraie vie ? Peut-on le voir et le toucher ? » |
| 3 | **Compagnonnage affectif** | La joueuse n'est jamais seule : Chips vit sa vie à côté d'elle, Honoré la reconnaît, le décor cache des attentions. | « Qui, dans le monde du jeu, remarque ce que la joueuse vient de faire ? » |
| 4 | **Tout est dans le décor** | Aucune interface flottante. Chaque information et chaque action passe par un objet. | « Où est l'objet ? » S'il n'y en a pas, la fonction n'entre pas. |

**Priorité en cas de conflit :** 1 > 2 > 3 > 4.

**Règles de conception** (dérivées des piliers et des arbitrages de Victor) :

- **R1 — Un geste, pas une corvée.** Toute action répétée se fait en un clic ou un glisser. Rien ne demande de trier, compter ou aligner à la main.
- **R2 — Proposer, ne jamais imposer.** Les quêtes se choisissent dans un pool, les pauses se prennent ou non, tout rituel peut être sauté.
- **R3 — Aucun profit fictif.** Aucune récompense n'est de l'argent. Aucun objet n'augmente les gains.
- **R4 — Rien d'irréversible.** Pas de dette, pas de péremption, pas de compteur de jours consécutifs.

### Core Gameplay Loop

Trois boucles imbriquées.

**Boucle du focus (25 + 5 min)**

1. Choisir une recette dans un livre (ou le minuteur seul).
2. Préparer : 3 à 5 gestes, 45 s au plus.
3. Focus : la phase cuit, le jeu passe en widget, le salaire continue de tomber.
4. Chips saute sur le plan de travail fariné : c'est la pause.
5. Pause : défourner, placer en vitrine, lire, noter, sortir.
6. Phase suivante, ou nouvelle recette.

**Boucle des courses (1 à 3 fois par semaine, 1 à 3 min)**

1. Lire un livre, vérifier le garde-manger, écrire sa liste.
2. Verser le bocal dans la sacoche.
3. Sortir : la rue montre la banque et l'épicerie, en face. Un clic sur le guichet dépose la sacoche.
4. Entrer chez Honoré : discuter, remplir le panier, payer.
5. Rentrer : le garde-manger est rempli, de nouvelles recettes sont possibles.

**Boucle longue (semaines et mois)**

Compléter un livre → remplir et arranger la vitrine → maîtriser les recettes → gagner l'affinité d'Honoré → commander meubles et ustensiles au catalogue → nouvelles saisons.

**Ce qui donne envie de revenir :** la vitrine qui se remplit, les petits mots du jour, ce qu'Honoré a à raconter, l'endroit où Chips s'est installé.

### Win/Loss Conditions

- **Pas de défaite.** Aucun état de jeu ne bloque la joueuse ni ne lui retire de l'argent déposé.
- **Fournée ratée (seul échec, hérité de la v1).** Abandonner un focus avant la fin fait retomber la préparation : les ingrédients de la recette sont perdus, Chips pousse un miaulement d'encouragement, le plan de travail se nettoie d'un geste. Coût : 1 à 10 € selon la recette. Aucun effet sur le salaire, l'affinité ou les quêtes.
- **Accomplissements, sans fin de partie :**
  - Livre complété : ses 6 recettes sont en vitrine.
  - Recette maîtrisée : 15 fournées.
  - Affinité maximale avec Honoré.
  - Tous les livres maîtrisés : un dernier message, tiré du contenu privé.

---

## Game Mechanics

### Primary Mechanics

Chaque mécanique indique les piliers qu'elle sert.

#### M1 — Gagner (piliers 2, 1)

- La joueuse saisit son **net mensuel**, ses **jours travaillés**, ses **horaires** et sa **pause déjeuner** sur une fiche de paie posée sur le bureau.
- Taux horaire = net mensuel ÷ heures mensuelles, avec heures mensuelles = heures hebdomadaires × 52 ÷ 12.
- L'argent tombe uniquement pendant les heures travaillées. Exemple : 2 000 € net, 35 h/semaine → 13,19 €/h → 1 centime toutes les 2,7 s → 92,31 € par jour.
- Tous les montants sont comptés en centimes entiers. Le total d'une journée complète est exact au centime.
- `[NOTE FOR DESIGNER]` Avec cette formule (celle de la v1), un mois de 23 jours ouvrés rapporte un peu plus que le net et un mois de 20 jours un peu moins. Variante possible : recalculer le taux chaque mois pour que le mois tombe pile sur le net.
- **Hors ligne :** au lancement, le jeu crédite les heures travaillées écoulées depuis la dernière fermeture, plafonnées à 31 jours. Ces espèces tombent en une **pluie de rattrapage** de 8 s au plus.
- **Pointage manuel** (option) : la joueuse démarre et arrête sa journée elle-même au lieu de suivre l'horaire.
- **Jours particuliers :** un jour peut être marqué « congé » ou « férié » sur le calendrier mural. Un jour marqué « congé » ou « férié » reste payé (salaire mensuel), un jour marqué « sans solde » ne l'est pas.
- Changer de salaire ou d'horaires ne modifie jamais les jours déjà clos. La journée en cours est recalculée avec les nouveaux réglages ; si le nouveau total est inférieur à ce qui est déjà tombé, rien n'est repris.

#### M2 — Le bocal (piliers 2, 3)

- Chaque centime gagné fait tomber une pièce dessinée dans le bocal.
- **Le niveau du bocal est une jauge :** plein à ras bord = la capacité de sa taille.

| Taille | Capacité | Objets quand il est plein | Obtention |
|---|---|---|---|
| Pot | 1 jour de net | 90 | Départ |
| Bocal | 1 semaine de net | 160 | Catalogue, 12 € |
| Bonbonne | 1 mois de net | 240 | Catalogue, 45 € |

- **Fusion paresseuse :** le nombre d'objets visibles ne dépasse pas le remplissage (remplissage × objets-quand-plein, minimum 12). Quand il y a un objet de trop, deux ou trois coupures fusionnent en une plus grosse (2 × 1 c → 2 c, etc. ; table de fusion reprise de la v1), une seule fusion à la fois. Le choix de la fusion garde au bocal ses proportions : beaucoup de pièces de 1 et 2 €, de la petite monnaie, peu de billets. Un Pot plein à 2 000 € net contient ainsi environ 85 pièces et 4 billets. Cette fusion-là est automatique, accompagnée d'un petit « pouf ».
- **Fusion à la main** (ajoutée le 8 octobre 2026 à la demande de Victor, comme dans la v1) : la joueuse fait glisser une coupure sur une semblable et elles fusionnent en une plus grosse, qui reste dans sa main ; en continuant de glisser, elle fait de plus en plus gros. Même table de fusion ; pour une fusion à trois (2 € + 2 € + 1 € → 5 €), la troisième coupure vient d'elle-même du bocal, et trois pareilles rendent la monnaie (3 × 2 c → 5 c + 1 c). **Le bocal ne défait jamais ce que la main a fait :** il compte alors moins d'objets que son niveau n'en demande, et les centimes suivants tombent sans fusionner jusqu'à ce que le compte y soit de nouveau.
- **Débordement :** le bocal est ouvert. Au-delà de 100 %, il accepte jusqu'à 24 objets de plus : le tas dépasse du bord et des pièces roulent sur le comptoir. Rien n'est perdu.
- **Jouer :** attraper et lancer une pièce, fusionner des coupures, tapoter la vitre (clic), **secouer le bocal entier** en le saisissant par le verre (ou, sur le comptoir, en le faisant glisser ; touche Espace en gros plan ; en mini-bocal, en déplaçant le widget). Une pièce tombée dehors retourne d'elle-même dans le bocal tant qu'il y a de la place. Aucune récompense, aucune conséquence.
- **Sensation « coussin » :** les pièces gonflent légèrement à l'impact puis reprennent leur forme en 0,15 s. Rebond faible : une pièce lâchée de la hauteur du bocal s'immobilise en moins de 1,5 s.
- **Coupures :** 8 pièces (1 c à 2 €), 7 billets (5 € à 500 €), lingot (1 000 €), gemme (10 000 €).

#### M3 — Déposer (piliers 2, 4)

- À la maison, un clic sur la sacoche y verse **tout** le bocal (animation de 2 s).
- Dans la rue, un clic sur le guichet de la banque dépose la sacoche et crédite le compte (animation de 3 s : clapet, tampon).
- Sacoche vide : le guichet reste fermé, sans message.
- Le livret reçoit une ligne manuscrite : date, « Dépôt », montant, nouveau solde.
- Ni intérêts, ni frais, ni découvert.
- **Passage du facteur :** après 10 dépôts à la main, la joueuse peut demander au facteur d'emporter le bocal chaque matin travaillé. Option désactivable.

#### M4 — Lire et noter (piliers 4, R2)

- Les livres sont rangés sur une étagère de la cuisine. Un clic ouvre le livre en gros plan.
- Chaque recette occupe une double page : illustration, ingrédients avec quantités, ustensiles requis, phases avec leur durée, instructions réelles.
- Feuilletage : clic sur un coin de page ou flèches du clavier. La page tourne en 0,25 s.
- **Bloc-notes :** accessible partout (poche du tablier, coin inférieur gauche de l'écran). La joueuse y tape du texte libre, affiché en écriture manuscrite. 12 lignes de 28 caractères par page, 5 pages. Un clic dans la marge barre une ligne. Un glisser vers le haut arrache la page.
- Le jeu ne lit jamais le bloc-notes et ne signale jamais un oubli.
- **Aide facultative « recopier »** (désactivée par défaut) : un clic sur un ingrédient du livre l'ajoute au bloc-notes.
- **Garde-manger :** un clic ouvre le placard. Chaque ingrédient est un bocal étiqueté dont le niveau et l'étiquette indiquent la quantité restante.

#### M5 — Sortir (piliers 3, 4)

- Trois lieux : **Maison ↔ Rue ↔ Épicerie**. Un clic sur une porte suffit pour passer de l'un à l'autre.
- **La rue est une vue fixe**, d'un seul écran : ce qu'on voit depuis le seuil de la pâtisserie, en regardant en face. On y voit la banque et son guichet, et la devanture de l'épicerie.
- Pas de marche, pas de personnage à l'écran. Le décor garde sa profondeur : ses plans se décalent avec la souris.
- Trois objets répondent au clic : le guichet de la banque (déposer), la porte de l'épicerie (entrer), le seuil (rentrer).
- La rue suit l'heure, la météo et la saison réelles.
- À chaque sortie, une **petite scène** tirée d'un pool de 12 (le chat du voisin sur le mur, un vélo appuyé, du linge qui sèche, des feuilles qui tombent…). Aucune n'exige d'action.
- L'épicerie est toujours accessible. Après 20 h, il faut sonner : Honoré descend en gilet, avec des répliques dédiées.

#### M6 — Faire ses courses (piliers 2, 3)

- Dans l'épicerie, un clic sur un produit en rayon le pose dans le panier du comptoir. Un clic dans le panier le remet en rayon.
- **Prix réels, en euros** (table dans « Economy and Resources »).
- « L'addition, s'il vous plaît » : Honoré annonce le total. Si le compte suffit, le paiement se fait en un geste (un chèque se remplit tout seul en 2 s), le livret reçoit une ligne, les produits rejoignent le garde-manger au retour à la maison.
- Si le compte ne suffit pas, Honoré le dit sans reproche et met le panier de côté. Pas de crédit.
- **Catalogue :** dès l'affinité « Habituée », un catalogue de vente par correspondance permet de commander ustensiles, meubles et décoration. Livraison le jour réel suivant, dans un colis posé devant la porte. Une commande à la fois.

#### M7 — Parler à Honoré (pilier 3)

- Honoré salue la joueuse à chaque entrée : 2 à 4 répliques, variables selon l'heure (4 créneaux), la météo (5 états), la saison (4), l'affinité (4 paliers) et le contenu du panier.
- Un menu propose jusqu'à 3 sujets : « Des nouvelles du village ? », « Un conseil ? », « Je vous ai apporté quelque chose ».
- Les choix de réponse (2 ou 3) n'ont jamais de mauvaise issue. L'affinité ne baisse jamais.
- **Affinité :** +1 par jour de visite, +3 par part offerte (une par jour), +2 par petit mot d'Honoré terminé.

| Palier | Seuil | Débloque |
|---|---|---|
| Cliente | 0 | Rayons de base |
| Habituée | 10 | Catalogue, rayon ustensiles |
| Amie | 30 | Ingrédients rares, livre offert, anecdotes du village |
| De la famille | 70 | Histoire personnelle d'Honoré, recette de sa mère |

- Chaque recette offerte déclenche une réplique unique d'Honoré (18 répliques en v1.0).

#### M8 — La fournée (piliers 1, 2)

- **Lancer :** ouvrir un livre à une recette, cliquer sur le minuteur de cuisine. Conditions : tous les ingrédients et ustensiles de la recette sont à la maison.
- **Préparation :** 3 à 5 gestes (verser, casser, mélanger), un clic ou un glisser chacun, 45 s au plus. Un clic sur le tablier saute la préparation.
- **Phases :** une recette compte 1, 2 ou 4 phases. Chaque phase dure un focus.

| Réglage | Défaut | Plage |
|---|---|---|
| Focus | 25 min | 15 à 60 min, par pas de 5 |
| Pause courte | 5 min | 3 à 15 min |
| Pause longue (après 4 focus) | 15 min | 10 à 30 min |

- **Pendant le focus :** le jeu passe en widget. Les phrases d'ambiance de la phase (7 à 9 par phase, reprises de la v1) se succèdent à intervalles réguliers.
- **Mode strict :** pendant un focus, la maison est en veilleuse. On la voit (four allumé, Chips, minuteur) mais les livres, la vitrine, le bocal, le bloc-notes et la porte ne répondent pas ; seuls le minuteur et le retour au widget répondent. Tout redevient accessible à la pause.
- **Mode libre :** rien n'est bloqué pendant un focus.
- Le mode strict est actif par défaut ; la joueuse peut passer en mode libre dans les réglages.
- **Mettre en attente :** un clic sur le minuteur l'arrête, un second le relance. Sans limite.
- **Fin de focus :** un tintement unique, Chips saute sur le plan de travail. La pause démarre seule. À la fin de la pause, Chips redescend, double tintement, la phase suivante est proposée sans démarrer d'elle-même.
- **Fin de recette :** un geste pour défourner. La pâtisserie apparaît sur la grille. Première réussite : une nouvelle pièce de vitrine à placer. Chaque fournée ajoute une part à offrir dans la boîte à gâteaux (6 au plus).
- **Maîtrise :** 1 fournée ★, 5 fournées ★★, 15 fournées ★★★. Chaque étoile enrichit le rendu de la pièce de vitrine (★★ : assiette de porcelaine ; ★★★ : dorure et cloche).
- **Dorure parfaite :** une fournée terminée sans mise en attente ni abandon ajoute une coche dorée sur la fiche de la recette. Sans autre effet.
- **Minuteur seul :** toujours disponible, sans ingrédient. Une théière infuse à la place du four. Compte comme un focus pour les petits mots.

#### M9 — Exposer et arranger (piliers 2, 4, R1)

- Au départ : 3 cloches sur le comptoir et 2 étagères murales de 6 emplacements, soit 15 emplacements.
- Les pièces de vitrine ont une largeur de 1, 2 ou 3 emplacements.
- **Glisser-déposer :** maintenir le clic soulève la pièce (12 px, ombre portée). La relâcher au-dessus d'une surface la pose à l'emplacement libre le plus proche. La relâcher ailleurs la renvoie à sa place en 0,2 s. La déposer sur une cloche occupée échange les deux pièces.
- Un clic simple sur une pièce affiche son étiquette kraft : nom, date de la première fournée, nombre de fournées, étoiles.
- L'arrangement est conservé d'une session à l'autre.
- Le catalogue vend des surfaces supplémentaires (voir économie).

#### M10 — Le carnet de commandes (pilier 3, R2, R3)

- Chaque jour, au premier lancement après 4 h du matin, **5 petits mots** apparaissent sur le tableau de liège près de la porte.
- La joueuse en épingle jusqu'à **3** dans son carnet. Les autres restent sur le tableau jusqu'au lendemain.
- Un petit mot épinglé n'expire jamais. Le désépingler est gratuit.
- Pool de la v1.0 : 40 modèles répartis en 6 familles.

| Famille | Exemple |
|---|---|
| Fournée | « Deux fournées avant midi », « Une focaccia pour l'école » |
| Courses | « Goûte le miel de châtaignier » |
| Vitrine | « Une étagère rien qu'avec des tartes » |
| Relation | « Apporte une part à Honoré » |
| Rituel | « Dépose ton bocal un vendredi », « Quatre focus aujourd'hui » |
| Découverte | « Sors sous la pluie », « Lis un livre jusqu'à la dernière page » |

- **Récompenses, jamais de l'argent :** un tampon dans le carnet (toujours), plus l'une de ces choses : page de recette volante, objet de décoration, disque, carte postale, affinité, mot doux (contenu privé).
- Les auteurs sont des villageois qu'on ne voit jamais (Mme Lucie, le facteur, les enfants de l'école) et Honoré.

#### M11 — Chips (pilier 3, 1)

- Chips suit une **routine** calée sur l'heure réelle :

| Heure | Endroit |
|---|---|
| 6 h – 9 h | Rebord de la fenêtre |
| 9 h – 12 h | Tache de soleil près de la porte |
| 12 h – 14 h | Chaise |
| 14 h – 17 h | Étagère basse ou panier |
| 17 h – 19 h | Devant la porte |
| 19 h – 23 h | Près du four |
| 23 h – 6 h | Coussin, roulé en boule |

- Chips change de place au plus une fois toutes les 20 min, d'un bond de 0,6 s ou pendant que la joueuse regarde ailleurs.
- **Événements prioritaires :**

| Événement | Réaction de Chips |
|---|---|
| Fin d'un focus | Saute sur le plan de travail fariné et y reste toute la pause. Ses empreintes de farine s'effacent en 10 min. |
| 5 dernières minutes d'une cuisson | S'assoit devant la vitre du four |
| Pluie | Rebord de la fenêtre |
| Bocal qui déborde | Fait rouler une pièce du bout de la patte |
| Sacoche pleine posée | S'assoit dessus ; un clic le déloge |
| Fournée ratée | Miaulement d'encouragement |
| Heure de fin de journée dépassée de 30 min | Assis devant la porte, regarde la joueuse |

- **Caresser :** maintenir le clic 1 s déclenche le ronronnement (son, et légère vibration de l'image de Chips).
- **Gamelle :** remplir la gamelle (croquettes achetées chez Honoré) déclenche une animation. Chips n'a ni faim ni humeur mesurée.
- **Guide discret :** au premier lancement, Chips regarde tour à tour le bocal, les livres, le minuteur. C'est le seul tutoriel.
- **Surprises :** une fois par semaine au plus, Chips rapporte un objet trouvé (bouton, plume, pièce ancienne).
- Dans le widget, les pattes de Chips apparaissent sur le bord pendant les pauses.

#### M12 — Le temps réel (piliers 3, 4)

- **Lumière :** cinq ambiances fondues en continu selon l'heure locale et la position du soleil — aube, jour, heure dorée, heure bleue, nuit.
- **Météo :** celle de la ville saisie par la joueuse (clair, nuageux, pluie, neige, brouillard), ou un choix manuel. Sans connexion : dernière météo connue.
- **Saisons :** 4 habillages du décor et de la rue ; certains produits et recettes sont saisonniers.
- **Ticket du soir :** à l'heure de fin de journée, la caisse imprime un ticket (heures travaillées, gagné aujourd'hui, focus, fournées). Il se range dans le livret.

#### M13 — Le widget (piliers 1, 2)

| Format | Taille | Contenu |
|---|---|---|
| Pastille | 180 × 64 | Gagné aujourd'hui |
| Bandeau | 320 × 96 | Gagné aujourd'hui, anneau du minuteur, phrase d'ambiance |
| Mini-bocal | 240 × 300 | Vue réduite du bocal, anneau du minuteur |

- Toujours au premier plan, déplaçable en le faisant glisser ; format, position et opacité (60 à 100 %) mémorisés.
- Clic droit : format suivant. Molette : plus ou moins opaque. Double-clic : retour à la maison.
- En pastille et en bandeau, le bocal est en pause : ce qui est gagné tombe au retour à la maison. En mini-bocal, il vit dans le widget.
- **Mode discret :** un raccourci clavier masque les montants, à la maison comme dans le widget.

### Controls and Input

| Action | Entrée | Retour |
|---|---|---|
| Interagir | Clic gauche | L'objet survolé s'éclaircit ; léger rebond au clic |
| Saisir, déplacer | Clic gauche maintenu + glisser | L'objet se soulève, ombre portée |
| Fusionner des coupures | Glisser une coupure sur une semblable | « Pouf » ; la nouvelle coupure reste en main |
| Secouer le bocal | Glisser le bocal (par le verre, en gros plan), ou Espace en gros plan | Le bocal suit la main, les pièces tintent |
| Changer de lieu | Clic sur une porte | Fondu de 0,4 s |
| Balayer la maison | Souris vers un bord, ou Q/D | Défilement horizontal doux |
| Feuilleter | Clic sur un coin de page, ←/→ | Bruit de papier, page tournée en 0,25 s |
| Écrire | Clavier, bloc-notes ouvert | Crayon qui gratte |
| Fermer un gros plan | Échap, clic droit, ou clic hors de l'objet | L'objet retourne à sa place |
| Minuteur : attente / reprise | Espace, ou clic sur le minuteur | Déclic mécanique |
| Mode discret | Ctrl + Maj + H | Les montants deviennent « •••• » |
| Maison ↔ widget | Ctrl + Maj + M, double-clic sur le widget, ou clic sur l'icône de la zone de notification | Transition de 0,4 s |
| Widget : format suivant | Clic droit sur le widget | Le widget change de taille |
| Widget : opacité | Molette sur le widget | Le widget s'éclaircit ou s'assombrit |

**Accessibilité**

- Taille des textes : 100 %, 125 %, 150 %.
- « Écriture lisible » : remplace l'écriture manuscrite par une police droite.
- « Mouvements réduits » : coupe la parallaxe et la vibration du ronronnement.
- Chaque coupure se distingue par sa taille et sa forme, pas seulement par sa couleur.
- Un curseur de volume par famille de sons.

---

## Simulation Specific Design

### Core Simulation Systems

Le jeu simule un **foyer et son petit commerce de quartier**, à l'échelle d'une personne, en temps réel. La simulation est abstraite : pas de péremption, pas de besoins, pas de marché.

| Système | Ce qu'il fait évoluer | Cadence |
|---|---|---|
| Horloge | Heure, jour, saison | Temps réel |
| Salaire | Espèces du bocal | 1 fois par seconde, plus rattrapage au lancement |
| Banque | Compte, livret | À chaque dépôt ou achat |
| Garde-manger | Stocks d'ingrédients | À chaque achat ou fournée |
| Recettes | Phase en cours, maîtrise | À chaque fin de focus |
| Vitrine | Emplacements | À chaque glisser-déposer |
| Affinité | Palier d'Honoré | À chaque visite, cadeau, petit mot |
| Petits mots | Tableau, carnet | Une fois par jour |
| Chips | Endroit, posture | Toutes les 20 min, plus événements |
| Ciel | Lumière, météo | Lumière en continu ; météo toutes les 30 min |

### Systems Map

```
        travail réel
             │ (horloge + fiche de paie)
             ▼
        ┌─────────┐  verser   ┌─────────┐  déposer  ┌─────────┐
        │  BOCAL  │──────────▶│ SACOCHE │──────────▶│ COMPTE  │
        │ espèces │           └─────────┘           │ livret  │
        └─────────┘                                 └────┬────┘
             ▲ jouer                                     │ payer
             │                                           ▼
           Chips ◀── fin de focus ──┐              ┌──────────┐
                                    │              │ ÉPICERIE │◀── affinité
        ┌──────────┐  lire/noter  ┌─┴────────┐     │  Honoré  │
        │  LIVRES  │─────────────▶│ FOURNÉE  │◀────│ produits │
        └──────────┘              │ (focus)  │     └──────────┘
                                  └─┬──────┬─┘      garde-manger
                     pièce de vitrine│      │part à offrir
                                    ▼      └────────────▶ Honoré, petits mots
                               ┌─────────┐
                               │ VITRINE │◀── catalogue (surfaces)
                               └─────────┘
```

Seule entrée d'argent : le salaire. Sorties d'argent : épicerie et catalogue. Rien ne reconvertit un objet en argent.

### Management Mechanics

| Ressource | Limite | Décision de la joueuse |
|---|---|---|
| Temps réel | Durée de la pause | Aller aux courses, lire, arranger, ou ne rien faire |
| Compte | Ce qui a été déposé | Quoi acheter d'abord |
| Garde-manger | Aucune limite de place | Quelle recette préparer avec ce qu'il y a |
| Vitrine | 15 emplacements au départ | Quoi montrer, où |
| Carnet | 3 petits mots | Lesquels garder |

**Automatisations disponibles :** passage du facteur (dépôt), aide « recopier » (liste). Toutes deux facultatives.

### Building and Construction

- **Objets plaçables :** pièces de vitrine (18 en v1.0), objets de décoration (30 en v1.0), surfaces supplémentaires (4).
- **Placement :** libre le long des surfaces (étagères, comptoir, rebords), avec accrochage à l'emplacement libre le plus proche. Pas de grille au sol.
- **Prérequis :** une pièce de vitrine demande sa recette réussie ; un objet de décoration demande son achat.
- **Contrainte d'espace :** 15 emplacements au départ, 39 avec toutes les surfaces du catalogue (étagère murale +6, présentoir à étages +6, étagère d'angle +4, vitrine de comptoir +8).
- **Rangement :** une pièce retirée de la vitrine va dans le buffet, sans limite.

### Economic and Resource Loops

- **Revenu :** le salaire réel, 1 pour 1. Rien d'autre.
- **Dépenses :** ingrédients (consommés), produits éphémères (une semaine), ustensiles, livres, bocaux, surfaces et décoration (permanents).
- **Pas d'entretien, pas d'inflation, pas de marché, pas de revente.**
- Tables de prix et simulation de budget : section « Economy and Resources ».

### Progression and Unlocks

| Déblocage | Condition |
|---|---|
| Rue, banque, épicerie | Premier versement dans la sacoche |
| Tableau de liège | Deuxième jour de jeu |
| Catalogue, rayon ustensiles | Affinité Habituée (10) |
| Ingrédients rares, livre offert | Affinité Amie (30) |
| Passage du facteur | 10 dépôts |
| Livres 2 et 3 | Achat (18 € et 22 €) |
| Recettes saisonnières | Saison en cours |
| Variante ★★ / ★★★ d'une pièce | 5 / 15 fournées |

### Sandbox vs. Scenario

Bac à sable uniquement. Pas de scénario, pas de mode défi, pas de remise à zéro.

### Long-Tail Balance

Durée de contenu de la v1.0, pour une joueuse qui réalise 3 fournées par jour travaillé :

| Contenu | Volume | Durée |
|---|---|---|
| Livre 1, toutes recettes ★ | 6 recettes, 14 focus | 1 semaine |
| 3 livres, toutes recettes ★ | 18 recettes | 4 à 5 semaines |
| Affinité maximale | 70 points, 4 à 6 par jour | 3 à 4 semaines |
| Maîtrise ★★★ de tout | 270 fournées, ≈ 630 focus | ≈ 5 mois à 6 focus par jour |
| Catalogue complet | 41 achats, ≈ 2 920 € | Limité par la livraison : 41 jours au minimum |
| Saisons | 4 habillages, 8 recettes saisonnières | 1 an |

Le salaire dépasse vite les dépenses possibles : une joueuse à 2 000 € net achète tout le catalogue en 2 mois. C'est voulu : le solde du livret qui grandit fait partie du plaisir. Les **grands projets** (reportés après la v1.0, voir Out of Scope) donneront un but à cette épargne.

### Emergence Boundaries

| Situation | Règle |
|---|---|
| Blocage sans ingrédients ni argent | Impossible : le minuteur seul fonctionne toujours, et le garde-manger de départ suffit pour 2 recettes |
| Horloge du PC reculée | Aucun argent n'est retiré ; une même date n'est jamais payée deux fois |
| Horloge du PC avancée | Crédité selon l'horaire, plafonné à 31 jours par lancement |
| Salaire saisi volontairement faux | Accepté. L'honnêteté est un contrat avec soi-même ; le jeu ne contrôle rien |
| Bocal jamais déposé | Débordement visuel, plafonné à 24 objets hors bocal ; la valeur reste exacte |
| Vitrine pleine | Les nouvelles pièces vont au buffet |
| Boîte à gâteaux pleine | La part la plus ancienne est mangée par « quelqu'un » (une miette, une trace de patte) |

### End State

Jeu sans fin. Trois paliers de complétude, chacun salué par une lettre :

1. Un livre complété → lettre d'Honoré.
2. Affinité « De la famille » → la recette de sa mère.
3. Tous les livres maîtrisés ★★★ → dernier mot doux du contenu privé (ou, sans contenu privé, une carte postale du village).

### Idle : gains hors ligne

- Le salaire est crédité pour les heures travaillées écoulées pendant que le jeu était fermé (voir M1).
- Aucun gain hors horaire, aucun multiplicateur, aucun prestige.

### Aventure : personnages, objets, récit

- **Récit environnemental, sans intrigue imposée.** L'histoire du village se reconstitue par les répliques d'Honoré, les petits mots, les cartes postales et les objets rapportés par Chips.
- **Objets portés :** sacoche, cabas, boîte à gâteaux, bloc-notes. Pas d'inventaire à gérer : chacun a une seule fonction.
- **Secrets :** 20 objets du décor réagissent au clic par une anecdote ou un mot doux (contenu privé pour la destinataire, contenu neutre dans le dépôt public).
- Le personnage d'Honoré et les villageois hors champ méritent un document narratif dédié (voir Assumptions and Dependencies).

---

## Progression and Balance

### Player Progression

La progression est matérielle et visuelle : la maison se remplit. Il n'y a ni niveau ni expérience.

| Moment | Ce qui se passe |
|---|---|
| **Jour 1, 5 premières minutes** | Fiche de paie. Les premières pièces tombent. Chips désigne les livres et le minuteur. Première fournée de cookies avec le garde-manger de départ. |
| **Jours 1 à 3** | Le Pot déborde → premier dépôt → première visite chez Honoré. Le tableau de liège apparaît le jour 2. |
| **Semaine 1** | Le livre 1 se complète. Premiers petits mots terminés. |
| **Semaines 2 à 4** | Affinité Habituée : catalogue, ustensiles, Bocal. Livre 2. |
| **Mois 2 et 3** | Affinité Amie : ingrédients rares, livre offert. Bonbonne. Premières ★★★. |
| **Au-delà** | Saisons, maîtrise complète, arrangement de la vitrine. |

**Kit de départ :** Pot, livre 1 « Premières fournées », bloc-notes, saladier, fouet, plaque de cuisson, mug. Garde-manger : farine 1 kg, sucre 1 kg, beurre 250 g, 6 œufs, pépites de chocolat 100 g, chocolat noir 200 g, levure chimique 5 sachets, extrait de vanille 20 ml.

### Difficulty Curve

Pas de difficulté au sens d'un défi. La **complexité** monte avec les recettes :

| Niveau | Phases | Ingrédients | Ustensiles à acheter | Exemples |
|---|---|---|---|---|
| Simple | 1 | 5 à 7 | 0 | Cookies, mug cake |
| Moyen | 2 | 6 à 8 | 0 ou 1 | Brioche tressée, focaccia au romarin |
| Ambitieux | 4 | 8 à 10 | 2 ou 3 | Tarte au citron meringuée, forêt-noire |

Le seul effort demandé est la tenue du focus, dont la joueuse choisit la durée.

### Economy and Resources

**Repères de revenu**

| Net mensuel | Par heure | Par jour (7 h) | 1 centime toutes les |
|---|---|---|---|
| 1 500 € | 9,89 € | 69,23 € | 3,6 s |
| 2 000 € | 13,19 € | 92,31 € | 2,7 s |
| 3 000 € | 19,78 € | 138,46 € | 1,8 s |

**Ingrédients (rayons d'Honoré)**

| Produit | Conditionnement | Prix |
|---|---|---|
| Farine de blé | 1 kg | 1,20 € |
| Sucre en poudre | 1 kg | 1,60 € |
| Sucre glace | 500 g | 1,50 € |
| Beurre doux | 250 g | 2,80 € |
| Œufs fermiers | boîte de 6 | 2,40 € |
| Lait entier | 1 L | 1,20 € |
| Crème liquide entière | 50 cl | 2,30 € |
| Chocolat noir pâtissier | 200 g | 2,50 € |
| Pépites de chocolat | 100 g | 1,80 € |
| Cacao en poudre | 250 g | 3,20 € |
| Levure chimique | 5 sachets | 0,90 € |
| Levure boulangère | 3 sachets | 1,10 € |
| Sel fin | 500 g | 0,70 € |
| Fleur de sel | 125 g | 3,40 € |
| Extrait de vanille | 20 ml | 3,90 € |
| Citrons | filet de 4 | 2,20 € |
| Huile d'olive | 50 cl | 6,50 € |
| Romarin frais | botte | 1,50 € |
| Griottes au sirop | bocal de 350 g | 4,20 € |
| Kirsch (Amie) | 20 cl | 7,90 € |
| Poudre d'amandes | 125 g | 2,60 € |
| Miel de châtaignier (Amie) | 250 g | 5,90 € |
| Vanille en gousse (Amie) | 2 gousses | 6,50 € |
| Fruits de saison | barquette | 3,50 € |

L'eau est gratuite et illimitée.

**Coût d'une fournée** (ingrédients consommés, calculé sur les recettes de la v1) : mug cake ≈ 1,30 € · brioche tressée ≈ 3,10 € · focaccia ≈ 3,40 € · cookies ≈ 4,45 € · tarte au citron meringuée ≈ 7,90 € · forêt-noire ≈ 9,60 €.

**Produits éphémères**

| Produit | Durée | Prix | Effet visible |
|---|---|---|---|
| Bouquet de saison | 7 jours réels | 9 € | Vase fleuri sur le comptoir, fane sans conséquence |
| Bougie artisanale | 7 jours réels | 6 € | Flamme et halo le soir |
| Café en grains | 20 focus | 7,50 € | La machine fume et ronronne pendant les focus |
| Croquettes de Chips | 20 gamelles | 4,50 € | Animation de la gamelle |

**Ustensiles (permanents, requis par certaines recettes)**

| Ustensile | Prix | Requis par |
|---|---|---|
| Rouleau à pâtisserie | 9 € | Tartes |
| Moule à tarte 24 cm | 12 € | Tartes |
| Moule à génoise 20 cm | 11 € | Gâteaux montés |
| Tamis | 6 € | Génoises |
| Poche à douille | 7 € | Meringue, chantilly |
| Thermomètre à sucre | 14 € | Meringue italienne |
| Chalumeau de cuisine | 22 € | Tarte au citron meringuée |
| Batteur électrique | 35 € | Forêt-noire |

**Catalogue (livré le lendemain)**

| Catégorie | Objets | Fourchette | Total |
|---|---|---|---|
| Bocaux | Bocal, Bonbonne | 12 € – 45 € | 57 € |
| Livres | Livres 2 et 3 | 18 € – 22 € | 40 € |
| Surfaces de vitrine | 4 | 39 € – 240 € | 449 € |
| Décoration | 30 | 8 € – 320 € | ≈ 2 240 € |
| Pour Chips | 3 | 19 € – 89 € | 132 € |
| **Total** | **41 achats** | | **≈ 2 920 €** |

**Budget type** (35 focus par semaine, soit 18 fournées variées, 2 000 € net) : ingrédients ≈ 80 €, éphémères ≈ 20 €, soit ≈ 22 % du salaire hebdomadaire. Le reste s'épargne ou part au catalogue.

**Réglage global :** un coefficient unique multiplie tous les prix (défaut 1,0), ajustable par la joueuse entre 0,5 et 3 si son salaire rend le jeu trop serré ou trop facile.

---

## Level Design Framework

### Level Types

| Lieu | Taille | Rôle | Objets interactifs |
|---|---|---|---|
| **Maison** | 2 écrans de large, balayage horizontal | Lieu principal | 22 |
| **Rue** | 1 écran, vue fixe depuis le seuil | Dépôt, accès à l'épicerie | 3, plus la petite scène du jour |
| **Épicerie** | 1 écran | Achats, dialogue | 30 produits, panier, Honoré, catalogue, sonnette |
| **Gros plans** | Plein écran sur un objet | Lecture, écriture, bocal | Bocal, livre, bloc-notes, livret, carnet, garde-manger, four, tableau de liège |
| **Widget** | 3 formats | Travail | Minuteur, montant |

**La maison, de gauche à droite**

- **Coin bureau :** fiche de paie, livret, calendrier mural, tableau de liège, carnet de commandes, poste de musique, fenêtre.
- **Comptoir :** bocal, sacoche, caisse (ticket du soir), 3 cloches, étagères murales, boîte à gâteaux, vase, porte d'entrée.
- **Cuisine :** plan de travail, minuteur, four, étagère à livres, garde-manger, machine à café, gamelle et coussin de Chips.

**La rue, vue d'en face :** la banque et son guichet · une fontaine et un banc · la devanture de l'épicerie. Au premier plan, l'encadrement de la porte de la pâtisserie.

**Principes**

- **Cadrage douillet :** depuis chaque coin de la maison, on aperçoit le coin voisin.
- **Lumière protectrice :** l'intérieur est toujours plus chaud que l'extérieur.
- **Un objet, une fonction.**
- **La rue est calme :** des traces de présence (linge, vélo, volets), personne à l'écran hormis Honoré dans sa boutique.

### Level Progression

- Jour 1 : la maison seule. La porte s'ouvre au premier versement dans la sacoche.
- La rue, la banque et l'épicerie sont alors accessibles pour toujours.
- La maison s'enrichit par les achats et les saisons, pas par de nouvelles pièces en v1.0.

---

## Art and Audio Direction

### Art Style

- **Aquarelle et encre, dessiné à la main**, dans la lignée de l'illustration de Chips : trait d'encre brun-noir d'épaisseur variable, lavis d'aquarelle, grain du papier visible, bords irréguliers.
- **Interdits :** rendu photoréaliste, rendu 3D lisse, verre dépoli, néons, dégradés numériques, typographie en capitales espacées.
- **2.5D :** chaque lieu est composé de 3 à 6 plans qui se décalent avec la souris (± 12 px au premier plan, ± 3 px au fond). **L'argent a une vraie profondeur :** les pièces culbutent, se recouvrent et montrent leur tranche.
- **Lumière :** les décors sont peints en lumière neutre et diffuse ; l'heure et la météo les teintent. Les sources chaudes (guirlandes, lampe, four, bougie) sont des halos séparés.

**Palette**

| Rôle | Jour | Nuit |
|---|---|---|
| Lumière | Ambre miel `#F2B866` | Guirlande `#FFD9A0` |
| Bois | Noyer `#6B4423` | Noyer sombre `#2B2230` |
| Fond | Crème `#F6E9D2` | Heure bleue `#2A3350` |
| Accent | Croûte dorée `#D9902F` | Brume lavande `#8C93B8` |
| Encre | Cacao `#3A2618` | Ivoire `#EDE6D8` |

**Personnages**

- **Chips :** chat noir aux reflets roux, yeux mi-clos. 9 postures (roulé en boule, pain, assis, étiré, allongé sur le flanc dans la farine, toilette, regard caméra, patte tendue, guet à la fenêtre).
- **Honoré :** la soixantaine, tablier, lunettes rondes, cadré en buste derrière son comptoir. 5 expressions (neutre, souriant, surpris, attendri, malicieux).

**L'argent**

- 17 coupures dessinées, recto et verso, reconnaissables par leur taille, leur forme et leur couleur dominante.
- **Monnaie « maison » :** les valeurs, les tailles relatives et les couleurs dominantes sont celles de l'euro, et tous les montants sont en euros ; seuls les motifs sont propres au jeu (patte de Chips, brioche, épi de blé).

**Écritures :** une écriture manuscrite (bloc-notes, étiquettes, petits mots), une police de livre à empattements (recettes), une craie (ardoise). Polices sous licence libre.

### Audio and Music

**Six familles de sons, un curseur chacune :** musique · ambiance intérieure · cuisine · Chips · rue et météo · objets.

| Famille | Contenu v1.0 |
|---|---|
| Musique | Poste de musique jouant des disques (pistes locales libres de droits) et le dossier de musique de la joueuse. Disques supplémentaires en récompense. |
| Ambiance intérieure | Horloge, parquet, four qui ronfle, machine à café |
| Cuisine | 12 sons de préparation (fouet, œuf cassé, farine tamisée, pâte pétrie…) |
| Chips | Ronronnement, 4 miaulements, pas feutrés, saut |
| Rue et météo | Pluie sur la vitre, vent, oiseaux, fontaine, clochette de l'épicerie |
| Objets | Pièces (8 hauteurs selon la coupure, 8 tintements simultanés au plus), billets, papier, crayon, tampon, clapet de la banque, minuteur |

- Les sons de l'extérieur sont étouffés quand la porte est fermée.
- **Fin de focus :** un seul tintement doux. Aucune alarme.
- Les radios en ligne de la v1 (FIP, Nova) ne sont pas reprises en v1.0 ; elles font l'objet d'une étude technique.

---

## Technical Specifications

### Performance Requirements

| Mesure | Cible | Méthode |
|---|---|---|
| Fluidité à la maison | 60 images/s en 1080p sur un portable de bureau à puce graphique intégrée | 10 min, bocal à 200 objets |
| Charge en widget | ≤ 2 % d'un processeur 4 cœurs, ≤ 250 Mo de mémoire | Moyenne sur 10 min, gestionnaire des tâches |
| Démarrage | ≤ 4 s jusqu'à la maison | SSD, à froid |
| Changement de lieu | ≤ 0,7 s | Maison → rue → épicerie |
| Exactitude du salaire | Écart nul au centime sur une journée | Comparaison à la formule |
| Dérive du minuteur | ≤ 1 s sur 8 h, mise en veille comprise | Comparaison à l'horloge système |
| Sauvegarde | ≤ 50 ms, sans saccade | Mesure interne |

### Platform-Specific Details

- **Windows 10 et 11, 64 bits.** Moteur : Godot 4.7.
- Fenêtre redimensionnable, 1280 × 720 au minimum, conçue pour 1920 × 1080.
- Widget : fenêtre sans bordure, toujours au premier plan, fond transparent.
- Icône dans la zone de notification ; lancement au démarrage de Windows en option.
- Une seule instance à la fois.
- **Hors ligne par défaut.** Seule la météo utilise Internet, et elle est facultative.
- **Aucune collecte de données.** Sauvegarde locale uniquement, avec 3 copies de secours.
- Reprise des réglages de salaire de la v1 au premier lancement.
- Langue : français. Textes séparés du code pour une traduction ultérieure.

### Asset Requirements

| Type | Volume v1.0 |
|---|---|
| Décors en plans séparés | 3 lieux, 10 plans |
| Objets de décor et gros plans | ≈ 60 |
| Coupures | 17, recto et verso |
| Pièces de vitrine | 18, en 3 niveaux de maîtrise |
| Produits d'épicerie | 30 |
| Postures de Chips | 9 |
| Expressions d'Honoré | 5 |
| Objets de décoration | 30 |
| Sons | ≈ 90 |
| Musique | 10 pistes au moins |
| Recettes | 18 (6 reprises de la v1, 12 à écrire) |
| Répliques d'Honoré | ≈ 250 lignes |
| Petits mots | 40 modèles |

Poids de l'installation : ≤ 250 Mo.

---

## Development Epics

### Epic Structure

Détail et stories dans `epics.md`.

| # | Epic | Ce qu'on peut jouer à la fin | Mécaniques |
|---|---|---|---|
| 0 | Fondations | Le compteur de salaire est exact et sauvegardé | M1 |
| 1 | Le bocal et le widget | Regarder et manipuler son argent, travailler avec le widget | M2, M13 |
| 2 | La maison | Se promener dans la maison, lumière et météo réelles | M12 |
| 3 | La fournée | Lire un livre, cuire une recette pendant un focus | M4 (livres), M8 |
| 4 | La vitrine | Exposer et arranger ses pâtisseries | M9 |
| 5 | La rue et la banque | Sortir, déposer son bocal, tenir son livret | M3, M5 |
| 6 | L'épicerie et Honoré | Écrire sa liste, acheter, discuter | M4 (bloc-notes), M6, M7 |
| 7 | Chips | Un chat qui vit sa vie et annonce les pauses | M11 |
| 8 | Le carnet de commandes | Choisir ses petits mots, recevoir des récompenses | M10 |
| 9 | Sons et musique | Mixage par famille, disques | Audio |
| 10 | Contenu et secrets | Livres 2 et 3, catalogue, saisons, contenu privé | M6 (catalogue), secrets |
| 11 | Finition et sortie | Premier lancement guidé, accessibilité, installeur | — |

**Jalons**

- **Parité v1** : fin de l'epic 1. Le jeu fait ce que faisait l'app Electron, en mieux.
- **Tranche verticale** : fin de l'epic 6. La boucle complète est jouable.
- **Version cadeau** : fin de l'epic 11.

---

## Success Metrics

### Technical Metrics

Les sept cibles de « Performance Requirements », vérifiées à chaque jalon. Zéro perte de sauvegarde sur 30 jours d'usage réel.

### Gameplay Metrics

Compteurs locaux, visibles dans le livret, jamais transmis.

| Indicateur | Cible |
|---|---|
| Jours travaillés où le jeu est lancé | ≥ 90 % sur 4 semaines |
| Focus terminés par jour travaillé | ≥ 3 |
| Dépôts | ≥ 1 par semaine |
| Livre 1 complété | En 2 semaines au plus |
| Petits mots terminés | ≥ 3 par semaine |

**Qualitatif :** la destinataire sourit en découvrant un secret ; elle réarrange sa vitrine sans qu'on le lui demande ; elle parle d'Honoré comme d'une personne.

---

## Out of Scope

**Exclu définitivement** (arbitrages de Victor)

- Pourboires et tout revenu fictif.
- Table de tri et toute manipulation manuelle des espèces pour les ranger.
- Pénalités, dette, péremption, séries de jours consécutifs.
- Collecte de données, compte en ligne.

**Exclu de la v1.0**

- Promenade à pied dans le village : la rue est une vue fixe.
- Autres commerces et autres personnages à l'écran.
- Multijoueur, livre d'or, partage.
- Synchronisation entre appareils, plusieurs sauvegardes.

**Reporté après la v1.0**

- **Plantes et herbier.** Présents dans la v1 (boutique, soin, herbier) ; repris dans un epic « Jardin » après la version cadeau.
- **Grands projets** : objectifs d'épargne sur plusieurs mois qui transforment la maison ou la rue (véranda, devanture, four à bois).
- Radios en ligne.
- Nouvelles pièces de la maison, jardin, place du marché.
- **Application mobile, Android et iOS, avec widget d'écran d'accueil** (souhait de Victor du 8 octobre 2026, « plus tard »). Le jeu s'exporte sur mobile ; le widget d'écran d'accueil est un composant natif à écrire à part pour chaque système, qui affiche le montant calculé à partir de l'heure et des réglages, à la minute près.
- Anglais, Linux, macOS.

---

## Assumptions and Dependencies

### Assumptions Index

Aucune hypothèse ouverte. Les huit hypothèses du premier jet (A1 à A8) ont été tranchées par Victor le 8 octobre 2026 (`decision-log.md`, seconde série).

### Dependencies

- **Illustrations** produites par Victor avec Gemini à partir des prompts de `art-direction.md`.
- **Narration :** un document dédié pour Honoré et le village est recommandé avant l'epic 6 (`gds-create-narrative`).
- **12 recettes à écrire** pour les livres 2 et 3.
- **Sons et musiques** libres de droits à sélectionner.
- **Météo :** service gratuit sans clé (Open-Meteo).
- **Contenu privé** rédigé par Victor, hors dépôt.
