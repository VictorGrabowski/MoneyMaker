## Tout ce que le jeu doit retenir d'une session à l'autre.
## Chaque epic y ajoute sa partie ; pour l'instant : la paie, le bocal et les préférences d'affichage.
extends RefCounted

const Payroll := preload("res://core/money/payroll.gd")
const Jar := preload("res://core/money/jar.gd")
const SalaryEngine := preload("res://core/money/salary_engine.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
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
		"payroll": paid["state"],
		"ledger": paid["ledger"],
		"jar": jar.to_dict(),
		"stats": {"first_day": first_day},
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
