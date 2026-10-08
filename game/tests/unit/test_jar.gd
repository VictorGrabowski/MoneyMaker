extends "res://tests/test_case.gd"

const Denominations := preload("res://core/money/denominations.gd")
const JarComposition := preload("res://core/money/jar_composition.gd")
const Jar := preload("res://core/money/jar.gd")

const DAY := 9230
const WEEK := 46150
const MONTH := 200000


## Un bocal réglé pour 2 000 € net et 35 h par semaine.
func _jar(size: String = Jar.SIZE_POT) -> Jar:
	var jar := Jar.new()
	jar.size = size
	jar.day_pay_cents = DAY
	jar.week_pay_cents = WEEK
	jar.month_pay_cents = MONTH
	return jar


## Rejoue des opérations sur une composition, comme le fera la scène.
func _replay(before: Dictionary, ops: Array[Dictionary]) -> Dictionary:
	var comp := before.duplicate()
	for op in ops:
		var added: Array = []
		var removed: Array = []
		match op["op"]:
			Jar.OP_DROP:
				added = op["values"]
			Jar.OP_MERGE:
				removed = op["inputs"]
				added = [op["output"]]
			Jar.OP_SPLIT:
				removed = [op["input"]]
				added = op["outputs"]
		for value in removed:
			check(comp.get(value, 0) > 0, "l'opération retire une coupure de %d c présente" % value)
			comp[value] = comp.get(value, 0) - 1
			if comp[value] <= 0:
				comp.erase(value)
		for value in added:
			comp[value] = comp.get(value, 0) + 1
	return comp


func _kinds(jar: Jar, coins: bool) -> int:
	var number := 0
	for value in jar.composition:
		if Denominations.is_coin(value) == coins:
			number += jar.composition[value]
	return number


func test_capacity_follows_the_size() -> void:
	check_eq(_jar(Jar.SIZE_POT).capacity_cents(), DAY, "Pot : un jour")
	check_eq(_jar(Jar.SIZE_BOCAL).capacity_cents(), WEEK, "Bocal : une semaine")
	check_eq(_jar(Jar.SIZE_BONBONNE).capacity_cents(), MONTH, "Bonbonne : un mois")


func test_target_follows_the_level() -> void:
	var jar := _jar()
	check_eq(jar.target_count(), Jar.MIN_OBJECTS, "vide : le minimum")
	jar.set_cents(DAY / 2)
	check_eq(jar.target_count(), 45, "à moitié : 45 objets")
	jar.set_cents(DAY)
	check_eq(jar.target_count(), 90, "plein : 90 objets")
	jar.set_cents(DAY * 110 / 100)
	check_eq(jar.target_count(), 99, "110 % : 9 objets qui débordent")
	jar.set_cents(DAY * 3)
	check_eq(jar.target_count(), 90 + Jar.OVERFLOW_OBJECTS, "débordement plafonné")


func test_bigger_jars_hold_more_objects() -> void:
	var bocal := _jar(Jar.SIZE_BOCAL)
	bocal.set_cents(WEEK)
	check_eq(bocal.target_count(), 160, "Bocal plein")
	var bonbonne := _jar(Jar.SIZE_BONBONNE)
	bonbonne.set_cents(MONTH)
	check_eq(bonbonne.target_count(), 240, "Bonbonne pleine")


func test_adding_a_cent_drops_a_coin_and_keeps_the_value() -> void:
	var jar := _jar()
	var ops := jar.add_cents(1)
	check_eq(jar.cents(), 1, "un centime")
	check_eq(ops[0]["op"], Jar.OP_DROP, "une chute")
	check_eq(ops[0]["values"], [1] as Array[int], "une pièce de 1 c")
	check(jar.add_cents(0).is_empty(), "rien pour 0")
	check(jar.add_cents(-5).is_empty(), "rien pour un montant négatif")
	check_eq(jar.cents(), 1, "toujours un centime")


func test_a_day_cent_by_cent() -> void:
	var jar := _jar()
	var most_merges := 0
	var splits := 0
	for _cent in DAY:
		var before := jar.composition.duplicate()
		var ops := jar.add_cents(1)
		most_merges = maxi(most_merges, ops.size() - 1)
		for op in ops:
			if op["op"] == Jar.OP_SPLIT:
				splits += 1
		if _replay(before, ops) != jar.composition:
			check(false, "les opérations ne redonnent pas le contenu à %d c" % jar.cents())
			return
	check_eq(jar.cents(), DAY, "valeur de la journée")
	check(jar.object_count() <= jar.target_count(), "pas plus d'objets que la cible")
	check(jar.object_count() >= jar.target_count() - Jar.SLACK, "à 2 objets près de la cible")
	check_eq(most_merges, 1, "une seule fusion par centime au plus")
	check_eq(splits, 0, "aucune coupure cassée pendant que le bocal se remplit")


func test_a_full_pot_is_mostly_coins_with_a_few_bills() -> void:
	var jar := _jar()
	for _cent in DAY:
		jar.add_cents(1)
	var bills := _kinds(jar, false)
	check(jar.composition.size() >= 8, "au moins 8 sortes de coupures (obtenu %d)" % jar.composition.size())
	check(bills >= 1 and bills <= 8, "entre 1 et 8 billets (obtenu %d)" % bills)
	check(_kinds(jar, true) >= 75, "au moins 75 pièces")


func test_a_big_catch_up_is_described_by_its_operations() -> void:
	var jar := _jar()
	jar.add_cents(3956)
	var before := jar.composition.duplicate()
	var ops := jar.add_cents(3 * DAY)
	check_eq(jar.cents(), 3956 + 3 * DAY, "valeur")
	check_eq(_replay(before, ops), jar.composition, "les opérations redonnent le contenu")
	check(jar.object_count() <= jar.target_count(), "pas plus d'objets que la cible")
	check(jar.object_count() >= jar.target_count() - Jar.SLACK, "à 2 objets près de la cible")


## Fusionne à la main tout ce qui peut l'être par paires : 1 € + 1 € -> 2 €, 50 c + 50 c -> 1 €, etc.
func _fuse_pairs(jar: Jar) -> int:
	var fused := 0
	for value in [1, 5, 10, 50, 100]:
		while jar.composition.get(value, 0) >= 2:
			check(jar.exchange([value, value], [value * 2]), "fusion de deux coupures de %d c" % value)
			fused += 1
	return fused


func test_a_hand_merge_keeps_the_money() -> void:
	var jar := _jar()
	jar.set_cents(DAY / 2)
	var before := jar.object_count()
	var ones: int = jar.composition.get(100, 0)
	check(ones >= 2, "au moins deux pièces de 1 € dans un demi-pot (obtenu %d)" % ones)
	check(jar.exchange([100, 100], [200]), "deux pièces de 1 € en font une de 2 €")
	check_eq(jar.cents(), DAY / 2, "même valeur")
	check_eq(jar.object_count(), before - 1, "un objet de moins")
	check_eq(jar.composition.get(100, 0), ones - 2, "deux pièces de 1 € en moins")


func test_a_hand_merge_is_refused_when_it_does_not_add_up() -> void:
	var jar := _jar()
	jar.set_cents(DAY / 2)
	var before := jar.composition.duplicate()
	check(not jar.exchange([100, 100], [500]), "2 € ne font pas 5 €")
	check(not jar.exchange([100, 100], [199]), "199 c n'est pas une coupure")
	check(not jar.exchange([], []), "rien contre rien")
	check(not jar.exchange([1000000, 1000000], [1000000, 1000000]), "des coupures que le bocal n'a pas")
	var too_many: Array[int] = []
	for _i in int(jar.composition.get(100, 0)) + 1:
		too_many.append(100)
	check(not jar.exchange(too_many, too_many), "plus de pièces de 1 € qu'il n'y en a")
	check_eq(jar.composition, before, "un refus ne change rien")


func test_what_was_merged_by_hand_is_never_broken_by_the_next_cents() -> void:
	var jar := _jar()
	jar.set_cents(DAY / 2)
	var fused := _fuse_pairs(jar)
	check(fused >= 5, "plusieurs fusions à la main (obtenu %d)" % fused)
	check(jar.object_count() < jar.target_count() - Jar.SLACK, "le bocal compte moins d'objets que son niveau")
	var big := {}
	for value in jar.composition:
		if value >= 100:
			big[value] = jar.composition[value]
	# Autant de centimes que de fusions : chacun rend au bocal un des objets que la main lui a ôtés.
	var splits := 0
	var merges := 0
	for _cent in fused:
		for op in jar.add_cents(1):
			if op["op"] == Jar.OP_SPLIT:
				splits += 1
			elif op["op"] == Jar.OP_MERGE:
				merges += 1
	check_eq(splits, 0, "rien n'est cassé pour compenser")
	check_eq(merges, 0, "et rien ne fusionne tant que le compte n'y est pas")
	for value in big:
		check_eq(jar.composition.get(value, 0), big[value], "les coupures de %d c sont toujours là" % value)


func test_after_hand_merges_the_jar_fills_up_again_then_merges_as_before() -> void:
	var jar := _jar()
	jar.set_cents(DAY / 2)
	_fuse_pairs(jar)
	var merges := 0
	for _cent in DAY / 4:
		for op in jar.add_cents(1):
			if op["op"] == Jar.OP_MERGE:
				merges += 1
	check(merges > 0, "les fusions automatiques ont repris")
	check(jar.object_count() <= jar.target_count(), "pas plus d'objets que la cible")
	check(jar.object_count() >= jar.target_count() - Jar.SLACK, "le compte y est de nouveau")


func test_a_catch_up_only_breaks_what_just_fell() -> void:
	var jar := _jar()
	jar.set_cents(DAY / 2)
	_fuse_pairs(jar)
	var kept := {}
	for value in jar.composition:
		kept[value] = jar.composition[value]
	var before := jar.composition.duplicate()
	var ops := jar.add_cents(DAY)
	check_eq(_replay(before, ops), jar.composition, "les opérations redonnent le contenu")
	check_eq(jar.cents(), DAY / 2 + DAY, "valeur")
	# Ce qui était là avant le rattrapage y est encore, coupure par coupure.
	for value in kept:
		check(jar.composition.get(value, 0) >= kept[value], "aucune coupure de %d c d'avant n'a été cassée" % value)


func test_recomposing_matches_the_target() -> void:
	for size in Jar.SIZES:
		var jar := _jar(size)
		jar.set_cents(jar.capacity_cents())
		check_eq(jar.cents(), jar.capacity_cents(), "%s : valeur" % size)
		check_eq(jar.object_count(), jar.target_count(), "%s : nombre d'objets" % size)


func test_changing_size_keeps_the_money() -> void:
	var jar := _jar()
	jar.set_cents(DAY)
	jar.set_size(Jar.SIZE_BONBONNE)
	check_eq(jar.cents(), DAY, "même valeur")
	check_eq(jar.size, Jar.SIZE_BONBONNE, "nouvelle taille")
	check(jar.object_count() <= jar.target_count(), "moins d'objets dans un grand bocal presque vide")
	jar.set_size("baignoire")
	check_eq(jar.size, Jar.SIZE_BONBONNE, "taille inconnue ignorée")


func test_take_all_empties_the_jar() -> void:
	var jar := _jar()
	jar.set_cents(4321)
	check_eq(jar.take_all(), 4321, "tout est repris")
	check_eq(jar.cents(), 0, "bocal vide")
	check_eq(jar.take_all(), 0, "rien à reprendre")


func test_without_salary_the_jar_still_works() -> void:
	var jar := Jar.new()
	check_eq(jar.capacity_cents(), 0, "pas de capacité")
	check_eq(jar.fullness(), 0.0, "niveau nul")
	jar.add_cents(250)
	check_eq(jar.cents(), 250, "l'argent est gardé")
	check(jar.object_count() <= Jar.MIN_OBJECTS, "au plus le minimum d'objets")


func test_round_trip_through_json() -> void:
	var jar := _jar(Jar.SIZE_BOCAL)
	jar.set_cents(12345)
	var text := JSON.stringify(jar.to_dict())
	var restored := _jar()
	restored.load_dict(JSON.parse_string(text))
	check_eq(restored.size, Jar.SIZE_BOCAL, "taille")
	check_eq(restored.cents(), 12345, "valeur")
	check_eq(restored.composition, jar.composition, "mêmes objets")


func test_loading_an_amount_without_detail_recomposes() -> void:
	# Les sauvegardes de l'epic 0 ne gardaient que le montant.
	var jar := _jar()
	jar.load_dict({"size": "pot", "cents": 3956.0})
	check_eq(jar.cents(), 3956, "valeur")
	check_eq(jar.object_count(), jar.target_count(), "objets recomposés")


func test_loading_a_wrong_detail_trusts_the_amount() -> void:
	var jar := _jar()
	jar.load_dict({"size": "tonneau", "cents": 500, "composition": {"100": 9, "3": 4, "x": 1, "50": -2}})
	check_eq(jar.size, Jar.SIZE_POT, "taille inconnue ramenée au Pot")
	check_eq(jar.cents(), 500, "le montant fait foi")
	jar.load_dict({})
	check_eq(jar.cents(), 0, "sauvegarde vide : bocal vide")
