extends Node

signal building_action_completed(location: String, action_index: int)

var items_db
var current_building_menu = null
var log_system  # ✅ НОВОЕ

func _ready():
	items_db = get_node("/root/ItemsDB")
	log_system = get_node_or_null("/root/LogSystem")  # ✅ НОВОЕ

# Обработка действия в здании
func handle_building_action(location: String, action_index: int, player_data: Dictionary, main_node: Node):
	print("🏢 Действие в " + location + ", индекс: " + str(action_index))
	
	# ✅ ДОБАВЛЕНО: Получаем системы времени и полиции
	var time_system = get_node_or_null("/root/TimeSystem")
	var police_system = get_node_or_null("/root/PoliceSystem")
	
	match location:
		"ЛАРЁК":
			handle_kiosk_action(action_index, player_data, main_node, time_system, police_system)
		"ГАРАЖ":
			handle_garage_action(action_index, player_data, main_node, time_system, police_system)
		"РЫНОК":
			handle_market_action(action_index, player_data, main_node, time_system, police_system)
		"ПОРТ":
			handle_port_action(action_index, player_data, main_node, time_system, police_system)
		"ОБЩЕЖИТИЕ":
			handle_dorm_action(action_index, player_data, main_node, time_system, police_system)
		"УЛИЦА":
			handle_street_action(action_index, player_data, main_node, time_system, police_system)
		"ВОКЗАЛ":
			handle_station_action(action_index, player_data, main_node, time_system, police_system)
		"ФСБ":
			handle_fsb_action(action_index, player_data, main_node, time_system, police_system)
		"БОЛЬНИЦА":
			handle_hospital_action(action_index, player_data, main_node, time_system, police_system)
		"АВТОСАЛОН":
			handle_car_dealership_action(action_index, player_data, main_node, time_system, police_system)
		"БАНК":
			handle_bank_action(action_index, player_data, main_node, time_system, police_system)
		"СКЛАД":
			handle_warehouse_action(action_index, player_data, main_node, time_system, police_system)

	building_action_completed.emit(location, action_index)

# ЛАРЁК
func handle_kiosk_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить пиво (30р)
			buy_item("Пиво", player_data, main_node)
			if log_system:
				var texts = [
					"Тёплое пиво в ларьке - классика 90-х. Продавщица даже не смотрит на тебя.",
					"Взял баночку 'Жигулёвского'. Знакомый вкус Твери.",
					"Пиво почти горячее, но какая разница? Главное - есть."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(5)  # ✅ Быстрая покупка
		1: # Купить сигареты (15р)
			buy_item("Сигареты", player_data, main_node)
			if log_system:
				var texts = [
					"'Приму' или 'Беломор'? Выбрал привычные. Прикурю потом.",
					"Сигареты в кармане - значит, день пройдёт нормально.",
					"Продавец молча протянул пачку. Сдачу бросил на прилавок."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(3)
		2: # Купить кепку (50р)
			buy_item("Кепка", player_data, main_node)
			if log_system:
				var texts = [
					"Кепка с прямым козырьком - модно и практично. Теперь выглядишь как свой.",
					"Примерил кепку. Сидит отлично. Теперь в стиле района.",
					"Новая кепка - новый образ. На улицах Твери это важно."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(10)
		3: # 🛒 Черный рынок
			show_black_market(player_data, main_node)
			if log_system:
				log_system.add_event_log("Продавец кивнул в сторону подсобки. 'Там всё есть, что нужно'.")
		4: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "ЛАРЁК")
			if log_system:
				log_system.add_event_log("Оглядываешься по сторонам. Время действовать...")

# ГАРАЖ
func handle_garage_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить биту (100р)
			buy_item("Бита", player_data, main_node)
			if log_system:
				var texts = [
					"Бита алюминиевая, легкая. Мужик в гараже говорит: 'На всякий случай'.",
					"Взвесил биту в руке. Хорошая вещь. На районе пригодится.",
					"'Для самообороны', - усмехнулся продавец, протягивая биту."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(10)
		1: # Помочь механику
			if "Пиво" in player_data["inventory"]:
				player_data["inventory"].erase("Пиво")
				player_data["balance"] += 100
				player_data["reputation"] += 5
				main_node.show_message("Помогли механику! +100 руб., +5 репутации")
				main_node.update_ui()

				# ✅ ХУДОЖЕСТВЕННЫЙ ЛОГ
				if log_system:
					var texts = [
						"Механик Серёга доволен. 'Спасибо за пиво, братан! Держи за работу.' Руки в масле, но сотка в кармане.",
						"Покрутил гайки, подтянул ремень. Механик протянул сотню: 'Нормально работаешь, заходи ещё'.",
						"Пиво ушло за минуту. Работали под капотом часа полтора. Механик расщедрился - отдал сотку и репутацию поднял."
					]
					log_system.add_success_log(texts[randi() % texts.size()])

				# Прокачка силы и вождения за ремонт
				var stats_system = get_node("/root/PlayerStats")
				if stats_system:
					stats_system.add_stat_xp("STR", 10)
					stats_system.add_stat_xp("DRV", 5)

				# ✅ Работа в гараже занимает время
				if time_system:
					time_system.add_minutes(45)
			else:
				main_node.show_message("Механик: 'Принеси пивка!'")
				if log_system:
					log_system.add_event_log("Механик Серёга недовольно смотрит: 'Без пива работать не буду. Принеси баночку!'")
		2: # Взять инструменты
			player_data["inventory"].append("Инструменты")
			main_node.show_message("Взяли инструменты из гаража")

			# ✅ ХУДОЖЕСТВЕННЫЙ ЛОГ
			if log_system:
				var texts = [
					"Набор инструментов валялся в углу. Никто не заметит пропажу.",
					"Отвёртки, ключи, пассатижи - всё пригодится. Сунул в сумку.",
					"Инструменты тяжёлые, но полезные. Механик отвернулся - самое время."
				]
				log_system.add_event_log(texts[randi() % texts.size()])

			# Попытка взлома замка на ящике
			var stats_system = get_node("/root/PlayerStats")
			if stats_system and "Отмычка" in player_data["inventory"]:
				var lockpick_chance = stats_system.calculate_lockpick_chance(0.2)
				if randf() < lockpick_chance:
					player_data["balance"] += 50
					stats_system.on_lockpick_attempt(true)
					main_node.show_message("🔓 Взломали ящик! Нашли 50 руб.")
					if log_system:
						log_system.add_success_log("Отмычка сработала! В ящике лежала заначка - пятьдесят рублей.")
				else:
					stats_system.on_lockpick_attempt(false)
					main_node.show_message("🔒 Не удалось взломать замок")
					if log_system:
						log_system.add_event_log("Замок не поддался. Отмычка гнётся, но толку нет. Может, в другой раз.")

			# ✅ Взлом занимает время
			if time_system:
				time_system.add_minutes(15)
		3: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "ГАРАЖ")
			if log_system:
				log_system.add_event_log("Присматриваешь объекты для дела покрупнее...")

# РЫНОК
func handle_market_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить кожанку (200р)
			buy_item("Кожанка", player_data, main_node)
			if log_system:
				var texts = [
					"Кожанка чёрная, потёртая, но выглядит круто. На рынке таких много, но эта - лучшая.",
					"Примерил кожанку - сидит отлично. Продавец кивнул: 'По тебе видно - пацан с района'.",
					"Кожанка тяжёлая, настоящая. Теперь и в драке защитит, и вид солидный."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(15)
		1: # Продать вещь
			if player_data["inventory"].size() > 0:
				show_sell_menu(player_data, main_node)
				if log_system:
					log_system.add_event_log("Барыги на рынке готовы купить что угодно. Главное - сторговаться.")
				if time_system:
					time_system.add_minutes(20)
			else:
				main_node.show_message("Рюкзак пуст, нечего продавать")
				if log_system:
					log_system.add_event_log("Хотел продать, но рюкзак пустой. Надо сначала что-то раздобыть.")
		2: # Узнать новости
			var news = [
				"Говорят, на порту можно достать ствол...",
				"Слышал, механику в гараже нужна помощь",
				"На вокзале кто-то ищет курьера",
				"В городе появились новые люди"
			]
			var chosen_news = news[randi() % news.size()]
			main_node.show_message(chosen_news)

			# ✅ ХУДОЖЕСТВЕННЫЙ ЛОГ
			if log_system:
				var log_texts = [
					"Перекинулся парой слов с местными. Полезная инфа: " + chosen_news.to_lower(),
					"Мужики на рынке любят поболтать. Услышал: " + chosen_news.to_lower(),
					"Слухи, слухи... Но иногда в них есть правда: " + chosen_news.to_lower()
				]
				log_system.add_event_log(log_texts[randi() % log_texts.size()])

			# Шанс украсть что-то незаметно при посещении рынка
			var player_stats = get_node("/root/PlayerStats")
			if player_stats and randf() < 0.3:  # 30% шанс
				var stealth_check = randf()
				var detection_chance = 0.5 - player_stats.get_stat("STEALTH") * 0.05

				if stealth_check > detection_chance:
					var stolen_items = ["Продукты", "Сигареты", "Булка"]
					var stolen = stolen_items[randi() % stolen_items.size()]
					player_data["inventory"].append(stolen)
					player_stats.on_theft_attempt(false, 25)
					main_node.show_message("🥷 Незаметно украли: " + stolen)
					if log_system:
						var steal_texts = [
							"Пока продавец отвлёкся, стащил %s. Ловко получилось." % stolen,
							"Рука сама потянулась. %s теперь в кармане. Никто не заметил." % stolen,
							"Лёгкая добыча: %s. На рынке всегда можно что-то стянуть." % stolen
						]
						log_system.add_success_log(steal_texts[randi() % steal_texts.size()])
				else:
					player_stats.on_theft_attempt(true, 0)
					# ✅ ДОБАВЛЕНО: Повышаем УА если заметили
					if police_system:
						police_system.on_theft(25)
					main_node.show_message("⚠️ Чуть не заметили при попытке воровства!")
					if log_system:
						log_system.add_attack_log("Продавец резко обернулся! Чуть не попался. Быстро слинял с рынка.")

			# ✅ Время на новости
			if time_system:
				time_system.add_minutes(10)
		3: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "РЫНОК")
			if log_system:
				log_system.add_event_log("Среди толпы на рынке можно провернуть дельце...")

# ПОРТ
func handle_port_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить ПМ (500р)
			buy_item("ПМ", player_data, main_node)
			if log_system:
				var texts = [
					"Пистолет Макарова. Холодный металл в руке. Продавец шепчет: 'Осторожнее с этим'.",
					"ПМ в отличном состоянии. На порту всё достать можно, если есть деньги.",
					"Ствол спрятал глубоко. Мужик на складе говорит: 'Не палься, браток'."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(20)
		1: # Купить отмычку (100р)
			buy_item("Отмычка", player_data, main_node)
			if log_system:
				var texts = [
					"Отмычки тонкие, гибкие. Контрабандист ухмыляется: 'Только для своих дверей, да?'",
					"Набор отмычек в кармане. Теперь большинство замков - не проблема.",
					"Взял отмычки. Продавец намекнул, что в гараже есть интересные ящики..."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(15)
		2: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "ПОРТ")
			if log_system:
				log_system.add_event_log("Контейнеры, склады... Портовая зона полна возможностей...")
		3: # Уйти
			main_node.close_location_menu()

			if log_system:
				log_system.add_event_log("Порт пахнет рыбой и дизелем. Контрабандисты переглядываются...")

			# Шанс встретить контрабандистов (прокачка красноречия)
			var stats_system = get_node("/root/PlayerStats")
			if stats_system and randf() < 0.2:  # 20% шанс
				var cha = stats_system.get_stat("CHA")
				var persuasion_chance = 0.3 + cha * 0.05

				if randf() < persuasion_chance:
					player_data["balance"] += 50
					stats_system.on_persuasion_attempt(true)
					main_node.show_message("💬 Убедили контрабандистов поделиться (+50 руб)")
					if log_system:
						log_system.add_success_log("Поговорил с контрабандистами. Красиво подвесил язык - отдали полтинник. Харизма работает!")
				else:
					stats_system.on_persuasion_attempt(false)
					main_node.show_message("💬 Не удалось договориться с контрабандистами")
					if log_system:
						log_system.add_event_log("Попытался договориться с контрабандистами, но они только посмеялись. Надо прокачать харизму.")

			if time_system:
				time_system.add_minutes(5)

# ОБЩЕЖИТИЕ
func handle_dorm_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Отдохнуть
			var heal_amount = 30
			player_data["health"] = min(100, player_data["health"] + heal_amount)
			main_node.show_message("Хорошо отдохнули (+30 HP)")
			main_node.update_ui()
			if log_system:
				var texts = [
					"Прилёг на свою койку. Два часа сна - и как новенький. Голова больше не болит.",
					"Отдохнул в общаге. Тишина, покой. Силы восстановились.",
					"Поспал пару часов. Соседи не шумели. Здоровье восстановилось на треть."
				]
				log_system.add_success_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(120)  # 2 часа отдыха
		1: # Поговорить с другом
			var dialogues = [
				"Друг: 'Как дела, братан?'",
				"Друг: 'Слышал, на рынке выгодно продают'",
				"Друг: 'Береги себя на улицах'",
				"Друг: 'Может, пива принесёшь?'"
			]
			var chosen_dialogue = dialogues[randi() % dialogues.size()]
			main_node.show_message(chosen_dialogue)
			if log_system:
				var log_texts = [
					"Посидели с кентом, потрепались за жизнь. Он говорит: '%s'" % chosen_dialogue.trim_prefix("Друг: "),
					"Друган в общаге всегда рад поболтать: '%s'" % chosen_dialogue.trim_prefix("Друг: "),
					"Обменялись новостями с кентом. '%s'" % chosen_dialogue.trim_prefix("Друг: ")
				]
				log_system.add_event_log(log_texts[randi() % log_texts.size()])
			if time_system:
				time_system.add_minutes(30)
		2: # Взять вещи
			player_data["inventory"].append("Продукты")
			main_node.show_message("Взяли продукты из общаги")
			if log_system:
				var texts = [
					"В холодильнике нашлась тушёнка и хлеб. Пригодится в дороге.",
					"Забрал продукты из тумбочки. Сухари и консервы - стандартный набор.",
					"Взял еду из общажных запасов. Всё равно никто не заметит."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(5)

# УЛИЦА
func handle_street_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Прогуляться
			var events = [
				"Приятная прогулка по Твери. Ветерок в лицо, знакомые улицы.",
				"Встретили бродячую собаку. Она дружелюбно виляет хвостом.",
				"Нашли 10 рублей на земле! Видно кто-то обронил. Повезло!",
				"Погода отличная. Солнце светит, люди улыбаются."
			]
			var event = randi() % events.size()
			if event == 2:
				player_data["balance"] += 10
				main_node.update_ui()

			# ✅ ХУДОЖЕСТВЕННЫЙ текст → в лог событий
			if log_system:
				log_system.add_event_log(events[event])

			# ✅ ТЕХНИЧЕСКИЙ текст → в центр экрана
			main_node.show_message("🚶 Прогулялись")

			if time_system:
				time_system.add_minutes(20)

		1: # Встретить знакомого
			# ✅ ХУДОЖЕСТВЕННЫЙ текст → в лог
			if log_system:
				var texts = [
					"Встретил кента из района. 'Привет! Как жизнь?' - 'Нормально, по тихой.'",
					"Знакомый пацан машет рукой: 'Привет братан!' Перекинулись парой слов.",
					"Кент: 'Как дела?' - 'Да живём потихоньку'. Постояли, покурили."
				]
				log_system.add_event_log(texts[randi() % texts.size()])

			# ✅ ТЕХНИЧЕСКИЙ текст → в центр
			main_node.show_message("👋 Встретили кента")

			if time_system:
				time_system.add_minutes(15)

		2: # Посмотреть вокруг
			# ✅ ХУДОЖЕСТВЕННЫЙ текст → в лог
			if log_system:
				var texts = [
					"Вокруг много людей, шумный город. Тверь живёт своей жизнью.",
					"Осмотрелся по сторонам. Типичный день в 92-м: очереди, толкучка, суета.",
					"Постоял, покурил, понаблюдал за прохожими. Город как город."
				]
				log_system.add_event_log(texts[randi() % texts.size()])

			# ✅ ТЕХНИЧЕСКИЙ текст → в центр
			main_node.show_message("👀 Осмотрелись")

			if time_system:
				time_system.add_minutes(5)
		3: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "УЛИЦА")
			if log_system:
				log_system.add_event_log("На улицах полно возможностей для быстрой наживы...")

# ВОКЗАЛ
func handle_station_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить билет
			if player_data["balance"] >= 50:
				player_data["balance"] -= 50
				main_node.show_message("Купили билет на поезд (50 руб.)")
				main_node.update_ui()
				if log_system:
					var texts = [
						"Билет до Москвы в кармане. Кассирша даже не подняла глаз.",
						"Купил билет. Плацкарт, третья полка. Классика девяностых.",
						"Билет взял. Когда-нибудь уеду из Твери... Но не сегодня."
					]
					log_system.add_event_log(texts[randi() % texts.size()])
			else:
				main_node.show_message("Не хватает денег! Нужно 50 руб.")
				if log_system:
					log_system.add_event_log("Посмотрел на цены билетов и тяжело вздохнул. Не хватает денег даже на плацкарт.")
			if time_system:
				time_system.add_minutes(10)
		1: # Встретить контакт
			var contacts = [
				"Контакт не появился...",
				"Незнакомец: 'Ищешь работу?'",
				"Контакт передал записку"
			]
			var chosen_contact = contacts[randi() % contacts.size()]
			main_node.show_message(chosen_contact)
			if log_system:
				var log_texts = [
					"Прождал полчаса у третьей платформы. %s" % chosen_contact,
					"Встреча на вокзале: %s" % chosen_contact,
					"Стоял у кассы, высматривал нужного человека. %s" % chosen_contact
				]
				log_system.add_event_log(log_texts[randi() % log_texts.size()])
			if time_system:
				time_system.add_minutes(30)
		2: # Осмотреться
			main_node.show_message("Много людей спешат на поезда")
			if log_system:
				var texts = [
					"Вокзал кипит жизнью. Бабки торгуют пирожками, мужики курят у входа. Типичная Тверь.",
					"Объявление: 'Поезд Москва-Питер отправляется через 10 минут'. Суета, шум, запах дыма.",
					"Походил по вокзалу. Много народу. Кто-то уезжает, кто-то приезжает. Жизнь продолжается."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(5)
		3: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "ВОКЗАЛ")
			if log_system:
				log_system.add_event_log("Вокзал - много людей, много возможностей... Можно поработать.")

# ФСБ
func handle_fsb_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # 💰 Дать взятку
			if police_system:
				police_system.show_fsb_bribe_menu(main_node)
			if log_system:
				var texts = [
					"Серое здание ФСБ. Охранник кивает, проводит в кабинет. Тут всё решается деньгами.",
					"Офицер в форме смотрит равнодушно. 'Сколько готов заплатить?' - вот и весь разговор.",
					"В кабинете пахнет табаком. 'За определённую сумму можем помочь с вашей проблемой', - намекает майор."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(20)
		1: # 🚪 Уйти
			main_node.close_location_menu()
			if log_system:
				log_system.add_event_log("Вышел из здания ФСБ. Охранники проводили взглядом.")

# Покупка предмета
func buy_item(item_name: String, player_data: Dictionary, main_node: Node):
	var item_data = items_db.get_item(item_name)
	if not item_data:
		main_node.show_message("❌ Предмет не найден!")
		return
	
	var price = item_data["price"]
	
	if player_data["balance"] >= price:
		player_data["balance"] -= price
		player_data["inventory"].append(item_name)
		main_node.show_message("✅ Куплено: " + item_name + " за " + str(price) + " руб.")
		main_node.update_ui()
	else:
		main_node.show_message("❌ Не хватает денег! Нужно: " + str(price) + " руб.")

# Меню продажи
func show_sell_menu(player_data: Dictionary, main_node: Node):
	var sell_menu = CanvasLayer.new()
	sell_menu.layer = 25  # ✅ Выше сетки (1)
	sell_menu.name = "SellMenu"
	main_node.add_child(sell_menu)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 700)
	bg.position = Vector2(110, 290)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	sell_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "ЧТО ПРОДАТЬ?"
	title.position = Vector2(280, 310)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	sell_menu.add_child(title)
	
	var y_pos = 360
	for i in range(player_data["inventory"].size()):
		var item = player_data["inventory"][i]
		var item_data = items_db.get_item(item)
		var sell_price = item_data["price"] / 2 if item_data else 5
		
		var item_btn = Button.new()
		item_btn.custom_minimum_size = Vector2(460, 45)
		item_btn.position = Vector2(130, y_pos)
		item_btn.text = item + " — продать за " + str(sell_price) + " руб."
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.2, 0.25, 0.2, 1.0)
		item_btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.3, 0.35, 0.3, 1.0)
		item_btn.add_theme_stylebox_override("hover", style_hover)
		
		item_btn.add_theme_font_size_override("font_size", 16)
		item_btn.add_theme_color_override("font_color", Color.WHITE)
		
		var item_to_sell = item
		item_btn.pressed.connect(func(): 
			sell_item(item_to_sell, player_data, main_node)
			sell_menu.queue_free()
		)
		
		sell_menu.add_child(item_btn)
		y_pos += 55
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(460, 50)
	close_btn.position = Vector2(130, 920)
	close_btn.text = "ОТМЕНА"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	
	close_btn.pressed.connect(func(): sell_menu.queue_free())
	
	sell_menu.add_child(close_btn)

# Продажа предмета
func sell_item(item_name: String, player_data: Dictionary, main_node: Node):
	if item_name not in player_data["inventory"]:
		return
	
	var item_data = items_db.get_item(item_name)
	var sell_price = item_data["price"] / 2 if item_data else 5
	
	player_data["inventory"].erase(item_name)
	player_data["balance"] += sell_price

	main_node.show_message("💰 Продано: " + item_name + " за " + str(sell_price) + " руб.")
	main_node.update_ui()

# ✅ НОВОЕ: Черный рынок
func show_black_market(player_data: Dictionary, main_node: Node):
	# ✅ ИСПРАВЛЕНО: Закрываем меню ларька
	var larek_menu = main_node.get_node_or_null("BuildingMenu")
	if larek_menu:
		larek_menu.queue_free()

	var market_menu = CanvasLayer.new()
	market_menu.name = "BlackMarketMenu"
	market_menu.layer = 210  # ✅ ВЫШЕ всего остального
	main_node.add_child(market_menu)
	current_building_menu = market_menu

	# ✅ Overlay для блокировки кликов на карту
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # ✅ Блокирует клики
	market_menu.add_child(overlay)

	# Фон меню
	var bg = ColorRect.new()
	bg.size = Vector2(680, 1100)
	bg.position = Vector2(20, 90)
	bg.color = Color(0.08, 0.08, 0.08, 0.98)
	market_menu.add_child(bg)

	# Заголовок
	var title = Label.new()
	title.text = "🛒 ЧЕРНЫЙ РЫНОК"
	title.position = Vector2(200, 110)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	market_menu.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Оружие, броня, инструменты - всё для дела"
	subtitle.position = Vector2(150, 150)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	market_menu.add_child(subtitle)

	# ScrollContainer для товаров
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 930)
	scroll.position = Vector2(20, 190)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	market_menu.add_child(scroll)

	var scroll_content = VBoxContainer.new()
	scroll_content.custom_minimum_size = Vector2(660, 0)
	scroll.add_child(scroll_content)

	# Товары черного рынка
	var market_items = [
		# Оружие ближнего боя
		{"name": "Нож", "price": 150, "category": "⚔️ ОРУЖИЕ", "desc": "Складной нож. Надежно и компактно"},
		{"name": "Бита", "price": 100, "category": "⚔️ ОРУЖИЕ", "desc": "Алюминиевая бита. Классика районов"},
		{"name": "Кастет", "price": 200, "category": "⚔️ ОРУЖИЕ", "desc": "Латунные кастеты. Для ближнего боя"},
		{"name": "Монтировка", "price": 120, "category": "⚔️ ОРУЖИЕ", "desc": "Тяжелая и прочная. Универсальный инструмент"},

		# Огнестрельное оружие
		{"name": "ПМ", "price": 800, "category": "🔫 ОГНЕСТРЕЛ", "desc": "Пистолет Макарова. Легендарный стволик"},
		{"name": "ТТ", "price": 1200, "category": "🔫 ОГНЕСТРЕЛ", "desc": "Тульский Токарев. Мощь и надежность"},
		{"name": "Обрез", "price": 1500, "category": "🔫 ОГНЕСТРЕЛ", "desc": "Обрезанная двустволка. Страшная штука"},

		# Броня
		{"name": "Легкий бронежилет", "price": 600, "category": "🦺 БРОНЯ", "desc": "1 класс защиты. Легкий и незаметный"},
		{"name": "Бронежилет", "price": 1200, "category": "🦺 БРОНЯ", "desc": "2 класс. Надежная защита корпуса"},
		{"name": "Тяжелый бронежилет", "price": 2500, "category": "🦺 БРОНЯ", "desc": "3 класс. Армейский уровень"},

		# Инструменты
		{"name": "Отмычка", "price": 250, "category": "🔧 ИНСТРУМЕНТЫ", "desc": "Набор отмычек. Открывает многое"},
		{"name": "Болторез", "price": 400, "category": "🔧 ИНСТРУМЕНТЫ", "desc": "Режет замки и цепи как масло"},
		{"name": "Набор для угона", "price": 800, "category": "🔧 ИНСТРУМЕНТЫ", "desc": "Всё для угона авто. Риск оправдан"},
		{"name": "Дубликатор ключей", "price": 500, "category": "🔧 ИНСТРУМЕНТЫ", "desc": "Копирует ключи за минуту"}
	]

	var current_category = ""
	for item in market_items:
		# Заголовок категории
		if item["category"] != current_category:
			current_category = item["category"]
			var cat_label = Label.new()
			cat_label.text = current_category
			cat_label.add_theme_font_size_override("font_size", 20)
			cat_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
			scroll_content.add_child(cat_label)

			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 10)
			scroll_content.add_child(spacer)

		# Карточка товара
		var item_panel = ColorRect.new()
		item_panel.custom_minimum_size = Vector2(660, 100)
		item_panel.color = Color(0.15, 0.15, 0.18, 1.0)
		scroll_content.add_child(item_panel)

		var item_name_label = Label.new()
		item_name_label.text = item["name"]
		item_name_label.position = Vector2(15, 15)
		item_name_label.add_theme_font_size_override("font_size", 20)
		item_name_label.add_theme_color_override("font_color", Color.WHITE)
		item_panel.add_child(item_name_label)

		var item_desc = Label.new()
		item_desc.text = item["desc"]
		item_desc.position = Vector2(15, 45)
		item_desc.add_theme_font_size_override("font_size", 14)
		item_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		item_panel.add_child(item_desc)

		var price_label = Label.new()
		price_label.text = str(item["price"]) + " ₽"
		price_label.position = Vector2(15, 70)
		price_label.add_theme_font_size_override("font_size", 18)
		price_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		item_panel.add_child(price_label)

		# Кнопка покупки
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(180, 45)
		buy_btn.position = Vector2(460, 28)
		buy_btn.text = "КУПИТЬ"
		buy_btn.add_theme_font_size_override("font_size", 18)

		var style_buy = StyleBoxFlat.new()
		style_buy.bg_color = Color(0.2, 0.5, 0.2, 1.0)
		buy_btn.add_theme_stylebox_override("normal", style_buy)

		var style_buy_hover = StyleBoxFlat.new()
		style_buy_hover.bg_color = Color(0.3, 0.6, 0.3, 1.0)
		buy_btn.add_theme_stylebox_override("hover", style_buy_hover)

		var item_name_copy = item["name"]
		var item_price_copy = item["price"]
		buy_btn.pressed.connect(func():
			buy_black_market_item(item_name_copy, item_price_copy, player_data, main_node)
		)
		item_panel.add_child(buy_btn)

		var spacer2 = Control.new()
		spacer2.custom_minimum_size = Vector2(0, 10)
		scroll_content.add_child(spacer2)

	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 60)
	close_btn.position = Vector2(20, 1140)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.add_theme_font_size_override("font_size", 22)

	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)

	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)

	close_btn.pressed.connect(func(): market_menu.queue_free())
	market_menu.add_child(close_btn)

# Покупка на черном рынке - показ меню выбора получателя
func buy_black_market_item(item_name: String, price: int, player_data: Dictionary, main_node: Node):
	if player_data["balance"] < price:
		main_node.show_message("❌ Недостаточно денег! Нужно: " + str(price) + " руб.")
		return

	# Показываем меню выбора получателя
	show_recipient_selection_menu(item_name, price, player_data, main_node)

# Меню выбора получателя при покупке
func show_recipient_selection_menu(item_name: String, price: int, player_data: Dictionary, main_node: Node):
	var select_menu = CanvasLayer.new()
	select_menu.name = "RecipientSelectMenu"
	select_menu.layer = 220  # Поверх черного рынка
	main_node.add_child(select_menu)

	# Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	select_menu.add_child(overlay)

	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(600, 800)
	bg.position = Vector2(60, 240)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	select_menu.add_child(bg)

	# Заголовок
	var title = Label.new()
	title.text = "👤 КОМУ КУПИТЬ?"
	title.position = Vector2(200, 260)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	select_menu.add_child(title)

	var subtitle = Label.new()
	subtitle.text = item_name + " (" + str(price) + "₽)"
	subtitle.position = Vector2(200, 300)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	select_menu.add_child(subtitle)

	var btn_y = 360

	# Кнопка "Себе"
	var self_btn = Button.new()
	self_btn.custom_minimum_size = Vector2(540, 70)
	self_btn.position = Vector2(90, btn_y)
	self_btn.text = "🎯 СЕБЕ (ГГ)"
	self_btn.add_theme_font_size_override("font_size", 22)

	var style_self = StyleBoxFlat.new()
	style_self.bg_color = Color(0.3, 0.6, 0.3, 1.0)
	self_btn.add_theme_stylebox_override("normal", style_self)

	var style_self_hover = StyleBoxFlat.new()
	style_self_hover.bg_color = Color(0.4, 0.7, 0.4, 1.0)
	self_btn.add_theme_stylebox_override("hover", style_self_hover)

	self_btn.pressed.connect(func():
		complete_purchase(item_name, price, player_data, player_data, main_node)
		select_menu.queue_free()
	)
	select_menu.add_child(self_btn)
	btn_y += 80

	# Кнопки для членов банды
	var gang_members = main_node.gang_members if "gang_members" in main_node else []
	for i in range(gang_members.size()):
		if i == 0:
			continue  # Пропускаем ГГ (индекс 0)

		var member = gang_members[i]
		var member_btn = Button.new()
		member_btn.custom_minimum_size = Vector2(540, 60)
		member_btn.position = Vector2(90, btn_y)

		var member_name = member.get("name", "Боец " + str(i))
		member_btn.text = "👤 " + member_name
		member_btn.add_theme_font_size_override("font_size", 20)

		var style_member = StyleBoxFlat.new()
		style_member.bg_color = Color(0.2, 0.3, 0.5, 1.0)
		member_btn.add_theme_stylebox_override("normal", style_member)

		var style_member_hover = StyleBoxFlat.new()
		style_member_hover.bg_color = Color(0.3, 0.4, 0.6, 1.0)
		member_btn.add_theme_stylebox_override("hover", style_member_hover)

		var member_index = i
		member_btn.pressed.connect(func():
			complete_purchase(item_name, price, player_data, gang_members[member_index], main_node)
			select_menu.queue_free()
		)
		select_menu.add_child(member_btn)
		btn_y += 70

	# Кнопка отмены
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(540, 60)
	cancel_btn.position = Vector2(90, 950)
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.add_theme_font_size_override("font_size", 20)

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)

	var style_cancel_hover = StyleBoxFlat.new()
	style_cancel_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	cancel_btn.add_theme_stylebox_override("hover", style_cancel_hover)

	cancel_btn.pressed.connect(func(): select_menu.queue_free())
	select_menu.add_child(cancel_btn)

# Завершение покупки для выбранного получателя
func complete_purchase(item_name: String, price: int, player_data: Dictionary, recipient_data: Dictionary, main_node: Node):
	player_data["balance"] -= price

	# Добавляем в инвентарь получателя
	if not recipient_data.has("inventory"):
		recipient_data["inventory"] = []
	recipient_data["inventory"].append(item_name)

	var recipient_name = recipient_data.get("name", "Вы")
	main_node.show_message("✅ Куплено: " + item_name + " → " + recipient_name + " (" + str(price) + "₽)")
	main_node.update_ui()

	if log_system:
		var texts = [
			"Сделка прошла быстро. Товар в кармане, деньги у продавца.",
			"'Не светись с этим', - бросил торговец, передавая товар.",
			"Покупка на черном рынке - дело обычное. Главное не попасться ментам."
		]
		log_system.add_event_log(texts[randi() % texts.size()])

# БОЛЬНИЦА
func handle_hospital_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	var hospital_system = get_node_or_null("/root/HospitalSystem")
	if not hospital_system:
		main_node.show_message("❌ Система больницы недоступна")
		return

	match action_index:
		0: # Лечиться
			hospital_system.show_hospital_choice_menu(main_node, player_data)
			if log_system:
				log_system.add_event_log("Вошли в городскую больницу. Медсестра кивнула: 'Чем помочь?'")
			if time_system:
				time_system.add_minutes(5)
		1: # Купить аптечку (100р)
			buy_item("Аптечка", player_data, main_node)
			if log_system:
				var texts = [
					"Аптечка первой помощи. Бинты, перекись, зелёнка - всё на месте.",
					"Купил аптечку. В 90-е это must-have для каждого пацана.",
					"Медсестра протянула аптечку: 'Береги себя на улицах'."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(5)
		2: # Уйти
			main_node.close_location_menu()
			if log_system:
				log_system.add_event_log("Вышли из больницы. Пахнет хлоркой и лекарствами.")

# АВТОСАЛОН
func handle_car_dealership_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	var car_system = get_node_or_null("/root/CarSystem")
	if not car_system:
		main_node.show_message("❌ Система машин недоступна")
		return

	match action_index:
		0: # 🚗 Выбор машины
			car_system.show_car_dealership(main_node, player_data)
			if log_system:
				log_system.add_event_log("Зашли в автосалон. Блестящие машины стоят рядами.")
			if time_system:
				time_system.add_minutes(5)
		1: # 🔧 Починить машину
			if car_system and "car" in player_data and player_data["car"]:
				car_system.show_repair_menu(main_node, player_data)
				if log_system:
					log_system.add_event_log("Механик осматривает машину: 'Сейчас посмотрим, что тут...'")
			else:
				main_node.show_message("❌ У вас нет машины!")
				if log_system:
					log_system.add_event_log("Механик пожал плечами: 'Нечего чинить, нет машины'.")
			if time_system:
				time_system.add_minutes(5)
		2: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "АВТОСАЛОН")
			if log_system:
				log_system.add_event_log("Присматриваешь дорогие тачки... Можно попробовать угнать...")
		3: # 🚪 Уйти
			main_node.close_location_menu()
			if log_system:
				log_system.add_event_log("Вышли из автосалона. Охранник проводил взглядом.")

# БАНК
func handle_bank_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # 💰 Открыть счет
			main_node.show_message("💰 Банковские счета пока недоступны")
			if log_system:
				var texts = [
					"Консультант улыбается: 'В наше время лучше держать деньги при себе'.",
					"Очередь в банке огромная. Бабки с книжками стоят часами.",
					"Кассир сказал что-то про проценты, но ты не особо понял."
				]
				log_system.add_event_log(texts[randi() % texts.size()])
			if time_system:
				time_system.add_minutes(15)
		1: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "БАНК")
			if log_system:
				log_system.add_event_log("Охрана, сигнализация, камеры... Ограбить банк - это самоубийство. Или слава?")
		2: # 🚪 Уйти
			main_node.close_location_menu()
			if log_system:
				log_system.add_event_log("Вышли из банка. Мощное здание, много денег внутри...")

# СКЛАД
func handle_warehouse_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # 📦 Поискать товары
			if randf() < 0.3:  # 30% шанс найти что-то
				var items = ["Инструменты", "Продукты", "Запчасти"]
				var found = items[randi() % items.size()]
				player_data["inventory"].append(found)
				main_node.show_message("✅ Нашли: " + found)
				if log_system:
					var texts = [
						"Покопался в ящиках на складе. Нашёл %s - пригодится!" % found,
						"Охранник отвлёкся. Стащил %s незаметно." % found,
						"На складе валяется куча барахла. Взял %s." % found
					]
					log_system.add_success_log(texts[randi() % texts.size()])
			else:
				main_node.show_message("❌ Ничего полезного не нашли")
				if log_system:
					log_system.add_event_log("Обыскал склад, но ничего интересного. Один мусор.")
			if time_system:
				time_system.add_minutes(20)
		1: # 🎭 Ограбления
			var robbery_system = get_node_or_null("/root/RobberySystem")
			if robbery_system:
				robbery_system.show_robberies_menu(main_node, player_data, "СКЛАД")
			if log_system:
				log_system.add_event_log("Склад полон товаров. Можно неплохо поживиться...")
		2: # 🚪 Уйти
			main_node.close_location_menu()
			if log_system:
				log_system.add_event_log("Вышли со склада. Грузчики таскают ящики туда-сюда.")
