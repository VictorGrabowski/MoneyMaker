## Calendrier du jeu.
## Un instant est toujours un nombre de « secondes locales » : les secondes écoulées depuis le
## 1er janvier 1970 à l'heure qu'affiche l'horloge du PC (heure d'été comprise).
## Un jour est une chaîne « AAAA-MM-JJ » ; deux jours se comparent avec < et >.
extends RefCounted

const SECONDS_PER_DAY := 86400
## Un « jour de jeu » commence à 4 h : une soirée tardive compte pour la veille.
const GAME_DAY_STARTS_AT := 4 * 3600

const SPRING := "printemps"
const SUMMER := "ete"
const AUTUMN := "automne"
const WINTER := "hiver"


static func date_of(local: int) -> String:
	return Time.get_date_string_from_unix_time(local)


## « 2026-10-08 » -> minuit de ce jour. « 2026-10-08T12:30:00 » -> cet instant.
static func local_from_text(text: String) -> int:
	return Time.get_unix_time_from_datetime_string(text)


static func second_of_day(local: int) -> int:
	return posmod(local, SECONDS_PER_DAY)


## 0 = dimanche … 6 = samedi.
static func weekday_of(local: int) -> int:
	return Time.get_date_dict_from_unix_time(local)["weekday"]


static func weekday_of_date(day: String) -> int:
	return weekday_of(local_from_text(day))


static func add_days(day: String, count: int) -> String:
	return date_of(local_from_text(day) + count * SECONDS_PER_DAY)


static func next_date(day: String) -> String:
	return add_days(day, 1)


## Nombre de jours de `from_day` à `to_day` (négatif si `to_day` est avant).
static func days_between(from_day: String, to_day: String) -> int:
	return (local_from_text(to_day) - local_from_text(from_day)) / SECONDS_PER_DAY


static func game_day_of(local: int) -> String:
	return date_of(local - GAME_DAY_STARTS_AT)


## Saisons météorologiques de l'hémisphère nord.
static func season_of(local: int) -> String:
	var month: int = Time.get_date_dict_from_unix_time(local)["month"]
	if month >= 3 and month <= 5:
		return SPRING
	if month >= 6 and month <= 8:
		return SUMMER
	if month >= 9 and month <= 11:
		return AUTUMN
	return WINTER


## Vrai pour une date « AAAA-MM-JJ » qui existe.
## Vérifiée à la main : le moteur écrit une erreur quand on lui donne une date impossible.
static func is_valid_date(day: String) -> bool:
	if day.length() != 10:
		return false
	var parts := day.split("-")
	if parts.size() != 3 or parts[0].length() != 4 or parts[1].length() != 2:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
	var year := parts[0].to_int()
	var month := parts[1].to_int()
	var day_of_month := parts[2].to_int()
	if year < 1970 or month < 1 or month > 12 or day_of_month < 1:
		return false
	return day_of_month <= days_in_month(year, month)


static func days_in_month(year: int, month: int) -> int:
	if month == 2:
		var leap := (year % 4 == 0 and year % 100 != 0) or year % 400 == 0
		return 29 if leap else 28
	return 30 if month in [4, 6, 9, 11] else 31
