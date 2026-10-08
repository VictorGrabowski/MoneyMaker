## La paie : transforme le temps qui passe en centimes, jour après jour.
##
## Trois règles tiennent l'ensemble :
##  - un jour clos (inscrit au journal) n'est plus jamais modifié ;
##  - la journée en cours est recalculée avec les réglages du moment, et rien n'est jamais repris ;
##  - une même date n'est jamais payée deux fois, même si l'horloge du PC recule.
##
## Les instants sont des secondes locales (voir game_calendar.gd).
extends RefCounted

const WorkSchedule := preload("res://core/time/work_schedule.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const SalaryEngine := preload("res://core/money/salary_engine.gd")

const KIND_WORKED := "travaille"
const KIND_REST := "repos"
const KIND_LEAVE := "conge"
const KIND_HOLIDAY := "ferie"
const KIND_UNPAID := "sans_solde"
## Les marques que la joueuse peut poser sur un jour du calendrier.
const MARKS: Array[String] = [KIND_LEAVE, KIND_HOLIDAY, KIND_UNPAID]

## Jours payés au plus quand le jeu est resté fermé longtemps.
const MAX_CATCH_UP_DAYS := 31
## Pointage manuel : temps compté au plus par jour.
const MANUAL_DAY_CAP_SECONDS := 16 * 3600
const LEDGER_MAX_DAYS := 400

# --- Réglages ---
var schedule := WorkSchedule.new()
var net_monthly_cents := 0
## Vrai : le temps ne compte qu'entre un pointage d'arrivée et un pointage de départ.
var manual_clocking := false
## « AAAA-MM-JJ » -> KIND_LEAVE, KIND_HOLIDAY ou KIND_UNPAID.
var day_marks: Dictionary = {}

# --- État ---
## Jours clos : « AAAA-MM-JJ » -> { "worked_seconds": int, "cents": int, "kind": String }.
var ledger: Dictionary = {}
var open_day := ""
var open_day_credited := 0
var open_day_worked := 0
## Fraction de centime en attente : carry_numerator / carry_denominator.
var carry_numerator := 0
var carry_denominator := 0
var total_earned_cents := 0
var clocked_in_at := -1
var manual_worked_today := 0


func is_configured() -> bool:
	return net_monthly_cents > 0 and schedule.monthly_seconds() > 0


## Centimes tombés aujourd'hui.
func earned_today() -> int:
	return open_day_credited


func hourly_cents() -> int:
	return SalaryEngine.hourly_cents(schedule, net_monthly_cents)


## Nature d'un jour : sa marque s'il en a une, sinon ce que dit l'horaire.
func kind_of(day: String) -> String:
	if day_marks.has(day):
		return day_marks[day]
	return KIND_WORKED if schedule.is_working_day(GameCalendar.weekday_of_date(day)) else KIND_REST


## Fait avancer la paie jusqu'à `now_local` et renvoie les centimes nouvellement gagnés.
## À appeler chaque seconde et au lancement : c'est aussi le rattrapage hors ligne.
func advance(now_local: int) -> int:
	var today := GameCalendar.date_of(now_local)
	var credited := 0
	if open_day == "":
		_open(today)
	elif today > open_day:
		credited += _close_open_day()
		credited += _close_missed_days(open_day, today)
		_open(today)
	elif today < open_day:
		# L'horloge a reculé d'au moins un jour : la journée en cours est rangée telle quelle,
		# elle reprendra où elle en était quand sa date reviendra.
		_record(open_day, open_day_worked, open_day_credited)
		_open(today)
	credited += _credit_open_day(GameCalendar.second_of_day(now_local))
	total_earned_cents += credited
	return credited


## Pose (ou retire, avec "") une marque sur aujourd'hui ou un jour à venir. Faux si refusé.
func set_day_mark(day: String, kind: String) -> bool:
	if not GameCalendar.is_valid_date(day) or ledger.has(day):
		return false
	if open_day != "" and day < open_day:
		return false
	if kind == "":
		day_marks.erase(day)
		return true
	if not MARKS.has(kind):
		return false
	day_marks[day] = kind
	return true


func is_clocked_in() -> bool:
	return clocked_in_at >= 0


## Pointage d'arrivée (sans effet hors pointage manuel).
func clock_in(now_local: int) -> void:
	if manual_clocking and clocked_in_at < 0:
		clocked_in_at = now_local


## Pointage de départ.
func clock_out(now_local: int) -> void:
	if clocked_in_at < 0:
		return
	manual_worked_today = mini(manual_worked_today + maxi(0, now_local - clocked_in_at), MANUAL_DAY_CAP_SECONDS)
	clocked_in_at = -1


func to_dict() -> Dictionary:
	return {
		"settings": {
			"net_monthly_cents": net_monthly_cents,
			"manual_clocking": manual_clocking,
			"schedule": {
				"working_days": schedule.working_days.duplicate(),
				"start_minute": schedule.start_minute,
				"end_minute": schedule.end_minute,
				"lunch_start_minute": schedule.lunch_start_minute,
				"lunch_duration_minutes": schedule.lunch_duration_minutes,
			},
			"day_marks": day_marks.duplicate(),
		},
		"state": {
			"open_day": open_day,
			"open_day_credited": open_day_credited,
			"open_day_worked": open_day_worked,
			"carry_numerator": carry_numerator,
			"carry_denominator": carry_denominator,
			"total_earned_cents": total_earned_cents,
			"clocked_in_at": clocked_in_at,
			"manual_worked_today": manual_worked_today,
		},
		"ledger": ledger.duplicate(true),
	}


## Recharge ce que to_dict() a produit. Tolère les nombres à virgule d'un fichier JSON
## et les champs absents (ils gardent leur valeur par défaut).
func load_dict(data: Dictionary) -> void:
	var settings: Dictionary = data.get("settings", {})
	net_monthly_cents = maxi(0, int(settings.get("net_monthly_cents", 0)))
	manual_clocking = bool(settings.get("manual_clocking", false))
	apply_schedule_dict(settings.get("schedule", {}))
	day_marks = {}
	var marks: Dictionary = settings.get("day_marks", {})
	for day in marks:
		if MARKS.has(marks[day]) and GameCalendar.is_valid_date(day):
			day_marks[day] = marks[day]

	var state: Dictionary = data.get("state", {})
	open_day = str(state.get("open_day", ""))
	if open_day != "" and not GameCalendar.is_valid_date(open_day):
		open_day = ""
	open_day_credited = maxi(0, int(state.get("open_day_credited", 0)))
	open_day_worked = maxi(0, int(state.get("open_day_worked", 0)))
	carry_numerator = maxi(0, int(state.get("carry_numerator", 0)))
	carry_denominator = maxi(0, int(state.get("carry_denominator", 0)))
	total_earned_cents = maxi(0, int(state.get("total_earned_cents", 0)))
	clocked_in_at = int(state.get("clocked_in_at", -1))
	manual_worked_today = maxi(0, int(state.get("manual_worked_today", 0)))

	ledger = {}
	var lines: Dictionary = data.get("ledger", {})
	for day in lines:
		var line: Dictionary = lines[day]
		if GameCalendar.is_valid_date(day):
			ledger[day] = {
				"worked_seconds": maxi(0, int(line.get("worked_seconds", 0))),
				"cents": maxi(0, int(line.get("cents", 0))),
				"kind": str(line.get("kind", KIND_WORKED)),
			}


## Applique des horaires venus d'un formulaire ou d'un fichier ; les valeurs absurdes sont ignorées.
func apply_schedule_dict(values: Dictionary) -> void:
	if values.has("working_days"):
		var days: Array[int] = []
		for value in values["working_days"]:
			if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
				continue
			var weekday := int(value)
			if weekday >= 0 and weekday <= 6 and not days.has(weekday):
				days.append(weekday)
		days.sort()
		schedule.working_days = days
	schedule.start_minute = clampi(int(values.get("start_minute", schedule.start_minute)), 0, 1440)
	schedule.end_minute = clampi(int(values.get("end_minute", schedule.end_minute)), 0, 1440)
	schedule.lunch_start_minute = clampi(int(values.get("lunch_start_minute", schedule.lunch_start_minute)), 0, 1440)
	schedule.lunch_duration_minutes = clampi(int(values.get("lunch_duration_minutes", schedule.lunch_duration_minutes)), 0, 600)


func _open(day: String) -> void:
	open_day = day
	open_day_credited = 0
	open_day_worked = 0
	manual_worked_today = 0
	if ledger.has(day):
		# Cette date a déjà été payée, en tout ou partie : on repart de ce qui a été versé.
		var line: Dictionary = ledger[day]
		open_day_credited = line["cents"]
		open_day_worked = line["worked_seconds"]
		if manual_clocking:
			manual_worked_today = line["worked_seconds"]
		ledger.erase(day)


## Secondes travaillées le jour `day`, de minuit à `second_of_day`.
func _worked_seconds(day: String, second_of_day: int) -> int:
	if day_marks.get(day, "") == KIND_UNPAID:
		return 0
	if manual_clocking:
		if day != open_day:
			return 0
		var running := 0
		if clocked_in_at >= 0:
			running = maxi(0, GameCalendar.local_from_text(day) + second_of_day - clocked_in_at)
		return mini(manual_worked_today + running, MANUAL_DAY_CAP_SECONDS)
	return schedule.worked_seconds_on(GameCalendar.weekday_of_date(day), second_of_day)


## Centimes dus pour `worked_seconds` depuis le début du jour, reste compris.
func _earn(worked_seconds: int) -> Dictionary:
	var monthly := schedule.monthly_seconds()
	if carry_denominator != monthly:
		# Les horaires ont changé : la fraction de centime en attente garde sa valeur.
		carry_numerator = carry_numerator * monthly / carry_denominator if carry_denominator > 0 else 0
		carry_denominator = monthly
	return SalaryEngine.earned(worked_seconds, net_monthly_cents, monthly, carry_numerator)


func _credit_open_day(second_of_day: int) -> int:
	var worked := _worked_seconds(open_day, second_of_day)
	open_day_worked = maxi(open_day_worked, worked)
	var due: int = _earn(worked)["cents"]
	if due <= open_day_credited:
		return 0
	var delta := due - open_day_credited
	open_day_credited = due
	return delta


func _close_open_day() -> int:
	var worked := _worked_seconds(open_day, GameCalendar.SECONDS_PER_DAY)
	var result := _earn(worked)
	var due: int = result["cents"]
	var delta := maxi(0, due - open_day_credited)
	# Une journée qui a déjà reçu plus que son dû (réglages revus à la baisse) ne laisse aucun reste.
	carry_numerator = result["carry"] if due >= open_day_credited else 0
	_record(open_day, maxi(open_day_worked, worked), open_day_credited + delta)
	clocked_in_at = -1
	manual_worked_today = 0
	return delta


## Paie les jours entiers passés pendant que le jeu était fermé, entre deux dates exclues.
func _close_missed_days(after_day: String, before_day: String) -> int:
	var credited := 0
	var day := GameCalendar.next_date(after_day)
	if GameCalendar.days_between(day, before_day) > MAX_CATCH_UP_DAYS:
		day = GameCalendar.add_days(before_day, -MAX_CATCH_UP_DAYS)
	while day < before_day:
		if not ledger.has(day):
			var worked := _worked_seconds(day, GameCalendar.SECONDS_PER_DAY)
			var result := _earn(worked)
			carry_numerator = result["carry"]
			_record(day, worked, result["cents"])
			credited += result["cents"]
		day = GameCalendar.next_date(day)
	return credited


func _record(day: String, worked_seconds: int, cents: int) -> void:
	ledger[day] = {"worked_seconds": worked_seconds, "cents": cents, "kind": kind_of(day)}
	if ledger.size() > LEDGER_MAX_DAYS:
		var days := ledger.keys()
		days.sort()
		for i in ledger.size() - LEDGER_MAX_DAYS:
			ledger.erase(days[i])
