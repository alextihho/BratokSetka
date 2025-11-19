# robbery_system.gd - Система ограблений
extends Node

# ✅ ИМПОРТ МОДУЛЕЙ
const RobberyDefinitions = preload("res://scripts/systems/robbery_stages/robbery_definitions.gd")
const RobberyGenerator = preload("res://scripts/systems/robbery_stages/robbery_generator.gd")
const PlanningStage = preload("res://scripts/systems/robbery_stages/planning_stage.gd")
const EntryStage = preload("res://scripts/systems/robbery_stages/entry_stage.gd")
const ActionStage = preload("res://scripts/systems/robbery_stages/action_stage.gd")
const EscapeStage = preload("res://scripts/systems/robbery_stages/escape_stage.gd")
const SkillCheckSystem = preload("res://scripts/systems/skill_check_system.gd")

signal robbery_started(robbery_type: String)
signal robbery_completed(robbery_type: String, reward: int, caught: bool)
signal robbery_failed(robbery_type: String, reason: String)

var player_stats
var police_system
var time_system

# ✅ ИСПОЛЬЗУЕМ ОПРЕДЕЛЕНИЯ ИЗ МОДУЛЯ
var robberies = RobberyDefinitions.ROBBERIES

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

# ✅ ЭТАП 1: Планирование (ИСПОЛЬЗУЕМ МОДУЛЬ)
func show_planning_stage(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]
	PlanningStage.show(main_node, player_data, robbery, robbery_state,
		func(approach): on_approach_selected(approach, main_node, player_data), self)

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

# ✅ ЭТАП 2: Проникновение (ИСПОЛЬЗУЕМ МОДУЛЬ)
func show_entry_stage(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]
	EntryStage.show(main_node, player_data, robbery, robbery_state,
		func(entry_method): on_entry_selected(entry_method, main_node, player_data), player_stats, self)

# Обработка выбора способа проникновения
func on_entry_selected(entry_method: String, main_node: Node, player_data: Dictionary):
	robbery_state["entry_method"] = entry_method

	# Закрыть текущее меню
	var menu = main_node.get_node_or_null("RobberyStageMenu")
	if menu:
		menu.queue_free()

	# ✅ НОВОЕ: Проверка навыка перед переходом
	var robbery = robberies[robbery_state["robbery_id"]]

	# Проверяем есть ли требования для этого метода проникновения
	if robbery.has("entry_requirements") and robbery["entry_requirements"].has(entry_method):
		var req = robbery["entry_requirements"][entry_method]
		var security = robbery.get("security_level", 1)

		# Делаем проверку навыка
		var check_result = SkillCheckSystem.check_skill(
			player_data,
			player_stats,
			req["stat"],
			req["min"],
			security,
			req["tool"]
		)

		# Начисляем опыт
		if player_stats and check_result["xp_gained"] > 0:
			player_stats.add_stat_xp(check_result["stat_used"], check_result["xp_gained"])
			print("📈 +%d XP к %s" % [check_result["xp_gained"], check_result["stat_used"]])

		# Добавляем время
		if time_system and check_result["time_spent"] > 0:
			time_system.add_minutes(check_result["time_spent"])

		# При провале - показываем сообщение и возвращаемся на этот же этап
		if not check_result["success"]:
			main_node.show_message("❌ ПРОВАЛ\n\n" + check_result["reason"] + "\n\n+%d XP %s" % [check_result["xp_gained"], check_result["stat_used"]])
			main_node.update_ui()

			# Ждем чтобы игрок увидел сообщение
			await main_node.get_tree().create_timer(2.0).timeout

			# Возвращаемся на этап проникновения
			show_entry_stage(main_node, player_data)
			return

		# Успех - показываем сообщение и продолжаем
		main_node.show_message("✅ УСПЕХ\n\nВы успешно проникли внутрь!\n\n+%d XP %s" % [check_result["xp_gained"], check_result["stat_used"]])
		main_node.update_ui()

		await main_node.get_tree().create_timer(1.5).timeout

	# ✅ Применяем модификаторы из модуля
	EntryStage.apply_modifiers(entry_method, robbery_state, player_stats)

	# Переход к следующему этапу
	robbery_state["stage"] = 2
	show_action_stage(main_node, player_data)

# ✅ ЭТАП 3: Действие (ИСПОЛЬЗУЕМ МОДУЛЬ)
func show_action_stage(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]
	ActionStage.show(main_node, player_data, robbery, robbery_state,
		func(loot_amount): on_action_selected(loot_amount, main_node, player_data), self)

# Обработка выбора количества добычи
func on_action_selected(loot_amount: String, main_node: Node, player_data: Dictionary):
	robbery_state["loot_amount"] = loot_amount

	# ✅ Применяем модификаторы из модуля
	ActionStage.apply_modifiers(loot_amount, robbery_state)

	# Закрыть текущее меню
	var menu = main_node.get_node_or_null("RobberyStageMenu")
	if menu:
		menu.queue_free()

	# Переход к следующему этапу
	robbery_state["stage"] = 3
	show_escape_stage(main_node, player_data)

# ✅ ЭТАП 4: Побег (ИСПОЛЬЗУЕМ МОДУЛЬ)
func show_escape_stage(main_node: Node, player_data: Dictionary):
	var robbery = robberies[robbery_state["robbery_id"]]
	EscapeStage.show(main_node, player_data, robbery, robbery_state,
		func(escape_method): on_escape_selected(escape_method, main_node, player_data), self)

# Обработка выбора способа побега
func on_escape_selected(escape_method: String, main_node: Node, player_data: Dictionary):
	robbery_state["escape_method"] = escape_method

	# ✅ Применяем модификаторы из модуля
	EscapeStage.apply_modifiers(escape_method, robbery_state)

	# ✅ ФИКС: Сначала закрыть меню, потом завершить ограбление
	var menu = main_node.get_node_or_null("RobberyStageMenu")
	if menu:
		menu.queue_free()

	# Ждем следующий кадр чтобы меню точно закрылось
	await main_node.get_tree().process_frame

	# Завершить ограбление
	robbery_state["stage"] = 4
	complete_robbery_stepwise(main_node, player_data)

# ✅ Генерация художественного текста (ИСПОЛЬЗУЕМ МОДУЛЬ)
func generate_robbery_story(robbery: Dictionary, caught: bool, reward: int) -> String:
	return RobberyGenerator.generate_story(robbery_state, robbery, caught, reward)

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

	# ✅ КРИТИЧЕСКИЙ ФИКС: Закрываем все окна ограблений ПОСЛЕ show_message
	await main_node.get_tree().process_frame
	await main_node.get_tree().process_frame

	var old_menu = main_node.get_node_or_null("RobberiesMenu")
	if old_menu:
		print("🗑️ Удаляем RobberiesMenu")
		old_menu.queue_free()

	var stage_menu = main_node.get_node_or_null("RobberyStageMenu")
	if stage_menu:
		print("🗑️ Удаляем RobberyStageMenu")
		stage_menu.queue_free()

	# Проверяем все дочерние узлы на наличие окон ограблений
	for child in main_node.get_children():
		if child.name in ["RobberiesMenu", "RobberyStageMenu"]:
			print("🗑️ Принудительно удаляем оставшийся узел: " + child.name)
			child.queue_free()

	# ✅ НОВОЕ: Проверка вызова полиции ПОСЛЕ ограбления (100% при УА=100)
	if police_system and police_system.ua_level >= 100:
		# Ждем чуть-чуть чтобы игрок увидел результат
		await main_node.get_tree().create_timer(1.5).timeout
		police_system.check_police_after_crime(main_node)
