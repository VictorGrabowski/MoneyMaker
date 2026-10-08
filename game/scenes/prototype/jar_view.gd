## Le bocal en 2.5D : pièces et billets sont de vrais volumes, dessinés à plat sur leurs faces,
## rendus dans une vignette posée au milieu du décor 2D.
## Le bocal est une tranche mince (JAR_DEPTH) : les pièces s'y recouvrent et s'y inclinent,
## mais restent tournées vers la joueuse.
extends SubViewportContainer

const Denominations := preload("res://core/money/denominations.gd")
const MoneyPainter := preload("res://scenes/prototype/money_painter.gd")

const JAR_WIDTH := 6.0
const JAR_HEIGHT := 7.0
const JAR_DEPTH := 0.42
const WALL := 1.0

const COIN_THICKNESS := 0.10
const BILL_THICKNESS := 0.035
## Rayon du dessin dans sa texture. Doit rester égal à FACE_FILL dans money_face.gdshader.
const FACE_FILL := 0.93
## Diamètres proportionnels aux vraies pièces (1 unité ≈ 3,2 cm).
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

const LAYER_WALLS := 1
const LAYER_OBJECTS := 2

const DROPS_PER_SECOND := 40.0
const CAMERA_HOME := Vector3(0.0, 4.6, 24.0)
const CAMERA_TARGET := Vector3(0.0, 3.3, 0.0)
const CAMERA_PARALLAX := Vector2(0.9, 0.45)
const GRAB_STIFFNESS := 18.0
const GRAB_MAX_SPEED := 45.0

## Décalage de la souris par rapport au centre de l'écran, de -1 à 1.
var parallax := Vector2.ZERO

var _textures: Dictionary = {}
var _viewport: SubViewport
var _camera: Camera3D
var _objects: Node3D
var _object_physics: PhysicsMaterial
var _queue: Array[int] = []
var _drop_budget := 0.0
var _mesh_cache: Dictionary = {}
var _grabbed: RigidBody3D = null
var _grab_depth := 0.0
var _press_pending := false
var _camera_offset := Vector2.ZERO


func setup(textures: Dictionary) -> void:
	_textures = textures


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
	_camera.fov = 22.0
	_camera.near = 1.0
	_camera.far = 80.0
	_viewport.add_child(_camera)
	_place_camera()

	_object_physics = PhysicsMaterial.new()
	_object_physics.friction = 0.55
	_object_physics.bounce = 0.12

	_build_walls()
	_objects = Node3D.new()
	_viewport.add_child(_objects)


func _process(delta: float) -> void:
	_camera_offset = _camera_offset.lerp(parallax, minf(1.0, delta * 6.0))
	_place_camera()

	_drop_budget = minf(_drop_budget + DROPS_PER_SECOND * delta, 3.0)
	while _drop_budget >= 1.0 and not _queue.is_empty():
		_spawn(_queue.pop_back())
		_drop_budget -= 1.0


func _physics_process(_delta: float) -> void:
	if _press_pending:
		_press_pending = false
		_press()
	if _grabbed == null:
		return
	if not is_instance_valid(_grabbed):
		_grabbed = null
		return
	var to_target := _mouse_on_plane(_grab_depth) - _grabbed.global_position
	_grabbed.sleeping = false
	_grabbed.linear_velocity = (to_target * GRAB_STIFFNESS).limit_length(GRAB_MAX_SPEED)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_press_pending = true
	else:
		_grabbed = null  # la pièce garde son élan : on peut la lancer


## Fait tomber ces coupures dans le bocal, au rythme de DROPS_PER_SECOND.
func queue_values(values: Array[int]) -> void:
	_queue.append_array(values)


func object_count() -> int:
	return _objects.get_child_count()


func queued_count() -> int:
	return _queue.size()


func awake_count() -> int:
	var awake := 0
	for child in _objects.get_children():
		if not (child as RigidBody3D).sleeping:
			awake += 1
	return awake


## Plus grande vitesse linéaire et angulaire parmi les objets (diagnostic de mise au repos).
func max_speeds() -> Vector2:
	var fastest := Vector2.ZERO
	for child in _objects.get_children():
		var body := child as RigidBody3D
		fastest.x = maxf(fastest.x, body.linear_velocity.length())
		fastest.y = maxf(fastest.y, body.angular_velocity.length())
	return fastest


func clear() -> void:
	_queue.clear()
	for child in _objects.get_children():
		child.queue_free()


func shake() -> void:
	for child in _objects.get_children():
		var body := child as RigidBody3D
		body.sleeping = false
		body.apply_central_impulse(Vector3(randf_range(-3.0, 3.0), randf_range(6.0, 12.0), 0.0) * body.mass)
		body.apply_torque_impulse(Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 0.15)


## Arrête ou reprend le rendu (le widget n'affiche pas le bocal).
func set_rendering(enabled: bool) -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED


## Coins de la face avant (depth_sign = 1) ou arrière (-1) du bocal, en coordonnées locales :
## haut gauche, haut droit, bas droit, bas gauche.
func jar_face_points(depth_sign: float) -> PackedVector2Array:
	var z := depth_sign * JAR_DEPTH / 2.0
	var half_width := JAR_WIDTH / 2.0
	var corners := [
		Vector3(-half_width, JAR_HEIGHT, z), Vector3(half_width, JAR_HEIGHT, z),
		Vector3(half_width, 0.0, z), Vector3(-half_width, 0.0, z),
	]
	var scale_to_local := size / Vector2(_viewport.size)
	var points := PackedVector2Array()
	for corner in corners:
		points.append(_camera.unproject_position(corner) * scale_to_local)
	return points


func _place_camera() -> void:
	_camera.position = CAMERA_HOME + Vector3(-_camera_offset.x * CAMERA_PARALLAX.x, _camera_offset.y * CAMERA_PARALLAX.y, 0.0)
	_camera.look_at(CAMERA_TARGET)


func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_WALLS
	body.collision_mask = 0
	var material := PhysicsMaterial.new()
	material.friction = 0.7
	material.bounce = 0.05
	body.physics_material_override = material
	_viewport.add_child(body)

	var half_width := JAR_WIDTH / 2.0
	var half_depth := JAR_DEPTH / 2.0
	var tall := JAR_HEIGHT + 8.0
	var span := JAR_WIDTH + 2.0 * WALL
	var thick := JAR_DEPTH + 2.0 * WALL
	_add_wall(body, Vector3(0.0, -WALL / 2.0, 0.0), Vector3(span, WALL, thick))  # fond
	_add_wall(body, Vector3(-half_width - WALL / 2.0, tall / 2.0, 0.0), Vector3(WALL, tall, thick))
	_add_wall(body, Vector3(half_width + WALL / 2.0, tall / 2.0, 0.0), Vector3(WALL, tall, thick))
	_add_wall(body, Vector3(0.0, tall / 2.0, -half_depth - WALL / 2.0), Vector3(span, tall, WALL))  # arrière
	_add_wall(body, Vector3(0.0, tall / 2.0, half_depth + WALL / 2.0), Vector3(span, tall, WALL))  # vitre avant


func _add_wall(body: StaticBody3D, center: Vector3, box_size: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = box_size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = center
	body.add_child(shape)


func _spawn(value: int) -> void:
	var body := _make_object(value)
	var margin := 1.2
	body.position = Vector3(
		randf_range(-JAR_WIDTH / 2.0 + margin, JAR_WIDTH / 2.0 - margin),
		JAR_HEIGHT + 1.0 + randf() * 2.0,
		randf_range(-0.08, 0.08))
	if Denominations.is_coin(value):
		# L'axe d'une pièce est Y : un quart de tour autour de X la présente de face.
		body.rotation = Vector3(PI / 2.0 + randf_range(-0.6, 0.6), 0.0, randf_range(-PI, PI))
	else:
		body.rotation = Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.6, 0.6))
	body.angular_velocity = Vector3(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0), randf_range(-3.0, 3.0))
	_objects.add_child(body)


func _make_object(value: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.set_meta(&"value", value)
	body.collision_layer = LAYER_OBJECTS
	body.collision_mask = LAYER_WALLS | LAYER_OBJECTS
	body.physics_material_override = _object_physics
	body.continuous_cd = true
	body.linear_damp = 0.05
	body.angular_damp = 0.6

	var shape_node := CollisionShape3D.new()
	if Denominations.is_coin(value):
		var radius: float = COIN_DIAMETER[value] / 2.0
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = COIN_THICKNESS
		shape_node.shape = cylinder
		body.mass = 0.6 + radius * 2.0
		_add_mesh(body, _coin_edge_mesh(value), Vector3.ZERO, Vector3.ZERO)
		var face := _face_mesh(value, Vector2.ONE * radius * 2.0 / FACE_FILL)
		var lift := COIN_THICKNESS / 2.0 + 0.002
		_add_mesh(body, face, Vector3(0.0, lift, 0.0), Vector3(-PI / 2.0, 0.0, 0.0))
		_add_mesh(body, face, Vector3(0.0, -lift, 0.0), Vector3(PI / 2.0, 0.0, 0.0))
	elif Denominations.is_bill(value):
		var bill: Vector2 = BILL_SIZE[value]
		var box := BoxShape3D.new()
		box.size = Vector3(bill.x, bill.y, BILL_THICKNESS)
		shape_node.shape = box
		body.mass = 0.5
		_add_mesh(body, _box_mesh(value, box.size), Vector3.ZERO, Vector3.ZERO)
		var face := _face_mesh(value, bill / FACE_FILL)
		var lift := BILL_THICKNESS / 2.0 + 0.002
		_add_mesh(body, face, Vector3(0.0, 0.0, lift), Vector3.ZERO)
		_add_mesh(body, face, Vector3(0.0, 0.0, -lift), Vector3(0.0, PI, 0.0))
	else:
		var box := BoxShape3D.new()
		box.size = INGOT_SIZE
		shape_node.shape = box
		body.mass = 3.0
		_add_mesh(body, _box_mesh(value, INGOT_SIZE), Vector3.ZERO, Vector3.ZERO)
	body.add_child(shape_node)
	return body


func _add_mesh(body: RigidBody3D, mesh: Mesh, at: Vector3, euler: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.rotation = euler
	body.add_child(instance)


func _edge_material(value: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = MoneyPainter.edge_color(value)
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


func _face_mesh(value: int, quad_size: Vector2) -> Mesh:
	var key := "face:%d" % value
	if not _mesh_cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_texture = _textures[value]
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.5
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material.roughness = 1.0
		var mesh := QuadMesh.new()
		mesh.size = quad_size
		mesh.material = material
		_mesh_cache[key] = mesh
	return _mesh_cache[key]


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


## Clic : attrape la pièce visée, ou tapote la vitre si rien n'est visé.
func _press() -> void:
	var mouse := _mouse_in_viewport()
	var origin := _camera.project_ray_origin(mouse)
	var direction := _camera.project_ray_normal(mouse)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0, LAYER_OBJECTS)
	var hit := _viewport.find_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit["collider"] is RigidBody3D:
		_grabbed = hit["collider"]
		_grab_depth = _grabbed.global_position.z
		return
	var tap := _mouse_on_plane(0.0)
	for child in _objects.get_children():
		var body := child as RigidBody3D
		var away := body.global_position - tap
		if away.length() < 1.6:
			body.sleeping = false
			body.apply_central_impulse((away.normalized() + Vector3.UP * 0.6) * 1.5 * body.mass)
