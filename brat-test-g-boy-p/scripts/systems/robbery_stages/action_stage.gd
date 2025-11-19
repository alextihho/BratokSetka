# action_stage.gd - Этап действия (сбор добычи)
extends Node

const StageUIHelper = preload("res://scripts/systems/robbery_stages/stage_ui_helper.gd")

# Создать UI этапа действия
static func show(main_node: Node, player_data: Dictionary, robbery: Dictionary, robbery_state: Dictionary, on_action_selected: Callable):
	var window = StageUIHelper.create_stage_window(
		main_node,
		robbery["icon"] + " ДЕЙСТВИЕ",
		"Вы внутри! Сколько времени потратите на сбор ценностей?",
		Color(0.2, 1.0, 0.4, 1.0)
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

	var choices_label = Label.new()
	choices_label.text = "Выбор: %s → %s" % [approach_text, entry_text]
	choices_label.position = Vector2(220, 270)
	choices_label.add_theme_font_size_override("font_size", 14)
	choices_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	stage_menu.add_child(choices_label)

	# Вариант 1: Быстро
	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"💨 БЫСТРО",
		"Берём только самое ценное и уходим.\n+Безопасность, -Награда (60%), -Время",
		func(): on_action_selected.call("quick"),
		true
	)
	y_pos += 140

	# Вариант 2: Умеренно
	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"⚖️ УМЕРЕННО",
		"Действуем расчётливо, берём разумное.\nСредняя награда (100%), средний риск",
		func(): on_action_selected.call("medium"),
		true
	)
	y_pos += 140

	# Вариант 3: Жадно
	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"💰 ЖАДНО",
		"Берём всё, что можем унести!\n+Награда (150%), +Риск, +Время",
		func(): on_action_selected.call("greedy"),
		true
	)

	# Кнопка отмены
	StageUIHelper.create_cancel_button(stage_menu, main_node, player_data)

# Применить модификаторы в зависимости от выбора
static func apply_modifiers(loot_amount: String, robbery_state: Dictionary):
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
