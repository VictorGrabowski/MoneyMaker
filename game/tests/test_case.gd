## Base minimale d'une suite de tests. Chaque méthode `test_*` est exécutée par run_tests.gd.
extends RefCounted

var errors: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		errors.append("%s — attendu %s, obtenu %s" % [message, str(expected), str(actual)])
