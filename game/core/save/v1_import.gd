## Reprise des réglages de l'application Electron v1 (fichier config.json d'electron-store).
## La v1 enregistrait un taux horaire ; le jeu travaille avec le net mensuel.
extends RefCounted

const WorkSchedule := preload("res://core/time/work_schedule.gd")

## Nom du dossier de la v1 dans %APPDATA%.
const V1_FOLDER := "money-maker"
const V1_FILE := "config.json"


## Convertit le contenu de config.json en réglages de paie :
## { "net_monthly_cents": int, "schedule": { … } }. {} si le fichier est inexploitable.
static func settings_from_v1(config: Dictionary) -> Dictionary:
	var wage := float(config.get("wage", 0.0))
	if wage <= 0.0:
		return {}

	var schedule := WorkSchedule.new()
	var days: Array[int] = []
	var raw_days: Variant = config.get("workingDays", [1, 2, 3, 4, 5])
	if typeof(raw_days) != TYPE_ARRAY:
		return {}
	for value in raw_days:
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			continue
		var weekday := int(value)
		if weekday >= 0 and weekday <= 6 and not days.has(weekday):
			days.append(weekday)
	days.sort()
	schedule.working_days = days
	schedule.start_minute = roundi(float(config.get("workStartHour", 9)) * 60.0)
	schedule.end_minute = roundi(float(config.get("workEndHour", 17)) * 60.0)
	schedule.lunch_start_minute = roundi(float(config.get("lunchBreakStartHour", 12)) * 60.0)
	schedule.lunch_duration_minutes = roundi(float(config.get("lunchBreakDuration", 0)))

	var monthly_seconds := schedule.monthly_seconds()
	if monthly_seconds <= 0:
		return {}
	# net = taux horaire × heures mensuelles, arrondi au centime.
	var net_cents := roundi(wage * float(monthly_seconds) / 3600.0 * 100.0)
	if net_cents <= 0:
		return {}
	return {
		"net_monthly_cents": net_cents,
		"schedule": {
			"working_days": days,
			"start_minute": schedule.start_minute,
			"end_minute": schedule.end_minute,
			"lunch_start_minute": schedule.lunch_start_minute,
			"lunch_duration_minutes": schedule.lunch_duration_minutes,
		},
	}
