extends "res://tests/test_case.gd"

const GameState := preload("res://core/state/game_state.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const Migrations := preload("res://core/save/migrations.gd")


func _at(text: String) -> int:
	return GameCalendar.local_from_text(text)


func _configured() -> GameState:
	var state := GameState.new()
	state.payroll.net_monthly_cents = 200000
	return state


func test_earnings_go_into_the_jar() -> void:
	var state := _configured()
	check_eq(state.advance(_at("2026-10-05T12:00:00")), 3956, "gagné lundi midi")
	check_eq(state.jar_cents, 3956, "dans le bocal")
	state.advance(_at("2026-10-06T12:00:00"))
	check_eq(state.jar_cents, 9230 + 3956, "le bocal garde la veille")
	check_eq(state.payroll.earned_today(), 3956, "gagné aujourd'hui seulement")
	check_eq(state.first_day, "2026-10-05", "premier jour")


func test_save_and_reload_then_catch_up() -> void:
	# Fermé lundi à 15 h, rouvert jeudi à 10 h : rien ne manque, rien n'est payé deux fois.
	var state := _configured()
	state.advance(_at("2026-10-05T15:00:00"))
	var text := JSON.stringify(state.to_dict(_at("2026-10-05T15:00:00")))

	var reloaded := GameState.new()
	reloaded.load_dict(Migrations.migrate(JSON.parse_string(text)))
	check_eq(reloaded.jar_cents, state.jar_cents, "bocal rechargé")
	reloaded.advance(_at("2026-10-08T10:00:00"))

	var reference := _configured()
	reference.advance(_at("2026-10-08T10:00:00"))
	# La référence démarre jeudi : elle n'a que l'heure de jeudi. Le jeu rechargé a aussi
	# lundi, mardi et mercredi en entier.
	var three_days := 3 * 25200 * 200000 / 546000  # 27 692 c
	var thursday_hour := 3600 * 200000 / 546000  # 1 318 c
	check_eq(reference.jar_cents, thursday_hour, "référence : une heure jeudi")
	check(absi(reloaded.jar_cents - (three_days + thursday_hour)) <= 1, "trois jours et une heure (obtenu %d)" % reloaded.jar_cents)


func test_save_has_a_version_and_a_date() -> void:
	var state := _configured()
	var saved := state.to_dict(_at("2026-10-05T15:00:00"))
	check_eq(saved["version"], Migrations.CURRENT_VERSION, "version")
	check_eq(saved["saved_at"], _at("2026-10-05T15:00:00"), "instant de sauvegarde")
	check(Migrations.is_loadable(saved), "relisible")


func test_empty_save_gives_a_fresh_state() -> void:
	var state := GameState.new()
	state.load_dict({})
	check_eq(state.jar_cents, 0, "bocal vide")
	check(not state.payroll.is_configured(), "salaire non réglé")
	check_eq(state.advance(_at("2026-10-05T12:00:00")), 0, "rien ne tombe sans salaire")


func test_migrations_accept_only_known_versions() -> void:
	check(Migrations.is_loadable({"version": 1}), "version 1")
	check(Migrations.is_loadable({"version": 1.0}), "version lue d'un fichier JSON")
	check(not Migrations.is_loadable({"version": Migrations.CURRENT_VERSION + 1}), "version future")
	check(not Migrations.is_loadable({"version": 0}), "version 0")
	check(not Migrations.is_loadable({"version": "1"}), "version en texte")
	check(not Migrations.is_loadable({}), "sans version")


func test_migrate_keeps_the_original_untouched() -> void:
	var original := {"version": 1.0, "jar": {"cents": 12.0}}
	var migrated := Migrations.migrate(original)
	check_eq(migrated["version"], Migrations.CURRENT_VERSION, "version courante")
	migrated["jar"]["cents"] = 99
	check_eq(original["jar"]["cents"], 12.0, "l'original n'est pas modifié")
