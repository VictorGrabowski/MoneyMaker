## Fiche de paie provisoire : de simples champs pour saisir salaire et horaires.
## Sera remplacée par l'objet du décor prévu à l'epic 2.
extends PanelContainer

const WorkSchedule := preload("res://core/time/work_schedule.gd")

signal saved(net_monthly_cents: int, schedule_values: Dictionary)
signal closed

const DAY_LABELS: Array[String] = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
## Jour de la semaine de chaque case, dans la convention du moteur (0 = dimanche).
const DAY_WEEKDAYS: Array[int] = [1, 2, 3, 4, 5, 6, 0]

var _net: SpinBox
var _days: Array[CheckBox] = []
var _start: SpinBox
var _end: SpinBox
var _lunch_start: SpinBox
var _lunch_minutes: SpinBox


func _ready() -> void:
	var sheet_theme := Theme.new()
	sheet_theme.default_font_size = 24
	theme = sheet_theme
	custom_minimum_size = Vector2(640, 0)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var title := Label.new()
	title.text = "Fiche de paie (provisoire)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	# Le net se saisit au centime : un pas plus grossier arrondirait le salaire à chaque enregistrement.
	_net = _add_field(grid, "Net mensuel (€)", 0.0, 100000.0, 0.01)
	# Les heures se saisissent au quart d'heure (8,5 = 8 h 30).
	_start = _add_field(grid, "Début de journée (h)", 0.0, 24.0, 0.25)
	_end = _add_field(grid, "Fin de journée (h)", 0.0, 24.0, 0.25)
	_lunch_start = _add_field(grid, "Début du déjeuner (h)", 0.0, 24.0, 0.25)
	_lunch_minutes = _add_field(grid, "Durée du déjeuner (min)", 0.0, 240.0, 1.0)

	var days_row := HBoxContainer.new()
	days_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(days_row)
	for label in DAY_LABELS:
		var box := CheckBox.new()
		box.text = label
		days_row.add_child(box)
		_days.append(box)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	column.add_child(buttons)
	var save_button := Button.new()
	save_button.text = "Enregistrer"
	save_button.pressed.connect(_on_save_pressed)
	buttons.add_child(save_button)
	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.pressed.connect(func() -> void: closed.emit())
	buttons.add_child(close_button)


## Remplit les champs avec les réglages en cours.
func show_values(net_monthly_cents: int, schedule: WorkSchedule) -> void:
	_net.value = net_monthly_cents / 100.0
	_start.value = schedule.start_minute / 60.0
	_end.value = schedule.end_minute / 60.0
	_lunch_start.value = schedule.lunch_start_minute / 60.0
	_lunch_minutes.value = schedule.lunch_duration_minutes
	for i in _days.size():
		_days[i].button_pressed = schedule.working_days.has(DAY_WEEKDAYS[i])


func _add_field(grid: GridContainer, caption: String, minimum: float, maximum: float, step: float) -> SpinBox:
	var label := Label.new()
	label.text = caption
	grid.add_child(label)
	var field := SpinBox.new()
	field.min_value = minimum
	field.max_value = maximum
	field.step = step
	field.custom_minimum_size = Vector2(220, 0)
	grid.add_child(field)
	return field


func _on_save_pressed() -> void:
	var working_days: Array[int] = []
	for i in _days.size():
		if _days[i].button_pressed:
			working_days.append(DAY_WEEKDAYS[i])
	saved.emit(roundi(_net.value * 100.0), {
		"working_days": working_days,
		"start_minute": roundi(_start.value * 60.0),
		"end_minute": roundi(_end.value * 60.0),
		"lunch_start_minute": roundi(_lunch_start.value * 60.0),
		"lunch_duration_minutes": roundi(_lunch_minutes.value),
	})
