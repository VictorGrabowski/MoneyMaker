extends "res://tests/test_case.gd"

const Payroll := preload("res://core/money/payroll.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")

# Semaine de référence : lundi 5 octobre 2026.
const MON := "2026-10-05"
const TUE := "2026-10-06"
const WED := "2026-10-07"
const FRI := "2026-10-09"
const SAT := "2026-10-10"
const SUN := "2026-10-11"
const NEXT_MON := "2026-10-12"

## Une journée complète à 2 000 € net et 35 h : 92,30 € (le reste de 0,77 c est reporté).
const FULL_DAY := 9230


func _payroll() -> Payroll:
	var payroll := Payroll.new()
	payroll.net_monthly_cents = 200000
	return payroll


func _at(day: String, clock: String) -> int:
	return GameCalendar.local_from_text("%sT%s:00" % [day, clock])


func test_first_launch_pays_since_the_morning() -> void:
	var payroll := _payroll()
	check_eq(payroll.advance(_at(MON, "12:00")), 3956, "3 h à 13,19 €")
	check_eq(payroll.earned_today(), 3956, "gagné aujourd'hui")
	check_eq(payroll.open_day, MON, "jour en cours")


func test_increments_add_up_to_the_day() -> void:
	var payroll := _payroll()
	var sum := 0
	for clock in ["09:00", "10:00", "10:30", "12:30", "16:59", "17:00", "23:00"]:
		var earned := payroll.advance(_at(MON, clock))
		check(earned >= 0, "jamais négatif à %s" % clock)
		sum += earned
	check_eq(sum, FULL_DAY, "total de la journée")


func test_same_instant_pays_nothing_more() -> void:
	var payroll := _payroll()
	payroll.advance(_at(MON, "11:00"))
	check_eq(payroll.advance(_at(MON, "11:00")), 0, "même instant")


func test_end_of_day_is_caught_up_offline() -> void:
	var payroll := _payroll()
	var before := payroll.advance(_at(MON, "15:00"))
	var after := payroll.advance(_at(TUE, "08:00"))
	check_eq(before + after, FULL_DAY, "le lundi est payé en entier")
	check_eq(payroll.ledger[MON]["cents"], FULL_DAY, "ligne du lundi")
	check_eq(payroll.ledger[MON]["worked_seconds"], 25200, "7 h travaillées")
	check_eq(payroll.ledger[MON]["kind"], Payroll.KIND_WORKED, "jour travaillé")
	check_eq(payroll.open_day, TUE, "le mardi est ouvert")
	check_eq(payroll.earned_today(), 0, "rien encore mardi à 8 h")


func test_weekend_is_not_paid() -> void:
	var payroll := _payroll()
	check_eq(payroll.advance(_at(FRI, "17:30")), FULL_DAY, "vendredi complet")
	check_eq(payroll.advance(_at(NEXT_MON, "08:59")), 0, "rien pendant le week-end")
	check_eq(payroll.ledger[SAT]["kind"], Payroll.KIND_REST, "samedi : repos")
	check_eq(payroll.ledger[SUN]["cents"], 0, "dimanche : 0")


func test_two_weeks_away() -> void:
	var payroll := _payroll()
	var first := payroll.advance(_at(MON, "18:00"))
	var second := payroll.advance(_at("2026-10-19", "08:00"))
	# Dix jours travaillés du 5 au 16 : 10 × 25 200 s × 2 000 € ÷ 546 000 s = 923,07 €.
	check_eq(first + second, 92307, "dix jours travaillés")
	check_eq(payroll.ledger.size(), 14, "quatorze jours clos")


func test_long_absence_is_capped_at_31_days() -> void:
	var payroll := _payroll()
	payroll.advance(_at(MON, "18:00"))
	var caught_up := payroll.advance(_at("2027-01-04", "08:00"))
	# Seuls les 31 jours du 4 décembre au 3 janvier sont payés : 21 jours travaillés.
	check_eq(caught_up, 193846, "21 jours travaillés")
	check(not payroll.ledger.has("2026-11-10"), "novembre n'est pas payé")
	check(payroll.ledger.has("2026-12-04"), "le 4 décembre est payé")


func test_thirteen_working_days_are_exact() -> void:
	var payroll := _payroll()
	var sum := payroll.advance(_at(MON, "18:00"))
	sum += payroll.advance(_at("2026-10-22", "08:00"))
	check_eq(sum, 120000, "13 jours travaillés = 1 200,00 €")
	check_eq(payroll.carry_numerator, 0, "aucune fraction de centime en attente")
	check_eq(payroll.total_earned_cents, 120000, "cumul")


func test_clock_set_back_within_the_day() -> void:
	var payroll := _payroll()
	var sum := payroll.advance(_at(MON, "15:00"))
	check_eq(payroll.advance(_at(MON, "11:00")), 0, "retour en arrière : rien")
	sum += payroll.advance(_at(MON, "17:00"))
	check_eq(sum, FULL_DAY, "pas de double paie")


func test_clock_set_back_several_days_never_pays_a_date_twice() -> void:
	var payroll := _payroll()
	var sum := payroll.advance(_at(WED, "18:00"))
	sum += payroll.advance(_at(MON, "12:00"))
	sum += payroll.advance(_at(WED, "18:00"))
	# Lundi, mardi et mercredi payés une fois chacun : 3 × 25 200 s × 2 000 € ÷ 546 000 s.
	check_eq(sum, 27692, "trois jours, une seule fois")
	check_eq(payroll.open_day, WED, "retour au mercredi")


func test_lowering_the_salary_takes_nothing_back() -> void:
	var payroll := _payroll()
	var morning := payroll.advance(_at(MON, "15:00"))
	check_eq(morning, 6593, "5 h à 13,19 €")
	payroll.net_monthly_cents = 100000
	check_eq(payroll.advance(_at(MON, "16:00")), 0, "rien de plus au nouveau salaire")
	check_eq(payroll.advance(_at(TUE, "08:00")), 0, "rien à la clôture")
	check_eq(payroll.ledger[MON]["cents"], 6593, "le lundi garde ce qui est tombé")


func test_setting_the_salary_during_the_day_pays_since_the_morning() -> void:
	var payroll := Payroll.new()
	check_eq(payroll.advance(_at(MON, "10:00")), 0, "pas de salaire saisi")
	check(not payroll.is_configured(), "non réglé")
	payroll.net_monthly_cents = 200000
	check_eq(payroll.advance(_at(MON, "10:00")), 1318, "1 h depuis 9 h")


func test_changing_hours_never_touches_closed_days() -> void:
	var payroll := _payroll()
	payroll.advance(_at(MON, "18:00"))
	payroll.advance(_at(TUE, "08:00"))
	payroll.schedule.end_minute = 12 * 60
	payroll.advance(_at(TUE, "18:00"))
	payroll.advance(_at(WED, "08:00"))
	check_eq(payroll.ledger[MON]["cents"], FULL_DAY, "lundi inchangé")
	check_eq(payroll.ledger[TUE]["worked_seconds"], 3 * 3600, "mardi : 3 h avec les nouveaux horaires")


func test_unpaid_day() -> void:
	var payroll := _payroll()
	payroll.advance(_at(MON, "18:00"))
	check(payroll.set_day_mark(TUE, Payroll.KIND_UNPAID), "marque acceptée")
	check_eq(payroll.advance(_at(WED, "08:00")), 0, "mardi sans solde")
	check_eq(payroll.ledger[TUE]["kind"], Payroll.KIND_UNPAID, "nature du mardi")
	check_eq(payroll.ledger[TUE]["cents"], 0, "0 € le mardi")


func test_leave_and_holidays_are_paid() -> void:
	var payroll := _payroll()
	payroll.advance(_at(MON, "18:00"))
	check(payroll.set_day_mark(TUE, Payroll.KIND_LEAVE), "congé accepté")
	check(payroll.set_day_mark(WED, Payroll.KIND_HOLIDAY), "férié accepté")
	payroll.advance(_at("2026-10-08", "08:00"))
	check_eq(payroll.ledger[TUE]["kind"], Payroll.KIND_LEAVE, "mardi : congé")
	check_eq(payroll.ledger[TUE]["cents"], 9231, "le congé est payé")
	check_eq(payroll.ledger[WED]["kind"], Payroll.KIND_HOLIDAY, "mercredi : férié")
	check_eq(payroll.ledger[WED]["cents"], 9231, "le férié est payé")


func test_marks_are_refused_on_closed_days_and_nonsense() -> void:
	var payroll := _payroll()
	payroll.advance(_at(MON, "18:00"))
	payroll.advance(_at(TUE, "08:00"))
	check(not payroll.set_day_mark(MON, Payroll.KIND_UNPAID), "jour clos")
	check(not payroll.set_day_mark("2026-02-30", Payroll.KIND_LEAVE), "date inexistante")
	check(not payroll.set_day_mark(WED, "vacances"), "marque inconnue")
	check(payroll.set_day_mark(WED, Payroll.KIND_LEAVE), "marque posée")
	check(payroll.set_day_mark(WED, ""), "marque retirée")
	check(not payroll.day_marks.has(WED), "plus de marque")


func test_manual_clocking_counts_only_clocked_time() -> void:
	var payroll := _payroll()
	payroll.manual_clocking = true
	check_eq(payroll.advance(_at(MON, "12:00")), 0, "pas encore pointé")
	payroll.clock_in(_at(MON, "13:00"))
	check_eq(payroll.advance(_at(MON, "15:00")), 2637, "2 h pointées")
	payroll.clock_out(_at(MON, "15:00"))
	check_eq(payroll.advance(_at(MON, "16:00")), 0, "dépointé")
	check(not payroll.is_clocked_in(), "plus en pointage")


func test_forgotten_clock_out_stops_at_midnight() -> void:
	var payroll := _payroll()
	payroll.manual_clocking = true
	payroll.advance(_at(MON, "16:00"))
	payroll.clock_in(_at(MON, "16:00"))
	var earned := payroll.advance(_at(TUE, "08:00"))
	# 8 h comptées, de 16 h à minuit.
	check_eq(earned, 10549, "8 h")
	check_eq(payroll.ledger[MON]["worked_seconds"], 8 * 3600, "8 h au journal")
	check(not payroll.is_clocked_in(), "pointage arrêté à minuit")
	check_eq(payroll.earned_today(), 0, "rien le mardi sans pointer")


func test_manual_clocking_is_capped_per_day() -> void:
	var payroll := _payroll()
	payroll.manual_clocking = true
	payroll.advance(_at(MON, "00:00"))
	payroll.clock_in(_at(MON, "00:00"))
	payroll.advance(_at(TUE, "08:00"))
	check_eq(payroll.ledger[MON]["worked_seconds"], Payroll.MANUAL_DAY_CAP_SECONDS, "16 h au plus")


func test_switching_to_manual_clocking_keeps_the_time_already_counted() -> void:
	var payroll := _payroll()
	check_eq(payroll.advance(_at(MON, "11:00")), 2637, "2 h selon l'horaire")
	payroll.set_manual_clocking(true, _at(MON, "11:00"))
	check_eq(payroll.advance(_at(MON, "12:00")), 0, "pas pointé : rien ne tombe")
	payroll.clock_in(_at(MON, "12:00"))
	check_eq(payroll.advance(_at(MON, "13:00")), 1319, "1 h pointée en plus des 2 h déjà comptées")
	check_eq(payroll.earned_today(), 3956, "3 h en tout")


func test_switching_back_to_the_schedule_clocks_out() -> void:
	var payroll := _payroll()
	payroll.set_manual_clocking(true, _at(MON, "08:00"))
	payroll.advance(_at(MON, "08:00"))
	payroll.clock_in(_at(MON, "08:00"))
	payroll.advance(_at(MON, "10:00"))
	payroll.set_manual_clocking(false, _at(MON, "10:00"))
	check(not payroll.is_clocked_in(), "plus en pointage")
	check(not payroll.manual_clocking, "retour à l'horaire")
	# L'horaire ne compte qu'une heure à 10 h : les deux heures pointées ne sont pas reprises.
	check_eq(payroll.advance(_at(MON, "10:30")), 0, "rien n'est repris, rien n'est payé deux fois")
	check_eq(payroll.earned_today(), 2637, "les 2 h pointées restent acquises")


func test_working_now_follows_the_schedule() -> void:
	var payroll := _payroll()
	check(not payroll.is_working_at(_at(MON, "08:59")), "avant l'heure")
	check(payroll.is_working_at(_at(MON, "09:00")), "début de journée")
	check(not payroll.is_working_at(_at(MON, "12:30")), "pause déjeuner")
	check(payroll.is_working_at(_at(MON, "13:00")), "reprise")
	check(not payroll.is_working_at(_at(MON, "17:00")), "fin de journée")
	check(not payroll.is_working_at(_at(SAT, "10:00")), "samedi")
	payroll.set_day_mark(TUE, Payroll.KIND_UNPAID)
	check(not payroll.is_working_at(_at(TUE, "10:00")), "jour sans solde")
	payroll.set_day_mark(WED, Payroll.KIND_LEAVE)
	check(payroll.is_working_at(_at(WED, "10:00")), "un congé reste payé aux heures habituelles")


func test_working_now_follows_the_clocking_when_manual() -> void:
	var payroll := _payroll()
	payroll.manual_clocking = true
	payroll.advance(_at(MON, "10:00"))
	check(not payroll.is_working_at(_at(MON, "10:00")), "pas pointé")
	payroll.clock_in(_at(MON, "20:00"))
	check(payroll.is_working_at(_at(MON, "20:30")), "pointé, même hors horaire")
	payroll.clock_out(_at(MON, "21:00"))
	check(not payroll.is_working_at(_at(MON, "21:00")), "dépointé")


func test_nothing_breaks_without_working_days() -> void:
	var payroll := _payroll()
	payroll.schedule.working_days = []
	check_eq(payroll.advance(_at(MON, "12:00")), 0, "aucun jour travaillé")
	check_eq(payroll.advance(_at(WED, "12:00")), 0, "toujours rien")
	check(not payroll.is_configured(), "non réglé")


func test_round_trip_through_json() -> void:
	var payroll := _payroll()
	payroll.set_day_mark(WED, Payroll.KIND_LEAVE)
	payroll.advance(_at(MON, "15:00"))
	payroll.advance(_at(TUE, "11:00"))
	var text := JSON.stringify(payroll.to_dict())

	var restored := Payroll.new()
	restored.load_dict(JSON.parse_string(text))
	check_eq(JSON.stringify(restored.to_dict()), text, "même contenu après rechargement")
	check_eq(restored.advance(_at(FRI, "12:00")), payroll.advance(_at(FRI, "12:00")), "même suite")
	check_eq(typeof(restored.ledger[MON]["cents"]), TYPE_INT, "les centimes restent entiers")


func test_load_ignores_garbage() -> void:
	var payroll := Payroll.new()
	payroll.load_dict({
		"settings": {"net_monthly_cents": -5, "schedule": {"working_days": [1, 1, 9, "x"], "start_minute": 99999},
			"day_marks": {"2026-10-08": "vacances", "pas une date": Payroll.KIND_LEAVE}},
		"state": {"open_day": "hier", "open_day_credited": -3},
		"ledger": {"n'importe quoi": {"cents": 5}},
	})
	check_eq(payroll.net_monthly_cents, 0, "salaire négatif ramené à 0")
	check_eq(payroll.schedule.working_days, [1] as Array[int], "jours valides seulement")
	check_eq(payroll.schedule.start_minute, 1440, "heure bornée")
	check(payroll.day_marks.is_empty(), "marques invalides écartées")
	check_eq(payroll.open_day, "", "jour en cours invalide écarté")
	check_eq(payroll.open_day_credited, 0, "crédit négatif ramené à 0")
	check(payroll.ledger.is_empty(), "ligne invalide écartée")


func test_ledger_keeps_at_most_400_days() -> void:
	var payroll := _payroll()
	var day := "2025-01-06"
	for _i in 30:
		payroll.advance(GameCalendar.local_from_text(day) + 18 * 3600)
		day = GameCalendar.add_days(day, 20)
	check(payroll.ledger.size() <= Payroll.LEDGER_MAX_DAYS, "au plus 400 lignes (obtenu %d)" % payroll.ledger.size())
