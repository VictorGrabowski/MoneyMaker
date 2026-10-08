---
title: 'MoneyMaker — Journal des décisions de la refonte'
created: '2026-10-08'
updated: '2026-10-08'
---

# Journal des décisions

**Statuts :** `décidé` = arbitrage de Victor · `proposé` = choix de Claude, à valider · `repris` = intention du GDD v1 conservée.

## 2026-10-08 — Arbitrages de Victor

| # | Décision | Statut | Où dans le GDD |
|---|---|---|---|
| D1 | Le projet devient un jeu. Moteur : Godot (4.7.2 déjà installé chez Victor) | décidé (« peut être une bonne idée ») | Technical Specifications |
| D2 | L'argent est en 2.5D avec parallaxe, dessiné dans le style de Chips | décidé | M2, Art Style |
| D3 | Un épicier vend les ressources de pâtisserie ; on dialogue avec lui | décidé | M6, M7 |
| D4 | On se déplace de chez soi jusqu'au magasin | décidé | M5 |
| D5 | On dépense de l'argent pour les produits requis par les recettes | décidé | M6, Economy |
| D6 | On élabore sa liste soi-même en lisant des livres de recettes | décidé | M4 |
| D7 | Les recettes complétées sont visibles en vitrine et sur des étagères, déplaçables par glisser-déposer | décidé | M9 |
| D8 | Destinataire : la compagne de Victor. Victor s'en sert aussi. Dépôt GitHub public | décidé | Target Audience, G3 |
| D9 | Le salaire se dépense après avoir été mis sur un compte en banque | décidé | M3 |
| D10 | « Une session focus = une fournée » | décidé | M8 |
| D11 | Pas de pourboires : aucun profit autre que le salaire réel | décidé | R3, Out of Scope |
| D12 | Pas de table de tri : trop laborieux | décidé | R1, Out of Scope |
| D13 | Interface entièrement intra-diégétique | décidé | Pilier 4 |
| D14 | Carnet de commandes avec un choix de quêtes parmi un pool | décidé | M10, R2 |
| D15 | Chips a une routine ; il se pose sur la table pleine de farine quand vient la pause | décidé | M11 |
| D16 | Visuels : Claude fournit des prompts Gemini, ou produit lui-même quand c'est possible ; Blender est disponible | décidé | `art-direction.md` |

## 2026-10-08 — Propositions de Claude

P1 à P8 ont reçu une réponse de Victor le jour même : voir la seconde série plus bas. P9 à P16 n'ont pas été contestées.

| # | Proposition | Pourquoi | Hypothèse |
|---|---|---|---|
| P1 | Le dépôt se fait dans la rue, à une trappe de banque, et vide tout le bocal | Donne un deuxième but au trajet ; un seul geste (R1) | A1 |
| P2 | Promenade en vue subjective, sans avatar | Un cycle de marche dessiné est l'asset le plus coûteux à obtenir de façon cohérente ; le brief d'origine ne montrait pas de personnage | A2 |
| P3 | Paiement par chèque rempli automatiquement | Un geste ; cohérent avec un compte en banque et un village sans époque | A3 |
| P4 | L'épicier s'appelle Honoré (saint Honoré est le patron des boulangers-pâtissiers) | Nom provisoire | A4 |
| P5 | Mode strict par défaut pendant un focus | Le brief d'origine réservait le hub aux pauses | A5 |
| P6 | Monnaie « maison » aux valeurs et couleurs de l'euro | Personnalise le cadeau ; évite les règles de reproduction des billets pour un dépôt public | A6 |
| P7 | Radios en ligne non reprises en v1.0 | Godot ne lit pas nativement un flux radio ; à étudier | A7 |
| P8 | Plantes et herbier reportés après la version cadeau | Déjà 12 epics avant la version cadeau | A8 |
| P9 | Quatre piliers : Sérénité productive, Abondance tangible et honnête, Compagnonnage affectif, Tout est dans le décor | Fusion des piliers du brief et du GDD v1, plus D13 | — |
| P10 | Trois tailles de bocal (jour, semaine, mois) ; le niveau est une jauge | Rend le remplissage lisible et garde le débordement promis par le brief | — |
| P11 | Fusion paresseuse des coupures | Le bocal paraît toujours garni sans dépasser 240 objets | — |
| P12 | Prix réels en euros, avec un coefficient global réglable | « Économie flat » du GDD v1 | — |
| P13 | Affinité d'Honoré en quatre paliers, qui ne baisse jamais | Donne une raison de revenir sans pression | — |
| P14 | Récompenses de quêtes non monétaires | Conséquence de D11 | — |
| P15 | Contenu privé dans un pack hors dépôt | Conséquence de D8 | — |
| P16 | Catalogue livré le lendemain, une commande à la fois | Anticipation ; étale les achats | — |

## 2026-10-08 — Seconde série d'arbitrages de Victor

Réponses aux huit hypothèses du premier jet.

| # | Décision | Statut | Effet |
|---|---|---|---|
| D17 | Dépôt en un clic à un poste de banque, dans la rue | décidé | Confirme P1 ; « trappe » devient « guichet » ; un clic sur la sacoche à la maison, un clic sur le guichet dans la rue |
| D18 | La rue est une seule image : ce qu'on voit depuis la pâtisserie en regardant en face, avec la banque et le magasin | décidé | Remplace P2 : plus de marche ni de défilement ; M5 réécrit ; story 5.1 réécrite ; « trajet automatique » supprimé |
| D19 | Monnaie « maison », à condition qu'elle reste basée sur la valeur de l'euro | décidé | Confirme P6 : mêmes valeurs, montants en euros, seuls les motifs changent |
| D20 | Plantes et herbier reportés après la version cadeau | décidé | Confirme P8 |
| D21 | Paiement par chèque rempli automatiquement | décidé | Confirme P3 |
| D22 | L'épicier est Honoré, tel que décrit | décidé | Confirme P4 |
| D23 | Mode strict actif par défaut pendant un focus | décidé (après explication) | Confirme P5 ; le mode libre reste un réglage |
| D24 | Pas de radios en ligne en v1.0 | accepté (« dommage mais ok ») | Confirme P7 ; l'étude 9.4 reste prévue |

## 2026-10-08 — Règles précisées pendant l'epic 0

| # | Règle | Pourquoi |
|---|---|---|
| R-0.1 | Un jour clos n'est jamais modifié. La journée en cours est recalculée avec les réglages du moment ; si le nouveau total est inférieur à ce qui est déjà tombé, rien n'est repris | Corriger une faute de frappe dans son salaire doit prendre effet tout de suite, sans jamais retirer d'argent |
| R-0.2 | Une même date n'est jamais payée deux fois, même si l'horloge du PC recule | Remplace « rien n'est crédité tant que l'heure n'a pas dépassé la dernière connue », qui pouvait bloquer les gains après une erreur d'horloge |
| R-0.3 | Les copies de secours de la sauvegarde tournent au lancement, pas à chaque écriture | Trois copies écrites à quelques secondes d'écart ne protègent de rien |
| R-0.4 | Pointage manuel : 16 h comptées au plus par jour ; un pointage oublié s'arrête à minuit | Limite l'effet d'un oubli |

## 2026-10-08 — Troisième série d'arbitrages de Victor

| # | Décision | Statut | Effet |
|---|---|---|---|
| D25 | Retirer les installeurs `potato_rotato` du dépôt | décidé | Fait, avec le téléchargement interrompu du même dossier. L'historique git n'est pas purgé : la question est restée sans réponse |
| D26 | Travailler sur une nouvelle branche | décidé | Branche `refonte-godot` ; rien n'est poussé |
| D27 | Une application mobile (Android, iOS) avec widget d'écran d'accueil serait souhaitable, plus tard | noté | Ajouté aux reports d'après la v1.0. Corrige l'écart E4 : le jeu ne peut pas être lui-même un widget, mais un widget natif peut l'accompagner |

## 2026-10-08 — Règles précisées pendant l'epic 1

| # | Règle | Pourquoi |
|---|---|---|
| R-1.1 | La fusion à faire est choisie pour garder au bocal ses proportions (profil : pièces de 1 et 2 € nombreuses, petite monnaie, peu de billets), et non « la plus petite d'abord » | Mesuré : « la plus petite d'abord » donne un bocal de pièces toutes pareilles ; recomposer le bocal à chaque centime changerait jusqu'à 18 objets d'un coup |
| R-1.2 | Dans la sauvegarde, le montant du bocal fait foi ; si le détail des coupures ne tombe pas juste, le bocal est recomposé pour ce montant | Un détail abîmé ne doit jamais créer ou détruire de l'argent |
| R-1.3 | Le débordement est réel : le bocal est ouvert, le tas dépasse et des pièces roulent sur le comptoir, dans la limite de 24 objets en plus | Plus parlant qu'un compteur |
| R-1.4 | En pastille et en bandeau, le bocal est en pause ; ce qui est gagné tombe au retour | Tenir la charge processeur du widget |
| R-1.5 | Le jeu ne redessine l'écran que si quelque chose bouge | Mesuré : au repos, de 30 à 45 % d'un cœur à environ 1 % |
| R-1.6 | Les illustrations de coupures sont détourées par le jeu, par leur forme | Gemini ne produit pas de fond transparent ; un détourage à la main serait une corvée |
| R-1.7 | Secouer le bocal se fait à la touche Espace, pas en faisant glisser le bocal | Le glisser sert déjà à attraper une pièce |

## Repris du GDD v1

| # | Intention v1 | Statut |
|---|---|---|
| V1 | Fournée ratée si le focus est abandonné : ingrédients perdus, miaulement d'encouragement | repris tel quel |
| V2 | Ustensiles comme clés de progression des recettes | repris |
| V3 | Objets éphémères d'une semaine (fleurs, bougie, café) | repris |
| V4 | Ticket de caisse en fin de journée | repris |
| V5 | Chips désigne les objets au premier lancement (seul tutoriel) | repris |
| V6 | Chips rapporte des objets trouvés | repris |
| V7 | Pas de prestige ni de remise à zéro | repris |
| V8 | Sensation « coussin » des pièces | repris, en écrasement visuel à l'impact |
| V9 | Livre de comptes à onglets (historique, statistiques, notes) | repris, réparti entre le livret et le bloc-notes |

## Écarts assumés par rapport à la v1

| # | v1 | Refonte | Raison |
|---|---|---|---|
| E1 | Fenêtres à volets, la rue n'est jamais montrée | On sort : la rue est une vue fixe en face de la pâtisserie | D4, D18 |
| E2 | Argent utilisable le lendemain matin (rituel du rideau) | Argent utilisable après dépôt à la banque | D9 |
| E3 | Aucun personnage visible | Honoré est visible dans sa boutique | D3 |
| E4 | Widget Android en plateforme secondaire | Reporté après la v1.0 (voir D27) | Un jeu Godot ne peut pas être lui-même un widget d'écran d'accueil ; il faudra un widget natif à côté |
| E5 | Radios FIP et Nova | Disques locaux en v1.0 | P7 |
| E6 | Tables pour des clients dans le salon | Pas de clients | D11 : pas de vente |
| E7 | « Rangement » des pièces à la main | Supprimé | D12 |

## Correction

- Le diagnostic du 8 octobre indiquait « 10+ recettes rédigées ». Le fichier `src/data/recipes.ts` en contient **6**. Corrigé dans `brainstorming-session-2026-10-08.md`.
