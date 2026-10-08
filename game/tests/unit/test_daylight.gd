extends "res://tests/test_case.gd"

const Daylight := preload("res://core/world/daylight.gd")
const Weather := preload("res://core/world/weather.gd")

const PARIS_LATITUDE := 48.8566
const PARIS_LONGITUDE := 2.3522


func _utc(text: String) -> int:
	return Time.get_unix_time_from_datetime_string(text)


func _elevation(text: String, latitude: float = PARIS_LATITUDE, longitude: float = PARIS_LONGITUDE) -> float:
	return Daylight.sun(_utc(text), latitude, longitude)["elevation"]


func _near(value: float, expected: float, tolerance: float, message: String) -> void:
	check(absf(value - expected) <= tolerance, "%s — attendu %.1f ± %.1f, obtenu %.2f" % [message, expected, tolerance, value])


func test_sun_height_at_noon_in_paris() -> void:
	# À midi solaire : 90° − latitude ± 23,44° selon la saison.
	_near(_elevation("2026-06-21T11:52:00"), 64.6, 0.6, "solstice d'été")
	_near(_elevation("2026-12-21T11:49:00"), 17.7, 0.6, "solstice d'hiver")
	_near(_elevation("2026-03-20T11:58:00"), 41.2, 0.8, "équinoxe")


func test_sun_overhead_at_the_equator() -> void:
	check(_elevation("2026-03-20T12:07:00", 0.0, 0.0) > 88.0, "soleil au zénith à l'équateur, à l'équinoxe")


func test_sun_below_the_horizon_at_night() -> void:
	check(_elevation("2026-06-21T23:52:00") < -15.0, "minuit solaire en été")
	check(_elevation("2026-12-21T23:49:00") < -60.0, "minuit solaire en hiver")


func test_sunrise_and_sunset_in_paris() -> void:
	# 21 juin à Paris : lever à 5 h 47, coucher à 21 h 58, heure d'été (UTC + 2).
	var sunrise := Daylight.sun(_utc("2026-06-21T03:47:00"), PARIS_LATITUDE, PARIS_LONGITUDE)
	var sunset := Daylight.sun(_utc("2026-06-21T19:58:00"), PARIS_LATITUDE, PARIS_LONGITUDE)
	_near(sunrise["elevation"], -0.8, 1.5, "lever")
	_near(sunset["elevation"], -0.8, 1.5, "coucher")
	check(sunrise["rising"], "le matin, le soleil monte")
	check(not sunset["rising"], "le soir, il descend")


func test_longitude_shifts_the_solar_time() -> void:
	# À la même heure universelle, il fait jour à Paris et nuit à Tokyo.
	check(_elevation("2026-06-21T16:00:00") > 20.0, "après-midi à Paris")
	check(_elevation("2026-06-21T16:00:00", 35.68, 139.69) < -10.0, "nuit à Tokyo")


func test_weights_always_sum_to_one() -> void:
	for rising in [true, false]:
		for elevation in [-40.0, -12.0, -8.0, -4.0, -1.0, 0.0, 3.0, 5.5, 8.0, 10.0, 45.0]:
			var weights := Daylight.weights(elevation, rising)
			var sum := 0.0
			for ambience in weights:
				sum += weights[ambience]
				check(weights[ambience] >= 0.0, "poids positif")
			_near(sum, 1.0, 0.0001, "somme des poids à %.1f°" % elevation)


func test_each_ambience_has_its_moment() -> void:
	check_eq(Daylight.dominant(Daylight.weights(40.0, true)), Daylight.DAY, "plein jour le matin")
	check_eq(Daylight.dominant(Daylight.weights(40.0, false)), Daylight.DAY, "plein jour l'après-midi")
	check_eq(Daylight.dominant(Daylight.weights(-1.0, true)), Daylight.DAWN, "aube au lever")
	check_eq(Daylight.dominant(Daylight.weights(3.0, false)), Daylight.GOLDEN, "heure dorée avant le coucher")
	check_eq(Daylight.dominant(Daylight.weights(-4.0, false)), Daylight.BLUE, "heure bleue après le coucher")
	check_eq(Daylight.dominant(Daylight.weights(-30.0, true)), Daylight.NIGHT, "nuit avant l'aube")
	check_eq(Daylight.dominant(Daylight.weights(-30.0, false)), Daylight.NIGHT, "nuit le soir")


func test_ambiences_blend_smoothly() -> void:
	var halfway := Daylight.weights(6.5, false)
	_near(halfway[Daylight.DAY], 0.5, 0.001, "moitié jour")
	_near(halfway[Daylight.GOLDEN], 0.5, 0.001, "moitié heure dorée")
	var tint := Daylight.blend_color(halfway, Daylight.ROOM_TINT)
	_near(tint.b, (1.0 + 0.68) / 2.0, 0.001, "teinte intermédiaire")
	_near(Daylight.blend_value(halfway, Daylight.LAMPS), 0.125, 0.001, "lampes à peine allumées")


func test_lamps_are_off_by_day_and_on_at_night() -> void:
	_near(Daylight.blend_value(Daylight.weights(40.0, false), Daylight.LAMPS), 0.0, 0.001, "éteintes en plein jour")
	_near(Daylight.blend_value(Daylight.weights(-30.0, false), Daylight.LAMPS), 1.0, 0.001, "allumées la nuit")
	_near(Daylight.blend_value(Daylight.weights(-30.0, false), Daylight.SUNLIGHT), 0.0, 0.001, "pas de soleil la nuit")


func test_weather_codes() -> void:
	check_eq(Weather.from_wmo_code(0), Weather.CLEAR, "0 : ciel dégagé")
	check_eq(Weather.from_wmo_code(1), Weather.CLEAR, "1 : peu nuageux")
	check_eq(Weather.from_wmo_code(3), Weather.CLOUDY, "3 : couvert")
	check_eq(Weather.from_wmo_code(45), Weather.FOG, "45 : brouillard")
	check_eq(Weather.from_wmo_code(61), Weather.RAIN, "61 : pluie")
	check_eq(Weather.from_wmo_code(80), Weather.RAIN, "80 : averses")
	check_eq(Weather.from_wmo_code(95), Weather.RAIN, "95 : orage")
	check_eq(Weather.from_wmo_code(73), Weather.SNOW, "73 : neige")
	check_eq(Weather.from_wmo_code(86), Weather.SNOW, "86 : averses de neige")
	check_eq(Weather.from_wmo_code(1234), Weather.CLEAR, "code inconnu : ciel clair")


func test_every_weather_state_has_its_settings() -> void:
	for state in Weather.STATES:
		check(Weather.DAYLIGHT.has(state), "%s : lumière" % state)
		check(Weather.GREYNESS.has(state), "%s : gris" % state)
		check(Weather.LABELS.has(state), "%s : nom" % state)
		check(Weather.is_state(state), "%s est un état" % state)
	check(not Weather.is_state("canicule"), "état inconnu refusé")
