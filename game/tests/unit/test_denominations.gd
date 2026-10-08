extends "res://tests/test_case.gd"

const Denominations := preload("res://core/money/denominations.gd")


func _sum(values: Array) -> int:
	var total := 0
	for value in values:
		total += value
	return total


func test_every_break_keeps_the_value() -> void:
	for output in Denominations.BREAKS:
		check_eq(_sum(Denominations.BREAKS[output]), output, "la coupure de %d c vaut ses morceaux" % output)


func test_two_alike_merge_into_the_next_one() -> void:
	var jar := {100: 2}
	var merge := Denominations.hand_merge(100, 100, jar)
	check_eq(merge.get("inputs"), [100, 100] as Array[int], "deux pièces de 1 €")
	check_eq(merge.get("outputs"), [200] as Array[int], "une pièce de 2 €")
	check_eq(Denominations.hand_merge(500, 500, {500: 2}).get("outputs"), [1000] as Array[int], "deux billets de 5 € : un de 10 €")


func test_a_three_way_merge_fetches_its_third_piece_in_the_jar() -> void:
	# 2 € + 2 € + 1 € = 5 € : la pièce de 1 € n'a pas besoin d'être touchée.
	var merge := Denominations.hand_merge(200, 200, {200: 2, 100: 1})
	check_eq(merge.get("inputs"), [200, 200, 100] as Array[int], "deux pièces de 2 € et une de 1 €")
	check_eq(merge.get("outputs"), [500] as Array[int], "un billet de 5 €")
	# La petite posée sur la grande marche aussi.
	merge = Denominations.hand_merge(100, 200, {200: 2, 100: 1})
	check_eq(merge.get("outputs"), [500] as Array[int], "1 € posé sur 2 €, avec une autre de 2 € dans le bocal")
	check(Denominations.hand_merge(100, 200, {200: 1, 100: 1}).is_empty(), "sans la seconde pièce de 2 €, rien")


func test_three_alike_give_change() -> void:
	# Pas de pièce de 1 c pour compléter : 3 × 2 c -> 5 c + 1 c, comme dans la v1.
	var merge := Denominations.hand_merge(2, 2, {2: 3})
	check_eq(merge.get("inputs"), [2, 2, 2] as Array[int], "trois pièces de 2 c")
	check_eq(merge.get("outputs"), [5, 1] as Array[int], "5 c et 1 c")
	check_eq(_sum(merge["inputs"]), _sum(merge["outputs"]), "même valeur")
	# Avec la petite qui complète, c'est la fusion ordinaire qui passe.
	check_eq(Denominations.hand_merge(2, 2, {2: 3, 1: 1}).get("outputs"), [5] as Array[int], "2 c + 2 c + 1 c = 5 c")
	check(Denominations.hand_merge(2, 2, {2: 2}).is_empty(), "deux pièces de 2 c seules ne fusionnent pas")


func test_pieces_that_do_not_go_together_do_not_merge() -> void:
	var full := {}
	for value in Denominations.VALUES:
		full[value] = 20
	check(Denominations.hand_merge(1, 5, full).is_empty(), "1 c et 5 c")
	check(Denominations.hand_merge(100, 500, full).is_empty(), "1 € et 5 €")
	check(Denominations.hand_merge(1000000, 1000000, full).is_empty(), "rien au-dessus de la gemme")
	check(Denominations.hand_merge(100, 100, {100: 1}).is_empty(), "une seule pièce ne fusionne pas avec elle-même")
	check(Denominations.hand_merge(100, 100, {}).is_empty(), "bocal vide")


func test_ten_ingots_make_a_gem() -> void:
	var merge := Denominations.hand_merge(100000, 100000, {100000: 10})
	check_eq(merge.get("outputs"), [1000000] as Array[int], "une gemme")
	check_eq(merge.get("inputs", []).size(), 10, "dix lingots")
	check(Denominations.hand_merge(100000, 100000, {100000: 9}).is_empty(), "neuf lingots ne suffisent pas")


func test_every_hand_merge_keeps_the_value() -> void:
	var full := {}
	for value in Denominations.VALUES:
		full[value] = 20
	var found := 0
	for held in Denominations.VALUES:
		for touched in Denominations.VALUES:
			var merge := Denominations.hand_merge(held, touched, full)
			if merge.is_empty():
				continue
			found += 1
			check_eq(_sum(merge["inputs"]), _sum(merge["outputs"]), "%d c sur %d c : même valeur" % [held, touched])
			check(merge["inputs"].has(held) and merge["inputs"].has(touched), "%d c sur %d c : les deux en font partie" % [held, touched])
	check(found >= 20, "au moins vingt gestes de fusion possibles (obtenu %d)" % found)
