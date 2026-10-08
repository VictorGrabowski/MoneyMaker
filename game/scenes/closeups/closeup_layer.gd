## Le plan des gros plans : la maison s'assombrit derrière l'objet qu'on regarde de près.
## Un clic hors de l'objet, un clic droit ou Échap le referme.
extends CanvasLayer

## Le gros plan `id` vient de s'ouvrir, ou de se fermer.
signal opened(id: String)
signal closed(id: String)

const DIM_COLOR := Color(0.08, 0.05, 0.03, 0.55)

## Identifiant du gros plan ouvert, "" si aucun.
var current := ""

var _dim: ColorRect
var _holder: CenterContainer
var _content: Control


func _ready() -> void:
	layer = 10
	_dim = ColorRect.new()
	_dim.color = DIM_COLOR
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)
	_holder = CenterContainer.new()
	_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	visible = false


func is_open() -> bool:
	return current != ""


## Ouvre un gros plan. `content` est centré à l'écran et libéré à la fermeture ; null pour un gros
## plan qui place lui-même son objet (le bocal).
func open(id: String, content: Control) -> void:
	if is_open():
		close()
	current = id
	_content = content
	if content != null:
		_holder.add_child(content)
	visible = true
	opened.emit(id)


func close() -> void:
	if not is_open():
		return
	var id := current
	current = ""
	if _content != null:
		_content.queue_free()
		_content = null
	visible = false
	closed.emit(id)


func _on_dim_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		close()
