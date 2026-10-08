---
title: 'MoneyMaker — Direction artistique et prompts Gemini'
created: '2026-10-08'
updated: '2026-10-08'
status: 'en vigueur — parti pris validé par Victor le 2026-10-08'
source: 'gdds/gdd-MoneyMaker-2026-10-08/gdd.md, section Art and Audio Direction'
---

# Direction artistique et prompts Gemini

## 1. Le style en une phrase

**Une illustration de livre pour enfants, à l'encre et à l'aquarelle, sur papier à grain** — exactement ce qu'est déjà le dessin de Chips (`src/assets/hub/chips_sleeping_day.png`). Tout le reste du jeu s'aligne sur lui.

| On veut | On refuse |
|---|---|
| Trait d'encre brun-noir, irrégulier | Photoréalisme, rendu 3D lisse |
| Lavis d'aquarelle, auréoles, grain du papier | Dégradés numériques, reflets brillants |
| Palette chaude et courte | Néons, verre dépoli, couleurs saturées |
| Lumière neutre et diffuse | Rayons de soleil, ombres portées marquées, halos peints |
| Objets sans texte | Lettres, chiffres, logos, filigranes |

**Pourquoi une lumière neutre :** le jeu teinte lui-même le décor selon l'heure et la météo, et ajoute les halos des guirlandes, de la lampe et du four. Un décor peint « à l'heure dorée » ne pourrait plus passer à la nuit.

## 2. Qui fait quoi

| Toi, avec Gemini | Moi, dans le projet |
|---|---|
| Décors, objets, personnages, coupures, pâtisseries, produits | Détourage, recadrage, conversion, nommage |
| | Verre du bocal, halos de lumière, pluie, neige, buée, grain du papier |
| | Teinte jour/nuit, parallaxe, ombres portées |
| | Volumes 3D des pièces et des billets (tes dessins sont plaqués dessus) |
| | Faces provisoires en attendant tes images (déjà dans le prototype) |

Je ne sais pas peindre une aquarelle : pour tout ce qui est illustré, les prompts ci-dessous sont le bon chemin. Blender ne sera utile que si un objet du bocal demande une forme particulière (un lingot biseauté, par exemple).

## 3. Méthode avec Gemini

1. **Joins toujours le dessin de Chips** comme référence de style. C'est ce qui tient la cohérence d'une image à l'autre.
2. **Colle le bloc STYLE** en tête de chaque prompt, puis le bloc de cadrage (DÉCOUPE, FACE ou DÉCOR), puis la description.
3. **Ne demande jamais de fond transparent.** Gemini dessine alors un damier dans l'image (c'est ce qui est arrivé à `bocal_overlay.png` dans la v1). Demande un fond blanc uni ; je détoure.
4. **Un objet par image.** Les planches de plusieurs objets sortent à des échelles et des angles différents.
5. **Corrige par retouche plutôt que par nouveau tirage :** « même image, mais sans le vase », « même personnage, même cadrage, il sourit ». Gemini garde alors le reste identique.
6. **Pour un objet blanc ou très clair** (œufs, farine, crème, assiette), remplace le fond blanc par un bleu-gris uni `#C9D6DF`.

**Dépôt des images :** `game/assets/art/_inbox/`, avec le nom de fichier indiqué. Garde le format et la taille d'origine ; je m'occupe du reste.

**Avant de garder une image, vérifie :**

- le trait et le grain ressemblent à ceux de Chips ;
- aucun texte, aucun filigrane dans le cadre utile (l'étoile de Gemini en bas à droite doit tomber hors de l'objet) ;
- l'objet est entier, non coupé par le bord ;
- la lumière est plate : pas de rayon, pas de halo.

## 4. Les blocs à coller

### STYLE (toujours)

```text
STYLE — Hand-drawn children's-book illustration in ink and watercolor on cold-press paper.
Brown-black ink outline of uneven, slightly wobbly thickness. Soft watercolor washes with
visible pigment blooms and paper grain. Warm, limited palette: honey amber, cream, walnut
brown, golden crust, cocoa-brown ink, with a few small muted accents.
Soft, even, diffuse daylight. No strong cast shadows, no sunbeams, no glow, no lens effects.
Not photorealistic, not a 3D render, not vector art, not pixel art, no glossy digital shading.
No people, no text, no letters, no numbers, no logo, no watermark, no frame, no border.
Match the line quality and paint texture of the attached illustration of the sleeping cat.
Use it for style only; do not draw the cat unless asked.
```

### DÉCOUPE (objets, personnages)

```text
CUTOUT — One single subject, centered, fully visible, filling about 80% of a square image,
isolated on a perfectly flat, uniform, pure white background (#FFFFFF).
No ground shadow, no surface underneath, no scenery.
```

### FACE (pièces et billets)

```text
FLAT FACE — The subject is seen exactly from the front, perfectly flat, with no perspective,
no tilt and no thickness visible. It fills 92% of the image and is centered on a pure white
background. No shadow.
Exception to the style rules: the value described below must be drawn large and clearly
legible, in hand-lettered numerals. No other text.
The outer ink outline is bold, about 8% of the subject's radius: the subject will be shown
very small, around 60 pixels wide.
```

### DÉCOR (lieux)

```text
SCENE — Wide interior or street view at eye level, camera straight on, horizon at 45% of the
image height. All lamps, fairy lights and ovens are switched OFF. Shelves, counters and tables
are completely EMPTY: no objects, no food, no books, no plants. No people, no animals.
Widest landscape format available.
```

## 5. Lot 1 — L'argent (à faire en premier)

C'est le lot qui transforme le bocal. 17 images, toutes en vue de face.

**Ces images se déposent directement dans `game/assets/art/money/`**, sous le nom indiqué, sans passer par `_inbox` : le jeu les détoure lui-même par leur forme et les utilise au lancement suivant, à la place de la face provisoire. Le dessin doit occuper environ 92 % de l'image, sur fond blanc. Vérifié avec deux fausses images ; pas encore avec un vrai dessin.

**Parti pris validé : une monnaie « maison », basée sur l'euro.** Mêmes valeurs, mêmes tailles relatives et mêmes couleurs dominantes que l'euro, et tous les montants du jeu restent en euros ; seuls les motifs sont propres au jeu. Les valeurs à dessiner sont donc exactement celles des vraies pièces et des vrais billets.

**Pièces** — image carrée, STYLE + FACE, puis :

```text
A round coin made of {METAL}. A thin decorative ring runs near the edge.
In the centre: {MOTIF}. Below or beside it, the value "{VALEUR}".
```

| Fichier | METAL | MOTIF | VALEUR |
|---|---|---|---|
| `coin_1_face.png` | `warm copper` | `a single grain of wheat` | `1` |
| `coin_2_face.png` | `warm copper` | `an egg` | `2` |
| `coin_5_face.png` | `warm copper` | `a small whisk` | `5` |
| `coin_10_face.png` | `pale brass gold` | `a cat's paw print` | `10` |
| `coin_20_face.png` | `pale brass gold` | `a croissant` | `20` |
| `coin_50_face.png` | `pale brass gold` | `an ear of wheat crossed with a wooden spoon` | `50` |
| `coin_100_face.png` | `silver centre with a brass-gold outer ring` | `a sitting cat seen from behind` | `1` |
| `coin_200_face.png` | `brass-gold centre with a silver outer ring` | `a cat curled up asleep` | `2` |

Un seul dessin par pièce suffit : il sert pour les deux faces. Si tu veux un revers, ajoute `_back` au nom avec le même métal et, comme motif, `a simple laurel wreath`, sans valeur.

**Billets** — image au format 2:1 (paysage), STYLE + FACE, puis :

```text
A banknote, a rectangle twice as wide as it is tall, with softly rounded corners and a thin
ornamental border. Dominant colour: {COULEUR}, as a pale watercolor wash on cream paper.
On the left third, the value "{VALEUR}" in large numerals. On the right two thirds: {MOTIF},
drawn as a delicate engraving-style illustration.
```

| Fichier | COULEUR | MOTIF | VALEUR |
|---|---|---|---|
| `bill_5_face.png` | `grey-green` | `a plate of chocolate chip cookies` | `5` |
| `bill_10_face.png` | `soft brick red` | `a braided brioche` | `10` |
| `bill_20_face.png` | `soft blue` | `a lemon meringue tart` | `20` |
| `bill_50_face.png` | `warm orange` | `an old cast-iron oven with its door ajar` | `50` |
| `bill_100_face.png` | `sage green` | `a glass jar filled with coins` | `100` |
| `bill_200_face.png` | `straw yellow` | `the front of a small village grocery with a striped awning` | `200` |
| `bill_500_face.png` | `soft violet` | `a country house with an open door and a garden` | `500` |

**Lingot et gemme** — STYLE + FACE :

| Fichier | Format | Description |
|---|---|---|
| `ingot_face.png` | 2:1 | `A gold bar seen from the front, a rounded rectangle, with a cat's paw print stamped in its centre. No value.` |
| `gem_face.png` | carré | `A cut gemstone the colour of amber caramel, seen from the front, with simple facets. No value.` |

## 6. Lot 2 — La maison

**Le décor en trois plans.** La parallaxe vient de leur décalage.

| Fichier | Plan | Prompt (après STYLE + DÉCOR) |
|---|---|---|
| `home_room.png` | Milieu | Voir ci-dessous |
| `home_outside.png` | Fond | `A quiet country garden seen through an open doorway: a gravel path, lavender bushes, a low stone wall, soft trees in the distance, a pale sky. The door frame itself is not in the picture.` |
| `home_front_left.png` | Premier plan | STYLE + DÉCOUPE : `The top of a straw-seated wooden chair back, seen from behind and slightly from above, cropped at the bottom edge of the image.` |
| `home_front_right.png` | Premier plan | STYLE + DÉCOUPE : `The corner of a wooden table seen from above at a low angle, cropped at the bottom and right edges of the image.` |

`home_room.png` — joins aussi `src/assets/hub/salon_day.png` comme référence de **composition** :

```text
The inside of a small country pastry shop that is also someone's home.
Use the second attached image only for the layout of the room; redraw it entirely in the
style of the first attached image, and remove every movable object.
From left to right:
- a quiet desk corner: a small wooden desk against the wall, a bare cork board and a blank
  wall calendar above it, a window with thin curtains;
- in the middle: a glazed wooden door standing wide open (the opening itself painted as a
  flat pure white shape, to be replaced later), a long wooden counter with an old cash
  register, two empty wall shelves above it;
- on the right: a kitchen corner with a wooden worktop, a built-in oven with a glass door,
  an empty bookshelf, a tall closed pantry cupboard.
Stone floor, cream plastered walls, dark wooden beams, a string of unlit fairy lights along
the ceiling, an unlit wrought-iron chandelier.
```

**Objets de la maison** — STYLE + DÉCOUPE, un par image :

| Fichier | Description |
|---|---|
| `prop_sacoche.png` | `A small canvas money pouch with a leather drawstring, closed and full.` |
| `prop_sacoche_vide.png` | `The same small canvas money pouch with a leather drawstring, open and empty.` |
| `prop_livret.png` | `A small closed savings passbook with a dark green cloth cover, seen from above at a slight angle.` |
| `prop_fiche_paie.png` | `A single sheet of cream paper with faint blank ruled lines, lying flat, seen from above.` |
| `prop_calendrier.png` | `A wall calendar with a blank grid of squares and a blank illustration area at the top.` |
| `prop_minuteur.png` | `A round mechanical kitchen timer with a blank dial and a single pointer, cream enamel.` |
| `prop_poste.png` | `A small vintage wooden radio with a fabric speaker grille and two round knobs.` |
| `prop_caisse.png` | `An old brass cash register with round keys left blank and a small paper slot on top.` |
| `prop_boite_gateaux.png` | `A round metal biscuit tin with a plain lid, slightly dented.` |
| `prop_vase.png` | `An empty stoneware vase.` |
| `prop_bouquet.png` | `A loose bouquet of small seasonal wildflowers, stems together, without a vase.` |
| `prop_bougie.png` | `A short beeswax candle in a small ceramic holder, unlit.` |
| `prop_machine_cafe.png` | `A compact vintage espresso machine in cream enamel and chrome.` |
| `prop_gamelle.png` | `A small ceramic cat bowl, empty.` |
| `prop_coussin.png` | `A round, slightly flattened cat cushion in faded linen.` |
| `prop_colis.png` | `A parcel wrapped in brown kraft paper and tied with string.` |
| `prop_planche.png` | `A round wooden serving board, empty, seen from the front at a low angle.` |
| `prop_assiette.png` | `A white porcelain cake plate on a short foot, empty, seen from the front at a low angle.` (fond bleu-gris) |

La cloche en verre et le bocal sont dessinés par le jeu : un objet transparent ne se détoure pas proprement.

## 7. Lot 3 — Chips

Joins le dessin de Chips. STYLE + DÉCOUPE, puis, **dans chaque prompt** :

```text
The same cat as in the attached illustration: a black cat with warm russet-brown patches on
the back and shoulders, short fur, small pink inner ears. Same coat pattern, same proportions.
```

| Fichier | Posture |
|---|---|
| `chips_boule.png` | Existe déjà (`chips_sleeping_day.png`) |
| `chips_pain.png` | `Sitting in a loaf position, paws tucked under, eyes half closed, seen from the side.` |
| `chips_assis.png` | `Sitting upright, tail wrapped around the paws, seen from three-quarters front.` |
| `chips_etire.png` | `Stretching, front paws far forward and back arched, seen from the side.` |
| `chips_farine.png` | `Lying on its side, relaxed, belly towards the viewer, with white flour dust on its paws and fur.` |
| `chips_toilette.png` | `Sitting and licking one raised front paw.` |
| `chips_regard.png` | `Sitting, head turned towards the viewer, eyes open and looking straight at the viewer.` |
| `chips_patte.png` | `Crouching, one front paw stretched forward as if tapping a small object.` |
| `chips_guet.png` | `Sitting seen from behind, head slightly raised, as if watching through a window.` |
| `chips_pattes_widget.png` | `Only the two front paws and the top of the head with the ears, peeking over a horizontal edge, seen from the front.` |

Je produis la version de nuit en teintant ces images : inutile de les refaire en bleu.

## 8. Lot 4 — Pâtisseries du livre 1

STYLE + DÉCOUPE, puis `seen from the front at a low three-quarter angle, without plate or support` :

| Fichier | Description |
|---|---|
| `pastry_cookies.png` | `A small stack of five chocolate chip cookies.` |
| `pastry_mug_cake.png` | `A chocolate mug cake risen above the rim of a plain stoneware mug.` |
| `pastry_brioche_tressee.png` | `A golden braided brioche loaf.` |
| `pastry_focaccia.png` | `A rectangular rosemary focaccia with dimples and coarse salt.` |
| `pastry_tarte_citron.png` | `A whole lemon meringue tart with piped, lightly toasted meringue.` |
| `pastry_foret_noire.png` | `A whole Black Forest cake with whipped cream, chocolate shavings and cherries on top.` |

Les trois niveaux de maîtrise (planche, assiette, cloche) sont assemblés par le jeu à partir de ces images et des supports du lot 2.

## 9. Lot 5 — Papiers et gros plans

STYLE + DÉCOUPE, `seen from directly above, lying flat` :

| Fichier | Description |
|---|---|
| `paper_livre_ouvert.png` | `An open hardback book, both pages completely blank cream paper, with a ribbon bookmark.` (format 16:9) |
| `paper_livre_1_couverture.png` | `A closed hardback cookbook with a plain cloth cover in warm terracotta, a blank label on the front.` |
| `paper_bloc_notes.png` | `A small spiral-bound notepad, top page blank cream paper with faint ruled lines.` |
| `paper_crayon.png` | `A short, well-used wooden pencil.` |
| `paper_livret_ouvert.png` | `An open savings passbook with blank ruled columns on both pages.` (format 16:9) |
| `paper_cheque.png` | `A blank bank cheque with empty lines and an ornamental border.` (format 2:1) |
| `paper_ticket.png` | `A long, narrow, blank till receipt with a torn top edge, slightly curled.` (format 1:3) |
| `paper_carnet_ouvert.png` | `An open order book with kraft-paper pages, blank.` (format 16:9) |
| `paper_petit_mot_1.png` | `A small folded note on cream paper, blank.` |
| `paper_petit_mot_2.png` | `A small square of torn graph paper, blank.` |
| `paper_petit_mot_3.png` | `A blank postcard-sized card with a drawing-pin hole at the top.` |
| `paper_etiquette_kraft.png` | `A blank kraft-paper luggage tag with a short string.` |
| `paper_ardoise.png` | `A small blank slate chalkboard in a wooden frame.` |
| `paper_tampon.png` | `A round ink stamp impression showing a cat's paw print, in faded brown ink.` |

Tout texte (recettes, montants, petits mots) est écrit par le jeu par-dessus ces fonds.

## 10. Lot 6 — La rue

La rue est **une seule vue** : ce qu'on voit depuis le seuil de la pâtisserie, en regardant en face. Trois images suffisent, pour garder un peu de profondeur.

| Fichier | Plan | Prompt |
|---|---|---|
| `street_view.png` | Milieu | STYLE + DÉCOR, puis le texte ci-dessous |
| `street_lointain.png` | Fond | STYLE, format 4:1 : `A distant line of village rooftops and a church steeple against soft rolling hills, pale and hazy, as a horizontal band on a pure white background.` |
| `street_seuil.png` | Premier plan | STYLE, format 16:9 : `A wooden doorway seen from inside a shop, looking out: the two door jambs along the left and right edges of the image and the lintel along the top, with a terracotta flower pot at the foot of the right jamb. The whole opening in the middle is a flat pure white shape.` |

`street_view.png` :

```text
A quiet village street seen straight on from the doorway of a pastry shop, looking at the
buildings on the opposite side of the street. Flat front view, eye level.
On the left: the front of a tiny old village bank in pale stone, with a heavy closed wooden
door, one barred window, and beside the door a small walk-up deposit counter set into the
wall: a polished brass hatch under a little canopy, at hand height.
In the middle: a small round stone fountain with a wooden bench.
On the right: the front of a small village grocery, a wooden shopfront painted dark green,
a large window, a door with a small bell above it, a striped awning, and empty wooden crates
on trestles outside.
Old cobblestones across the bottom of the image. Blank signs above both doors.
The sky above the rooftops is a flat pure white shape, to be replaced later.
No vehicles.
```

Le guichet de la banque et la porte de l'épicerie sont les deux endroits cliquables : ils doivent être bien visibles et ne pas se toucher.

Les 12 petites scènes de rue (chat du voisin sur le muret, vélo appuyé, linge qui sèche…) viendront après : même méthode, un sujet par image, en DÉCOUPE.

## 11. Lot 7 — L'épicerie et Honoré

**Intérieur** — `grocery_interior.png`, STYLE + DÉCOR :

```text
The inside of an old village grocery seen from the customer's side. A long wooden counter
runs across the lower third. Behind it, floor-to-ceiling wooden shelves, all completely
EMPTY. On the counter: an old cash register with blank keys, a brass scale, an empty wicker
basket. On the left wall, a bare cork notice board. Hanging from the ceiling, unlit enamel
lamps. Wooden floor. Nobody behind the counter.
```

**Honoré** — STYLE + DÉCOUPE, d'abord l'image de base, puis les quatre autres par retouche (« same character, same clothes, same framing, … ») :

```text
A friendly French village grocer in his sixties, seen from the waist up, facing the viewer:
round wire glasses, a grey moustache, thinning grey hair, rolled-up cream shirt sleeves and
a long dark-green apron. Hands resting on an invisible counter in front of him.
Calm, neutral expression.
```

| Fichier | Retouche |
|---|---|
| `honore_neutre.png` | Image de base |
| `honore_souriant.png` | `he smiles warmly` |
| `honore_surpris.png` | `he raises his eyebrows in pleasant surprise` |
| `honore_attendri.png` | `he tilts his head with a soft, moved smile` |
| `honore_malicieux.png` | `he gives a knowing half-smile, one eyebrow raised` |
| `honore_gilet.png` | `he wears a thick knitted cardigan over his shirt instead of the apron, and looks slightly sleepy` |

Tu as validé Honoré tel quel ; la description reste modifiable à ton goût avant de générer.

**Produits** — STYLE + DÉCOUPE, `a single grocery product seen from the front, with a blank label` :

| Fichier | Description | Fond |
|---|---|---|
| `product_farine.png` | `A paper sack of flour.` | bleu-gris |
| `product_sucre.png` | `A paper bag of sugar.` | bleu-gris |
| `product_sucre_glace.png` | `A small cardboard box of icing sugar with a metal sifter top.` | bleu-gris |
| `product_beurre.png` | `A block of butter wrapped in foil-lined paper.` | blanc |
| `product_oeufs.png` | `An open cardboard box of six brown eggs.` | blanc |
| `product_lait.png` | `A glass bottle of milk with a foil cap.` | bleu-gris |
| `product_creme.png` | `A small glass jar of cream with a cloth cover.` | bleu-gris |
| `product_chocolat_noir.png` | `A bar of dark baking chocolate, wrapper half opened.` | blanc |
| `product_pepites.png` | `A small paper bag of chocolate chips, open.` | blanc |
| `product_cacao.png` | `A round tin of cocoa powder.` | blanc |
| `product_levure_chimique.png` | `A few small paper sachets of baking powder held by a paper band.` | bleu-gris |
| `product_levure_boulangere.png` | `Three small paper sachets of baker's yeast.` | bleu-gris |
| `product_sel.png` | `A cardboard cylinder of table salt.` | bleu-gris |
| `product_fleur_de_sel.png` | `A small stoneware pot of sea salt with a cork lid.` | blanc |
| `product_vanille.png` | `A tiny brown glass bottle of vanilla extract.` | blanc |
| `product_vanille_gousses.png` | `A slim glass tube holding two vanilla pods.` | blanc |
| `product_citrons.png` | `A small net of four lemons.` | blanc |
| `product_huile_olive.png` | `A tall glass bottle of olive oil with a cork.` | blanc |
| `product_romarin.png` | `A bunch of fresh rosemary tied with string.` | blanc |
| `product_griottes.png` | `A glass jar of sour cherries in syrup.` | blanc |
| `product_kirsch.png` | `A small clear glass bottle of cherry brandy.` | bleu-gris |
| `product_amandes.png` | `A small paper bag of ground almonds.` | blanc |
| `product_miel.png` | `A glass jar of dark chestnut honey with a cloth cover.` | blanc |
| `product_fruits_saison.png` | `A small wooden punnet of seasonal fruit.` | blanc |
| `product_croquettes.png` | `A paper bag of cat kibble with a blank label.` | blanc |
| `product_cafe.png` | `A paper bag of coffee beans, folded shut with a clip.` | blanc |

**Ustensiles** — même méthode :

| Fichier | Description |
|---|---|
| `tool_rouleau.png` | `A wooden rolling pin.` |
| `tool_moule_tarte.png` | `A fluted metal tart tin.` |
| `tool_moule_genoise.png` | `A round metal cake tin.` |
| `tool_tamis.png` | `A round flour sieve with a wooden rim.` |
| `tool_poche_douille.png` | `A cloth piping bag with a metal star nozzle.` |
| `tool_thermometre.png` | `A sugar thermometer with a blank scale.` |
| `tool_chalumeau.png` | `A small kitchen blowtorch.` |
| `tool_batteur.png` | `A vintage electric hand mixer in cream enamel.` |

## 12. Ordre conseillé

| Priorité | Lot | Images | Débloque |
|---|---|---|---|
| 1 | L'argent | 17 | Epic 1 : le bocal avec tes dessins |
| 2 | La maison | 4 plans + 18 objets | Epic 2 |
| 3 | Chips | 9 | Epics 2 et 7 |
| 4 | Pâtisseries, papiers | 6 + 14 | Epics 3 et 4 |
| 5 | La rue | 3 | Epic 5 |
| 6 | L'épicerie et Honoré | 1 + 6 + 34 | Epic 6 |

Un premier essai utile avant de tout lancer : **trois images seulement** — `coin_100_face.png`, `bill_20_face.png` et `chips_assis.png`. Si elles tiennent à côté du dessin de Chips, la méthode est bonne ; sinon on ajuste le bloc STYLE avant de produire la centaine d'autres.

## 13. Images de la v1

| Image | Sort |
|---|---|
| `chips_sleeping_day.png`, `chips_sleeping_night.png` | Gardées : référence de style et première posture |
| `salon_day.png` | Gardée comme référence de composition, pas dans le jeu |
| Pièces et billets photographiques | Remplacés par le lot 1 |
| `bureau_bg.png`, `kitchen_*.png`, `salon_*.png`, `bocal_*.png` | Remplacés par le lot 2 |
| `golden_bar.png`, `daimond.png` | Remplacés par le lot 1 |
