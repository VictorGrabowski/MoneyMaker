## Ce que la joueuse écrit sur une feuille : une heure, une somme.
## La lecture est tolérante sur la forme, mais ne devine jamais : ce qui est ambigu est refusé (-1)
## plutôt que compris de travers.
extends RefCounted

const MINUTES_PER_DAY := 1440
## Une somme saisie tient en 7 chiffres avant la virgule.
const MAX_EURO_DIGITS := 7


## « 9 », « 9h », « 9 h 30 », « 09:30 » -> minutes depuis minuit ; -1 si illisible.
## « 9,5 » et « 9.30 » sont refusés : l'un veut dire 9 h 30, l'autre aussi, et rien ne les distingue.
static func minutes_from_text(text: String) -> int:
	var clean := _without_spaces(text).to_lower()
	var hours_text := clean
	var minutes_text := ""
	for separator in ["h", ":"]:
		var at := clean.find(separator)
		if at >= 0:
			hours_text = clean.substr(0, at)
			minutes_text = clean.substr(at + 1)
			break
	if not _is_digits(hours_text) or hours_text.length() > 2:
		return -1
	if minutes_text != "" and (not _is_digits(minutes_text) or minutes_text.length() > 2):
		return -1
	var minutes := int(minutes_text) if minutes_text != "" else 0
	if minutes > 59:
		return -1
	var total := int(hours_text) * 60 + minutes
	return total if total <= MINUTES_PER_DAY else -1


## 570 -> « 9 h 30 »
static func text_from_minutes(minutes: int) -> String:
	return "%d h %02d" % [minutes / 60, minutes % 60]


## « 2000 », « 2 000,50 », « 2000.5 € » -> centimes ; -1 si illisible.
## « 2.000 » est refusé : ce pourrait être deux mille euros comme deux euros.
static func cents_from_text(text: String) -> int:
	var clean := _without_spaces(text).replace("€", "").replace(",", ".")
	var parts := clean.split(".")
	if parts.size() > 2:
		return -1
	var euros_text := parts[0]
	var cents_text := parts[1] if parts.size() == 2 else ""
	if not _is_digits(euros_text) or euros_text.length() > MAX_EURO_DIGITS:
		return -1
	if cents_text.length() > 2 or (cents_text != "" and not _is_digits(cents_text)):
		return -1
	var cents := int(euros_text) * 100
	if cents_text.length() == 1:
		cents += int(cents_text) * 10
	elif cents_text.length() == 2:
		cents += int(cents_text)
	return cents


## 200000 -> « 2000 », 200050 -> « 2000,50 » : la somme telle qu'on la retape.
static func text_from_cents(cents: int) -> String:
	if cents % 100 == 0:
		return str(cents / 100)
	return "%d,%02d" % [cents / 100, cents % 100]


## Le texte sans aucune espace : ordinaire, insécable ou fine.
static func _without_spaces(text: String) -> String:
	return text.strip_edges().replace(" ", "").replace(" ", "").replace(" ", "")


static func _is_digits(text: String) -> bool:
	if text == "":
		return false
	for i in text.length():
		var code := text.unicode_at(i)
		if code < 48 or code > 57:
			return false
	return true
