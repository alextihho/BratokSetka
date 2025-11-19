# escape_stage.gd - Этап побега
extends Node

const StageUIHelper = preload("res://scripts/systems/robbery_stages/stage_ui_helper.gd")

# Создать UI этапа побега
static func show(main_node: Node, player_data: Dictionary, robbery: Dictionary, robbery_state: Dictionary, on_escape_selected: Callable, robbery_system):
	var window = StageUIHelper.create_stage_window(
		main_node,
		robbery["icon"] + " ПОБЕГ",
		"Добыча взята! Пора сваливать. Как будете уходить?",
		Color(1.0, 0.3, 0.3, 1.0)
	)
	var stage_menu = window["menu"]
	var y_pos = window["y_start"]

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

	# Вариант 1: Тихо уйти
	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"🥷 ТИХО УЙТИ",
		"Незаметно выскользнуть.\n-Шанс встретить патруль, нормальное время",
		func(): stage_menu.queue_free(); on_escape_selected.call("sneak"),
		true
	)
	y_pos += 140

	# Вариант 2: Бежать
	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"🏃 БЕЖАТЬ",
		"Быстро свалить, не обращая внимания.\n+Шанс патруля заметить, -Время",
		func(): stage_menu.queue_free(); on_escape_selected.call("run"),
		true
	)
	y_pos += 140

	# Вариант 3: На машине (если есть)
	var has_car = player_data.get("car", null) != null
	var car_ready = player_data.get("car_equipped", false)
	var can_drive = has_car and car_ready

	var car_desc = "Рвануть на тачке!\n"
	if not has_car:
		car_desc += "У вас нет машины! [ТРЕБУЕТСЯ МАШИНА]"
	elif not car_ready:
		car_desc += "Машина не готова! Назначьте водителя"
	else:
		car_desc += "Очень быстро, +Шум"

	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"🚗 НА МАШИНЕ",
		car_desc,
		func(): stage_menu.queue_free(); on_escape_selected.call("car"),
		can_drive
	)

	# Кнопка отмены
	StageUIHelper.create_cancel_button(stage_menu, main_node, player_data, robbery_system)

# Применить модификаторы в зависимости от выбора
static func apply_modifiers(escape_method: String, robbery_state: Dictionary):
	match escape_method:
		"sneak":
			robbery_state["modifiers"]["police_chance"] -= 0.15
		"run":
			robbery_state["modifiers"]["police_chance"] += 0.1
			robbery_state["modifiers"]["time_mult"] *= 0.8
		"car":
			robbery_state["modifiers"]["alarm_chance"] += 0.1
			robbery_state["modifiers"]["time_mult"] *= 0.6
