# battle_manager.gd (ИСПРАВЛЕНО - БЕЗ АВТОБИТВЫ)
extends Node

var quest_system
var districts_system

func initialize():
	quest_system = get_node_or_null("/root/QuestSystem")
	districts_system = get_node_or_null("/root/DistrictsSystem")
	print("⚔️ Battle Manager инициализирован (без автостарта)")

func show_enemy_selection_menu(main_node):
	var enemy_menu = CanvasLayer.new()
	enemy_menu.name = "EnemySelectionMenu"
	main_node.add_child(enemy_menu)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 600)
	bg.position = Vector2(110, 340)
	bg.color = Color(0.1, 0.05, 0.05, 0.95)
	enemy_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "ВЫБЕРИ ПРОТИВНИКА"
	title.position = Vector2(230, 360)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	enemy_menu.add_child(title)
	
	var enemies = [
		{"name": "Пьяный (легко)", "type": "drunkard"},
		{"name": "Гопник (нормально)", "type": "gopnik"},
		{"name": "Хулиган (средне)", "type": "thug"},
		{"name": "Бандит (сложно)", "type": "bandit"},
		{"name": "Охранник (очень сложно)", "type": "guard"},
		{"name": "Главарь (босс)", "type": "boss"}
	]
	
	var y_pos = 420
	
	for enemy in enemies:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(460, 50)
		btn.position = Vector2(130, y_pos)
		btn.text = enemy["name"]
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.2, 0.2, 1.0)
		btn.add_theme_stylebox_override("normal", style)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.4, 0.3, 0.3, 1.0)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		btn.add_theme_font_size_override("font_size", 18)
		
		var enemy_type = enemy["type"]
		btn.pressed.connect(func():
			enemy_menu.queue_free()
			start_battle(main_node, enemy_type)
		)
		
		enemy_menu.add_child(btn)
		y_pos += 60
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(460, 50)
	close_btn.position = Vector2(130, 860)
	close_btn.text = "ОТМЕНА"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): enemy_menu.queue_free())
	
	enemy_menu.add_child(close_btn)

func start_battle(main_node, enemy_type: String = "gopnik", is_first_battle: bool = false):
	print("⚔️ Запуск боя: " + enemy_type + " (первый=" + str(is_first_battle) + ")")
	
	var battle_script = load("res://scripts/systems/battle.gd")
	if not battle_script:
		main_node.show_message("❌ Система боёв не найдена!")
		return
	
	var battle = battle_script.new()
	battle.name = "BattleScene"
	main_node.add_child(battle)
	battle.setup(main_node.player_data, enemy_type, is_first_battle)
	
	battle.battle_ended.connect(func(victory):
		if battle.player_data and battle.player_data.has("health"):
			main_node.player_data["health"] = battle.player_data["health"]
		
		if victory:
			main_node.show_message("✅ Победа в бою!")
			if quest_system:
				quest_system.check_quest_progress("combat", {"victory": true})
				quest_system.check_quest_progress("collect", {"balance": main_node.player_data["balance"]})
			
			if districts_system and main_node.current_location:
				var district = districts_system.get_district_by_building(main_node.current_location)
				var influence_gain = 5
				districts_system.add_influence(district, "Игрок", influence_gain)
				main_node.show_message("🏴 Влияние в районе увеличено на " + str(influence_gain) + "%")
		else:
			main_node.show_message("💀 Поражение...")
		
		main_node.update_ui()
	)
