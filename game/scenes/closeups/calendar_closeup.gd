## Le calendrier mural en gros plan : un mois, un tampon par jour clos, et la possibilité de marquer
## aujourd'hui ou un jour à venir (congé, férié, sans solde).
extends PanelContainer

const Paper := preload("res://scenes/closeups/paper.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const Payroll := preload("res://core/money/payroll.gd")
const Denominations := preload("res://core/money/denominations.gd")

const WEEKDAY_HEADERS: Array[String] = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
## Un clic sur un jour passe à la marque suivante ; "" retire la marque.
const MARK_CYCLE: Array[String] = ["", Payroll.KIND_LEAVE, Payroll.KIND_HOLIDAY, Payroll.KIND_UNPAID]
const KIND_LABELS: Dictionary = {
	Payroll.KIND_WORKED: "",
	Payroll.KIND_REST: "repos",
	Payroll.KIND_LEAVE: "congé",
	Payroll.KIND_HOLIDAY: "férié",
	Payroll.KIND_UNPAID: "sans solde",
}
const KIND_COLORS: Dictionary = {
	Payroll.KIND_WORKED: Color(0.985, 0.960, 0.900),
	Payroll.KIND_REST: Color(0.900, 0.870, 0.800),
	Payroll.KIND_LEAVE: Color(0.760, 0.860, 0.930),
	Payroll.KIND_HOLIDAY: Color(0.790, 0.900, 0.760),
	Payroll.KIND_UNPAID: Color(0.950, 0.780, 0.740),
}
const CELL_SIZE := Vector2(124.0, 84.0)

var _year := 2026
var _month := 1
var _title: Label
var _grid: GridContainer


func _ready() -> void:
	theme = Paper.theme()
	add_theme_stylebox_override("panel", Paper.sheet_style())

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 30)
	column.add_child(header)
	var previous := Button.new()
	previous.text = "  ‹  "
	previous.pressed.connect(_shift_month.bind(-1))
	header.add_child(previous)
	_title = Paper.title("")
	_title.custom_minimum_size = Vector2(380.0, 0.0)
	header.add_child(_title)
	var next := Button.new()
	next.text = "  ›  "
	next.pressed.connect(_shift_month.bind(1))
	header.add_child(next)

	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(_grid)

	column.add_child(Paper.rule())
	var hint := Paper.label("Clique sur aujourd'hui ou sur un jour à venir pour le marquer : congé, férié, sans solde.", 18, Paper.INK_SOFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

	var today := GameCalendar.date_of(Clock.now_local())
	_year = GameCalendar.year_of(today)
	_month = GameCalendar.month_of(today)
	Events.settings_changed.connect(_fill)
	Events.preferences_changed.connect(_fill)
	_fill()


func _shift_month(direction: int) -> void:
	_month += direction
	if _month < 1:
		_month = 12
		_year -= 1
	elif _month > 12:
		_month = 1
		_year += 1
	_fill()


func _fill() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_title.text = "%s %d" % [GameCalendar.month_name(_month).capitalize(), _year]
	for text in WEEKDAY_HEADERS:
		var header := Paper.label(text, 18, Paper.INK_SOFT)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_grid.add_child(header)
	for _i in GameCalendar.first_weekday_of_month(_year, _month):
		var blank := Control.new()
		blank.custom_minimum_size = CELL_SIZE
		_grid.add_child(blank)

	var payroll: Payroll = Game.state.payroll
	var today := GameCalendar.date_of(Clock.now_local())
	for number in range(1, GameCalendar.days_in_month(_year, _month) + 1):
		var day := GameCalendar.date_from(_year, _month, number)
		var kind := payroll.kind_of(day)
		var caption: String = KIND_LABELS[kind]
		if payroll.ledger.has(day):
			# Jour clos : sa nature d'alors, et ce qu'il a rapporté.
			kind = payroll.ledger[day]["kind"]
			caption = KIND_LABELS.get(kind, "")
			if payroll.ledger[day]["cents"] > 0:
				caption = _amount(payroll.ledger[day]["cents"])
		elif day == today and payroll.open_day == today and payroll.open_day_credited > 0:
			caption = _amount(payroll.open_day_credited)

		var cell := Button.new()
		cell.text = "%d\n%s" % [number, caption]
		cell.custom_minimum_size = CELL_SIZE
		cell.add_theme_font_size_override("font_size", 18)
		var fill: Color = KIND_COLORS.get(kind, KIND_COLORS[Payroll.KIND_WORKED])
		var border := Paper.CRUST if day == today else Paper.INK_SOFT
		var border_width := 4 if day == today else 1
		for state in ["normal", "disabled", "pressed"]:
			cell.add_theme_stylebox_override(state, Paper.flat(fill, border, border_width, 6, 4))
		cell.add_theme_stylebox_override("hover", Paper.flat(fill.lightened(0.3), Paper.INK, 2, 6, 4))
		cell.add_theme_color_override("font_disabled_color", Paper.INK)
		# Seuls aujourd'hui et les jours à venir peuvent être marqués.
		cell.disabled = day < today
		cell.pressed.connect(_on_day_pressed.bind(day))
		_grid.add_child(cell)


func _amount(cents: int) -> String:
	return "•••• €" if Game.state.discreet else Denominations.format_cents(cents)


func _on_day_pressed(day: String) -> void:
	var current: String = Game.state.payroll.day_marks.get(day, "")
	var next: String = MARK_CYCLE[(MARK_CYCLE.find(current) + 1) % MARK_CYCLE.size()]
	Game.set_day_mark(day, next)
