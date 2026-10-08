## Le bocal en 2.5D : pièces et billets sont de vrais volumes, dessinés à plat sur leurs faces,
## rendus dans une vignette posée dans le décor 2D.
##
## - Le monde est une tranche mince (DEPTH) : les objets s'y recouvrent et s'y inclinent, mais
##   restent tournés vers la joueuse.
## - Le bocal est ouvert et posé sur un comptoir : trop plein, il déborde pour de bon.
## - La scène ne décide de rien : elle joue les opérations du modèle (core/money/jar.gd).
extends SubViewportContainer

const Denominations := preload("res://core/money/denominations.gd")
const Jar := preload("res://core/money/jar.gd")
const MoneyFaces := preload("res://scenes/jar/money_faces.gd")
const ART_FACE_SHADER := preload("res://scenes/jar/art_face.gdshader")

## Un objet vient de toucher quelque chose. `strength` : de 0 (frôlement) à 1 (chute franche).
signal object_landed(value: int, strength: float)
## Des coupures viennent de fusionner en `output`, ou une coupure de se casser.
signal objects_changed(output: int)

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

var _grabbed: RigidBody3D = null
var _grab_depth := 0.0
var _press_pending := false


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
	var busy := camera_moving or _grabbed != null or not _pending.is_empty() or _is_anything_moving()
	if busy:
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
	if _press_pending:
		_press_pending = false
		_press()
	if _grabbed != null:
		if not is_instance_valid(_grabbed) or _grabbed.has_meta(&"leaving"):
			_grabbed = null
		else:
			var to_target := _mouse_on_plane(_grab_depth) - _grabbed.global_position
			_grabbed.sleeping = false
			_grabbed.linear_velocity = (to_target * GRAB_STIFFNESS).limit_length(GRAB_MAX_SPEED)
	_guard_in -= delta
	if _guard_in <= 0.0:
		_guard_in = GUARD_PERIOD
		_guard()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_press_pending = true
	else:
		_grabbed = null  # la pièce garde son élan : on peut la lancer


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
	_walls = StaticBody3D.new()
	_walls.collision_layer = LAYER_WALLS
	_walls.collision_mask = 0
	var material := PhysicsMaterial.new()
	material.friction = 0.7
	material.bounce = 0.05
	_walls.physics_material_override = material
	_viewport.add_child(_walls)

	var interior: Vector2 = INTERIOR[_size]
	var half_width := interior.x / 2.0
	var reach := _reach()
	var tall := interior.y + HEADROOM + 8.0
	var span := 2.0 * reach + 2.0 * SLAB_WALL
	var thick := DEPTH + 2.0 * SLAB_WALL
	# Comptoir, sur lequel le bocal est posé.
	_add_wall(Vector3(0.0, -SLAB_WALL / 2.0, 0.0), Vector3(span, SLAB_WALL, thick))
	# Parois de verre : minces, pour que les pièces tombées dehors viennent s'y appuyer.
	_add_wall(Vector3(-half_width - GLASS / 2.0, interior.y / 2.0, 0.0), Vector3(GLASS, interior.y, thick))
	_add_wall(Vector3(half_width + GLASS / 2.0, interior.y / 2.0, 0.0), Vector3(GLASS, interior.y, thick))
	# Butées au bout du comptoir.
	_add_wall(Vector3(-reach - SLAB_WALL / 2.0, tall / 2.0, 0.0), Vector3(SLAB_WALL, tall, thick))
	_add_wall(Vector3(reach + SLAB_WALL / 2.0, tall / 2.0, 0.0), Vector3(SLAB_WALL, tall, thick))
	# Les deux faces de la tranche : derrière, et la vitre devant.
	_add_wall(Vector3(0.0, tall / 2.0, -DEPTH / 2.0 - SLAB_WALL / 2.0), Vector3(span, tall, SLAB_WALL))
	_add_wall(Vector3(0.0, tall / 2.0, DEPTH / 2.0 + SLAB_WALL / 2.0), Vector3(span, tall, SLAB_WALL))


func _add_wall(center: Vector3, box_size: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = box_size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = center
	_walls.add_child(shape)


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
func _spawn_at(value: int, at: Vector3, generation: int) -> void:
	_pending.erase(value)
	if generation != _generation:
		return
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
			# Pas encore tombée : la coupure est retirée de la file d'attente.
			_queue.erase(value)
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
		_queue.erase(input)
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
	for body in _bodies():
		if body.sleeping:
			continue
		var slow := body.linear_velocity.length() < CALM_SPEED and body.angular_velocity.length() < CALM_SPIN
		var calm: float = body.get_meta(&"calm") + GUARD_PERIOD if slow else 0.0
		body.set_meta(&"calm", calm)
		var calming := calm >= CALM_AFTER and body != _grabbed
		body.linear_damp = DAMP_CALMING.x if calming else DAMP_NORMAL.x
		body.angular_damp = DAMP_CALMING.y if calming else DAMP_NORMAL.y


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

func _mouse_in_viewport() -> Vector2:
	return get_local_mouse_position() * Vector2(_viewport.size) / size


func _mouse_on_plane(depth: float) -> Vector3:
	var mouse := _mouse_in_viewport()
	var origin := _camera.project_ray_origin(mouse)
	var direction := _camera.project_ray_normal(mouse)
	var hit: Variant = Plane(Vector3.BACK, depth).intersects_ray(origin, direction)
	if hit == null:
		return _grabbed.global_position if _grabbed != null else Vector3.ZERO
	return hit


## Clic : attrape l'objet visé, ou tapote la vitre si rien n'est visé.
func _press() -> void:
	var mouse := _mouse_in_viewport()
	var origin := _camera.project_ray_origin(mouse)
	var direction := _camera.project_ray_normal(mouse)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 120.0, LAYER_OBJECTS)
	var hit := _viewport.find_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit["collider"] is RigidBody3D:
		_grabbed = hit["collider"]
		_grab_depth = _grabbed.global_position.z
		_wake_around(_grabbed.global_position, 1.5)
		return
	var tap := _mouse_on_plane(0.0)
	for body in _bodies():
		var away := body.global_position - tap
		if away.length() < 1.6:
			body.sleeping = false
			body.apply_central_impulse((away.normalized() + Vector3.UP * 0.6) * 1.5 * body.mass)
