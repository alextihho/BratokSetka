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
			if roll < 0.4:
				return "combat"
			elif roll < 0.6:
				return "meet_npc"
			elif roll < 0.8:
				return "find_money"
			else:
				return "find_item"
		
		"ПОРТ":
			if roll < 0.5:
				return "combat"
			elif roll < 0.7:
				return "find_item"
			else:
				return "meet_npc"
		
		"ВОКЗАЛ":
			if roll < 0.3:
				return "combat"
			elif roll < 0.6:
				return "meet_npc"
			else:
				return "find_money"
		
		_:
			if roll < 0.4:
				return "find_money"
			elif roll < 0.7:
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
