## Le petit cadre du bureau en gros plan : choisir la forme du widget, et s'y installer.
extends PanelContainer

const Paper := preload("res://scenes/closeups/paper.gd")
const GameState := preload("res://core/state/game_state.gd")

const FORMAT_LABELS: Dictionary = {
	GameState.WIDGET_PASTILLE: "Pastille\nle montant seul",
	GameState.WIDGET_BANDEAU: "Bandeau\nmontant et minuteur",
	GameState.WIDGET_MINI_BOCAL: "Mini-bocal\nle bocal en petit",
}

var _buttons: Dictionary = {}


func _ready() -> void:
	theme = Paper.theme()
	add_theme_stylebox_override("panel", Paper.sheet_style())

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(Paper.title("Le widget"))
	column.add_child(Paper.rule())
	var hint := Paper.label("Une petite fenêtre qui reste au-dessus des autres pendant que tu travailles.", 18, Paper.INK_SOFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

	var formats := HBoxContainer.new()
	formats.alignment = BoxContainer.ALIGNMENT_CENTER
	formats.add_theme_constant_override("separation", 14)
	column.add_child(formats)
	for format in GameState.WIDGET_FORMATS:
		var button := Button.new()
		button.text = FORMAT_LABELS[format]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(230.0, 90.0)
		button.pressed.connect(_choose.bind(format))
		formats.add_child(button)
		_buttons[format] = button

	column.add_child(Paper.rule())
	var go := Button.new()
	go.text = "Passer en widget"
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void: WindowModes.show_widget())
	column.add_child(go)

	WindowModes.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for format in _buttons:
		(_buttons[format] as Button).button_pressed = format == WindowModes.format


func _choose(format: String) -> void:
	WindowModes.choose_format(format)
