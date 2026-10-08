extends "res://tests/test_case.gd"

const SaveFiles := preload("res://core/save/save_files.gd")
const Migrations := preload("res://core/save/migrations.gd")

const ROOT := "user://_tests"

var _counter := 0


## Un dossier neuf par test, sous user://_tests.
func _files() -> SaveFiles:
	_counter += 1
	var directory := ROOT.path_join("save_%d_%d" % [Time.get_ticks_usec(), _counter])
	return SaveFiles.new(directory)


func _cleanup(files: SaveFiles) -> void:
	_remove_folder(files.directory)


func _remove_folder(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub in DirAccess.get_directories_at(path):
		_remove_folder(path.path_join(sub))
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	DirAccess.remove_absolute(path)


func _write_raw(files: SaveFiles, file_name: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(files.directory)
	var file := FileAccess.open(files.directory.path_join(file_name), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _save(marker: int) -> Dictionary:
	return {"version": Migrations.CURRENT_VERSION, "marker": marker}


func test_write_then_read() -> void:
	var files := _files()
	check(files.write(_save(1)), "écriture")
	var data := files.read(Migrations.is_loadable)
	check_eq(int(data.get("marker", 0)), 1, "contenu relu")
	check_eq(files.last_source, SaveFiles.MAIN, "lu dans le fichier principal")
	check(not FileAccess.file_exists(files.directory.path_join(SaveFiles.TEMP)), "pas de fichier temporaire laissé")
	_cleanup(files)


func test_second_write_replaces_the_first() -> void:
	var files := _files()
	files.write(_save(1))
	check(files.write(_save(2)), "seconde écriture")
	check_eq(int(files.read(Migrations.is_loadable)["marker"]), 2, "dernière version lue")
	_cleanup(files)


func test_empty_folder_reads_nothing() -> void:
	var files := _files()
	check(files.read(Migrations.is_loadable).is_empty(), "rien à lire")
	check(not files.has_any_file(), "aucun fichier")
	check_eq(files.last_source, "", "aucune source")


func test_corrupted_main_falls_back_to_backup() -> void:
	var files := _files()
	files.write(_save(1))
	files.rotate_backups()
	_write_raw(files, SaveFiles.MAIN, "{ ceci n'est pas du JSON")
	var data := files.read(Migrations.is_loadable)
	check_eq(int(data.get("marker", 0)), 1, "copie de secours lue")
	check_eq(files.last_source, SaveFiles.BACKUPS[0], "source : première copie")
	_cleanup(files)


func test_interrupted_write_is_recovered() -> void:
	# Coupure entre la suppression de l'ancien fichier et le renommage du nouveau.
	var files := _files()
	_write_raw(files, SaveFiles.TEMP, JSON.stringify(_save(7)))
	check_eq(int(files.read(Migrations.is_loadable).get("marker", 0)), 7, "fichier temporaire repris")
	check_eq(files.last_source, SaveFiles.TEMP, "source : fichier temporaire")
	_cleanup(files)


func test_backups_rotate_and_keep_three() -> void:
	var files := _files()
	for marker in [1, 2, 3, 4]:
		files.write(_save(marker))
		files.rotate_backups()
	files.write(_save(5))
	var kept: Array[int] = []
	for backup in SaveFiles.BACKUPS:
		var text := FileAccess.get_file_as_string(files.directory.path_join(backup))
		kept.append(int(JSON.parse_string(text)["marker"]))
	check_eq(kept, [4, 3, 2] as Array[int], "trois dernières copies, de la plus récente à la plus ancienne")
	check_eq(int(files.read(Migrations.is_loadable)["marker"]), 5, "le fichier principal reste le plus récent")
	_cleanup(files)


func test_newer_version_is_refused_and_set_aside() -> void:
	var files := _files()
	_write_raw(files, SaveFiles.MAIN, JSON.stringify({"version": Migrations.CURRENT_VERSION + 1, "marker": 9}))
	check(files.read(Migrations.is_loadable).is_empty(), "sauvegarde trop récente refusée")
	check(files.has_any_file(), "le fichier est toujours là")
	var aside := files.set_aside("essai")
	check(not files.has_any_file(), "plus de fichier à la place")
	check(FileAccess.file_exists(aside.path_join(SaveFiles.MAIN)), "fichier conservé de côté")
	_cleanup(files)


func test_everything_unreadable_reads_nothing() -> void:
	var files := _files()
	_write_raw(files, SaveFiles.MAIN, "")
	_write_raw(files, SaveFiles.BACKUPS[0], "[1, 2, 3]")
	_write_raw(files, SaveFiles.BACKUPS[1], "{\"pas de version\": true}")
	check(files.read(Migrations.is_loadable).is_empty(), "aucune sauvegarde exploitable")
	_cleanup(files)


func test_writing_a_year_of_ledger_is_fast() -> void:
	var files := _files()
	var ledger := {}
	for i in 400:
		ledger["2026-%03d" % i] = {"worked_seconds": 25200, "cents": 9230, "kind": "travaille"}
	var data := {"version": Migrations.CURRENT_VERSION, "ledger": ledger}
	files.write(data)  # crée le dossier
	var started := Time.get_ticks_usec()
	files.write(data)
	var elapsed_ms := (Time.get_ticks_usec() - started) / 1000.0
	check(elapsed_ms < 50.0, "écriture en moins de 50 ms (mesuré : %.1f ms)" % elapsed_ms)
	_cleanup(files)
