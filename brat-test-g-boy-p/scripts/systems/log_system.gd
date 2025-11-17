# log_system.gd - Система логов с двумя панелями
extends Node

signal log_added(message: String, category: String)

# Массивы логов
var game_logs: Array = []  # Художественные логи (события игры)
var tech_logs: Array = []  # Технические логи (print, debug)
var max_logs: int = 100

# UI элементы
var log_panel: CanvasLayer = null
var game_log_container: VBoxContainer = null  # СПРАВА - художественные
var tech_log_container: VBoxContainer = null  # В ЦЕНТРЕ - технические
var is_visible: bool = true

func _ready():
	print("📜 Система логов готова (2 панели)")

	# Создаем UI сразу
	create_log_ui()

	# ✅ ТЕСТОВЫЕ ЛОГИ для проверки
	await get_tree().create_timer(0.5).timeout
	add_news_log("Игра запущена - Тверь, 02.03.1992")
	add_success_log("Система логов работает!")
	add_system_log("Техническая система инициализирована")

# ✅ Создание UI логов (2 панели)
func create_log_ui():
	# CanvasLayer для логов
	log_panel = CanvasLayer.new()
	log_panel.name = "LogPanel"
	log_panel.layer = 40
	add_child(log_panel)

	# ========== ПАНЕЛЬ СПРАВА: ХУДОЖЕСТВЕННЫЕ ЛОГИ (СОБЫТИЯ ИГРЫ) ==========
	var game_bg = ColorRect.new()
	game_bg.size = Vector2(340, 500)
	game_bg.position = Vector2(370, 720)
	game_bg.color = Color(0.1, 0.15, 0.1, 0.95)
	game_bg.name = "GameLogBackground"
	game_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(game_bg)

	var game_title = Label.new()
	game_title.text = "📜 СОБЫТИЯ"
	game_title.position = Vector2(470, 730)
	game_title.add_theme_font_size_override("font_size", 16)
	game_title.add_theme_color_override("font_color", Color(0.9, 1.0, 0.7))
	game_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(game_title)

	var game_scroll = ScrollContainer.new()
	game_scroll.position = Vector2(380, 760)
	game_scroll.size = Vector2(320, 450)
	game_scroll.name = "GameLogScroll"
	game_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(game_scroll)

	game_log_container = VBoxContainer.new()
	game_log_container.name = "GameLogContainer"
	game_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_scroll.add_child(game_log_container)

	# ========== ПАНЕЛЬ В ЦЕНТРЕ: ТЕХНИЧЕСКИЕ ЛОГИ ==========
	var tech_bg = ColorRect.new()
	tech_bg.size = Vector2(350, 300)
	tech_bg.position = Vector2(10, 920)
	tech_bg.color = Color(0.1, 0.1, 0.15, 0.9)
	tech_bg.name = "TechLogBackground"
	tech_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(tech_bg)

	var tech_title = Label.new()
	tech_title.text = "🔧 ТЕХН. ЛОГИ"
	tech_title.position = Vector2(140, 930)
	tech_title.add_theme_font_size_override("font_size", 14)
	tech_title.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	tech_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(tech_title)

	var tech_scroll = ScrollContainer.new()
	tech_scroll.position = Vector2(20, 960)
	tech_scroll.size = Vector2(330, 250)
	tech_scroll.name = "TechLogScroll"
	tech_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(tech_scroll)

	tech_log_container = VBoxContainer.new()
	tech_log_container.name = "TechLogContainer"
	tech_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tech_scroll.add_child(tech_log_container)

func add_log(message: String, category: String = "info"):
	var time_system = get_node_or_null("/root/TimeSystem")
	var time_str = "??:??"
	if time_system:
		time_str = time_system.get_time_string()

	var log_entry = {
		"message": message,
		"category": category,
		"time": time_str
	}

	# Разделяем логи
	if category in ["debug", "system", "movement"]:
		tech_logs.insert(0, log_entry)
		if tech_logs.size() > max_logs:
			tech_logs.resize(max_logs)
		update_tech_log_display()
	else:
		game_logs.insert(0, log_entry)
		if game_logs.size() > max_logs:
			game_logs.resize(max_logs)
		update_game_log_display()

	log_added.emit(message, category)
	print("📜 [%s] %s: %s" % [log_entry["time"], category.to_upper(), message])

func add_news_log(message: String):
	add_log(message, "news")

func add_attack_log(message: String):
	add_log(message, "attack")

func add_success_log(message: String):
	add_log(message, "success")

func add_combat_log(message: String):
	add_log(message, "combat")

func add_money_log(message: String):
	add_log(message, "money")

func add_quest_log(message: String):
	add_log(message, "quest")

func add_event_log(message: String):
	add_log(message, "event")

func add_movement_log(message: String):
	add_log(message, "movement")

func add_debug_log(message: String):
	add_log(message, "debug")

func add_system_log(message: String):
	add_log(message, "system")

func update_game_log_display():
	if not game_log_container or not is_instance_valid(game_log_container):
		return

	for child in game_log_container.get_children():
		child.queue_free()

	var logs_to_show = min(20, game_logs.size())

	for i in range(logs_to_show):
		var log_entry = game_logs[i]
		var log_label = Label.new()

		var display_text = "[%s] %s" % [log_entry["time"], log_entry["message"]]
		log_label.text = display_text

		var color = get_category_color(log_entry["category"])
		log_label.add_theme_color_override("font_color", color)
		log_label.add_theme_font_size_override("font_size", 12)
		log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_label.custom_minimum_size = Vector2(300, 0)

		game_log_container.add_child(log_label)

func update_tech_log_display():
	if not tech_log_container or not is_instance_valid(tech_log_container):
		return

	for child in tech_log_container.get_children():
		child.queue_free()

	var logs_to_show = min(15, tech_logs.size())

	for i in range(logs_to_show):
		var log_entry = tech_logs[i]
		var log_label = Label.new()

		var display_text = "[%s] %s" % [log_entry["time"], log_entry["message"]]
		log_label.text = display_text

		log_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		log_label.add_theme_font_size_override("font_size", 11)
		log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_label.custom_minimum_size = Vector2(310, 0)

		tech_log_container.add_child(log_label)

func get_category_color(category: String) -> Color:
	match category:
		"news":
			return Color(0.95, 0.85, 0.55)
		"attack", "combat":
			return Color(1.0, 0.3, 0.3)
		"success", "money":
			return Color(0.3, 1.0, 0.3)
		"quest":
			return Color(0.3, 0.8, 1.0)
		"event":
			return Color(1.0, 0.7, 0.3)
		"movement", "debug", "system":
			return Color(0.7, 0.7, 0.7)
		_:
			return Color(0.9, 0.9, 0.9)

func toggle_logs():
	if log_panel:
		is_visible = !is_visible
		log_panel.visible = is_visible

func show_logs():
	if log_panel:
		is_visible = true
		log_panel.visible = true

func hide_logs():
	if log_panel:
		is_visible = false
		log_panel.visible = false

func get_recent_logs(count: int = 10) -> Array:
	return game_logs.slice(0, min(count, game_logs.size()))

func clear_logs():
	game_logs.clear()
	tech_logs.clear()
	update_game_log_display()
	update_tech_log_display()

func get_logs_by_category(category: String) -> Array:
	var filtered = []
	for log in game_logs:
		if log["category"] == category:
			filtered.append(log)
	for log in tech_logs:
		if log["category"] == category:
			filtered.append(log)
	return filtered
