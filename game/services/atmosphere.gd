## Le ciel : la lumière selon l'heure et la position du soleil, la météo, la saison.
## Les lieux lisent ses valeurs et écoutent `changed`.
extends Node

const Daylight := preload("res://core/world/daylight.gd")
const Weather := preload("res://core/world/weather.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")

## La lumière, la météo ou la saison viennent de changer.
signal changed
## Résultat d'une recherche de ville : [{ "name", "region", "latitude", "longitude" }], vide si rien.
signal cities_found(results: Array[Dictionary])

## Sans ville, le soleil est celui du centre de la France.
const DEFAULT_LATITUDE := 46.6
const DEFAULT_LONGITUDE := 2.4
## La lumière change lentement : elle est recalculée toutes les 20 s.
const LIGHT_PERIOD_SECONDS := 20
const WEATHER_PERIOD_SECONDS := 1800
const REQUEST_TIMEOUT_SECONDS := 5.0
const FORECAST_URL := "https://api.open-meteo.com/v1/forecast?latitude=%.1f&longitude=%.1f&current=weather_code"
const SEARCH_URL := "https://geocoding-api.open-meteo.com/v1/search?name=%s&count=5&language=fr"

## Part de chaque ambiance (voir Daylight) et ambiance dominante.
var weights: Dictionary = Daylight.weights(40.0, false)
var ambience := Daylight.DAY
var sun_elevation := 40.0
var weather := Weather.CLEAR
var season := GameCalendar.AUTUMN

var room_tint := Color.WHITE
var outside_tint := Color.WHITE
var sky_top := Color(0.50, 0.72, 0.95)
var sky_bottom := Color(0.82, 0.92, 1.0)
## Force des lampes et guirlandes, de 0 à 1.
var lamps := 0.0
## Lumière du jour qui entre par la porte et la fenêtre : force de 0 à 1, et couleur.
var sunlight := 0.65
var sunlight_color := Color(1.0, 0.97, 0.88)

## Pour les essais : imposent une météo ou une saison ("" : ne rien imposer).
var forced_weather := ""
var forced_season := ""

var _started := false
var _next_light_at := 0
var _forecast_request: HTTPRequest
var _search_request: HTTPRequest
var _forecast_pending := false
## Heure du dernier essai de relevé, réussi ou non : pas de nouvel essai avant une demi-heure.
var _last_attempt_at := 0


## À appeler une fois l'état du jeu chargé.
func start() -> void:
	if _started:
		return
	_started = true
	_forecast_request = _new_request(_on_forecast_received)
	_search_request = _new_request(_on_search_received)
	Clock.second_ticked.connect(_on_second)
	Events.world_changed.connect(refresh)
	refresh()
	_on_second(Clock.now_local())


## Recalcule tout de suite la lumière, la météo et la saison.
func refresh() -> void:
	var now := Clock.now_local()
	_next_light_at = now + LIGHT_PERIOD_SECONDS

	var latitude := DEFAULT_LATITUDE
	var longitude := DEFAULT_LONGITUDE
	if Game.is_booted() and Game.state.has_city:
		latitude = Game.state.latitude
		longitude = Game.state.longitude
	var sun := Daylight.sun(now - _utc_offset_seconds(), latitude, longitude)
	sun_elevation = sun["elevation"]
	weights = Daylight.weights(sun_elevation, sun["rising"])
	ambience = Daylight.dominant(weights)

	weather = forced_weather if Weather.is_state(forced_weather) else (Game.state.shown_weather() if Game.is_booted() else Weather.CLEAR)
	season = forced_season if forced_season != "" else GameCalendar.season_of(now)

	var grey: float = Weather.GREYNESS[weather]
	var daylight: float = Weather.DAYLIGHT[weather]
	sky_top = _greyed(Daylight.blend_color(weights, Daylight.SKY_TOP), grey)
	sky_bottom = _greyed(Daylight.blend_color(weights, Daylight.SKY_BOTTOM), grey)
	outside_tint = _greyed(Daylight.blend_color(weights, Daylight.OUTSIDE_TINT), grey * 0.6) * Color(daylight, daylight, daylight).lerp(Color.WHITE, 0.4)
	lamps = Daylight.blend_value(weights, Daylight.LAMPS)
	sunlight = Daylight.blend_value(weights, Daylight.SUNLIGHT) * daylight
	sunlight_color = _greyed(Daylight.blend_color(weights, Daylight.SUNLIGHT_COLOR), grey * 0.7)
	# Par temps couvert, l'intérieur est un peu plus sombre le jour ; la nuit, rien ne change.
	var day_share: float = weights[Daylight.DAY] + weights[Daylight.GOLDEN] + weights[Daylight.DAWN]
	var dimming := lerpf(1.0, 0.86, grey * day_share)
	room_tint = Daylight.blend_color(weights, Daylight.ROOM_TINT) * Color(dimming, dimming, dimming)
	changed.emit()


## Cherche une ville par son nom. La réponse arrive par `cities_found`.
func search_city(city_name: String) -> void:
	var wanted := city_name.strip_edges()
	if wanted.length() < 2 or not _started:
		cities_found.emit([] as Array[Dictionary])
		return
	_search_request.cancel_request()
	if _search_request.request(SEARCH_URL % wanted.uri_encode()) != OK:
		cities_found.emit([] as Array[Dictionary])


func _on_second(now_local: int) -> void:
	if now_local >= _next_light_at:
		refresh()
	_fetch_weather_if_due(now_local)


## Relève la météo réelle : seulement si une ville est réglée, en mode réel, et pas plus d'une fois
## par demi-heure. Un échec garde la dernière météo connue, sans rien afficher.
func _fetch_weather_if_due(now_local: int) -> void:
	if _forecast_pending or not Game.is_booted():
		return
	var state := Game.state
	if not state.has_city or state.weather_mode != Weather.MODE_REAL:
		return
	var last := maxi(state.last_weather_at, _last_attempt_at)
	if last > 0 and now_local - last < WEATHER_PERIOD_SECONDS and now_local >= last:
		return
	_last_attempt_at = now_local
	_forecast_pending = _forecast_request.request(FORECAST_URL % [state.latitude, state.longitude]) == OK


func _on_forecast_received(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_forecast_pending = false
	var data := _json(result, response_code, body)
	var current: Variant = data.get("current")
	if typeof(current) != TYPE_DICTIONARY or not current.has("weather_code"):
		return
	Game.remember_weather(Weather.from_wmo_code(int(current["weather_code"])))


func _on_search_received(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var found: Array[Dictionary] = []
	var results: Variant = _json(result, response_code, body).get("results")
	if typeof(results) == TYPE_ARRAY:
		for entry in results:
			if typeof(entry) != TYPE_DICTIONARY or not entry.has("latitude") or not entry.has("longitude"):
				continue
			var parts: Array[String] = []
			for key in ["admin1", "country"]:
				if str(entry.get(key, "")) != "":
					parts.append(str(entry[key]))
			found.append({
				"name": str(entry.get("name", "")),
				"region": ", ".join(parts),
				"latitude": float(entry["latitude"]),
				"longitude": float(entry["longitude"]),
			})
	cities_found.emit(found)


func _new_request(on_completed: Callable) -> HTTPRequest:
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.request_completed.connect(on_completed)
	add_child(request)
	return request


## Le contenu d'une réponse, ou {} si la requête a échoué ou si la réponse n'est pas lisible.
func _json(result: int, response_code: int, body: PackedByteArray) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return {}
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data


## Écart entre l'heure du PC et l'heure universelle, en secondes (7200 en France l'été).
func _utc_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system()["bias"]) * 60


func _greyed(color: Color, amount: float) -> Color:
	var luminance := color.get_luminance()
	return color.lerp(Color(luminance, luminance, luminance * 1.04, color.a), clampf(amount, 0.0, 1.0))
