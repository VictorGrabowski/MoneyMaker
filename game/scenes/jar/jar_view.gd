## Le bocal en 2.5D : pièces et billets sont de vrais volumes, dessinés à plat sur leurs faces,
## rendus dans une vignette posée dans le décor 2D.
##
## - Le monde est une tranche mince (DEPTH) : les objets s'y recouvrent et s'y inclinent, mais
##   restent tournés vers la joueuse.
## - Le bocal est ouvert et posé sur un comptoir : trop plein, il déborde pour de bon.
## - La scène joue les opérations du modèle (core/money/jar.gd). Elle ne décide que d'une chose :
##   les fusions que la joueuse fait à la main, qu'elle annonce par `merged_by_hand`.
##
## Ce qu'on peut y faire à la souris :
## - attraper une pièce, la lancer ;
## - la faire glisser sur ses semblables : elles fusionnent, et la nouvelle reste en main ;
## - saisir le bocal par une paroi (ou par un vide) et le secouer ;
## - cliquer dans le vide : tapoter la vitre.
extends SubViewportContainer

const Denominations := preload("res://core/money/denominations.gd")
const Jar := preload("res://core/money/jar.gd")
const MoneyFaces := preload("res://scenes/jar/money_faces.gd")
const ART_FACE_SHADER := preload("res://scenes/jar/art_face.gdshader")

## Un objet vient de toucher quelque chose. `strength` : de 0 (frôlement) à 1 (chute franche).
signal object_landed(value: int, strength: float)
## Des coupures viennent de fusionner en `output`, ou une coupure de se casser.
signal objects_changed(output: int)
## La joueuse vient de fusionner des coupures à la main : `inputs` sont devenues `outputs`.
## La scène l'a déjà joué ; au modèle d'en prendre acte.
signal merged_by_hand(inputs: Array[int], outputs: Array[int])

## Intérieur du bocal par taille : largeur et hauteur, en unités (1 unité ≈ 3 cm).
## Réglé pour qu'un bocal plein (Jar.FULL_OBJECTS) arrive au bord.
const INTERIOR: Dictionary = {
	Jar.SIZE_POT: Vector2(3.7, 3.25),
	Jar.SIZE_BOCAL: Vector2(4.8, 4.4),
	Jar.SIZE_BONBONNE: Vector2(5.9, 5.4),
}
const DEPTH := 0.42
const GLASS := 0.14
const SLAB_WALL := 1.0
## Comptoir de chaque côté du bocal, où roulent les pièces qui débordent.
const COUNTER_REACH := 2.0
## Espace au-dessus du bord, pour voir tomber les pièces.
const HEADROOM := 3.0
const COMPACT_HEADROOM := 1.5

const COIN_THICKNESS := 0.10
const BILL_THICKNESS := 0.035
## Rayon du dessin dans sa texture : faces provisoires (money_face.gdshader) et illustrations.
const FACE_FILL := 0.93
## Les prompts demandent une coupure qui occupe 92 % de son image (art-direction.md).
const ART_FILL := 0.92
## Diamètres proportionnels aux vraies pièces.
const COIN_DIAMETER: Dictionary = {
	1: 0.50, 2: 0.58, 5: 0.66, 10: 0.61, 20: 0.69, 50: 0.75, 100: 0.72, 200: 0.80,
}
## Billets représentés pliés : plus petits que nature pour rester lisibles à côté des pièces.
const BILL_SIZE: Dictionary = {
	500: Vector2(1.50, 0.78), 1000: Vector2(1.59, 0.84), 2000: Vector2(1.66, 0.90),
	5000: Vector2(1.75, 0.96), 10000: Vector2(1.84, 1.02), 20000: Vector2(1.91, 1.02),
	50000: Vector2(2.00, 1.02),
}
const INGOT_SIZE := Vector3(1.30, 0.55, 0.34)
const GEM_SIZE := Vector3(0.70, 0.70, 0.34)

const LAYER_WALLS := 1
const LAYER_OBJECTS := 2

const FOV := 22.0
const CAMERA_PARALLAX := Vector2(0.9, 0.45)
const DROPS_PER_SECOND := 40.0
## Durée maximale de la pluie quand il y a beaucoup à faire tomber (rattrapage, lancement).
const RAIN_SECONDS := 8.0
const GRAB_STIFFNESS := 18.0
const GRAB_MAX_SPEED := 45.0
const MERGE_SECONDS := 0.18
const CUSHION_SECONDS := 0.15

## Fusion à la main : la coupure tenue fusionne avec une semblable qu'elle touche, une fois que la
## main a parcouru ce trajet (attraper n'est pas fusionner) et après cette pause entre deux fusions.
const HAND_MERGE_TRAVEL := 0.35
const HAND_MERGE_PAUSE := 0.28
## Contacts suivis pour la coupure tenue (un seul suffit aux autres, pour leur tintement).
const HELD_CONTACTS := 8

## Le bocal saisi suit la main dans ces limites, de chaque côté et vers le haut (en unités)…
const JAR_SWAY := Vector2(0.8, 1.0)
## … à cette vitesse au plus (unités par seconde) : assez pour brasser, pas assez pour tout vider.
## Mesuré sur un Pot plein : à 12 de côté et 7 vers le haut, une secousse d'une demi-seconde en
## jetait 55 pièces sur 88 par-dessus bord.
const JAR_SPEED := Vector2(7.0, 4.5)
const JAR_RETURN_SPEED := 6.0
## Pas de physique par seconde tant que le bocal bouge. À 60, une pièce en l'air et une paroi qui
## vient à sa rencontre se croisent en un seul pas : la pièce se retrouve dehors, à travers le verre.
const SHAKE_TICKS := 180

## Une pièce tombée hors du bocal y retourne d'elle-même après ce temps au repos, tant que le tas
## reste sous ce niveau (1.0 = au bord) : au-delà, le bocal déborde pour de bon et elle reste dehors.
const TIDY_AFTER := 3.0
const TIDY_PERIOD := 0.5
const TIDY_BELOW := 0.8
## Fond du bocal, et jupe des parois sous le fond : rien ne roule sous un bocal soulevé.
const JAR_FLOOR := 0.4
const JAR_SKIRT := 1.4
## De part et d'autre d'une paroi, c'est le bocal qu'on saisit, pas la pièce qui s'y appuie.
const JAR_GRIP_BAND := 0.22
## Trajet de la main à partir duquel un appui sur le bocal devient une saisie (sinon : un tapotement).
const JAR_DRAG_START := 0.10

## Widget déplacé : part du mouvement de la fenêtre que le contenu ressent, et plafond par image.
const SWAY_GAIN := 0.5
const SWAY_MAX := Vector2(7.0, 5.0)

## Garde de mise au repos : un objet resté lent pendant CALM_AFTER est fortement amorti, pour qu'il
## s'arrête au lieu de vibrer et de tenir tout le tas éveillé.
const GUARD_PERIOD := 0.25
const CALM_SPEED := 0.6
const CALM_SPIN := 2.0
const CALM_AFTER := 1.0
const DAMP_NORMAL := Vector2(0.05, 0.6)
const DAMP_CALMING := Vector2(4.0, 8.0)

## Décalage de la souris par rapport au centre de l'écran, de -1 à 1.
var parallax := Vector2.ZERO
## Cadrage serré sur le bocal, sans le comptoir : pour le widget.
var compact := false:
	set(value):
		compact = value
		if is_inside_tree():
			_frame()

var _textures: Dictionary = {}
var _illustrated: Array[int] = []
var _size := Jar.SIZE_POT
var _viewport: SubViewport
var _camera: Camera3D
var _walls: StaticBody3D
var _objects: Node3D
var _object_physics: PhysicsMaterial
var _mesh_cache: Dictionary = {}
var _camera_home := Vector3(0.0, 4.0, 20.0)
var _camera_target := Vector3(0.0, 3.0, 0.0)
var _camera_offset := Vector2.ZERO

## Coupures qui attendent de tomber, et coupures qui apparaîtront à la fin d'une fusion.
var _queue: Array[int] = []
var _pending: Array[int] = []
var _drop_rate := DROPS_PER_SECOND
var _drop_budget := 0.0
## Change à chaque remise à zéro : les apparitions programmées avant ne comptent plus.
var _generation := 0
var _simulating := true
var _guard_in := GUARD_PERIOD
var _was_busy := true
## Une image de plus est demandée (cadrage, taille ou contenu changés).
var _redraw_requested := true
## Temps passé à simuler et redessiner depuis le lancement, en secondes : pour mesurer ce que coûte le bocal.
var busy_seconds := 0.0

## Le bocal lui-même (fond et parois), qui suit la main quand on le secoue.
var _jar_body: AnimatableBody3D
var _jar_offset := Vector3.ZERO
## Vrai : le bocal suit la main. `_jar_candidate` : appui sur le bocal, sans mouvement encore.
var _jar_held := false
var _jar_candidate := false
## Écart entre la main et le bocal à la saisie, et point de l'appui (pour le tapotement).
var _jar_grip := Vector3.ZERO
var _press_point := Vector3.ZERO
## Vrai tant que la physique tourne à SHAKE_TICKS ; et la cadence à rétablir ensuite.
var _fine_physics := false
var _usual_ticks := 60
## Temps avant de ranger la prochaine pièce tombée dehors.
var _tidy_in := TIDY_PERIOD

## La souris en coordonnées locales, tenue à jour par les événements reçus ; et si son bouton est enfoncé.
var _pointer := Vector2.ZERO
var _pointer_down := false
var _grabbed: RigidBody3D = null
var _grab_depth := 0.0
## Trajet de la main depuis la saisie ou la dernière fusion, et pause avant la fusion suivante.
var _grab_travel := 0.0
var _grab_last := Vector3.ZERO
var _merge_pause := 0.0
## Fusions à la main depuis le lancement (pour les essais).
var hand_merges := 0

## Coupures en attente d'apparition qu'une autre opération a déjà consommées.
var _cancelled: Array[int] = []
## Déplacement de la fenêtre depuis le dernier pas de physique (widget), et sa vitesse lissée.
var _frame_shift := Vector2.ZERO
var _frame_velocity := Vector2.ZERO


## À appeler avant d'ajouter la scène à l'arbre.
func setup(textures: Dictionary, illustrated: Array[int], jar_size: String) -> void:
	_textures = textures
	_illustrated = illustrated
	_size = jar_size if INTERIOR.has(jar_size) else Jar.SIZE_POT


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 0.95, 0.88)
	environment.ambient_light_energy = 0.55
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.80)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	_viewport.add_child(sun)

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.near = 1.0
	_camera.far = 90.0
	_viewport.add_child(_camera)

	_object_physics = PhysicsMaterial.new()
	_object_physics.friction = 0.55
	_object_physics.bounce = 0.12

	_objects = Node3D.new()
	_viewport.add_child(_objects)
	_build_walls()
	_frame()
	resized.connect(_frame)


func _process(delta: float) -> void:
	if not _simulating:
		return
	var camera_moving := _camera_offset.distance_to(parallax) > 0.002
	if camera_moving:
		_camera_offset = _camera_offset.lerp(parallax, minf(1.0, delta * 6.0))
		_place_camera()

	_drop_budget = minf(_drop_budget + _drop_rate * delta, 4.0)
	while _drop_budget >= 1.0 and not _queue.is_empty():
		_spawn_falling(_queue.pop_back())
		_drop_budget -= 1.0
	if _queue.is_empty():
		_drop_rate = DROPS_PER_SECOND

	# Le bocal n'est redessiné que si quelque chose y bouge : au repos, il ne coûte rien.
	var busy := camera_moving or _grabbed != null or _jar_held or not _jar_offset.is_zero_approx() \
			or not _pending.is_empty() or _is_anything_moving()
	if busy:
		busy_seconds += delta
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	elif _was_busy or _redraw_requested:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_was_busy = busy
	_redraw_requested = false


## Vrai tant qu'un objet tombe, roule ou disparaît.
func _is_anything_moving() -> bool:
	for child in _objects.get_children():
		if child.has_meta(&"leaving") or not (child as RigidBody3D).sleeping:
			return true
	return false


func _physics_process(delta: float) -> void:
	if not _simulating:
		return
	_move_jar(delta)
	_sway_with_the_frame(delta)
	if _grabbed != null:
		if not is_instance_valid(_grabbed) or _grabbed.has_meta(&"leaving"):
			_grabbed = null
		else:
			var target := _point_on_plane(_pointer, _grab_depth)
			_grab_travel += target.distance_to(_grab_last)
			_grab_last = target
			_grabbed.sleeping = false
			_grabbed.linear_velocity = ((target - _grabbed.global_position) * GRAB_STIFFNESS).limit_length(GRAB_MAX_SPEED)
			_merge_pause = maxf(0.0, _merge_pause - delta)
			if _merge_pause <= 0.0 and _grab_travel >= HAND_MERGE_TRAVEL:
				_try_hand_merge()
	_guard_in -= delta
	if _guard_in <= 0.0:
		_guard_in = GUARD_PERIOD
		_guard()


## La souris, vue du bocal. Tout passe par press_at(), drag_to() et release() : la maison s'en sert
## aussi quand c'est elle qui reçoit les clics (bocal posé sur le comptoir).
func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse == null:
		return
	var button := event as InputEventMouseButton
	if button == null:
		# Un mouvement ne regarde le bocal que s'il tient quelque chose.
		if is_holding():
			drag_to(mouse.position)
			accept_event()
		elif not compact:
			# Le curseur dit ce qu'un appui ferait : saisir le bocal, attraper une pièce, tapoter.
			if _on_glass(_point_on_plane(mouse.position, 0.0)):
				mouse_default_cursor_shape = Control.CURSOR_MOVE
			elif _pick(mouse.position) != null:
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			else:
				mouse_default_cursor_shape = Control.CURSOR_ARROW
		return
	if button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		# Dans le widget, le double-clic ramène à la maison : il n'est pas pour le bocal.
		if not (compact and button.double_click) and press_at(button.position):
			accept_event()
	elif _pointer_down:
		release()
		accept_event()


# --- La main ---

## Vrai tant que la main tient une coupure ou le bocal.
func is_holding() -> bool:
	return _grabbed != null or _jar_held or _jar_candidate


## Appui en `point` (coordonnées locales). Vrai si le bocal s'en occupe : une coupure attrapée, le
## bocal saisi, la vitre tapotée. Faux en widget quand l'appui ne vise aucune coupure : il sert
## alors à déplacer la fenêtre.
func press_at(point: Vector2) -> bool:
	_pointer = point
	var world := _point_on_plane(point, 0.0)
	var body := _pick(point)
	if not compact and _on_glass(world):
		# Sur une paroi, c'est le bocal qu'on saisit, pas la pièce qui s'y appuie.
		_hold_jar(world, false)
	elif body != null:
		_grab(body)
	elif compact:
		return false
	elif _over_jar(world):
		# Glissé, cet appui devient une saisie du bocal ; relâché sur place, un tapotement.
		_hold_jar(world, false)
	else:
		_tap(world)
	_pointer_down = true
	return true


## Saisit le bocal tout de suite, la main en `point` : pour qui a déjà reconnu le geste (la maison,
## quand le bocal est sur le comptoir et qu'on le fait glisser).
func grab_jar_at(point: Vector2) -> void:
	_pointer = point
	_pointer_down = true
	_hold_jar(_point_on_plane(point, 0.0), true)


## La main est maintenant en `point`.
func drag_to(point: Vector2) -> void:
	_pointer = point


## Le bouton est relâché : la coupure garde son élan (on peut la lancer), le bocal retourne à sa place.
func release() -> void:
	if _jar_candidate:
		_tap(_press_point)
	_jar_candidate = false
	_jar_held = false
	_pointer_down = false
	_let_go()


## Valeur de la coupure tenue, 0 si la main est vide. Écart du bocal à sa place, en unités.
func held_value() -> int:
	return _grabbed.get_meta(&"value") if _grabbed != null and is_instance_valid(_grabbed) else 0


func jar_shift() -> Vector2:
	return Vector2(_jar_offset.x, _jar_offset.y)


## Position à l'écran (coordonnées locales) de chaque coupure posée de cette valeur.
func local_points_of(value: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for body in _bodies():
		if body.get_meta(&"value") == value:
			points.append(_to_local(body.global_position))
	return points


## Position à l'écran du milieu d'une paroi (-1 : gauche, 1 : droite), là où l'on saisit le bocal.
func local_point_of_wall(side: float) -> Vector2:
	var interior: Vector2 = INTERIOR[_size]
	return _to_local(_jar_offset + Vector3(signf(side) * (interior.x + GLASS) / 2.0, interior.y * 0.7, DEPTH / 2.0))


## La fenêtre du widget vient de bouger de `pixels` : le contenu du bocal s'en ressentira.
func sway(pixels: Vector2) -> void:
	var per_unit := _to_local(Vector3.RIGHT).x - _to_local(Vector3.ZERO).x
	if per_unit > 0.001:
		_frame_shift += Vector2(pixels.x, -pixels.y) / per_unit


func _grab(body: RigidBody3D) -> void:
	_let_go()
	_grabbed = body
	_grab_depth = body.global_position.z
	_grab_last = _point_on_plane(_pointer, _grab_depth)
	_grab_travel = 0.0
	body.max_contacts_reported = HELD_CONTACTS
	_wake_around(body.global_position, 1.5)


func _let_go() -> void:
	if _grabbed != null and is_instance_valid(_grabbed):
		_grabbed.max_contacts_reported = 1
	_grabbed = null


func _hold_jar(world: Vector3, at_once: bool) -> void:
	_let_go()
	_jar_grip = world - _jar_offset
	_press_point = world
	_jar_held = at_once
	_jar_candidate = not at_once
	if at_once:
		_wake_all()


## Vrai si ce point est sur une paroi de verre du bocal (à JAR_GRIP_BAND près).
func _on_glass(world: Vector3) -> bool:
	var interior: Vector2 = INTERIOR[_size]
	var local := world - _jar_offset
	return absf(absf(local.x) - (interior.x + GLASS) / 2.0) < JAR_GRIP_BAND \
			and local.y > -0.1 and local.y < interior.y + 0.3


## Vrai si ce point est sur le bocal ou dedans.
func _over_jar(world: Vector3) -> bool:
	var interior: Vector2 = INTERIOR[_size]
	var local := world - _jar_offset
	return absf(local.x) < (interior.x + GLASS) / 2.0 + JAR_GRIP_BAND \
			and local.y > -0.1 and local.y < interior.y + 0.3


## Le bocal suit la main tant qu'on le tient, puis retourne à sa place.
func _move_jar(delta: float) -> void:
	var target := Vector3.ZERO
	if _jar_held or _jar_candidate:
		var wanted := _point_on_plane(_pointer, 0.0) - _jar_grip
		if _jar_candidate and wanted.distance_to(_jar_offset) > JAR_DRAG_START:
			_jar_candidate = false
			_jar_held = true
			_wake_all()
		target = _jar_offset
		if _jar_held:
			target = Vector3(clampf(wanted.x, -JAR_SWAY.x, JAR_SWAY.x), clampf(wanted.y, 0.0, JAR_SWAY.y), 0.0)
	var step := target - _jar_offset
	if step.is_zero_approx():
		if not _jar_held and not _jar_offset.is_zero_approx():
			_jar_offset = Vector3.ZERO
			_jar_body.position = _jar_offset
		if not _jar_held:
			_set_fine_physics(false)
		return
	_set_fine_physics(true)
	var limit := JAR_SPEED * delta if _jar_held else Vector2.ONE * JAR_RETURN_SPEED * delta
	_jar_offset += Vector3(clampf(step.x, -limit.x, limit.x), clampf(step.y, -limit.y, limit.y), 0.0)
	_jar_body.position = _jar_offset
	_wake_all()


## Affine la physique le temps d'une secousse, puis rétablit la cadence ordinaire.
func _set_fine_physics(enabled: bool) -> void:
	if enabled == _fine_physics:
		return
	_fine_physics = enabled
	if enabled:
		_usual_ticks = Engine.physics_ticks_per_second
		Engine.physics_ticks_per_second = SHAKE_TICKS
	else:
		Engine.physics_ticks_per_second = _usual_ticks


func _exit_tree() -> void:
	_set_fine_physics(false)


## Le widget qu'on déplace emporte son bocal : le contenu, lui, voudrait rester où il était.
func _sway_with_the_frame(delta: float) -> void:
	if _frame_shift == Vector2.ZERO and _frame_velocity.length() < 0.05:
		_frame_velocity = Vector2.ZERO
		return
	# La souris ne bouge pas à chaque pas de physique : la vitesse est lissée, sans quoi un
	# déplacement régulier secouerait autant qu'un coup sec.
	var velocity := _frame_velocity.lerp(_frame_shift / delta, 0.35)
	_frame_shift = Vector2.ZERO
	var change := velocity - _frame_velocity
	_frame_velocity = velocity
	var kick := Vector3(
		clampf(-change.x * SWAY_GAIN, -SWAY_MAX.x, SWAY_MAX.x),
		clampf(-change.y * SWAY_GAIN, -SWAY_MAX.y, SWAY_MAX.y), 0.0)
	if kick.length() < 0.05:
		return
	for body in _bodies():
		body.sleeping = false
		body.set_meta(&"calm", 0.0)
		body.linear_velocity += kick


func _wake_all() -> void:
	for body in _bodies():
		body.sleeping = false
		body.set_meta(&"calm", 0.0)


## Tapote la vitre : ce qui est autour sursaute.
func _tap(world: Vector3) -> void:
	for body in _bodies():
		var away := body.global_position - world
		if away.length() < 1.6:
			body.sleeping = false
			body.apply_central_impulse((away.normalized() + Vector3.UP * 0.6) * 1.5 * body.mass)


## La coupure tenue touche-t-elle de quoi fusionner ? Si oui, la fusion se fait dans la main.
func _try_hand_merge() -> void:
	var held: int = _grabbed.get_meta(&"value")
	var available := {}
	for body in _bodies():
		var value: int = body.get_meta(&"value")
		available[value] = available.get(value, 0) + 1
	for other in _grabbed.get_colliding_bodies():
		var touched := other as RigidBody3D
		if touched == null or touched == _grabbed or touched.has_meta(&"leaving") or not touched.has_meta(&"value"):
			continue
		var touched_value: int = touched.get_meta(&"value")
		var recipe := Denominations.hand_merge(held, touched_value, available)
		if not recipe.is_empty():
			_merge_in_hand(touched, recipe["inputs"], recipe["outputs"])
			return


## Fusionne la coupure tenue avec celle qu'elle touche (et, pour une fusion à trois, avec la plus
## proche de ce qui manque). La plus grosse des coupures obtenues reste en main.
func _merge_in_hand(touched: RigidBody3D, inputs: Array[int], outputs: Array[int]) -> void:
	var center := _grabbed.global_position
	var bodies: Array[RigidBody3D] = [_grabbed, touched]
	var missing := inputs.duplicate()
	missing.erase(_grabbed.get_meta(&"value"))
	missing.erase(touched.get_meta(&"value"))
	for value in missing:
		var body := _find_body(value, center, bodies)
		if body == null:
			return
		bodies.append(body)
	for body in bodies:
		_leave(body, center)
	_wake_around(center, 2.0)
	for i in outputs.size():
		_pending.append(outputs[i])
		var at := center + Vector3(0.45 * i, 0.25 * i, 0.0)
		get_tree().create_timer(MERGE_SECONDS).timeout.connect(_spawn_at.bind(outputs[i], at, _generation, i == 0))
	_merge_pause = HAND_MERGE_PAUSE
	_grab_travel = 0.0
	hand_merges += 1
	objects_changed.emit(outputs[0])
	merged_by_hand.emit(inputs, outputs)


# --- Ce que la scène montre ---

func jar_size() -> String:
	return _size


## Change de bocal. Le contenu est à redonner ensuite avec show_composition().
func set_jar_size(new_size: String) -> void:
	if not INTERIOR.has(new_size) or new_size == _size:
		return
	_size = new_size
	_clear()
	_build_walls()
	_frame()


## Vide la scène et fait tomber tout ce contenu ({ valeur: nombre }).
func show_composition(composition: Dictionary) -> void:
	_clear()
	var values: Array[int] = []
	for value in composition:
		for _i in composition[value]:
			values.append(value)
	values.shuffle()
	_queue = values
	_refresh_drop_rate()


## Joue les opérations du modèle, dans l'ordre.
func apply_ops(ops: Array[Dictionary]) -> void:
	for op in ops:
		match op["op"]:
			Jar.OP_DROP:
				_queue.append_array(op["values"])
			Jar.OP_MERGE:
				_merge(op["inputs"], op["output"])
			Jar.OP_SPLIT:
				_split(op["input"], op["outputs"])
	_refresh_drop_rate()


## Ce que la scène contient, tout compris : objets posés, en chute, en attente ({ valeur: nombre }).
func content() -> Dictionary:
	var counts := {}
	for value in _queue:
		counts[value] = counts.get(value, 0) + 1
	for value in _pending:
		counts[value] = counts.get(value, 0) + 1
	for body in _bodies():
		var value: int = body.get_meta(&"value")
		counts[value] = counts.get(value, 0) + 1
	return counts


func object_count() -> int:
	return _bodies().size()


func queued_count() -> int:
	return _queue.size() + _pending.size()


func awake_count() -> int:
	var awake := 0
	for body in _bodies():
		if not body.sleeping:
			awake += 1
	return awake


## Objets posés hors du bocal, sur le comptoir.
func outside_count() -> int:
	var half_width: float = INTERIOR[_size].x / 2.0
	var outside := 0
	for body in _bodies():
		if absf(body.global_position.x) > half_width + GLASS:
			outside += 1
	return outside


## Hauteur du tas dans le bocal, rapportée à la hauteur du bocal (1.0 = au bord).
func pile_level() -> float:
	var interior: Vector2 = INTERIOR[_size]
	var top := 0.0
	for body in _bodies():
		if body.sleeping and absf(body.global_position.x) < interior.x / 2.0:
			top = maxf(top, body.global_position.y)
	return top / interior.y


## Plus grande vitesse linéaire et angulaire parmi les objets (diagnostic de mise au repos).
func max_speeds() -> Vector2:
	var fastest := Vector2.ZERO
	for body in _bodies():
		fastest.x = maxf(fastest.x, body.linear_velocity.length())
		fastest.y = maxf(fastest.y, body.angular_velocity.length())
	return fastest


func shake() -> void:
	for body in _bodies():
		body.sleeping = false
		body.apply_central_impulse(Vector3(randf_range(-3.0, 3.0), randf_range(6.0, 12.0), 0.0) * body.mass)
		body.apply_torque_impulse(Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 0.15)


## Met le bocal en pause (ni simulation ni rendu) ou le relance. Ce qui devait tomber attend.
func set_simulating(enabled: bool) -> void:
	_simulating = enabled
	_redraw_requested = true
	if not enabled:
		# Rien ne reste en main, et le bocal est remis d'aplomb.
		_jar_candidate = false
		_jar_held = false
		_pointer_down = false
		_let_go()
		_jar_offset = Vector3.ZERO
		_jar_body.position = _jar_offset
		_set_fine_physics(false)
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	PhysicsServer3D.space_set_active(_viewport.find_world_3d().space, enabled)


## Coins de la face avant (depth_sign = 1) ou arrière (-1) de l'intérieur du bocal, en coordonnées
## locales : haut gauche, haut droit, bas droit, bas gauche.
func jar_face_points(depth_sign: float) -> PackedVector2Array:
	var interior: Vector2 = INTERIOR[_size]
	var z := depth_sign * DEPTH / 2.0
	var half_width := interior.x / 2.0
	var corners := [
		Vector3(-half_width, interior.y, z), Vector3(half_width, interior.y, z),
		Vector3(half_width, 0.0, z), Vector3(-half_width, 0.0, z),
	]
	var points := PackedVector2Array()
	# Le verre suit le bocal quand on le secoue.
	for i in corners.size():
		corners[i] += _jar_offset
	for corner in corners:
		points.append(_to_local(corner))
	return points


## Hauteur, en coordonnées locales, de la ligne du comptoir au pied du bocal.
func counter_line() -> float:
	return _to_local(Vector3(0.0, 0.0, DEPTH / 2.0)).y


# --- Monde et caméra ---

func _to_local(world: Vector3) -> Vector2:
	return _camera.unproject_position(world) * size / Vector2(_viewport.size)


func _reach() -> float:
	return INTERIOR[_size].x / 2.0 + GLASS + COUNTER_REACH


## Cadre le bocal : assez haut pour voir tomber les pièces, assez large pour voir le comptoir.
func _frame() -> void:
	var interior: Vector2 = INTERIOR[_size]
	var half_width := interior.x / 2.0 + GLASS + (0.3 if compact else COUNTER_REACH)
	var aspect := size.x / maxf(size.y, 1.0)
	var needed_height := interior.y + (COMPACT_HEADROOM if compact else HEADROOM)
	var view_height := maxf(needed_height, (2.0 * half_width + 0.3) / maxf(aspect, 0.1))
	var distance := view_height / (2.0 * tan(deg_to_rad(FOV / 2.0)))
	var center := -0.35 + view_height / 2.0
	_camera_target = Vector3(0.0, center, 0.0)
	_camera_home = Vector3(0.0, center + 0.9, distance)
	_place_camera()
	_redraw_requested = true


func _place_camera() -> void:
	_camera.position = _camera_home + Vector3(-_camera_offset.x * CAMERA_PARALLAX.x, _camera_offset.y * CAMERA_PARALLAX.y, 0.0)
	_camera.look_at(_camera_target)


func _build_walls() -> void:
	if _walls != null:
		_walls.queue_free()
	if _jar_body != null:
		_jar_body.queue_free()
	var material := PhysicsMaterial.new()
	material.friction = 0.7
	material.bounce = 0.05
	# Ce qui ne bouge jamais : le comptoir, ses butées, les deux faces de la tranche.
	_walls = StaticBody3D.new()
	_walls.collision_layer = LAYER_WALLS
	_walls.collision_mask = 0
	_walls.physics_material_override = material
	_viewport.add_child(_walls)
	# Le bocal lui-même, un corps à part : il suit la main quand on le secoue, et pousse ce qu'il contient.
	_jar_offset = Vector3.ZERO
	_jar_held = false
	_jar_candidate = false
	_jar_body = AnimatableBody3D.new()
	_jar_body.collision_layer = LAYER_WALLS
	_jar_body.collision_mask = 0
	_jar_body.physics_material_override = material
	_viewport.add_child(_jar_body)

	var interior: Vector2 = INTERIOR[_size]
	var half_width := interior.x / 2.0
	var reach := _reach()
	var tall := interior.y + HEADROOM + 8.0
	var span := 2.0 * reach + 2.0 * SLAB_WALL
	var thick := DEPTH + 2.0 * SLAB_WALL
	# Comptoir, sur lequel le bocal est posé.
	_add_wall(_walls, Vector3(0.0, -SLAB_WALL / 2.0, 0.0), Vector3(span, SLAB_WALL, thick))
	# Butées au bout du comptoir.
	_add_wall(_walls, Vector3(-reach - SLAB_WALL / 2.0, tall / 2.0, 0.0), Vector3(SLAB_WALL, tall, thick))
	_add_wall(_walls, Vector3(reach + SLAB_WALL / 2.0, tall / 2.0, 0.0), Vector3(SLAB_WALL, tall, thick))
	# Les deux faces de la tranche : derrière, et la vitre devant.
	_add_wall(_walls, Vector3(0.0, tall / 2.0, -DEPTH / 2.0 - SLAB_WALL / 2.0), Vector3(span, tall, SLAB_WALL))
	_add_wall(_walls, Vector3(0.0, tall / 2.0, DEPTH / 2.0 + SLAB_WALL / 2.0), Vector3(span, tall, SLAB_WALL))

	# Fond du bocal : au repos, il affleure le comptoir ; soulevé, il emporte les pièces.
	_add_wall(_jar_body, Vector3(0.0, -JAR_FLOOR / 2.0, 0.0), Vector3(interior.x + 2.0 * GLASS, JAR_FLOOR, thick))
	# Parois de verre : minces, pour que les pièces tombées dehors viennent s'y appuyer ; prolongées
	# sous le fond, pour que rien ne roule sous le bocal quand on le soulève.
	var wall_height := interior.y + JAR_SKIRT
	var wall_middle := (interior.y - JAR_SKIRT) / 2.0
	_add_wall(_jar_body, Vector3(-half_width - GLASS / 2.0, wall_middle, 0.0), Vector3(GLASS, wall_height, thick))
	_add_wall(_jar_body, Vector3(half_width + GLASS / 2.0, wall_middle, 0.0), Vector3(GLASS, wall_height, thick))


func _add_wall(body: PhysicsBody3D, center: Vector3, box_size: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = box_size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = center
	body.add_child(shape)


# --- Objets ---

## Les objets présents, sauf ceux qui sont en train de disparaître dans une fusion.
func _bodies() -> Array[RigidBody3D]:
	var bodies: Array[RigidBody3D] = []
	for child in _objects.get_children():
		if not child.has_meta(&"leaving"):
			bodies.append(child as RigidBody3D)
	return bodies


func _clear() -> void:
	_redraw_requested = true
	_generation += 1
	_queue.clear()
	_pending.clear()
	_cancelled.clear()
	_grabbed = null
	for child in _objects.get_children():
		child.queue_free()
		_objects.remove_child(child)


func _refresh_drop_rate() -> void:
	_drop_rate = maxf(DROPS_PER_SECOND, _queue.size() / RAIN_SECONDS)


func _spawn_falling(value: int) -> void:
	var interior: Vector2 = INTERIOR[_size]
	var body := _make_object(value)
	var half_span := maxf(0.2, interior.x / 2.0 - _half_width(value) - 0.1)
	body.position = Vector3(randf_range(-half_span, half_span), interior.y + 1.0 + randf() * 1.6, randf_range(-0.08, 0.08))
	if Denominations.is_coin(value):
		# L'axe d'une pièce est Y : un quart de tour autour de X la présente de face.
		body.rotation = Vector3(PI / 2.0 + randf_range(-0.6, 0.6), 0.0, randf_range(-PI, PI))
	else:
		body.rotation = Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.6, 0.6))
	body.angular_velocity = Vector3(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0), randf_range(-3.0, 3.0))
	body.set_meta(&"falling", true)
	_objects.add_child(body)


## Fait apparaître une coupure sur place, avec un petit sursaut (résultat d'une fusion ou d'une casse).
## `hold` : elle reste dans la main si le bouton est toujours enfoncé (fusion à la main).
func _spawn_at(value: int, at: Vector3, generation: int, hold: bool = false) -> void:
	if generation != _generation:
		return
	if _cancelled.has(value):
		# Une autre opération a consommé cette coupure avant qu'elle n'apparaisse.
		_cancelled.erase(value)
		return
	_pending.erase(value)
	var body := _make_object(value)
	body.position = Vector3(at.x, maxf(at.y, _half_width(value)), clampf(at.z, -0.08, 0.08))
	if Denominations.is_coin(value):
		body.rotation = Vector3(PI / 2.0 + randf_range(-0.3, 0.3), 0.0, randf_range(-PI, PI))
	else:
		body.rotation = Vector3(0.0, 0.0, randf_range(-0.5, 0.5))
	body.linear_velocity = Vector3(randf_range(-1.0, 1.0), 3.0, 0.0)
	_objects.add_child(body)
	var visual: Node3D = body.get_node("Visual")
	visual.scale = Vector3.ONE * 0.3
	# Les animations sont attachées à l'objet : elles s'arrêtent d'elles-mêmes s'il disparaît.
	body.create_tween().tween_property(visual, "scale", Vector3.ONE, MERGE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_wake_around(body.position, 1.6)
	if hold and _pointer_down and _grabbed == null and not _jar_held:
		# La main n'a pas lâché : elle tient maintenant la nouvelle coupure, et peut enchaîner.
		_grab(body)


func _half_width(value: int) -> float:
	if Denominations.is_coin(value):
		return COIN_DIAMETER[value] / 2.0
	if Denominations.is_bill(value):
		return BILL_SIZE[value].x / 2.0
	return INGOT_SIZE.x / 2.0


func _make_object(value: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.set_meta(&"value", value)
	body.set_meta(&"calm", 0.0)
	body.collision_layer = LAYER_OBJECTS
	body.collision_mask = LAYER_WALLS | LAYER_OBJECTS
	body.physics_material_override = _object_physics
	body.continuous_cd = true
	body.linear_damp = DAMP_NORMAL.x
	body.angular_damp = DAMP_NORMAL.y
	body.contact_monitor = true
	body.max_contacts_reported = 1
	body.body_entered.connect(_on_body_hit.bind(body))

	var visual := Node3D.new()
	visual.name = "Visual"
	body.add_child(visual)
	var shape_node := CollisionShape3D.new()
	if Denominations.is_coin(value):
		var radius: float = COIN_DIAMETER[value] / 2.0
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = COIN_THICKNESS
		shape_node.shape = cylinder
		body.mass = 0.6 + radius * 2.0
		_add_mesh(visual, _coin_edge_mesh(value), Vector3.ZERO, Vector3.ZERO)
		var face := _face_mesh(value, Vector2.ONE * radius * 2.0)
		var lift := COIN_THICKNESS / 2.0 + 0.002
		_add_mesh(visual, face, Vector3(0.0, lift, 0.0), Vector3(-PI / 2.0, 0.0, 0.0))
		_add_mesh(visual, face, Vector3(0.0, -lift, 0.0), Vector3(PI / 2.0, 0.0, 0.0))
	elif Denominations.is_bill(value):
		var bill: Vector2 = BILL_SIZE[value]
		var box := BoxShape3D.new()
		box.size = Vector3(bill.x, bill.y, BILL_THICKNESS)
		shape_node.shape = box
		body.mass = 0.5
		_add_mesh(visual, _box_mesh(value, box.size), Vector3.ZERO, Vector3.ZERO)
		var face := _face_mesh(value, bill)
		var lift := BILL_THICKNESS / 2.0 + 0.002
		_add_mesh(visual, face, Vector3(0.0, 0.0, lift), Vector3.ZERO)
		_add_mesh(visual, face, Vector3(0.0, 0.0, -lift), Vector3(0.0, PI, 0.0))
	else:
		var box := BoxShape3D.new()
		box.size = INGOT_SIZE if value == 100000 else GEM_SIZE
		shape_node.shape = box
		body.mass = 3.0
		_add_mesh(visual, _box_mesh(value, box.size), Vector3.ZERO, Vector3.ZERO)
	body.add_child(shape_node)
	return body


func _add_mesh(parent: Node3D, mesh: Mesh, at: Vector3, euler: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.rotation = euler
	parent.add_child(instance)


func _edge_material(value: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = MoneyFaces.edge_color(value)
	material.roughness = 1.0
	return material


func _coin_edge_mesh(value: int) -> Mesh:
	var key := "edge:%d" % value
	if not _mesh_cache.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = COIN_DIAMETER[value] / 2.0
		mesh.bottom_radius = mesh.top_radius
		mesh.height = COIN_THICKNESS
		mesh.radial_segments = 24
		mesh.rings = 1
		mesh.material = _edge_material(value)
		_mesh_cache[key] = mesh
	return _mesh_cache[key]


func _box_mesh(value: int, box_size: Vector3) -> Mesh:
	var key := "box:%d" % value
	if not _mesh_cache.has(key):
		var mesh := BoxMesh.new()
		mesh.size = box_size
		mesh.material = _edge_material(value)
		_mesh_cache[key] = mesh
	return _mesh_cache[key]


## Face d'une coupure de taille `object_size` : un carré un peu plus grand que l'objet, puisque le
## dessin n'occupe pas toute son image.
func _face_mesh(value: int, object_size: Vector2) -> Mesh:
	var key := "face:%d" % value
	if not _mesh_cache.has(key):
		var mesh := QuadMesh.new()
		if _illustrated.has(value):
			var material := ShaderMaterial.new()
			material.shader = ART_FACE_SHADER
			material.set_shader_parameter("face", _textures[value])
			material.set_shader_parameter("fill", ART_FILL)
			material.set_shader_parameter("is_bill", not Denominations.is_coin(value))
			material.set_shader_parameter("aspect", object_size.x / object_size.y)
			mesh.size = object_size / ART_FILL
			mesh.material = material
		else:
			var material := StandardMaterial3D.new()
			material.albedo_texture = _textures[value]
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold = 0.5
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			material.roughness = 1.0
			mesh.size = object_size / FACE_FILL
			mesh.material = material
		_mesh_cache[key] = mesh
	return _mesh_cache[key]


# --- Fusions et casses ---

## Un objet de cette valeur, le plus proche de `near` s'il est donné. null si aucun.
func _find_body(value: int, near: Variant, taken: Array[RigidBody3D]) -> RigidBody3D:
	var best: RigidBody3D = null
	var best_distance := INF
	for body in _bodies():
		if body.get_meta(&"value") != value or taken.has(body):
			continue
		if near == null:
			return body
		var distance: float = body.global_position.distance_squared_to(near)
		if distance < best_distance:
			best_distance = distance
			best = body
	return best


func _merge(inputs: Array, output: int) -> void:
	var bodies: Array[RigidBody3D] = []
	var near: Variant = null
	for value in inputs:
		var body := _find_body(value, near, bodies)
		if body != null:
			bodies.append(body)
			if near == null:
				near = body.global_position
		else:
			_take_back(value)
	if bodies.is_empty():
		_queue.append(output)
		return
	var center := Vector3.ZERO
	for body in bodies:
		center += body.global_position
	center /= bodies.size()
	for body in bodies:
		_leave(body, center)
	_wake_around(center, 2.0)
	_pending.append(output)
	get_tree().create_timer(MERGE_SECONDS).timeout.connect(_spawn_at.bind(output, center, _generation))
	objects_changed.emit(output)


func _split(input: int, outputs: Array) -> void:
	var taken: Array[RigidBody3D] = []
	var body := _find_body(input, null, taken)
	if body == null:
		_take_back(input)
		_queue.append_array(outputs)
		return
	var at := body.global_position
	_leave(body, at)
	_wake_around(at, 2.0)
	for i in outputs.size():
		var value: int = outputs[i]
		_pending.append(value)
		var offset := Vector3((i - (outputs.size() - 1) / 2.0) * 0.35, 0.1 * i, 0.0)
		get_tree().create_timer(MERGE_SECONDS).timeout.connect(_spawn_at.bind(value, at + offset, _generation))
	objects_changed.emit(input)


## Retire une coupure qui n'est pas encore posée : de ce qui devait tomber, sinon de ce qui allait
## apparaître à la fin d'une fusion (elle n'apparaîtra pas).
func _take_back(value: int) -> void:
	if _queue.has(value):
		_queue.erase(value)
	elif _pending.has(value):
		_pending.erase(value)
		_cancelled.append(value)


## Fait disparaître un objet : il glisse vers `toward` en rétrécissant, sans plus rien heurter.
func _leave(body: RigidBody3D, toward: Vector3) -> void:
	body.set_meta(&"leaving", true)
	body.freeze = true
	body.collision_layer = 0
	body.collision_mask = 0
	if body == _grabbed:
		_grabbed = null
	var tween := body.create_tween().set_parallel()
	tween.tween_property(body, "global_position", toward, MERGE_SECONDS)
	tween.tween_property(body.get_node("Visual"), "scale", Vector3.ONE * 0.15, MERGE_SECONDS)
	tween.chain().tween_callback(body.queue_free)


func _wake_around(point: Vector3, radius: float) -> void:
	for body in _bodies():
		if body.global_position.distance_to(point) < radius:
			body.sleeping = false
			body.set_meta(&"calm", 0.0)


# --- Repos, chocs ---

func _guard() -> void:
	var outer_edge: float = INTERIOR[_size].x / 2.0 + GLASS
	var spilled: RigidBody3D = null
	for body in _bodies():
		if body.sleeping:
			# Posée hors du bocal : elle y retournera si elle y reste.
			var outside: float = body.get_meta(&"outside", 0.0) + GUARD_PERIOD if absf(body.global_position.x) > outer_edge else 0.0
			body.set_meta(&"outside", outside)
			if outside >= TIDY_AFTER and spilled == null:
				spilled = body
			continue
		body.set_meta(&"outside", 0.0)
		var slow := body.linear_velocity.length() < CALM_SPEED and body.angular_velocity.length() < CALM_SPIN
		var calm: float = body.get_meta(&"calm") + GUARD_PERIOD if slow else 0.0
		body.set_meta(&"calm", calm)
		var calming := calm >= CALM_AFTER and body != _grabbed
		body.linear_damp = DAMP_CALMING.x if calming else DAMP_NORMAL.x
		body.angular_damp = DAMP_CALMING.y if calming else DAMP_NORMAL.y
	_tidy_in -= GUARD_PERIOD
	if spilled != null and _tidy_in <= 0.0 and not is_holding() and _jar_offset.is_zero_approx() \
			and _queue.is_empty() and _pending.is_empty() and pile_level() < TIDY_BELOW:
		_put_back(spilled)
		_tidy_in = TIDY_PERIOD


## Une pièce tombée dehors s'éclipse et retombe dans le bocal.
func _put_back(body: RigidBody3D) -> void:
	var value: int = body.get_meta(&"value")
	_leave(body, body.global_position + Vector3.UP * 0.5)
	_queue.append(value)
	_refresh_drop_rate()


func _on_body_hit(_other: Node, body: RigidBody3D) -> void:
	if body.has_meta(&"leaving"):
		return
	var strength := 0.0
	if body.get_meta(&"falling", false):
		body.set_meta(&"falling", false)
		strength = 1.0
	else:
		strength = clampf(body.linear_velocity.length() / 12.0, 0.0, 1.0)
		if strength < 0.25:
			return
	# Effet « coussin » : l'objet gonfle un instant puis reprend sa forme.
	var visual: Node3D = body.get_node("Visual")
	var tween := body.create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE * (1.0 + 0.14 * strength), CUSHION_SECONDS / 3.0)
	tween.tween_property(visual, "scale", Vector3.ONE, CUSHION_SECONDS * 2.0 / 3.0)
	object_landed.emit(body.get_meta(&"value"), strength)


# --- Souris ---

## Le point du monde visé par `point` (coordonnées locales), sur le plan de profondeur `depth`.
func _point_on_plane(point: Vector2, depth: float) -> Vector3:
	var view_point := point * Vector2(_viewport.size) / size
	var origin := _camera.project_ray_origin(view_point)
	var direction := _camera.project_ray_normal(view_point)
	var hit: Variant = Plane(Vector3.BACK, depth).intersects_ray(origin, direction)
	if hit == null:
		return _grabbed.global_position if _grabbed != null else Vector3.ZERO
	return hit


## La coupure visée par `point` (coordonnées locales), null s'il n'y en a pas.
func _pick(point: Vector2) -> RigidBody3D:
	var view_point := point * Vector2(_viewport.size) / size
	var origin := _camera.project_ray_origin(view_point)
	var direction := _camera.project_ray_normal(view_point)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 120.0, LAYER_OBJECTS)
	var hit := _viewport.find_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var body := hit["collider"] as RigidBody3D
	return body if body != null and not body.has_meta(&"leaving") else null
