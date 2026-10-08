## L'heure du jeu : celle de l'horloge du PC, en secondes locales (voir game_calendar.gd).
## Seul endroit du jeu qui lit l'horloge système.
extends Node

const GameCalendar := preload("res://core/time/game_calendar.gd")

## Émis une fois par seconde d'horloge.
signal second_ticked(now_local: int)

## Décalage ajouté à l'heure réelle. Reste à 0 hors essais.
var offset_seconds := 0

var _last_second := -1


func now_local() -> int:
	return Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system()) + offset_seconds


## Fait comme s'il était `text` (« 2026-10-05T12:00:00 ») ; le temps continue ensuite de s'écouler.
## Réservé aux essais.
func pretend_it_is(text: String) -> void:
	offset_seconds = 0
	offset_seconds = GameCalendar.local_from_text(text) - now_local()


func _process(_delta: float) -> void:
	var now := now_local()
	if now != _last_second:
		_last_second = now
		second_ticked.emit(now)
