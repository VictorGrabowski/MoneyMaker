---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
inputDocuments: ['game-brief.md', 'brainstorming-session-2026-01-14.md']
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 1
  projectDocs: 0
workflowType: 'gdd'
lastStep: 0
project_name: 'MoneyMaker'
user_name: 'V.grabowski'
date: '2026-01-14'
game_type: 'idle-incremental'
game_name: 'MoneyMaker'
---

# MoneyMaker - Game Design Document

**Author:** V.grabowski
**Target Platform(s):** Windows (Primary), Android (Secondary)

---

### Game Name

**MoneyMaker**

### Core Concept

MoneyMaker est un compagnon de bureau apaisant qui transforme le temps de travail en une expérience de découverte visuelle et émotionnelle. L'application synchronise les revenus réels de l'utilisateur en temps réel, matérialisant chaque centime durement gagné par une pluie de pièces physiques s'accumulant dans une échoppe de pâtisserie cozy ("The Bakery"). 

Le jeu s'articule autour d'un cycle de productivité Pomodoro : pendant les phases de travail, une interface minimaliste ("Vitre Propre") affiche discrètement le compteur de salaire. Pendant les pauses, l'utilisateur accède au Hub complet pour interagir avec Chips le chat, dépenser ses gains en décorations, et débloquer des recettes dans son "Grimoire Sucré". 

Trois mécaniques de "jus" (game feel) et de rétention renforcent cette immersion :
- **Physique de Coussin** : Les pièces ne s'entrechoquent pas froidement mais s'empilent avec une mollesse satisfaisante et des sons étouffés, renforçant l'aspect "cozy".
- **Interface Diégétique & Réactivité** : Dans le Hub, le solde est consultable uniquement via le **"Livre de Comptes"**. 
    - *Mécanique* : Le livre s'affiche en overlay (superposition) sur l'écran et s'ouvre instantanément à la page "Compte". 
    - *Contenu* : Il affiche l'historique complet des gains, un sommaire pour naviguer entre les sections, et un outil de suivi des dépenses. L'ouverture est accompagnée d'un son de papier riche pour une satisfaction tactile maximale. Mieux, l'effort laisse des traces sur tous les écrans : de la poussière de farine, des taches de café ou même une part de gâteau croquée apparaissent sur l'ATH minimaliste. Chips peut aussi s'y "inviter" brièvement s'il ne trouve pas sa place dans la Bakery, avant de s'effacer pour laisser l'utilisateur travailler.
- **Le Sommeil de Chips** : S'il est tard, le compteur minimaliste se fige sur le gain de la journée ; Chips y apparaît allongé, la queue bougeant calmement, un bonnet de nuit sur la tête, bloquant la moitié de l'affichage.

### Game Type

**Type :** Idle/Incremental
**Framework :** Ce GDD utilise le template `idle-incremental` avec des sections spécifiques pour la progression passive (salaire), les arbres d'amélioration (shop) et le système d'automatisation des recettes.

---

## Target Platform(s)

### Primary Platform: Windows (Desktop)

**Environnement :** Application Desktop via Electron + React.

**La Transition (The Flow) :** 
- Le mode minimaliste dispose d'une icône cliquable "vivante".
- **Feedback Haptique Visuel** : L'icône grossit légèrement au survol (hover), créant une envie organique d'ouverture.
- **Transition Cinétique Optimisée** : Passage vers le Hub via un effet de flou (blur) fluide et élégant ciblant une durée de **0.5 seconde**.
- **Performance Flash** : Les assets sont pré-chargés en arrière-plan durant le flou pour garantir une ouverture instantanée. Seuls les calculs dynamiques (incrément de salaire, météo, position de Chips) sont exécutés au moment de l'ouverture du Livre.
- **Philosophie d'Immersion** : Le Hub doit donner l'impression d'avoir toujours été là. L'ambiance sonore (bruits de café, radio Lo-Fi) apparaît progressivement lors de la transition.

### Secondary Platform: Android (Widget)

**Type :** Widget de bureau interactif (Home-screen).

**Design & Personnalisation :** Affichage de l'incrémentation du salaire sur un fond thématique (nappe à carreaux rouge et blanc, illustrations de pâtisseries). L'utilisateur peut personnaliser le "look" du widget.
**Interaction :** Possibilité de caresser Chips en cliquant sur le widget (feedback haptique/sonore discret).

---

## Target Audience

### Primary Audience

**Utilisatrice :** Votre copine.
**Profil :** Joueuse occasionnelle, amatrice de jeux "cozy" (Animal Crossing, Valheim, Ghibli).
**Niveau d'expérience :** Familière avec l'outil informatique, mais recherche une expérience apaisante et sans stress technique.

### Motivations et Patterns

- **Session de Jeu** : Sessions longues en arrière-plan pendant le travail (8h-10h), avec des micro-interactions de 5-15 minutes lors des pauses Pomodoro.
- **Ce qui l'attire** : L'esthétique artisanale, la collection de secrets, la satisfaction visuelle de l'accumulation, et le sentiment de "compagnon" bienveillant.

---

## Goals and Context

### Project Goals

- **Objectif Affectif** : Créer un cadeau mémorable et personnel qui déclenche une émotion positive quotidienne (le "Gnon" de Chips).
- **Sérénité Productive** : Offrir un outil de focus (Pomodoro) qui aide au travail sans ajouter de stress visuel ou cognitif.
- **Excellence Technique** : Assurer une fluidité parfaite (target 0.5s) entre le widget minimaliste et le hub immersif via Electron.
- **Réalisation Artistique** : Produire une direction artistique "Cozy" cohérente et chaleureuse assistée par IA.

### Background and Rationale

MoneyMaker est né de la volonté de transformer l'abstraction numérique du salaire en une expérience gratifiante et zen. Dans un monde où le temps de travail est souvent perçu comme une donnée immatérielle, ce projet vise à redonner du sens à l'effort par la matérialisation de la richesse dans un univers protecteur. C'est à la fois un outil de productivité, une bulle de calme pour les journées chargées, et un témoignage d'affection personnalisé à travers un univers évolutif.

---

## Unique Selling Points (USPs)

1.  **L'Abondance Tangible** : Chaque centime est représenté par une pièce physique avec une "Physique de Coussin" (mollesse satisfaisante) et un rendu sonore riche. L'argent devient une matière vivante.
2.  **L'Immersion Diégétique (Zéro UI)** : Suppression des éléments d'interface traditionnels dans le Hub. Toute l'information passe par le décor (Livre de Comptes, ardoise, bocal).
3.  **Le Compagnon Évolutif** : Chips le chat n'est pas qu'une mascotte ; il réagit à l'heure, à l'effort de l'utilisateur (traces sur l'ATH) et possède ses propres routines (ferme la boutique la nuit).
4.  **Le Grimoire Sucré Automatisé** : Un système de recettes détaillées où l'utilisateur gère les courses et le lancement, puis suit la préparation automatisée et sensorielle de pâtisseries magnifiques.

### Competitive Positioning

Contrairement aux outils de finance austères ou aux jeux de gestion stressants, MoneyMaker se positionne comme un **"Lifestyle Companion"**. Il ne demande pas d'attention constante mais récompense la concentration par des moments de calme et de fierté partagée.

---

## Core Gameplay

### Game Pillars

1.  **Abondance Tangible** : Redonner du poids et du sens à l'argent par la physique (coussin) et le son. Chaque centime est une matière vivante.
2.  **Sérénité Productive** : Créer un espace de concentration sans stress, récompensé par la découverte et la transformation.
3.  **Compagnonnage Affectif** : L'utilisateur n'est jamais seul ; Chips et l'univers réagissent dynamiquement à ses efforts.

**Priorisation :** En cas de conflit, la **Sérénité Productive** prime sur l'abondance visuelle pour éviter de surcharger l'utilisateur.

### Core Gameplay Loop

La boucle s'articule autour de la transformation d'un flux passif (salaire) en une gestion active (pâtisserie/déco) :

1.  **Planification (Hub)** : L'utilisateur choisit une recette dans le Grimoire selon son défi de focus (ex: 25 min = Cookies, 4h = Gâteau Divin).
2.  **Focus (Minimaliste)** : Lancer le Pomodoro. Le salaire s'incrémente en temps réel. La farine et le café apparaissent sur l'ATH. Chips surveille.
3.  **Récompense (Hub)** : Fin du timer. Le gâteau est réussi. Phase ASMR de collecte des pièces et d'interaction avec Chips.
4.  **Motivation** : Utiliser les gains pour améliorer le shop ou acheter des ingrédients rares.

**Timing de la boucle :** Variable, de 25 minutes à 4 heures selon l'ambition de l'utilisateur.

### Win/Loss Conditions

#### Victory Conditions
- **Succès Continu** : Compléter le Grimoire Sucré, débloquer tous les secrets du shop, et maintenir le bocal plein. Il n'y a pas de "fin" abrupte, seulement une accumulation de fierté.

#### Failure Conditions (Le Soufflé Râté)
- **Rupture de Focus** : Annuler le timer Pomodoro avant la fin détruit instantanément les ingrédients engagés. La recette échoue visuellement (soufflé qui retombe, fumée).
- **Conséquence** : Perte sèche de ressources (argent investi dans les ingrédients) mais aucun impact sur le salaire global.

#### Failure Recovery
- Chips émet un petit miaulement d'encouragement/tristesse. L'utilisateur peut immédiatement relancer une nouvelle recette après avoir "nettoyé" le plan de travail.

### User Emotion Journey (Philosophie)
Le jeu repose sur un contrat de confiance : le gain est 100% passif pour éviter toute corvée supplémentaire, tandis que la progression est 100% active. L'utilisatrice transforme son temps de travail (flux subi) en une création artisanale (stock choisi), créant un sentiment d'agence et de fierté.

---

## Game Mechanics

### Primary Mechanics

1.  **Le Grimoire (Pâtisser)** : Sélection d'une recette -> Phase de Focus. La préparation est automatisée (ASMR) mais parsemée de "Clics Magiques" optionnels (éclairs, étincelles) qui déclenchent des sons/effets visuels supplémentaires sans impacter la réussite.
2.  **L'Abondance (Accumuler)** : Gain passif indexé sur le salaire. Les pièces s'empilent physiquement. Action de "Rangement" consistant à glisser les pièces dans le bocal ou le comptoir.
3.  **L'Entretien (Arroser & Nettoyer)** : Actions quotidiennes douces. Arroser les plantes du shop (qui s'ébrouent et vibrent joyeusement sous l'eau), nettoyer les traces de farine après une cuisson, ou remplir la gamelle de Chips.
4.  **Le Journaliste (Le Livre de Comptes)** : Un livre diégétique avec des **marque-pages (onglets)** latéraux pour une navigation ultra-rapide entre les sections.
    - **Historique** : Suivi complet des gains et dépenses.
    - **Statistiques** : Un chapitre récapitulant tout le parcours (focus total, gâteaux cuits, etc.).
    - **Notes** : Onglet libre pour noter des tâches ou des pensées.
5.  **L'Aménagement (Habiller)** : Achat et placement libre d'objets de décoration (plantes, mobilier, luminaires) pour transformer le Hub.

### Mechanic Interactions
- **Focus -> Farine** : Réussir un Pomodoro laisse des traces de farine dans le Hub, demandant un petit nettoyage (satisfaction de l'effort).
- **Notes -> Focus** : Utiliser l'onglet "Notes" durant le travail aide à vider l'esprit et augmente l'efficacité du sentiment de sérénité.

### Mechanic Progression
- **Maîtrise Culinaire** : Plus on réalise une recette, plus l'animation ASMR devient riche (détails supplémentaires, nouveaux bruits de spatule).
- **Évolution de Chips** : Chips débloque de nouvelles routines à mesure que son bocal/gamelle est entretenu.

---

## Controls and Input

### Control Scheme (Windows)

| Action | Input | Feedback |
| :--- | :--- | :--- |
| **Interagir / Sélectionner** | Clic Gauche | Vibration visuelle légère de l'objet. |
| **Déplacer objet / Ranger pièce** | Clic Gauche + Drag | Physique "soft" avec inertie. |
| **Feuilleter le Livre** | Clic sur les coins inférieurs des pages | **Quick-Flip** : Animation ultra-rapide et son de papier riche. La navigation est séquentielle mais instantanée pour un plaisir haptique. |
| **Écrire des Notes** | Clavier (une fois le livre ouvert) | Son de machine à écrire Lo-Fi étouffé. |
| **Annuler / Fermer** | Touche `ESC` ou Clic hors de l'overlay | Transition de flou inverse. |

### Input Feel
- **Poids et Tactilité (Soft Bodies)** : Chaque clic donne l'impression de toucher physiquement la pâtisserie ou le papier. Les pièces et objets interactifs utilisent une physique de **corps mous** (déformation légère et inertie caoutchouc) pour renforcer l'effet "Coussin".
- **Réactivité "Quick-Flip"** : Malgré les animations fluides, la réponse aux contrôles est immédiate. Le livre privilégie la vitesse de feuilletage pour ne jamais bloquer l'utilisateur.

### Accessibility Controls
- **Mode Haute Visibilité** : Contour des pièces d'or plus marqué.
- **Paramètres ASMR** : Sliders séparés pour les bruits de cuisine, la musique Lo-Fi et les miaulements de Chips.

---

## Idle/Incremental Specific Design

### Core Interaction
- **Le Flux Passif** : L'argent s'incrémente en temps réel, indexé strictement (1:1) sur le salaire saisi par l'utilisateur. Aucune mécanique de "click" actif n'est présente pour multiplier ce gain.
- **Réaction Visuelle** : Chaque centime (ou palier de centimes) déclenche la chute d'une pièce physique dans le bocal. Le feedback est axé sur la satisfaction sensorielle (sons variés, micro-étincelles) plutôt que sur la performance.

### Upgrade Systems (Le Grimoire & Boutique)
- **Progression Linéaire** : Les achats sont principalement cosmétiques ou servent de "clés" de progression.
- **Catégories d'Achat** : 
    - **Ustensiles** : Débloquent visuellement de nouvelles capacités de cuisson.
    - **Ingrédients** : Débloquent l'accès à des recettes plus complexes dans le Grimoire.
    - **Objets Éphémères (Consommables)** : Fleurs fraîches, bougies artisanales, café premium. Ces objets durent une semaine réelle et maintiennent le Hub "vivant" et changeant visuellement, offrant une raison constante de transformer le flux passif en beauté temporaire.
- **Philosophie "Puriste"** : Aucun objet n'octroie de bonus de gain. Le lien 1:1 avec le salaire réel est maintenu à 100% pour préserver la valeur de l'effort.

### Automation Systems
- **Le Grimoire Automatisé** : Une fois la recette lancée via le timer Pomodoro, la préparation se déroule seule. C'est l'automatisation "narrative" du jeu.
- **Persistance Hors-Ligne** : L'application suit le temps écoulé pour calculer le salaire accumulé même lorsqu'elle est fermée. À la réouverture, une pluie de pièces (douce et satisfaisante) accueille l'utilisatrice pour symboliser le travail accompli.

### Prestige and Reset
- **Absence de Prestige** : Fidèle à l'objectif de " Safe Haven ", le jeu ne propose aucun système de reset ou de prestige. La progression est éternelle, cumulative et jamais remise à zéro.

### Number Balancing & Economy
- **Notation Réaliste** : Toutes les valeurs sont exprimées en **Euros (€)**. 
- **Économie Flat** : Pas de progression exponentielle. Les prix des objets et des ingrédients restent dans des fourchettes réalistes (ex: 5€ pour un sachet de farine rare, 300€ pour un meuble de designer). Le rythme de progression est dicté par le salaire réel de l'utilisatrice.

### Meta-Progression
- **Collectibles** : Remplir le Grimoire et collectionner toutes les variantes de décoration.
- **Événements Fortuits (Surprises)** : Pour briser la monotonie du rythme linéaire, le jeu déclenche des événements aléatoires gratuits (pluie audio relaxante, Chips qui ramène un objet trouvé, radio qui capte une fréquence secrète).
- **Secrets Affectifs** : Des évolutions subtiles du décor récompensent l'engagement sur le long terme.

---

---

## Progression and Balance

### Player Progression

La progression dans MoneyMaker est **esthétique, matérielle et rituelle**. Elle ne repose pas sur une montée en puissance statistique, mais sur la transformation du lieu de vie.

#### Progression Types
- **Matérielle (Outils & Recettes)** : Les recettes ne se débloquent pas avec de l'expérience, mais par l'achat d'équipement (Four, Moules, Fouet, Chinois, Tamis, etc.). Posséder l'outil adéquat débloque l'accès à la création.
- **Visuelle (Impact Shop)** : C'est le moteur principal. Le sentiment de progrès vient du fait d'avoir choisi et placé chaque élément à l'écran, transformant une échoppe vide en un cocon ultra-personnalisé.
- **Disciplinaire (Focus)** : La satisfaction vient de l'accomplissement réel du travail (Pomodoro) et de la gestion honnête de son budget quotidien.

#### Progression Pacing
- **Rythme Réel** : Le rythme est dicté par le salaire réel du joueur. L'argent peut être "empoché" à la fin de chaque journée pour être utilisé dès le lendemain, créant un cycle de récompense quotidien.
- **Le Rituel du Cash-out (La consécration)** : À la fin de la journée de travail, un rituel multi-sensoriel s'active :
    1. **Le Rideau de Chips** : Chips s'étire et tire physiquement le rideau de l'échoppe (fermeture symbolique du travail).
    2. **La Pluie de Digits** : Le solde accumulé sur le widget "tombe" littéralement dans le bocal du Hub avec une physique lourde et des étincelles dorées.
    3. **Le Ticket de Caisse** : Une vieille caisse enregistreuse imprime un petit reçu diégétique résumant l'effort du jour ("X heures travaillées, X gâteaux en préparation").
    4. **Disponibilité** : L'argent devient utilisable uniquement le lendemain matin quand Chips rouvre le rideau, empêchant toute déconcentration nocturne.

### Difficulty Curve

#### Challenge Scaling
- **Difficulté Contrôlée** : La courbe est plate. Le "défi" réside uniquement dans la discipline du timer choisi par l'utilisateur. Plus une recette nécessite un outil coûteux et un temps long, plus la satisfaction de l'accomplir est grande.

#### Difficulty Options
- Le jeu ne propose pas de réglage de difficulté, car l'échec n'est pas punitif au-delà de la perte des ressources engagées.

### Economy and Resources

#### Resources
- **L'Euro (€)** : Unique monnaie, indexée 1:1 sur le gain réel irl. 
- **Équipement (Asset-Gate)** : Les moules et ustensiles servent de "clés" de progression pour la pâtisserie.

#### Economy Flow
- **Le Cycle Journalier** : Gain Passif (Travail) -> Fin de journée (Encaisser) -> lendemain (Dépenser/Investir). 
- **Discipline Pure** : Pas de monnaies premium ou de bonus de quête. La seule source de richesse est le temps de travail réel.

---

---

## Level Design Framework

### Structure Type

MoneyMaker utilise une structure de **Hub Unique Évolutif**. Le joueur n'évolue pas à travers une succession de niveaux, mais habite un espace fixe qui se transforme selon ses actions et le temps réel.

### Level Types (Zones du Hub)

L'échoppe est conçue comme un espace ouvert et interconnecté :
- **Le Salon de Thé / Café** : Zone centrale contenant la porte d'entrée, une ou deux tables pour les clients, et une grande fenêtre. Depuis le salon, on peut apercevoir le **four** et un coin du **plan de travail** de la cuisine, créant un lien permanent avec l'activité de pâtisserie.
- **Le Bureau de Travail** : Un recoin calme disposant de sa propre fenêtre. C'est l'espace dédié au focus et à la consultation du Livre.
- **La Cuisine** : Partiellement visible depuis le salon, c'est le cœur technique (four, ustensiles).

#### Atmospheric Windows (Les Volets)
Les deux fenêtres (Bureau et Salon) ne montrent pas l'agitation de la rue. Un **volet** (ou store filtrant) cache l'extérieur tout en laissant passer une lumière calme et colorée selon l'heure et la saison, renforçant l'effet "Bulle de Sérénité".

#### Tutorial Integration
L'apprentissage se fait de manière organique : Clips attire l'attention sur les objets interactifs (bocal, plante, four) via des miaulements ou des regards lors de la première ouverture.

#### Special States (Saisons et Temps Réel)
Le "Niveau" est synchronisé avec le monde réel :
- **Météo & Saisons** : La fenêtre du Hub reflète les saisons réelles (neige, feuilles d'automne, grand soleil) et la météo locale si possible.
- **Cycle Jour/Nuit** : L'éclairage du shop change dynamiquement selon l'heure système de l'utilisateur.

### Level Progression

Le sentiment de progression ne vient pas du déblocage de nouvelles cartes, mais de **l'enrichissement visuel** du Hub. 

#### Unlock System
- **Biomes Futurs** : Bien que le jeu commence dans une échoppe classique, le framework permet de débloquer des biomes ou bâtiments entièrement différents (ex: Stand de plage) dans des phases de développement ultérieures.

#### Replayability
La "rejouabilité" est remplacée par la **pérennité**. Le shop devient un compagnon quotidien dont l'apparence change au gré des achats et des saisons, incitant à revenir chaque jour pour voir son évolution.

### Level Design Principles

- **"Cozy Framing"** : Chaque zone est un diorama chaleureux. On voit toujours un morceau d'une autre zone (ex: le four lointain) pour donner de la profondeur.
- **"Information Diégétique"** : Aucun texte flottant. L'état des plantes (soif/santé) ou du four (cuisson) est purement visuel.
- **"Végétalisation Libre"** : Le joueur peut placer et entretenir des plantes différentes un peu partout dans le shop, et pas uniquement sur le bureau.
- **"Atmosphère Filtrée"** : La lumière doit être travaillée pour être douce et protectrice, évitant les contrastes agressifs de l'extérieur.

---

## Art and Audio Direction

### Art Style

MoneyMaker adopte une esthétique **"Ghibli-Clean"**. Le visuel doit être lumineux, rassurant et extrêmement propre.

- **Style Visuel** : Lignes très nettes ("clean lineart") avec des ombrages doux et simplifiés. Pas de textures complexes ou de grain excessif, privilégiant la clarté et la douceur.
- **Éclairage Dynamique** :
    - **Jour** : Lumière globale diffuse et chaleureuse.
    - **Nuit** : Obscurité reposante. L'éclairage est géré via des luminaires d'appoint (lampes de bureau, guirlandes) activables manuellement.
    - **Auto-Glow** : Les lumières peuvent s'allumer automatiquement selon l'heure système (coucher du soleil IRL), tout en laissant la priorité à l'interrupteur manuel pour le plaisir du "clic".
- **Character Design & Physique (Chips)** : 
    - Chips s'exprime par le langage corporel. 
    - **Interaction Tactile** : Les objets réagissent physiquement (tremblement, balancement) quand Chips se frotte à eux.
    - **Les Bêtises** : Rarement, Chips peut renverser ou "casser" un petit objet. L'utilisatrice doit cliquer sur les débris pour "nettoyer", et l'objet réapparaît intact après un cooldown de 5 secondes.

#### Visual References
- **Studio Ghibli** (Kiki l'Apprentie Sorcière) : Pour l'architecture du shop et la lumière.
- **Lofi Girl** : Pour l'ambiance de travail et la sérénité.

#### Color Palette
- Couleurs dominantes : Crème, bois clair, vert sauge, jaune miel. 
- Couleurs nocturnes : Bleus profonds et orangés chauds (ampoules).

### Audio and Music

#### Music Style (Real-Stream Radio)
La musique n'est pas une simple piste en boucle, mais une **Radio Old-School** interactive :
- **Sources Réelles** : Le jeu streame de vraies radios (Lofi Girl, Radio Nova, France Info, etc.).
- **Interface Diégétique** : Changement de station en cliquant sur le cadran ou les boutons.
- **Friture-Juice** : Présence de parasites sonores ("white noise") et de bruits de friture lors du changement de source pour une sensation haptique sonore riche.
- **Extensibilité** : L'utilisateur pourra ajouter ses propres URLs de flux audio.

#### Sound Design
- **ASMR Culinaire** : Sons de papier, cliquetis d'ustensiles, bruit de cuisson étouffé.
- **Interactions Physiques** : Clic sec des interrupteurs, frottement de Chips sur le bois, chute cristalline des pièces.
- **Bruits d'Ambiance** : Friture radio, vent léger, bruits de voisinage très lointains.

#### Voice/Dialogue
- Aucun texte. Chips s'exprime uniquement par ses enregistrements sonores (miaulements, ronrons).

### Aesthetic Goals
L'objectif est de créer un **"Safe Haven" numérique**. Chaque interaction visuelle ou sonore doit déclencher une micro-dose de dopamine calme (calm-joy).

---

## Technical Specifications

### Performance Requirements

MoneyMaker est conçu pour être un compagnon de travail "silencieux" et réactif.

#### Frame Rate Target
- **60 FPS stable** : Indispensable pour la fluidité des animations physiques (pièces, Chips) et l'effet de "beurre" visuel.

#### Resolution Support
- **Format Cible** : Full HD (1920x1080).
- **Compatibilité Ultra-wide** : Utilisation d'un **Parallax Étendu**. Le shop reste central, mais les côtés révèlent plus de détails du décor (rues, plantes) glissant avec une profondeur de champ élégante au lieu de simples bordures noires.

#### Load Times
- **Objectif 0.5s (Ghost-Loading)** : Transition quasi-instantanée. La technique de Ghost-Loading pré-charge les textures dès le survol (hover) de l'icône widget, garantissant que le Hub est déjà en RAM au moment du clic.

### Platform-Specific Details

#### PC (Windows / Electron)
- **Indépendance (Zero-Sync)** : Aucune synchronisation cloud entre PC et Mobile pour garantir une confidentialité totale et une architecture simplifiée.
- **Distribution** : Fichier **.exe léger** (< 100 Mo).
- **Asset Strategy** : Utilisation massive du **WebP (sans perte)** pour les décors et du **SVG** pour l'UI afin de minimiser le poids de l'installeur.

#### Android
- **Légèreté** : Un widget minimaliste indépendant du shop principal PC, axé sur la consultation rapide et l'interaction basique avec Chips.

### Asset Requirements

#### Art Assets
- **Format** : WebP ou PNG haute résolution pour un rendu "Ghibli-Clean" sans pixellisation sur 1080p.
- **Optimisation** : Texture Atlasing pour limiter les appels de dessin (draw calls) et maintenir le CPU au repos.

#### Audio Assets
- **Radio Streaming** : Utilisation d'API de streaming audio standard (HLS/Icecast) avec gestion du buffer.
- **SFX** : Échantillons haute fidélité (WAV/OGG) pour les bruits ASMR.

---

---

## Development Epics

### Epic Overview

| # | Epic Name | Scope | Dependencies | Est. Stories |
|---|-----------|-------|--------------|--------------|
| 1 | **Le Bocal Fondateur** | Widget, Salaire 1:1, Bocal Physique | None | 8 |
| 2 | **Ondes & Saisons** | Radio, Météo-sync, Auto-Glow | 1 | 6 |
| 3 | **Le Grimoire (Alpha)** | 1 Recette Ultra-polished, Pomodoro | 1 | 8 |
| 4 | **L'Échoppe & Chips** | Hub complet, Arrivée de Chips (Repos) | 1 | 7 |
| 5 | **Interactions Félines** | IA Chips, Bêtises, Ronrons | 4 | 8 |
| 6 | **L'Archiveur & Polish** | Livre de Comptes (Notes), .exe final | 5 | 6 |

### Recommended Sequence
1. **Atmosphere (1 & 2)** : Immersion immédiate (Argent + Radio + Saisons).
2. **Action (3)** : La première recette "parfaite" pour tester la boucle de focus.
3. **Compagnonnage (4 & 5)** : Le shop prend vie avec Chips et le Hub complet.
4. **Finalization (6)** : Outils d'archivage et polissage final.

### Vertical Slice
**Le premier jalon jouable :** Fin de l'Epic 1. L'utilisatrice peut déjà lancer le widget, voir son argent tomber dans le bocal et ressentir la satisfaction physique des pièces.

---

## Success Metrics

### Technical Metrics

| Metric | Target | Measurement Method |
| ------ | ------ | ------------------ |
| Frame Rate | 60 FPS (>95% du temps) | Outil de debug interne |
| Transition Flash | < 0.5 seconde | Chronométrage système |
| Poids de l'App | < 100 Mo (.exe final) | Taille du build |
| Stabilité | Zéro crash critique | Rapport de logs local |

### Gameplay Metrics (Privé)

L'intégralité des données est stockée localement sur le PC de l'utilisateur. Aucune collecte externe.

| Metric | Target | Measurement Method |
| ------ | ------ | ------------------ |
| Rétention "Target" | **1 semaine de jeu quotidien** | Consultation du Livre (manuel) |
| Engagement Focus | > 3 sessions Pomodoro / jour | Chapitre "Statistiques" |
| Complétion | 100% du Grimoire rempli | Chapitre "Recettes" |

### Qualitative Success Criteria

- **"L'Adoption"** : La cible principale (copine du créateur) joue spontanément chaque jour.
- **"Feedback Organique"** : L'avancement est montré fièrement en personne (pas via une plateforme).
- **"Zenitude"** : Les sessions de travail sont décrites comme étant moins stressantes grâce à l'ambiance du Hub.
- **"Attachement"** : L'utilisateur vérifie l'état de Chips ou de ses plantes par réflexe.

### Metric Review Cadence
Les statistiques sont consultables en temps réel via le **chapitre "Statistiques"** du Livre de Comptes. Le créateur peut les consulter manuellement pour évaluer le succès du projet.

---

## Out of Scope

- **Multijoueur** : Expérience strictement solo et locale.
- **Synchronisation Cloud** : Pas de partage de données entre PC et Mobile (Zero-Sync).
- **Contenu Avancé (v1.0)** : Pas de biomes additionnels (Plage/Montagne) ou de recettes complexes.
- **Leaderboards / Social** : Pas de comparaison de score ou de partage social intégré.
- **Contrôles Manette** : Support Souris/Clavier uniquement pour la version PC.

### Deferred to Post-Launch
- Ouverture d'une deuxième boutique thématique.
- Système de succès (Achievements) Steam/Android.
- Personnalisation poussée des skins de Chips.

---

## Assumptions and Dependencies

### Key Assumptions
- **Stabilité OS** : Electron permet une transparence et un mode "Always on Top" stable sur Windows 10/11.
- **Intégrité Utilisateur** : Le joueur saisit honnêtement son salaire horaire réel.
- **Focus Cycle** : L'utilisatrice accepte la perte d'ingrédients en cas d'annulation de Pomodoro (Soft-failure).

### External Dependencies
- **Audio Streams** : Disponibilité continue des URLs de streaming radio (Lofi Girl, etc.).
- **Calcul Temps** : Dépendance à l'horloge système pour le calcul du salaire hors-ligne.

---

## Document Information

**Document:** MoneyMaker - Game Design Document
**Version:** 1.0
**Created:** 2026-01-15
**Author:** V.grabowski & Antigravity (Assistant BMAD)
**Status:** Complete

### Change Log

| Version | Date | Changes |
| ------- | ---- | ------- |
| 1.0 | 2026-01-15 | GDD Initial complet après 14 étapes collaboratives. |
