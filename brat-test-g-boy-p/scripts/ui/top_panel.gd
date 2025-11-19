extends CanvasLayer

func create_top_panel():
	# Фон верхней панели
	var top_panel = ColorRect.new()
	top_panel.size = Vector2(720, 60)
	top_panel.position = Vector2(0, 0)
	top_panel.color = Color.BLACK
	top_panel.name = "TopPanel"
	add_child(top_panel)
	
	# Аватар (красный кружок)
	var avatar = ColorRect.new()
	avatar.size = Vector2(40, 40)
	avatar.position = Vector2(10, 10)
	avatar.color = Color.RED
	avatar.name = "Avatar"
	add_child(avatar)
	
	# Здоровье
	var health_label = Label.new()
	health_label.text = "♥ 100/100"
	health_label.position = Vector2(60, 20)
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.name = "HealthLabel"
	add_child(health_label)
	
	# Деньги
	var money_label = Label.new()
	money_label.text = "💰 150 руб"
	money_label.position = Vector2(180, 20)
	money_label.add_theme_font_size_override("font_size", 18)
	money_label.name = "MoneyLabel"
	add_child(money_label)
	
	# Дата
	var date_label = Label.new()
	date_label.text = "📅 01.01.1992"
	date_label.position = Vector2(320, 20)
	date_label.add_theme_font_size_override("font_size", 18)
	date_label.name = "DateLabel"
	add_child(date_label)
	
	# Репутация
	var rep_label = Label.new()
	rep_label.text = "⭐ 0"
	rep_label.position = Vector2(480, 20)
	rep_label.add_theme_font_size_override("font_size", 18)
	rep_label.name = "RepLabel"
	add_child(rep_label)

	# Уровень розыска (УП)
	var wanted_label = Label.new()
	wanted_label.text = "🚔 0"
	wanted_label.position = Vector2(580, 20)
	wanted_label.add_theme_font_size_override("font_size", 18)
	wanted_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))  # Зеленый по умолчанию
	wanted_label.name = "WantedLabel"
	add_child(wanted_label)

func update_ui(player_data, player_stats, game_time):
	get_node("MoneyLabel").text = "💰 " + str(player_data["balance"]) + " руб"
	get_node("HealthLabel").text = "♥ " + str(player_stats["health"]) + "/" + str(player_stats["max_health"])
	get_node("DateLabel").text = "📅 " + game_time.get_date_string()
	get_node("RepLabel").text = "⭐ " + str(player_stats["reputation"])

	# Обновление уровня розыска
	var police_system = get_node_or_null("/root/PoliceSystem")
	if police_system:
		var ua = police_system.ua_level
		var wanted_label = get_node("WantedLabel")
		wanted_label.text = "🚔 " + str(ua)

		# Цвет зависит от уровня
		if ua == 0:
			wanted_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))  # Зеленый
		elif ua < 30:
			wanted_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3, 1.0))  # Желтый
		elif ua < 70:
			wanted_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0, 1.0))  # Оранжевый
		else:
			wanted_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))  # Красный
