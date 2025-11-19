extends Node

signal treatment_completed(health_restored: int)

var player_stats
var items_db

# Типы лечения
var treatments = {
	"bandage": {
		"name": "Перевязка",
		"icon": "🩹",
		"health_restore": 20,
		"cost": 50,
		"duration": 1.0,
		"description": "Быстрая перевязка ран"
	},
	"firstaid": {
		"name": "Первая помощь",
		"icon": "💊",
		"health_restore": 40,
		"cost": 150,
		"duration": 2.0,
		"description": "Оказание первой помощи"
	},
	"treatment": {
		"name": "Лечение",
		"icon": "🏥",
		"health_restore": 70,
		"cost": 300,
		"duration": 3.0,
		"description": "Полноценное лечение"
	},
	"surgery": {
		"name": "Операция",
		"icon": "⚕️",
		"health_restore": 100,
		"cost": 800,
		"duration": 5.0,
		"description": "Серьёзная операция - полное восстановление"
	}
}

var current_treatment = null
var treatment_timer: Timer = null

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	items_db = get_node_or_null("/root/ItemsDB")
	print("🏥 Система больниц загружена")

# Меню выбора: лечить игрока или членов банды
func show_hospital_choice_menu(main_node: Node, player_data: Dictionary):
	var choice_menu = CanvasLayer.new()
	choice_menu.layer = 100
	choice_menu.name = "HospitalChoiceMenu"
	main_node.add_child(choice_menu)

	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_menu.add_child(overlay)

	var bg = ColorRect.new()
	bg.size = Vector2(600, 490)
	bg.position = Vector2(60, 395)
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	choice_menu.add_child(bg)

	var title = Label.new()
	title.text = "🏥 БОЛЬНИЦА"
	title.position = Vector2(250, 415)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	choice_menu.add_child(title)

	# Кнопка "Лечить себя"
	var self_btn = Button.new()
	self_btn.custom_minimum_size = Vector2(560, 70)
	self_btn.position = Vector2(80, 480)
	self_btn.text = "🩹 ЛЕЧИТЬ СЕБЯ"

	var style_self = StyleBoxFlat.new()
	style_self.bg_color = Color(0.2, 0.6, 0.8, 1.0)
	self_btn.add_theme_stylebox_override("normal", style_self)

	var style_self_hover = StyleBoxFlat.new()
	style_self_hover.bg_color = Color(0.3, 0.7, 0.9, 1.0)
	self_btn.add_theme_stylebox_override("hover", style_self_hover)

	self_btn.add_theme_font_size_override("font_size", 22)

	self_btn.pressed.connect(func():
		choice_menu.queue_free()
		show_hospital_menu(main_node, player_data)
	)
	choice_menu.add_child(self_btn)

	# Кнопка "Лечить банду"
	var gang_btn = Button.new()
	gang_btn.custom_minimum_size = Vector2(560, 70)
	gang_btn.position = Vector2(80, 570)
	gang_btn.text = "👥 ЛЕЧИТЬ ЧЛЕНОВ БАНДЫ"

	var style_gang = StyleBoxFlat.new()
	style_gang.bg_color = Color(0.6, 0.4, 0.2, 1.0)
	gang_btn.add_theme_stylebox_override("normal", style_gang)

	var style_gang_hover = StyleBoxFlat.new()
	style_gang_hover.bg_color = Color(0.7, 0.5, 0.3, 1.0)
	gang_btn.add_theme_stylebox_override("hover", style_gang_hover)

	gang_btn.add_theme_font_size_override("font_size", 22)

	gang_btn.pressed.connect(func():
		choice_menu.queue_free()
		show_gang_hospital_menu(main_node, player_data)
	)
	choice_menu.add_child(gang_btn)

	# Кнопка "Спасти раненых"
	var rescue_btn = Button.new()
	rescue_btn.custom_minimum_size = Vector2(560, 70)
	rescue_btn.position = Vector2(80, 660)
	rescue_btn.text = "🚑 СПАСТИ РАНЕНЫХ БОЙЦОВ"

	var style_rescue = StyleBoxFlat.new()
	style_rescue.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	rescue_btn.add_theme_stylebox_override("normal", style_rescue)

	var style_rescue_hover = StyleBoxFlat.new()
	style_rescue_hover.bg_color = Color(0.9, 0.3, 0.3, 1.0)
	rescue_btn.add_theme_stylebox_override("hover", style_rescue_hover)

	rescue_btn.add_theme_font_size_override("font_size", 22)

	rescue_btn.pressed.connect(func():
		choice_menu.queue_free()
		show_rescue_menu(main_node, player_data)
	)
	choice_menu.add_child(rescue_btn)

	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(560, 60)
	close_btn.position = Vector2(80, 750)
	close_btn.text = "ЗАКРЫТЬ"

	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)

	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)

	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		choice_menu.queue_free()
		main_node.show_location_menu("БОЛЬНИЦА")
	)

	choice_menu.add_child(close_btn)

# Показать меню больницы
func show_hospital_menu(main_node: Node, player_data: Dictionary):
	var hospital_menu = CanvasLayer.new()
	hospital_menu.layer = 100  # ✅ Поверх всего
	hospital_menu.name = "HospitalMenu"
	main_node.add_child(hospital_menu)
	
	# ✅ Overlay на весь экран - блокирует клики по другим элементам
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.8)  # Полупрозрачный черный
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Блокирует клики
	hospital_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)  # ✅ Выше, чтобы не перекрывалось нижним меню
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	hospital_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🏥 БОЛЬНИЦА"
	title.position = Vector2(270, 110)  # ✅ Скорректировано
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	hospital_menu.add_child(title)
	
	# Информация о здоровье
	var current_hp = player_data.get("health", 100)
	var max_hp = 100
	var hp_percent = (float(current_hp) / float(max_hp)) * 100
	
	var health_info = Label.new()
	health_info.text = "Ваше здоровье: " + str(current_hp) + "/" + str(max_hp) + " (" + str(int(hp_percent)) + "%)"
	health_info.position = Vector2(200, 170)  # ✅ Скорректировано
	health_info.add_theme_font_size_override("font_size", 18)
	
	var health_color = Color.GREEN
	if hp_percent < 30:
		health_color = Color.RED
	elif hp_percent < 60:
		health_color = Color.YELLOW
	
	health_info.add_theme_color_override("font_color", health_color)
	hospital_menu.add_child(health_info)
	
	# Прогресс-бар здоровья
	var hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(660, 30)
	hp_bar_bg.position = Vector2(30, 210)  # ✅ Скорректировано
	hp_bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	hospital_menu.add_child(hp_bar_bg)
	
	var hp_bar_fill = ColorRect.new()
	hp_bar_fill.size = Vector2(660 * (hp_percent / 100.0), 30)
	hp_bar_fill.position = Vector2(30, 210)  # ✅ Скорректировано
	hp_bar_fill.color = health_color
	hospital_menu.add_child(hp_bar_fill)
	
	var hp_bar_text = Label.new()
	hp_bar_text.text = str(current_hp) + " HP"
	hp_bar_text.position = Vector2(330, 215)  # ✅ Скорректировано
	hp_bar_text.add_theme_font_size_override("font_size", 16)
	hp_bar_text.add_theme_color_override("font_color", Color.BLACK)
	hospital_menu.add_child(hp_bar_text)
	
	# Проверка, лечится ли игрок сейчас
	if current_treatment != null:
		var treating_label = Label.new()
		treating_label.text = "⏳ Вы лечитесь..."
		treating_label.position = Vector2(270, 260)  # ✅ Скорректировано
		treating_label.add_theme_font_size_override("font_size", 18)
		treating_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		hospital_menu.add_child(treating_label)
	
	# Список видов лечения
	var y_pos = 300  # ✅ Скорректировано
	
	# Подсказка
	var hint = Label.new()
	hint.text = "Выберите вид лечения:"
	hint.position = Vector2(30, y_pos)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	hospital_menu.add_child(hint)
	y_pos += 40
	
	for treatment_key in treatments:
		var treatment = treatments[treatment_key]
		
		# Проверяем, нужно ли лечение
		var needed_hp = max_hp - current_hp
		var is_useful = needed_hp > 0
		
		var treatment_bg = ColorRect.new()
		treatment_bg.size = Vector2(680, 130)
		treatment_bg.position = Vector2(20, y_pos)
		
		if is_useful:
			treatment_bg.color = Color(0.15, 0.2, 0.25, 1.0)
		else:
			treatment_bg.color = Color(0.1, 0.1, 0.1, 1.0)
		
		hospital_menu.add_child(treatment_bg)
		
		var icon = Label.new()
		icon.text = treatment["icon"]
		icon.position = Vector2(40, y_pos + 15)
		icon.add_theme_font_size_override("font_size", 48)
		hospital_menu.add_child(icon)
		
		var name_label = Label.new()
		name_label.text = treatment["name"]
		name_label.position = Vector2(120, y_pos + 15)
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
		hospital_menu.add_child(name_label)
		
		var desc = Label.new()
		desc.text = treatment["description"]
		desc.position = Vector2(120, y_pos + 45)
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		hospital_menu.add_child(desc)
		
		var restore = Label.new()
		restore.text = "❤️ Восстановление: +" + str(treatment["health_restore"]) + " HP"
		restore.position = Vector2(120, y_pos + 70)
		restore.add_theme_font_size_override("font_size", 16)
		restore.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		hospital_menu.add_child(restore)
		
		var cost = Label.new()
		cost.text = "💰 Стоимость: " + str(treatment["cost"]) + " руб."
		cost.position = Vector2(120, y_pos + 95)
		cost.add_theme_font_size_override("font_size", 16)
		cost.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		hospital_menu.add_child(cost)
		
		# Кнопка лечения
		var treat_btn = Button.new()
		treat_btn.custom_minimum_size = Vector2(160, 50)
		treat_btn.position = Vector2(520, y_pos + 40)
		treat_btn.text = "ЛЕЧИТЬСЯ"
		
		# Проверка доступности
		var can_afford = player_data["balance"] >= treatment["cost"]
		var is_treating = (current_treatment != null)
		
		treat_btn.disabled = (not is_useful) or (not can_afford) or is_treating
		
		var style_treat = StyleBoxFlat.new()
		if treat_btn.disabled:
			style_treat.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		else:
			style_treat.bg_color = Color(0.2, 0.6, 0.8, 1.0)
		treat_btn.add_theme_stylebox_override("normal", style_treat)
		
		var style_treat_hover = StyleBoxFlat.new()
		style_treat_hover.bg_color = Color(0.3, 0.7, 0.9, 1.0)
		treat_btn.add_theme_stylebox_override("hover", style_treat_hover)
		
		treat_btn.add_theme_font_size_override("font_size", 18)
		
		var treat_id = treatment_key
		treat_btn.pressed.connect(func():
			start_treatment(treat_id, player_data, main_node)
			# ✅ НЕ закрываем меню - пользователь может лечиться ещё
		)
		hospital_menu.add_child(treat_btn)
		
		y_pos += 150
	
	# Раздел: Использовать предметы
	var items_title = Label.new()
	items_title.text = "═══ ИСПОЛЬЗОВАТЬ ПРЕДМЕТЫ ═══"
	items_title.position = Vector2(180, y_pos + 20)
	items_title.add_theme_font_size_override("font_size", 20)
	items_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	hospital_menu.add_child(items_title)
	y_pos += 60
	
	# Показать лечебные предметы из инвентаря
	var healing_items = get_healing_items_from_inventory(player_data)
	
	if healing_items.size() > 0:
		for item_name in healing_items:
			var item_data = items_db.get_item(item_name) if items_db else null
			if not item_data:
				continue
			
			var item_btn = Button.new()
			item_btn.custom_minimum_size = Vector2(660, 45)
			item_btn.position = Vector2(30, y_pos)
			item_btn.text = item_name + " (+" + str(item_data.get("value", 0)) + " HP)"
			
			var style_item = StyleBoxFlat.new()
			style_item.bg_color = Color(0.2, 0.4, 0.2, 1.0)
			item_btn.add_theme_stylebox_override("normal", style_item)
			
			var style_item_hover = StyleBoxFlat.new()
			style_item_hover.bg_color = Color(0.3, 0.5, 0.3, 1.0)
			item_btn.add_theme_stylebox_override("hover", style_item_hover)
			
			item_btn.add_theme_font_size_override("font_size", 16)
			
			var item_to_use = item_name
			item_btn.pressed.connect(func():
				use_healing_item(item_to_use, player_data, main_node)
				# ✅ Обновляем меню вместо закрытия
				hospital_menu.queue_free()
				show_hospital_menu(main_node, player_data)
			)
			hospital_menu.add_child(item_btn)
			y_pos += 55
	else:
		var no_items = Label.new()
		no_items.text = "Нет лечебных предметов в инвентаре"
		no_items.position = Vector2(200, y_pos)
		no_items.add_theme_font_size_override("font_size", 14)
		no_items.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		hospital_menu.add_child(no_items)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1100)  # ✅ Выше нижнего меню (которое на 1180)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): 
		hospital_menu.queue_free()
		# ✅ Возвращаем меню выбора действий
		main_node.show_location_menu("БОЛЬНИЦА")
	)
	
	hospital_menu.add_child(close_btn)

# Начать лечение
func start_treatment(treatment_key: String, player_data: Dictionary, main_node: Node):
	if current_treatment != null:
		main_node.show_message("⚠️ Вы уже лечитесь!")
		return
	
	if not treatments.has(treatment_key):
		return
	
	var treatment = treatments[treatment_key]
	
	# Проверка денег
	if player_data["balance"] < treatment["cost"]:
		main_node.show_message("❌ Недостаточно денег! Нужно: " + str(treatment["cost"]) + " руб.")
		return
	
	# Проверка HP
	if player_data["health"] >= 100:
		main_node.show_message("✅ Вы полностью здоровы!")
		return
	
	# Списываем деньги
	player_data["balance"] -= treatment["cost"]
	current_treatment = treatment_key
	
	main_node.show_message(treatment["icon"] + " Начато лечение: " + treatment["name"])
	
	# Показываем прогресс
	show_treatment_progress(treatment, player_data, main_node)
	
	# Таймер лечения
	treatment_timer = Timer.new()
	treatment_timer.wait_time = treatment["duration"]
	treatment_timer.one_shot = true
	main_node.add_child(treatment_timer)
	
	treatment_timer.timeout.connect(func():
		complete_treatment(treatment_key, player_data, main_node)
		treatment_timer.queue_free()
		
		# ✅ ДОБАВЛЕНО: Обновляем меню больницы после завершения лечения
		await main_node.get_tree().create_timer(3.5).timeout  # Ждем окончания анимации результата
		var hospital_menu = main_node.get_node_or_null("HospitalMenu")
		if hospital_menu:
			hospital_menu.queue_free()
			show_hospital_menu(main_node, player_data)
	)
	treatment_timer.start()
	
	main_node.update_ui()

# Показать прогресс лечения
func show_treatment_progress(treatment: Dictionary, player_data: Dictionary, main_node: Node):
	var progress_layer = CanvasLayer.new()
	progress_layer.name = "TreatmentProgressLayer"
	progress_layer.layer = 150  # ✅ Поверх меню больницы (layer 100)
	main_node.add_child(progress_layer)
	
	var bg = ColorRect.new()
	bg.size = Vector2(450, 180)
	bg.position = Vector2(135, 550)
	bg.color = Color(0.05, 0.1, 0.15, 0.95)
	progress_layer.add_child(bg)
	
	var icon = Label.new()
	icon.text = treatment["icon"]
	icon.position = Vector2(285, 565)
	icon.add_theme_font_size_override("font_size", 48)
	progress_layer.add_child(icon)
	
	var title = Label.new()
	title.text = treatment["name"]
	title.position = Vector2(260, 625)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	progress_layer.add_child(title)
	
	# Прогресс-бар
	var progress_bg = ColorRect.new()
	progress_bg.size = Vector2(410, 25)
	progress_bg.position = Vector2(155, 670)
	progress_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	progress_layer.add_child(progress_bg)
	
	var progress_fill = ColorRect.new()
	progress_fill.size = Vector2(0, 25)
	progress_fill.position = Vector2(155, 670)
	progress_fill.color = Color(0.3, 0.8, 1.0, 1.0)
	progress_fill.name = "ProgressFill"
	progress_layer.add_child(progress_fill)
	
	var progress_label = Label.new()
	progress_label.text = "0%"
	progress_label.position = Vector2(345, 673)
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color.BLACK)
	progress_label.name = "ProgressLabel"
	progress_layer.add_child(progress_label)
	
	# Анимация прогресса
	var tween = create_tween()
	tween.tween_property(progress_fill, "size:x", 410, treatment["duration"])
	
	# Обновление процентов
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(func():
		var percent = int((progress_fill.size.x / 410.0) * 100)
		progress_label.text = str(percent) + "%"
	)
	progress_layer.add_child(timer)
	timer.start()

# Завершить лечение
func complete_treatment(treatment_key: String, player_data: Dictionary, main_node: Node):
	if not treatments.has(treatment_key):
		return
	
	var treatment = treatments[treatment_key]
	
	# Восстанавливаем здоровье
	var old_health = player_data["health"]
	player_data["health"] = min(100, player_data["health"] + treatment["health_restore"])
	var restored = player_data["health"] - old_health
	
	# Удаляем прогресс-бар
	var progress_layer = main_node.get_node_or_null("TreatmentProgressLayer")
	if progress_layer:
		progress_layer.queue_free()
	
	# Показываем результат
	show_treatment_result(treatment, restored, main_node)
	
	# Обновляем UI
	main_node.update_ui()
	
	# Сбрасываем текущее лечение
	current_treatment = null
	
	treatment_completed.emit(restored)

# Показать результат лечения
func show_treatment_result(treatment: Dictionary, restored: int, main_node: Node):
	var result_layer = CanvasLayer.new()
	result_layer.name = "TreatmentResultLayer"
	result_layer.layer = 150  # ✅ Поверх меню больницы
	main_node.add_child(result_layer)
	
	var bg = ColorRect.new()
	bg.size = Vector2(450, 180)
	bg.position = Vector2(135, 550)
	bg.color = Color(0.1, 0.3, 0.1, 0.95)
	result_layer.add_child(bg)
	
	var icon = Label.new()
	icon.text = treatment["icon"]
	icon.position = Vector2(285, 565)
	icon.add_theme_font_size_override("font_size", 48)
	result_layer.add_child(icon)
	
	var title = Label.new()
	title.text = "ЛЕЧЕНИЕ ЗАВЕРШЕНО!"
	title.position = Vector2(200, 625)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	result_layer.add_child(title)
	
	var restored_label = Label.new()
	restored_label.text = "❤️ Восстановлено: +" + str(restored) + " HP"
	restored_label.position = Vector2(220, 665)
	restored_label.add_theme_font_size_override("font_size", 20)
	restored_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	result_layer.add_child(restored_label)
	
	# Автоматически убираем через 3 секунды
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	main_node.add_child(timer)
	
	timer.timeout.connect(func():
		if result_layer and is_instance_valid(result_layer):
			result_layer.queue_free()
		timer.queue_free()
	)
	timer.start()

# Получить лечебные предметы из инвентаря
func get_healing_items_from_inventory(player_data: Dictionary) -> Array:
	var healing_items = []
	
	if not items_db or not player_data.has("inventory"):
		return healing_items
	
	for item_name in player_data["inventory"]:
		var item_data = items_db.get_item(item_name)
		if item_data and item_data.get("type") == "consumable" and item_data.get("effect") == "heal":
			healing_items.append(item_name)
	
	return healing_items

# Использовать лечебный предмет
func use_healing_item(item_name: String, player_data: Dictionary, main_node: Node):
	if not items_db:
		return
	
	var item_data = items_db.get_item(item_name)
	if not item_data:
		return
	
	# Восстанавливаем здоровье
	var heal_amount = item_data.get("value", 10)
	var old_health = player_data["health"]
	player_data["health"] = min(100, player_data["health"] + heal_amount)
	var restored = player_data["health"] - old_health
	
	# Удаляем предмет из инвентаря
	player_data["inventory"].erase(item_name)
	
	main_node.show_message("✅ Использовано: " + item_name + " (+" + str(restored) + " HP)")
	main_node.update_ui()

# Проверка, лечится ли игрок сейчас
func is_treating() -> bool:
	return current_treatment != null

# Меню лечения членов банды
func show_gang_hospital_menu(main_node: Node, player_data: Dictionary):
	var gang_menu = CanvasLayer.new()
	gang_menu.layer = 100
	gang_menu.name = "GangHospitalMenu"
	main_node.add_child(gang_menu)

	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	gang_menu.add_child(overlay)

	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	gang_menu.add_child(bg)

	var title = Label.new()
	title.text = "👥 ЛЕЧЕНИЕ БАНДЫ"
	title.position = Vector2(220, 110)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))
	gang_menu.add_child(title)

	var hint = Label.new()
	hint.text = "Выберите члена банды для лечения:"
	hint.position = Vector2(190, 170)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	gang_menu.add_child(hint)

	# Список членов банды
	var gang_members = main_node.gang_members if "gang_members" in main_node else []

	var y_pos = 220
	var wounded_count = 0

	for i in range(gang_members.size()):
		var member = gang_members[i]
		var hp = member.get("hp", 100)
		var max_hp = member.get("max_hp", 100)
		var hp_percent = (float(hp) / float(max_hp)) * 100

		# Показываем только раненых (HP < 100%)
		if hp < max_hp:
			wounded_count += 1
			create_gang_member_card(member, i, hp, max_hp, hp_percent, gang_menu, y_pos, main_node, player_data)
			y_pos += 160

	# Если все здоровы
	if wounded_count == 0:
		var all_healthy = Label.new()
		all_healthy.text = "✅ Все члены банды здоровы!"
		all_healthy.position = Vector2(220, 400)
		all_healthy.add_theme_font_size_override("font_size", 22)
		all_healthy.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		gang_menu.add_child(all_healthy)

	# Кнопка назад
	var back_btn = Button.new()
	back_btn.custom_minimum_size = Vector2(680, 50)
	back_btn.position = Vector2(20, 1100)
	back_btn.text = "НАЗАД"

	var style_back = StyleBoxFlat.new()
	style_back.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	back_btn.add_theme_stylebox_override("normal", style_back)

	var style_back_hover = StyleBoxFlat.new()
	style_back_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	back_btn.add_theme_stylebox_override("hover", style_back_hover)

	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(func():
		gang_menu.queue_free()
		show_hospital_choice_menu(main_node, player_data)
	)

	gang_menu.add_child(back_btn)

# Создать карточку члена банды
func create_gang_member_card(member: Dictionary, index: int, hp: int, max_hp: int, hp_percent: float, parent: CanvasLayer, y_pos: int, main_node: Node, player_data: Dictionary):
	var card_bg = ColorRect.new()
	card_bg.size = Vector2(680, 150)
	card_bg.position = Vector2(20, y_pos)
	card_bg.color = Color(0.15, 0.1, 0.1, 1.0)
	parent.add_child(card_bg)

	# Имя
	var name_label = Label.new()
	name_label.text = member.get("name", "Неизвестный")
	name_label.position = Vector2(40, y_pos + 15)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	parent.add_child(name_label)

	# HP инфо
	var hp_label = Label.new()
	hp_label.text = "❤️ %d/%d (%d%%)" % [hp, max_hp, int(hp_percent)]
	hp_label.position = Vector2(40, y_pos + 45)
	hp_label.add_theme_font_size_override("font_size", 18)

	var hp_color = Color.GREEN
	if hp_percent < 30:
		hp_color = Color.RED
	elif hp_percent < 60:
		hp_color = Color.YELLOW

	hp_label.add_theme_color_override("font_color", hp_color)
	parent.add_child(hp_label)

	# HP бар
	var hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(300, 20)
	hp_bar_bg.position = Vector2(40, y_pos + 75)
	hp_bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	parent.add_child(hp_bar_bg)

	var hp_bar_fill = ColorRect.new()
	hp_bar_fill.size = Vector2(300 * (hp_percent / 100.0), 20)
	hp_bar_fill.position = Vector2(40, y_pos + 75)
	hp_bar_fill.color = hp_color
	parent.add_child(hp_bar_fill)

	# Нужно HP
	var needed_hp = max_hp - hp
	var cost = needed_hp * 5  # 5 рублей за 1 HP

	var cost_label = Label.new()
	cost_label.text = "💰 Стоимость лечения: %d руб." % cost
	cost_label.position = Vector2(40, y_pos + 105)
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	parent.add_child(cost_label)

	# Кнопка лечения
	var heal_btn = Button.new()
	heal_btn.custom_minimum_size = Vector2(200, 50)
	heal_btn.position = Vector2(480, y_pos + 50)
	heal_btn.text = "ВЫЛЕЧИТЬ"

	var can_afford = player_data["balance"] >= cost

	heal_btn.disabled = not can_afford

	var style_heal = StyleBoxFlat.new()
	style_heal.bg_color = Color(0.2, 0.6, 0.2, 1.0) if can_afford else Color(0.3, 0.3, 0.3, 1.0)
	heal_btn.add_theme_stylebox_override("normal", style_heal)

	if can_afford:
		var style_heal_hover = StyleBoxFlat.new()
		style_heal_hover.bg_color = Color(0.3, 0.7, 0.3, 1.0)
		heal_btn.add_theme_stylebox_override("hover", style_heal_hover)

	heal_btn.add_theme_font_size_override("font_size", 18)

	var member_index = index
	heal_btn.pressed.connect(func():
		heal_gang_member(member_index, needed_hp, cost, main_node, player_data)
	)

	parent.add_child(heal_btn)

# Вылечить члена банды
func heal_gang_member(member_index: int, heal_amount: int, cost: int, main_node: Node, player_data: Dictionary):
	# Проверка денег
	if player_data["balance"] < cost:
		main_node.show_message("❌ Недостаточно денег!")
		return

	# Списываем деньги
	player_data["balance"] -= cost

	# Лечим
	var gang_members = main_node.gang_members if "gang_members" in main_node else []
	if member_index < gang_members.size():
		var member = gang_members[member_index]
		member["hp"] = min(member.get("max_hp", 100), member.get("hp", 100) + heal_amount)

		main_node.show_message("✅ %s вылечен! +%d HP" % [member.get("name", "Член банды"), heal_amount])
		main_node.update_ui()

		# Обновляем меню
		var gang_menu = main_node.get_node_or_null("GangHospitalMenu")
		if gang_menu:
			gang_menu.queue_free()
			show_gang_hospital_menu(main_node, player_data)

# Меню спасения раненых бойцов
func show_rescue_menu(main_node: Node, player_data: Dictionary):
	var rescue_menu = CanvasLayer.new()
	rescue_menu.layer = 100
	rescue_menu.name = "RescueMenu"
	main_node.add_child(rescue_menu)

	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	rescue_menu.add_child(overlay)

	var bg = ColorRect.new()
	bg.size = Vector2(680, 1100)
	bg.position = Vector2(20, 90)
	bg.color = Color(0.1, 0.05, 0.05, 0.95)
	rescue_menu.add_child(bg)

	var title = Label.new()
	title.text = "🚑 СПАСЕНИЕ РАНЕНЫХ"
	title.position = Vector2(180, 110)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	rescue_menu.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Раненые бойцы нуждаются в срочной помощи"
	subtitle.position = Vector2(140, 155)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7, 1.0))
	rescue_menu.add_child(subtitle)

	# Получаем список раненых (HP = 0)
	var gang_members = main_node.gang_members if "gang_members" in main_node else []
	var wounded = []

	for i in range(gang_members.size()):
		if i == 0:
			continue  # Пропускаем ГГ

		var member = gang_members[i]
		var hp = member.get("hp", member.get("health", 100))
		var max_hp = member.get("max_hp", 100)

		if hp <= 0:
			wounded.append({"index": i, "member": member, "hp": hp, "max_hp": max_hp})

	var y_pos = 200

	if wounded.size() == 0:
		var no_wounded = Label.new()
		no_wounded.text = "✅ Нет раненых бойцов"
		no_wounded.position = Vector2(220, y_pos + 100)
		no_wounded.add_theme_font_size_override("font_size", 22)
		no_wounded.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		rescue_menu.add_child(no_wounded)
	else:
		var info = Label.new()
		info.text = "💰 Стоимость спасения одного бойца: 500 руб."
		info.position = Vector2(140, y_pos)
		info.add_theme_font_size_override("font_size", 16)
		info.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5, 1.0))
		rescue_menu.add_child(info)
		y_pos += 40

		# ScrollContainer для раненых
		var scroll = ScrollContainer.new()
		scroll.position = Vector2(30, y_pos)
		scroll.size = Vector2(660, 750)
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		rescue_menu.add_child(scroll)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		scroll.add_child(vbox)

		# Карточки раненых
		for wounded_data in wounded:
			create_wounded_card(wounded_data, vbox, main_node, player_data)

	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(660, 60)
	close_btn.position = Vector2(30, 1100)
	close_btn.text = "ЗАКРЫТЬ"

	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)

	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)

	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		rescue_menu.queue_free()
		show_hospital_choice_menu(main_node, player_data)
	)
	rescue_menu.add_child(close_btn)

# Создать карточку раненого бойца
func create_wounded_card(wounded_data: Dictionary, parent: VBoxContainer, main_node: Node, player_data: Dictionary):
	var card = ColorRect.new()
	card.custom_minimum_size = Vector2(640, 150)
	card.color = Color(0.2, 0.1, 0.1, 1.0)
	parent.add_child(card)

	var member = wounded_data["member"]
	var member_index = wounded_data["index"]
	var max_hp = wounded_data["max_hp"]

	# Имя бойца
	var name_label = Label.new()
	name_label.text = "💀 " + member.get("name", "Боец " + str(member_index))
	name_label.position = Vector2(15, 15)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	card.add_child(name_label)

	# Статус
	var status_label = Label.new()
	status_label.text = "⚠️ КРИТИЧЕСКОЕ СОСТОЯНИЕ"
	status_label.position = Vector2(15, 45)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	card.add_child(status_label)

	# Описание
	var desc_label = Label.new()
	desc_label.text = "Боец нуждается в срочной госпитализации и лечении"
	desc_label.position = Vector2(15, 70)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	card.add_child(desc_label)

	# Стоимость
	var cost = 500
	var cost_label = Label.new()
	cost_label.text = "💰 Стоимость: " + str(cost) + " руб."
	cost_label.position = Vector2(15, 95)
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	card.add_child(cost_label)

	# Кнопка спасения
	var rescue_btn = Button.new()
	rescue_btn.custom_minimum_size = Vector2(200, 50)
	rescue_btn.position = Vector2(420, 80)
	rescue_btn.text = "🚑 СПАСТИ"

	var style_rescue = StyleBoxFlat.new()
	style_rescue.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	rescue_btn.add_theme_stylebox_override("normal", style_rescue)

	var style_rescue_hover = StyleBoxFlat.new()
	style_rescue_hover.bg_color = Color(0.4, 0.8, 0.4, 1.0)
	rescue_btn.add_theme_stylebox_override("hover", style_rescue_hover)

	rescue_btn.add_theme_font_size_override("font_size", 18)

	rescue_btn.pressed.connect(func():
		rescue_gang_member(member_index, cost, main_node, player_data)
	)
	card.add_child(rescue_btn)

# Спасти раненого члена банды
func rescue_gang_member(member_index: int, cost: int, main_node: Node, player_data: Dictionary):
	# Проверка денег
	if player_data["balance"] < cost:
		main_node.show_message("❌ Недостаточно денег! Нужно: " + str(cost) + " руб.")
		return

	# Списываем деньги
	player_data["balance"] -= cost

	# Спасаем - восстанавливаем HP до максимума
	var gang_members = main_node.gang_members if "gang_members" in main_node else []
	if member_index < gang_members.size():
		var member = gang_members[member_index]
		var max_hp = member.get("max_hp", 100)

		# Восстанавливаем HP и health
		member["hp"] = max_hp
		member["health"] = max_hp

		var member_name = member.get("name", "Боец " + str(member_index))
		main_node.show_message("✅ %s спасён! HP восстановлено до %d" % [member_name, max_hp])
		main_node.update_ui()

		# Лог
		var log_system = get_node_or_null("/root/LogSystem")
		if log_system:
			log_system.add_success_log("Врачи смогли спасти %s. Боец снова в строю!" % member_name)

		# Обновляем меню
		var rescue_menu = main_node.get_node_or_null("RescueMenu")
		if rescue_menu:
			rescue_menu.queue_free()
			show_rescue_menu(main_node, player_data)
