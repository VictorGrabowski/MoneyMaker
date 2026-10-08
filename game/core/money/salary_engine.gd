## Conversion du temps travaillé en centimes, sans dérive.
## Tout est entier : le reste de la division est reporté d'un jour sur l'autre (`carry`).
extends RefCounted

const WorkSchedule := preload("res://core/time/work_schedule.gd")


## Centimes gagnés pour `worked_seconds`, plus le reste à reporter.
## Renvoie { "cents": int, "carry": int }.
static func earned(worked_seconds: int, net_monthly_cents: int, monthly_seconds: int, carry: int = 0) -> Dictionary:
	if monthly_seconds <= 0 or net_monthly_cents <= 0:
		return {"cents": 0, "carry": 0}
	var numerator := worked_seconds * net_monthly_cents + carry
	return {
		"cents": numerator / monthly_seconds,
		"carry": numerator % monthly_seconds,
	}


## Centimes gagnés aujourd'hui à `second_of_day`.
static func earned_today(schedule: WorkSchedule, net_monthly_cents: int, weekday: int, second_of_day: int, carry: int = 0) -> int:
	var worked := schedule.worked_seconds_on(weekday, second_of_day)
	return earned(worked, net_monthly_cents, schedule.monthly_seconds(), carry)["cents"]


## Centimes par heure travaillée (arrondi, pour l'affichage uniquement).
static func hourly_cents(schedule: WorkSchedule, net_monthly_cents: int) -> int:
	var monthly := schedule.monthly_seconds()
	if monthly <= 0:
		return 0
	return roundi(float(net_monthly_cents) * 3600.0 / float(monthly))
