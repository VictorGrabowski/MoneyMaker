## Décor provisoire de la maison, dessiné par le code en attendant les illustrations.
## Un nœud par plan : ce qu'on voit dehors, la pièce, les lumières, le premier plan.
## Les formes sont volontairement simples ; seules la palette et la lumière donnent déjà le ton.
extends Node2D

const Layout := preload("res://scenes/home/home_layout.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const Weather := preload("res://core/world/weather.gd")

enum Kind { OUTSIDE, ROOM, LIGHTS, FRONT }

const INK := Color(0.227, 0.149, 0.094, 0.85)
const WALL := Color(0.965, 0.914, 0.824)
const WALL_LOW := Color(0.910, 0.840, 0.720)
const FLOOR := Color(0.640, 0.540, 0.440)
const FLOOR_LINE := Color(0.500, 0.410, 0.330)
const WOOD := Color(0.420, 0.267, 0.137)
const WOOD_LIGHT := Color(0.640, 0.440, 0.260)
const WOOD_DARK := Color(0.290, 0.185, 0.100)
const IVORY := Color(0.940, 0.920, 0.870)
const CURTAIN := Color(0.985, 0.955, 0.880, 0.80)
const BRASS := Color(0.800, 0.640, 0.300)
const CORK := Color(0.760, 0.600, 0.420)
const ENAMEL := Color(0.900, 0.880, 0.830)
const STONE := Color(0.720, 0.700, 0.660)
const WARM_LIGHT := Color(1.0, 0.80, 0.48)
const OVEN_LIGHT := Color(1.0, 0.55, 0.20)

## Couleurs du jardin par saison : [collines, sol, buissons, accent].
const SEASON_COLORS: Dictionary = {
	GameCalendar.SPRING: [Color(0.62, 0.76, 0.58), Color(0.66, 0.80, 0.52), Color(0.42, 0.66, 0.40), Color(0.96, 0.72, 0.80)],
	GameCalendar.SUMMER: [Color(0.52, 0.68, 0.50), Color(0.56, 0.72, 0.42), Color(0.30, 0.54, 0.32), Color(0.62, 0.52, 0.82)],
	GameCalendar.AUTUMN: [Color(0.70, 0.62, 0.46), Color(0.72, 0.64, 0.40), Color(0.80, 0.50, 0.22), Color(0.72, 0.28, 0.16)],
	GameCalendar.WINTER: [Color(0.80, 0.84, 0.90), Color(0.93, 0.95, 0.98), Color(0.56, 0.54, 0.54), Color(0.98, 0.99, 1.0)],
}

## Entre deux crochets de la guirlande, et entre deux ampoules.
const GARLAND_SPAN := 480.0
const GARLAND_BULB_GAP := 60.0
## Haut du trottoir, dehors.
const PAVEMENT_Y := 700.0
## La pièce déborde de ses bords : la souris la décale de quelques pixels, et rien ne doit se
## découvrir autour.
const BLEED := 60.0

var kind := Kind.ROOM

static var _glow: GradientTexture2D


func _ready() -> void:
	if kind == Kind.LIGHTS:
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = additive
	Atmosphere.changed.connect(_on_sky_changed)
	_on_sky_changed()


func _on_sky_changed() -> void:
	match kind:
		Kind.ROOM:
			modulate = Atmosphere.room_tint
		Kind.FRONT:
			modulate = Atmosphere.room_tint * Color(0.72, 0.70, 0.70)
			modulate.a = 1.0
		_:
			queue_redraw()


func _draw() -> void:
	match kind:
		Kind.OUTSIDE:
			_draw_outside()
		Kind.ROOM:
			_draw_room()
		Kind.LIGHTS:
			_draw_lights()
		Kind.FRONT:
			_draw_front()


# --- Outils ---

static func glow_texture() -> GradientTexture2D:
	if _glow == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
		_glow = GradientTexture2D.new()
		_glow.gradient = gradient
		_glow.fill = GradientTexture2D.FILL_RADIAL
		_glow.fill_from = Vector2(0.5, 0.5)
		_glow.fill_to = Vector2(1.0, 0.5)
		_glow.width = 128
		_glow.height = 128
	return _glow


## Positions des ampoules de la guirlande, le long du haut du mur.
static func garland_bulbs() -> PackedVector2Array:
	var bulbs := PackedVector2Array()
	var x := GARLAND_BULB_GAP / 2.0
	while x < Layout.WORLD_SIZE.x:
		bulbs.append(Vector2(x, _garland_y(x)))
		x += GARLAND_BULB_GAP
	return bulbs


static func _garland_y(x: float) -> float:
	var t := fposmod(x, GARLAND_SPAN) / GARLAND_SPAN
	return 84.0 + 4.0 * t * (1.0 - t) * 46.0


## Un bloc plein, cerné d'un trait d'encre.
func _block(rect: Rect2, color: Color, outline: float = 3.0) -> void:
	draw_rect(rect, color)
	if outline > 0.0:
		draw_rect(rect, INK, false, outline)


func _poly(points: PackedVector2Array, color: Color, outline: float = 3.0) -> void:
	draw_colored_polygon(points, color)
	if outline > 0.0:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, INK, outline, true)


func _glow_at(center: Vector2, radius: float, color: Color) -> void:
	if color.a <= 0.003:
		return
	draw_texture_rect(glow_texture(), Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, color)


# --- Dehors : ce qu'on voit par la fenêtre et la porte ---

func _draw_outside() -> void:
	var left := -900.0
	var width := Layout.WORLD_SIZE.x + 1000.0
	var tint := Atmosphere.outside_tint
	var colors: Array = SEASON_COLORS.get(Atmosphere.season, SEASON_COLORS[GameCalendar.AUTUMN])
	var horizon := 540.0

	# Ciel : un dégradé en bandes.
	var bands := 30
	for i in bands:
		var t := float(i) / (bands - 1)
		draw_rect(Rect2(left, horizon * i / bands, width, horizon / bands + 1.0), Atmosphere.sky_top.lerp(Atmosphere.sky_bottom, t))

	# Étoiles par nuit claire.
	if Atmosphere.lamps > 0.7 and Atmosphere.weather == Weather.CLEAR:
		var stars := RandomNumberGenerator.new()
		stars.seed = 12
		for _i in 160:
			var at := Vector2(stars.randf_range(left, left + width), stars.randf_range(10.0, horizon - 90.0))
			draw_circle(at, stars.randf_range(1.0, 2.4), Color(1.0, 0.98, 0.90, (Atmosphere.lamps - 0.7) / 0.3 * 0.85))

	# Collines, en deux rangées.
	var far_hill: Color = colors[0] * tint
	var hills := PackedVector2Array([Vector2(left, horizon + 20.0)])
	var x := left
	while x <= left + width:
		hills.append(Vector2(x, horizon - 70.0 - 46.0 * sin(x * 0.0031) - 22.0 * sin(x * 0.0083 + 1.7)))
		x += 60.0
	hills.append(Vector2(left + width, horizon + 20.0))
	draw_colored_polygon(hills, far_hill.lerp(Atmosphere.sky_bottom, 0.45))

	# Sol du jardin, puis le trottoir au pied de la maison. Rien que des bandes horizontales : ce
	# plan défile moins vite que la pièce, et ce qu'on voit par la porte change quand on la balaie.
	var ground: Color = colors[1] * tint
	draw_rect(Rect2(left, horizon, width, 400.0), ground)
	var pavement := STONE * tint
	draw_rect(Rect2(left, PAVEMENT_Y, width, 940.0 - PAVEMENT_Y), pavement)
	draw_rect(Rect2(left, PAVEMENT_Y, width, 8.0), pavement.lightened(0.18))
	draw_line(Vector2(left, PAVEMENT_Y), Vector2(left + width, PAVEMENT_Y), Color(INK.r, INK.g, INK.b, 0.35) * tint, 2.0)

	# Muret et buissons.
	draw_rect(Rect2(left, horizon - 6.0, width, 34.0), (STONE * tint).darkened(0.08))
	var bush: Color = colors[2] * tint
	var accent: Color = colors[3] * tint
	var plants := RandomNumberGenerator.new()
	plants.seed = 5
	x = left + 40.0
	while x < left + width:
		var radius := plants.randf_range(46.0, 88.0)
		var center := Vector2(x, horizon + 30.0 + plants.randf_range(-12.0, 26.0))
		draw_circle(center, radius, bush.darkened(plants.randf_range(0.0, 0.18)))
		for _i in 5:
			var dot := center + Vector2(plants.randf_range(-0.7, 0.7), plants.randf_range(-0.8, 0.1)) * radius
			draw_circle(dot, plants.randf_range(5.0, 10.0), accent)
		x += plants.randf_range(90.0, 170.0)

	if Atmosphere.weather == Weather.FOG:
		draw_rect(Rect2(left, 0.0, width, 940.0), Color(0.86, 0.87, 0.90, 0.55) * Color(tint.r, tint.g, tint.b, 1.0))


# --- La pièce ---

## Le mur, en rectangles qui contournent la fenêtre et la porte.
func _wall_rects() -> Array[Rect2]:
	var window := Layout.WINDOW
	var door := Layout.DOOR
	var floor_y := Layout.FLOOR_Y
	return [
		Rect2(-BLEED, -BLEED, window.position.x + BLEED, floor_y + BLEED),
		Rect2(window.position.x, -BLEED, window.size.x, window.position.y + BLEED),
		Rect2(window.position.x, window.end.y, window.size.x, floor_y - window.end.y),
		Rect2(window.end.x, -BLEED, door.position.x - window.end.x, floor_y + BLEED),
		Rect2(door.position.x, -BLEED, door.size.x, door.position.y + BLEED),
		Rect2(door.end.x, -BLEED, Layout.WORLD_SIZE.x - door.end.x + BLEED, floor_y + BLEED),
	]


func _draw_room() -> void:
	var world := Layout.WORLD_SIZE
	var floor_y := Layout.FLOOR_Y
	var left := -BLEED
	var right := world.x + BLEED

	# Mur et soubassement.
	var low_band := Rect2(left, 600.0, right - left, floor_y - 600.0)
	for rect in _wall_rects():
		draw_rect(rect, WALL)
		var low := rect.intersection(low_band)
		if low.has_area():
			draw_rect(low, WALL_LOW)
	draw_line(Vector2(left, 600.0), Vector2(Layout.DOOR.position.x - 20.0, 600.0), INK, 2.0)
	draw_line(Vector2(Layout.DOOR.end.x + 20.0, 600.0), Vector2(right, 600.0), INK, 2.0)

	# Sol de pierre.
	draw_rect(Rect2(left, floor_y, right - left, world.y - floor_y + BLEED), FLOOR)
	for row in 4:
		var y := floor_y + 70.0 + row * 80.0
		draw_line(Vector2(left, y), Vector2(right, y), FLOOR_LINE, 2.0)
		var x := 80.0 + row * 110.0 - 260.0
		while x < right:
			draw_line(Vector2(x, y - (80.0 if row > 0 else 70.0)), Vector2(x, y), FLOOR_LINE, 2.0)
			x += 260.0
	draw_line(Vector2(left, floor_y), Vector2(Layout.DOOR.position.x, floor_y), INK, 3.0)
	draw_line(Vector2(Layout.DOOR.end.x, floor_y), Vector2(right, floor_y), INK, 3.0)

	_draw_window()
	_draw_door()

	# Poutres : une au plafond, deux poteaux qui séparent les trois coins de la maison.
	_block(Rect2(left, -BLEED, right - left, 46.0 + BLEED), WOOD_DARK)
	for post_x in Layout.POSTS:
		_block(Rect2(post_x, 46.0, Layout.POST_WIDTH, floor_y - 46.0), WOOD_DARK)

	# Guirlande : le fil, et les ampoules éteintes.
	var wire := PackedVector2Array()
	var x := left
	while x <= right:
		wire.append(Vector2(x, _garland_y(x) - 8.0))
		x += 20.0
	draw_polyline(wire, WOOD_DARK, 2.0, true)
	for bulb in garland_bulbs():
		draw_circle(bulb, 6.0, Color(1.0, 0.95, 0.80))

	_draw_desk_corner()
	_draw_counter()
	_draw_kitchen()


func _draw_window() -> void:
	var window := Layout.WINDOW
	draw_rect(window, Color(0.80, 0.90, 0.95, 0.10))
	# Rideaux.
	for side in [0.0, 1.0]:
		var curtain := Rect2(window.position.x + side * (window.size.x - 74.0), window.position.y, 74.0, window.size.y)
		draw_rect(curtain, CURTAIN)
		for fold in 3:
			var fold_x := curtain.position.x + 14.0 + fold * 22.0
			draw_line(Vector2(fold_x, curtain.position.y), Vector2(fold_x, curtain.end.y), Color(0.80, 0.74, 0.62, 0.55), 2.0)
	# Croisillons et cadre.
	draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), IVORY, 10.0)
	draw_line(Vector2(window.position.x, window.position.y + window.size.y * 0.42), Vector2(window.end.x, window.position.y + window.size.y * 0.42), IVORY, 10.0)
	draw_rect(window.grow(8.0), IVORY, false, 18.0)
	draw_rect(window.grow(17.0), INK, false, 3.0)
	draw_rect(window, INK, false, 2.0)
	_block(Rect2(window.position.x - 34.0, window.end.y + 14.0, window.size.x + 68.0, 20.0), WOOD_LIGHT)


func _draw_door() -> void:
	var door := Layout.DOOR
	# Seuil de pierre, encadrement, puis le battant ouvert vers l'intérieur.
	_block(Rect2(door.position.x - 30.0, door.end.y - 6.0, door.size.x + 60.0, 22.0), STONE)
	draw_rect(door.grow(10.0), WOOD, false, 22.0)
	draw_rect(door.grow(21.0), INK, false, 3.0)
	draw_rect(door, INK, false, 2.0)
	var leaf := PackedVector2Array([
		Vector2(door.position.x, door.position.y), Vector2(door.position.x - 116.0, door.position.y + 34.0),
		Vector2(door.position.x - 116.0, door.end.y + 34.0), Vector2(door.position.x, door.end.y),
	])
	_poly(leaf, IVORY)
	for pane in 3:
		var top := door.position.y + 60.0 + pane * 150.0
		draw_polyline(PackedVector2Array([
			Vector2(door.position.x - 18.0, top + 6.0), Vector2(door.position.x - 98.0, top + 30.0),
			Vector2(door.position.x - 98.0, top + 150.0), Vector2(door.position.x - 18.0, top + 126.0),
			Vector2(door.position.x - 18.0, top + 6.0),
		]), INK, 2.0, true)


func _draw_table(rect: Rect2, panels: int) -> void:
	# Façade à panneaux, puis le plateau, un peu plus large.
	var front := Rect2(rect.position.x, rect.position.y + 22.0, rect.size.x, rect.size.y - 22.0)
	_block(front, WOOD)
	var panel_width := (front.size.x - 30.0 * (panels + 1)) / panels
	for i in panels:
		var panel := Rect2(front.position.x + 30.0 + i * (panel_width + 30.0), front.position.y + 24.0, panel_width, front.size.y - 48.0)
		draw_rect(panel, WOOD_DARK, false, 3.0)
	_block(Rect2(rect.position.x - 16.0, rect.position.y, rect.size.x + 32.0, 22.0), WOOD_LIGHT)


func _draw_desk_corner() -> void:
	var desk := Layout.DESK
	# Bureau : un plateau sur deux pieds et un caisson.
	_block(Rect2(desk.position.x + 20.0, desk.position.y + 22.0, 26.0, desk.size.y - 22.0), WOOD)
	_block(Rect2(desk.end.x - 230.0, desk.position.y + 22.0, 210.0, desk.size.y - 22.0), WOOD)
	draw_rect(Rect2(desk.end.x - 212.0, desk.position.y + 44.0, 174.0, 50.0), WOOD_DARK, false, 3.0)
	draw_rect(Rect2(desk.end.x - 212.0, desk.position.y + 108.0, 174.0, 50.0), WOOD_DARK, false, 3.0)
	_block(Rect2(desk.position.x - 16.0, desk.position.y, desk.size.x + 32.0, 22.0), WOOD_LIGHT)

	# Tableau de liège, vide pour l'instant.
	_block(Layout.CORK_BOARD, CORK)
	draw_rect(Layout.CORK_BOARD.grow(6.0), WOOD, false, 12.0)

	# Lampe de bureau.
	var lamp := Layout.DESK_LAMP
	_block(Rect2(lamp.x - 34.0, lamp.y - 12.0, 68.0, 12.0), BRASS)
	draw_line(lamp + Vector2(0.0, -12.0), lamp + Vector2(0.0, -110.0), INK, 5.0)
	_poly(PackedVector2Array([
		lamp + Vector2(-28.0, -150.0), lamp + Vector2(28.0, -150.0), lamp + Vector2(52.0, -92.0), lamp + Vector2(-52.0, -92.0),
	]), ENAMEL)


func _draw_counter() -> void:
	_draw_table(Layout.COUNTER, 4)
	# Étagères murales, vides : la vitrine viendra s'y ranger.
	for shelf in Layout.WALL_SHELVES:
		_block(shelf, WOOD_LIGHT)
		for bracket_x in [shelf.position.x + 40.0, shelf.end.x - 40.0]:
			draw_line(Vector2(bracket_x, shelf.end.y), Vector2(bracket_x, shelf.end.y + 30.0), INK, 4.0)
			draw_line(Vector2(bracket_x, shelf.end.y + 30.0), Vector2(bracket_x + (24.0 if bracket_x < shelf.get_center().x else -24.0), shelf.end.y), INK, 4.0)
	# Cloches de verre.
	for base in Layout.CLOCHES:
		draw_arc(base + Vector2(0.0, -8.0), 58.0, PI, TAU, 24, Color(1.0, 1.0, 1.0, 0.70), 3.0, true)
		draw_circle(base + Vector2(0.0, -70.0), 7.0, Color(1.0, 1.0, 1.0, 0.70))
		_block(Rect2(base.x - 66.0, base.y - 10.0, 132.0, 10.0), IVORY, 2.0)
	# Lustre : une chaîne, un cercle de fer, quatre bougies.
	var chandelier := Layout.CHANDELIER
	draw_line(Vector2(chandelier.x, 46.0), chandelier + Vector2(0.0, -30.0), INK, 3.0)
	draw_arc(chandelier, 86.0, 0.0, PI, 20, WOOD_DARK, 7.0, true)
	draw_line(chandelier + Vector2(-86.0, 0.0), chandelier + Vector2(86.0, 0.0), WOOD_DARK, 7.0)
	for offset in [-70.0, -24.0, 24.0, 70.0]:
		_block(Rect2(chandelier.x + offset - 6.0, chandelier.y - 30.0, 12.0, 30.0), IVORY, 2.0)


func _draw_kitchen() -> void:
	_draw_table(Layout.WORKTOP, 1)
	# Four encastré : une porte vitrée, une poignée, deux boutons.
	var oven := Layout.OVEN
	_block(oven, Color(0.22, 0.21, 0.21))
	_block(oven.grow_individual(-26.0, -34.0, -26.0, -16.0), Color(0.45, 0.25, 0.12))
	draw_line(oven.position + Vector2(30.0, 18.0), Vector2(oven.end.x - 30.0, oven.position.y + 18.0), ENAMEL, 6.0)
	for knob_x in [oven.position.x - 26.0, oven.end.x + 26.0]:
		draw_circle(Vector2(knob_x, oven.position.y + 24.0), 12.0, ENAMEL)
		draw_arc(Vector2(knob_x, oven.position.y + 24.0), 12.0, 0.0, TAU, 16, INK, 2.0, true)

	# Étagère à livres, vide pour l'instant.
	var bookshelf := Layout.BOOKSHELF
	_block(bookshelf, WOOD_LIGHT.darkened(0.12))
	draw_rect(bookshelf, WOOD, false, 12.0)
	draw_line(Vector2(bookshelf.position.x, bookshelf.get_center().y), Vector2(bookshelf.end.x, bookshelf.get_center().y), WOOD, 12.0)

	# Machine à café.
	var machine := Layout.COFFEE_MACHINE
	_block(machine, ENAMEL)
	_block(Rect2(machine.position.x + 14.0, machine.position.y + 16.0, machine.size.x - 28.0, 22.0), Color(0.30, 0.30, 0.30), 2.0)
	_block(Rect2(machine.get_center().x - 8.0, machine.position.y + 46.0, 16.0, 20.0), Color(0.30, 0.30, 0.30), 2.0)

	# Garde-manger : un grand placard à deux portes.
	var pantry := Layout.PANTRY
	_block(pantry, WOOD)
	draw_line(Vector2(pantry.get_center().x, pantry.position.y), Vector2(pantry.get_center().x, pantry.end.y), INK, 3.0)
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(pantry.get_center().x + side * 58.0 - 44.0, pantry.position.y + 26.0, 88.0, pantry.size.y - 52.0), WOOD_DARK, false, 3.0)
		draw_circle(Vector2(pantry.get_center().x + side * 14.0, pantry.get_center().y), 7.0, BRASS)


# --- Lumières, en ajout de couleur par-dessus la pièce ---

func _draw_lights() -> void:
	var lamps := Atmosphere.lamps
	var warm := WARM_LIGHT

	# Jour qui entre par la porte et la fenêtre : deux nappes qui s'éteignent en s'éloignant.
	var sun := Atmosphere.sunlight_color * Atmosphere.sunlight
	if Atmosphere.sunlight > 0.01:
		var window := Layout.WINDOW
		var door := Layout.DOOR
		# En ajout de couleur, la transparence règle la force de la lumière.
		var bright := Color(sun.r, sun.g, sun.b, 0.30)
		var brighter := Color(sun.r, sun.g, sun.b, 0.45)
		var faded := Color(sun.r, sun.g, sun.b, 0.0)
		# La fenêtre éclaire le sol devant le bureau, pas le bureau lui-même.
		draw_polygon(PackedVector2Array([
			Vector2(window.position.x + 60.0, Layout.FLOOR_Y), Vector2(window.end.x + 120.0, Layout.FLOOR_Y),
			Vector2(window.end.x + 380.0, 1080.0), Vector2(window.position.x + 200.0, 1080.0),
		]), PackedColorArray([bright, bright, faded, faded]))
		draw_polygon(PackedVector2Array([
			Vector2(door.position.x, door.end.y), Vector2(door.end.x, door.end.y),
			Vector2(door.end.x + 380.0, 1080.0), Vector2(door.position.x + 90.0, 1080.0),
		]), PackedColorArray([brighter, brighter, faded, faded]))
		# Clarté autour des ouvertures.
		_glow_at(window.get_center(), 380.0, Color(sun.r, sun.g, sun.b, 0.16))
		_glow_at(door.get_center(), 460.0, Color(sun.r, sun.g, sun.b, 0.16))

	if lamps > 0.01:
		for bulb in garland_bulbs():
			_glow_at(bulb, 34.0, Color(warm.r, warm.g, warm.b, 0.85 * lamps))
		_glow_at(Layout.CHANDELIER + Vector2(0.0, -20.0), 520.0, Color(warm.r, warm.g, warm.b, 0.42 * lamps))
		_glow_at(Layout.CHANDELIER + Vector2(0.0, -30.0), 120.0, Color(warm.r, warm.g, warm.b, 0.70 * lamps))
		_glow_at(Layout.DESK_LAMP + Vector2(0.0, -80.0), 330.0, Color(warm.r, warm.g, warm.b, 0.50 * lamps))

	# Le four rougeoie toujours un peu.
	_glow_at(Layout.OVEN.get_center(), 190.0, Color(OVEN_LIGHT.r, OVEN_LIGHT.g, OVEN_LIGHT.b, 0.20 + 0.25 * lamps))


# --- Premier plan : deux silhouettes proches, qui bougent plus vite que la pièce ---

func _draw_front() -> void:
	# Dossier d'une chaise, à gauche.
	var chair := Vector2(330.0, 770.0)
	_block(Rect2(chair.x, chair.y, 26.0, 330.0), WOOD_DARK)
	_block(Rect2(chair.x + 220.0, chair.y, 26.0, 330.0), WOOD_DARK)
	for rung in 3:
		_block(Rect2(chair.x, chair.y + 30.0 + rung * 70.0, 246.0, 22.0), WOOD_DARK)
	# Coin d'une table, à droite (visible quand on regarde la cuisine).
	_poly(PackedVector2Array([
		Vector2(4020.0, 1000.0), Vector2(4700.0, 930.0), Vector2(4900.0, 1080.0), Vector2(3960.0, 1080.0),
	]), WOOD_DARK)
