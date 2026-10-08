## Table des coupures. Toutes les valeurs sont en centimes entiers.
extends RefCounted

## Les 17 coupures, de la plus petite à la plus grande.
const VALUES: Array[int] = [
	1, 2, 5, 10, 20, 50, 100, 200,
	500, 1000, 2000, 5000, 10000, 20000, 50000,
	100000, 1000000,
]

## « Casse » d'une coupure en coupures plus petites de même valeur totale.
## Lue à l'envers, c'est la table de fusion.
const BREAKS: Dictionary = {
	2: [1, 1],
	5: [2, 2, 1],
	10: [5, 5],
	20: [10, 10],
	50: [20, 20, 10],
	100: [50, 50],
	200: [100, 100],
	500: [200, 200, 100],
	1000: [500, 500],
	2000: [1000, 1000],
	5000: [2000, 2000, 1000],
	10000: [5000, 5000],
	20000: [10000, 10000],
	50000: [20000, 20000, 10000],
	100000: [50000, 50000],
	1000000: [100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000],
}

const LARGEST_COIN := 200
const LARGEST_BILL := 50000


static func is_coin(value: int) -> bool:
	return value <= LARGEST_COIN


static func is_bill(value: int) -> bool:
	return value > LARGEST_COIN and value <= LARGEST_BILL


## « 1 c », « 2 € », « 500 € »…
static func label(value: int) -> String:
	if value < 100:
		return "%d c" % value
	return "%d €" % (value / 100)


## Fusion que la joueuse déclenche en posant la coupure `held` sur la coupure `touched`.
## `available` dit ce que le bocal contient ({ valeur: nombre }), ces deux-là comprises : une fusion
## à trois va chercher sa troisième coupure dans le bocal.
## Renvoie { "inputs": Array[int], "outputs": Array[int] }, ou {} si rien ne fusionne.
static func hand_merge(held: int, touched: int, available: Dictionary) -> Dictionary:
	# La table de casse, lue à l'envers.
	for output in VALUES:
		if not BREAKS.has(output):
			continue
		var inputs: Array = BREAKS[output]
		if _has_both(inputs, held, touched) and _covers(available, inputs):
			var needed: Array[int] = []
			needed.assign(inputs)
			var made: Array[int] = [output]
			return {"inputs": needed, "outputs": made}
	# Trois pareilles, faute de la petite qui complète : 3 × 2 c -> 5 c + 1 c.
	if held == touched:
		for output in VALUES:
			if not BREAKS.has(output):
				continue
			var inputs: Array = BREAKS[output]
			if inputs.size() == 3 and inputs[0] == held and inputs[1] == held and inputs[2] != held:
				var three: Array[int] = [held, held, held]
				if _covers(available, three):
					var change: int = inputs[2]
					var made: Array[int] = [output, change]
					return {"inputs": three, "outputs": made}
	return {}


static func _has_both(inputs: Array, first: int, second: int) -> bool:
	if first == second:
		return inputs.count(first) >= 2
	return inputs.has(first) and inputs.has(second)


static func _covers(available: Dictionary, inputs: Array) -> bool:
	for value in inputs:
		if int(available.get(value, 0)) < inputs.count(value):
			return false
	return true


## 9231 -> « 92,31 € »
static func format_cents(cents: int) -> String:
	var euros := cents / 100
	var rest := cents % 100
	var text := str(euros)
	var grouped := ""
	while text.length() > 3:
		grouped = " " + text.substr(text.length() - 3) + grouped
		text = text.substr(0, text.length() - 3)
	return "%s%s,%02d €" % [text, grouped, rest]
