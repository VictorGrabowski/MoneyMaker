extends "res://tests/test_case.gd"

const Denominations := preload("res://core/money/denominations.gd")
const JarComposition := preload("res://core/money/jar_composition.gd")


func test_breaks_preserve_value() -> void:
	for value in Denominations.BREAKS:
		var sum := 0
		for part in Denominations.BREAKS[value]:
			sum += part
			check(part < value, "%d se casse en coupures plus petites" % value)
		check_eq(sum, value, "casse de %d" % value)


func test_every_denomination_but_the_cent_can_break() -> void:
	for value in Denominations.VALUES:
		if value == 1:
			continue
		check(Denominations.BREAKS.has(value), "%d a une règle de casse" % value)


func test_greedy_is_minimal_for_a_day() -> void:
	var comp := JarComposition.greedy(9231)
	check_eq(JarComposition.total(comp), 9231, "valeur")
	# 50 + 20 + 20 + 2 + 0,20 + 0,10 + 0,01
	check_eq(JarComposition.count(comp), 7, "nombre d'objets")


func test_compose_preserves_value_and_reaches_target() -> void:
	for total_cents in [1, 37, 923, 9231, 46155, 200000]:
		for target in [12, 90, 160, 240]:
			var comp := JarComposition.compose(total_cents, target)
			var n := JarComposition.count(comp)
			check_eq(JarComposition.total(comp), total_cents, "valeur pour %d c / %d objets" % [total_cents, target])
			check(n <= maxi(target, JarComposition.count(JarComposition.greedy(total_cents))),
				"pas plus de %d objets pour %d c (obtenu %d)" % [target, total_cents, n])
			if total_cents >= target:
				check(n >= target - 1, "au moins %d objets pour %d c (obtenu %d)" % [target - 1, total_cents, n])


func test_compose_keeps_variety() -> void:
	# Un Pot plein à 2 000 € net : 92,31 € en 90 objets, avec pièces ET billets.
	var comp := JarComposition.compose(9231, 90)
	var kinds := comp.size()
	check(kinds >= 8, "au moins 8 sortes de coupures (obtenu %d)" % kinds)
	var has_bill := false
	for value in comp:
		if Denominations.is_bill(value):
			has_bill = true
	check(has_bill, "au moins un billet")


func test_to_values_is_flat_and_complete() -> void:
	var comp := JarComposition.compose(9231, 90)
	var values := JarComposition.to_values(comp)
	check_eq(values.size(), JarComposition.count(comp), "taille de la liste")
	var sum := 0
	for value in values:
		sum += value
	check_eq(sum, 9231, "valeur de la liste")


func test_format_cents() -> void:
	check_eq(Denominations.format_cents(9231), "92,31 €", "92,31 €")
	check_eq(Denominations.format_cents(5), "0,05 €", "0,05 €")
	check_eq(Denominations.format_cents(123456789), "1 234 567,89 €", "milliers séparés")
