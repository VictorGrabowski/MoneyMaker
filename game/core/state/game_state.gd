## Tout ce que le jeu doit retenir d'une session à l'autre.
## Chaque epic y ajoutera sa partie ; pour l'instant : la paie et le contenu du bocal.
extends RefCounted

const Payroll := preload("res://core/money/payroll.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const Migrations := preload("res://core/save/migrations.gd")

const JAR_POT := "pot"

var payroll := Payroll.new()
## Espèces dans le bocal : gagnées, pas encore déposées.
var jar_cents := 0
var jar_size := JAR_POT
## Premier jour d'utilisation (« AAAA-MM-JJ »), vide tant que le jeu n'a jamais tourné.
var first_day := ""


## Fait avancer la paie et verse les centimes gagnés dans le bocal. Renvoie ces centimes.
func advance(now_local: int) -> int:
	if first_day == "":
		first_day = GameCalendar.date_of(now_local)
	var earned := payroll.advance(now_local)
	jar_cents += earned
	return earned


func to_dict(now_local: int) -> Dictionary:
	var paid := payroll.to_dict()
	return {
		"version": Migrations.CURRENT_VERSION,
		"saved_at": now_local,
		"settings": paid["settings"],
		"payroll": paid["state"],
		"ledger": paid["ledger"],
		"jar": {"size": jar_size, "cents": jar_cents},
		"stats": {"first_day": first_day},
	}


## Recharge une sauvegarde déjà passée par Migrations.migrate().
func load_dict(data: Dictionary) -> void:
	payroll.load_dict({
		"settings": data.get("settings", {}),
		"state": data.get("payroll", {}),
		"ledger": data.get("ledger", {}),
	})
	var jar: Dictionary = data.get("jar", {})
	jar_cents = maxi(0, int(jar.get("cents", 0)))
	jar_size = str(jar.get("size", JAR_POT))
	var stats: Dictionary = data.get("stats", {})
	first_day = str(stats.get("first_day", ""))
