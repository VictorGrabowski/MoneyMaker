## La météo du jeu : cinq états, traduits depuis les codes météo internationaux (OMM)
## que renvoie le service Open-Meteo.
extends RefCounted

const CLEAR := "clair"
const CLOUDY := "nuageux"
const RAIN := "pluie"
const SNOW := "neige"
const FOG := "brouillard"
const STATES: Array[String] = [CLEAR, CLOUDY, RAIN, SNOW, FOG]

## La météo vient du ciel réel, ou d'un choix de la joueuse.
const MODE_REAL := "reelle"
const MODE_MANUAL := "manuelle"
const MODES: Array[String] = [MODE_REAL, MODE_MANUAL]

## Part de lumière du jour qui passe, par état.
const DAYLIGHT: Dictionary = {CLEAR: 1.0, CLOUDY: 0.60, RAIN: 0.45, SNOW: 0.70, FOG: 0.55}
## Part de gris ajoutée au ciel, par état.
const GREYNESS: Dictionary = {CLEAR: 0.0, CLOUDY: 0.55, RAIN: 0.75, SNOW: 0.65, FOG: 0.80}

const LABELS: Dictionary = {
	CLEAR: "Ciel clair", CLOUDY: "Nuageux", RAIN: "Pluie", SNOW: "Neige", FOG: "Brouillard",
}


static func is_state(value: String) -> bool:
	return STATES.has(value)


## État du jeu pour un code météo OMM. Un code inconnu donne un ciel clair.
static func from_wmo_code(code: int) -> String:
	if code == 45 or code == 48:
		return FOG
	if (code >= 71 and code <= 77) or code == 85 or code == 86:
		return SNOW
	if (code >= 51 and code <= 67) or (code >= 80 and code <= 82) or (code >= 95 and code <= 99):
		return RAIN
	if code == 2 or code == 3:
		return CLOUDY
	return CLEAR
