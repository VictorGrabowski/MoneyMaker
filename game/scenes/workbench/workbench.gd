## Écran de travail de la refonte, en attendant la maison (epic 2) : le bocal, l'ardoise du jour,
## la fiche de paie provisoire et la bascule en widget. Le décor est un bouche-trou.
##
## Arguments (après `--`) :
##   --shot=<fichier.png>   enregistre une capture, écrit un rapport puis quitte
##   --shot-delay=<s>       délai avant la capture (6 s par défaut)
##   --widget               démarre en widget
## Démonstration, sans toucher à la sauvegarde :
##   --fill=<centimes>      montant placé dans le bocal
##   --bench=<objets>       fait tomber ce nombre d'objets et mesure les images par seconde
## Essais (version de développement uniquement) :
##   --profile=<nom>        sauvegarde à part, dans user://save_<nom>
##   --now=<AAAA-MM-JJTHH:MM:SS>  fait comme s'il était cette heure-là
##   --net=<centimes>       règle le net mensuel si rien n'est encore réglé
##   --jar=<pot|bocal|bonbonne>   change de bocal
extends Node2D

const Denominations := preload("res://core/money/denominations.gd")
const JarComposition := preload("res://core/money/jar_composition.gd")
const Jar := preload("res://core/money/jar.gd")
const SalaryEngine := preload("res://core/money/salary_engine.gd")
const WorkSchedule := preload("res://core/time/work_schedule.gd")
const MoneyFaces := preload("res://scenes/jar/money_faces.gd")
const JarView := preload("res://scenes/jar/jar_view.gd")
const JarGlass := preload("res://scenes/jar/jar_glass.gd")
const WidgetView := preload("res://scenes/widget/widget_view.gd")
const PaySheet := preload("res://scenes/workbench/pay_sheet.gd")

## Salaire de la démonstration : 2 000 € net, 35 h par semaine.
const DEMO_NET_CENTS := 200000
const DEMO_DAY_CENTS := 9230
const DEMO_WEEK_CENTS := 46150
const POUR_CENTS := 500

const DESIGN_SIZE := Vector2i(1920, 1080)
const WIDGET_SIZE := Vector2i(320, 96)
const JAR_RECT := Rect2(380, 110, 1160, 900)
const SLATE_POSITION := Vector2(110, 250)

const INK := Color(0.227, 0.149, 0.094)
const CREAM := Color(0.965, 0.914, 0.824)
const HONEY := Color(0.949, 0.722, 0.400)
const CRUST := Color(0.851, 0.565, 0.184)
const WALNUT := Color(0.420, 0.267, 0.137)
const CHALK := Color(0.929, 0.902, 0.847)

const HELP_LIVE := "Glisser : attraper une pièce   ·   Espace : secouer   ·   P : fiche de paie   ·   W : widget   ·   F : images/s"
const HELP_DEMO := "Démonstration   ·   Glisser : attraper une pièce   ·   Espace : secouer   ·   + : verser 5 €   ·   W : widget"

var _args: Dictionary = {}
## Vrai : montants de démonstration, la sauvegarde n'est ni lue ni écrite.
var _is_demo := false
var _demo_jar: Jar
var _in_widget := false
var _window_before_widget: Dictionary = {}

var _home: Node2D
var _backdrop: Node2D
var _counter: ColorRect
var _counter_edge: ColorRect
var _jar: JarView
var _back_glass: JarGlass
var _slate: Panel
var _slate_amount: Label
var _slate_jar: Label
var _slate_rate: Label
var _fps_label: Label
var _widget: WidgetView
var _pay_sheet: PaySheet
var _hand_font: SystemFont


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--"):
			var pair := argument.substr(2).split("=", true, 1)
			_args[pair[0]] = pair[1] if pair.size() > 1 else ""
	_is_demo = _args.has("fill") or _args.has("bench")

	if _is_demo:
		_demo_jar = Jar.new()
		_demo_jar.day_pay_cents = DEMO_DAY_CENTS
		_demo_jar.week_pay_cents = DEMO_WEEK_CENTS
		_demo_jar.month_pay_cents = DEMO_NET_CENTS
		if Jar.SIZES.has(_args.get("jar", "")):
			_demo_jar.size = _args["jar"]
		_demo_jar.set_cents(int(_args.get("fill", "0")))
	else:
		var testing := OS.is_debug_build()
		if testing and _args.has("now"):
			Clock.pretend_it_is(_args["now"])
		Game.boot(_args.get("profile", "") if testing else "")
		if testing and _args.has("net") and not Game.state.payroll.is_configured():
			Game.set_pay(int(_args["net"]), {})
		if testing and Jar.SIZES.has(_args.get("jar", "")):
			Game.state.jar.set_size(_args["jar"])

	_hand_font = SystemFont.new()
	_hand_font.font_names = PackedStringArray(["Segoe Print", "Ink Free", "Comic Sans MS"])
	_hand_font.font_weight = 700

	_home = Node2D.new()
	add_child(_home)
	_build_backdrop()
	_build_slate()

	var faces := MoneyFaces.new()
	add_child(faces)
	var textures: Dictionary = await faces.load_all()
	var illustrated := faces.illustrated.duplicate()
	faces.queue_free()
	_build_jar(textures, illustrated)
	_build_widget()
	_build_pay_sheet()
	_fill_at_start()

	if not _is_demo:
		Events.jar_changed.connect(_on_jar_changed)
		Events.settings_changed.connect(_refresh_amounts)
		Clock.second_ticked.connect(func(_now: int) -> void: _refresh_amounts())
		if not Game.state.payroll.is_configured():
			_show_pay_sheet(true)
	if _args.has("widget"):
		_set_widget_mode(true)
	if _args.has("shot"):
		_capture_and_quit()


func _process(delta: float) -> void:
	if _in_widget or _jar == null:
		return
	var view := Vector2(get_viewport().get_visible_rect().size)
	var mouse := (get_viewport().get_mouse_position() / view * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)
	_backdrop.position = _backdrop.position.lerp(-mouse * 14.0, minf(1.0, delta * 6.0))
	_slate.position = SLATE_POSITION - mouse * 7.0
	_jar.parallax = mouse
	_align_counter()
	if _fps_label.visible:
		_fps_label.text = "%d images/s · %d objets · %d en mouvement" % [
			Engine.get_frames_per_second(), _jar.object_count(), _jar.awake_count()]


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _jar == null:
		return
	match key.keycode:
		KEY_SPACE:
			_jar.shake()
		KEY_W:
			_set_widget_mode(not _in_widget)
		KEY_F:
			_fps_label.visible = not _fps_label.visible
		KEY_P:
			if not _is_demo and not _in_widget:
				_show_pay_sheet(not _pay_sheet.visible)
		KEY_KP_ADD, KEY_PLUS, KEY_EQUAL:
			if _is_demo and not _args.has("bench"):
				_on_jar_changed(_demo_jar.add_cents(POUR_CENTS))
		KEY_ESCAPE:
			if _pay_sheet.visible:
				_show_pay_sheet(false)
			elif _in_widget:
				_set_widget_mode(false)


# --- Montants ---

func _jar_model() -> Jar:
	return _demo_jar if _is_demo else Game.state.jar


func _today_cents() -> int:
	return _demo_jar.cents() if _is_demo else Game.state.payroll.earned_today()


func _hourly_cents() -> int:
	if _is_demo:
		return SalaryEngine.hourly_cents(WorkSchedule.new(), DEMO_NET_CENTS)
	return Game.state.payroll.hourly_cents()


func _fill_at_start() -> void:
	if _args.has("bench"):
		var objects := int(_args["bench"])
		_jar.show_composition(JarComposition.compose(objects * 103, objects))
	else:
		_jar.show_composition(_jar_model().composition)
	_refresh_amounts()


## Le modèle du bocal a changé : la scène joue ses opérations, puis on vérifie qu'elle montre
## bien le même contenu que lui.
func _on_jar_changed(ops: Array[Dictionary]) -> void:
	_jar.apply_ops(ops)
	if _jar.content() != _jar_model().composition:
		push_warning("Le bocal affiché ne correspond plus au modèle : il est refait.")
		_jar.show_composition(_jar_model().composition)
	_refresh_amounts()


func _refresh_amounts() -> void:
	var today := Denominations.format_cents(_today_cents())
	_slate_amount.text = today
	_slate_jar.text = "Dans le bocal : %s" % Denominations.format_cents(_jar_model().cents())
	_slate_rate.text = "%s de l'heure" % Denominations.format_cents(_hourly_cents())
	_widget.amount_text = today
	_widget.ring_progress = 0.62


# --- Construction de l'écran ---

func _build_backdrop() -> void:
	_backdrop = Node2D.new()
	_home.add_child(_backdrop)

	var wall_gradient := Gradient.new()
	wall_gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	wall_gradient.colors = PackedColorArray([CREAM, HONEY.lerp(CREAM, 0.35), CRUST.lerp(CREAM, 0.15)])
	var wall_texture := GradientTexture2D.new()
	wall_texture.gradient = wall_gradient
	wall_texture.fill_from = Vector2(0.0, 0.0)
	wall_texture.fill_to = Vector2(0.0, 1.0)
	wall_texture.width = 8
	wall_texture.height = 256
	var wall := TextureRect.new()
	wall.texture = wall_texture
	wall.stretch_mode = TextureRect.STRETCH_SCALE
	wall.position = Vector2(-160, -120)
	wall.size = Vector2(DESIGN_SIZE) + Vector2(320, 240)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.add_child(wall)

	var glow_gradient := Gradient.new()
	glow_gradient.offsets = PackedFloat32Array([0.0, 1.0])
	glow_gradient.colors = PackedColorArray([Color(1.0, 0.86, 0.60, 0.9), Color(1.0, 0.86, 0.60, 0.0)])
	var glow_texture := GradientTexture2D.new()
	glow_texture.gradient = glow_gradient
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 0.5)
	glow_texture.width = 128
	glow_texture.height = 128

	# Guirlande : une courbe de petites lumières chaudes en haut du mur.
	for i in 17:
		var t := i / 16.0
		var bulb := Sprite2D.new()
		bulb.texture = glow_texture
		bulb.position = Vector2(lerpf(-60.0, 1980.0, t), 96.0 + sin(t * PI) * 70.0 + sin(i * 2.3) * 10.0)
		bulb.scale = Vector2.ONE * (0.42 + 0.10 * sin(i * 1.7))
		_backdrop.add_child(bulb)
	var window_glow := Sprite2D.new()
	window_glow.texture = glow_texture
	window_glow.position = Vector2(1560, 420)
	window_glow.scale = Vector2(9.0, 7.0)
	window_glow.modulate = Color(1.0, 1.0, 1.0, 0.55)
	_backdrop.add_child(window_glow)

	_counter = ColorRect.new()
	_counter.color = WALNUT
	_counter.size = Vector2(DESIGN_SIZE.x + 320, 600)
	_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.add_child(_counter)
	_counter_edge = ColorRect.new()
	_counter_edge.color = WALNUT.lightened(0.22)
	_counter_edge.size = Vector2(DESIGN_SIZE.x + 320, 14)
	_counter_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.add_child(_counter_edge)
	_counter.position = Vector2(-160, 880)
	_counter_edge.position = _counter.position


## Pose le bord du comptoir dessiné à la hauteur du comptoir sur lequel roulent les pièces.
func _align_counter() -> void:
	var line := _jar.position.y + _jar.counter_line() - _backdrop.position.y
	_counter.position.y = line
	_counter_edge.position.y = line


func _build_slate() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.17, 0.17, 0.16)
	style.border_color = WALNUT
	style.set_border_width_all(12)
	style.set_corner_radius_all(8)
	_slate = Panel.new()
	_slate.add_theme_stylebox_override("panel", style)
	_slate.position = SLATE_POSITION
	_slate.size = Vector2(420, 290)
	_slate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home.add_child(_slate)

	_chalk_label("Démonstration" if _is_demo else "Aujourd'hui", 24, Vector2(34, 28))
	_slate_amount = _chalk_label("0,00 €", 50, Vector2(30, 62))
	_slate_jar = _chalk_label("", 21, Vector2(34, 164))
	_slate_rate = _chalk_label("", 19, Vector2(34, 212))

	var help_settings := LabelSettings.new()
	help_settings.font = _hand_font
	help_settings.font_size = 20
	help_settings.font_color = CREAM
	var help := Label.new()
	help.text = HELP_DEMO if _is_demo else HELP_LIVE
	help.label_settings = help_settings
	help.position = Vector2(40, 1026)
	_home.add_child(help)

	var fps_settings := LabelSettings.new()
	fps_settings.font_size = 20
	fps_settings.font_color = INK
	_fps_label = Label.new()
	_fps_label.label_settings = fps_settings
	_fps_label.position = Vector2(40, 24)
	_fps_label.visible = false
	_home.add_child(_fps_label)


func _chalk_label(text: String, font_size: int, at: Vector2) -> Label:
	var settings := LabelSettings.new()
	settings.font = _hand_font
	settings.font_size = font_size
	settings.font_color = CHALK
	var label := Label.new()
	label.text = text
	label.label_settings = settings
	label.position = at
	_slate.add_child(label)
	return label


func _build_jar(textures: Dictionary, illustrated: Array[int]) -> void:
	_back_glass = JarGlass.new()
	_back_glass.is_back = true
	_back_glass.position = JAR_RECT.position
	_home.add_child(_back_glass)

	_jar = JarView.new()
	_jar.setup(textures, illustrated, _jar_model().size)
	_jar.position = JAR_RECT.position
	_jar.size = JAR_RECT.size
	_home.add_child(_jar)
	_back_glass.jar = _jar

	var front_glass := JarGlass.new()
	front_glass.jar = _jar
	_jar.add_child(front_glass)
	# L'ardoise passe devant le bocal, dont la vignette couvre presque tout l'écran.
	_home.move_child(_slate, -1)


func _build_widget() -> void:
	_widget = WidgetView.new()
	_widget.size = Vector2(WIDGET_SIZE)
	_widget.visible = false
	_widget.expand_requested.connect(_set_widget_mode.bind(false))
	add_child(_widget)


func _build_pay_sheet() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	_pay_sheet = PaySheet.new()
	_pay_sheet.visible = false
	_pay_sheet.saved.connect(_on_pay_saved)
	_pay_sheet.closed.connect(_show_pay_sheet.bind(false))
	center.add_child(_pay_sheet)


func _show_pay_sheet(shown: bool) -> void:
	if shown:
		_pay_sheet.show_values(Game.state.payroll.net_monthly_cents, Game.state.payroll.schedule)
	_pay_sheet.visible = shown


func _on_pay_saved(net_monthly_cents: int, schedule_values: Dictionary) -> void:
	Game.set_pay(net_monthly_cents, schedule_values)
	_show_pay_sheet(false)


# --- Widget ---

func _set_widget_mode(enabled: bool) -> void:
	if enabled == _in_widget:
		return
	var window := get_window()
	_in_widget = enabled
	_home.visible = not enabled
	_widget.visible = enabled
	# En bandeau, le bocal est en pause : ce qui est gagné attend et tombera au retour.
	_jar.set_simulating(not enabled)
	if enabled:
		_show_pay_sheet(false)
		_window_before_widget = {"mode": window.mode, "size": window.size, "position": window.position}
		window.mode = Window.MODE_WINDOWED
		window.borderless = true
		window.unresizable = true
		window.always_on_top = true
		window.transparent = true
		window.transparent_bg = true
		window.content_scale_size = WIDGET_SIZE
		window.min_size = WIDGET_SIZE
		window.size = WIDGET_SIZE
		var area := DisplayServer.screen_get_usable_rect(window.current_screen)
		window.position = area.position + area.size - WIDGET_SIZE - Vector2i(24, 24)
		OS.low_processor_usage_mode = true
	else:
		OS.low_processor_usage_mode = false
		window.transparent_bg = false
		window.transparent = false
		window.always_on_top = false
		window.unresizable = false
		window.borderless = false
		window.content_scale_size = DESIGN_SIZE
		window.size = _window_before_widget["size"]
		window.position = _window_before_widget["position"]
		window.mode = _window_before_widget["mode"]


# --- Capture et rapport (essais) ---

func _capture_and_quit() -> void:
	var delay := float(_args.get("shot-delay", "6"))
	await get_tree().create_timer(delay).timeout
	# --pour=<n> : en démonstration, verse n fois 5 € pour exercer chutes et fusions.
	if _is_demo and _args.has("pour"):
		for _i in int(_args["pour"]):
			_on_jar_changed(_demo_jar.add_cents(POUR_CENTS))
			await get_tree().create_timer(0.5).timeout
		await get_tree().create_timer(5.0).timeout

	var model := _jar_model()
	var report := {
		"objets": _jar.object_count(),
		"en_mouvement": _jar.awake_count(),
		"en_attente": _jar.queued_count(),
		"hors_bocal": _jar.outside_count(),
		"niveau_du_tas": snappedf(_jar.pile_level(), 0.01),
		"vitesse_max": str(_jar.max_speeds()),
		"aujourd_hui": Denominations.format_cents(_today_cents()),
	}
	if not _args.has("bench"):
		report["bocal"] = "%s (%s)" % [Denominations.format_cents(model.cents()), model.size]
		report["cible"] = model.target_count()
		report["niveau"] = snappedf(model.fullness(), 0.01)
		report["conforme_au_modele"] = _jar.content() == model.composition
		var kinds: Array[String] = []
		for value in Denominations.VALUES:
			if model.composition.get(value, 0) > 0:
				kinds.append("%s×%d" % [Denominations.label(value).replace(" ", ""), model.composition[value]])
		report["contenu"] = " ".join(kinds)
	if not _is_demo:
		var payroll := Game.state.payroll
		report["depart"] = Game.started_from
		report["jour_en_cours"] = payroll.open_day
		report["jours_clos"] = payroll.ledger.size()
		report["cumul"] = Denominations.format_cents(payroll.total_earned_cents)
	if _args.has("bench"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		await get_tree().create_timer(1.0).timeout
		var frames_before := Engine.get_frames_drawn()
		var started := Time.get_ticks_usec()
		await get_tree().create_timer(4.0).timeout
		var seconds := (Time.get_ticks_usec() - started) / 1000000.0
		report["images_par_seconde_sans_vsync"] = roundi((Engine.get_frames_drawn() - frames_before) / seconds)
		report["en_mouvement"] = _jar.awake_count()

	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(_args["shot"])

	var window := get_window()
	report["fenetre"] = "%s à %s" % [window.size, window.position]
	if _in_widget:
		report["transparence_disponible"] = DisplayServer.is_window_transparency_available()
		report["drapeau_transparent"] = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT)
		report["drapeau_premier_plan"] = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP)
		report["drapeau_sans_bordure"] = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
		report["alpha_du_coin"] = image.get_pixel(0, 0).a
		report["alpha_du_centre"] = image.get_pixel(image.get_width() / 2, image.get_height() / 2).a
		report["economie_processeur"] = OS.low_processor_usage_mode
	print("RAPPORT ", JSON.stringify(report))
	get_tree().quit()
