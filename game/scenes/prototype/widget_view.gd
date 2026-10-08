## Le widget au format « bandeau » (320 × 96) : montant du jour et anneau du minuteur.
## Se déplace en le faisant glisser ; un double-clic ramène à la maison.
extends Control

signal expand_requested

const INK := Color(0.227, 0.149, 0.094)
const PAPER := Color(0.965, 0.914, 0.824)
const CRUST := Color(0.851, 0.565, 0.184)

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

var _amount: Label
var _dragging := false
var _drag_offset := Vector2i.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe Print", "Ink Free", "Comic Sans MS"])
	font.font_weight = 700

	var caption_settings := LabelSettings.new()
	caption_settings.font = font
	caption_settings.font_size = 15
	caption_settings.font_color = INK.lightened(0.25)
	var caption := Label.new()
	caption.text = "aujourd'hui"
	caption.label_settings = caption_settings
	caption.position = Vector2(104, 12)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)

	var amount_settings := LabelSettings.new()
	amount_settings.font = font
	amount_settings.font_size = 32
	amount_settings.font_color = INK
	_amount = Label.new()
	_amount.text = amount_text
	_amount.label_settings = amount_settings
	_amount.position = Vector2(102, 30)
	_amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_amount)


func _draw() -> void:
	# Étiquette de papier aux coins arrondis : le reste de la fenêtre est transparent.
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = INK
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(26)
	paper.anti_aliasing = true
	draw_style_box(paper, Rect2(Vector2(2, 2), size - Vector2(4, 4)))

	# Anneau du minuteur.
	var center := Vector2(52, size.y / 2.0)
	draw_arc(center, 28.0, 0.0, TAU, 48, INK.lightened(0.6), 7.0, true)
	if ring_progress > 0.0:
		draw_arc(center, 28.0, -PI / 2.0, -PI / 2.0 + TAU * ring_progress, 48, CRUST, 7.0, true)
	draw_circle(center, 6.0, INK)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.double_click:
			_dragging = false
			expand_requested.emit()
		elif button.pressed:
			_dragging = true
			_drag_offset = DisplayServer.mouse_get_position() - get_window().position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		get_window().position = DisplayServer.mouse_get_position() - _drag_offset
