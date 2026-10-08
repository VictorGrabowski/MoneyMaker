## La lumière du jour : où est le soleil, et quelle ambiance en découle.
## Cinq ambiances se fondent l'une dans l'autre : aube, jour, heure dorée, heure bleue, nuit.
extends RefCounted

const DAWN := "aube"
const DAY := "jour"
const GOLDEN := "heure_doree"
const BLUE := "heure_bleue"
const NIGHT := "nuit"
const AMBIENCES: Array[String] = [DAWN, DAY, GOLDEN, BLUE, NIGHT]

## Le matin, quand le soleil monte : [hauteur du soleil en degrés, ambiance].
const MORNING_KEYS: Array = [[-12.0, NIGHT], [-1.0, DAWN], [8.0, DAY]]
## Le soir, quand il descend.
const EVENING_KEYS: Array = [[-12.0, NIGHT], [-4.0, BLUE], [3.0, GOLDEN], [10.0, DAY]]

## Teinte de l'intérieur, par ambiance.
const ROOM_TINT: Dictionary = {
	DAWN: Color(0.80, 0.78, 0.88),
	DAY: Color(1.0, 1.0, 1.0),
	GOLDEN: Color(1.0, 0.87, 0.68),
	BLUE: Color(0.52, 0.56, 0.78),
	NIGHT: Color(0.32, 0.35, 0.54),
}
const SKY_TOP: Dictionary = {
	DAWN: Color(0.55, 0.62, 0.85),
	DAY: Color(0.50, 0.72, 0.95),
	GOLDEN: Color(0.58, 0.64, 0.88),
	BLUE: Color(0.16, 0.22, 0.45),
	NIGHT: Color(0.05, 0.07, 0.16),
}
const SKY_BOTTOM: Dictionary = {
	DAWN: Color(0.98, 0.78, 0.70),
	DAY: Color(0.82, 0.92, 1.0),
	GOLDEN: Color(1.0, 0.72, 0.42),
	BLUE: Color(0.42, 0.44, 0.68),
	NIGHT: Color(0.12, 0.14, 0.28),
}
## Teinte de ce qu'on voit dehors (jardin, rue).
const OUTSIDE_TINT: Dictionary = {
	DAWN: Color(0.86, 0.80, 0.88),
	DAY: Color(1.0, 1.0, 1.0),
	GOLDEN: Color(1.0, 0.84, 0.62),
	BLUE: Color(0.40, 0.46, 0.72),
	NIGHT: Color(0.16, 0.19, 0.34),
}
## Force des lampes, guirlandes et autres sources chaudes, de 0 à 1.
const LAMPS: Dictionary = {DAWN: 0.45, DAY: 0.0, GOLDEN: 0.25, BLUE: 0.85, NIGHT: 1.0}
## Force de la lumière du jour qui entre par la porte et la fenêtre, de 0 à 1.
const SUNLIGHT: Dictionary = {DAWN: 0.30, DAY: 0.65, GOLDEN: 1.0, BLUE: 0.10, NIGHT: 0.0}
const SUNLIGHT_COLOR: Dictionary = {
	DAWN: Color(1.0, 0.80, 0.74),
	DAY: Color(1.0, 0.97, 0.88),
	GOLDEN: Color(1.0, 0.76, 0.42),
	BLUE: Color(0.60, 0.66, 0.95),
	NIGHT: Color(0.40, 0.45, 0.75),
}


## Hauteur du soleil au-dessus de l'horizon, en degrés (négative la nuit), et s'il monte encore.
## `utc_unix` : heure universelle, pas l'heure locale. Longitude positive vers l'est.
## Formules simplifiées de la NOAA : précises à une fraction de degré, bien assez pour une ambiance.
static func sun(utc_unix: int, latitude: float, longitude: float) -> Dictionary:
	var date := Time.get_date_dict_from_unix_time(utc_unix)
	var year_start := Time.get_unix_time_from_datetime_dict({"year": date["year"], "month": 1, "day": 1})
	var day_of_year := (utc_unix - year_start) / 86400 + 1
	var hour := posmod(utc_unix, 86400) / 3600.0
	var gamma := TAU / 365.0 * (day_of_year - 1 + (hour - 12.0) / 24.0)
	# Équation du temps, en minutes, et déclinaison du soleil, en radians.
	var equation := 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma)
		- 0.014615 * cos(2.0 * gamma) - 0.040849 * sin(2.0 * gamma))
	var declination := (0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma)
		- 0.006758 * cos(2.0 * gamma) + 0.000907 * sin(2.0 * gamma)
		- 0.002697 * cos(3.0 * gamma) + 0.00148 * sin(3.0 * gamma))
	# Heure solaire vraie, en minutes depuis minuit.
	var solar_minutes := fposmod(hour * 60.0 + equation + 4.0 * longitude, 1440.0)
	var hour_angle := deg_to_rad(solar_minutes / 4.0 - 180.0)
	var lat := deg_to_rad(latitude)
	var cos_zenith := sin(lat) * sin(declination) + cos(lat) * cos(declination) * cos(hour_angle)
	return {
		"elevation": 90.0 - rad_to_deg(acos(clampf(cos_zenith, -1.0, 1.0))),
		"rising": solar_minutes < 720.0,
	}


## Part de chaque ambiance pour cette hauteur de soleil : { ambiance: poids }, la somme vaut 1.
static func weights(elevation: float, rising: bool) -> Dictionary:
	var keys := MORNING_KEYS if rising else EVENING_KEYS
	var result := {}
	for ambience in AMBIENCES:
		result[ambience] = 0.0
	if elevation <= keys[0][0]:
		result[keys[0][1]] = 1.0
		return result
	for i in range(1, keys.size()):
		if elevation <= keys[i][0]:
			var t := inverse_lerp(keys[i - 1][0], keys[i][0], elevation)
			result[keys[i - 1][1]] += 1.0 - t
			result[keys[i][1]] += t
			return result
	result[keys[-1][1]] = 1.0
	return result


## Mélange des couleurs d'une table (ROOM_TINT, SKY_TOP…) selon les poids des ambiances.
static func blend_color(ambience_weights: Dictionary, table: Dictionary) -> Color:
	var color := Color(0.0, 0.0, 0.0, 0.0)
	for ambience in ambience_weights:
		var weight: float = ambience_weights[ambience]
		var entry: Color = table[ambience]
		color += Color(entry.r * weight, entry.g * weight, entry.b * weight, entry.a * weight)
	return color


## Mélange des valeurs d'une table (LAMPS, SUNLIGHT) selon les poids des ambiances.
static func blend_value(ambience_weights: Dictionary, table: Dictionary) -> float:
	var value := 0.0
	for ambience in ambience_weights:
		value += float(table[ambience]) * float(ambience_weights[ambience])
	return value


## L'ambiance qui pèse le plus.
static func dominant(ambience_weights: Dictionary) -> String:
	var best := DAY
	var best_weight := -1.0
	for ambience in AMBIENCES:
		if ambience_weights.get(ambience, 0.0) > best_weight:
			best_weight = ambience_weights[ambience]
			best = ambience
	return best
