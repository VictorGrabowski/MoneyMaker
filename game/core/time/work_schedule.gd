## Horaires de travail de la joueuse. Minutes comptées depuis minuit.
extends RefCounted

## 0 = dimanche … 6 = samedi (convention de Time.get_datetime_dict_from_system).
var working_days: Array[int] = [1, 2, 3, 4, 5]
var start_minute: int = 9 * 60
var end_minute: int = 17 * 60
var lunch_start_minute: int = 12 * 60
var lunch_duration_minutes: int = 60


func is_working_day(weekday: int) -> bool:
	return working_days.has(weekday)


func effective_minutes_per_day() -> int:
	return worked_seconds_at(end_minute * 60) / 60


## Secondes travaillées dans un mois moyen : heures hebdomadaires × 52 ÷ 12.
## Toujours entier : jours × minutes × 60 × 52 ÷ 12 = jours × minutes × 260.
func monthly_seconds() -> int:
	return working_days.size() * effective_minutes_per_day() * 260


## Secondes travaillées entre le début de la journée et `second_of_day`, un jour travaillé.
func worked_seconds_at(second_of_day: int) -> int:
	var start := start_minute * 60
	var end := end_minute * 60
	if end <= start:
		return 0
	var now := clampi(second_of_day, start, end)
	var lunch_start := lunch_start_minute * 60
	var lunch_end := lunch_start + lunch_duration_minutes * 60
	var lunch_overlap := maxi(0, mini(now, lunch_end) - maxi(start, lunch_start))
	return maxi(0, now - start - lunch_overlap)


## Idem, en tenant compte du jour de la semaine.
func worked_seconds_on(weekday: int, second_of_day: int) -> int:
	if not is_working_day(weekday):
		return 0
	return worked_seconds_at(second_of_day)
