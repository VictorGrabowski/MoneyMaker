## Possède l'état du jeu : le charge, le fait avancer chaque seconde et le sauvegarde.
## Reste inerte tant que boot() n'a pas été appelé, pour que les tests hors écran ne touchent
## jamais à la vraie sauvegarde.
extends Node

const GameState := preload("res://core/state/game_state.gd")
const SaveFiles := preload("res://core/save/save_files.gd")
const Migrations := preload("res://core/save/migrations.gd")
const V1Import := preload("res://core/save/v1_import.gd")

const SAVE_FOLDER := "user://save"
## Délai entre une action de la joueuse et l'écriture, pour regrouper les écritures.
const SAVE_DELAY_SECONDS := 2.0
## Les centimes qui tombent ne déclenchent pas d'écriture : au pire, le rattrapage les recalcule.
const AUTOSAVE_SECONDS := 60.0

const FROM_SAVE := "sauvegarde"
const FROM_V1 := "reprise_v1"
const FROM_SCRATCH := "nouvelle_partie"

var state: GameState = null
## D'où vient l'état après boot() : FROM_SAVE, FROM_V1 ou FROM_SCRATCH.
var started_from := ""

var _files: SaveFiles
var _save_in := -1.0
var _autosave_in := AUTOSAVE_SECONDS
var _dirty := false


func is_booted() -> bool:
	return state != null


## Charge la sauvegarde (ou en crée une), rattrape le temps écoulé et démarre la paie.
## `profile` isole une sauvegarde d'essai dans son propre dossier.
func boot(profile: String = "") -> void:
	if state != null:
		return
	_files = SaveFiles.new(SAVE_FOLDER if profile == "" else "%s_%s" % [SAVE_FOLDER, profile])
	state = GameState.new()

	var data := _files.read(Migrations.is_loadable)
	if not data.is_empty():
		state.load_dict(Migrations.migrate(data))
		started_from = FROM_SAVE
		# Si la lecture vient d'une copie, le fichier principal est abîmé : on ne le recopie pas.
		if _files.last_source == SaveFiles.MAIN:
			_files.rotate_backups()
	else:
		if _files.has_any_file():
			var aside := _files.set_aside(Time.get_datetime_string_from_system().replace(":", "-"))
			push_warning("Sauvegarde illisible, mise de côté dans %s" % aside)
		started_from = FROM_SCRATCH
		if profile == "" and _import_v1_settings():
			started_from = FROM_V1

	Clock.second_ticked.connect(_on_second)
	_on_second(Clock.now_local())
	save_now()


## Change le salaire et les horaires. Prend effet tout de suite pour la journée en cours ;
## les jours clos ne bougent pas.
func set_pay(net_monthly_cents: int, schedule_values: Dictionary) -> void:
	state.payroll.net_monthly_cents = maxi(0, net_monthly_cents)
	state.payroll.apply_schedule_dict(schedule_values)
	Events.settings_changed.emit()
	_on_second(Clock.now_local())
	request_save()


## Demande une écriture dans SAVE_DELAY_SECONDS ; plusieurs demandes rapprochées n'en font qu'une.
func request_save() -> void:
	_dirty = true
	if _save_in < 0.0:
		_save_in = SAVE_DELAY_SECONDS


func save_now() -> bool:
	_dirty = false
	_save_in = -1.0
	_autosave_in = AUTOSAVE_SECONDS
	var written := _files.write(state.to_dict(Clock.now_local()))
	if not written:
		push_warning("La sauvegarde n'a pas pu être écrite dans %s" % _files.directory)
	return written


func _on_second(now_local: int) -> void:
	var earned := state.advance(now_local)
	if earned > 0:
		_dirty = true
		Events.cents_earned.emit(earned)


func _process(delta: float) -> void:
	if state == null:
		return
	if _save_in >= 0.0:
		_save_in -= delta
		if _save_in <= 0.0:
			save_now()
	_autosave_in -= delta
	if _autosave_in <= 0.0:
		_autosave_in = AUTOSAVE_SECONDS
		if _dirty:
			save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and state != null:
		save_now()


func _exit_tree() -> void:
	if state != null:
		save_now()


## Au tout premier lancement : reprend salaire et horaires de l'application v1 s'ils existent.
func _import_v1_settings() -> bool:
	var app_data := OS.get_environment("APPDATA")
	if app_data == "":
		return false
	var path := app_data.path_join(V1Import.V1_FOLDER).path_join(V1Import.V1_FILE)
	if not FileAccess.file_exists(path):
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false
	var settings := V1Import.settings_from_v1(json.data)
	if settings.is_empty():
		return false
	state.payroll.net_monthly_cents = settings["net_monthly_cents"]
	state.payroll.apply_schedule_dict(settings["schedule"])
	return true
