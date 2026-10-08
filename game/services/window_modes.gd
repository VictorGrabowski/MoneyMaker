## La fenêtre a deux visages : la maison (fenêtre ordinaire) et le widget (petite étiquette sans
## bordure, toujours au premier plan, à fond transparent). Ce service change de visage, retient le
## format, la place et l'opacité du widget, et tient l'icône de la zone de notification.
## Il ne connaît aucune scène : celles-ci écoutent `changed` et s'arrangent.
extends Node

const GameState := preload("res://core/state/game_state.gd")

## Le visage, le format ou l'opacité viennent de changer.
signal changed

const HOME_DESIGN_SIZE := Vector2i(1920, 1080)
const WIDGET_SIZES: Dictionary = {
	GameState.WIDGET_PASTILLE: Vector2i(180, 64),
	GameState.WIDGET_BANDEAU: Vector2i(320, 96),
	GameState.WIDGET_MINI_BOCAL: Vector2i(240, 300),
}
## Écart au bord de l'écran quand le widget n'a encore jamais été placé.
const SCREEN_MARGIN := Vector2i(24, 24)
const OPACITY_STEP := 0.05
## En widget, 30 images par seconde suffisent, même quand le mini-bocal s'anime.
const WIDGET_MAX_FPS := 30
## À la maison, 60 : la pluie ou la neige animent l'écran en continu, inutile d'aller plus vite.
const HOME_MAX_FPS := 60

var in_widget := false
var format := GameState.WIDGET_BANDEAU
var opacity := 1.0

var _home_window: Dictionary = {}
var _position := Vector2i.ZERO
var _has_position := false
var _tray: StatusIndicator


func _ready() -> void:
	Engine.max_fps = HOME_MAX_FPS


## Reprend les préférences sauvegardées. À appeler une fois l'état du jeu chargé.
func restore(state: GameState) -> void:
	format = state.widget_format
	opacity = state.widget_opacity
	_position = state.widget_position
	_has_position = state.has_widget_position


func widget_size() -> Vector2i:
	return WIDGET_SIZES[format]


func toggle() -> void:
	if in_widget:
		show_home()
	else:
		show_widget()


## Passe en widget, dans `new_format` s'il est donné, sinon dans le dernier format utilisé.
func show_widget(new_format: String = "") -> void:
	var window := get_window()
	if WIDGET_SIZES.has(new_format):
		format = new_format
	if not in_widget:
		_home_window = {"mode": window.mode, "size": window.size, "position": window.position}
		# Ordre validé par le prototype : fenêtrée, sans bordure, figée, premier plan, transparente.
		window.mode = Window.MODE_WINDOWED
		window.borderless = true
		window.unresizable = true
		window.always_on_top = true
		window.transparent = true
		window.transparent_bg = true
		Engine.max_fps = WIDGET_MAX_FPS
		in_widget = true
	var size := widget_size()
	window.content_scale_size = size
	window.min_size = size
	window.size = size
	_position = _fit_on_screen(_position if _has_position else _default_position(size), size)
	window.position = _position
	_remember()
	changed.emit()


func show_home() -> void:
	if not in_widget:
		return
	var window := get_window()
	in_widget = false
	Engine.max_fps = HOME_MAX_FPS
	window.transparent_bg = false
	window.transparent = false
	window.always_on_top = false
	window.unresizable = false
	window.borderless = false
	window.min_size = Vector2i.ZERO
	window.content_scale_size = HOME_DESIGN_SIZE
	window.size = _home_window["size"]
	window.position = _home_window["position"]
	window.mode = _home_window["mode"]
	changed.emit()


## Format suivant : pastille, bandeau, mini-bocal, puis de nouveau pastille.
func cycle_format() -> void:
	var index := GameState.WIDGET_FORMATS.find(format)
	var next: String = GameState.WIDGET_FORMATS[(index + 1) % GameState.WIDGET_FORMATS.size()]
	if in_widget:
		show_widget(next)
	else:
		format = next


## Choisit le format du widget, qu'on y soit déjà ou non.
func choose_format(new_format: String) -> void:
	if not WIDGET_SIZES.has(new_format) or new_format == format:
		return
	if in_widget:
		show_widget(new_format)
		return
	format = new_format
	_remember()
	changed.emit()


## Rend le widget un peu plus (+1) ou un peu moins (-1) opaque.
func nudge_opacity(direction: int) -> void:
	opacity = clampf(opacity + direction * OPACITY_STEP, GameState.WIDGET_MIN_OPACITY, 1.0)
	_remember()
	changed.emit()


## Déplace le widget (pendant un glisser). La place est retenue par end_move().
func move_widget_to(position: Vector2i) -> void:
	if not in_widget:
		return
	_position = position
	_has_position = true
	get_window().position = position


func end_move() -> void:
	if not in_widget:
		return
	_position = _fit_on_screen(_position, widget_size())
	get_window().position = _position
	_remember()


## Installe l'icône de la zone de notification ; un clic dessus bascule maison / widget.
func setup_tray(icon: Texture2D) -> void:
	if _tray != null or not DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR):
		return
	_tray = StatusIndicator.new()
	_tray.icon = icon
	_tray.tooltip = "MoneyMaker"
	add_child(_tray)
	_tray.pressed.connect(func(_button: int, _at: Vector2i) -> void: toggle())


func has_tray() -> bool:
	return _tray != null


func set_tray_tooltip(text: String) -> void:
	if _tray != null and _tray.tooltip != text:
		_tray.tooltip = text


func _remember() -> void:
	if Game.is_booted() and _has_position:
		Game.remember_widget(format, _position, opacity)
	elif Game.is_booted():
		Game.state.set_widget_format(format)
		Game.state.set_widget_opacity(opacity)
		Game.request_save()


## En bas à droite de l'écran où se trouve la fenêtre.
func _default_position(size: Vector2i) -> Vector2i:
	var area := DisplayServer.screen_get_usable_rect(get_window().current_screen)
	_has_position = true
	return area.position + area.size - size - SCREEN_MARGIN


## Ramène une position dans la zone utile de l'écran qu'elle touche le plus ; si elle n'en touche
## aucun (écran débranché), revient en bas à droite de l'écran courant.
func _fit_on_screen(position: Vector2i, size: Vector2i) -> Vector2i:
	var wanted := Rect2i(position, size)
	var best_area := Rect2i()
	var best_overlap := 0
	for screen in DisplayServer.get_screen_count():
		var area := DisplayServer.screen_get_usable_rect(screen)
		var overlap := area.intersection(wanted).get_area()
		if overlap > best_overlap:
			best_overlap = overlap
			best_area = area
	if best_overlap == 0:
		return _default_position(size)
	return Vector2i(
		clampi(position.x, best_area.position.x, best_area.end.x - size.x),
		clampi(position.y, best_area.position.y, best_area.end.y - size.y))
