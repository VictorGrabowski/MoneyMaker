## Habillage commun des gros plans : du papier crème, de l'encre brune, une écriture à la main.
## Provisoire comme le reste du décor, mais sans rien de flottant ni de vitré.
extends RefCounted

const INK := Color(0.227, 0.149, 0.094)
const INK_SOFT := Color(0.227, 0.149, 0.094, 0.6)
const PAPER := Color(0.965, 0.914, 0.824)
const PAPER_SHADE := Color(0.925, 0.860, 0.745)
const CRUST := Color(0.851, 0.565, 0.184)
const WALNUT := Color(0.420, 0.267, 0.137)

static var _hand_font: SystemFont
static var _theme: Theme


## L'écriture manuscrite du jeu.
static func hand_font() -> SystemFont:
	if _hand_font == null:
		_hand_font = SystemFont.new()
		_hand_font.font_names = PackedStringArray(["Segoe Print", "Ink Free", "Comic Sans MS"])
		_hand_font.font_weight = 700
	return _hand_font


static func flat(color: Color, border: Color, border_width: int, radius: int, margin: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	style.anti_aliasing = true
	return style


## Fond d'une feuille de papier.
static func sheet_style() -> StyleBoxFlat:
	var style := flat(PAPER, INK, 3, 10, 34)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


## Thème des gros plans : boutons, champs et cases dessinés comme sur du papier.
static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font = hand_font()
	_theme.default_font_size = 22

	for type in ["Label", "CheckBox", "Button", "LineEdit", "SpinBox"]:
		_theme.set_color("font_color", type, INK)
	_theme.set_color("font_hover_color", "Button", INK)
	_theme.set_color("font_pressed_color", "Button", INK)
	_theme.set_color("font_focus_color", "Button", INK)
	_theme.set_color("font_disabled_color", "Button", INK_SOFT)
	_theme.set_color("font_hover_color", "CheckBox", INK)
	_theme.set_color("font_pressed_color", "CheckBox", INK)
	_theme.set_color("font_hover_pressed_color", "CheckBox", INK)
	_theme.set_color("font_focus_color", "CheckBox", INK)
	_theme.set_color("font_placeholder_color", "LineEdit", INK_SOFT)
	_theme.set_color("caret_color", "LineEdit", INK)

	_theme.set_stylebox("normal", "Button", flat(PAPER_SHADE, INK, 2, 8, 10))
	_theme.set_stylebox("hover", "Button", flat(PAPER_SHADE.lightened(0.25), INK, 2, 8, 10))
	_theme.set_stylebox("pressed", "Button", flat(CRUST.lightened(0.45), INK, 2, 8, 10))
	_theme.set_stylebox("disabled", "Button", flat(PAPER_SHADE, INK_SOFT, 1, 8, 10))
	_theme.set_stylebox("focus", "Button", flat(Color(0, 0, 0, 0), CRUST, 2, 8, 10))
	_theme.set_stylebox("normal", "LineEdit", flat(Color(1.0, 0.98, 0.93), INK, 2, 6, 8))
	_theme.set_stylebox("focus", "LineEdit", flat(Color(1.0, 0.98, 0.93), CRUST, 2, 6, 8))
	_theme.set_stylebox("read_only", "LineEdit", flat(PAPER_SHADE, INK_SOFT, 1, 6, 8))
	return _theme


static func label(text: String, font_size: int = 22, color: Color = INK) -> Label:
	var settings := LabelSettings.new()
	settings.font = hand_font()
	settings.font_size = font_size
	settings.font_color = color
	var node := Label.new()
	node.text = text
	node.label_settings = settings
	return node


## Titre centré d'une feuille.
static func title(text: String) -> Label:
	var node := label(text, 30)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node


## Un trait de séparation, à l'encre pâle.
static func rule() -> ColorRect:
	var line := ColorRect.new()
	line.color = INK_SOFT
	line.custom_minimum_size = Vector2(0.0, 2.0)
	return line
