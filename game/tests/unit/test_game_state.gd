extends "res://tests/test_case.gd"

const GameState := preload("res://core/state/game_state.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const Jar := preload("res://core/money/jar.gd")
const Weather := preload("res://core/world/weather.gd")
const Migrations := preload("res://core/save/migrations.gd")


func _at(text: String) -> int:
	return GameCalendar.local_from_text(text)


func _configured() -> GameState:
	var state := GameState.new()
	state.payroll.net_monthly_cents = 200000
	return state


func _reload(state: GameState, now_text: String) -> GameState:
	var text := JSON.stringify(state.to_dict(_at(now_text)))
	var reloaded := GameState.new()
	reloaded.load_dict(Migrations.migrate(JSON.parse_string(text)))
	return reloaded


func test_earnings_go_into_the_jar() -> void:
	var state := _configured()
	check_eq(state.advance(_at("2026-10-05T12:00:00")), 3956, "gagné lundi midi")
	check_eq(state.jar.cents(), 3956, "dans le bocal")
	state.advance(_at("2026-10-06T12:00:00"))
	check_eq(state.jar.cents(), 9230 + 3956, "le bocal garde la veille")
	check_eq(state.payroll.earned_today(), 3956, "gagné aujourd'hui seulement")
	check_eq(state.first_day, "2026-10-05", "premier jour")


func test_jar_capacity_follows_the_salary() -> void:
	var state := _configured()
	state.advance(_at("2026-10-05T12:00:00"))
	check_eq(state.jar.day_pay_cents, 9230, "un jour")
	check_eq(state.jar.week_pay_cents, 46150, "une semaine")
	check_eq(state.jar.month_pay_cents, 200000, "un mois")
	check_eq(state.jar.target_count(), 39, "39 objets pour 43 % d'une journée")
	check(state.jar.object_count() >= 37 and state.jar.object_count() <= 39, "objets à la cible")


func test_each_second_reports_what_the_jar_did() -> void:
	var state := _configured()
	state.advance(_at("2026-10-05T10:00:00"))
	state.advance(_at("2026-10-05T10:00:10"))
	check(not state.last_jar_ops.is_empty(), "des opérations après 10 s de travail")
	check_eq(state.last_jar_ops[0]["op"], Jar.OP_DROP, "d'abord une chute")
	state.advance(_at("2026-10-05T10:00:10"))
	check(state.last_jar_ops.is_empty(), "rien quand rien n'est gagné")


func test_raising_the_salary_rebalances_the_jar() -> void:
	var state := _configured()
	state.advance(_at("2026-10-05T17:00:00"))
	check_eq(state.jar.target_count(), 90, "Pot plein")
	state.payroll.net_monthly_cents = 400000
	var ops := state.rebalance_jar()
	check_eq(state.jar.cents(), 9230, "l'argent ne change pas")
	check_eq(state.jar.target_count(), 45, "le même montant ne remplit plus que la moitié")
	check(not ops.is_empty(), "des fusions à jouer")
	check(state.jar.object_count() <= 45, "objets ramenés à la cible")


func test_hand_merges_survive_a_reload_and_the_next_cents() -> void:
	var state := _configured()
	state.advance(_at("2026-10-05T12:00:00"))
	var ones: int = state.jar.composition.get(100, 0)
	check(ones >= 2, "au moins deux pièces de 1 € à midi (obtenu %d)" % ones)
	check(state.jar.exchange([100, 100], [200]), "fusion à la main")
	var twos: int = state.jar.composition.get(200, 0)

	var reloaded := _reload(state, "2026-10-05T12:00:00")
	check_eq(reloaded.jar.composition, state.jar.composition, "le bocal est retrouvé tel que la main l'a laissé")
	# Dix secondes de salaire plus tard, rien n'a été cassé pour compenser.
	reloaded.advance(_at("2026-10-05T13:00:10"))
	for op in reloaded.last_jar_ops:
		check(op["op"] != Jar.OP_SPLIT, "aucune coupure cassée après le rechargement")
	check(reloaded.jar.composition.get(200, 0) >= twos, "la pièce de 2 € faite à la main est toujours là")


func test_save_and_reload_then_catch_up() -> void:
	# Fermé lundi à 15 h, rouvert jeudi à 10 h : rien ne manque, rien n'est payé deux fois.
	var state := _configured()
	state.advance(_at("2026-10-05T15:00:00"))
	var reloaded := _reload(state, "2026-10-05T15:00:00")
	check_eq(reloaded.jar.cents(), state.jar.cents(), "bocal rechargé")
	check_eq(reloaded.jar.composition, state.jar.composition, "mêmes objets dans le bocal")
	reloaded.advance(_at("2026-10-08T10:00:00"))

	var reference := _configured()
	reference.advance(_at("2026-10-08T10:00:00"))
	# La référence démarre jeudi : elle n'a que l'heure de jeudi. Le jeu rechargé a aussi
	# lundi, mardi et mercredi en entier.
	var three_days := 3 * 25200 * 200000 / 546000  # 27 692 c
	var thursday_hour := 3600 * 200000 / 546000  # 1 318 c
	check_eq(reference.jar.cents(), thursday_hour, "référence : une heure jeudi")
	check(absi(reloaded.jar.cents() - (three_days + thursday_hour)) <= 1,
		"trois jours et une heure (obtenu %d)" % reloaded.jar.cents())
	check_eq(reloaded.jar.target_count(), 90 + Jar.OVERFLOW_OBJECTS, "le Pot déborde")


func test_save_has_a_version_and_a_date() -> void:
	var state := _configured()
	var saved := state.to_dict(_at("2026-10-05T15:00:00"))
	check_eq(saved["version"], Migrations.CURRENT_VERSION, "version")
	check_eq(saved["saved_at"], _at("2026-10-05T15:00:00"), "instant de sauvegarde")
	check(Migrations.is_loadable(saved), "relisible")


func test_empty_save_gives_a_fresh_state() -> void:
	var state := GameState.new()
	state.load_dict({})
	check_eq(state.jar.cents(), 0, "bocal vide")
	check(not state.payroll.is_configured(), "salaire non réglé")
	check_eq(state.advance(_at("2026-10-05T12:00:00")), 0, "rien ne tombe sans salaire")
	check_eq(state.widget_format, GameState.WIDGET_BANDEAU, "widget en bandeau")
	check(not state.has_widget_position, "pas de position de widget")
	check(not state.discreet, "mode discret éteint")


func test_an_epic_0_save_still_loads() -> void:
	# Avant l'epic 1, la sauvegarde ne gardait que le montant du bocal et aucune préférence.
	var state := GameState.new()
	state.load_dict({
		"version": 1,
		"settings": {"net_monthly_cents": 200000.0},
		"jar": {"size": "pot", "cents": 3956.0},
	})
	check_eq(state.jar.cents(), 3956, "montant repris")
	check_eq(state.jar.object_count(), state.jar.target_count(), "bocal recomposé")


func test_preferences_survive_a_reload() -> void:
	var state := _configured()
	state.set_widget_format(GameState.WIDGET_MINI_BOCAL)
	state.set_widget_opacity(0.75)
	state.set_widget_position(Vector2i(3096, -40))
	state.discreet = true
	state.sound_enabled = false
	var reloaded := _reload(state, "2026-10-05T15:00:00")
	check_eq(reloaded.widget_format, GameState.WIDGET_MINI_BOCAL, "format")
	check_eq(reloaded.widget_opacity, 0.75, "opacité")
	check(reloaded.has_widget_position, "position connue")
	check_eq(reloaded.widget_position, Vector2i(3096, -40), "position")
	check(reloaded.discreet, "mode discret")
	check(not reloaded.sound_enabled, "son coupé")


func test_preferences_refuse_nonsense() -> void:
	var state := GameState.new()
	state.set_widget_format("affiche")
	check_eq(state.widget_format, GameState.WIDGET_BANDEAU, "format inconnu ignoré")
	state.set_widget_opacity(0.1)
	check_eq(state.widget_opacity, GameState.WIDGET_MIN_OPACITY, "opacité bornée")
	state.load_dict({"preferences": {"widget": {"format": 7, "opacity": "x", "position": [1]}, "discreet": 1}})
	check_eq(state.widget_format, GameState.WIDGET_BANDEAU, "format illisible ignoré")
	check(not state.has_widget_position, "position illisible ignorée")


func test_city_is_rounded_and_survives_a_reload() -> void:
	var state := _configured()
	state.set_city("  Lyon ", 45.7640, 4.8357)
	check(state.has_city, "ville connue")
	check_eq(state.city_name, "Lyon", "nom sans espaces autour")
	check_eq(state.latitude, 45.8, "latitude au dixième")
	check_eq(state.longitude, 4.8, "longitude au dixième")
	var reloaded := _reload(state, "2026-10-05T15:00:00")
	check_eq(reloaded.city_name, "Lyon", "nom rechargé")
	check_eq(reloaded.latitude, 45.8, "latitude rechargée")
	state.clear_city()
	check(not state.has_city, "ville oubliée")
	check(not _reload(state, "2026-10-05T15:00:00").has_city, "toujours oubliée après rechargement")
	state.set_city("", 10.0, 10.0)
	check(not state.has_city, "une ville sans nom n'est pas retenue")


func test_shown_weather_follows_the_mode() -> void:
	var state := _configured()
	check_eq(state.shown_weather(), Weather.CLEAR, "ciel clair tant que rien n'est connu")
	state.remember_weather(Weather.RAIN, _at("2026-10-05T15:00:00"))
	check_eq(state.shown_weather(), Weather.RAIN, "dernière météo réelle")
	state.set_manual_weather(Weather.SNOW)
	check_eq(state.shown_weather(), Weather.RAIN, "le choix manuel attend le mode manuel")
	state.set_weather_mode(Weather.MODE_MANUAL)
	check_eq(state.shown_weather(), Weather.SNOW, "choix manuel")
	state.set_manual_weather("canicule")
	state.set_weather_mode("au hasard")
	check_eq(state.shown_weather(), Weather.SNOW, "valeurs inconnues ignorées")
	var reloaded := _reload(state, "2026-10-05T15:00:00")
	check_eq(reloaded.weather_mode, Weather.MODE_MANUAL, "mode rechargé")
	check_eq(reloaded.shown_weather(), Weather.SNOW, "météo rechargée")
	check_eq(reloaded.last_weather, Weather.RAIN, "dernière météo réelle rechargée")


func test_changing_city_forgets_the_known_weather() -> void:
	var state := _configured()
	state.set_city("Lyon", 45.8, 4.8)
	state.remember_weather(Weather.FOG, _at("2026-10-05T15:00:00"))
	state.set_city("Brest", 48.4, -4.5)
	check_eq(state.last_weather_at, 0, "la météo de Lyon ne vaut pas pour Brest")
	check_eq(state.shown_weather(), Weather.CLEAR, "ciel clair en attendant")


func test_evening_ticket() -> void:
	var state := _configured()
	state.advance(_at("2026-10-05T15:00:00"))
	check(state.evening_ticket(_at("2026-10-05T15:00:00")).is_empty(), "pas de ticket avant la fin de la première journée")
	state.advance(_at("2026-10-05T17:30:00"))
	var ticket := state.evening_ticket(_at("2026-10-05T17:30:00"))
	check_eq(ticket.get("day"), "2026-10-05", "ticket du jour après 17 h")
	check_eq(ticket.get("cents"), 9230, "montant du jour")
	check_eq(ticket.get("worked_seconds"), 25200, "7 h travaillées")
	# Le lendemain en fin de matinée : le ticket montré est encore celui de la veille.
	state.advance(_at("2026-10-06T11:00:00"))
	check_eq(state.evening_ticket(_at("2026-10-06T11:00:00")).get("day"), "2026-10-05", "ticket de la veille")
	# Le week-end ne produit pas de ticket : on garde celui du vendredi.
	state.advance(_at("2026-10-11T12:00:00"))
	check_eq(state.evening_ticket(_at("2026-10-11T12:00:00")).get("day"), "2026-10-09", "ticket du vendredi, le dimanche")


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
