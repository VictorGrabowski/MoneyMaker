## La fiche de paie : la feuille où l'on règle son salaire et ses horaires.
## On y écrit comme sur du papier (« 2000 », « 9 h 30 ») ; ce qui ne se lit pas est signalé en
## rouge et rien n'est enregistré tant que la feuille n'est pas claire.
extends PanelContainer

const Paper := preload("res://scenes/closeups/paper.gd")
const WorkSchedule := preload("res://core/time/work_schedule.gd")
const Entries := preload("res://core/text/entries.gd")

## `schedule_values` porte les horaires, les jours travaillés et "manual_clocking".
signal saved(net_monthly_cents: int, schedule_values: Dictionary)
signal closed

const DAY_LABELS: Array[String] = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
## Jour de la semaine de chaque case, dans la convention du moteur (0 = dimanche).
const DAY_WEEKDAYS: Array[int] = [1, 2, 3, 4, 5, 6, 0]
const RED_INK := Color(0.700, 0.220, 0.160)

var _net: LineEdit
var _days: Array[CheckBox] = []
var _start: LineEdit
var _end: LineEdit
var _lunch_start: LineEdit
var _lunch_minutes: SpinBox
var _manual_clocking: CheckBox
var _problem: Label


func _ready() -> void:
	theme = Paper.theme()
	add_theme_stylebox_override("panel", Paper.sheet_style())
	custom_minimum_size = Vector2(700.0, 0.0)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(Paper.title("Fiche de paie"))
	column.add_child(Paper.rule())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	_net = _add_field(grid, "Net mensuel (€)", "2000")
	_start = _add_field(grid, "Début de journée", "9 h 00")
	_end = _add_field(grid, "Fin de journée", "17 h 00")
	_lunch_start = _add_field(grid, "Début du déjeuner", "12 h 00")
	grid.add_child(Paper.label("Durée du déjeuner (min)"))
	_lunch_minutes = SpinBox.new()
	_lunch_minutes.min_value = 0.0
	_lunch_minutes.max_value = 240.0
	_lunch_minutes.step = 1.0
	_lunch_minutes.custom_minimum_size = Vector2(240.0, 0.0)
	grid.add_child(_lunch_minutes)

	column.add_child(Paper.label("Jours travaillés", 20, Paper.INK_SOFT))
	var days_row := HBoxContainer.new()
	days_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(days_row)
	for text in DAY_LABELS:
		var box := CheckBox.new()
		box.text = text
		days_row.add_child(box)
		_days.append(box)

	# Pointage à la main : pour qui n'a pas d'horaires fixes.
	_manual_clocking = CheckBox.new()
	_manual_clocking.text = "Je pointe moi-même mes journées"
	_manual_clocking.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_manual_clocking)
	var note := Paper.label("Le temps ne compte alors que lorsque le chevalet du bureau dit « Au travail » :\nun clic dessus pour commencer la journée, un autre pour la finir.", 16, Paper.INK_SOFT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)

	_problem = Paper.label("", 18, RED_INK)
	_problem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_problem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_problem.visible = false
	column.add_child(_problem)

	column.add_child(Paper.rule())
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	column.add_child(buttons)
	var save_button := Button.new()
	save_button.text = "Enregistrer"
	save_button.pressed.connect(save)
	buttons.add_child(save_button)
	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.pressed.connect(func() -> void: closed.emit())
	buttons.add_child(close_button)


## Remplit les champs avec les réglages en cours.
func show_values(net_monthly_cents: int, schedule: WorkSchedule, manual_clocking: bool = false) -> void:
	# Tant que rien n'est réglé, le champ reste vide : son exemple en gris montre quoi écrire.
	_net.text = Entries.text_from_cents(net_monthly_cents) if net_monthly_cents > 0 else ""
	_start.text = Entries.text_from_minutes(schedule.start_minute)
	_end.text = Entries.text_from_minutes(schedule.end_minute)
	_lunch_start.text = Entries.text_from_minutes(schedule.lunch_start_minute)
	_lunch_minutes.value = schedule.lunch_duration_minutes
	_manual_clocking.button_pressed = manual_clocking
	for i in _days.size():
		_days[i].button_pressed = schedule.working_days.has(DAY_WEEKDAYS[i])
	if net_monthly_cents <= 0:
		# Feuille vierge : la plume est déjà posée sur la première ligne.
		_net.grab_focus.call_deferred()


## Ce que dit la feuille telle qu'elle est remplie : { "problem": String } si quelque chose ne va
## pas, sinon { "net_monthly_cents": int, "schedule_values": Dictionary }.
func read_values() -> Dictionary:
	# Un net laissé vide n'est pas illisible : il manque.
	var net := Entries.cents_from_text(_net.text) if _net.text.strip_edges() != "" else 0
	var start := Entries.minutes_from_text(_start.text)
	var end := Entries.minutes_from_text(_end.text)
	var lunch_start := Entries.minutes_from_text(_lunch_start.text)
	_flag(_net, net <= 0)
	_flag(_start, start < 0)
	_flag(_end, end < 0 or (start >= 0 and end <= start))
	_flag(_lunch_start, lunch_start < 0)

	var working_days: Array[int] = []
	for i in _days.size():
		if _days[i].button_pressed:
			working_days.append(DAY_WEEKDAYS[i])

	if net < 0 or start < 0 or end < 0 or lunch_start < 0:
		return {"problem": "Je n'arrive pas à lire ce qui est en rouge. Une somme s'écrit 2000 ou 1834,50 ; une heure, 9 h 30."}
	if net == 0:
		return {"problem": "Il manque le net mensuel : sans lui, rien ne tombe dans le bocal."}
	if end <= start:
		return {"problem": "La journée doit finir après avoir commencé."}
	if working_days.is_empty():
		return {"problem": "Coche au moins un jour travaillé."}
	return {
		"net_monthly_cents": net,
		"schedule_values": {
			"working_days": working_days,
			"start_minute": start,
			"end_minute": end,
			"lunch_start_minute": lunch_start,
			"lunch_duration_minutes": roundi(_lunch_minutes.value),
			"manual_clocking": _manual_clocking.button_pressed,
		},
	}


func _add_field(grid: GridContainer, caption: String, example: String) -> LineEdit:
	grid.add_child(Paper.label(caption))
	var field := LineEdit.new()
	field.placeholder_text = example
	field.custom_minimum_size = Vector2(240.0, 0.0)
	field.text_submitted.connect(func(_text: String) -> void: save())
	grid.add_child(field)
	return field


## Écrit et entoure un champ en rouge quand il pose problème.
func _flag(field: LineEdit, wrong: bool) -> void:
	for style in ["normal", "focus"]:
		if wrong:
			field.add_theme_stylebox_override(style, Paper.flat(Color(1.0, 0.95, 0.92), RED_INK, 3, 6, 8))
		else:
			field.remove_theme_stylebox_override(style)
	if wrong:
		field.add_theme_color_override("font_color", RED_INK)
	else:
		field.remove_theme_color_override("font_color")


## Enregistre la feuille si elle est claire ; sinon dit ce qui ne va pas et n'enregistre rien.
func save() -> void:
	var values := read_values()
	_problem.visible = values.has("problem")
	if values.has("problem"):
		_problem.text = values["problem"]
		return
	saved.emit(values["net_monthly_cents"], values["schedule_values"])
