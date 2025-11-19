# stage_result_ui.gd - UI для показа результатов этапов
extends Node

# Показать результат этапа прямо в окне ограбления
static func show_stage_result(main_node: Node, title: String, message: String, is_success: bool, callback: Callable, story_text: String = ""):
	# Создаем окно результата
	var result_window = CanvasLayer.new()
	result_window.name = "StageResultWindow"
	result_window.layer = 160  # Выше окна ограбления
	main_node.add_child(result_window)

	# Полупрозрачный оверлей
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_window.add_child(overlay)

	# Окно с результатом
	var panel = ColorRect.new()
	panel.size = Vector2(600, 500)
	panel.position = Vector2(60, 390)
	panel.color = Color(0.08, 0.08, 0.12, 0.98)
	result_window.add_child(panel)

	# Цветная полоска сверху
	var header = ColorRect.new()
	header.size = Vector2(600, 60)
	header.position = Vector2(60, 390)
	if is_success:
		header.color = Color(0.2, 0.8, 0.3, 1.0)  # Зеленый
	else:
		header.color = Color(0.9, 0.3, 0.2, 1.0)  # Красный
	result_window.add_child(header)

	# Заголовок
	var title_label = Label.new()
	title_label.text = title
	title_label.position = Vector2(80, 400)
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	result_window.add_child(title_label)

	# Сообщение (статистика)
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.position = Vector2(80, 480)
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.custom_minimum_size = Vector2(540, 0)
	result_window.add_child(msg_label)

	# Художественный текст (если есть)
	if story_text != "":
		var story_label = Label.new()
		story_label.text = "\n━━━━━━━━━━━━━━━━━━━━\n\n" + story_text
		story_label.position = Vector2(80, 580)
		story_label.add_theme_font_size_override("font_size", 15)
		story_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6, 1))  # Бежевый оттенок
		story_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		story_label.custom_minimum_size = Vector2(540, 0)
		result_window.add_child(story_label)

	# Кнопка продолжить
	var continue_btn = Button.new()
	continue_btn.custom_minimum_size = Vector2(400, 60)
	continue_btn.position = Vector2(160, 800)
	continue_btn.text = "ПРОДОЛЖИТЬ" if is_success else "ПОПРОБОВАТЬ СНОВА"
	continue_btn.add_theme_font_size_override("font_size", 22)

	var style_btn = StyleBoxFlat.new()
	if is_success:
		style_btn.bg_color = Color(0.2, 0.7, 0.3, 1.0)
	else:
		style_btn.bg_color = Color(0.7, 0.3, 0.2, 1.0)
	continue_btn.add_theme_stylebox_override("normal", style_btn)

	var style_hover = StyleBoxFlat.new()
	if is_success:
		style_hover.bg_color = Color(0.3, 0.85, 0.4, 1.0)
	else:
		style_hover.bg_color = Color(0.85, 0.4, 0.3, 1.0)
	continue_btn.add_theme_stylebox_override("hover", style_hover)

	continue_btn.pressed.connect(func():
		result_window.queue_free()
		callback.call()
	)
	result_window.add_child(continue_btn)
