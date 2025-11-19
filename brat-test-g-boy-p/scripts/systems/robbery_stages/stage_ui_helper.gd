# stage_ui_helper.gd - Помощник для создания UI этапов
extends Node

# Создать базовое окно этапа
static func create_stage_window(main_node: Node, title_text: String, desc_text: String, title_color: Color) -> Dictionary:
	var stage_menu = CanvasLayer.new()
	stage_menu.name = "RobberyStageMenu"
	stage_menu.layer = 150
	main_node.add_child(stage_menu)

	# Оверлей
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stage_menu.add_child(overlay)

	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(680, 1000)
	bg.position = Vector2(20, 140)
	bg.color = Color(0.05, 0.05, 0.1, 0.98)
	stage_menu.add_child(bg)

	# Заголовок
	var title = Label.new()
	title.text = title_text
	title.position = Vector2(200, 160)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", title_color)
	stage_menu.add_child(title)

	# Описание
	var desc = Label.new()
	desc.text = desc_text
	desc.position = Vector2(40, 220)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(640, 0)
	stage_menu.add_child(desc)

	return {"menu": stage_menu, "y_start": 330}

# Создать кнопку выбора
static func create_choice_button(parent: CanvasLayer, y: int, btn_title: String, desc: String, callback: Callable, enabled: bool = true):
	var panel = ColorRect.new()
	panel.size = Vector2(660, 120)
	panel.position = Vector2(30, y)
	panel.color = Color(0.15, 0.15, 0.2, 1.0)
	parent.add_child(panel)

	var title_label = Label.new()
	title_label.text = btn_title
	title_label.position = Vector2(50, y + 15)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	parent.add_child(title_label)

	var desc_label = Label.new()
	desc_label.text = desc
	desc_label.position = Vector2(50, y + 50)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(600, 0)
	parent.add_child(desc_label)

	if not enabled:
		var dim_panel = ColorRect.new()
		dim_panel.size = Vector2(660, 120)
		dim_panel.position = Vector2(30, y)
		dim_panel.color = Color(0, 0, 0, 0.6)
		dim_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		parent.add_child(dim_panel)
		return

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(660, 120)
	btn.position = Vector2(30, y)
	btn.text = ""

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.25, 0.25, 0.3, 0.8)
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.pressed.connect(callback)
	parent.add_child(btn)

# Создать кнопку отмены
static func create_cancel_button(parent: CanvasLayer, main_node: Node, player_data: Dictionary, robbery_system):
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(660, 50)
	cancel_btn.position = Vector2(30, 1070)
	cancel_btn.text = "ОТМЕНИТЬ"
	cancel_btn.add_theme_font_size_override("font_size", 18)

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)

	cancel_btn.pressed.connect(func():
		parent.queue_free()
		if robbery_system:
			robbery_system.show_robberies_menu(main_node, player_data)
	)
	parent.add_child(cancel_btn)

# ✅ НОВОЕ: Показать результат прямо в текущем окне этапа
static func show_result_in_window(main_node: Node, title: String, message: String, is_success: bool, callback: Callable):
	# Находим текущее окно этапа
	var stage_menu = main_node.get_node_or_null("RobberyStageMenu")
	if not stage_menu:
		print("❌ RobberyStageMenu не найдено!")
		return

	# Скрываем все кнопки и панели (они начинаются с позиции 330)
	for child in stage_menu.get_children():
		if child is Button or (child is ColorRect and child.position.y >= 300):
			child.visible = false
		if child is Label and child.position.y >= 300:
			child.visible = false

	# Добавляем цветную полоску результата
	var result_header = ColorRect.new()
	result_header.size = Vector2(660, 80)
	result_header.position = Vector2(30, 280)
	if is_success:
		result_header.color = Color(0.2, 0.8, 0.3, 1.0)  # Зелёный
	else:
		result_header.color = Color(0.9, 0.3, 0.2, 1.0)  # Красный
	stage_menu.add_child(result_header)

	# Заголовок результата
	var result_title = Label.new()
	result_title.text = title
	result_title.position = Vector2(250, 295)
	result_title.add_theme_font_size_override("font_size", 32)
	result_title.add_theme_color_override("font_color", Color.WHITE)
	stage_menu.add_child(result_title)

	# Текст результата
	var result_text = Label.new()
	result_text.text = message
	result_text.position = Vector2(50, 400)
	result_text.add_theme_font_size_override("font_size", 18)
	result_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	result_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	result_text.custom_minimum_size = Vector2(620, 0)
	stage_menu.add_child(result_text)

	# Кнопка продолжения
	var continue_btn = Button.new()
	continue_btn.custom_minimum_size = Vector2(660, 60)
	continue_btn.position = Vector2(30, 1050)
	continue_btn.text = "ПРОДОЛЖИТЬ" if is_success else "ПОПРОБОВАТЬ СНОВА"
	continue_btn.add_theme_font_size_override("font_size", 24)

	var style_btn = StyleBoxFlat.new()
	if is_success:
		style_btn.bg_color = Color(0.2, 0.7, 0.3, 1.0)
	else:
		style_btn.bg_color = Color(0.7, 0.3, 0.2, 1.0)
	continue_btn.add_theme_stylebox_override("normal", style_btn)

	var style_hover = StyleBoxFlat.new()
	if is_success:
		style_hover.bg_color = Color(0.3, 0.9, 0.4, 1.0)
	else:
		style_hover.bg_color = Color(0.9, 0.4, 0.3, 1.0)
	continue_btn.add_theme_stylebox_override("hover", style_hover)

	continue_btn.pressed.connect(func():
		# Закрываем окно этапа
		stage_menu.queue_free()
		# Вызываем callback
		callback.call()
	)
	stage_menu.add_child(continue_btn)
