extends "res://tests/test_case.gd"

const V1Import := preload("res://core/save/v1_import.gd")
const Payroll := preload("res://core/money/payroll.gd")


## Réglages tels que la v1 les écrivait : 2 000 € net, 9 h – 17 h, une heure de déjeuner à midi.
func _v1_config() -> Dictionary:
	return {
		"wage": 2000.0 / (5.0 * 7.0 * 52.0 / 12.0),
		"lastSeen": 1768400000000,
		"workingDays": [1, 2, 3, 4, 5],
		"workStartHour": 9,
		"workEndHour": 17,
		"lunchBreakDuration": 60,
		"lunchBreakStartHour": 12,
		"windowBounds": {"main": {"x": 0, "y": 0}, "widget": {"x": 0, "y": 0}},
	}


func test_hourly_wage_becomes_monthly_net() -> void:
	var settings := V1Import.settings_from_v1(_v1_config())
	check_eq(settings["net_monthly_cents"], 200000, "2 000,00 € net")
	check_eq(settings["schedule"]["start_minute"], 540, "début à 9 h")
	check_eq(settings["schedule"]["end_minute"], 1020, "fin à 17 h")
	check_eq(settings["schedule"]["lunch_start_minute"], 720, "déjeuner à midi")
	check_eq(settings["schedule"]["lunch_duration_minutes"], 60, "une heure")


func test_imported_settings_feed_the_payroll() -> void:
	var settings := V1Import.settings_from_v1(_v1_config())
	var payroll := Payroll.new()
	payroll.net_monthly_cents = settings["net_monthly_cents"]
	payroll.apply_schedule_dict(settings["schedule"])
	check(payroll.is_configured(), "paie réglée")
	check_eq(payroll.hourly_cents(), 1319, "13,19 € de l'heure")


func test_half_hours_and_text_from_json() -> void:
	var config := _v1_config()
	config["workStartHour"] = 8.5
	config["lunchBreakStartHour"] = 12.5
	var settings := V1Import.settings_from_v1(JSON.parse_string(JSON.stringify(config)))
	check_eq(settings["schedule"]["start_minute"], 510, "8 h 30")
	check_eq(settings["schedule"]["lunch_start_minute"], 750, "12 h 30")


func test_unusable_files_are_ignored() -> void:
	check(V1Import.settings_from_v1({}).is_empty(), "fichier vide")
	check(V1Import.settings_from_v1({"wage": 0}).is_empty(), "taux nul")
	check(V1Import.settings_from_v1({"wage": "beaucoup"}).is_empty(), "taux illisible")
	var no_days := _v1_config()
	no_days["workingDays"] = []
	check(V1Import.settings_from_v1(no_days).is_empty(), "aucun jour travaillé")
	var upside_down := _v1_config()
	upside_down["workEndHour"] = 8
	check(V1Import.settings_from_v1(upside_down).is_empty(), "fin avant le début")
