# robbery_system.gd - Система ограблений
extends Node

signal robbery_started(robbery_type: String)
signal robbery_completed(robbery_type: String, reward: int, caught: bool)
signal robbery_failed(robbery_type: String, reason: String)

var player_stats
var police_system
var time_system

# Типы ограблений
var robberies = {
	"shop": {
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
	"apartment": {
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
	"warehouse": {
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
	"car_dealership": {
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
	"bank": {
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

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	police_system = get_node_or_null("/root/PoliceSystem")
	time_system = get_node_or_null("/root/TimeSystem")
	print("🎭 Система ограблений загружена")

# Показать меню ограблений
func show_robberies_menu(main_node: Node, player_data: Dictionary, location: String = ""):
	# Закрыть предыдущее меню если есть
	var old_menu = main_node.get_node_or_null("RobberiesMenu")
	if old_menu:
		old_menu.queue_free()
		await main_node.get_tree().process_frame

	var menu = CanvasLayer.new()
	menu.name = "RobberiesMenu"
	main_node.add_child(menu)

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
			start_robbery(robbery_id, main_node, player_data)
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
		time_system.advance_time(int(robbery["duration"]))

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
	player_data["money"] += reward

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
