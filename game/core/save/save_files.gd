## Lecture et écriture de la sauvegarde sur disque.
##
## - L'écriture passe par un fichier temporaire : le bon fichier n'est jamais à moitié écrit.
## - Trois copies de secours tournent une fois par lancement (pas à chaque écriture : des copies
##   écrites à quelques secondes d'écart ne protégeraient de rien).
## - Rien n'est jamais supprimé quand une sauvegarde est illisible : elle est mise de côté.
extends RefCounted

const MAIN := "save.json"
const TEMP := "save.tmp"
const BACKUPS: Array[String] = ["save.1.json", "save.2.json", "save.3.json"]

var directory := ""
## Fichier d'où vient la dernière lecture réussie (MAIN, TEMP ou une copie), "" sinon.
var last_source := ""


func _init(save_directory: String) -> void:
	directory = save_directory


## Remplace la sauvegarde par `data`. Faux si l'écriture a échoué (l'ancienne reste alors en place).
func write(data: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return false
	var temp_path := directory.path_join(TEMP)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	var main_path := directory.path_join(MAIN)
	if FileAccess.file_exists(main_path) and DirAccess.remove_absolute(main_path) != OK:
		return false
	return DirAccess.rename_absolute(temp_path, main_path) == OK


## Première sauvegarde lisible et acceptée par `is_loadable` : le fichier principal, puis une
## écriture interrompue, puis les copies de la plus récente à la plus ancienne. {} si aucune.
func read(is_loadable: Callable) -> Dictionary:
	last_source = ""
	var candidates: Array[String] = [MAIN, TEMP]
	candidates.append_array(BACKUPS)
	for file_name in candidates:
		var data := _read_file(directory.path_join(file_name))
		if not data.is_empty() and is_loadable.call(data):
			last_source = file_name
			return data
	return {}


## Vrai s'il existe au moins un fichier de sauvegarde, lisible ou non.
func has_any_file() -> bool:
	var candidates: Array[String] = [MAIN, TEMP]
	candidates.append_array(BACKUPS)
	for file_name in candidates:
		if FileAccess.file_exists(directory.path_join(file_name)):
			return true
	return false


## Décale les copies (1 -> 2 -> 3) et copie la sauvegarde courante en première position.
## À appeler une fois par lancement, après une lecture réussie.
func rotate_backups() -> void:
	var main_path := directory.path_join(MAIN)
	if not FileAccess.file_exists(main_path):
		return
	for i in range(BACKUPS.size() - 1, 0, -1):
		var newer := directory.path_join(BACKUPS[i - 1])
		var older := directory.path_join(BACKUPS[i])
		if not FileAccess.file_exists(newer):
			continue
		if FileAccess.file_exists(older):
			DirAccess.remove_absolute(older)
		DirAccess.rename_absolute(newer, older)
	DirAccess.copy_absolute(main_path, directory.path_join(BACKUPS[0]))


## Déplace tous les fichiers de sauvegarde dans un sous-dossier « illisible-<label> ».
## Renvoie le chemin de ce sous-dossier.
func set_aside(label: String) -> String:
	var target := directory.path_join("illisible-%s" % label)
	DirAccess.make_dir_recursive_absolute(target)
	var candidates: Array[String] = [MAIN, TEMP]
	candidates.append_array(BACKUPS)
	for file_name in candidates:
		var path := directory.path_join(file_name)
		if FileAccess.file_exists(path):
			DirAccess.rename_absolute(path, target.path_join(file_name))
	return target


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data
