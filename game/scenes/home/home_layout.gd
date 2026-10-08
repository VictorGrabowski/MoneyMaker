## Plan de la maison, en coordonnées du décor (3840 × 1080, soit deux écrans de large).
## De gauche à droite : le coin bureau, le comptoir, la cuisine.
## Tout ce qui se place à l'œil est ici : à retoucher quand les vrais décors arriveront.
extends RefCounted

const WORLD_SIZE := Vector2(3840.0, 1080.0)
const VIEW_SIZE := Vector2(1920.0, 1080.0)
## Ligne où le mur rencontre le sol.
const FLOOR_Y := 820.0
## Hauteur du dessus des meubles (bureau, comptoir, plan de travail).
const TABLE_Y := 640.0

# --- Ouvertures sur l'extérieur ---
const WINDOW := Rect2(300.0, 210.0, 420.0, 390.0)
const DOOR := Rect2(1270.0, 170.0, 380.0, 650.0)

# --- Coin bureau ---
const DESK := Rect2(140.0, 640.0, 770.0, 180.0)
const CORK_BOARD := Rect2(60.0, 250.0, 190.0, 170.0)
const DESK_LAMP := Vector2(215.0, 640.0)
const PAY_SHEET := Rect2(360.0, 600.0, 170.0, 46.0)
const WIDGET_FRAME := Rect2(590.0, 548.0, 120.0, 92.0)
## Chevalet « Au travail » / « Au repos », posé sur le bureau.
const WORK_SIGN := Rect2(752.0, 568.0, 140.0, 72.0)
const CALENDAR := Rect2(790.0, 230.0, 180.0, 230.0)
const BAROMETER := Rect2(992.0, 290.0, 110.0, 110.0)

# --- Poteaux qui séparent les trois coins de la maison (bord gauche de chacun) ---
const POST_WIDTH := 34.0
const POSTS: Array[float] = [1118.0, 2928.0]

# --- Comptoir ---
const COUNTER := Rect2(1760.0, 640.0, 1160.0, 180.0)
const SLATE := Rect2(1790.0, 140.0, 360.0, 150.0)
const TILL := Rect2(1790.0, 540.0, 160.0, 100.0)
## Place du bocal sur le comptoir : sa vignette est plus large que lui, pour montrer les pièces
## qui débordent. Son bas est calé sur le dessus du comptoir.
const JAR_SPOT := Rect2(1960.0, 200.0, 560.0, 440.0)
const WALL_SHELVES: Array[Rect2] = [Rect2(2480.0, 300.0, 410.0, 16.0), Rect2(2480.0, 430.0, 410.0, 16.0)]
const CLOCHES: Array[Vector2] = [Vector2(2590.0, 640.0), Vector2(2725.0, 640.0), Vector2(2860.0, 640.0)]
const CHANDELIER := Vector2(2680.0, 150.0)

# --- Cuisine ---
const WORKTOP := Rect2(2960.0, 640.0, 560.0, 180.0)
const OVEN := Rect2(3070.0, 666.0, 300.0, 132.0)
const BOOKSHELF := Rect2(3010.0, 250.0, 360.0, 190.0)
const COFFEE_MACHINE := Rect2(3400.0, 540.0, 96.0, 100.0)
const PANTRY := Rect2(3570.0, 230.0, 230.0, 590.0)

# --- Gros plans ---
## Taille du bocal agrandi ; il est centré à l'écran, un peu plus haut que le milieu pour laisser
## la place de son étiquette.
const CLOSEUP_JAR_SIZE := Vector2(1160.0, 900.0)
const CLOSEUP_JAR_LIFT := 20.0

# --- Balayage ---
## Largeur de la bande, sur chaque bord de l'écran, où la souris fait défiler la maison.
const PAN_EDGE := 150.0
const PAN_SPEED := 1500.0
## Au lancement, c'est le bocal qui est au centre de l'écran.
const START_FOCUS_X := 2240.0


## Place du bocal en gros plan, dans un écran de cette taille.
static func closeup_jar(view: Vector2) -> Rect2:
	var position := (view - CLOSEUP_JAR_SIZE) / 2.0 - Vector2(0.0, CLOSEUP_JAR_LIFT)
	return Rect2(position, CLOSEUP_JAR_SIZE)
