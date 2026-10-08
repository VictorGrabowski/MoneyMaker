---
title: 'Game Brainstorming Session — Refonte MoneyMaker'
date: '2026-10-08'
author: 'Victor'
version: '1.0'
stepsCompleted: [1, 2, 3, 4]
status: 'complete'
mode: 'YOLO (analyse brownfield + premier lot d''idées, triées par Victor le 2026-10-08)'
inputDocuments: ['archive-v1-electron/game-brief.md', 'archive-v1-electron/gdd.md', 'archive-v1-electron/brainstorming-session-2026-01-23.md', 'archive-v1-electron/epics/polish-epic.md', 'code source v1.1.2']
---

> **Suite donnée :** Victor a trié ces idées le 8 octobre 2026. Ses arbitrages sont dans
> `planning-artifacts/gdds/gdd-MoneyMaker-2026-10-08/decision-log.md` et le résultat dans le `gdd.md` du même dossier.
> Retenu : fournée, interface diégétique, carnet de commandes à choix, routine de Chips. Écarté : pourboires (idée 1), table de tri (idée 10).

# Game Brainstorming Session — Refonte MoneyMaker

## Session Info

- **Date :** 2026-10-08
- **Facilitateur :** Game Designer Agent (BMAD GDS `gds-brainstorm-game`)
- **Participant :** Victor
- **Demande :** analyser l'existant, en extraire le « mood », proposer un maximum d'améliorations, trancher entre évolution et refonte.

---

## 1. Diagnostic de l'existant (v1.1.2)

### Ce qui existe vraiment

| Zone | État réel dans le code |
|---|---|
| **Compteur de salaire** | Fonctionne. Calcul à partir du net mensuel + jours/horaires/pause déj. (`salaryStore.ts`). Rattrapage animé à l'ouverture. |
| **Bocal physique** | Fonctionne, c'est la pièce la plus aboutie : Matter.js, 19 dénominations (1 c → 💎 10 k€), 25 recettes de fusion, zoom, secousse, plafond de dénomination (`BocalView.tsx`, ~1 300 lignes). |
| **Widget** | Fenêtre 250×100 always-on-top, forcée en bas à droite. |
| **Hub** | 2 zones (bureau / salon) = images fixes + zones cliquables invisibles. |
| **Pomodoro pâtisserie** | 6 recettes rédigées (vraies instructions + phrases d'ambiance), timer par phases de 25 min. |
| **Plantes** | Boutique gratuite, soin, croissance par jour réel, herbier, inventaire. Visuels = placeholders. |
| **Radio** | 3 flux (Nova, FIP, France Info) via Howler. |
| **Météo / jour-nuit** | Bascule manuelle uniquement, pas d'API ni d'heure réelle. |

### Ce qui cloche

**Boucle de jeu — le vrai problème**
- **L'argent ne sert à rien.** Il s'accumule, on peut le secouer, c'est tout. Aucun puits (la boutique est gratuite), aucun objectif.
- **Finir une recette ne donne rien.** `completePhase()` s'arrête sur un `TODO: Trigger a global 'Recipe Complete' event`. Pas de pâtisserie obtenue, pas de collection, pas de trace.
- **Aucune quête, aucune progression, aucun secret.** Les piliers « Découverte Affective » et le Grimoire à débloquer du GDD ne sont pas implémentés.
- **Aucune mémoire.** Seuls le salaire et les horaires sont sauvegardés. Pas d'historique de gains, pas de « depuis le début », le timer et la recette en cours sont perdus à la fermeture. `lastSeen` est stocké mais jamais lu.

**Technique**
- **Deux systèmes de cuisine concurrents** : `cookingStore` (cookie/brownie + `GrimoireView`/`PrepStation`) et `bakingStore` (+ `RecipeBook`/`BakingView`). Le premier est du code mort.
- `LivingRoomView.tsx` utilise `useCookingStore` **sans l'importer** (composant `OvenTimer` jamais rendu, sinon crash).
- **Timer qui dérive** : `timeRemaining - 1` à chaque `setInterval`, au lieu d'un horodatage de fin. Faux dès que la fenêtre est throttlée ou le PC en veille.
- **Le salaire est recalculé, pas enregistré** : changer ses horaires réécrit le passé ; jours fériés, congés, heures sup impossibles.
- `BocalView.tsx` est un composant-dieu (physique + rendu + UI + spawn + fusion), intestable.
- Aucun test, aucun lint, `as any` sur la persistance, 19 `console.log`.
- L'architecture décrite dans `project-context.md` (logique dans le main process, `BurstManager`, object pooling, WebP) **n'existe pas** dans le code.
- Fenêtre forcée en 1920×1080 transparente sans cadre.

**Dépôt**
- `src/assets/hub/` contient **deux installeurs `potato_rotato-1.1.0-setup.exe` de 96 Mo** (une autre app) et un `.crdownload`. ~190 Mo de poids mort dans l'historique git.
- Fonds en PNG de 7–8 Mo chacun (≈ 33 Mo d'images de fond).

**Direction artistique — l'incohérence centrale**
- Le GDD demande du « 2D dessiné main, ni hyper-réaliste ». Les décors sont des **rendus 3D photoréalistes générés par IA** (filigrane ✦ encore visible), le chat Chips est une **aquarelle**, la machine à café est une **icône Lucide dans une carte en verre dépoli**, et l'UI est en **glassmorphism sombre** (`bg-black/60 backdrop-blur`, blobs indigo, majuscules espacées).
- Quatre langages visuels superposés. Le décor dit « pâtisserie de campagne », l'interface dit « dashboard SaaS ».

---

## 2. Le « mood »

### En une phrase
> **Une pâtisserie de campagne à l'heure dorée, porte ouverte sur le jardin, où l'argent tinte doucement dans un bocal pendant que quelque chose cuit et que le chat dort.**

### Ce que les assets racontent déjà (et qu'il faut garder)
- **Lumière** : contre-jour ambré par la porte vitrée, guirlandes lumineuses, lustre en fer forgé. La nuit : heure bleue, brume au jardin, seules les guirlandes restent chaudes.
- **Matières** : bois ciré, pierre au sol, cloches en verre, faïence blanche, cuivre, papier d'un livre ouvert.
- **Présence** : personne à l'écran, mais tout est habité — four allumé, livre ouvert, chaise tirée, **Chips** (écaille de tortue) roulée en boule.
- **Tempo** : rien ne clignote, rien ne presse. Le temps passe au rythme d'une cuisson.

### Mots-clés
`chaleur` · `tangible` · `lent` · `artisanal` · `intime` · `gourmand` · `refuge` · `petits rituels`

### Palette extraite
| Rôle | Jour | Nuit |
|---|---|---|
| Lumière | Ambre miel `#F2B866` | Guirlande `#FFD9A0` |
| Bois | Noyer `#6B4423` | Noyer sombre `#2B2230` |
| Fond | Crème `#F6E9D2` | Bleu heure bleue `#2A3350` |
| Accent | Beurre / croûte dorée `#D9902F` | Brume lavande `#8C93B8` |
| Encre | Brun cacao `#3A2618` | Ivoire `#EDE6D8` |

### Anti-mood (à bannir)
- Verre dépoli noir, néons, dégradés indigo, majuscules en `tracking-[0.6em]`.
- Tout vocabulaire de clicker / casino / « trillionaire » (déjà rejeté en janvier).
- Compteurs qui stressent : séries à ne pas briser, notifications culpabilisantes, minuteries rouges.
- L'interface flottante *par-dessus* le décor. **L'UI doit être dans le décor** : ardoise, étiquettes kraft, carnet, ticket de caisse, minuteur de cuisine.

### Références de ton
Lo-Fi Girl (fenêtre sur le monde), Animal Crossing (temps réel, collection), intérieurs Ghibli, *Unpacking* (rangement tactile), *A Little to the Left* (micro-manipulations satisfaisantes), *Spirit City: Lofi Sessions* et *Chill Pulse* (concurrents directs focus-cozy), *Rusty's Retirement* (jeu qui vit en bas de l'écran pendant qu'on travaille).

---

## 3. Verdict : évoluer ou refondre ?

**Recommandation : refonte, en récupérant le contenu — pas le code.**

| | Garder | Jeter |
|---|---|---|
| **Design** | Brief, GDD, piliers, Chips, le bocal, les plantes comme idée | — |
| **Données** | `recipes.ts` (le vrai trésor : recettes + phrases d'ambiance), table des dénominations, recettes de fusion, calcul des heures effectives | — |
| **Code** | Les formules de `salaryStore` (à réécrire en fonctions pures testées) | `BocalView` monolithique, les deux stores de cuisine, le hub en hotspots, la persistance par clé, la gestion de fenêtre |
| **Assets** | Chips, billets/pièces (à compresser) | Fonds photoréalistes filigranés, les `.exe` |

Pourquoi ne pas réparer : les quatre manques structurants (économie, progression, sauvegarde, rendu de scène) touchent tous les fichiers. Les ajouter par-dessus coûte plus cher que repartir d'un socle où ils sont au centre. L'app fait ~5 500 lignes, dont 1 300 dans un seul composant : la réécriture est petite.

### Socle technique proposé

**Option A — recommandée : Electron + React + TypeScript, scène en PixiJS**
- **Cœur de simulation en TS pur**, sans React ni DOM : temps, salaire, pomodoro, économie, quêtes. Tout est dérivé d'horodatages → exact après veille/fermeture, et testable (Vitest).
- **Journal de gains** : on enregistre des sessions réelles, on ne recalcule plus le passé.
- **Une seule sauvegarde versionnée** (JSON + migrations + backup), au lieu de clés éparses.
- **Scène PixiJS** (WebGL) pour le hub et le bocal : calques, parallaxe, particules, éclairage jour/nuit par teinte, des centaines de sprites à 60 fps. Physique : Matter.js conservé (ou Rapier si besoin de plus).
- **React uniquement pour les panneaux** (carnet, réglages), stylés papier/bois.
- **Deux fenêtres distinctes** (hub / widget) au lieu d'une fenêtre redimensionnée.
- On garde la CI de release existante.

**Option B — Godot 4** : meilleur outillage 2D (lumières, particules, animation, tilemaps), export Windows + Android natif. Mais nouveau langage, widget transparent always-on-top plus délicat, et on perd la réutilisation directe de `recipes.ts`. À choisir seulement si l'envie est de faire « un vrai jeu » plutôt qu'une app-compagnon.

**Option C — Tauri** : binaire 10× plus léger, même front. Gain réel mais secondaire ; migration possible plus tard depuis A.

---

## 4. Idées (YOLO lot 1 — 60 idées à trier)

Légende : ⭐ = je le mettrais dans la première version · 🔧 = socle · 🌱 = plus tard

### A. La boucle centrale (le cœur de la refonte)

1. ⭐ **L'argent réel devient la monnaie du jeu, sans jamais être « dépensé ».** Le bocal affiche le vrai gagné. À côté, une **cagnotte de pourboires** (« miettes ») gagnée par les pomodoros sert aux achats. Le salaire reste intact et honnête : ni plus, ni moins.
2. ⭐ **Une session focus = une fournée.** On choisit une recette → on prépare (30 s tactiles) → ça cuit pendant 25 min → on sort du four → la pâtisserie va en vitrine. Cycle complet, enfin fermé.
3. ⭐ **La vitrine se remplit.** Chaque pâtisserie réussie est posée sous une cloche du comptoir. Fin de journée : la vitrine est le résumé visuel de ton travail.
4. ⭐ **Les clients fantômes.** On ne voit personne, mais le soir la vitrine est vide et il reste des pourboires + un petit mot sur le comptoir (« La brioche était parfaite. — Mme L. »).
5. ⭐ **Pause = dégustation.** Les 5 min de pause ouvrent le hub : caresser Chips, arroser, ranger les pièces. Le hub *est* la récompense, comme prévu dans le brief.
6. **Recettes à phases = pomodoros enchaînés.** Brioche = pétrissage (25) + pousse (pause longue !) + cuisson (25). La pause fait partie de la recette : la pâte lève pendant que tu te reposes.
7. **Cuisson ratée douce.** Abandonner une session ne punit pas : la fournée devient « biscuits de Chips ». Rien n'est perdu, rien n'est honteux.
8. **Qualité de fournée.** Session sans interruption = dorure parfaite (variante visuelle dorée à collectionner). Jamais de malus, seulement un bonus.

### B. Le bocal et la physique (jouer avec son argent)

9. ⭐ **Le bocal reste la star**, réécrit en WebGL : plus d'objets, ombres douces, reflets du verre, tintements positionnés.
10. ⭐ **Table de tri.** On renverse le bocal sur la table en bois : empiler les pièces en rouleaux, lisser les billets, faire des liasses. Du rangement à la *Unpacking*.
11. ⭐ **Fusion manuelle.** Glisser deux pièces de 1 € l'une sur l'autre → une pièce de 2 € avec un petit « cling ». La fusion automatique reste en option.
12. **Rouleaux de pièces en papier kraft** : 25 pièces empilées → un rouleau étiqueté, objet physique à part entière.
13. **Tirelires thématiques** : un petit bocal par objectif réel (« Vacances », « Vélo »), qu'on alimente en y versant des pièces à la main. Jauge = hauteur de pièces.
14. **Le débordement de fin de mois** (promis dans le brief) : le bocal déborde sur le comptoir, puis au sol, Chips joue avec une pièce.
15. **Jour de paie.** Le jour réel de versement : le bocal se vide dans un coffre/livret avec une animation rituelle, un ticket de caisse du mois s'imprime, on repart d'un bocal vide.
16. **Chips pousse une pièce** du bord de la table de temps en temps. Elle vous regarde en le faisant.
17. **Pièces rares.** Une fois de temps en temps, une pièce commémorative tombe (2 € spéciale, vieille pièce en francs) → album de numismate.
18. **Mode bac à sable** : aimant, entonnoir, toboggan, balance à plateaux — des jouets physiques à débloquer.
19. **Pluie de pièces de rattrapage** scénarisée : à l'ouverture le matin, ce qui a été gagné la veille tombe en cascade, lissé sur 8 s.
20. **Convertisseur concret** : glisser un tas de pièces sur une étiquette (« un café », « un livre », « un plein ») pour voir combien ça fait. Rend la valeur tangible.

### C. Le hub — la maison

21. ⭐ **Un seul décor continu, en calques**, redessiné dans un style unique (gouache/aquarelle comme Chips) : fond, plans intermédiaires, premier plan, lumière. Parallaxe douce à la souris.
22. ⭐ **Vrai cycle jour/nuit** calé sur l'heure et le lever/coucher du soleil locaux, par teinte continue (aube, journée, heure dorée, heure bleue, nuit) plutôt que deux images.
23. ⭐ **Vraie météo** (Open-Meteo, gratuit, sans clé) : pluie sur la vitre, buée, neige au jardin. Bascule manuelle conservée.
24. ⭐ **L'UI est dans le décor** : ardoise pour les gains du jour, minuteur de cuisine pour le pomodoro, carnet pour les quêtes, radio en bakélite pour la musique, calendrier mural pour l'historique.
25. **Pièces de la maison débloquées progressivement** : boutique → arrière-cuisine → jardin → véranda → grenier. On glisse d'une pièce à l'autre.
26. **Décoration libre** : poser/déplacer meubles et objets achetés avec les pourboires (30–50 objets, comme prévu).
27. **Le jardin** remplace la boutique de plantes gratuite : on y fait pousser les ingrédients (menthe, fraises, citronnier) qui débloquent des recettes.
28. **Saisons réelles** : citrouilles en octobre, guirlandes en décembre, lilas en mai. Décor, recettes et lumière suivent.
29. **Objets vivants** : vapeur de la machine à café, pendule qui bat, poussières dans le rayon de soleil, rideau qui bouge quand la porte est ouverte.
30. **La fenêtre sur la rue** : ombres de passants, vélo, facteur le matin. Une présence humaine suggérée, jamais montrée.

### D. Chips

31. ⭐ **Chips a une routine** : dort au soleil le matin, change de place selon l'heure, s'installe près du four pendant une cuisson, sur le clavier (le widget) quand tu travailles trop tard.
32. ⭐ **Caresse = ronronnement** (son + légère vibration visuelle, idée de janvier).
33. **Chips apporte des cadeaux** : un bouton, une plume, une pièce rare trouvée sous un meuble.
34. **Chips signale les pauses** : elle s'étire et miaule à la fin d'un pomodoro, plutôt qu'une alarme.
35. **Chips te rappelle de partir** : après l'heure de fin de journée, elle s'assoit devant la porte.
36. **Carnet de Chips** : toutes ses positions/humeurs observées, à compléter comme un bestiaire.

### E. Quêtes, recettes, progression

37. ⭐ **Le carnet de commandes** : 3 petites commandes par jour, calmes et optionnelles (« Une fournée avant midi », « Arroser le basilic », « Ranger 20 pièces »). Aucune pénalité si ignorées, elles s'effacent le lendemain.
38. ⭐ **Le Grimoire Sucré** : chaque recette se débloque par une condition douce (X fournées, un ingrédient du jardin, une saison). Une page vide avec une silhouette donne envie.
39. ⭐ **Maîtrise d'une recette** en 3 étoiles (1, 5, 15 fournées) → variante visuelle, puis la *vraie* recette imprimable.
40. **Commandes des habitués** : une lettre arrive (« Pour l'anniversaire de ma fille, il me faudrait un fraisier »). Quête sur plusieurs jours, avec une histoire à la clé.
41. **Les habitués ont un fil narratif** distillé en 6–8 lettres chacun. Lore environnemental, zéro dialogue.
42. **Étapes de préparation tactiles** (30–60 s avant le timer) : casser des œufs, tamiser, pétrir en glissant la souris. Mini-rituel d'entrée en concentration, toujours passable.
43. **Les étapes d'ambiance existantes** (« Ça commence à sentir bon… ») s'affichent sur le minuteur et dans le widget pendant la cuisson, avec le four qui change visuellement.
44. **Événements saisonniers** : galette en janvier, bûche en décembre, tarte aux fraises en juin.
45. **Succès discrets** façon timbres dans un album, avec intitulés poétiques.
46. **Secrets cliquables** : ~20 objets du décor cachent un mot doux, une anecdote, une photo. Le pilier « Découverte Affective » du brief.
47. **Mots doux programmables** : un mode « auteur » où Victor écrit des messages qui apparaîtront à une date ou une condition donnée (le cadeau d'origine).

### F. Le widget (mode travail)

48. ⭐ **Widget = petit bocal vivant**, pas un compteur : quelques pièces qui tombent en vrai, l'anneau du minuteur autour, Chips qui dort dessus.
49. ⭐ **Plusieurs tailles** : pastille (montant seul), bandeau, mini-scène. Position libre et mémorisée.
50. **Mode « bas d'écran »** à la *Rusty's Retirement* : une bande du comptoir en bas de l'écran pendant le travail.
51. **Icône dans la zone de notification** avec le gain du jour au survol ; l'app vit dans le tray.
52. **Mode discret** : un raccourci masque les montants (partage d'écran, collègue derrière l'épaule).

### G. Temps, argent, mémoire

53. 🔧 **Journal des gains réel** : on enregistre chaque journée (heures, montant). Permet congés, jours fériés, heures sup, changement de salaire sans réécrire l'histoire.
54. 🔧 **Pointage optionnel** : « je commence / je termine » en un clic, ou automatique selon l'horaire.
55. ⭐ **Le ticket du matin** (idée de janvier) : imprimante thermique, résumé de la veille.
56. ⭐ **Calendrier mural** : chaque jour porte un tampon (fournées, gains). Vue mois = heatmap en tampons.
57. **Bilan annuel** façon « Wrapped » en décembre : total gagné, pâtisserie fétiche, heure préférée de Chips.
58. **Profils de revenu** : salarié mensuel, freelance au TJM, taux horaire, multi-employeurs.

### H. Son

59. ⭐ **Table de mixage d'ambiance** : radio, pluie, four, rue, chat, horloge — un curseur chacun (prévu au brief, absent du code).
60. ⭐ **Stations lo-fi/jazz** en plus de FIP et Nova, stations personnalisées par URL, et sons d'interface en matière (bois, verre, papier, pièces).

---

## 5. Proposition de découpage (si refonte validée)

| Jalon | Contenu | Résultat tangible |
|---|---|---|
| **0 — Ménage** | Retirer `.exe`/`.crdownload`, compresser les assets, lint + tests, extraire le cœur de sim en TS pur | Dépôt sain, formules testées |
| **1 — Socle** | Sauvegarde versionnée, journal de gains, horloge par horodatage, 2 fenêtres, scène PixiJS vide | Le compteur est juste, même après veille |
| **2 — Bocal 2** | Bocal WebGL, fusion manuelle, table de tri, widget-bocal | « Jouer avec son argent » |
| **3 — Fournée** | Boucle recette → cuisson → vitrine → pourboires, minuteur diégétique | Le pomodoro pâtisserie a un sens |
| **4 — Maison** | Décor en calques, jour/nuit et météo réels, Chips avec routine, mixage audio | Le « mood » est là |
| **5 — Carnet** | Commandes du jour, Grimoire à débloquer, maîtrise, secrets | Raison de revenir chaque jour |
| **6 — Au-delà** | Jardin, décoration, habitués, saisons, mode auteur | Profondeur |

---

## 6. Questions ouvertes pour Victor

1. **Socle** : option A (Electron + PixiJS) ou B (Godot) ?
2. **Destinataire** : toujours un cadeau pour une personne précise, ou une app pour toi / publiable ? (change le poids du « mode auteur » et des secrets)
3. **Direction artistique** : refaire les décors dans le style aquarelle de Chips, ou assumer le rendu 3D chaleureux actuel et y aligner Chips et l'UI ?
4. **Économie** : d'accord avec « le salaire ne se dépense jamais, les pourboires oui » (idée 1) ?
5. **Quelles idées gardes-tu, lesquelles t'ennuient ?** La suite du brainstorming (étape 3) creuse celles que tu choisis.
