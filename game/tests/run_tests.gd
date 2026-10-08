## Lanceur de tests sans dépendance :
##   godot --headless --path game --script res://tests/run_tests.gd
##   godot --headless --path game --script res://tests/run_tests.gd -- res://tests/unit/test_payroll.gd
## Exécute toutes les suites `test_*.gd` de tests/unit et tests/content, ou seulement celles
## passées après `--`. Code de sortie 1 si un test échoue.
extends SceneTree

const SUITE_FOLDERS: Array[String] = ["res://tests/unit", "res://tests/content"]


## Compte les erreurs du moteur : une erreur de script interrompt un test sans rien signaler,
## il passerait pour réussi.
class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		count += 1


func _initialize() -> void:
	var counter := ErrorCounter.new()
	OS.add_logger(counter)
	var failures := 0
	var total := 0
	var suites := _find_suites()
	if not OS.get_cmdline_user_args().is_empty():
		suites.assign(OS.get_cmdline_user_args())
	for path in suites:
		var script: GDScript = load(path)
		# Un script qui ne compile pas doit faire échouer la suite, jamais bloquer le lanceur.
		if script == null or not script.can_instantiate():
			print("  ECHEC  %s — script introuvable ou invalide" % path)
			failures += 1
			continue
		var suite: RefCounted = script.new()
		for method in suite.get_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			suite.errors.clear()
			var errors_before := counter.count
			suite.call(method_name)
			if counter.count > errors_before:
				suite.errors.append("erreur de script pendant le test (voir stderr)")
			if suite.errors.is_empty():
				print("  ok     %s :: %s" % [path.get_file(), method_name])
			else:
				failures += 1
				for error in suite.errors:
					print("  ECHEC  %s :: %s — %s" % [path.get_file(), method_name, error])
	print("%d tests, %d échec(s)" % [total, failures])
	OS.remove_logger(counter)
	quit(1 if failures > 0 or total == 0 else 0)


func _find_suites() -> Array[String]:
	var suites: Array[String] = []
	for folder in SUITE_FOLDERS:
		if not DirAccess.dir_exists_absolute(folder):
			continue
		var names := DirAccess.get_files_at(folder)
		names.sort()
		for file_name in names:
			if file_name.begins_with("test_") and file_name.ends_with(".gd"):
				suites.append(folder.path_join(file_name))
	return suites
