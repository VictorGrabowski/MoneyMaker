## Le verre du bocal, dessiné en 2D par-dessus (face avant) ou par-dessous (fond) les pièces.
## Suit la projection de la caméra du bocal : il se décale avec la parallaxe et change avec la taille.
extends Node2D

const JarView := preload("res://scenes/jar/jar_view.gd")

const GLASS_LINE := Color(1.0, 1.0, 1.0, 0.55)
const GLASS_HALO := Color(0.78, 0.90, 0.93, 0.22)
## Liseré sombre sous le trait clair : sans lui, le verre disparaît devant un mur clair.
const GLASS_EDGE := Color(0.24, 0.30, 0.36, 0.42)
const GLASS_TINT := Color(0.80, 0.90, 0.92, 0.10)
const HIGHLIGHT := Color(1.0, 1.0, 1.0, 0.24)

var jar: JarView
## true : fond du bocal, à placer derrière les pièces. false : vitre avant.
var is_back := false

var _face := PackedVector2Array()


## Le verre n'est redessiné que si le bocal a bougé à l'écran.
func _process(_delta: float) -> void:
	if jar == null or not jar.is_inside_tree():
		return
	var face := jar.jar_face_points(-1.0 if is_back else 1.0)
	if face != _face:
		_face = face
		queue_redraw()


func _draw() -> void:
	if _face.size() != 4:
		return
	var face := _face
	var top_left := face[0]
	var top_right := face[1]
	var bottom_right := face[2]
	var bottom_left := face[3]
	var width := top_right.x - top_left.x
	var height := bottom_left.y - top_left.y
	# Les traits gardent la même finesse quelle que soit la taille du bocal à l'écran.
	var line := clampf(width / 100.0, 2.0, 6.0)

	if is_back:
		draw_colored_polygon(face, GLASS_TINT)
		# Culot épais du bocal.
		var base := PackedVector2Array([
			bottom_left, bottom_right,
			bottom_right + Vector2(-0.02 * width, 0.035 * height),
			bottom_left + Vector2(0.02 * width, 0.035 * height),
		])
		draw_colored_polygon(base, Color(0.85, 0.93, 0.95, 0.30))
		return

	# Paroi : un U ouvert en haut, aux angles arrondis.
	var outline := _u_path(top_left, top_right, bottom_right, bottom_left, 0.07 * width)
	draw_polyline(outline, GLASS_HALO, line * 3.0, true)
	draw_polyline(outline, GLASS_EDGE, line * 1.7, true)
	draw_polyline(outline, GLASS_LINE, line, true)

	# Col : une ellipse aplatie.
	var rim := PackedVector2Array()
	var center := (top_left + top_right) / 2.0
	for i in 49:
		var angle := TAU * i / 48.0
		rim.append(center + Vector2(cos(angle) * width * 0.5, sin(angle) * width * 0.032))
	draw_polyline(rim, GLASS_HALO, line * 2.4, true)
	draw_polyline(rim, GLASS_EDGE, line * 1.4, true)
	draw_polyline(rim, GLASS_LINE, line * 0.8, true)

	# Reflets.
	_streak(top_left + Vector2(0.09 * width, 0.10 * height), top_left + Vector2(0.09 * width, 0.62 * height), 0.035 * width)
	_streak(top_left + Vector2(0.155 * width, 0.14 * height), top_left + Vector2(0.155 * width, 0.30 * height), 0.014 * width)
	_streak(top_left + Vector2(0.90 * width, 0.66 * height), top_left + Vector2(0.90 * width, 0.86 * height), 0.020 * width)


func _streak(from: Vector2, to: Vector2, thickness: float) -> void:
	draw_line(from, to, HIGHLIGHT, thickness, true)
	draw_circle(from, thickness / 2.0, HIGHLIGHT)
	draw_circle(to, thickness / 2.0, HIGHLIGHT)


func _u_path(top_left: Vector2, top_right: Vector2, bottom_right: Vector2, bottom_left: Vector2, radius: float) -> PackedVector2Array:
	var path := PackedVector2Array()
	path.append(top_left)
	for i in 9:
		var angle := PI - (PI / 2.0) * i / 8.0  # de la gauche vers le bas
		path.append(bottom_left + Vector2(radius, -radius) + Vector2(cos(angle), sin(angle)) * radius)
	for i in 9:
		var angle := PI / 2.0 - (PI / 2.0) * i / 8.0  # du bas vers la droite
		path.append(bottom_right + Vector2(-radius, -radius) + Vector2(cos(angle), sin(angle)) * radius)
	path.append(top_right)
	return path
