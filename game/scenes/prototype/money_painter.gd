## Dessine des coupures provisoires (« monnaie maison ») en attendant les illustrations.
## Chaque face est rendue une fois dans une vignette, puis convertie en texture.
extends Node

const Denominations := preload("res://core/money/denominations.gd")
const FACE_SHADER := preload("res://scenes/prototype/money_face.gdshader")

const INK := Color(0.227, 0.149, 0.094)
const COPPER := Color(0.753, 0.478, 0.271)
const GOLD := Color(0.878, 0.690, 0.290)
const SILVER := Color(0.835, 0.824, 0.784)

## valeur -> [couleur du centre, couleur de la couronne, largeur de la couronne]
const COIN_STYLE: Dictionary = {
	1: [COPPER, COPPER, 0.0],
	2: [COPPER, COPPER, 0.0],
	5: [COPPER, COPPER, 0.0],
	10: [GOLD, GOLD, 0.0],
	20: [GOLD, GOLD, 0.0],
	50: [GOLD, GOLD, 0.0],
	100: [SILVER, GOLD, 0.30],
	200: [GOLD, SILVER, 0.30],
}

## Couleurs dominantes des billets en euros.
const BILL_COLOR: Dictionary = {
	500: Color(0.718, 0.741, 0.690),
	1000: Color(0.867, 0.561, 0.518),
	2000: Color(0.561, 0.702, 0.851),
	5000: Color(0.914, 0.651, 0.376),
	10000: Color(0.624, 0.769, 0.541),
	20000: Color(0.890, 0.812, 0.478),
	50000: Color(0.725, 0.604, 0.820),
}

const COIN_TEXTURE_SIZE := Vector2i(256, 256)
const BILL_TEXTURE_SIZE := Vector2i(512, 256)

var _font: SystemFont


func _init() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe Print", "Ink Free", "Comic Sans MS"])
	_font.font_weight = 700


## Couleur de la tranche d'une coupure.
static func edge_color(value: int) -> Color:
	if COIN_STYLE.has(value):
		var ring: Color = COIN_STYLE[value][1]
		return ring.darkened(0.30)
	if BILL_COLOR.has(value):
		var paper: Color = BILL_COLOR[value]
		return paper.lightened(0.25)
	return GOLD.darkened(0.2)


## Renvoie { valeur: Texture2D } pour les pièces et les billets.
func paint_all() -> Dictionary:
	var jobs: Array = []
	var index := 0
	for value in Denominations.VALUES:
		if value > Denominations.LARGEST_BILL:
			continue
		var viewport := _build_face(value, index)
		add_child(viewport)
		jobs.append([value, viewport])
		index += 1
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var textures := {}
	for job in jobs:
		var viewport: SubViewport = job[1]
		var image := viewport.get_texture().get_image()
		image.generate_mipmaps()
		textures[job[0]] = ImageTexture.create_from_image(image)
		viewport.queue_free()
	return textures


func _build_face(value: int, index: int) -> SubViewport:
	var coin := Denominations.is_coin(value)
	var size := COIN_TEXTURE_SIZE if coin else BILL_TEXTURE_SIZE

	var viewport := SubViewport.new()
	viewport.size = size
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var material := ShaderMaterial.new()
	material.shader = FACE_SHADER
	material.set_shader_parameter("ink_color", INK)
	material.set_shader_parameter("seed", 3.7 + index * 11.3)
	if coin:
		var style: Array = COIN_STYLE[value]
		material.set_shader_parameter("fill_color", style[0])
		material.set_shader_parameter("ring_color", style[1])
		material.set_shader_parameter("ring_width", style[2])
	else:
		material.set_shader_parameter("fill_color", BILL_COLOR[value])
		material.set_shader_parameter("is_bill", true)
		material.set_shader_parameter("aspect", float(size.x) / float(size.y))

	var face := ColorRect.new()
	face.size = Vector2(size)
	face.material = material
	viewport.add_child(face)

	var text := Denominations.label(value).replace(" ", "") if coin else Denominations.label(value)
	var settings := LabelSettings.new()
	settings.font = _font
	settings.font_color = INK
	if coin:
		settings.font_size = 84 if text.length() >= 3 else 112
	else:
		settings.font_size = 104
	var label := Label.new()
	label.text = text
	label.label_settings = settings
	label.size = Vector2(size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	viewport.add_child(label)
	return viewport
