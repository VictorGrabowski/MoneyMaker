## Le ticket du soir : ce que la journée a donné, imprimé par la caisse.
extends PanelContainer

const Paper := preload("res://scenes/closeups/paper.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const Denominations := preload("res://core/money/denominations.gd")

## { "day": String, "worked_seconds": int, "cents": int } ; vide s'il n'y a pas encore de ticket.
var ticket: Dictionary = {}
## Vrai : les montants sont masqués.
var discreet := false


func _ready() -> void:
	theme = Paper.theme()
	var style := Paper.sheet_style()
	style.set_corner_radius_all(2)
	style.bg_color = Color(0.985, 0.975, 0.945)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(430.0, 0.0)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	column.add_child(Paper.title("MoneyMaker"))

	if ticket.is_empty():
		column.add_child(Paper.rule())
		var waiting := Paper.label("Le premier ticket s'imprimera\nà la fin de ta journée.", 20, Paper.INK_SOFT)
		waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(waiting)
		return

	var date := Paper.label(GameCalendar.long_date(ticket["day"]), 20, Paper.INK_SOFT)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(date)
	column.add_child(Paper.rule())
	_add_line(column, "Heures travaillées", _duration(ticket["worked_seconds"]))
	_add_line(column, "Gagné ce jour-là", "•••• €" if discreet else Denominations.format_cents(ticket["cents"]))
	_add_line(column, "Focus terminés", "0")
	_add_line(column, "Fournées", "0")
	column.add_child(Paper.rule())
	var goodbye := Paper.label("Merci, et à demain !", 20, Paper.INK_SOFT)
	goodbye.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(goodbye)


func _add_line(column: VBoxContainer, caption: String, value: String) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)
	var left := Paper.label(caption)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(Paper.label(value))


## 25200 -> « 7 h 00 »
static func _duration(seconds: int) -> String:
	return "%d h %02d" % [seconds / 3600, (seconds % 3600) / 60]
