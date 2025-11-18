extends Node

var items = {
	# === ШЛЕМЫ И ГОЛОВНЫЕ УБОРЫ ===
	"Кепка": {"type": "helmet", "defense": 1, "price": 50, "level": 1, "description": "Простая кепка. Защита +1"},
	"Бандана": {"type": "helmet", "defense": 0, "price": 30, "level": 1, "description": "Бандана гопника. Стиль!"},
	"Шапка-ушанка": {"type": "helmet", "defense": 2, "price": 80, "level": 1, "description": "Тёплая ушанка. Защита +2"},
	"Шлем": {"type": "helmet", "defense": 5, "price": 300, "level": 3, "description": "Мотоциклетный шлем. Защита +5"},
	"Каска": {"type": "helmet", "defense": 8, "price": 500, "level": 5, "description": "Военная каска. Защита +8"},
	"Очки": {"type": "helmet", "defense": 0, "price": 100, "level": 1, "description": "Крутые очки. Стиль +10"},

	# === БРОНЯ И ОДЕЖДА ===
	"Майка": {"type": "armor", "defense": 0, "price": 20, "level": 1, "description": "Обычная майка. Без защиты"},
	"Спортивный костюм": {"type": "armor", "defense": 1, "price": 100, "level": 1, "description": "Спортивка. Защита +1"},
	"Джинсовка": {"type": "armor", "defense": 2, "price": 120, "level": 1, "description": "Джинсовая куртка. Защита +2"},
	"Пальто": {"type": "armor", "defense": 2, "price": 120, "level": 1, "description": "Длинное пальто. Защита +2"},
	"Куртка": {"type": "armor", "defense": 3, "price": 150, "level": 2, "description": "Кожаная куртка. Защита +3"},
	"Дублёнка": {"type": "armor", "defense": 4, "price": 180, "level": 2, "description": "Тёплая дублёнка. Защита +4"},
	"Кожанка": {"type": "armor", "defense": 5, "price": 200, "level": 3, "description": "Толстая кожанка. Защита +5"},
	"Армейская куртка": {"type": "armor", "defense": 7, "price": 350, "level": 4, "description": "Военная куртка. Защита +7"},
	"Камуфляж": {"type": "armor", "defense": 8, "price": 400, "level": 4, "description": "Камуфляжная форма. Защита +8"},
	"Бронежилет": {"type": "armor", "defense": 15, "price": 800, "level": 6, "description": "Военный бронежилет. Защита +15"},
	"Тяжёлый бронежилет": {"type": "armor", "defense": 20, "price": 1500, "level": 8, "description": "Усиленный бронежилет. Защита +20"},

	# === БЛИЖНИЙ БОЙ ===
	"Кулаки": {"type": "melee", "damage": 2, "strength_req": 0, "price": 0, "level": 1, "description": "Голыми руками. Урон +2"},
	"Нож": {"type": "melee", "damage": 3, "strength_req": 1, "price": 50, "level": 1, "description": "Складной нож. Урон +3"},
	"Кухонный нож": {"type": "melee", "damage": 4, "strength_req": 1, "price": 30, "level": 1, "description": "Обычный кухонный нож. Урон +4"},
	"Кастет": {"type": "melee", "damage": 4, "strength_req": 1, "price": 75, "level": 1, "description": "Латунный кастет. Урон +4"},
	"Бита": {"type": "melee", "damage": 5, "strength_req": 2, "price": 100, "level": 2, "description": "Деревянная бита. Урон +5"},
	"Монтировка": {"type": "melee", "damage": 6, "strength_req": 2, "price": 80, "level": 2, "description": "Железная монтировка. Урон +6"},
	"Цепь": {"type": "melee", "damage": 7, "strength_req": 2, "price": 120, "level": 2, "description": "Тяжёлая цепь. Урон +7"},
	"Мачете": {"type": "melee", "damage": 9, "strength_req": 3, "price": 200, "level": 3, "description": "Большой мачете. Урон +9"},
	"Топор": {"type": "melee", "damage": 11, "strength_req": 4, "price": 300, "level": 4, "description": "Боевой топор. Урон +11"},
	"Катана": {"type": "melee", "damage": 13, "strength_req": 4, "price": 500, "level": 5, "description": "Японский меч. Урон +13"},

	# === ДАЛЬНИЙ БОЙ ===
	"Рогатка": {"type": "ranged", "damage": 3, "accuracy_req": 1, "price": 20, "level": 1, "description": "Детская рогатка. Урон +3"},
	"ТТ": {"type": "ranged", "damage": 12, "accuracy_req": 2, "price": 400, "level": 2, "description": "Пистолет ТТ. Урон +12"},
	"ПМ": {"type": "ranged", "damage": 15, "accuracy_req": 3, "price": 500, "level": 3, "description": "Пистолет Макарова. Урон +15"},
	"Наган": {"type": "ranged", "damage": 16, "accuracy_req": 3, "price": 600, "level": 3, "description": "Старый наган. Урон +16"},
	"Беретта": {"type": "ranged", "damage": 18, "accuracy_req": 3, "price": 800, "level": 4, "description": "Beretta 92. Урон +18"},
	"Обрез": {"type": "ranged", "damage": 25, "accuracy_req": 2, "price": 1200, "level": 4, "description": "Обрез ружья. Урон +25"},
	"Дробовик": {"type": "ranged", "damage": 28, "accuracy_req": 3, "price": 1800, "level": 5, "description": "Помповый дробовик. Урон +28"},
	"Автомат Калашникова": {"type": "ranged", "damage": 35, "accuracy_req": 5, "price": 3000, "level": 6, "description": "АК-47. Урон +35"},
	"СВД": {"type": "ranged", "damage": 45, "accuracy_req": 7, "price": 5000, "level": 8, "description": "Снайперская винтовка. Урон +45"},
	# === ГАДЖЕТЫ ===
	"Рация": {"type": "gadget", "effect": "связь", "price": 150, "level": 2, "description": "Связь на расстоянии"},
	"Телефон": {"type": "gadget", "effect": "связь", "price": 500, "level": 3, "description": "Мобильный телефон. Престиж!"},
	"GPS-трекер": {"type": "gadget", "effect": "навигация", "price": 800, "level": 4, "description": "Высокие технологии"},
	"Отмычка": {"type": "gadget", "effect": "взлом", "price": 100, "level": 2, "description": "Для взлома замков"},

	# === РАСХОДНИКИ ===
	"Пиво": {"type": "consumable", "price": 30, "level": 1, "description": "Восстанавливает 10 HP", "effect": "heal", "value": 10},
	"Сигареты": {"type": "consumable", "price": 15, "level": 1, "description": "Снимает стресс", "effect": "stress", "value": 5},
	"Булка": {"type": "consumable", "price": 10, "level": 1, "description": "Восстанавливает 15 HP", "effect": "heal", "value": 15},
	"Шаурма": {"type": "consumable", "price": 50, "level": 1, "description": "Восстанавливает 30 HP", "effect": "heal", "value": 30},
	"Чипсы": {"type": "consumable", "price": 25, "level": 1, "description": "Восстанавливает 5 HP", "effect": "heal", "value": 5},
	"Аптечка": {"type": "consumable", "price": 100, "level": 2, "description": "Восстанавливает 50 HP", "effect": "heal", "value": 50},
	"Сок": {"type": "consumable", "price": 20, "level": 1, "description": "Восстанавливает 10 HP", "effect": "heal", "value": 10},
	"Пачка сигарет": {"type": "consumable", "price": 15, "level": 1, "description": "Пачка сигарет. Снимает стресс", "effect": "stress", "value": 5},
	"Продукты": {"type": "consumable", "price": 25, "level": 1, "description": "Обычная еда. Восстанавливает 20 HP", "effect": "heal", "value": 20}
}

func get_item(item_name: String):
	if item_name in items:
		return items[item_name]
	print("⚠️ Предмет не найден в базе: " + item_name)
	return null

func get_item_price(item_name: String) -> int:
	if item_name in items:
		return items[item_name].get("price", 0)
	return 0

func get_item_type(item_name: String) -> String:
	if item_name in items:
		return items[item_name].get("type", "")
	return ""
