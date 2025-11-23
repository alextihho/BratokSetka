# ui_helpers.gd - Вспомогательные функции для создания UI элементов
extends Node

# ===== ЦВЕТОВАЯ СХЕМА =====
const COLOR_OVERLAY = Color(0, 0, 0, 0.7)
const COLOR_BG_DARK = Color(0.05, 0.05, 0.05, 0.95)
const COLOR_BG_MEDIUM = Color(0.1, 0.1, 0.1, 0.9)
const COLOR_BG_PANEL = Color(0.25, 0.25, 0.3, 1.0)
const COLOR_TITLE = Color(1.0, 0.8, 0.2, 1.0)
const COLOR_TEXT_WHITE = Color(0.95, 0.95, 0.95, 1.0)
const COLOR_BTN_CLOSE = Color(0.5, 0.1, 0.1, 1.0)
const COLOR_BTN_CLOSE_HOVER = Color(0.6, 0.2, 0.2, 1.0)
const COLOR_BTN_GREEN = Color(0.2, 0.5, 0.2, 1.0)
const COLOR_BTN_GREEN_HOVER = Color(0.3, 0.6, 0.3, 1.0)
const COLOR_BTN_BLUE = Color(0.2, 0.4, 0.7, 1.0)
const COLOR_BTN_BLUE_HOVER = Color(0.3, 0.5, 0.8, 1.0)
const COLOR_BTN_NORMAL = Color(0.25, 0.25, 0.3, 1.0)
const COLOR_BTN_HOVER = Color(0.35, 0.35, 0.4, 1.0)

# ===== РАЗМЕРЫ =====
const SCREEN_SIZE = Vector2(720, 1280)
const PANEL_SIZE = Vector2(700, 1100)
const BUTTON_SIZE = Vector2(680, 50)

# ===== СОЗДАНИЕ OVERLAY =====
static func create_overlay(alpha: float = 0.7, stop_mouse: bool = true) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.size = SCREEN_SIZE
	overlay.position = Vector2.ZERO
	overlay.color = Color(0, 0, 0, alpha)
	if stop_mouse:
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return overlay

# ===== СОЗДАНИЕ ФОНОВОЙ ПАНЕЛИ =====
static func create_panel_bg(size: Vector2 = PANEL_SIZE, pos: Vector2 = Vector2(10, 90), color: Color = COLOR_BG_DARK) -> ColorRect:
	var bg = ColorRect.new()
	bg.size = size
	bg.position = pos
	bg.color = color
	return bg

# ===== СОЗДАНИЕ ЗАГОЛОВКА =====
static func create_title(text: String, pos: Vector2, font_size: int = 28, color: Color = COLOR_TITLE) -> Label:
	var title = Label.new()
	title.text = text
	title.position = pos
	title.add_theme_font_size_override("font_size", font_size)
	title.add_theme_color_override("font_color", color)
	return title

# ===== СОЗДАНИЕ ТЕКСТОВОЙ МЕТКИ =====
static func create_label(text: String, pos: Vector2, font_size: int = 16, color: Color = COLOR_TEXT_WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

# ===== СОЗДАНИЕ STYLEBOXFLAT =====
static func create_style(bg_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	return style

# ===== СОЗДАНИЕ КНОПКИ С СТИЛЕМ =====
static func create_button(text: String, pos: Vector2, size: Vector2, normal_color: Color, hover_color: Color = Color.TRANSPARENT, font_size: int = 20) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.custom_minimum_size = size

	var style_normal = create_style(normal_color)
	btn.add_theme_stylebox_override("normal", style_normal)

	if hover_color != Color.TRANSPARENT:
		var style_hover = create_style(hover_color)
		btn.add_theme_stylebox_override("hover", style_hover)

	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COLOR_TEXT_WHITE)
	return btn

# ===== СОЗДАНИЕ СТАНДАРТНОЙ КНОПКИ =====
static func create_std_button(text: String, pos: Vector2, size: Vector2 = Vector2(200, 50), font_size: int = 18) -> Button:
	return create_button(text, pos, size, COLOR_BTN_NORMAL, COLOR_BTN_HOVER, font_size)

# ===== СОЗДАНИЕ КНОПКИ ЗАКРЫТИЯ =====
static func create_close_button(text: String = "ЗАКРЫТЬ", pos: Vector2 = Vector2(20, 1100), size: Vector2 = BUTTON_SIZE) -> Button:
	return create_button(text, pos, size, COLOR_BTN_CLOSE, COLOR_BTN_CLOSE_HOVER, 20)

# ===== СОЗДАНИЕ ЗЕЛЕНОЙ КНОПКИ ДЕЙСТВИЯ =====
static func create_action_button(text: String, pos: Vector2, size: Vector2 = Vector2(200, 50)) -> Button:
	return create_button(text, pos, size, COLOR_BTN_GREEN, COLOR_BTN_GREEN_HOVER, 18)

# ===== СОЗДАНИЕ СИНЕЙ КНОПКИ =====
static func create_blue_button(text: String, pos: Vector2, size: Vector2 = Vector2(200, 50)) -> Button:
	return create_button(text, pos, size, COLOR_BTN_BLUE, COLOR_BTN_BLUE_HOVER, 18)

# ===== СОЗДАНИЕ SCROLLCONTAINER =====
static func create_scroll_container(pos: Vector2, size: Vector2) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.position = pos
	scroll.size = size  # ✅ ВАЖНО: Устанавливаем size для правильного скроллинга
	scroll.custom_minimum_size = size
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return scroll

# ===== ОЧИСТКА ДЕТЕЙ =====
static func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

# ===== СОЗДАНИЕ VBOXCONTAINER =====
static func create_vbox(min_width: float = 660) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(min_width, 0)
	return vbox

# ===== СОЗДАНИЕ HBOXCONTAINER =====
static func create_hbox(min_width: float = 660) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(min_width, 0)
	return hbox
