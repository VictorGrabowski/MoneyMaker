## Tout ce que le jeu doit retenir d'une session à l'autre.
## Chaque epic y ajoute sa partie ; pour l'instant : la paie, le bocal et les préférences d'affichage.
extends RefCounted

const Payroll := preload("res://core/money/payroll.gd")
const Jar := preload("res://core/money/jar.gd")
const SalaryEngine := preload("res://core/money/salary_engine.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const Weather := preload("res://core/world/weather.gd")
const Migrations := preload("res://core/save/migrations.gd")

const WIDGET_PASTILLE := "pastille"
const WIDGET_BANDEAU := "bandeau"
const WIDGET_MINI_BOCAL := "mini_bocal"
const WIDGET_FORMATS: Array[String] = [WIDGET_PASTILLE, WIDGET_BANDEAU, WIDGET_MINI_BOCAL]
const WIDGET_MIN_OPACITY := 0.6

var payroll := Payroll.new()
## Les espèces gagnées et pas encore déposées.
var jar := Jar.new()
## Opérations du bocal produites par le dernier advance(), à jouer par la scène.
var last_jar_ops: Array[Dictionary] = []
## Premier jour d'utilisation (« AAAA-MM-JJ »), vide tant que le jeu n'a jamais tourné.
var first_day := ""

# --- Préférences d'affichage ---
var widget_format := WIDGET_BANDEAU
## Position du widget à l'écran ; has_widget_position dit si elle a déjà été choisie.
var widget_position := Vector2i.ZERO
var has_widget_position := false
var widget_opacity := 1.0
## Mode discret : les montants sont masqués.
var discreet := false
var sound_enabled := true

# --- Le monde ---
## Ville de la joueuse, pour le soleil et la météo. Les coordonnées sont arrondies au dixième de degré.
var city_name := ""
var latitude := 0.0
var longitude := 0.0
var has_city := false
var weather_mode := Weather.MODE_REAL
## Météo choisie à la main (mode manuel).
var manual_weather := Weather.CLEAR
## Dernière météo réelle connue, et quand elle a été relevée (secondes locales, 0 = jamais).
var last_weather := Weather.CLEAR
var last_weather_at := 0
## Dernier jour dont le ticket du soir a été lu (« AAAA-MM-JJ »).
var ticket_seen_day := ""


## Fait avancer la paie et verse les centimes gagnés dans le bocal. Renvoie ces centimes.
func advance(now_local: int) -> int:
	if first_day == "":
		first_day = GameCalendar.date_of(now_local)
	var earned := payroll.advance(now_local)
	refresh_jar_capacity()
	last_jar_ops = jar.add_cents(earned)
	return earned


## Recalcule ce que vaut un bocal plein. À appeler quand le salaire ou les horaires changent.
func refresh_jar_capacity() -> void:
	var schedule := payroll.schedule
	var day: int = SalaryEngine.earned(schedule.worked_seconds_at(GameCalendar.SECONDS_PER_DAY),
		payroll.net_monthly_cents, schedule.monthly_seconds())["cents"]
	jar.day_pay_cents = day
	jar.week_pay_cents = day * schedule.working_days.size()
	jar.month_pay_cents = payroll.net_monthly_cents if payroll.is_configured() else 0


## Après un changement de salaire : ramène le bocal à son nouveau niveau. Renvoie les opérations à jouer.
func rebalance_jar() -> Array[Dictionary]:
	refresh_jar_capacity()
	return jar.rebalance()


func set_widget_format(format: String) -> void:
	if WIDGET_FORMATS.has(format):
		widget_format = format


func set_widget_opacity(opacity: float) -> void:
	widget_opacity = clampf(opacity, WIDGET_MIN_OPACITY, 1.0)


func set_widget_position(position: Vector2i) -> void:
	widget_position = position
	has_widget_position = true


## Retient la ville. Les coordonnées sont arrondies : elles ne servent qu'au soleil et à la météo.
func set_city(name: String, city_latitude: float, city_longitude: float) -> void:
	city_name = name.strip_edges()
	latitude = roundf(clampf(city_latitude, -90.0, 90.0) * 10.0) / 10.0
	longitude = roundf(clampf(city_longitude, -180.0, 180.0) * 10.0) / 10.0
	has_city = city_name != ""
	# La météo connue était celle d'une autre ville.
	last_weather_at = 0


func clear_city() -> void:
	city_name = ""
	latitude = 0.0
	longitude = 0.0
	has_city = false
	last_weather_at = 0


func set_weather_mode(mode: String) -> void:
	if Weather.MODES.has(mode):
		weather_mode = mode


func set_manual_weather(state: String) -> void:
	if Weather.is_state(state):
		manual_weather = state


## Retient la météo réelle qui vient d'être relevée.
func remember_weather(state: String, now_local: int) -> void:
	if Weather.is_state(state):
		last_weather = state
		last_weather_at = now_local


## La météo à montrer : celle choisie à la main, sinon la dernière connue, sinon un ciel clair.
func shown_weather() -> String:
	if weather_mode == Weather.MODE_MANUAL:
		return manual_weather
	return last_weather if last_weather_at > 0 else Weather.CLEAR


## Le ticket du soir à montrer : le dernier jour travaillé terminé. {} s'il n'y en a pas.
## { "day": String, "worked_seconds": int, "cents": int }
func evening_ticket(now_local: int) -> Dictionary:
	var today := GameCalendar.date_of(now_local)
	var schedule := payroll.schedule
	var day_is_over := GameCalendar.second_of_day(now_local) >= schedule.end_minute * 60
	if payroll.open_day == today and day_is_over and payroll.open_day_credited > 0:
		return {"day": today, "worked_seconds": payroll.open_day_worked, "cents": payroll.open_day_credited}
	var days := payroll.ledger.keys()
	days.sort()
	for i in range(days.size() - 1, -1, -1):
		var line: Dictionary = payroll.ledger[days[i]]
		if line["cents"] > 0:
			return {"day": days[i], "worked_seconds": line["worked_seconds"], "cents": line["cents"]}
	return {}


func to_dict(now_local: int) -> Dictionary:
	var paid := payroll.to_dict()
	var widget := {"format": widget_format, "opacity": widget_opacity}
	if has_widget_position:
		widget["position"] = [widget_position.x, widget_position.y]
	return {
		"version": Migrations.CURRENT_VERSION,
		"saved_at": now_local,
		"settings": paid["settings"],
		"preferences": {"widget": widget, "discreet": discreet, "sound": sound_enabled},
		"world": {
			"city": {"name": city_name, "latitude": latitude, "longitude": longitude} if has_city else {},
			"weather": {"mode": weather_mode, "manual": manual_weather, "last": last_weather, "last_at": last_weather_at},
		},
		"payroll": paid["state"],
		"ledger": paid["ledger"],
		"jar": jar.to_dict(),
		"stats": {"first_day": first_day, "ticket_seen_day": ticket_seen_day},
	}


## Recharge une sauvegarde déjà passée par Migrations.migrate().
func load_dict(data: Dictionary) -> void:
	payroll.load_dict({
		"settings": data.get("settings", {}),
		"state": data.get("payroll", {}),
		"ledger": data.get("ledger", {}),
	})
	# La capacité d'abord : le bocal en a besoin s'il doit se recomposer.
	refresh_jar_capacity()
	jar.load_dict(_dictionary(data.get("jar")))

	var stats := _dictionary(data.get("stats"))
	first_day = str(stats.get("first_day", ""))
	ticket_seen_day = str(stats.get("ticket_seen_day", ""))

	var world := _dictionary(data.get("world"))
	clear_city()
	var city := _dictionary(world.get("city"))
	if str(city.get("name", "")).strip_edges() != "":
		set_city(str(city["name"]), float(city.get("latitude", 0.0)), float(city.get("longitude", 0.0)))
	var saved_weather := _dictionary(world.get("weather"))
	weather_mode = Weather.MODE_REAL
	set_weather_mode(str(saved_weather.get("mode", Weather.MODE_REAL)))
	manual_weather = Weather.CLEAR
	set_manual_weather(str(saved_weather.get("manual", Weather.CLEAR)))
	last_weather = Weather.CLEAR
	last_weather_at = 0
	remember_weather(str(saved_weather.get("last", Weather.CLEAR)), maxi(0, int(saved_weather.get("last_at", 0))))

	var preferences := _dictionary(data.get("preferences"))
	discreet = bool(preferences.get("discreet", false))
	sound_enabled = bool(preferences.get("sound", true))
	var widget := _dictionary(preferences.get("widget"))
	widget_format = WIDGET_BANDEAU
	set_widget_format(str(widget.get("format", WIDGET_BANDEAU)))
	set_widget_opacity(float(widget.get("opacity", 1.0)))
	has_widget_position = false
	var position: Variant = widget.get("position")
	if typeof(position) == TYPE_ARRAY and position.size() == 2:
		set_widget_position(Vector2i(int(position[0]), int(position[1])))


## Un dictionnaire, quoi que contienne le fichier à cet endroit.
static func _dictionary(value: Variant) -> Dictionary:
	return value if typeof(value) == TYPE_DICTIONARY else {}
