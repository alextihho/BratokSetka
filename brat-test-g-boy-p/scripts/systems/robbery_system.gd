# robbery_system.gd - Система ограблений
extends Node

signal robbery_started(robbery_type: String)
signal robbery_completed(robbery_type: String, reward: int, caught: bool)
signal robbery_failed(robbery_type: String, reason: String)

var player_stats
var police_system
var time_system

# Типы ограблений (ключи соответствуют локациям)
var robberies = {
	"ЛАРЁК": {
		"name": "Ограбить ларёк",
		"icon": "🏪",
		"difficulty": 1,  # 1-5
		"min_reward": 500,
		"max_reward": 2000,
		"duration": 3.0,  # минуты игрового времени
		"alarm_chance": 0.2,  # 20% шанс сигнализации
		"police_chance": 0.3,  # 30% шанс патруля
		"required_stats": {"AGI": 3, "LCK": 2},
		"ua_gain": 15,  # Прирост УА при обнаружении
		"description": "Быстрое ограбление ларька. Низкий риск, небольшая награда.",
		"xp_gain": {"AGI": 5, "LCK": 3, "CHA": 2}
	},
	"КВАРТИРА": {
		"name": "Ограбить квартиру",
		"icon": "🏠",
		"difficulty": 2,
		"min_reward": 1000,
		"max_reward": 5000,
		"duration": 5.0,
		"alarm_chance": 0.35,
		"police_chance": 0.25,
		"required_stats": {"AGI": 5, "INT": 4},
		"ua_gain": 20,
		"description": "Взлом квартиры. Средний риск и награда.",
		"xp_gain": {"AGI": 8, "INT": 6, "LCK": 4}
	},
	"СКЛАД": {
		"name": "Ограбить склад",
		"icon": "🏭",
		"difficulty": 3,
		"min_reward": 3000,
		"max_reward": 10000,
		"duration": 8.0,
		"alarm_chance": 0.5,
		"police_chance": 0.4,
		"required_stats": {"STR": 6, "AGI": 6, "INT": 5},
		"ua_gain": 30,
		"description": "Ограбление склада. Требует силы и ловкости. Высокая награда.",
		"xp_gain": {"STR": 10, "AGI": 10, "INT": 8, "LCK": 5}
	},
	"АВТОСАЛОН": {
		"name": "Ограбить автосалон",
		"icon": "🚗",
		"difficulty": 4,
		"min_reward": 5000,
		"max_reward": 20000,
		"duration": 10.0,
		"alarm_chance": 0.7,
		"police_chance": 0.6,
		"required_stats": {"AGI": 8, "INT": 7, "DRV": 5},
		"ua_gain": 40,
		"description": "Кража машины из автосалона. Очень высокий риск!",
		"xp_gain": {"AGI": 15, "INT": 12, "DRV": 10, "LCK": 6}
	},
	"БАНК": {
		"name": "Ограбить банк",
		"icon": "🏦",
		"difficulty": 5,
		"min_reward": 10000,
		"max_reward": 50000,
		"duration": 15.0,
		"alarm_chance": 0.9,
		"police_chance": 0.8,
		"required_stats": {"STR": 10, "AGI": 10, "INT": 10, "CHA": 8},
		"ua_gain": 60,
		"description": "Ограбление банка. Экстремальный риск! Требует команды и подготовки.",
		"xp_gain": {"STR": 20, "AGI": 20, "INT": 20, "CHA": 15, "LCK": 10}
	}
}

var active_robbery = null
var robbery_timer: Timer = null

# ✅ НОВОЕ: Пошаговая система ограблений
var robbery_state = {
	"robbery_id": "",
	"stage": 0,  # 0=planning, 1=entry, 2=action, 3=escape
	"approach": "",  # stealth/aggressive/clever
	"entry_method": "",
	"loot_amount": "",  # quick/medium/greedy
	"escape_method": "",
	"modifiers": {
		"alarm_chance": 0.0,
		"police_chance": 0.0,
		"reward_mult": 1.0,
		"ua_mult": 1.0,
		"time_mult": 1.0
	}
}

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	police_system = get_node_or_null("/root/PoliceSystem")
	time_system = get_node_or_null("/root/TimeSystem")
	print("🎭 Система ограблений загружена")

# Показать меню ограблений
func show_robberies_menu(main_node: Node, player_data: Dictionary, location: String = ""):
	# ✅ ЗАКРЫТЬ МЕНЮ ЛОКАЦИИ
	var building_menu = main_node.get_node_or_null("BuildingMenu")
	if building_menu:
		building_menu.queue_free()
		await main_node.get_tree().process_frame

	# Закрыть предыдущее меню если есть
	var old_menu = main_node.get_node_or_null("RobberiesMenu")
	if old_menu:
		old_menu.queue_free()
		await main_node.get_tree().process_frame

	var menu = CanvasLayer.new()
	menu.name = "RobberiesMenu"
	menu.layer = 150  # ✅ Поверх логов (layer 40) и UI (layer 50)
	main_node.add_child(menu)

	# ✅ Оверлей для блокировки кликов
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu.add_child(overlay)

	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	menu.add_child(bg)

	# Заголовок
	var title = Label.new()
	title.text = "🎭 ОГРАБЛЕНИЯ"
	title.position = Vector2(250, 160)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	menu.add_child(title)

	# Предупреждение
	var warning = Label.new()
	warning.text = "⚠️ Незаконная деятельность! Повышает уровень розыска!"
	warning.position = Vector2(140, 210)
	warning.add_theme_font_size_override("font_size", 14)
	warning.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0, 1.0))
	menu.add_child(warning)

	# Текущий УА
	if police_system:
		var ua_label = Label.new()
		ua_label.text = "🚔 Уровень розыска: %d/100" % police_system.ua_level
		ua_label.position = Vector2(240, 240)
		ua_label.add_theme_font_size_override("font_size", 16)
		var ua_color = Color(0.3, 1.0, 0.3, 1.0) if police_system.ua_level < 30 else (Color(1.0, 0.8, 0.0, 1.0) if police_system.ua_level < 70 else Color(1.0, 0.2, 0.2, 1.0))
		ua_label.add_theme_color_override("font_color", ua_color)
		menu.add_child(ua_label)

	# ScrollContainer для списка ограблений
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 280)
	scroll.size = Vector2(680, 740)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# Создать карточки ограблений
	for robbery_id in robberies:
		create_robbery_card(robberies[robbery_id], robbery_id, vbox, main_node, player_data)

	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1030)
	close_btn.text = "ЗАКРЫТЬ"

	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)

	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)

	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		menu.queue_free()
	)
	menu.add_child(close_btn)

# Создать карточку ограбления
func create_robbery_card(robbery: Dictionary, robbery_id: String, container: VBoxContainer, main_node: Node, player_data: Dictionary):
	var card = Control.new()
	card.custom_minimum_size = Vector2(660, 180)
	container.add_child(card)

	# Фон карточки
	var bg = ColorRect.new()
	bg.size = Vector2(660, 180)
	bg.color = Color(0.1, 0.05, 0.05, 1.0)
	card.add_child(bg)

	# Иконка и название
	var name_label = Label.new()
	name_label.text = robbery["icon"] + " " + robbery["name"]
	name_label.position = Vector2(15, 10)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	card.add_child(name_label)

	# Сложность
	var difficulty_stars = ""
	for i in range(robbery["difficulty"]):
		difficulty_stars += "⭐"
	var diff_label = Label.new()
	diff_label.text = "Сложность: " + difficulty_stars
	diff_label.position = Vector2(15, 40)
	diff_label.add_theme_font_size_override("font_size", 14)
	diff_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))
	card.add_child(diff_label)

	# Награда
	var reward_label = Label.new()
	reward_label.text = "💰 Награда: %d - %d руб." % [robbery["min_reward"], robbery["max_reward"]]
	reward_label.position = Vector2(15, 60)
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	card.add_child(reward_label)

	# Время
	var time_label = Label.new()
	time_label.text = "⏱️ Время: %.0f мин" % robbery["duration"]
	time_label.position = Vector2(15, 80)
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0, 1.0))
	card.add_child(time_label)

	# Риски
	var risk_label = Label.new()
	risk_label.text = "⚠️ Сигнализация: %d%% | Патруль: %d%%" % [int(robbery["alarm_chance"] * 100), int(robbery["police_chance"] * 100)]
	risk_label.position = Vector2(15, 100)
	risk_label.add_theme_font_size_override("font_size", 13)
	risk_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0, 1.0))
	card.add_child(risk_label)

	# Описание
	var desc_label = Label.new()
	desc_label.text = robbery["description"]
	desc_label.position = Vector2(15, 120)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(630, 0)
	card.add_child(desc_label)

	# Проверка требований
	var can_do = can_attempt_robbery(robbery_id, player_data)

	# Кнопка начать
	var start_btn = Button.new()
	start_btn.custom_minimum_size = Vector2(200, 40)
	start_btn.position = Vector2(440, 130)
	start_btn.text = "НАЧАТЬ" if can_do["can"] else "НЕДОСТУПНО"
	start_btn.disabled = not can_do["can"]

	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.6, 0.2, 0.1, 1.0) if can_do["can"] else Color(0.3, 0.3, 0.3, 1.0)
	start_btn.add_theme_stylebox_override("normal", style_btn)

	if can_do["can"]:
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.8, 0.3, 0.1, 1.0)
		start_btn.add_theme_stylebox_override("hover", style_hover)

		start_btn.pressed.connect(func():
			start_robbery_stepwise(robbery_id, main_node, player_data)
		)
	else:
		# Показать причину недоступности
		var reason_label = Label.new()
		reason_label.text = can_do["reason"]
		reason_label.position = Vector2(15, 145)
		reason_label.add_theme_font_size_override("font_size", 11)
		reason_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		card.add_child(reason_label)

	card.add_child(start_btn)

# Проверить возможность ограбления
func can_attempt_robbery(robbery_id: String, player_data: Dictionary) -> Dictionary:
	if not robberies.has(robbery_id):
		return {"can": false, "reason": "Неизвестный тип ограбления"}

	var robbery = robberies[robbery_id]

	# Проверка активного ограбления
	if active_robbery:
		return {"can": false, "reason": "Уже выполняется другое ограбление"}

	# Проверка навыков
	if player_stats:
		for stat in robbery["required_stats"]:
			var required = robbery["required_stats"][stat]
			var current = player_stats.get_stat(stat)
			if current < required:
				return {"can": false, "reason": "Требуется %s: %d (у вас: %d)" % [stat, required, current]}

	# Проверка УА (если слишком высокий, ограбления опаснее)
	if police_system and police_system.ua_level >= 90:
		return {"can": false, "reason": "Слишком высокий уровень розыска! Переждите"}

	return {"can": true, "reason": ""}

# Начать ограбление
func start_robbery(robbery_id: String, main_node: Node, player_data: Dictionary):
	if not robberies.has(robbery_id):
		print("❌ Неизвестное ограбление: " + robbery_id)
		return

	var robbery = robberies[robbery_id]
	active_robbery = robbery_id

	# Закрыть меню
	var menu = main_node.get_node_or_null("RobberiesMenu")
	if menu:
		menu.queue_free()

	# Показать процесс ограбления
	show_robbery_progress(robbery, main_node, player_data)

	robbery_started.emit(robbery_id)
	print("🎭 Начато ограбление: " + robbery["name"])

# Показать прогресс ограбления
func show_robbery_progress(robbery: Dictionary, main_node: Node, player_data: Dictionary):
	var progress_menu = CanvasLayer.new()
	progress_menu.name = "RobberyProgress"
	main_node.add_child(progress_menu)

	var bg = ColorRect.new()
	bg.size = Vector2(600, 300)
	bg.position = Vector2(60, 400)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	progress_menu.add_child(bg)

	var title = Label.new()
	title.text = robbery["icon"] + " " + robbery["name"]
	title.position = Vector2(200, 420)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0, 1.0))
	progress_menu.add_child(title)

	var status = Label.new()
	status.name = "StatusLabel"
	status.text = "⏳ Выполняется..."
	status.position = Vector2(240, 480)
	status.add_theme_font_size_override("font_size", 18)
	status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	progress_menu.add_child(status)

	# Таймер
	if robbery_timer:
		robbery_timer.queue_free()

	robbery_timer = Timer.new()
	robbery_timer.wait_time = robbery["duration"]
	robbery_timer.one_shot = true
	robbery_timer.timeout.connect(func():
		complete_robbery(active_robbery, main_node, player_data)
	)
	main_node.add_child(robbery_timer)
	robbery_timer.start()

	# Симуляция времени
	if time_system:
		time_system.add_minutes(int(robbery["duration"]))

# Завершить ограбление
func complete_robbery(robbery_id: String, main_node: Node, player_data: Dictionary):
	if not robberies.has(robbery_id):
		return

	var robbery = robberies[robbery_id]
	var caught = false
	var reward = 0

	# Проверка сигнализации
	if randf() < robbery["alarm_chance"]:
		print("🚨 СРАБОТАЛА СИГНАЛИЗАЦИЯ!")
		if police_system:
			police_system.on_alarm_triggered()
		caught = true

	# Проверка патруля
	if randf() < robbery["police_chance"]:
		print("🚔 ПАТРУЛЬ ЗАСЁК!")
		if police_system:
			police_system.register_crime("robbery", robbery["ua_gain"])
		caught = true

	# Награда (меньше если поймали)
	if caught:
		reward = randi_range(robbery["min_reward"] / 4, robbery["max_reward"] / 4)
		print("⚠️ Удалось сбежать с частью добычи: %d руб." % reward)
	else:
		reward = randi_range(robbery["min_reward"], robbery["max_reward"])
		print("✅ Ограбление удалось! Награда: %d руб." % reward)

		# Прибавить опыт только при успехе
		if player_stats:
			for stat in robbery["xp_gain"]:
				player_stats.add_stat_xp(stat, robbery["xp_gain"][stat])

	# Выдать деньги
	player_data["balance"] += reward

	# Обновить UI
	var progress_menu = main_node.get_node_or_null("RobberyProgress")
	if progress_menu:
		var status = progress_menu.get_node_or_null("StatusLabel")
		if status:
			if caught:
				status.text = "⚠️ Частично провалено! +%d руб." % reward
				status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0, 1.0))
			else:
				status.text = "✅ Успех! +%d руб." % reward
				status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))

		# Автозакрытие через 3 секунды
		await main_node.get_tree().create_timer(3.0).timeout
		progress_menu.queue_free()

	active_robbery = null
	robbery_completed.emit(robbery_id, reward, caught)

func get_robberies_list() -> Dictionary:
	return robberies

# ========== ✅ ПОШАГОВАЯ СИСТЕМА ОГРАБЛЕНИЙ ==========

# Запуск пошаговой системы вместо старой
func start_robbery_stepwise(robbery_id: String, main_node: Node, player_data: Dictionary):
	if not robberies.has(robbery_id):
		print("❌ Неизвестное ограбление: " + robbery_id)
		return

	# Инициализируем состояние
	robbery_state["robbery_id"] = robbery_id
	robbery_state["stage"] = 0
	robbery_state["approach"] = ""
	robbery_state["entry_method"] = ""
	robbery_state["loot_amount"] = ""
	robbery_state["escape_method"] = ""
	robbery_state["modifiers"] = {
		"alarm_chance": 0.0,
		"police_chance": 0.0,
		"reward_mult": 1.0,
		"ua_mult": 1.0,
		"time_mult": 1.0
	}

	# Закрыть меню выбора ограблений
	var menu = main_node.get_node_or_null("RobberiesMenu")
	if menu:
		menu.queue_free()

	# Начинаем с этапа планирования
	show_planning_stage(main_node, player_data)

# ЭТАП 1: Планирование
func show_planning_stage(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]

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
	title.text = robbery["icon"] + " ПЛАНИРОВАНИЕ"
	title.position = Vector2(200, 160)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0, 1.0))
	stage_menu.add_child(title)

	# Описание
	var desc = Label.new()
	desc.text = "Цель: " + robbery["name"] + "\n" + robbery["description"]
	desc.position = Vector2(40, 220)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(640, 0)
	stage_menu.add_child(desc)

	# Вопрос
	var question = Label.new()
	question.text = "Как вы будете действовать?"
	question.position = Vector2(220, 300)
	question.add_theme_font_size_override("font_size", 20)
	question.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	stage_menu.add_child(question)

	var y_pos = 360

	# Вариант 1: Скрытно
	create_choice_button(stage_menu, y_pos, "🥷 СКРЫТНО",
		"Тихо, незаметно. Меньше риск, но требует ловкости.\n+Шанс успеха, -Награда, -УА если заметят",
		func(): on_approach_selected("stealth", main_node, player_data))
	y_pos += 140

	# Вариант 2: Агрессивно
	create_choice_button(stage_menu, y_pos, "💪 АГРЕССИВНО",
		"Быстро и жёстко. Берём всё силой.\n+Награда, -Шанс успеха, +УА",
		func(): on_approach_selected("aggressive", main_node, player_data))
	y_pos += 140

	# Вариант 3: Хитростью
	create_choice_button(stage_menu, y_pos, "🎭 ХИТРОСТЬЮ",
		"Обман, отвлечение, социальная инженерия.\nСредний риск, зависит от харизмы",
		func(): on_approach_selected("clever", main_node, player_data))
	y_pos += 140

	# Кнопка отмены
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(660, 50)
	cancel_btn.position = Vector2(30, 1070)
	cancel_btn.text = "ОТМЕНИТЬ"
	cancel_btn.add_theme_font_size_override("font_size", 18)

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)

	cancel_btn.pressed.connect(func():
		stage_menu.queue_free()
		show_robberies_menu(main_node, player_data)
	)
	stage_menu.add_child(cancel_btn)

# Создать кнопку выбора
func create_choice_button(parent: CanvasLayer, y: int, title: String, desc: String, callback: Callable):
	var panel = ColorRect.new()
	panel.size = Vector2(660, 120)
	panel.position = Vector2(30, y)
	panel.color = Color(0.15, 0.15, 0.2, 1.0)
	parent.add_child(panel)

	var btn_title = Label.new()
	btn_title.text = title
	btn_title.position = Vector2(50, y + 15)
	btn_title.add_theme_font_size_override("font_size", 22)
	btn_title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	parent.add_child(btn_title)

	var btn_desc = Label.new()
	btn_desc.text = desc
	btn_desc.position = Vector2(50, y + 50)
	btn_desc.add_theme_font_size_override("font_size", 14)
	btn_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	btn_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	btn_desc.custom_minimum_size = Vector2(600, 0)
	parent.add_child(btn_desc)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(660, 120)
	btn.position = Vector2(30, y)
	btn.text = ""
	btn.add_theme_font_size_override("font_size", 18)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.25, 0.25, 0.3, 0.8)
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.pressed.connect(callback)
	parent.add_child(btn)

# Обработка выбора подхода
func on_approach_selected(approach: String, main_node: Node, player_data: Dictionary):
	robbery_state["approach"] = approach

	# Модификаторы в зависимости от подхода
	match approach:
		"stealth":
			robbery_state["modifiers"]["alarm_chance"] -= 0.2
			robbery_state["modifiers"]["reward_mult"] = 0.8
			robbery_state["modifiers"]["ua_mult"] = 0.7
		"aggressive":
			robbery_state["modifiers"]["alarm_chance"] += 0.15
			robbery_state["modifiers"]["reward_mult"] = 1.3
			robbery_state["modifiers"]["ua_mult"] = 1.5
		"clever":
			robbery_state["modifiers"]["police_chance"] -= 0.1
			robbery_state["modifiers"]["reward_mult"] = 1.0
			robbery_state["modifiers"]["ua_mult"] = 1.0

	# Закрыть текущее меню
	var menu = main_node.get_node_or_null("RobberyStageMenu")
	if menu:
		menu.queue_free()

	# Переход к следующему этапу
	robbery_state["stage"] = 1
	show_entry_stage(main_node, player_data)

# ЭТАП 2: Проникновение
func show_entry_stage(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]

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
	title.text = robbery["icon"] + " ПРОНИКНОВЕНИЕ"
	title.position = Vector2(180, 160)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0, 1.0))
	stage_menu.add_child(title)

	# Описание
	var desc = Label.new()
	desc.text = "Вы подобрались к цели. Как будете проникать внутрь?"
	desc.position = Vector2(40, 220)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(640, 0)
	stage_menu.add_child(desc)

	# Текущий подход
	var approach_text = ""
	match robbery_state["approach"]:
		"stealth": approach_text = "🥷 Скрытный подход"
		"aggressive": approach_text = "💪 Агрессивный подход"
		"clever": approach_text = "🎭 Хитрый подход"

	var approach_label = Label.new()
	approach_label.text = "Выбранный подход: " + approach_text
	approach_label.position = Vector2(200, 270)
	approach_label.add_theme_font_size_override("font_size", 14)
	approach_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	stage_menu.add_child(approach_label)

	var y_pos = 330

	# Вариант 1: Взломать замок
	var has_lockpick = player_data.get("has_lockpick", false) or player_stats.get_stat("AGI") >= 7
	create_choice_button(stage_menu, y_pos, "🔓 ВЗЛОМАТЬ ЗАМОК",
		"Тихо вскрыть замок. Требует навыка или отмычки.\n-Шанс сигнализации" + ("" if has_lockpick else " [ТРЕБУЕТСЯ AGI 7+]"),
		func(): on_entry_selected("lockpick", main_node, player_data) if has_lockpick else null)
	if not has_lockpick:
		# Затемнить кнопку если недоступна
		var dim_panel = ColorRect.new()
		dim_panel.size = Vector2(660, 120)
		dim_panel.position = Vector2(30, y_pos)
		dim_panel.color = Color(0, 0, 0, 0.6)
		dim_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		stage_menu.add_child(dim_panel)
	y_pos += 140

	# Вариант 2: Через окно
	create_choice_button(stage_menu, y_pos, "🪟 ЧЕРЕЗ ОКНО",
		"Пролезть через окно. Быстро, но рискованно.\n+Шанс сигнализации, -Время",
		func(): on_entry_selected("window", main_node, player_data))
	y_pos += 140

	# Вариант 3: Договориться
	var has_charisma = player_stats.get_stat("CHA") >= 6
	create_choice_button(stage_menu, y_pos, "🗣️ ДОГОВОРИТЬСЯ",
		"Обмануть охрану или уговорить пустить.\n" + ("Шанс зависит от харизмы" if has_charisma else "Высокий риск провала [ТРЕБУЕТСЯ CHA 6+]"),
		func(): on_entry_selected("talk", main_node, player_data))
	if not has_charisma:
		var dim_panel = ColorRect.new()
		dim_panel.size = Vector2(660, 120)
		dim_panel.position = Vector2(30, y_pos)
		dim_panel.color = Color(0, 0, 0, 0.6)
		dim_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		stage_menu.add_child(dim_panel)
	y_pos += 140

	# Кнопка отмены
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(660, 50)
	cancel_btn.position = Vector2(30, 1070)
	cancel_btn.text = "ОТМЕНИТЬ"
	cancel_btn.add_theme_font_size_override("font_size", 18)

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)

	cancel_btn.pressed.connect(func():
		stage_menu.queue_free()
		show_robberies_menu(main_node, player_data)
	)
	stage_menu.add_child(cancel_btn)

# Обработка выбора способа проникновения
func on_entry_selected(entry_method: String, main_node: Node, player_data: Dictionary):
	robbery_state["entry_method"] = entry_method

	# Модификаторы в зависимости от способа
	match entry_method:
		"lockpick":
			robbery_state["modifiers"]["alarm_chance"] -= 0.15
		"window":
			robbery_state["modifiers"]["alarm_chance"] += 0.1
			robbery_state["modifiers"]["time_mult"] = 0.8
		"talk":
			# Проверка харизмы
			var cha = player_stats.get_stat("CHA")
			if cha >= 8:
				robbery_state["modifiers"]["police_chance"] -= 0.15
				robbery_state["modifiers"]["alarm_chance"] -= 0.1
			elif cha >= 6:
				robbery_state["modifiers"]["police_chance"] -= 0.05
			else:
				# Провал разговора
				robbery_state["modifiers"]["alarm_chance"] += 0.2

	# Закрыть текущее меню
	var menu = main_node.get_node_or_null("RobberyStageMenu")
	if menu:
		menu.queue_free()

	# Переход к следующему этапу
	robbery_state["stage"] = 2
	show_action_stage(main_node, player_data)

# ЭТАП 3: Действие (сколько брать)
func show_action_stage(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]

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
	title.text = robbery["icon"] + " ДЕЙСТВИЕ"
	title.position = Vector2(230, 160)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
	stage_menu.add_child(title)

	# Описание
	var desc = Label.new()
	desc.text = "Вы внутри! Сколько времени потратите на сбор ценностей?"
	desc.position = Vector2(40, 220)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(640, 0)
	stage_menu.add_child(desc)

	# Напоминание о выбранных вариантах
	var approach_text = ""
	match robbery_state["approach"]:
		"stealth": approach_text = "🥷 Скрытно"
		"aggressive": approach_text = "💪 Агрессивно"
		"clever": approach_text = "🎭 Хитростью"

	var entry_text = ""
	match robbery_state["entry_method"]:
		"lockpick": entry_text = "🔓 Взлом"
		"window": entry_text = "🪟 Окно"
		"talk": entry_text = "🗣️ Разговор"

	var choices_label = Label.new()
	choices_label.text = "Выбор: %s → %s" % [approach_text, entry_text]
	choices_label.position = Vector2(220, 270)
	choices_label.add_theme_font_size_override("font_size", 14)
	choices_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	stage_menu.add_child(choices_label)

	var y_pos = 330

	# Вариант 1: Быстро
	create_choice_button(stage_menu, y_pos, "💨 БЫСТРО",
		"Берём только самое ценное и уходим.\n+Безопасность, -Награда (60%), -Время",
		func(): on_action_selected("quick", main_node, player_data))
	y_pos += 140

	# Вариант 2: Умеренно
	create_choice_button(stage_menu, y_pos, "⚖️ УМЕРЕННО",
		"Действуем расчётливо, берём разумное.\nСредняя награда (100%), средний риск",
		func(): on_action_selected("medium", main_node, player_data))
	y_pos += 140

	# Вариант 3: Жадно
	create_choice_button(stage_menu, y_pos, "💰 ЖАДНО",
		"Берём всё, что можем унести!\n+Награда (150%), +Риск, +Время",
		func(): on_action_selected("greedy", main_node, player_data))
	y_pos += 140

	# Кнопка отмены
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(660, 50)
	cancel_btn.position = Vector2(30, 1070)
	cancel_btn.text = "ОТМЕНИТЬ"
	cancel_btn.add_theme_font_size_override("font_size", 18)

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)

	cancel_btn.pressed.connect(func():
		stage_menu.queue_free()
		show_robberies_menu(main_node, player_data)
	)
	stage_menu.add_child(cancel_btn)

# Обработка выбора количества добычи
func on_action_selected(loot_amount: String, main_node: Node, player_data: Dictionary):
	robbery_state["loot_amount"] = loot_amount

	# Модификаторы в зависимости от жадности
	match loot_amount:
		"quick":
			robbery_state["modifiers"]["reward_mult"] *= 0.6
			robbery_state["modifiers"]["alarm_chance"] -= 0.1
			robbery_state["modifiers"]["time_mult"] *= 0.7
		"medium":
			# Без изменений - базовые значения
			pass
		"greedy":
			robbery_state["modifiers"]["reward_mult"] *= 1.5
			robbery_state["modifiers"]["alarm_chance"] += 0.15
			robbery_state["modifiers"]["time_mult"] *= 1.3

	# Закрыть текущее меню
	var menu = main_node.get_node_or_null("RobberyStageMenu")
	if menu:
		menu.queue_free()

	# Переход к следующему этапу
	robbery_state["stage"] = 3
	show_escape_stage(main_node, player_data)

# ЭТАП 4: Побег
func show_escape_stage(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]

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
	title.text = robbery["icon"] + " ПОБЕГ"
	title.position = Vector2(250, 160)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	stage_menu.add_child(title)

	# Описание
	var desc = Label.new()
	desc.text = "Добыча взята! Пора сваливать. Как будете уходить?"
	desc.position = Vector2(40, 220)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(640, 0)
	stage_menu.add_child(desc)

	# Напоминание о выбранных вариантах
	var approach_text = ""
	match robbery_state["approach"]:
		"stealth": approach_text = "🥷 Скрытно"
		"aggressive": approach_text = "💪 Агрессивно"
		"clever": approach_text = "🎭 Хитростью"

	var entry_text = ""
	match robbery_state["entry_method"]:
		"lockpick": entry_text = "🔓 Взлом"
		"window": entry_text = "🪟 Окно"
		"talk": entry_text = "🗣️ Разговор"

	var loot_text = ""
	match robbery_state["loot_amount"]:
		"quick": loot_text = "💨 Быстро"
		"medium": loot_text = "⚖️ Умеренно"
		"greedy": loot_text = "💰 Жадно"

	var choices_label = Label.new()
	choices_label.text = "Выбор: %s → %s → %s" % [approach_text, entry_text, loot_text]
	choices_label.position = Vector2(160, 270)
	choices_label.add_theme_font_size_override("font_size", 14)
	choices_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	stage_menu.add_child(choices_label)

	var y_pos = 330

	# Вариант 1: Тихо уйти
	create_choice_button(stage_menu, y_pos, "🥷 ТИХО УЙТИ",
		"Незаметно выскользнуть.\n-Шанс встретить патруль, нормальное время",
		func(): on_escape_selected("sneak", main_node, player_data))
	y_pos += 140

	# Вариант 2: Бежать
	create_choice_button(stage_menu, y_pos, "🏃 БЕЖАТЬ",
		"Быстро свалить, не обращая внимания.\n+Шанс патруля заметить, -Время",
		func(): on_escape_selected("run", main_node, player_data))
	y_pos += 140

	# Вариант 3: На машине (если есть)
	var has_car = player_data.get("has_car", false)
	create_choice_button(stage_menu, y_pos, "🚗 НА МАШИНЕ",
		"Рвануть на тачке!\n" + ("Очень быстро, +Шум" if has_car else "У вас нет машины! [ТРЕБУЕТСЯ МАШИНА]"),
		func(): on_escape_selected("car", main_node, player_data) if has_car else null)
	if not has_car:
		var dim_panel = ColorRect.new()
		dim_panel.size = Vector2(660, 120)
		dim_panel.position = Vector2(30, y_pos)
		dim_panel.color = Color(0, 0, 0, 0.6)
		dim_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		stage_menu.add_child(dim_panel)
	y_pos += 140

	# Кнопка отмены
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(660, 50)
	cancel_btn.position = Vector2(30, 1070)
	cancel_btn.text = "ОТМЕНИТЬ"
	cancel_btn.add_theme_font_size_override("font_size", 18)

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)

	cancel_btn.pressed.connect(func():
		stage_menu.queue_free()
		show_robberies_menu(main_node, player_data)
	)
	stage_menu.add_child(cancel_btn)

# Обработка выбора способа побега
func on_escape_selected(escape_method: String, main_node: Node, player_data: Dictionary):
	robbery_state["escape_method"] = escape_method

	# Модификаторы в зависимости от способа побега
	match escape_method:
		"sneak":
			robbery_state["modifiers"]["police_chance"] -= 0.15
		"run":
			robbery_state["modifiers"]["police_chance"] += 0.1
			robbery_state["modifiers"]["time_mult"] *= 0.8
		"car":
			robbery_state["modifiers"]["alarm_chance"] += 0.1
			robbery_state["modifiers"]["time_mult"] *= 0.6

	# Закрыть текущее меню
	var menu = main_node.get_node_or_null("RobberyStageMenu")
	if menu:
		menu.queue_free()

	# Завершить ограбление
	robbery_state["stage"] = 4
	complete_robbery_stepwise(main_node, player_data)

# Генерация художественного текста ограбления
func generate_robbery_story(robbery: Dictionary, caught: bool, reward: int) -> String:
	var story = ""

	# Вступление (подход)
	match robbery_state["approach"]:
		"stealth":
			story += "Вы решили действовать тихо и осторожно. "
		"aggressive":
			story += "Вы ворвались быстро и агрессивно. "
		"clever":
			story += "Вы использовали хитрость и обман. "

	# Проникновение
	match robbery_state["entry_method"]:
		"lockpick":
			story += "Взломали замок за считанные секунды - пальцы работали как часы. "
		"window":
			story += "Пролезли через окно, стараясь не шуметь. "
		"talk":
			story += "Уговорили охранника пропустить вас внутрь. "

	# Действие
	match robbery_state["loot_amount"]:
		"quick":
			story += "Схватили самое ценное и приготовились уходить. "
		"medium":
			story += "Методично собрали всё ценное, что попалось под руку. "
		"greedy":
			story += "Жадно набили карманы всем, что можно унести! "

	# Побег
	match robbery_state["escape_method"]:
		"sneak":
			story += "Незаметно выскользнули, растворившись в темноте. "
		"run":
			story += "Рванули бегом, не оглядываясь назад! "
		"car":
			story += "Запрыгнули в машину и умчались с визгом шин! "

	# Результат
	if caught:
		story += "\n\n⚠️ Но что-то пошло не так! Вас заметили. "
		if randf() < 0.5:
			story += "Успели смыться с частью добычи (+%d руб.)" % reward
		else:
			story += "Пришлось бросить часть награбленного. Всего взяли: %d руб." % reward
	else:
		story += "\n\n✅ Всё прошло идеально! "
		story += "Чистая работа. В кармане теперь %d руб." % reward

	return story

# Завершить пошаговое ограбление
func complete_robbery_stepwise(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]

	# Применяем модификаторы
	var alarm_chance = robbery["alarm_chance"] + robbery_state["modifiers"]["alarm_chance"]
	var police_chance = robbery["police_chance"] + robbery_state["modifiers"]["police_chance"]
	var reward_mult = robbery_state["modifiers"]["reward_mult"]
	var ua_mult = robbery_state["modifiers"]["ua_mult"]

	# Расчёт результата
	var caught = false
	var reward = 0

	# Проверка сигнализации
	if randf() < alarm_chance:
		print("🚨 СРАБОТАЛА СИГНАЛИЗАЦИЯ!")
		if police_system:
			police_system.add_ua(int(robbery["ua_gain"] * ua_mult), "ограбление с сигнализацией")
		caught = true

	# Проверка патруля
	if randf() < police_chance:
		print("🚔 ПАТРУЛЬ!")
		if police_system:
			police_system.add_ua(int(robbery["ua_gain"] * ua_mult * 0.5), "замечен при ограблении")
		caught = true

	# Награда
	if not caught:
		reward = int(randi_range(robbery["min_reward"], robbery["max_reward"]) * reward_mult)
	else:
		reward = int(randi_range(robbery["min_reward"], robbery["max_reward"]) * reward_mult * 0.3)

	# XP
	if player_stats:
		for stat in robbery["xp_gain"]:
			player_stats.add_stat_xp(stat, robbery["xp_gain"][stat])

	# Выдать деньги
	player_data["balance"] += reward

	# Время
	if time_system:
		time_system.add_minutes(int(robbery["duration"] * robbery_state["modifiers"]["time_mult"]))

	# Обновить UI
	main_node.update_ui()

	# ✅ НОВОЕ: Художественный текст в лог
	var log_sys = get_node_or_null("/root/LogSystem")
	if log_sys:
		var story = generate_robbery_story(robbery, caught, reward)
		log_sys.add_event_log(robbery["icon"] + " " + robbery["name"] + "\n" + story)

	# Показать результат
	var result_text = ""
	if caught:
		result_text = "⚠️ Ограбление частично провалено!\n+%d руб., но вас заметили!" % reward
	else:
		result_text = "✅ Ограбление успешно!\n+%d руб." % reward

	main_node.show_message(result_text)

	print("🎭 Ограбление завершено: " + robbery["name"] + " | Награда: " + str(reward))
