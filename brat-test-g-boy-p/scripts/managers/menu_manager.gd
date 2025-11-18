# menu_manager.gd (ИСПРАВЛЕНО - квесты работают!)
extends Node

var gang_manager
var quest_system
var districts_system
var simple_jobs
var player_stats
var save_manager

var player_data: Dictionary
var gang_members: Array

func initialize(p_player_data, p_gang_members):
	player_data = p_player_data
	gang_members = p_gang_members
	
	gang_manager = get_node("/root/GangManager")
	quest_system = get_node_or_null("/root/QuestSystem")
	districts_system = get_node_or_null("/root/DistrictsSystem")
	simple_jobs = get_node_or_null("/root/SimpleJobs")
	player_stats = get_node_or_null("/root/PlayerStats")
	save_manager = get_node("/root/SaveManager")

func show_gang_menu(main_node: Node):
	# ✅ ВАЖНО: Берём актуальный gang_members из main_node, а не устаревшую копию!
	gang_manager.show_gang_menu(main_node, main_node.gang_members)

func show_districts_menu(main_node: Node):
	if not districts_system:
		main_node.show_message("Система районов недоступна")
		return
	main_node.show_districts_menu()

# ✅ ИСПРАВЛЕНО: Убрана заглушка!
func show_quests_menu(main_node: Node):
	if not quest_system:
		quest_system = get_node_or_null("/root/QuestSystem")
	
	if quest_system:
		quest_system.show_quests_menu(main_node)
	else:
		main_node.show_message("❌ Система квестов не найдена!\nПроверь autoload QuestSystem")

func show_main_menu(main_node: Node):
	var menu_layer = CanvasLayer.new()
	menu_layer.name = "MainMenuLayer"
	menu_layer.layer = 200
	main_node.add_child(menu_layer)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 850)
	bg.position = Vector2(110, 215)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	menu_layer.add_child(bg)
	
	var title = Label.new()
	title.text = "МЕНЮ"
	title.position = Vector2(310, 245)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	menu_layer.add_child(title)
	
	var options = ["Продолжить", "Сохранить игру", "Загрузить игру", "Квесты", "Инвентарь", "Статистика", "Читы", "Тест бой", "Выход"]
	var y_pos = 320
	
	for option in options:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(460, 50)
		btn.position = Vector2(130, y_pos)
		btn.text = option
		btn.name = "MenuOption_" + option
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.25, 0.25, 0.3, 1.0)
		btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.35, 0.35, 0.4, 1.0)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", Color.WHITE)
		
		var current_option = option
		btn.pressed.connect(func(): handle_menu_option(current_option, main_node))
		
		menu_layer.add_child(btn)
		y_pos += 70
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(460, 50)
	close_btn.position = Vector2(130, 1000)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.name = "CloseMainMenu"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): 
		var menu = main_node.get_node_or_null("MainMenuLayer")
		if menu:
			menu.queue_free()
	)
	menu_layer.add_child(close_btn)

func handle_menu_option(option: String, main_node: Node):
	print("🎮 === ОБРАБОТКА МЕНЮ: %s ===" % option)
	var menu_layer = main_node.get_node_or_null("MainMenuLayer")

	match option:
		"Продолжить":
			if menu_layer:
				menu_layer.queue_free()
		
		"Сохранить игру":
			save_game(main_node)
		
		"Загрузить игру":
			load_game(main_node)
		
		"Квесты":
			if menu_layer:
				menu_layer.queue_free()
			show_quests_menu(main_node)
		
		"Инвентарь":
			if menu_layer:
				menu_layer.queue_free()
			var inventory_manager = get_node("/root/InventoryManager")
			inventory_manager.show_inventory_for_member(main_node, 0, main_node.gang_members, main_node.player_data)
		
		"Статистика":
			if menu_layer:
				menu_layer.queue_free()
			show_stats_window(main_node)

		"Читы":
			if menu_layer:
				menu_layer.queue_free()
			show_cheats_menu(main_node)

		"Тест бой":
			if menu_layer:
				menu_layer.queue_free()
			main_node.show_enemy_selection_menu()
		
		"Выход":
			main_node.get_tree().quit()

func save_game(main_node: Node):
	print("💾 === НАЧАЛО СОХРАНЕНИЯ ===")

	if not save_manager:
		save_manager = get_node_or_null("/root/SaveManager")
		print("   Получаем SaveManager: %s" % ("✅ OK" if save_manager else "❌ NULL"))

	if not save_manager:
		print("❌ SaveManager не найден!")
		main_node.show_message("❌ Система сохранений недоступна!")
		return

	print("   Сохраняем данные игрока...")
	print("   - Деньги: %d" % main_node.player_data.get("balance", 0))
	print("   - HP: %d" % main_node.player_data.get("health", 100))
	print("   - Банда: %d человек" % main_node.gang_members.size())

	# ✅ ВАЖНО: Берём актуальные данные из main_node
	var success = save_manager.save_game(
		main_node.player_data,
		main_node.gang_members
	)

	print("   Результат: %s" % ("✅ SUCCESS" if success else "❌ FAILED"))

	if success:
		main_node.show_message("💾 Игра сохранена!")
	else:
		main_node.show_message("❌ Ошибка сохранения!")

	print("💾 === КОНЕЦ СОХРАНЕНИЯ ===")

func load_game(main_node: Node):
	print("📂 === НАЧАЛО ЗАГРУЗКИ ===")

	if not save_manager:
		save_manager = get_node_or_null("/root/SaveManager")
		print("   Получаем SaveManager: %s" % ("✅ OK" if save_manager else "❌ NULL"))

	if not save_manager:
		print("❌ SaveManager не найден!")
		main_node.show_message("❌ Система сохранений недоступна!")
		return

	print("   Проверяем наличие сохранения...")
	if not save_manager.has_save():
		print("⚠️ Файл сохранения не найден")
		main_node.show_message("⚠️ Нет сохранённой игры!")
		return

	print("   ✅ Сохранение найдено, загружаем...")
	var save_data = save_manager.load_game()

	if save_data.is_empty():
		print("❌ Сохранение пустое или повреждено")
		main_node.show_message("❌ Ошибка загрузки!")
		return

	print("   ✅ Данные загружены, восстанавливаем игру...")
	main_node.load_game_from_data(save_data)

	main_node.show_message("✅ Игра загружена!")

	var menu_layer = main_node.get_node_or_null("MainMenuLayer")
	if menu_layer:
		menu_layer.queue_free()

	print("📂 === КОНЕЦ ЗАГРУЗКИ ===")

func show_stats_window(main_node: Node):
	if not player_stats:
		main_node.show_message("Статистика недоступна")
		return
	
	var stats_popup = CanvasLayer.new()
	stats_popup.name = "StatsPopup"
	stats_popup.layer = 200
	main_node.add_child(stats_popup)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_popup.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(680, 950)
	bg.position = Vector2(20, 165)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	stats_popup.add_child(bg)
	
	var title = Label.new()
	title.text = "📊 СТАТИСТИКА"
	title.position = Vector2(250, 185)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	stats_popup.add_child(title)
	
	var stats_text = player_stats.get_stats_text()
	var label = Label.new()
	label.text = stats_text
	label.position = Vector2(40, 235)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color.WHITE)
	stats_popup.add_child(label)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(640, 50)
	close_btn.position = Vector2(40, 1050)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): stats_popup.queue_free())
	
	stats_popup.add_child(close_btn)

# ===== МЕНЮ ЧИТОВ =====
func show_cheats_menu(main_node: Node):
	var cheats_popup = CanvasLayer.new()
	cheats_popup.name = "CheatsPopup"
	cheats_popup.layer = 200
	main_node.add_child(cheats_popup)

	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	cheats_popup.add_child(overlay)

	var bg = ColorRect.new()
	bg.size = Vector2(680, 1100)
	bg.position = Vector2(20, 90)
	bg.color = Color(0.1, 0.05, 0.15, 0.98)
	cheats_popup.add_child(bg)

	var title = Label.new()
	title.text = "🎮 ЧИТЫ"
	title.position = Vector2(290, 110)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 1.0, 1.0))
	cheats_popup.add_child(title)

	var y_pos = 180

	# === ДЕНЬГИ ===
	var money_title = Label.new()
	money_title.text = "💰 ДЕНЬГИ"
	money_title.position = Vector2(40, y_pos)
	money_title.add_theme_font_size_override("font_size", 24)
	money_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	cheats_popup.add_child(money_title)

	# ✅ НОВОЕ: Текущий баланс
	var money_current = Label.new()
	money_current.text = "Текущий: %d руб." % main_node.player_data.get("balance", 0)
	money_current.position = Vector2(400, y_pos)
	money_current.add_theme_font_size_override("font_size", 18)
	money_current.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3, 1.0))
	cheats_popup.add_child(money_current)
	y_pos += 40

	var money_amounts = [1000, 5000, 10000]
	for amount in money_amounts:
		var btn = create_cheat_button("+%d руб." % amount, Vector2(40, y_pos), Vector2(200, 50))
		btn.pressed.connect(func():
			cheat_add_money(main_node, amount)
			money_current.text = "Текущий: %d руб." % main_node.player_data.get("balance", 0)
		)
		cheats_popup.add_child(btn)
		y_pos += 60

	y_pos += 20

	# === ЗДОРОВЬЕ ===
	var health_title = Label.new()
	health_title.text = "❤️ ЗДОРОВЬЕ"
	health_title.position = Vector2(40, y_pos)
	health_title.add_theme_font_size_override("font_size", 24)
	health_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	cheats_popup.add_child(health_title)

	# ✅ НОВОЕ: Текущее HP
	var health_current = Label.new()
	health_current.text = "Текущее: %d HP" % main_node.player_data.get("health", 100)
	health_current.position = Vector2(400, y_pos)
	health_current.add_theme_font_size_override("font_size", 18)
	health_current.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	cheats_popup.add_child(health_current)
	y_pos += 40

	var heal_btn = create_cheat_button("Полное исцеление", Vector2(40, y_pos), Vector2(200, 50))
	heal_btn.pressed.connect(func():
		cheat_heal(main_node)
		health_current.text = "Текущее: %d HP" % main_node.player_data.get("health", 100)
	)
	cheats_popup.add_child(heal_btn)
	y_pos += 80

	# === НАВЫКИ ===
	var skills_title = Label.new()
	skills_title.text = "📊 НАВЫКИ"
	skills_title.position = Vector2(40, y_pos)
	skills_title.add_theme_font_size_override("font_size", 24)
	skills_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.8, 1.0))
	cheats_popup.add_child(skills_title)
	y_pos += 40

	# Список навыков
	var skills = ["STR", "AGI", "INT", "CHA", "STEALTH", "DRV"]
	var skill_names = {
		"STR": "Сила",
		"AGI": "Ловкость",
		"INT": "Интеллект",
		"CHA": "Харизма",
		"STEALTH": "Скрытность",
		"DRV": "Вождение"
	}

	# ✅ НОВОЕ: Массив лейблов для обновления
	var skill_current_labels = {}

	for skill in skills:
		var skill_label = Label.new()
		skill_label.text = skill_names[skill] + " (%s)" % skill
		skill_label.position = Vector2(40, y_pos)
		skill_label.add_theme_font_size_override("font_size", 16)
		skill_label.add_theme_color_override("font_color", Color.WHITE)
		cheats_popup.add_child(skill_label)

		# ✅ НОВОЕ: Текущий уровень навыка
		var skill_current = Label.new()
		var current_level = player_stats.get_stat(skill) if player_stats else 0
		skill_current.text = "Ур. %d" % current_level
		skill_current.position = Vector2(480, y_pos)
		skill_current.add_theme_font_size_override("font_size", 16)
		skill_current.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1.0))
		cheats_popup.add_child(skill_current)
		skill_current_labels[skill] = skill_current

		var levels = [1, 5, 10]
		var x_offset = 250
		for level in levels:
			var skill_btn = create_cheat_button("+%d" % level, Vector2(x_offset, y_pos - 5), Vector2(60, 40))
			var s = skill
			var l = level
			skill_btn.pressed.connect(func():
				cheat_add_skill(main_node, s, l)
				# ✅ ОБНОВЛЯЕМ лейбл после изменения
				var new_level = player_stats.get_stat(s) if player_stats else 0
				skill_current_labels[s].text = "Ур. %d" % new_level
			)
			cheats_popup.add_child(skill_btn)
			x_offset += 70

		y_pos += 50

	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(640, 50)
	close_btn.position = Vector2(40, 1100)
	close_btn.text = "ЗАКРЫТЬ"

	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)

	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): cheats_popup.queue_free())

	cheats_popup.add_child(close_btn)

# Создание кнопки чита
func create_cheat_button(text: String, pos: Vector2, size: Vector2) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = size
	btn.position = pos
	btn.text = text

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.3, 0.2, 0.5, 1.0)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.4, 0.3, 0.6, 1.0)
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color.WHITE)

	return btn

# === ФУНКЦИИ ЧИТОВ ===

func cheat_add_money(main_node: Node, amount: int):
	main_node.player_data["balance"] += amount
	main_node.update_ui()
	main_node.show_message("💰 +%d рублей (ЧИТ)" % amount)
	print("💰 ЧИТ: Добавлено %d рублей" % amount)

func cheat_heal(main_node: Node):
	main_node.player_data["health"] = 100
	main_node.update_ui()
	main_node.show_message("❤️ Полное исцеление (ЧИТ)")
	print("❤️ ЧИТ: Полное исцеление")

func cheat_add_skill(main_node: Node, skill: String, levels: int):
	if not player_stats:
		player_stats = get_node_or_null("/root/PlayerStats")

	if not player_stats:
		main_node.show_message("❌ PlayerStats не найден!")
		return

	# Добавляем уровни
	for i in range(levels):
		player_stats.level_up_stat(skill)

	var current_level = player_stats.get_stat(skill)
	main_node.show_message("📊 %s +%d (текущий: %d) (ЧИТ)" % [skill, levels, current_level])
	print("📊 ЧИТ: %s +%d уровней" % [skill, levels])

func _ready():
	gang_manager = get_node("/root/GangManager")
	quest_system = get_node_or_null("/root/QuestSystem")
