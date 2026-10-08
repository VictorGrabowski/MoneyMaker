## Le bocal : ce qu'il contient, sa taille et son niveau.
##
## Le bocal est une jauge : plein à ras bord, il vaut un jour (Pot), une semaine (Bocal) ou un mois
## (Bonbonne) de salaire. Le nombre d'objets suit ce niveau ; pour le tenir, les coupures fusionnent
## (ou se cassent) une à une, en gardant à peu près les proportions de PROFILE.
##
## Chaque changement est décrit par une liste d'opérations que la scène n'a plus qu'à jouer.
extends RefCounted

const Denominations := preload("res://core/money/denominations.gd")
const JarComposition := preload("res://core/money/jar_composition.gd")

const SIZE_POT := "pot"
const SIZE_BOCAL := "bocal"
const SIZE_BONBONNE := "bonbonne"
const SIZES: Array[String] = [SIZE_POT, SIZE_BOCAL, SIZE_BONBONNE]
## Nombre d'objets quand le bocal est plein à ras bord.
const FULL_OBJECTS: Dictionary = {SIZE_POT: 90, SIZE_BOCAL: 160, SIZE_BONBONNE: 240}
## Un bocal presque vide garde quand même quelques pièces plutôt qu'une seule grosse coupure.
const MIN_OBJECTS := 12
## Objets tolérés en plus quand le bocal déborde.
const OVERFLOW_OBJECTS := 24
## Écart toléré sous la cible avant de casser une coupure : évite de fusionner puis casser en boucle.
const SLACK := 2

## Part relative de chaque coupure : beaucoup de pièces de 1 et 2 €, de la petite monnaie,
## peu de billets. Une coupure « encombre » le bocal à hauteur de nombre ÷ part.
const PROFILE: Dictionary = {
	1: 0.6, 2: 0.6, 5: 0.7, 10: 0.8, 20: 0.9, 50: 1.0, 100: 1.6, 200: 2.0,
	500: 0.35, 1000: 0.30, 2000: 0.25, 5000: 0.20, 10000: 0.15, 20000: 0.12, 50000: 0.10,
	100000: 0.08, 1000000: 0.05,
}

## { "op": OP_DROP, "values": Array[int] } : ces coupures tombent dans le bocal.
const OP_DROP := "tomber"
## { "op": OP_MERGE, "inputs": Array[int], "output": int } : ces coupures n'en font plus qu'une.
const OP_MERGE := "fusionner"
## { "op": OP_SPLIT, "input": int, "outputs": Array[int] } : cette coupure se casse en plus petites.
const OP_SPLIT := "casser"

var size := SIZE_POT
## Les objets du bocal : valeur en centimes -> nombre.
var composition: Dictionary = {}
## Repères de salaire, tenus à jour par l'état du jeu : ils donnent la capacité.
var day_pay_cents := 0
var week_pay_cents := 0
var month_pay_cents := 0


func cents() -> int:
	return JarComposition.total(composition)


func object_count() -> int:
	return JarComposition.count(composition)


## Ce que vaut le bocal plein à ras bord.
func capacity_cents() -> int:
	match size:
		SIZE_BOCAL:
			return week_pay_cents
		SIZE_BONBONNE:
			return month_pay_cents
	return day_pay_cents


## Niveau du bocal : 1.0 = plein à ras bord, davantage s'il déborde. 0 tant que le salaire n'est pas réglé.
func fullness() -> float:
	var capacity := capacity_cents()
	return float(cents()) / float(capacity) if capacity > 0 else 0.0


## Nombre d'objets que le bocal doit montrer pour son niveau. Calculé en entiers : un arrondi de
## nombre à virgule ferait parfois apparaître ou disparaître un objet sans raison.
func target_count() -> int:
	var full: int = FULL_OBJECTS[size]
	var capacity := capacity_cents()
	if capacity <= 0:
		return MIN_OBJECTS
	var amount := cents()
	if amount <= capacity:
		# Arrondi au plus proche de amount × full ÷ capacity.
		return clampi((2 * amount * full + capacity) / (2 * capacity), MIN_OBJECTS, full)
	# Arrondi supérieur de la part qui dépasse.
	var overflowing := ((amount - capacity) * full + capacity - 1) / capacity
	return full + mini(OVERFLOW_OBJECTS, overflowing)


## Ajoute `amount` centimes. Renvoie les opérations à jouer : la chute, puis les fusions.
func add_cents(amount: int) -> Array[Dictionary]:
	var ops: Array[Dictionary] = []
	if amount <= 0:
		return ops
	var dropped := JarComposition.to_values(JarComposition.greedy(amount))
	for value in dropped:
		composition[value] = composition.get(value, 0) + 1
	ops.append({"op": OP_DROP, "values": dropped})
	ops.append_array(rebalance())
	return ops


## Ramène le nombre d'objets vers la cible, une fusion ou une casse à la fois.
func rebalance(slack: int = SLACK) -> Array[Dictionary]:
	var ops: Array[Dictionary] = []
	var target := target_count()
	var count := object_count()
	while count > target:
		var output := _best_merge()
		if output == 0:
			break
		var inputs: Array = Denominations.BREAKS[output]
		for value in inputs:
			_remove(value)
		composition[output] = composition.get(output, 0) + 1
		ops.append({"op": OP_MERGE, "inputs": inputs.duplicate(), "output": output})
		count -= inputs.size() - 1
	while count < target - slack:
		var input := _best_split(target - count)
		if input == 0:
			break
		var outputs: Array = Denominations.BREAKS[input]
		_remove(input)
		for value in outputs:
			composition[value] = composition.get(value, 0) + 1
		ops.append({"op": OP_SPLIT, "input": input, "outputs": outputs.duplicate()})
		count += outputs.size() - 1
	return ops


## Recompose entièrement le bocal pour ce montant (changement de taille, sauvegarde sans détail).
func set_cents(amount: int) -> void:
	composition = JarComposition.greedy(maxi(0, amount))
	rebalance(0)


func set_size(new_size: String) -> void:
	if not SIZES.has(new_size) or new_size == size:
		return
	var amount := cents()
	size = new_size
	set_cents(amount)


## Vide le bocal et renvoie ce qu'il contenait.
func take_all() -> int:
	var amount := cents()
	composition = {}
	return amount


func to_dict() -> Dictionary:
	var objects := {}
	for value in Denominations.VALUES:
		if composition.get(value, 0) > 0:
			objects[str(value)] = composition[value]
	return {"size": size, "cents": cents(), "composition": objects}


## Recharge ce que to_dict() a produit. Le montant fait foi : si le détail manque ou ne tombe pas
## juste, le bocal est recomposé pour ce montant.
func load_dict(data: Dictionary) -> void:
	size = str(data.get("size", SIZE_POT))
	if not SIZES.has(size):
		size = SIZE_POT
	composition = {}
	var objects: Variant = data.get("composition", {})
	if typeof(objects) == TYPE_DICTIONARY:
		for key in objects:
			var value := str(key).to_int()
			var number := int(objects[key])
			if Denominations.VALUES.has(value) and number > 0:
				composition[value] = number
	var amount := maxi(0, int(data.get("cents", cents())))
	if cents() != amount:
		set_cents(amount)


func _remove(value: int) -> void:
	composition[value] -= 1
	if composition[value] <= 0:
		composition.erase(value)


func _crowding(value: int) -> float:
	return composition.get(value, 0) / float(PROFILE[value])


## Coupure à former par fusion : celle dont l'ingrédient principal encombre le plus le bocal.
## 0 si aucune fusion n'est possible.
func _best_merge() -> int:
	var best := 0
	var best_score := -1.0
	for output in Denominations.VALUES:
		if not Denominations.BREAKS.has(output):
			continue
		var inputs: Array = Denominations.BREAKS[output]
		var available := true
		for value in inputs:
			if composition.get(value, 0) < inputs.count(value):
				available = false
				break
		if not available:
			continue
		# Le premier ingrédient d'une règle est toujours le plus gros.
		var score := _crowding(inputs[0])
		if score > best_score:
			best_score = score
			best = output
	return best


## Coupure à casser parmi celles qui tiennent dans `room` objets de plus : celle qui encombre le
## plus par rapport à ce qu'elle donnerait. Sans cet écart, toute la monnaie finirait en centimes.
## 0 si rien ne peut être cassé.
func _best_split(room: int) -> int:
	var best := 0
	var best_score := -INF
	for i in range(Denominations.VALUES.size() - 1, -1, -1):
		var value: int = Denominations.VALUES[i]
		if composition.get(value, 0) == 0 or not Denominations.BREAKS.has(value):
			continue
		var outputs: Array = Denominations.BREAKS[value]
		if outputs.size() - 1 > room:
			continue
		var most_crowded_output := 0.0
		for output in outputs:
			most_crowded_output = maxf(most_crowded_output, _crowding(output))
		var score := _crowding(value) - most_crowded_output
		if score > best_score:
			best_score = score
			best = value
	return best
