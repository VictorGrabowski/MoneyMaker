extends "res://tests/test_case.gd"

const WorkSchedule := preload("res://core/time/work_schedule.gd")
const SalaryEngine := preload("res://core/money/salary_engine.gd")

const NET_2000 := 200000
const MONDAY := 1
const SUNDAY := 0


func _schedule_35h() -> WorkSchedule:
	# 9 h – 17 h, déjeuner de 12 h à 13 h, du lundi au vendredi.
	return WorkSchedule.new()


func test_monthly_seconds_35h() -> void:
	var schedule := _schedule_35h()
	check_eq(schedule.effective_minutes_per_day(), 420, "7 h effectives par jour")
	check_eq(schedule.monthly_seconds(), 546000, "151,67 h par mois")


func test_worked_seconds_boundaries() -> void:
	var schedule := _schedule_35h()
	check_eq(schedule.worked_seconds_on(MONDAY, 8 * 3600), 0, "avant le début")
	check_eq(schedule.worked_seconds_on(MONDAY, 9 * 3600), 0, "à l'ouverture")
	check_eq(schedule.worked_seconds_on(MONDAY, 10 * 3600 + 1800), 5400, "à 10 h 30")
	check_eq(schedule.worked_seconds_on(MONDAY, 17 * 3600), 25200, "à la fermeture")
	check_eq(schedule.worked_seconds_on(MONDAY, 23 * 3600), 25200, "après la fermeture")
	check_eq(schedule.worked_seconds_on(SUNDAY, 12 * 3600), 0, "jour non travaillé")


func test_lunch_break_is_not_paid() -> void:
	var schedule := _schedule_35h()
	check_eq(schedule.worked_seconds_on(MONDAY, 12 * 3600), 10800, "à midi : 3 h")
	check_eq(schedule.worked_seconds_on(MONDAY, 12 * 3600 + 1800), 10800, "pendant le déjeuner : toujours 3 h")
	check_eq(schedule.worked_seconds_on(MONDAY, 13 * 3600), 10800, "fin du déjeuner : 3 h")
	check_eq(schedule.worked_seconds_on(MONDAY, 13 * 3600 + 1800), 12600, "à 13 h 30 : 3 h 30")


func test_no_lunch_break() -> void:
	var schedule := _schedule_35h()
	schedule.lunch_duration_minutes = 0
	check_eq(schedule.effective_minutes_per_day(), 480, "8 h sans pause")
	check_eq(schedule.worked_seconds_on(MONDAY, 12 * 3600 + 1800), 12600, "12 h 30 : 3 h 30")


func test_full_day_at_2000_net() -> void:
	var schedule := _schedule_35h()
	check_eq(SalaryEngine.earned_today(schedule, NET_2000, MONDAY, 17 * 3600), 9230, "92,30 € le premier jour")
	check_eq(SalaryEngine.hourly_cents(schedule, NET_2000), 1319, "13,19 € de l'heure")


func test_carry_makes_long_run_exact() -> void:
	# 13 jours complets à 2 000 € net valent exactement 1 200,00 €.
	var schedule := _schedule_35h()
	var monthly := schedule.monthly_seconds()
	var carry := 0
	var sum := 0
	for _day in 13:
		var result: Dictionary = SalaryEngine.earned(25200, NET_2000, monthly, carry)
		sum += result["cents"]
		carry = result["carry"]
	check_eq(sum, 120000, "somme sur 13 jours")
	check_eq(carry, 0, "aucun reste au bout de 13 jours")


func test_never_negative_or_crashing() -> void:
	var schedule := _schedule_35h()
	schedule.working_days = []
	check_eq(SalaryEngine.earned_today(schedule, NET_2000, MONDAY, 12 * 3600), 0, "aucun jour travaillé")
	schedule = _schedule_35h()
	schedule.end_minute = schedule.start_minute
	check_eq(SalaryEngine.earned_today(schedule, NET_2000, MONDAY, 12 * 3600), 0, "journée de durée nulle")
	check_eq(SalaryEngine.earned(1000, 0, 546000)["cents"], 0, "salaire nul")
