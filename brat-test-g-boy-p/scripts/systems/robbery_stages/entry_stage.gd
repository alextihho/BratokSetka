# entry_stage.gd - Этап проникновения
extends Node

const StageUIHelper = preload("res://scripts/systems/robbery_stages/stage_ui_helper.gd")

# Создать UI этапа проникновения
static func show(main_node: Node, player_data: Dictionary, robbery: Dictionary, robbery_state: Dictionary, on_entry_selected: Callable):
	var window = StageUIHelper.create_stage_window(
		main_node,
		robbery["icon"] + " ПРОНИКНОВЕНИЕ",
		"Вы подобрались к цели. Как будете проникать внутрь?",
		Color(0.2, 0.8, 1.0, 1.0)
	)
	var stage_menu = window["menu"]
	var y_pos = window["y_start"]

	# Показать выбранный подход
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

	# Получить player_stats
	var player_stats = get_node_or_null("/root/PlayerStatsSystem")

	# Вариант 1: Взломать замок
	var has_lockpick = player_data.get("has_lockpick", false) or (player_stats and player_stats.get_stat("AGI") >= 7)
	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"🔓 ВЗЛОМАТЬ ЗАМОК",
		"Тихо вскрыть замок. Требует навыка или отмычки.\n-Шанс сигнализации" + ("" if has_lockpick else " [ТРЕБУЕТСЯ AGI 7+]"),
		func(): on_entry_selected.call("lockpick"),
		has_lockpick
	)
	y_pos += 140

	# Вариант 2: Через окно
	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"🪟 ЧЕРЕЗ ОКНО",
		"Пролезть через окно. Быстро, но рискованно.\n+Шанс сигнализации, -Время",
		func(): on_entry_selected.call("window"),
		true
	)
	y_pos += 140

	# Вариант 3: Договориться
	var has_charisma = player_stats and player_stats.get_stat("CHA") >= 6
	StageUIHelper.create_choice_button(
		stage_menu,
		y_pos,
		"🗣️ ДОГОВОРИТЬСЯ",
		"Обмануть охрану или уговорить пустить.\n" + ("Шанс зависит от харизмы" if has_charisma else "Высокий риск провала [ТРЕБУЕТСЯ CHA 6+]"),
		func(): on_entry_selected.call("talk"),
		true
	)

	# Кнопка отмены
	StageUIHelper.create_cancel_button(stage_menu, main_node, player_data)

# Применить модификаторы в зависимости от выбора
static func apply_modifiers(entry_method: String, robbery_state: Dictionary, player_data: Dictionary):
	var player_stats = get_node_or_null("/root/PlayerStatsSystem")

	match entry_method:
		"lockpick":
			robbery_state["modifiers"]["alarm_chance"] -= 0.15
		"window":
			robbery_state["modifiers"]["alarm_chance"] += 0.1
			robbery_state["modifiers"]["time_mult"] *= 0.8
		"talk":
			# Проверка харизмы
			var cha = player_stats.get_stat("CHA") if player_stats else 0
			if cha >= 8:
				robbery_state["modifiers"]["police_chance"] -= 0.15
				robbery_state["modifiers"]["alarm_chance"] -= 0.1
			elif cha >= 6:
				robbery_state["modifiers"]["police_chance"] -= 0.05
			else:
				# Провал разговора
				robbery_state["modifiers"]["alarm_chance"] += 0.2
