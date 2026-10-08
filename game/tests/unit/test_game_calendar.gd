extends "res://tests/test_case.gd"

const GameCalendar := preload("res://core/time/game_calendar.gd")


func test_date_and_second_of_day() -> void:
	var noon := GameCalendar.local_from_text("2026-10-08T12:30:15")
	check_eq(GameCalendar.date_of(noon), "2026-10-08", "date")
	check_eq(GameCalendar.second_of_day(noon), 12 * 3600 + 30 * 60 + 15, "seconde du jour")
	check_eq(GameCalendar.second_of_day(GameCalendar.local_from_text("2026-10-08")), 0, "minuit")


func test_weekday() -> void:
	# Le 8 octobre 2026 est un jeudi ; 0 = dimanche.
	check_eq(GameCalendar.weekday_of_date("2026-10-08"), 4, "jeudi")
	check_eq(GameCalendar.weekday_of_date("2026-10-11"), 0, "dimanche")
	check_eq(GameCalendar.weekday_of_date("2026-10-05"), 1, "lundi")


func test_next_date_crosses_months_and_years() -> void:
	check_eq(GameCalendar.next_date("2026-10-31"), "2026-11-01", "fin de mois")
	check_eq(GameCalendar.next_date("2026-12-31"), "2027-01-01", "fin d'année")
	check_eq(GameCalendar.next_date("2028-02-28"), "2028-02-29", "année bissextile")
	check_eq(GameCalendar.next_date("2027-02-28"), "2027-03-01", "année ordinaire")


func test_days_between_and_add_days() -> void:
	check_eq(GameCalendar.days_between("2026-10-05", "2026-10-19"), 14, "deux semaines")
	check_eq(GameCalendar.days_between("2026-10-19", "2026-10-05"), -14, "à rebours")
	check_eq(GameCalendar.add_days("2027-01-04", -31), "2026-12-04", "31 jours plus tôt")


func test_dates_compare_as_text() -> void:
	check("2026-10-08" > "2026-10-07", "lendemain")
	check("2027-01-01" > "2026-12-31", "nouvelle année")
	check(not ("2026-10-08" > "2026-10-08"), "même jour")


func test_game_day_starts_at_four() -> void:
	check_eq(GameCalendar.game_day_of(GameCalendar.local_from_text("2026-10-08T03:59:59")), "2026-10-07", "avant 4 h : la veille")
	check_eq(GameCalendar.game_day_of(GameCalendar.local_from_text("2026-10-08T04:00:00")), "2026-10-08", "à 4 h : le jour même")


func test_seasons() -> void:
	check_eq(GameCalendar.season_of(GameCalendar.local_from_text("2026-10-08")), GameCalendar.AUTUMN, "octobre")
	check_eq(GameCalendar.season_of(GameCalendar.local_from_text("2027-01-15")), GameCalendar.WINTER, "janvier")
	check_eq(GameCalendar.season_of(GameCalendar.local_from_text("2027-04-15")), GameCalendar.SPRING, "avril")
	check_eq(GameCalendar.season_of(GameCalendar.local_from_text("2027-07-15")), GameCalendar.SUMMER, "juillet")


func test_dates_in_words() -> void:
	check_eq(GameCalendar.long_date("2026-10-08"), "jeudi 8 octobre 2026", "date ordinaire")
	check_eq(GameCalendar.long_date("2026-11-01"), "dimanche 1er novembre 2026", "premier du mois")
	check_eq(GameCalendar.month_name(8), "août", "nom de mois")
	check_eq(GameCalendar.date_from(2026, 3, 7), "2026-03-07", "date fabriquée")
	check_eq(GameCalendar.year_of("2026-10-08"), 2026, "année")
	check_eq(GameCalendar.month_of("2026-10-08"), 10, "mois")
	check_eq(GameCalendar.day_of_month("2026-10-08"), 8, "jour du mois")


func test_first_weekday_of_month_starts_on_monday() -> void:
	# Octobre 2026 commence un jeudi, novembre un dimanche, juin un lundi.
	check_eq(GameCalendar.first_weekday_of_month(2026, 10), 3, "jeudi")
	check_eq(GameCalendar.first_weekday_of_month(2026, 11), 6, "dimanche")
	check_eq(GameCalendar.first_weekday_of_month(2026, 6), 0, "lundi")


func test_valid_dates() -> void:
	check(GameCalendar.is_valid_date("2026-10-08"), "date correcte")
	check(GameCalendar.is_valid_date("2028-02-29"), "29 février d'une année bissextile")
	check(not GameCalendar.is_valid_date("2027-02-29"), "29 février d'une année ordinaire")
	check(not GameCalendar.is_valid_date("2026-02-30"), "30 février")
	check(not GameCalendar.is_valid_date("2026-13-01"), "treizième mois")
	check(not GameCalendar.is_valid_date("2026-1-08"), "mois sur un chiffre")
	check(not GameCalendar.is_valid_date("aaaa-bb-cc"), "lettres")
	check(not GameCalendar.is_valid_date("demain"), "texte quelconque")
	check(not GameCalendar.is_valid_date(""), "vide")
