extends Node

signal event_triggered(event_type: String, event_data: Dictionary)

var player_stats
var items_db
var log_system  # ✅ НОВОЕ

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	items_db = get_node_or_null("/root/ItemsDB")
	log_system = get_node_or_null("/root/LogSystem")  # ✅ НОВОЕ
	print("🎲 Система случайных событий загружена")

func trigger_random_event(location: String, player_data: Dictionary, main_node: Node) -> bool:
	var event_chance = randf()
	var chance_threshold = get_location_danger(location)
	
	if event_chance > chance_threshold:
		return false
	
	var event_type = choose_event_type(location)
	
	match event_type:
		"combat":
			start_combat_event(location, player_data, main_node)
			return true
		"find_item":
			find_item_event(player_data, main_node)
			return true
		"find_money":
			find_money_event(player_data, main_node)
			return true
		"meet_npc":
			meet_npc_event(location, player_data, main_node)
			return true
		"choice_event":  # ✅ НОВОЕ: События с выбором
			show_choice_event(player_data, main_node)
			return true

	return false

func get_location_danger(location: String) -> float:
	match location:
		"ОБЩЕЖИТИЕ":
			return 0.95
		"ЛАРЁК":
			return 0.90
		"ГАРАЖ":
			return 0.85
		"РЫНОК":
			return 0.80
		"ВОКЗАЛ":
			return 0.75
		"УЛИЦА":
			return 0.70
		"ПОРТ":
			return 0.60
		_:
			return 0.85

func choose_event_type(location: String) -> String:
	var roll = randf()

	match location:
		"УЛИЦА":
			if roll < 0.25:
				return "combat"
			elif roll < 0.45:
				return "choice_event"  # ✅ НОВОЕ
			elif roll < 0.65:
				return "meet_npc"
			elif roll < 0.85:
				return "find_money"
			else:
				return "find_item"

		"ПОРТ":
			if roll < 0.4:
				return "combat"
			elif roll < 0.6:
				return "find_item"
			elif roll < 0.8:
				return "choice_event"  # ✅ НОВОЕ
			else:
				return "meet_npc"

		"ВОКЗАЛ":
			if roll < 0.2:
				return "combat"
			elif roll < 0.45:
				return "choice_event"  # ✅ НОВОЕ
			elif roll < 0.7:
				return "meet_npc"
			else:
				return "find_money"

		_:
			if roll < 0.3:
				return "find_money"
			elif roll < 0.55:
				return "choice_event"  # ✅ НОВОЕ
			elif roll < 0.8:
				return "meet_npc"
			else:
				return "find_item"

func start_combat_event(location: String, player_data: Dictionary, main_node: Node):
	var enemy_type = choose_enemy_type(location)

	var enemy_names = {
		"gopnik": "Гопник",
		"drunkard": "Пьяный",
		"thug": "Хулиган",
		"bandit": "Бандит",
		"guard": "Охранник",
		"boss": "Главарь"
	}

	var enemy_name = enemy_names.get(enemy_type, "Противник")
	main_node.show_message("⚠️ " + enemy_name + " хочет подраться!")

	# ✅ ХУДОЖЕСТВЕННЫЙ ЛОГ
	if log_system:
		var artistic_texts = {
			"gopnik": [
				"Гопник с кривой ухмылкой преградил путь. Драки не избежать",
				"Местный шпана решил проверить нас на прочность",
				"Гопота подошла 'поговорить'. Разговор будет короткий"
			],
			"drunkard": [
				"Пьяный агрессивно полез в драку. Ну что ж...",
				"Бухой мужик решил выяснить отношения кулаками",
				"Алкаш ищет неприятностей. Пожалуйста, получи"
			],
			"thug": [
				"Хулиган вышел на конфликт. Время показать кто тут главный",
				"Местная шпана хочет разборок. Будут разборки",
				"Наглый тип пытается нас запугать. Не выйдет"
			],
			"bandit": [
				"Бандит вышел на дело. Сейчас будет жарко",
				"Серьёзный противник перекрыл дорогу. Драка неизбежна",
				"Бандюга с ножом решил нас ограбить. Попробуй только"
			]
		}
		var texts = artistic_texts.get(enemy_type, ["Противник напал на нас. Начинаем бой"])
		log_system.add_attack_log(texts[randi() % texts.size()])

	await main_node.get_tree().create_timer(1.5).timeout
	
	var battle_script = load("res://scripts/systems/battle.gd")
	if battle_script:
		var battle = battle_script.new()
		main_node.add_child(battle)
		battle.setup(player_data, enemy_type)
		
		battle.battle_ended.connect(func(victory):
			if victory:
				main_node.show_message("✅ Победа!")
				main_node.update_ui()
			else:
				main_node.show_message("💀 Поражение...")
				main_node.update_ui()
		)

func choose_enemy_type(location: String) -> String:
	var roll = randf()
	
	match location:
		"УЛИЦА":
			if roll < 0.5:
				return "gopnik"
			elif roll < 0.8:
				return "thug"
			else:
				return "drunkard"
		
		"ПОРТ":
			if roll < 0.4:
				return "bandit"
			elif roll < 0.7:
				return "thug"
			else:
				return "guard"
		
		"ВОКЗАЛ":
			if roll < 0.6:
				return "gopnik"
			else:
				return "thug"
		
		_:
			if roll < 0.7:
				return "gopnik"
			else:
				return "thug"

func find_item_event(player_data: Dictionary, main_node: Node):
	var possible_items = [
		"Булка", "Сигареты", "Пиво", "Продукты"
	]

	var luck = player_stats.get_stat("LCK") if player_stats else 1
	var rare_chance = 0.1 + luck * 0.02

	var found_item = ""

	if randf() < rare_chance:
		var rare_items = ["Кожанка", "Бита", "Отмычка", "Аптечка"]
		found_item = rare_items[randi() % rare_items.size()]
		main_node.show_message("✨ Редкая находка: " + found_item + "!")
		# ✅ ХУДОЖЕСТВЕННЫЙ ЛОГ
		if log_system:
			var artistic_texts = [
				"В закоулке нашлась неплохая вещица: %s. Судьба улыбается!" % found_item,
				"Бродя по улицам, наткнулись на ценную находку: %s" % found_item,
				"Удача! Кто-то потерял, мы нашли: %s" % found_item
			]
			log_system.add_event_log(artistic_texts[randi() % artistic_texts.size()])
	else:
		found_item = possible_items[randi() % possible_items.size()]
		main_node.show_message("🔍 Нашли: " + found_item)
		# ✅ ХУДОЖЕСТВЕННЫЙ ЛОГ
		if log_system:
			var artistic_texts = [
				"Подобрали %s с земли. Пригодится" % found_item,
				"Валялось на дороге: %s. Взяли, не пропадать же добру" % found_item,
				"Нашли %s. Мелочь, а приятно" % found_item
			]
			log_system.add_event_log(artistic_texts[randi() % artistic_texts.size()])

	player_data["inventory"].append(found_item)

	if player_stats:
		player_stats.add_stat_xp("LCK", 5)

func find_money_event(player_data: Dictionary, main_node: Node):
	var luck = player_stats.get_stat("LCK") if player_stats else 1
	var base_amount = randi_range(10, 50)
	var amount = base_amount + luck * 5

	player_data["balance"] += amount
	main_node.show_message("💰 Нашли " + str(amount) + " руб.!")
	main_node.update_ui()

	# ✅ ХУДОЖЕСТВЕННЫЙ ЛОГ
	if log_system:
		var artistic_texts = [
			"Деньги на дороге не валяются? А вот и валялись! Подняли %d рублей" % amount,
			"Удачный день: нашли %d рублей в переулке" % amount,
			"Судьба подкинула %d рублей. Спасибо, жизнь!" % amount,
			"Чей-то косяк - наша прибыль: %d рублей в кармане" % amount
		]
		log_system.add_money_log(artistic_texts[randi() % artistic_texts.size()])

	if player_stats:
		player_stats.add_stat_xp("LCK", 3)

func meet_npc_event(location: String, player_data: Dictionary, main_node: Node):
	var dialogues = get_location_dialogues(location)
	var dialogue = dialogues[randi() % dialogues.size()]

	main_node.show_message(dialogue)

	# ✅ ХУДОЖЕСТВЕННЫЙ ЛОГ
	if log_system:
		var artistic_texts = [
			"Встретили местного. Обменялись парой слов о жизни",
			"Разговор с прохожим. Узнали пару слухов про район",
			"Столкнулись с кентом. Поболтали о том о сём",
			"Старый знакомый поделился новостями. Интересно..."
		]
		log_system.add_event_log(artistic_texts[randi() % artistic_texts.size()])

func get_location_dialogues(location: String) -> Array:
	match location:
		"УЛИЦА":
			return [
				"Прохожий: 'Эй, не найдётся пары рублей?'",
				"Старик: 'Молодёжь пошла не та...'",
				"Кент: 'Слышал, на порту движуха...'",
				"Девушка: 'Извините, где вокзал?'"
			]
		
		"ВОКЗАЛ":
			return [
				"Контакт: 'Ищешь работу? Есть дельце...'",
				"Мент: 'Документы есть?'",
				"Барыга: 'Качественный товар!'"
			]
		
		"РЫНОК":
			return [
				"Торговец: 'Гляди, какой товар!'",
				"Бабка: 'Купи огурчиков!'",
				"Братан: 'Помоги с грузом...'"
			]
		
		"ПОРТ":
			return [
				"Грузчик: 'Порт - не место для прогулок'",
				"Шёпот: 'Интересуешься оружием?'",
				"Охранник: 'Чего тут шляешься?'"
			]
		
		_:
			return [
				"Незнакомец кивает",
				"Кто-то проходит мимо"
			]

# ✅ НОВОЕ: События с выбором решения
func show_choice_event(player_data: Dictionary, main_node: Node):
	var events = [
		{
			"text": "🙏 Бедный человек просит денег на еду. Дать ему 50 рублей?",
			"choices": [
				{"text": "Дать 50₽", "money": -50, "reputation": 5, "item": null},
				{"text": "Пройти мимо", "money": 0, "reputation": 0, "item": null}
			],
			"artistic_log": {
				"give": "Помогли бедняку. Может быть добро вернётся?",
				"refuse": "Прошли мимо просящего. Своя рубаха ближе к телу"
			}
		},
		{
			"text": "👴 Старик предлагает купить старинный нож за 100₽. Купить?",
			"choices": [
				{"text": "Купить", "money": -100, "reputation": 0, "item": "Старинный нож"},
				{"text": "Отказаться", "money": 0, "reputation": 0, "item": null}
			],
			"artistic_log": {
				"give": "Купили старинный нож. Выглядит интересно, может пригодится",
				"refuse": "Не стали покупать нож у старика. Зачем нам старьё?"
			}
		},
		{
			"text": "💼 На земле лежит портфель. Открыть или оставить?",
			"choices": [
				{"text": "Открыть", "money": 0, "reputation": -5, "item": "random"},
				{"text": "Оставить", "money": 0, "reputation": 5, "item": null}
			],
			"artistic_log": {
				"give": "Открыли чужой портфель. Внутри что-то лежало...",
				"refuse": "Не тронули чужой портфель. Не наше - не трогаем"
			}
		},
		{
			"text": "🚬 Парни предлагают покурить за компанию. Присоединиться?",
			"choices": [
				{"text": "Да", "money": 0, "reputation": 10, "item": null},
				{"text": "Нет", "money": 0, "reputation": 0, "item": null}
			],
			"artistic_log": {
				"give": "Покурили с местными. Познакомились, обсудили дела района",
				"refuse": "Отказались от предложения. Не курим, спасибо"
			}
		},
		{
			"text": "🎰 Уличный наперстки. Поставить 100₽ на удачу?",
			"choices": [
				{"text": "Играть", "money": 0, "reputation": 0, "item": "gamble"},
				{"text": "Не играть", "money": 0, "reputation": 0, "item": null}
			],
			"artistic_log": {
				"give": "Попробовали удачу в наперстки...",
				"refuse": "Не стали играть в наперстки. Не лохи"
			}
		}
	]

	var event = events[randi() % events.size()]

	# Создаём меню выбора
	var choice_layer = CanvasLayer.new()
	choice_layer.name = "ChoiceEventLayer"
	choice_layer.layer = 250
	main_node.add_child(choice_layer)

	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_layer.add_child(overlay)

	var bg = ColorRect.new()
	bg.size = Vector2(680, 400)
	bg.position = Vector2(20, 440)
	bg.color = Color(0.1, 0.1, 0.15, 0.98)
	choice_layer.add_child(bg)

	var title = Label.new()
	title.text = "🎯 СОБЫТИЕ"
	title.position = Vector2(280, 460)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	choice_layer.add_child(title)

	var event_text = Label.new()
	event_text.text = event["text"]
	event_text.position = Vector2(60, 520)
	event_text.add_theme_font_size_override("font_size", 18)
	event_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	event_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	event_text.custom_minimum_size = Vector2(600, 100)
	choice_layer.add_child(event_text)

	var y_pos = 640
	for i in range(event["choices"].size()):
		var choice = event["choices"][i]
		var choice_btn = Button.new()
		choice_btn.custom_minimum_size = Vector2(640, 60)
		choice_btn.position = Vector2(40, y_pos)
		choice_btn.text = choice["text"]
		choice_btn.z_index = 10

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.5, 0.3, 1.0) if i == 0 else Color(0.5, 0.3, 0.3, 1.0)
		choice_btn.add_theme_stylebox_override("normal", style)

		choice_btn.add_theme_font_size_override("font_size", 20)

		var ch = choice.duplicate()
		var art_log_key = "give" if i == 0 else "refuse"
		choice_btn.pressed.connect(func():
			handle_choice(player_data, main_node, ch, event["artistic_log"][art_log_key], choice_layer)
		)
		choice_layer.add_child(choice_btn)

		y_pos += 80

func handle_choice(player_data: Dictionary, main_node: Node, choice: Dictionary, artistic_log: String, choice_layer: CanvasLayer):
	# Применяем последствия
	if choice["money"] != 0:
		if player_data["balance"] + choice["money"] < 0:
			main_node.show_message("❌ Недостаточно денег!")
			choice_layer.queue_free()
			return
		player_data["balance"] += choice["money"]

	if choice["reputation"] != 0:
		player_data["reputation"] = player_data.get("reputation", 0) + choice["reputation"]

	# Особые случаи
	if choice["item"] == "random":
		# Случайный предмет из портфеля
		var items = ["Аптечка", "Документы", "Деньги", "Пустой портфель"]
		var item = items[randi() % items.size()]
		if item == "Деньги":
			var amount = randi_range(50, 200)
			player_data["balance"] += amount
			main_node.show_message("💰 В портфеле было %d₽!" % amount)
		elif item != "Пустой портфель":
			player_data["inventory"].append(item)
			main_node.show_message("📦 В портфеле: " + item)
		else:
			main_node.show_message("❌ Портфель пустой")

	elif choice["item"] == "gamble":
		# Азартная игра
		if player_data["balance"] < 100:
			main_node.show_message("❌ Недостаточно денег!")
			choice_layer.queue_free()
			return

		player_data["balance"] -= 100
		if randf() < 0.4:  # 40% шанс выиграть
			var winnings = randi_range(150, 300)
			player_data["balance"] += winnings
			main_node.show_message("🎰 ВЫИГРЫШ! +%d₽" % winnings)
			if log_system:
				log_system.add_event_log("Сыграли в наперстки и ВЫИГРАЛИ %d рублей! Удача!" % winnings)
		else:
			main_node.show_message("💸 Проиграли 100₽")
			if log_system:
				log_system.add_event_log("Сыграли в наперстки и проиграли. Лохотрон...")

	elif choice["item"]:
		# Обычный предмет
		player_data["inventory"].append(choice["item"])
		main_node.show_message("📦 Получено: " + choice["item"])

	# Художественный лог
	if log_system and artistic_log:
		log_system.add_event_log(artistic_log)

	main_node.update_ui()
	choice_layer.queue_free()
