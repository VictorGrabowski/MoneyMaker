## Le baromètre en gros plan : le ciel du jeu suit le ciel réel de sa ville, ou un temps choisi.
extends PanelContainer

const Paper := preload("res://scenes/closeups/paper.gd")
const Weather := preload("res://core/world/weather.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")

var _real: Button
var _manual: Button
var _states_row: HBoxContainer
var _state_buttons: Dictionary = {}
var _city_label: Label
var _city_field: LineEdit
var _results: VBoxContainer
var _status: Label
var _forget: Button


func _ready() -> void:
	theme = Paper.theme()
	add_theme_stylebox_override("panel", Paper.sheet_style())
	custom_minimum_size = Vector2(760.0, 0.0)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	column.add_child(Paper.title("Le temps qu'il fait"))
	column.add_child(Paper.rule())

	var modes := HBoxContainer.new()
	modes.alignment = BoxContainer.ALIGNMENT_CENTER
	modes.add_theme_constant_override("separation", 16)
	column.add_child(modes)
	_real = _toggle(modes, "Le ciel de ma ville", _set_mode.bind(Weather.MODE_REAL))
	_manual = _toggle(modes, "Je choisis", _set_mode.bind(Weather.MODE_MANUAL))

	_states_row = HBoxContainer.new()
	_states_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_states_row.add_theme_constant_override("separation", 10)
	column.add_child(_states_row)
	for state in Weather.STATES:
		_state_buttons[state] = _toggle(_states_row, Weather.LABELS[state], _set_manual.bind(state))

	_status = Paper.label("", 20, Paper.INK_SOFT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status)
	column.add_child(Paper.rule())

	_city_label = Paper.label("")
	column.add_child(_city_label)
	var search := HBoxContainer.new()
	search.add_theme_constant_override("separation", 12)
	column.add_child(search)
	_city_field = LineEdit.new()
	_city_field.placeholder_text = "Nom de ta ville"
	_city_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_city_field.text_submitted.connect(func(_text: String) -> void: _search())
	search.add_child(_city_field)
	var search_button := Button.new()
	search_button.text = "Chercher"
	search_button.pressed.connect(_search)
	search.add_child(search_button)
	_forget = Button.new()
	_forget.text = "Oublier"
	_forget.pressed.connect(func() -> void: Game.clear_city())
	search.add_child(_forget)
	_results = VBoxContainer.new()
	_results.add_theme_constant_override("separation", 6)
	column.add_child(_results)

	var note := Paper.label("Sans ville, le soleil est celui du centre de la France et le ciel reste clair.\nSeules la latitude et la longitude, arrondies, sont envoyées au service météo.", 16, Paper.INK_SOFT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)

	Atmosphere.cities_found.connect(_on_cities_found)
	Events.world_changed.connect(_refresh)
	_refresh()


func _toggle(parent: Control, text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button


func _refresh() -> void:
	var state := Game.state
	var manual := state.weather_mode == Weather.MODE_MANUAL
	_real.button_pressed = not manual
	_manual.button_pressed = manual
	_states_row.visible = manual
	for weather_state in _state_buttons:
		(_state_buttons[weather_state] as Button).button_pressed = weather_state == state.manual_weather

	if manual:
		_status.text = "Dehors : %s." % String(Weather.LABELS[state.manual_weather]).to_lower()
	elif not state.has_city:
		_status.text = "Indique ta ville pour que le ciel du jeu suive le vrai."
	elif state.last_weather_at == 0:
		_status.text = "En attente du premier relevé…"
	else:
		var seconds := GameCalendar.second_of_day(state.last_weather_at)
		_status.text = "Dehors : %s (relevé à %d h %02d)." % [
			String(Weather.LABELS[state.last_weather]).to_lower(), seconds / 3600, (seconds % 3600) / 60]

	_city_label.text = "Ma ville : %s" % state.city_name if state.has_city else "Ma ville : aucune"
	_forget.visible = state.has_city


func _set_mode(mode: String) -> void:
	Game.set_weather(mode, Game.state.manual_weather)


func _set_manual(weather_state: String) -> void:
	Game.set_weather(Weather.MODE_MANUAL, weather_state)


func _search() -> void:
	for child in _results.get_children():
		child.queue_free()
	_results.add_child(Paper.label("Recherche…", 18, Paper.INK_SOFT))
	Atmosphere.search_city(_city_field.text)


func _on_cities_found(results: Array[Dictionary]) -> void:
	for child in _results.get_children():
		child.queue_free()
	if results.is_empty():
		_results.add_child(Paper.label("Aucune ville trouvée (ou pas de connexion).", 18, Paper.INK_SOFT))
		return
	for city in results:
		var choice := Button.new()
		choice.text = "%s — %s" % [city["name"], city["region"]] if city["region"] != "" else str(city["name"])
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.pressed.connect(_choose.bind(city))
		_results.add_child(choice)


func _choose(city: Dictionary) -> void:
	Game.set_city(city["name"], city["latitude"], city["longitude"])
	for child in _results.get_children():
		child.queue_free()
	_city_field.text = ""
