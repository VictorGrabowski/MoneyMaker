## Répartition d'un montant en coupures pour garnir le bocal.
## Une composition est un Dictionary { valeur_en_centimes: nombre }.
extends RefCounted

const Denominations := preload("res://core/money/denominations.gd")


## Le moins d'objets possible pour `total_cents`.
static func greedy(total_cents: int) -> Dictionary:
	var comp := {}
	var rest := total_cents
	for i in range(Denominations.VALUES.size() - 1, -1, -1):
		var value: int = Denominations.VALUES[i]
		if rest >= value:
			comp[value] = rest / value
			rest %= value
	return comp


static func count(comp: Dictionary) -> int:
	var n := 0
	for value in comp:
		n += comp[value]
	return n


static func total(comp: Dictionary) -> int:
	var sum := 0
	for value in comp:
		sum += value * comp[value]
	return sum


## Environ `target_count` objets valant exactement `total_cents`.
## Part de la répartition minimale, puis casse une coupure de chaque sorte à tour de rôle,
## de la plus grosse à la plus petite : le bocal garde des coupures de toutes tailles.
static func compose(total_cents: int, target_count: int) -> Dictionary:
	var comp := greedy(total_cents)
	var n := count(comp)
	var changed := true
	while changed and n < target_count:
		changed = false
		for i in range(Denominations.VALUES.size() - 1, -1, -1):
			var value: int = Denominations.VALUES[i]
			if comp.get(value, 0) == 0 or not Denominations.BREAKS.has(value):
				continue
			var parts: Array = Denominations.BREAKS[value]
			if n + parts.size() - 1 > target_count:
				continue
			comp[value] -= 1
			if comp[value] == 0:
				comp.erase(value)
			for part in parts:
				comp[part] = comp.get(part, 0) + 1
			n += parts.size() - 1
			changed = true
	return comp


## Liste à plat, mélangée, prête à tomber dans le bocal.
static func to_values(comp: Dictionary, rng: RandomNumberGenerator = null) -> Array[int]:
	var values: Array[int] = []
	for value in comp:
		for _i in comp[value]:
			values.append(value)
	if rng == null:
		values.shuffle()
	else:
		for i in range(values.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := values[i]
			values[i] = values[j]
			values[j] = tmp
	return values
