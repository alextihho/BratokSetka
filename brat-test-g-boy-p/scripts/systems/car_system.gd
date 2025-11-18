# car_system.gd - ОБНОВЛЕНО (система мест и экипировки)
extends Node

signal car_purchased(car_name: String)
signal car_repaired()
signal driver_changed(member_index: int)

var player_stats
var time_system
var log_system  # ✅ НОВОЕ

# ✅ РАСШИРЕННАЯ СИСТЕМА: База данных машин с полными характеристиками
var cars_db = {
	"vaz_2106": {
		"name": "ВАЗ-2106",
		"price": 5000,
		"speed": 120,
		"max_hp": 200,  # ✅ НОВОЕ: Здоровье машины
		"durability": 60,  # Влияет на износ
		"stability": 40,  # ✅ НОВОЕ: Устойчивость (сцепление с дорогой, уворот от погони)
		"armor": 20,  # ✅ НОВОЕ: Защита (снижение урона пассажирам)
		"fuel_consumption": 8,
		"seats": 2,  # Водитель + 1 пассажир
		"cargo": 5,  # ✅ НОВОЕ: Грузоподъёмность (слоты для вещей)
		"description": "Классическая 'шестёрка' - надёжная рабочая лошадка",
		"image": "res://assets/cars/vaz_2106.png"
	},
	"vaz_2109": {
		"name": "ВАЗ-2109",
		"price": 7000,
		"speed": 130,
		"max_hp": 220,
		"durability": 65,
		"stability": 50,
		"armor": 25,
		"fuel_consumption": 7,
		"seats": 3,
		"cargo": 6,
		"description": "Девятка - чуть быстрее и просторнее шестёрки",
		"image": "res://assets/cars/vaz_2109.png"
	},
	"volga_3110": {
		"name": "Волга ГАЗ-3110",
		"price": 12000,
		"speed": 140,
		"max_hp": 280,
		"durability": 80,
		"stability": 60,
		"armor": 40,
		"fuel_consumption": 12,
		"seats": 4,  # Водитель + 3 пассажира
		"cargo": 10,
		"description": "Просторная и комфортная - идеальна для банды",
		"image": "res://assets/cars/volga.png"
	},
	"uaz_469": {
		"name": "УАЗ-469",
		"price": 15000,
		"speed": 110,
		"max_hp": 350,
		"durability": 95,
		"stability": 75,  # Высокая проходимость
		"armor": 50,  # Крепкий кузов
		"fuel_consumption": 15,
		"seats": 5,
		"cargo": 15,  # Большой багажник
		"description": "Военный УАЗ - танк на колёсах, проедет везде",
		"image": "res://assets/cars/uaz_469.png"
	},
	"bmw_e34": {
		"name": "BMW E34",
		"price": 25000,
		"speed": 180,
		"max_hp": 300,
		"durability": 90,
		"stability": 80,  # Отличная управляемость
		"armor": 45,
		"fuel_consumption": 10,
		"seats": 6,  # Водитель + 5 пассажиров
		"cargo": 8,
		"description": "Легенда 90-х - статус и мощь",
		"image": "res://assets/cars/bmw_e34.png"
	},
	"mercedes_w124": {
		"name": "Mercedes W124",
		"price": 30000,
		"speed": 170,
		"max_hp": 320,
		"durability": 95,
		"stability": 85,
		"armor": 55,  # Качественный немецкий кузов
		"fuel_consumption": 11,
		"seats": 6,
		"cargo": 12,
		"description": "Мерседес - роскошь и надёжность",
		"image": "res://assets/cars/mercedes_w124.png"
	},
	"gaz_3102": {
		"name": "ГАЗ-3102 (Бронированная)",
		"price": 45000,
		"speed": 150,
		"max_hp": 400,
		"durability": 100,
		"stability": 70,
		"armor": 80,  # ✅ Бронированная!
		"fuel_consumption": 18,
		"seats": 5,
		"cargo": 8,
		"description": "Бронированная Волга - для серьёзных дел",
		"image": "res://assets/cars/gaz_3102.png"
	},
	"gazelle": {
		"name": "ГАЗель (фургон)",
		"price": 20000,
		"speed": 100,
		"max_hp": 280,
		"durability": 75,
		"stability": 50,
		"armor": 35,
		"fuel_consumption": 14,
		"seats": 8,  # ✅ Много мест!
		"cargo": 20,  # ✅ Огромный грузовой отсек!
		"description": "ГАЗель - вся банда влезет + куча барахла",
		"image": "res://assets/cars/gazelle.png"
	}
}

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	time_system = get_node_or_null("/root/TimeSystem")
	log_system = get_node_or_null("/root/LogSystem")  # ✅ НОВОЕ
	print("🚗 Система машин загружена (с местами)")

# Показать меню автосалона
func show_car_dealership_menu(main_node: Node, player_data: Dictionary):
	var dealership_menu = CanvasLayer.new()
	dealership_menu.layer = 100
	dealership_menu.name = "DealershipMenu"
	main_node.add_child(dealership_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dealership_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.05, 0.05, 0.15, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ ФИКС: Не блокируем клики
	dealership_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🚗 АВТОСАЛОН"
	title.position = Vector2(260, 110)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 1.0))
	dealership_menu.add_child(title)
	
	# Информация о текущей машине
	var current_car_text = "Текущая машина: "
	if player_data.get("car"):
		var car = cars_db.get(player_data["car"])
		if car:
			current_car_text += car["name"] + " (%d мест)" % car["seats"]
			current_car_text += " (состояние: %.0f%%)" % player_data.get("car_condition", 100)
		else:
			current_car_text += "Нет"
	else:
		current_car_text += "Нет"
	
	var current_car_label = Label.new()
	current_car_label.text = current_car_text
	current_car_label.position = Vector2(160, 160)
	current_car_label.add_theme_font_size_override("font_size", 16)
	current_car_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	dealership_menu.add_child(current_car_label)
	
	var y_pos = 220
	
	# Кнопка "ВЫБОР МАШИНЫ"
	var choose_car_btn = Button.new()
	choose_car_btn.custom_minimum_size = Vector2(660, 80)
	choose_car_btn.position = Vector2(30, y_pos)
	choose_car_btn.text = "🚗 ВЫБОР МАШИНЫ"
	choose_car_btn.z_index = 10  # ✅ ФИКС: Поверх overlay

	var style_choose = StyleBoxFlat.new()
	style_choose.bg_color = Color(0.2, 0.5, 0.8, 1.0)
	choose_car_btn.add_theme_stylebox_override("normal", style_choose)
	
	choose_car_btn.add_theme_font_size_override("font_size", 24)
	choose_car_btn.pressed.connect(func():
		dealership_menu.queue_free()
		show_car_selection_menu(main_node, player_data)
	)
	dealership_menu.add_child(choose_car_btn)
	
	y_pos += 100
	
	# Кнопка "ПОЧИНИТЬ МАШИНУ"
	var repair_btn = Button.new()
	repair_btn.custom_minimum_size = Vector2(660, 80)
	repair_btn.position = Vector2(30, y_pos)
	repair_btn.text = "🔧 ПОЧИНИТЬ МАШИНУ"
	repair_btn.disabled = not player_data.get("car") or player_data.get("car_condition", 100) >= 100
	repair_btn.z_index = 10  # ✅ ФИКС: Поверх overlay

	var style_repair = StyleBoxFlat.new()
	if repair_btn.disabled:
		style_repair.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	else:
		style_repair.bg_color = Color(0.6, 0.4, 0.2, 1.0)
	repair_btn.add_theme_stylebox_override("normal", style_repair)
	
	repair_btn.add_theme_font_size_override("font_size", 24)
	repair_btn.pressed.connect(func():
		show_repair_menu(main_node, player_data, dealership_menu)
	)
	dealership_menu.add_child(repair_btn)

	y_pos += 100

	# Информационный блок
	var info_bg = ColorRect.new()
	info_bg.size = Vector2(660, 500)  # ✅ Немного уменьшили
	info_bg.position = Vector2(30, y_pos)
	info_bg.color = Color(0.1, 0.1, 0.2, 0.8)
	info_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ ФИКС: Не блокируем клики
	dealership_menu.add_child(info_bg)
	
	var info_text = "ℹ️ АВТОСАЛОН\n\n"
	info_text += "Здесь вы можете:\n"
	info_text += "• Купить машину для быстрых передвижений\n"
	info_text += "• Починить свою машину\n\n"
	info_text += "⚠️ ВАЖНО:\n"
	info_text += "• После покупки назначьте водителя в меню\n"
	info_text += "• Количество мест ограничивает банду в поездках\n"
	info_text += "• Машина изнашивается при использовании\n\n"
	info_text += "💡 Совет: лучшая машина = больше мест и престиж!"
	
	var info_label = Label.new()
	info_label.text = info_text
	info_label.position = Vector2(50, y_pos + 20)
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1.0))
	dealership_menu.add_child(info_label)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1100)
	close_btn.text = "УЙТИ"
	close_btn.z_index = 10  # ✅ ФИКС: Поверх overlay

	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		dealership_menu.queue_free()
	)
	dealership_menu.add_child(close_btn)

# Меню выбора машины
func show_car_selection_menu(main_node: Node, player_data: Dictionary):
	var selection_menu = CanvasLayer.new()
	selection_menu.layer = 110
	selection_menu.name = "CarSelectionMenu"
	main_node.add_child(selection_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	selection_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.05, 0.05, 0.15, 0.98)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ ФИКС: Не блокируем клики
	selection_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🚗 ВЫБОР МАШИНЫ"
	title.position = Vector2(230, 110)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 1.0))
	selection_menu.add_child(title)
	
	var balance_label = Label.new()
	balance_label.text = "💰 Баланс: %d руб." % player_data["balance"]
	balance_label.position = Vector2(260, 160)
	balance_label.add_theme_font_size_override("font_size", 18)
	balance_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	selection_menu.add_child(balance_label)

	# ✅ НОВОЕ: ScrollContainer для списка машин
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(700, 870)  # Высота до кнопки закрытия
	scroll_container.position = Vector2(10, 210)
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	selection_menu.add_child(scroll_container)

	# ✅ Control для контента (чтобы позиционирование работало)
	var scroll_content = Control.new()
	scroll_content.custom_minimum_size = Vector2(680, 0)  # Высота будет рассчитана
	scroll_container.add_child(scroll_content)

	var y_pos = 10  # ✅ Начинаем с малого отступа внутри scroll

	# Список машин
	for car_id in cars_db:
		var car = cars_db[car_id]
		
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(680, 220)
		card_bg.position = Vector2(10, y_pos)
		card_bg.color = Color(0.15, 0.15, 0.25, 1.0)
		card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ ФИКС: Не блокируем клики
		scroll_content.add_child(card_bg)

		# Placeholder для изображения машины
		var car_image_bg = ColorRect.new()
		car_image_bg.size = Vector2(200, 150)
		car_image_bg.position = Vector2(30, y_pos + 20)
		car_image_bg.color = Color(0.2, 0.2, 0.3, 1.0)
		car_image_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ ФИКС: Не блокируем клики
		scroll_content.add_child(car_image_bg)

		var car_icon = Label.new()
		car_icon.text = "🚗"
		car_icon.position = Vector2(100, y_pos + 65)
		car_icon.add_theme_font_size_override("font_size", 64)
		scroll_content.add_child(car_icon)

		# Информация о машине
		var car_name = Label.new()
		car_name.text = car["name"] + " (%d мест)" % car["seats"]  # ✅ Показываем места
		car_name.position = Vector2(250, y_pos + 20)
		car_name.add_theme_font_size_override("font_size", 20)
		car_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5, 1.0))
		scroll_content.add_child(car_name)
		
		var car_desc = Label.new()
		car_desc.text = car["description"]
		car_desc.position = Vector2(260, y_pos + 50)
		car_desc.add_theme_font_size_override("font_size", 13)
		car_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		scroll_content.add_child(car_desc)
		
		# ✅ НОВОЕ: Первая строка статов
		var car_stats1 = Label.new()
		car_stats1.text = "⚡ %d км/ч | ❤️ %d HP | 🛡️ Прочн:%d | 🔰 Устой:%d" % [
			car["speed"],
			car["max_hp"],
			car["durability"],
			car["stability"]
		]
		car_stats1.position = Vector2(260, y_pos + 75)
		car_stats1.add_theme_font_size_override("font_size", 12)
		car_stats1.add_theme_color_override("font_color", Color(0.5, 1.0, 0.8, 1.0))
		scroll_content.add_child(car_stats1)

		# ✅ НОВОЕ: Вторая строка статов
		var car_stats2 = Label.new()
		car_stats2.text = "🛡 Броня:%d | 👥 %d мест | 📦 %d слотов | ⛽ %dл" % [
			car["armor"],
			car["seats"],
			car["cargo"],
			car["fuel_consumption"]
		]
		car_stats2.position = Vector2(260, y_pos + 95)
		car_stats2.add_theme_font_size_override("font_size", 12)
		car_stats2.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
		scroll_content.add_child(car_stats2)
		
		var car_price = Label.new()
		car_price.text = "💰 Цена: %d руб." % car["price"]
		car_price.position = Vector2(260, y_pos + 110)
		car_price.add_theme_font_size_override("font_size", 18)
		car_price.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
		scroll_content.add_child(car_price)
		
		# Кнопка выбора
		var select_btn = Button.new()
		select_btn.custom_minimum_size = Vector2(180, 50)
		select_btn.position = Vector2(500, y_pos + 150)
		select_btn.z_index = 10  # ✅ ФИКС: Поверх overlay

		# Проверяем есть ли уже эта машина
		if player_data.get("car") == car_id:
			select_btn.text = "✓ КУПЛЕНА"
			select_btn.disabled = true
		else:
			select_btn.text = "КУПИТЬ"
			select_btn.disabled = player_data["balance"] < car["price"]

		var style_select = StyleBoxFlat.new()
		if select_btn.disabled:
			style_select.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		else:
			style_select.bg_color = Color(0.3, 0.7, 0.3, 1.0)
		select_btn.add_theme_stylebox_override("normal", style_select)
		
		select_btn.add_theme_font_size_override("font_size", 16)
		
		var c_id = car_id
		var c_car = car.duplicate()
		select_btn.pressed.connect(func():
			buy_car(main_node, player_data, c_id, c_car, selection_menu)
		)
		scroll_content.add_child(select_btn)
		
		y_pos += 240

	# ✅ НОВОЕ: Устанавливаем высоту контента
	scroll_content.custom_minimum_size.y = y_pos + 20
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1100)
	close_btn.text = "НАЗАД"
	close_btn.z_index = 10  # ✅ ФИКС: Поверх overlay

	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		selection_menu.queue_free()
		# ✅ ИСПРАВЛЕНО: НЕ открываем автосалон после выбора водителя
	)
	selection_menu.add_child(close_btn)

# Купить машину
func buy_car(main_node: Node, player_data: Dictionary, car_id: String, car: Dictionary, selection_menu: CanvasLayer):
	if player_data["balance"] < car["price"]:
		main_node.show_message("❌ Недостаточно денег!")
		return
	
	# Списываем деньги
	player_data["balance"] -= car["price"]
	
	# Устанавливаем машину
	player_data["car"] = car_id
	player_data["car_condition"] = 100.0
	player_data["car_hp"] = car.get("max_hp", 200)  # ✅ НОВОЕ: Здоровье машины
	player_data["car_equipped"] = false  # ✅ Машина НЕ экипирована
	player_data["current_driver"] = null  # ✅ Водитель НЕ назначен
	player_data["in_car"] = false  # ✅ ИСПРАВЛЕНО: НЕ в машине! Нужно вручную назначить водителя

	main_node.show_message("🚗 Машина куплена: %s!\n📋 Откройте ИНВЕНТАРЬ → назначьте водителя → нажмите СЕСТЬ В МАШИНУ" % car["name"])

	# ✅ НОВОЕ: Логируем покупку
	if log_system:
		log_system.add_money_log("🚗 Куплена машина: %s (-%dр)" % [car["name"], car["price"]])

		# ✅ НОВОЕ: Художественный лог события
		var purchase_events = {
			"vaz_2106": "Продавец протер капот тряпкой. 'Шестёрка - рабочая лошадка! Не подведёт!' Ключи в руках.",
			"vaz_2109": "'Девятка' посвежее шестёрки. 'На ней бандиты гоняют!' - усмехается продавец.",
			"volga_3110": "Волга блестит на солнце. 'Вот это авто! Для солидных людей!' - гордо говорит продавец.",
			"uaz_469": "УАЗ стоит как танк. 'Военный УАЗик! Хоть на войну, хоть в поле!' Мощь!",
			"bmw_e34": "BMW стоит особняком. 'Немецкое качество, братан. Просто бомба!' Мечта сбылась.",
			"mercedes_w124": "Мерседес как новенький. 'Машина для настоящих авторитетов!' Класс!",
			"gaz_3102": "Бронированная Волга. 'Для особых дел. Пули не страшны!' Продавец серьёзен.",
			"gazelle": "ГАЗель огромная. 'Вся банда влезет! И товар везти можно!' Практично."
		}
		var event_text = purchase_events.get(car_id, "Новая машина куплена! Пора прокатиться.")
		log_system.add_event_log(event_text)

	main_node.update_ui()
	
	car_purchased.emit(car["name"])
	
	selection_menu.queue_free()
	await main_node.get_tree().create_timer(1.0).timeout
	show_car_dealership_menu(main_node, player_data)

# Меню ремонта (без изменений)
func show_repair_menu(main_node: Node, player_data: Dictionary, dealership_menu: CanvasLayer):
	if not player_data.get("car"):
		main_node.show_message("❌ У вас нет машины!")
		return
	
	var condition = player_data.get("car_condition", 100)
	if condition >= 100:
		main_node.show_message("✅ Машина в отличном состоянии!")
		return
	
	var car = cars_db.get(player_data["car"])
	if not car:
		return
	
	var wear = 100 - condition
	var base_cost = int(car["price"] * 0.01 * wear)
	
	var charisma_discount = 0
	if player_stats:
		var charisma = player_stats.get_stat("Харизма")
		charisma_discount = charisma * 2
	
	var repair_cost = int(base_cost * (100 - charisma_discount) / 100.0)
	repair_cost = max(50, repair_cost)
	
	# Создаём диалог подтверждения
	var confirm_layer = CanvasLayer.new()
	confirm_layer.layer = 120
	confirm_layer.name = "RepairConfirm"
	main_node.add_child(confirm_layer)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_layer.add_child(overlay)
	
	var dialog_bg = ColorRect.new()
	dialog_bg.size = Vector2(600, 400)
	dialog_bg.position = Vector2(60, 440)
	dialog_bg.color = Color(0.1, 0.1, 0.15, 0.98)
	dialog_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ ФИКС: Не блокируем клики
	confirm_layer.add_child(dialog_bg)
	
	var title = Label.new()
	title.text = "🔧 РЕМОНТ МАШИНЫ"
	title.position = Vector2(210, 470)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1.0))
	confirm_layer.add_child(title)
	
	var info_text = "Машина: %s\n\nТекущее состояние: %.0f%%\nИзнос: %.0f%%\n\n" % [
		car["name"],
		condition,
		wear
	]
	info_text += "Стоимость ремонта: %d руб." % repair_cost
	
	if charisma_discount > 0:
		info_text += "\n(скидка %d%% от харизмы)" % charisma_discount
	
	var info_label = Label.new()
	info_label.text = info_text
	info_label.position = Vector2(140, 530)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	confirm_layer.add_child(info_label)
	
	var repair_btn = Button.new()
	repair_btn.custom_minimum_size = Vector2(250, 60)
	repair_btn.position = Vector2(100, 730)
	repair_btn.text = "ПОЧИНИТЬ"
	repair_btn.disabled = player_data["balance"] < repair_cost
	repair_btn.z_index = 10  # ✅ ФИКС: Поверх overlay

	var style_repair = StyleBoxFlat.new()
	if repair_btn.disabled:
		style_repair.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	else:
		style_repair.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	repair_btn.add_theme_stylebox_override("normal", style_repair)
	
	repair_btn.add_theme_font_size_override("font_size", 20)
	repair_btn.pressed.connect(func():
		repair_car(main_node, player_data, repair_cost, confirm_layer, dealership_menu)
	)
	confirm_layer.add_child(repair_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(250, 60)
	cancel_btn.position = Vector2(370, 730)
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.z_index = 10  # ✅ ФИКС: Поверх overlay

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)
	
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func():
		confirm_layer.queue_free()
	)
	confirm_layer.add_child(cancel_btn)

# Починить машину
func repair_car(main_node: Node, player_data: Dictionary, cost: int, confirm_layer: CanvasLayer, dealership_menu: CanvasLayer):
	if player_data["balance"] < cost:
		main_node.show_message("❌ Недостаточно денег!")
		return
	
	player_data["balance"] -= cost
	player_data["car_condition"] = 100.0
	
	if time_system:
		time_system.add_hours(randi_range(1, 3))
	
	main_node.show_message("🔧 Машина отремонтирована!\n💰 Потрачено: %d руб." % cost)

	# ✅ НОВОЕ: Логируем ремонт
	if log_system:
		log_system.add_money_log("🔧 Ремонт машины (-%dр)" % cost)

		# ✅ НОВОЕ: Художественный лог события
		var repair_events = [
			"Механик ковыряется под капотом. Дым, стук молотка. 'Готово, поедет как новая!'",
			"Подняли на подъёмник, заменили масло и фильтры. Машина как будто ожила.",
			"Мастер покачал головой: 'Запущено, но починим.' Через пару часов всё работает.",
			"Сварили кузов, подтянули подвеску. Теперь тачка не стучит на кочках!"
		]
		var random_event = repair_events[randi() % repair_events.size()]
		log_system.add_event_log(random_event)

	main_node.update_ui()
	
	car_repaired.emit()
	
	confirm_layer.queue_free()
	dealership_menu.queue_free()
	await main_node.get_tree().create_timer(0.5).timeout
	show_car_dealership_menu(main_node, player_data)

# Изнашивание машины при использовании
func use_car(player_data: Dictionary, distance: float = 10.0):
	if not player_data.get("car"):
		return
	
	var car = cars_db.get(player_data["car"])
	if not car:
		return
	
	var wear_rate = 100.0 / car["durability"]
	var wear = wear_rate * (distance / 10.0)
	
	player_data["car_condition"] = max(0, player_data.get("car_condition", 100) - wear)

# ✅ НОВОЕ: Меню выбора водителя
func show_driver_selection_menu(main_node: Node, player_data: Dictionary):
	var driver_menu = CanvasLayer.new()
	driver_menu.layer = 110
	driver_menu.name = "DriverSelectionMenu"
	main_node.add_child(driver_menu)

	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	driver_menu.add_child(overlay)

	var bg = ColorRect.new()
	bg.size = Vector2(680, 1100)
	bg.position = Vector2(20, 90)
	bg.color = Color(0.05, 0.05, 0.15, 0.98)
	driver_menu.add_child(bg)

	var title = Label.new()
	title.text = "👤 ВЫБОР ВОДИТЕЛЯ"
	title.position = Vector2(230, 110)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 1.0))
	driver_menu.add_child(title)

	var car_name = "Машина"
	if player_data.get("car"):
		var car = cars_db.get(player_data["car"])
		if car:
			car_name = car["name"]

	var subtitle = Label.new()
	subtitle.text = "Выберите кто будет водить: " + car_name
	subtitle.position = Vector2(150, 160)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	driver_menu.add_child(subtitle)

	var y_pos = 220

	# ✅ ГГ (Главный Герой)
	var player_card = ColorRect.new()
	player_card.size = Vector2(640, 100)
	player_card.position = Vector2(40, y_pos)
	player_card.color = Color(0.15, 0.15, 0.25, 1.0)
	driver_menu.add_child(player_card)

	var player_name = Label.new()
	player_name.text = "🎯 ВЫ (Главный герой)"
	player_name.position = Vector2(60, y_pos + 15)
	player_name.add_theme_font_size_override("font_size", 20)
	player_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5, 1.0))
	driver_menu.add_child(player_name)

	var player_drv = player_stats.get_stat("DRV") if player_stats else 0
	var player_drv_label = Label.new()
	player_drv_label.text = "🚗 Вождение: %d" % player_drv
	player_drv_label.position = Vector2(60, y_pos + 45)
	player_drv_label.add_theme_font_size_override("font_size", 16)
	player_drv_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1.0))
	driver_menu.add_child(player_drv_label)

	var player_current = player_data.get("current_driver") == -1  # -1 = ГГ
	var player_btn = Button.new()
	player_btn.custom_minimum_size = Vector2(160, 50)
	player_btn.position = Vector2(500, y_pos + 25)
	player_btn.text = "✓ ВОДИТЕЛЬ" if player_current else "ВЫБРАТЬ"
	player_btn.disabled = player_current
	player_btn.z_index = 10

	var style_player = StyleBoxFlat.new()
	style_player.bg_color = Color(0.3, 0.3, 0.3, 1.0) if player_current else Color(0.3, 0.6, 0.3, 1.0)
	player_btn.add_theme_stylebox_override("normal", style_player)

	player_btn.add_theme_font_size_override("font_size", 16)
	player_btn.pressed.connect(func():
		select_driver(main_node, player_data, -1, driver_menu)  # -1 = ГГ
	)
	driver_menu.add_child(player_btn)

	y_pos += 120

	# ✅ Члены банды
	var gang_title = Label.new()
	gang_title.text = "═══ БАНДА ═══"
	gang_title.position = Vector2(280, y_pos)
	gang_title.add_theme_font_size_override("font_size", 22)
	gang_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	driver_menu.add_child(gang_title)
	y_pos += 50

	var gang_members = main_node.gang_members if "gang_members" in main_node else []

	if gang_members.size() == 0:
		var no_gang = Label.new()
		no_gang.text = "⚠️ Нет членов банды"
		no_gang.position = Vector2(250, y_pos + 20)
		no_gang.add_theme_font_size_override("font_size", 18)
		no_gang.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3, 1.0))
		driver_menu.add_child(no_gang)
	else:
		for i in range(gang_members.size()):
			var member = gang_members[i]

			var member_card = ColorRect.new()
			member_card.size = Vector2(640, 100)
			member_card.position = Vector2(40, y_pos)
			member_card.color = Color(0.15, 0.15, 0.25, 1.0)
			driver_menu.add_child(member_card)

			var member_name_text = member.get("name", "Безымянный")
			if not member.get("is_active", true):
				member_name_text += " (неактивен)"

			var member_name_label = Label.new()
			member_name_label.text = member_name_text
			member_name_label.position = Vector2(60, y_pos + 15)
			member_name_label.add_theme_font_size_override("font_size", 18)
			member_name_label.add_theme_color_override("font_color", Color.WHITE if member.get("is_active", true) else Color(0.5, 0.5, 0.5, 1.0))
			driver_menu.add_child(member_name_label)

			# Получаем DRV скилл члена банды
			var member_drv = member.get("driving_skill", 0)
			var member_drv_label = Label.new()
			member_drv_label.text = "🚗 Вождение: %d" % member_drv
			member_drv_label.position = Vector2(60, y_pos + 45)
			member_drv_label.add_theme_font_size_override("font_size", 16)
			member_drv_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1.0))
			driver_menu.add_child(member_drv_label)

			var is_current_driver = player_data.get("current_driver") == i
			var member_btn = Button.new()
			member_btn.custom_minimum_size = Vector2(160, 50)
			member_btn.position = Vector2(500, y_pos + 25)
			member_btn.text = "✓ ВОДИТЕЛЬ" if is_current_driver else "ВЫБРАТЬ"
			member_btn.disabled = is_current_driver or not member.get("is_active", true)
			member_btn.z_index = 10

			var style_member = StyleBoxFlat.new()
			if member_btn.disabled:
				style_member.bg_color = Color(0.3, 0.3, 0.3, 1.0)
			else:
				style_member.bg_color = Color(0.3, 0.6, 0.3, 1.0)
			member_btn.add_theme_stylebox_override("normal", style_member)

			member_btn.add_theme_font_size_override("font_size", 16)
			var member_index = i
			member_btn.pressed.connect(func():
				select_driver(main_node, player_data, member_index, driver_menu)
			)
			driver_menu.add_child(member_btn)

			y_pos += 120

			# Ограничение по высоте экрана
			if y_pos > 1000:
				break

	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(640, 50)
	close_btn.position = Vector2(40, 1100)
	close_btn.text = "НАЗАД"
	close_btn.z_index = 10

	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)

	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		driver_menu.queue_free()
		# ✅ ИСПРАВЛЕНО: НЕ открываем автосалон при закрытии меню водителя
	)
	driver_menu.add_child(close_btn)

# ✅ НОВОЕ: Выбрать водителя
func select_driver(main_node: Node, player_data: Dictionary, driver_index: int, driver_menu: CanvasLayer):
	player_data["current_driver"] = driver_index
	player_data["car_equipped"] = true  # ✅ Машина теперь готова к использованию

	var driver_name = "Вы"
	if driver_index >= 0:
		var gang_members = main_node.gang_members if "gang_members" in main_node else []
		if driver_index < gang_members.size():
			driver_name = gang_members[driver_index].get("name", "Безымянный")

	main_node.show_message("✅ Водитель назначен: %s\n🚗 Машина готова к использованию!" % driver_name)

	# ✅ НОВОЕ: Логируем назначение водителя
	if log_system:
		log_system.add_event_log("Машина готова! Теперь за рулём: %s." % driver_name)

	driver_menu.queue_free()
	# ✅ ИСПРАВЛЕНО: НЕ открываем автосалон после выбора водителя

# ✅ НОВОЕ: Получить количество мест в машине
func get_car_seats(car_id: String) -> int:
	var car = cars_db.get(car_id)
	if car and car.has("seats"):
		return car["seats"]
	return 1
