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
