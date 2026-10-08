## Un objet de la maison sur lequel on peut cliquer : il s'éclaire au survol et s'ouvre en gros plan.
## Provisoire : chaque objet se dessine lui-même en quelques traits.
extends Control

const Paper := preload("res://scenes/closeups/paper.gd")
const GameState := preload("res://core/state/game_state.gd")
const Weather := preload("res://core/world/weather.gd")

signal activated(kind: String)
## Pour un objet qu'on peut aussi saisir (drag_threshold > 0) : la main vient de l'emporter, le
## déplace, le lâche. `at` : la position de la souris, dans le repère de get_global_transform().
signal grabbed(kind: String, at: Vector2)
signal dragged(kind: String, at: Vector2)
signal dropped(kind: String)

const PAY_SHEET := "fiche_de_paie"
const CALENDAR := "calendrier"
const BAROMETER := "barometre"
const TILL := "caisse"
const WIDGET_FRAME := "cadre_du_widget"
const WORK_SIGN := "chevalet"
const JAR := "bocal"

const INK := Color(0.227, 0.149, 0.094, 0.9)
const PAPER := Color(0.985, 0.960, 0.900)
const BRASS := Color(0.800, 0.640, 0.300)
const WOOD := Color(0.420, 0.267, 0.137)
const RED := Color(0.760, 0.300, 0.240)
const HONEY := Color(0.949, 0.722, 0.400)
const HOVER_TINT := Color(1.22, 1.20, 1.12)

var kind := ""
## Jour du mois affiché sur le calendrier.
var day_number := 1
## Vrai quand un ticket du soir attend d'être lu : il dépasse de la caisse.
var has_ticket := false:
	set(value):
		if has_ticket != value:
			has_ticket = value
			queue_redraw()
## Format du widget mis en avant sur le cadre.
var widget_format := GameState.WIDGET_BANDEAU:
	set(value):
		if widget_format != value:
			widget_format = value
			queue_redraw()
## Vrai quand le temps de travail compte : le chevalet dit « Au travail ».
var working := false:
	set(value):
		if working != value:
			working = value
			queue_redraw()
## Faux : l'objet se montre mais ne répond pas (le chevalet quand l'horaire décide seul ; tous les
## objets pendant un focus en mode strict, plus tard).
var enabled := true:
	set(value):
		enabled = value
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW

## Au-delà de ce trajet (en pixels), un appui devient une saisie au lieu d'un clic. 0 : l'objet ne
## se saisit pas, il s'active dès l'appui.
var drag_threshold := 0.0

var _tween: Tween
var _pressed := false
var _press_at := Vector2.ZERO
var _carried := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = size / 2.0
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	if kind == BAROMETER:
		Atmosphere.changed.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed and enabled:
			if drag_threshold <= 0.0:
				activated.emit(kind)
			else:
				# Clic ou saisie ? On le saura au relâchement, ou dès que la main aura bougé.
				_pressed = true
				_carried = false
				_press_at = button.position
			accept_event()
		elif not button.pressed and _pressed:
			_pressed = false
			if _carried:
				_carried = false
				dropped.emit(kind)
			else:
				activated.emit(kind)
			accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _pressed:
		if not _carried and motion.position.distance_to(_press_at) > drag_threshold:
			_carried = true
			grabbed.emit(kind, get_global_transform() * _press_at)
		if _carried:
			dragged.emit(kind, get_global_transform() * motion.position)
		accept_event()


## Survol : l'objet s'éclaire et se soulève à peine.
func _on_hover(hovered: bool) -> void:
	if not enabled and hovered:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "modulate", HOVER_TINT if hovered else Color.WHITE, 0.12)
	_tween.tween_property(self, "scale", Vector2.ONE * (1.05 if hovered else 1.0), 0.12)


func _draw() -> void:
	match kind:
		PAY_SHEET:
			_draw_pay_sheet()
		CALENDAR:
			_draw_calendar()
		BAROMETER:
			_draw_barometer()
		TILL:
			_draw_till()
		WIDGET_FRAME:
			_draw_widget_frame()
		WORK_SIGN:
			_draw_work_sign()


func _outline(points: PackedVector2Array, width: float = 3.0) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, INK, width, true)


## Une feuille posée à plat sur le bureau, et un crayon.
func _draw_pay_sheet() -> void:
	var sheet := PackedVector2Array([
		Vector2(26.0, 6.0), Vector2(size.x - 6.0, 2.0), Vector2(size.x - 30.0, size.y - 6.0), Vector2(2.0, size.y - 2.0),
	])
	draw_colored_polygon(sheet, PAPER)
	_outline(sheet, 2.0)
	for line in 3:
		var y := 14.0 + line * 9.0
		draw_line(Vector2(34.0 - line * 5.0, y), Vector2(size.x - 34.0 - line * 5.0, y - 2.0), Color(INK.r, INK.g, INK.b, 0.45), 2.0)
	draw_line(Vector2(size.x - 50.0, size.y - 8.0), Vector2(size.x + 10.0, size.y - 20.0), Color(0.85, 0.65, 0.20), 5.0)


## Un éphéméride : un bandeau rouge, le jour en grand.
func _draw_calendar() -> void:
	var block := Rect2(Vector2.ZERO, size)
	draw_rect(block, PAPER)
	draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.24), RED)
	draw_rect(block, INK, false, 3.0)
	draw_circle(Vector2(size.x * 0.3, 0.0), 6.0, INK)
	draw_circle(Vector2(size.x * 0.7, 0.0), 6.0, INK)
	var font := Paper.hand_font()
	var text := str(day_number)
	var font_size := int(size.y * 0.42)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2((size.x - text_size.x) / 2.0, size.y * 0.74), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)


## Un cadran de laiton dont l'aiguille montre le temps qu'il fait.
func _draw_barometer() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 3.0
	draw_circle(center, radius, BRASS)
	draw_circle(center, radius - 10.0, PAPER)
	draw_arc(center, radius, 0.0, TAU, 40, INK, 3.0, true)
	draw_arc(center, radius - 10.0, 0.0, TAU, 40, INK, 2.0, true)
	# Cinq graduations, du beau temps (à gauche) au brouillard (à droite).
	var order: Array[String] = [Weather.CLEAR, Weather.CLOUDY, Weather.RAIN, Weather.SNOW, Weather.FOG]
	for i in order.size():
		var angle := lerpf(-PI * 0.85, -PI * 0.15, i / 4.0)
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * (radius - 22.0), center + direction * (radius - 13.0), INK, 3.0)
	var needle := lerpf(-PI * 0.85, -PI * 0.15, maxi(0, order.find(Atmosphere.weather)) / 4.0)
	draw_line(center, center + Vector2(cos(needle), sin(needle)) * (radius - 24.0), RED, 4.0, true)
	draw_circle(center, 6.0, INK)


## Une caisse enregistreuse de laiton ; le ticket du soir en dépasse quand il attend d'être lu.
func _draw_till() -> void:
	if has_ticket:
		var ticket := Rect2(size.x * 0.56, -26.0, 34.0, 46.0)
		draw_rect(ticket, PAPER)
		draw_rect(ticket, INK, false, 2.0)
		for line in 3:
			draw_line(Vector2(ticket.position.x + 6.0, ticket.position.y + 10.0 + line * 8.0), Vector2(ticket.end.x - 6.0, ticket.position.y + 10.0 + line * 8.0), Color(INK.r, INK.g, INK.b, 0.5), 2.0)
	var body := PackedVector2Array([
		Vector2(8.0, size.y * 0.34), Vector2(size.x - 8.0, size.y * 0.34), Vector2(size.x, size.y), Vector2(0.0, size.y),
	])
	draw_colored_polygon(body, BRASS)
	_outline(body)
	var top := Rect2(size.x * 0.18, size.y * 0.08, size.x * 0.64, size.y * 0.28)
	draw_rect(top, BRASS.darkened(0.12))
	draw_rect(top, INK, false, 3.0)
	draw_rect(top.grow(-8.0), PAPER)
	for row in 2:
		for column in 5:
			draw_circle(Vector2(size.x * (0.20 + 0.15 * column), size.y * (0.56 + 0.20 * row)), 6.0, PAPER)


## Un chevalet de carton posé sur le bureau : couleur de miel et « Au travail » quand le temps
## compte, pâle et « Au repos » sinon.
func _draw_work_sign() -> void:
	draw_line(Vector2(16.0, size.y), Vector2(28.0, size.y - 18.0), INK, 4.0)
	draw_line(Vector2(size.x - 16.0, size.y), Vector2(size.x - 28.0, size.y - 18.0), INK, 4.0)
	var card := PackedVector2Array([
		Vector2(10.0, 4.0), Vector2(size.x - 10.0, 4.0), Vector2(size.x - 3.0, size.y - 14.0), Vector2(3.0, size.y - 14.0),
	])
	draw_colored_polygon(card, HONEY if working else PAPER)
	_outline(card)
	var font := Paper.hand_font()
	var text := "Au travail" if working else "Au repos"
	var font_size := 19
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2((size.x - text_size.x) / 2.0, (size.y - 10.0) / 2.0 + text_size.y * 0.30), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)


## Un petit cadre posé sur le bureau, qui montre les trois formats du widget.
func _draw_widget_frame() -> void:
	var frame := Rect2(Vector2.ZERO, size)
	draw_rect(frame, WOOD)
	draw_rect(frame.grow(-9.0), PAPER)
	draw_rect(frame, INK, false, 3.0)
	var slots: Dictionary = {
		GameState.WIDGET_PASTILLE: Rect2(18.0, 18.0, 40.0, 14.0),
		GameState.WIDGET_BANDEAU: Rect2(18.0, 40.0, 62.0, 18.0),
		GameState.WIDGET_MINI_BOCAL: Rect2(86.0, 18.0, 20.0, 54.0),
	}
	for format in slots:
		var slot: Rect2 = slots[format]
		draw_rect(slot, Paper.CRUST if format == widget_format else Paper.PAPER_SHADE)
		draw_rect(slot, INK, false, 2.0)
