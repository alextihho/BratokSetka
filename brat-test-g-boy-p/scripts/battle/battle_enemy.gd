# scripts/battle/battle_enemy.gd
extends Node

var items_db  # ✅ Ссылка на базу предметов

func _ready():
	items_db = get_node_or_null("/root/ItemsDB")
	if not items_db:
		print("⚠️ ItemsDB не найден! Враги будут без экипировки")

# ===== ШАБЛОНЫ ВРАГОВ =====
var enemy_templates = {
	"drunkard": {
		"name": "Пьяный",
		"hp": 40,
		"max_hp": 40,
		"damage_min": 3,
		"damage_max": 8,
		"level": 1,
		"faction": "street"  # ✅ Гопота с улицы
	},
	"gopnik": {
		"name": "Гопник",
		"hp": 60,
		"max_hp": 60,
		"damage_min": 8,
		"damage_max": 15,
		"level": 2,
		"faction": "street"  # ✅ Гопота
	},
	"thug": {
		"name": "Хулиган",
		"hp": 80,
		"max_hp": 80,
		"damage_min": 10,
		"damage_max": 18,
		"level": 3,
		"faction": "street"  # ✅ Гопота
	},
	"bandit": {
		"name": "Бандит",
		"hp": 100,
		"max_hp": 100,
		"damage_min": 12,
		"damage_max": 22,
		"level": 4,
		"faction": "criminal"  # ✅ Криминал (могут иметь пистолеты)
	},
	"guard": {
		"name": "Охранник",
		"hp": 120,
		"max_hp": 120,
		"damage_min": 15,
		"damage_max": 25,
		"level": 5,
		"faction": "security"  # ✅ Охрана (оружие и броня)
	},
	"boss": {
		"name": "Главарь",
		"hp": 200,
		"max_hp": 200,
		"damage_min": 20,
		"damage_max": 35,
		"level": 7,
		"faction": "criminal"  # ✅ Криминал
	},
	# ✅ НОВЫЕ ВРАГИ - МЕНТЫ
	"cop": {
		"name": "Мент",
		"hp": 150,
		"max_hp": 150,
		"damage_min": 18,
		"damage_max": 30,
		"level": 5,
		"faction": "police"  # ✅ Милиция
	},
	"swat": {
		"name": "ОМОН",
		"hp": 180,
		"max_hp": 180,
		"damage_min": 22,
		"damage_max": 38,
		"level": 7,
		"faction": "police"  # ✅ Спецназ
	}
}

# ===== ЭКИПИРОВКА ПО ФРАКЦИЯМ =====
func get_equipment_for_faction(faction: String, level: int) -> Dictionary:
	var equipment = {
		"weapon": null,
		"armor": null,
		"helmet": null
	}

	if not items_db:
		return equipment

	match faction:
		"street":  # ✅ ГОПОТА - только ближний бой!
			# Оружие: кулаки, нож, кастет, бита, цепь (НИКОГДА пистолеты!)
			var street_weapons = []
			if level >= 1:
				street_weapons.append("Кулаки")
			if level >= 1:
				street_weapons.append_array(["Нож", "Кухонный нож", "Кастет"])
			if level >= 2:
				street_weapons.append_array(["Бита", "Монтировка"])
			if level >= 3:
				street_weapons.append("Цепь")
			if level >= 4:
				street_weapons.append("Мачете")

			equipment["weapon"] = street_weapons[randi() % street_weapons.size()] if street_weapons.size() > 0 else "Кулаки"

			# Броня: спортивки, куртки
			var street_armor = ["Майка", "Спортивный костюм"]
			if level >= 2:
				street_armor.append_array(["Джинсовка", "Куртка"])
			if level >= 3:
				street_armor.append("Кожанка")

			equipment["armor"] = street_armor[randi() % street_armor.size()]

			# Шлемы: кепки, банданы
			var street_helmets = ["Кепка", "Бандана"]
			if level >= 2:
				street_helmets.append("Шапка-ушанка")

			equipment["helmet"] = street_helmets[randi() % street_helmets.size()]

		"criminal":  # ✅ КРИМИНАЛ - может иметь пистолеты
			# Оружие: ножи на низких уровнях, потом пистолеты
			if level <= 3:
				var crim_melee = ["Нож", "Кастет", "Бита", "Цепь"]
				equipment["weapon"] = crim_melee[randi() % crim_melee.size()]
			else:
				var crim_guns = ["ТТ", "ПМ"]
				if level >= 5:
					crim_guns.append_array(["Наган", "Беретта"])
				if level >= 6:
					crim_guns.append("Обрез")

				equipment["weapon"] = crim_guns[randi() % crim_guns.size()]

			# Броня: кожанки, армейки
			var crim_armor = ["Куртка", "Кожанка"]
			if level >= 4:
				crim_armor.append("Армейская куртка")
			if level >= 5:
				crim_armor.append("Камуфляж")

			equipment["armor"] = crim_armor[randi() % crim_armor.size()]

			# Шлемы
			var crim_helmets = ["Кепка", "Шапка-ушанка"]
			if level >= 4:
				crim_helmets.append("Шлем")

			equipment["helmet"] = crim_helmets[randi() % crim_helmets.size()]

		"security":  # ✅ ОХРАНА - оружие + броня
			# Оружие: пистолеты и дробовики
			var security_weapons = ["ПМ", "Беретта"]
			if level >= 5:
				security_weapons.append("Обрез")
			if level >= 6:
				security_weapons.append("Дробовик")

			equipment["weapon"] = security_weapons[randi() % security_weapons.size()]

			# Броня: хорошая защита
			var security_armor = ["Кожанка", "Армейская куртка", "Камуфляж"]
			if level >= 6:
				security_armor.append("Бронежилет")

			equipment["armor"] = security_armor[randi() % security_armor.size()]

			# Шлемы
			equipment["helmet"] = "Шлем" if level >= 5 else "Каска"

		"police":  # ✅ МЕНТЫ - лучшее оружие и броня!
			# Оружие: только огнестрел
			var police_weapons = ["ПМ", "Беретта", "Обрез"]
			if level >= 6:
				police_weapons.append_array(["Дробовик", "Автомат Калашникова"])
			if level >= 8:
				police_weapons.append("СВД")

			equipment["weapon"] = police_weapons[randi() % police_weapons.size()]

			# Броня: бронежилеты
			var police_armor = ["Камуфляж"]
			if level >= 5:
				police_armor.append("Бронежилет")
			if level >= 7:
				police_armor.append("Тяжёлый бронежилет")

			equipment["armor"] = police_armor[randi() % police_armor.size()]

			# Шлемы
			equipment["helmet"] = "Каска" if level >= 5 else "Шлем"

	return equipment

# ===== ПРИМЕНЕНИЕ ЭКИПИРОВКИ =====
func apply_equipment(enemy: Dictionary) -> void:
	if not items_db:
		return

	var faction = enemy.get("faction", "street")
	var level = enemy.get("level", 1)

	var equipment = get_equipment_for_faction(faction, level)

	# Применяем оружие
	if equipment["weapon"]:
		var weapon_data = items_db.get_item(equipment["weapon"])
		if weapon_data:
			enemy["equipped_weapon"] = equipment["weapon"]

			# ✅ Увеличиваем урон от оружия
			if weapon_data.has("damage"):
				enemy["damage_min"] += weapon_data["damage"]
				enemy["damage_max"] += weapon_data["damage"]

			print("   🗡️ %s экипирован: %s (урон: %d-%d)" % [
				enemy["name"],
				equipment["weapon"],
				enemy["damage_min"],
				enemy["damage_max"]
			])

	# Применяем броню
	if equipment["armor"]:
		var armor_data = items_db.get_item(equipment["armor"])
		if armor_data:
			enemy["equipped_armor"] = equipment["armor"]

			# ✅ Добавляем защиту
			if armor_data.has("defense"):
				if not enemy.has("defense"):
					enemy["defense"] = 0
				enemy["defense"] += armor_data["defense"]

			print("   🛡️ %s носит: %s (защита: +%d)" % [
				enemy["name"],
				equipment["armor"],
				armor_data.get("defense", 0)
			])

	# Применяем шлем
	if equipment["helmet"]:
		var helmet_data = items_db.get_item(equipment["helmet"])
		if helmet_data:
			enemy["equipped_helmet"] = equipment["helmet"]

			# ✅ Добавляем защиту от шлема
			if helmet_data.has("defense"):
				if not enemy.has("defense"):
					enemy["defense"] = 0
				enemy["defense"] += helmet_data["defense"]

			print("   ⛑️ %s в: %s (защита: +%d)" % [
				enemy["name"],
				equipment["helmet"],
				helmet_data.get("defense", 0)
			])

# ===== ГЕНЕРАЦИЯ ВРАГОВ =====
func generate_enemies(enemy_type: String, count: int = 1) -> Array:
	var result = []

	if not enemy_templates.has(enemy_type):
		enemy_type = "gopnik"

	var template = enemy_templates[enemy_type]

	for i in range(count):
		var enemy = template.duplicate(true)

		# Добавляем номер если врагов несколько
		if count > 1:
			enemy["name"] = enemy["name"] + " #" + str(i + 1)

		# ✅ НОВОЕ: Экипируем врага!
		apply_equipment(enemy)

		result.append(enemy)

	return result

# ===== ГЕНЕРАЦИЯ ПО ЛОКАЦИИ =====
func generate_by_location(location: String) -> Array:
	match location:
		"УЛИЦА":
			return generate_enemies(["gopnik", "thug"][randi() % 2], 1 + randi() % 2)
		"ПОРТ":
			return generate_enemies(["bandit", "guard"][randi() % 2], 1 + randi() % 2)
		"ВОКЗАЛ":
			return generate_enemies("gopnik", 1)
		_:
			return generate_enemies("gopnik", 1)
