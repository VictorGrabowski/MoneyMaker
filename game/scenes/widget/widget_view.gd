## Le widget, en trois formats : pastille (le montant seul), bandeau (montant et anneau du minuteur),
## mini-bocal (le bocal en petit, montant en dessous).
##
## Glisser : déplacer. Double-clic : revenir à la maison. Clic droit : format suivant.
## Molette : plus ou moins opaque.
extends Control

const GameState := preload("res://core/state/game_state.gd")

const INK := Color(0.227, 0.149, 0.094)
const PAPER := Color(0.965, 0.914, 0.824)
const CRUST := Color(0.851, 0.565, 0.184)
## Hauteur de l'étiquette sous le bocal, en format mini-bocal.
const MINI_LABEL_HEIGHT := 60.0

var format := GameState.WIDGET_BANDEAU:
	set(value):
		format = value
		_layout()

var amount_text := "0,00 €":
	set(value):
		amount_text = value
		if _amount != null:
			_amount.text = value

## Avancement du focus en cours, de 0 à 1.
var ring_progress := 0.0:
	set(value):
		ring_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _caption: Label
var _amount: Label
var _font: SystemFont
var _dragging := false
var _drag_offset := Vector2i.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe Print", "Ink Free", "Comic Sans MS"])
	_font.font_weight = 700

	_caption = Label.new()
	_caption.text = "aujourd'hui"
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	_amount = Label.new()
	_amount.text = amount_text
	_amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_amount)
	_layout()
	resized.connect(_layout)


## Place réservée au bocal en format mini-bocal, en coordonnées locales.
func jar_rect() -> Rect2:
	return Rect2(0.0, 0.0, size.x, size.y - MINI_LABEL_HEIGHT)


func _settings(font_size: int, color: Color) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = _font
	settings.font_size = font_size
	settings.font_color = color
	return settings


func _layout() -> void:
	if _amount == null:
		return
	_caption.label_settings = _settings(15, INK.lightened(0.25))
	match format:
		GameState.WIDGET_PASTILLE:
			_caption.visible = false
			_amount.label_settings = _settings(25, INK)
			_amount.position = Vector2.ZERO
			_amount.size = size
		GameState.WIDGET_MINI_BOCAL:
			_caption.visible = false
			_amount.label_settings = _settings(24, INK)
			_amount.position = Vector2(0.0, size.y - MINI_LABEL_HEIGHT)
			_amount.size = Vector2(size.x, MINI_LABEL_HEIGHT - 8.0)
		_:
			_caption.visible = true
			_caption.position = Vector2(104.0, 12.0)
			_amount.label_settings = _settings(32, INK)
			_amount.position = Vector2(96.0, 30.0)
			_amount.size = Vector2(size.x - 108.0, 54.0)
	queue_redraw()


func _paper(rect: Rect2, radius: int) -> void:
	# Étiquette de papier aux coins arrondis : le reste de la fenêtre est transparent.
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = INK
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(radius)
	paper.anti_aliasing = true
	draw_style_box(paper, rect)


func _draw() -> void:
	match format:
		GameState.WIDGET_PASTILLE:
			_paper(Rect2(Vector2(2, 2), size - Vector2(4, 4)), 28)
		GameState.WIDGET_MINI_BOCAL:
			var label := Rect2(4.0, size.y - MINI_LABEL_HEIGHT, size.x - 8.0, MINI_LABEL_HEIGHT - 4.0)
			_paper(label, 20)
			# Avancement du focus : un trait le long du bas de l'étiquette.
			var from := Vector2(label.position.x + 22.0, label.end.y - 9.0)
			var to := Vector2(label.end.x - 22.0, label.end.y - 9.0)
			draw_line(from, to, INK.lightened(0.6), 4.0, true)
			if ring_progress > 0.0:
				draw_line(from, from.lerp(to, ring_progress), CRUST, 4.0, true)
		_:
			_paper(Rect2(Vector2(2, 2), size - Vector2(4, 4)), 26)
			var center := Vector2(52.0, size.y / 2.0)
			draw_arc(center, 28.0, 0.0, TAU, 48, INK.lightened(0.6), 7.0, true)
			if ring_progress > 0.0:
				draw_arc(center, 28.0, -PI / 2.0, -PI / 2.0 + TAU * ring_progress, 48, CRUST, 7.0, true)
			draw_circle(center, 6.0, INK)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				if button.double_click:
					_dragging = false
					WindowModes.show_home()
				elif button.pressed:
					_dragging = true
					_drag_offset = DisplayServer.mouse_get_position() - get_window().position
				elif _dragging:
					_dragging = false
					WindowModes.end_move()
			MOUSE_BUTTON_RIGHT:
				if button.pressed:
					WindowModes.cycle_format()
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					WindowModes.nudge_opacity(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					WindowModes.nudge_opacity(-1)
	elif event is InputEventMouseMotion and _dragging:
		WindowModes.move_widget_to(DisplayServer.mouse_get_position() - _drag_offset)
