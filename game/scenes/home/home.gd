## La maison : le lieu principal du jeu, deux écrans de large, en décor provisoire.
## On la balaie en approchant la souris d'un bord (ou avec Q/D et les flèches) ; ses objets
## s'ouvrent en gros plan ; sa lumière suit l'heure et le ciel.
##
## Arguments (après `--`), pour les essais :
##   --shot=<fichier.png>   enregistre une capture, écrit un rapport puis quitte
##   --shot-delay=<s>       délai avant la capture (6 s par défaut)
##   --pan=<0 à 1>          position du balayage, de l'extrême gauche (0) à l'extrême droite (1)
##   --mouse=<x,y>          fait comme si la souris était là (de -1 à 1, 0,0 au centre de l'écran)
##   --watch=<s>            avant la capture, observe le bocal pendant ce temps (part du temps occupé)
##   --search=<nom>         avant la capture, cherche une ville auprès du service météo
##   --closeup=<objet>      ouvre un gros plan : fiche_de_paie, calendrier, barometre, caisse,
##                          cadre_du_widget, bocal
##   --tour                 ouvre et referme chaque gros plan, pour débusquer les erreurs
##   --gestures             joue les gestes à la souris avec de vrais événements : secouer le bocal,
##                          l'ouvrir d'un clic, fusionner des pièces, clic droit sur le mini-bocal
##   --snaps=<préfixe>      avec --gestures : enregistre <préfixe>_<moment>.png en plein geste
##   --blank                avec --closeup=fiche_de_paie : tente d'enregistrer la fiche sans salaire
##   --widget[=<format>]    démarre en widget
## Version de développement uniquement :
##   --profile=<nom>  --now=<AAAA-MM-JJTHH:MM:SS>  --net=<centimes>  --jar=<taille>  --discreet
##   --weather=<clair|nuageux|pluie|neige|brouillard>  --season=<printemps|ete|automne|hiver>
##   --city=<nom,latitude,longitude>   règle la ville (et déclenche un relevé météo réel)
##   --mark=<AAAA-MM-JJ:marque>        marque un jour (conge, ferie, sans_solde)
##   --manual[=pointe]                 passe au pointage manuel (et pointe l'arrivée)
##   --fps=<n>                         images par seconde au plus (60 par défaut à la maison)
extends Node2D

const Layout := preload("res://scenes/home/home_layout.gd")
const Decor := preload("res://scenes/home/home_decor.gd")
const Prop := preload("res://scenes/home/home_prop.gd")
const ParallaxPlane := preload("res://scenes/shared/parallax_plane.gd")
const CloseupLayer := preload("res://scenes/closeups/closeup_layer.gd")
const Paper := preload("res://scenes/closeups/paper.gd")
const PaySheet := preload("res://scenes/closeups/pay_sheet.gd")
const CalendarCloseup := preload("res://scenes/closeups/calendar_closeup.gd")
const BarometerCloseup := preload("res://scenes/closeups/barometer_closeup.gd")
const TicketCloseup := preload("res://scenes/closeups/ticket_closeup.gd")
const WidgetFrameCloseup := preload("res://scenes/closeups/widget_frame_closeup.gd")
const MoneyFaces := preload("res://scenes/jar/money_faces.gd")
const JarView := preload("res://scenes/jar/jar_view.gd")
const JarGlass := preload("res://scenes/jar/jar_glass.gd")
const JarSounds := preload("res://scenes/jar/jar_sounds.gd")
const WidgetView := preload("res://scenes/widget/widget_view.gd")
const Jar := preload("res://core/money/jar.gd")
const GameState := preload("res://core/state/game_state.gd")
const Denominations := preload("res://core/money/denominations.gd")
const GameCalendar := preload("res://core/time/game_calendar.gd")
const Weather := preload("res://core/world/weather.gd")

enum JarPlace { COUNTER, CLOSEUP, WIDGET }

const HIDDEN_AMOUNT := "•••• €"
const CHALK := Color(0.929, 0.902, 0.847)
## Partie de la vignette du bocal qui répond au clic, quand il est sur le comptoir.
const JAR_HIT_AREA := Rect2(140.0, 150.0, 280.0, 290.0)
## Sur le comptoir, un appui qui glisse de plus que cela saisit le bocal au lieu de l'ouvrir.
const JAR_DRAG_PIXELS := 10.0
## Les objets prennent la lumière de la pièce, mais gardent une part de clarté propre : la nuit,
## ce qui se clique reste repérable, et le bocal comme l'ardoise restent lisibles.
const PROP_OWN_LIGHT := 0.18
const JAR_OWN_LIGHT := 0.5
## Bande d'où tombent la pluie et la neige, dans le plan du dehors : juste ce qu'il faut pour
## couvrir ce que la fenêtre et la porte laissent voir, d'un bout à l'autre du balayage.
const WEATHER_ORIGIN := Vector2(600.0, -40.0)
const WEATHER_EXTENTS := Vector2(1250.0, 10.0)

var _args: Dictionary = {}
## Vrai pendant un essai avec capture : la vraie souris ne doit rien déplacer.
var _scripted := false

var _world: Node2D
var _outside: ParallaxPlane
var _room: ParallaxPlane
var _lights: ParallaxPlane
var _front: ParallaxPlane
var _props: Dictionary = {}
var _slate: Panel
var _slate_amount: Label
var _slate_jar: Label
var _jar: JarView
var _jar_place := JarPlace.COUNTER
## Opérations appliquées au bocal depuis le lancement (pour les mesures).
var _ops_applied := 0
var _jar_label: Label
var _closeups: CloseupLayer
## La dernière fiche de paie ouverte (libérée à la fermeture de son gros plan).
var _pay_sheet: PaySheet
var _widget: WidgetView
var _sounds: JarSounds
var _rain: CPUParticles2D
var _snow: CPUParticles2D

var _closeup_counter: Panel

var _pan := 0.0
var _pan_target := 0.0
var _mouse_inside := true
## Écart de la souris au centre de l'écran, de -1 à 1 ; et celui qui décale les plans de la maison,
## figé tant qu'un gros plan est ouvert.
var _mouse := Vector2.ZERO
var _room_mouse := Vector2.ZERO
var _shown_day := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--"):
			var pair := argument.substr(2).split("=", true, 1)
			_args[pair[0]] = pair[1] if pair.size() > 1 else ""
	_scripted = _args.has("shot")
	_boot()

	_world = Node2D.new()
	_world.name = "Maison"
	add_child(_world)
	_outside = _add_plane(Decor.Kind.OUTSIDE, 0.6, 3.0)
	_room = _add_plane(Decor.Kind.ROOM, 1.0, 6.0)
	_build_weather()
	_build_slate()
	_build_props()
	_build_closeups()

	var faces := MoneyFaces.new()
	add_child(faces)
	var textures: Dictionary = await faces.load_all()
	var illustrated := faces.illustrated.duplicate()
	faces.queue_free()
	_build_jar(textures, illustrated)
	_lights = _add_plane(Decor.Kind.LIGHTS, 1.0, 6.0)
	_front = _add_plane(Decor.Kind.FRONT, 1.25, 12.0)

	_widget = WidgetView.new()
	_widget.name = "Widget"
	_widget.visible = false
	add_child(_widget)
	# Déplacer le mini-bocal, c'est déplacer le bocal : son contenu s'en ressent.
	_widget.window_moved.connect(func(pixels: Vector2) -> void:
		if _jar_place == JarPlace.WIDGET:
			_jar.sway(pixels))

	_sounds = JarSounds.new()
	_sounds.enabled = Game.state.sound_enabled
	add_child(_sounds)
	_jar.object_landed.connect(_on_object_landed)
	_jar.objects_changed.connect(func(_output: int) -> void: _sounds.play_merge())

	WindowModes.setup_tray(_tray_icon(textures[100]))
	WindowModes.changed.connect(_on_window_mode_changed)
	Events.jar_changed.connect(_on_jar_changed)
	Events.settings_changed.connect(_refresh)
	Events.preferences_changed.connect(_refresh)
	Clock.second_ticked.connect(func(_now: int) -> void: _refresh())
	Atmosphere.changed.connect(_on_sky_changed)
	get_window().mouse_entered.connect(func() -> void: _mouse_inside = true)
	get_window().mouse_exited.connect(func() -> void: _mouse_inside = false)

	get_viewport().size_changed.connect(_fit_view)
	_fit_view()
	_pan_target = clampf(Layout.START_FOCUS_X - _view_width() / 2.0, 0.0, _max_pan())
	if _args.has("pan"):
		_pan_target = clampf(float(_args["pan"]), 0.0, 1.0) * _max_pan()
	_pan = _pan_target
	if _args.has("mouse"):
		var offset: PackedStringArray = _args["mouse"].split(",")
		if offset.size() == 2:
			_mouse = Vector2(float(offset[0]), float(offset[1])).clamp(-Vector2.ONE, Vector2.ONE)
			_room_mouse = _mouse
	_place_planes(_room_mouse)
	_on_sky_changed()
	_refresh()

	if not Game.state.payroll.is_configured():
		_open_closeup(Prop.PAY_SHEET)
	elif _args.has("closeup"):
		_open_closeup(_args["closeup"])
	if _args.has("widget"):
		WindowModes.show_widget(_args["widget"])
	# À partir d'ici, le moteur ne redessine que si quelque chose change. (Pas plus tôt : les faces
	# provisoires ont besoin d'être dessinées.)
	OS.low_processor_usage_mode = true
	if _scripted:
		_capture_and_quit()


## Charge la partie et applique les réglages d'essai.
func _boot() -> void:
	var testing := OS.is_debug_build()
	if testing and _args.has("now"):
		Clock.pretend_it_is(_args["now"])
	Game.boot(_args.get("profile", "") if testing else "")
	if testing:
		if _args.has("net") and not Game.state.payroll.is_configured():
			Game.set_pay(int(_args["net"]), {})
		if Jar.SIZES.has(_args.get("jar", "")):
			Game.state.jar.set_size(_args["jar"])
		if _args.has("discreet"):
			Game.set_discreet(true)
		if _args.has("manual"):
			Game.set_pay(Game.state.payroll.net_monthly_cents, {"manual_clocking": true})
			if _args["manual"] == "pointe":
				Game.set_clocked_in(true)
		if _args.has("city"):
			var city: PackedStringArray = _args["city"].split(",")
			if city.size() == 3:
				Game.set_city(city[0], float(city[1]), float(city[2]))
		if _args.has("mark"):
			var mark: PackedStringArray = _args["mark"].split(":")
			if mark.size() == 2:
				Game.set_day_mark(mark[0], mark[1])
		Atmosphere.forced_weather = _args.get("weather", "")
		Atmosphere.forced_season = _args.get("season", "")
		if _args.has("fps"):
			Engine.max_fps = int(_args["fps"])
	WindowModes.restore(Game.state)
	Atmosphere.start()


func _process(delta: float) -> void:
	if WindowModes.in_widget or _jar == null:
		return
	var view := get_viewport().get_visible_rect().size
	var mouse_position := get_viewport().get_mouse_position()
	# La vraie souris ne compte pas pendant un essai avec capture, ni hors de la fenêtre.
	var mouse_counts := _mouse_inside and not _scripted
	if mouse_counts:
		_mouse = (mouse_position / view * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)
	if not _closeups.is_open():
		_room_mouse = _mouse
		if not _scripted:
			# Balayage : la souris près d'un bord, ou les touches.
			var push := 0.0
			if mouse_counts:
				if mouse_position.x < Layout.PAN_EDGE:
					push -= 1.0 - maxf(mouse_position.x, 0.0) / Layout.PAN_EDGE
				elif mouse_position.x > view.x - Layout.PAN_EDGE:
					push += 1.0 - maxf(view.x - mouse_position.x, 0.0) / Layout.PAN_EDGE
			if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
				push -= 1.0
			if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
				push += 1.0
			if push != 0.0:
				_pan_target = clampf(_pan_target + push * Layout.PAN_SPEED * delta, 0.0, _max_pan())
	if absf(_pan - _pan_target) > 0.05:
		_pan = lerpf(_pan, _pan_target, minf(1.0, delta * 10.0))
	_place_planes(_room_mouse)

	if _jar_place == JarPlace.COUNTER:
		_jar.parallax = Vector2.ZERO
		# Le bas du bocal reste posé sur le dessus du comptoir.
		var top := Layout.TABLE_Y - _jar.counter_line()
		if absf(_jar.position.y - top) > 0.05:
			_jar.position.y = top
	elif _jar_place == JarPlace.CLOSEUP:
		_jar.parallax = _mouse
		# Le comptoir du gros plan suit le pied du bocal, que la parallaxe déplace un peu.
		var line := _jar.position.y + _jar.counter_line()
		if absf(_closeup_counter.position.y - line) > 0.05 or absf(_closeup_counter.size.x - view.x) > 0.05:
			_closeup_counter.position = Vector2(0.0, line)
			_closeup_counter.size = Vector2(view.x, maxf(0.0, view.y - line))


## Un clic droit referme le gros plan ouvert, où qu'il tombe.
func _input(event: InputEvent) -> void:
	if _scripted and event is InputEventMouse and not event.has_meta(&"essai"):
		# Pendant un essai, la vraie souris ne doit pas se mêler des gestes joués par le script.
		get_viewport().set_input_as_handled()
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_RIGHT \
			and _closeups != null and _closeups.is_open() and not WindowModes.in_widget:
		_closeups.close()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _jar == null:
		return
	if key.ctrl_pressed and key.shift_pressed:
		match key.keycode:
			KEY_H:
				Game.set_discreet(not Game.state.discreet)
			KEY_M:
				WindowModes.toggle()
		return
	match key.keycode:
		KEY_ESCAPE:
			if _closeups.is_open():
				_closeups.close()
			elif WindowModes.in_widget:
				WindowModes.show_home()
		KEY_W:
			WindowModes.toggle()
		KEY_M:
			Game.set_sound_enabled(not Game.state.sound_enabled)
		KEY_SPACE:
			if _jar_place != JarPlace.COUNTER or _closeups.current == Prop.JAR:
				_jar.shake()


# --- Construction ---

func _add_plane(decor_kind: Decor.Kind, scroll_factor: float, mouse_shift: float) -> ParallaxPlane:
	var plane := ParallaxPlane.new()
	plane.scroll_factor = scroll_factor
	plane.mouse_shift = mouse_shift
	_world.add_child(plane)
	var decor := Decor.new()
	decor.kind = decor_kind
	plane.add_child(decor)
	return plane


## Pluie et neige : elles tombent dehors, et ne se voient que par la fenêtre et la porte.
func _build_weather() -> void:
	var streak := Image.create(3, 28, false, Image.FORMAT_RGBA8)
	streak.fill(Color.WHITE)
	_rain = CPUParticles2D.new()
	_rain.texture = ImageTexture.create_from_image(streak)
	_rain.amount = 320
	_rain.lifetime = 0.8
	_rain.preprocess = 0.8
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = WEATHER_EXTENTS
	_rain.position = WEATHER_ORIGIN
	_rain.direction = Vector2(0.12, 1.0)
	_rain.spread = 2.0
	_rain.gravity = Vector2.ZERO
	_rain.initial_velocity_min = 1150.0
	_rain.initial_velocity_max = 1350.0
	_rain.color = Color(0.86, 0.90, 0.98, 0.55)
	_rain.emitting = false
	_outside.add_child(_rain)

	_snow = CPUParticles2D.new()
	_snow.texture = Decor.glow_texture()
	_snow.amount = 180
	_snow.lifetime = 7.0
	_snow.preprocess = 7.0
	_snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_snow.emission_rect_extents = WEATHER_EXTENTS
	_snow.position = WEATHER_ORIGIN
	_snow.direction = Vector2(0.05, 1.0)
	_snow.spread = 12.0
	_snow.gravity = Vector2.ZERO
	_snow.initial_velocity_min = 110.0
	_snow.initial_velocity_max = 170.0
	_snow.scale_amount_min = 0.10
	_snow.scale_amount_max = 0.20
	_snow.color = Color(1.0, 1.0, 1.0, 0.95)
	_snow.emitting = false
	_outside.add_child(_snow)


## L'ardoise du comptoir : ce qui est tombé aujourd'hui, et ce que contient le bocal.
func _build_slate() -> void:
	var style := Paper.flat(Color(0.17, 0.17, 0.16), Decor.WOOD, 10, 6)
	_slate = Panel.new()
	_slate.add_theme_stylebox_override("panel", style)
	_slate.position = Layout.SLATE.position
	_slate.size = Layout.SLATE.size
	_slate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room.add_child(_slate)
	var caption := Paper.label("Aujourd'hui", 20, CHALK)
	caption.position = Vector2(24.0, 14.0)
	_slate.add_child(caption)
	_slate_amount = Paper.label("0,00 €", 44, CHALK)
	_slate_amount.position = Vector2(22.0, 34.0)
	_slate.add_child(_slate_amount)
	_slate_jar = Paper.label("", 17, CHALK)
	_slate_jar.position = Vector2(24.0, 110.0)
	_slate.add_child(_slate_jar)


## Le plan des gros plans, avec ce qui accompagne le bocal quand on le regarde de près.
func _build_closeups() -> void:
	_closeups = CloseupLayer.new()
	add_child(_closeups)
	_closeups.closed.connect(_on_closeup_closed)
	# Le comptoir vu de près : il passe sous le bocal.
	var wood := StyleBoxFlat.new()
	wood.bg_color = Decor.WOOD
	wood.border_color = Decor.WOOD_LIGHT
	wood.border_width_top = 18
	_closeup_counter = Panel.new()
	_closeup_counter.add_theme_stylebox_override("panel", wood)
	_closeup_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_closeup_counter.visible = false
	_closeups.add_child(_closeup_counter)
	_jar_label = Paper.label("", 30, Paper.PAPER)
	_jar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_jar_label.visible = false
	_closeups.add_child(_jar_label)


func _build_props() -> void:
	_add_prop(Prop.PAY_SHEET, Layout.PAY_SHEET)
	_add_prop(Prop.WIDGET_FRAME, Layout.WIDGET_FRAME)
	_add_prop(Prop.WORK_SIGN, Layout.WORK_SIGN)
	_add_prop(Prop.CALENDAR, Layout.CALENDAR)
	_add_prop(Prop.BAROMETER, Layout.BAROMETER)
	_add_prop(Prop.TILL, Layout.TILL)


func _add_prop(kind: String, rect: Rect2) -> Prop:
	var prop := Prop.new()
	prop.kind = kind
	prop.position = rect.position
	prop.size = rect.size
	prop.activated.connect(_on_prop_activated)
	_room.add_child(prop)
	_props[kind] = prop
	return prop


func _build_jar(textures: Dictionary, illustrated: Array[int]) -> void:
	_jar = JarView.new()
	_jar.setup(textures, illustrated, Game.state.jar.size)
	_jar.position = Layout.JAR_SPOT.position
	_jar.size = Layout.JAR_SPOT.size
	_room.add_child(_jar)
	# Le verre est rattaché au bocal : il le suit dans le gros plan et dans le widget.
	var back_glass := JarGlass.new()
	back_glass.is_back = true
	back_glass.show_behind_parent = true
	back_glass.jar = _jar
	_jar.add_child(back_glass)
	var front_glass := JarGlass.new()
	front_glass.jar = _jar
	_jar.add_child(front_glass)
	_jar.show_composition(Game.state.jar.composition)

	# Sur le comptoir, un clic sur le bocal l'ouvre en gros plan ; le faire glisser le secoue sur place.
	var hit := _add_prop(Prop.JAR, Rect2(Layout.JAR_SPOT.position + JAR_HIT_AREA.position, JAR_HIT_AREA.size))
	hit.drag_threshold = JAR_DRAG_PIXELS
	hit.mouse_entered.connect(func() -> void: _jar.self_modulate = Prop.HOVER_TINT)
	hit.mouse_exited.connect(func() -> void: _jar.self_modulate = Color.WHITE)
	hit.grabbed.connect(func(_kind: String, at: Vector2) -> void: _jar.grab_jar_at(_in_jar(at)))
	hit.dragged.connect(func(_kind: String, at: Vector2) -> void: _jar.drag_to(_in_jar(at)))
	hit.dropped.connect(func(_kind: String) -> void: _jar.release())
	_jar.merged_by_hand.connect(_on_merged_by_hand)
	_place_jar(JarPlace.COUNTER)


## Un point de l'écran, vu du bocal.
func _in_jar(at: Vector2) -> Vector2:
	return _jar.get_global_transform().affine_inverse() * at


## Petite image de la pièce de 1 € pour la zone de notification.
func _tray_icon(face: Texture2D) -> Texture2D:
	var image := face.get_image()
	if image.is_compressed():
		image.decompress()
	image.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


# --- Balayage et plans ---

## Largeur de maison visible à l'écran, en coordonnées du décor.
func _view_width() -> float:
	return get_viewport().get_visible_rect().size.x / _world.scale.x


func _max_pan() -> float:
	return maxf(0.0, Layout.WORLD_SIZE.x - _view_width())


## La maison remplit toujours la hauteur de la fenêtre : sur un écran moins allongé que le 16:9,
## elle est agrandie, et on en voit simplement un peu moins large.
func _fit_view() -> void:
	if WindowModes.in_widget:
		return
	var view := get_viewport().get_visible_rect().size
	_world.scale = Vector2.ONE * maxf(1.0, view.y / Layout.WORLD_SIZE.y)
	_place_planes(_room_mouse)
	if _jar != null and _jar_place == JarPlace.CLOSEUP:
		_place_jar(JarPlace.CLOSEUP)


func _place_planes(mouse: Vector2) -> void:
	# Le balayage voulu est gardé tel quel : une fenêtre plus large le borne sans l'oublier, et il
	# revient quand elle rétrécit (au retour du widget, par exemple).
	var pan := clampf(_pan, 0.0, _max_pan())
	for plane: ParallaxPlane in [_outside, _room, _lights, _front]:
		if plane != null:
			plane.place(pan, mouse)


func _on_sky_changed() -> void:
	# En widget, la maison est cachée : la pluie et la neige s'arrêtent, pour ne rien redessiner.
	_rain.emitting = Atmosphere.weather == Weather.RAIN and not WindowModes.in_widget
	_snow.emitting = Atmosphere.weather == Weather.SNOW and not WindowModes.in_widget
	_rain.modulate = Atmosphere.outside_tint.lerp(Color.WHITE, 0.5)
	_snow.modulate = Atmosphere.outside_tint.lerp(Color.WHITE, 0.5)
	var prop_light := Atmosphere.room_tint.lerp(Color.WHITE, PROP_OWN_LIGHT)
	for prop: Prop in _props.values():
		prop.self_modulate = prop_light
	_slate.modulate = Atmosphere.room_tint.lerp(Color.WHITE, JAR_OWN_LIGHT)
	_light_jar()


## Sur le comptoir, le bocal prend la lumière de la pièce ; en gros plan et en widget, il est en pleine lumière.
func _light_jar() -> void:
	if _jar != null:
		_jar.modulate = Atmosphere.room_tint.lerp(Color.WHITE, JAR_OWN_LIGHT) if _jar_place == JarPlace.COUNTER else Color.WHITE


# --- Le bocal, d'une place à l'autre ---

## Pose le bocal sur le comptoir, l'agrandit en gros plan, ou l'installe dans le widget.
func _place_jar(place: JarPlace) -> void:
	if _jar.is_holding():
		_jar.release()
	_jar_place = place
	var parent: Node = _room
	var rect := Layout.JAR_SPOT
	if place == JarPlace.CLOSEUP:
		parent = _closeups
		rect = Layout.closeup_jar(get_viewport().get_visible_rect().size)
		_jar_label.position = Vector2(rect.position.x, rect.end.y + 6.0)
		_jar_label.size = Vector2(rect.size.x, 50.0)
	elif place == JarPlace.WIDGET:
		parent = _widget
		rect = _widget.jar_rect()
	if _jar.get_parent() != parent:
		_jar.reparent(parent, false)
	_jar.position = rect.position
	_jar.size = rect.size
	_jar.compact = place == JarPlace.WIDGET
	_jar.self_modulate = Color.WHITE
	_light_jar()
	# Sur le comptoir, c'est l'objet cliquable posé par-dessus qui répond, pas le bocal lui-même.
	# Dans le widget, ce que le bocal ne prend pas (clic droit, molette, appui dans le vide) revient
	# au widget : changer de format, d'opacité, déplacer la fenêtre.
	match place:
		JarPlace.COUNTER:
			_jar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		JarPlace.WIDGET:
			_jar.mouse_filter = Control.MOUSE_FILTER_PASS
		_:
			_jar.mouse_filter = Control.MOUSE_FILTER_STOP
	(_props[Prop.JAR] as Prop).visible = place == JarPlace.COUNTER
	_closeup_counter.visible = place == JarPlace.CLOSEUP
	_jar_label.visible = place == JarPlace.CLOSEUP


func _on_jar_changed(ops: Array[Dictionary]) -> void:
	_ops_applied += ops.size()
	_jar.apply_ops(ops)
	if _jar.content() != Game.state.jar.composition:
		push_warning("Le bocal affiché ne correspond plus au modèle : il est refait.")
		_jar.show_composition(Game.state.jar.composition)
	_refresh()


## La joueuse vient de fusionner des coupures à la main : l'état du jeu en prend acte.
func _on_merged_by_hand(inputs: Array[int], outputs: Array[int]) -> void:
	if not Game.exchange_in_jar(inputs, outputs):
		push_warning("Fusion à la main refusée par l'état du jeu : le bocal affiché est refait.")
		_jar.show_composition(Game.state.jar.composition)
	_refresh()


## Pendant une pluie de pièces (lancement, rattrapage), les tintements sont adoucis.
func _on_object_landed(value: int, strength: float) -> void:
	_sounds.play_landing(value, strength * (0.35 if _jar.queued_count() > 12 else 1.0))


# --- Objets et gros plans ---

## Un clic sur un objet : le chevalet pointe l'arrivée ou le départ, les autres s'ouvrent en gros plan.
func _on_prop_activated(kind: String) -> void:
	if kind == Prop.WORK_SIGN:
		Game.set_clocked_in(not Game.state.payroll.is_clocked_in())
	else:
		_open_closeup(kind)


func _open_closeup(kind: String) -> void:
	if WindowModes.in_widget:
		return
	match kind:
		Prop.PAY_SHEET:
			var sheet := PaySheet.new()
			_closeups.open(kind, sheet)
			sheet.show_values(Game.state.payroll.net_monthly_cents, Game.state.payroll.schedule, Game.state.payroll.manual_clocking)
			sheet.saved.connect(_on_pay_saved)
			sheet.closed.connect(_closeups.close)
			_pay_sheet = sheet
		Prop.CALENDAR:
			_closeups.open(kind, CalendarCloseup.new())
		Prop.BAROMETER:
			_closeups.open(kind, BarometerCloseup.new())
		Prop.WIDGET_FRAME:
			_closeups.open(kind, WidgetFrameCloseup.new())
		Prop.TILL:
			var receipt := TicketCloseup.new()
			receipt.ticket = Game.state.evening_ticket(Clock.now_local())
			receipt.discreet = Game.state.discreet
			_closeups.open(kind, receipt)
			if not receipt.ticket.is_empty():
				Game.mark_ticket_seen(receipt.ticket["day"])
			_refresh()
		Prop.JAR:
			_closeups.open(kind, null)
			_place_jar(JarPlace.CLOSEUP)
			_closeups.move_child(_jar_label, -1)
			_refresh()


func _on_closeup_closed(kind: String) -> void:
	# Le bocal retourne toujours sur le comptoir, même si la fenêtre passe en widget : c'est de là
	# qu'il repartira, vers le mini-bocal ou à la réouverture de la maison.
	if kind == Prop.JAR and _jar_place == JarPlace.CLOSEUP:
		_place_jar(JarPlace.COUNTER)


func _on_pay_saved(net_monthly_cents: int, schedule_values: Dictionary) -> void:
	Game.set_pay(net_monthly_cents, schedule_values)
	_closeups.close()


# --- Ce qui s'affiche ---

## Un montant tel qu'il doit s'afficher : masqué en mode discret.
func _shown(cents: int) -> String:
	return HIDDEN_AMOUNT if Game.state.discreet else Denominations.format_cents(cents)


func _refresh() -> void:
	var state := Game.state
	var now := Clock.now_local()
	var today := _shown(state.payroll.earned_today())
	_slate_amount.text = today
	_slate_jar.text = "Dans le bocal : %s" % _shown(state.jar.cents())
	if not state.payroll.is_configured():
		# Rien ne tombe sans salaire : l'ardoise dit où le régler.
		_slate_jar.text = "À régler : la fiche de paie"
	_jar_label.text = "Dans le bocal : %s" % _shown(state.jar.cents())
	_widget.amount_text = today
	_widget.ring_progress = 0.0
	_sounds.enabled = state.sound_enabled
	WindowModes.set_tray_tooltip("MoneyMaker — aujourd'hui : %s" % today)

	var ticket := state.evening_ticket(now)
	(_props[Prop.TILL] as Prop).has_ticket = not ticket.is_empty() and ticket["day"] != state.ticket_seen_day
	(_props[Prop.WIDGET_FRAME] as Prop).widget_format = WindowModes.format
	# Le chevalet suit l'horaire tout seul ; il ne se clique que si l'on pointe soi-même.
	var work_sign := _props[Prop.WORK_SIGN] as Prop
	work_sign.working = state.payroll.is_configured() and state.payroll.is_working_at(now)
	if work_sign.enabled != state.payroll.manual_clocking:
		work_sign.enabled = state.payroll.manual_clocking
	var day := GameCalendar.date_of(now)
	if day != _shown_day:
		_shown_day = day
		var calendar := _props[Prop.CALENDAR] as Prop
		calendar.day_number = GameCalendar.day_of_month(day)
		calendar.queue_redraw()


# --- Maison et widget ---

## La fenêtre vient de changer de visage, de format ou d'opacité : l'écran s'arrange.
func _on_window_mode_changed() -> void:
	var in_widget := WindowModes.in_widget
	var mini := in_widget and WindowModes.format == GameState.WIDGET_MINI_BOCAL
	if in_widget and _closeups.is_open():
		_closeups.close()
	_world.visible = not in_widget
	_widget.visible = in_widget
	if in_widget:
		_widget.size = Vector2(WindowModes.widget_size())
		_widget.format = WindowModes.format
		_widget.modulate.a = WindowModes.opacity
	else:
		_fit_view()
	if mini:
		_place_jar(JarPlace.WIDGET)
	elif _jar_place == JarPlace.WIDGET:
		_place_jar(JarPlace.COUNTER)
	# En pastille et en bandeau, le bocal est en pause : ce qui est gagné attend et tombera au retour.
	_jar.set_simulating(not in_widget or mini)
	_on_sky_changed()
	_refresh()


# --- Capture et rapport (essais) ---

## Envoie au jeu un appui ou un relâchement de souris en `at` (coordonnées de l'écran), comme le
## ferait le système : l'événement suit tout le chemin d'un vrai clic.
func _mouse_button(at: Vector2, pressed: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed and button == MOUSE_BUTTON_LEFT else 0
	event.set_meta(&"essai", true)
	get_viewport().push_input(event, true)


## Fait glisser la souris, bouton enfoncé, de `from` à `to` en `seconds`.
func _mouse_glide(from: Vector2, to: Vector2, seconds: float) -> void:
	var steps := maxi(2, roundi(seconds * 60.0))
	var previous := from
	for i in range(1, steps + 1):
		var at := from.lerp(to, float(i) / steps)
		var event := InputEventMouseMotion.new()
		event.position = at
		event.global_position = at
		event.relative = at - previous
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		event.set_meta(&"essai", true)
		get_viewport().push_input(event, true)
		previous = at
		await get_tree().physics_frame


## Un point du bocal (coordonnées locales), à l'écran.
func _on_screen(local_point: Vector2) -> Vector2:
	return _jar.get_global_transform_with_canvas() * local_point


## Avec --snaps=<préfixe> : enregistre l'écran tel qu'il est, en plein geste.
func _snap(label: String) -> void:
	if not _args.has("snaps"):
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [_args["snaps"], label])


## Attrape une pièce d'une des valeurs de `values` et la fait glisser sur la plus proche de celles
## avec qui elle peut fusionner. Renvoie ce qui s'est passé.
func _merge_by_dragging(values: Array, snap_label: String) -> String:
	var tree := get_tree()
	var merges_before := _jar.hand_merges
	var tried: Array[String] = []
	for value in values:
		var points := _jar.local_points_of(value)
		if points.is_empty():
			continue
		# La pièce de cette valeur la plus proche du milieu du bocal : loin des parois, qui se saisissent.
		var middle := _jar.size / 2.0
		var best := points[0]
		for point in points:
			if absf(point.x - middle.x) < absf(best.x - middle.x):
				best = point
		var press := _on_screen(best)
		_mouse_button(press, true)
		await tree.physics_frame
		# La pièce visée peut être cachée par une autre : on fait avec celle que la main a prise.
		var held := _jar.held_value()
		tried.append("%s visée, %s prise" % [Denominations.label(value), Denominations.label(held) if held > 0 else "rien"])
		var target := Vector2.INF
		for other in Denominations.VALUES:
			if held == 0 or Denominations.hand_merge(held, other, Game.state.jar.composition).is_empty():
				continue
			for point in _jar.local_points_of(other):
				var candidate := _on_screen(point)
				if candidate.distance_to(press) > 30.0 and candidate.distance_to(press) < target.distance_to(press):
					target = candidate
		if target == Vector2.INF:
			_mouse_button(press, false)
			await tree.create_timer(0.3).timeout
			continue
		await _mouse_glide(press, target, 0.5)
		# Sur place, de petits va-et-vient, comme une main qui cherche le contact.
		var at := target
		for wiggle in 12:
			if _jar.hand_merges > merges_before:
				break
			var to := target + Vector2(26.0 if wiggle % 2 == 0 else -26.0, 14.0 if wiggle % 4 < 2 else -14.0)
			await _mouse_glide(at, to, 0.12)
			at = to
		await tree.create_timer(0.4).timeout
		await _snap(snap_label)
		var story := "pièce de %s glissée, %d fusion(s), en main ensuite : %s" % [
			Denominations.label(held), _jar.hand_merges - merges_before,
			Denominations.label(_jar.held_value()) if _jar.held_value() > 0 else "rien"]
		_mouse_button(at, false)
		await tree.create_timer(0.5).timeout
		if _jar.hand_merges > merges_before:
			return story
	return "rien n'a fusionné (%s)" % ", ".join(tried)


## Essai des gestes à la souris : secouer le bocal sur le comptoir, l'ouvrir d'un clic, y fusionner
## des pièces en les faisant glisser l'une sur l'autre, le saisir par une paroi, puis le clic droit
## à travers le mini-bocal. Renvoie ce qui a été constaté.
func _exercise_gestures() -> Array[String]:
	var seen: Array[String] = []
	var state := Game.state
	var tree := get_tree()
	# Pour les captures en plein geste, le moteur dessine en continu.
	OS.low_processor_usage_mode = not _args.has("snaps")

	# 1. Sur le comptoir : appuyer sur le bocal et le faire aller et venir.
	var prop := _props[Prop.JAR] as Prop
	var start := prop.get_global_transform_with_canvas() * (prop.size / 2.0)
	var widest := 0.0
	var most_awake := 0
	_mouse_button(start, true)
	var from := start
	for swing in [Vector2(70.0, -30.0), Vector2(-70.0, 0.0), Vector2(70.0, -40.0), Vector2(-70.0, 0.0), Vector2(0.0, 0.0)]:
		var to: Vector2 = start + swing
		await _mouse_glide(from, to, 0.12)
		from = to
		if _jar.jar_shift().length() > widest:
			await _snap("comptoir_secoue")
		widest = maxf(widest, _jar.jar_shift().length())
		most_awake = maxi(most_awake, _jar.awake_count())
	_mouse_button(from, false)
	seen.append("comptoir, bocal secoué : écart %.2f, %d objets réveillés, gros plan resté fermé : %s" % [
		widest, most_awake, not _closeups.is_open()])
	await tree.create_timer(1.5).timeout
	seen.append("bocal revenu à sa place : %s ; %d pièce(s) dehors ; physique à %d pas/s" % [
		_jar.jar_shift().is_zero_approx(), _jar.outside_count(), Engine.physics_ticks_per_second])

	# 2. Un clic sans bouger l'ouvre en gros plan.
	_mouse_button(start, true)
	await tree.physics_frame
	_mouse_button(start, false)
	await tree.create_timer(2.5).timeout
	seen.append("un clic ouvre le gros plan : %s" % (_closeups.current == Prop.JAR))
	if _closeups.current != Prop.JAR:
		return seen

	# 3. En gros plan : attraper une pièce, la faire glisser sur une semblable, garder la nouvelle en
	# main. D'abord une fusion à deux (1 € + 1 €), puis une fusion à trois (2 € + 2 € + 1 €).
	var cents_before := state.jar.cents()
	var objects_before := state.jar.object_count()
	seen.append("fusion à deux : " + await _merge_by_dragging([100, 50, 10, 5, 1], "fusion_a_deux"))
	seen.append("fusion à trois : " + await _merge_by_dragging([200, 20, 2], "fusion_a_trois"))
	seen.append("après fusions : même valeur : %s, objets %d -> %d, affichage conforme à l'état : %s" % [
		state.jar.cents() == cents_before, objects_before, state.jar.object_count(),
		_jar.content() == state.jar.composition])

	# 4. En gros plan : saisir le bocal par sa paroi droite et le secouer.
	var wall := _on_screen(_jar.local_point_of_wall(1.0))
	_mouse_button(wall, true)
	await tree.physics_frame
	var grip := "bocal saisi par la paroi : %s (rien en main : %s)" % [_jar.is_holding(), _jar.held_value() == 0]
	var reach := Vector2.ZERO
	from = wall
	for swing in [Vector2(-160.0, -120.0), Vector2(140.0, -40.0), Vector2(-160.0, -140.0), Vector2(150.0, 0.0)]:
		var to: Vector2 = wall + swing
		await _mouse_glide(from, to, 0.14)
		from = to
		if _jar.jar_shift().abs().y > reach.y:
			await _snap("gros_plan_secoue")
		reach = reach.max(_jar.jar_shift().abs())
	_mouse_button(from, false)
	seen.append("%s, écart atteint : %.2f de côté, %.2f vers le haut" % [grip, reach.x, reach.y])
	await tree.create_timer(2.0).timeout
	var spilled := _jar.outside_count()
	seen.append("relâché, le bocal revient : %s ; affichage conforme : %s ; %d pièce(s) dehors" % [
		_jar.jar_shift().is_zero_approx(), _jar.content() == state.jar.composition, spilled])
	# Ce qui est tombé dehors retourne de soi-même dans le bocal, tant qu'il y a de la place.
	await tree.create_timer(3.5 + 0.9 * spilled).timeout
	await _snap("apres_rangement")
	seen.append("quelques secondes plus tard : %d pièce(s) dehors, %d objets, affichage conforme : %s" % [
		_jar.outside_count(), _jar.object_count(), _jar.content() == state.jar.composition])
	_closeups.close()
	await tree.create_timer(0.4).timeout

	# 5. En mini-bocal : un clic droit sur le bocal doit traverser jusqu'au widget (format suivant),
	# et déplacer la fenêtre doit remuer le contenu.
	WindowModes.show_widget(GameState.WIDGET_MINI_BOCAL)
	await tree.create_timer(2.0).timeout
	var asleep := _jar.awake_count()
	for _i in 6:
		_jar.sway(Vector2(40.0, 0.0))
		await tree.physics_frame
	seen.append("mini-bocal, fenêtre déplacée : %d objets réveillés (%d avant)" % [_jar.awake_count(), asleep])
	var middle := Vector2(WindowModes.widget_size()) * Vector2(0.5, 0.35)
	_mouse_button(middle, true, MOUSE_BUTTON_RIGHT)
	await tree.physics_frame
	_mouse_button(middle, false, MOUSE_BUTTON_RIGHT)
	await tree.create_timer(0.6).timeout
	seen.append("mini-bocal, clic droit sur le bocal : format devenu %s" % WindowModes.format)
	WindowModes.show_home()
	await tree.create_timer(1.0).timeout
	OS.low_processor_usage_mode = true
	return seen


func _capture_and_quit() -> void:
	var delay := float(_args.get("shot-delay", "6"))
	await get_tree().create_timer(delay).timeout

	var visited: Array[String] = []
	var state := Game.state
	var watched := {}
	if _args.has("watch"):
		# Regarde le bocal vivre un moment : part du temps où il simule, opérations reçues.
		var seconds := maxf(1.0, float(_args["watch"]))
		var busy_before := _jar.busy_seconds
		var ops_before := _ops_applied
		await get_tree().create_timer(seconds).timeout
		watched = {
			"secondes": seconds,
			"part_du_temps_occupe": snappedf((_jar.busy_seconds - busy_before) / seconds, 0.01),
			"operations": _ops_applied - ops_before,
		}
	var cities: Array[String] = []
	if _args.has("search"):
		# Cherche une ville comme le ferait le baromètre, et attend la réponse du service.
		Atmosphere.cities_found.connect(func(results: Array[Dictionary]) -> void:
			for city in results:
				cities.append("%s (%s) %.1f, %.1f" % [city["name"], city["region"], city["latitude"], city["longitude"]]))
		Atmosphere.search_city(_args["search"])
		await get_tree().create_timer(4.0).timeout
	if _args.has("blank") and is_instance_valid(_pay_sheet):
		# Pour voir ce que dit la fiche quand on l'enregistre sans salaire.
		_pay_sheet.show_values(0, state.payroll.schedule)
		_pay_sheet.save()
	if _args.has("gestures"):
		visited.append_array(await _exercise_gestures())
	if _args.has("tour"):
		for kind in [Prop.PAY_SHEET, Prop.CALENDAR, Prop.BAROMETER, Prop.WIDGET_FRAME, Prop.TILL, Prop.JAR]:
			_open_closeup(kind)
			await get_tree().create_timer(0.6).timeout
			visited.append("%s ouvert : %s" % [kind, _closeups.current == kind])
			if kind == Prop.PAY_SHEET:
				# La fiche relit ce qu'elle affiche, puis refuse d'enregistrer une feuille sans salaire.
				var read := _pay_sheet.read_values()
				visited.append("fiche relue : %s" % (read["problem"] if read.has("problem") else "%d c, %s" % [read["net_monthly_cents"], JSON.stringify(read["schedule_values"])]))
				_pay_sheet.show_values(0, state.payroll.schedule)
				_pay_sheet.save()
				visited.append("fiche vide refusée : %s" % (_closeups.current == kind and state.payroll.net_monthly_cents > 0))
			_closeups.close()
			await get_tree().create_timer(0.3).timeout
		visited.append("bocal revenu sur le comptoir : %s" % (_jar.get_parent() == _room))
		WindowModes.show_widget(GameState.WIDGET_MINI_BOCAL)
		await get_tree().create_timer(1.0).timeout
		visited.append("mini-bocal : bocal dans %s" % _jar.get_parent().name)
		WindowModes.show_home()
		await get_tree().create_timer(1.0).timeout
		visited.append("retour : bocal dans le plan de la pièce : %s" % (_jar.get_parent() == _room))
		# Passer en widget pendant que le bocal est en gros plan ne doit pas l'égarer.
		_open_closeup(Prop.JAR)
		await get_tree().create_timer(0.4).timeout
		WindowModes.show_widget(GameState.WIDGET_BANDEAU)
		await get_tree().create_timer(0.8).timeout
		WindowModes.show_home()
		await get_tree().create_timer(0.8).timeout
		visited.append("gros plan puis widget puis maison : bocal sur le comptoir : %s" % (_jar.get_parent() == _room and _jar_place == JarPlace.COUNTER))

	var report := {
		"parcours": visited,
		"ambiance": Atmosphere.ambience,
		"hauteur_du_soleil": snappedf(Atmosphere.sun_elevation, 0.1),
		"lampes": snappedf(Atmosphere.lamps, 0.01),
		"meteo": Atmosphere.weather,
		"saison": Atmosphere.season,
		"ville": state.city_name if state.has_city else "",
		"meteo_relevee": state.last_weather if state.last_weather_at > 0 else "",
		"villes_trouvees": cities,
		"bocal_observe": watched,
		"balayage": roundi(_pan),
		"gros_plan": _closeups.current,
		"aujourd_hui": _shown(state.payroll.earned_today()),
		"bocal": "%s (%s), cible %d" % [_shown(state.jar.cents()), state.jar.size, state.jar.target_count()],
		"objets": _jar.object_count(),
		"en_mouvement": _jar.awake_count(),
		"conforme_au_modele": _jar.content() == state.jar.composition,
		"ticket_en_attente": (_props[Prop.TILL] as Prop).has_ticket,
		"chevalet": "%s%s" % ["au travail" if (_props[Prop.WORK_SIGN] as Prop).working else "au repos", ", cliquable" if (_props[Prop.WORK_SIGN] as Prop).enabled else ""],
		"jour_en_cours": state.payroll.open_day,
		"marques": state.payroll.day_marks,
		"sons_joues": _sounds.plays,
	}

	# En mode économie, le moteur ne redessine que si quelque chose change : pour la capture,
	# on le remet en dessin continu.
	OS.low_processor_usage_mode = false
	_widget.queue_redraw()
	_slate_amount.queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_args["shot"])
	report["fenetre"] = "%s à %s" % [get_window().size, get_window().position]
	print("RAPPORT ", JSON.stringify(report))
	get_tree().quit()
