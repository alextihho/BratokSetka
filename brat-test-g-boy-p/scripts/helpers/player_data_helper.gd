# player_data_helper.gd - Вспомогательные функции для работы с данными игрока
extends Node

# ===== КОНСТАНТЫ =====
const DEFAULT_EQUIPMENT = {
	"helmet": null,
	"armor": null,
	"melee": null,
	"ranged": null,
	"gadget": null
}

const DEFAULT_POCKETS = [null, null, null]

# ===== СОЗДАНИЕ ПУСТОЙ ЭКИПИРОВКИ =====
static func create_empty_equipment() -> Dictionary:
	return DEFAULT_EQUIPMENT.duplicate(true)

# ===== СОЗДАНИЕ ПУСТЫХ КАРМАНОВ =====
static func create_empty_pockets() -> Array:
	return DEFAULT_POCKETS.duplicate(true)

# ===== ИНИЦИАЛИЗАЦИЯ ДАННЫХ ИГРОКА =====
static func initialize_player_data(balance: int = 150, health: int = 100) -> Dictionary:
	return {
		"balance": balance,
		"health": health,
		"reputation": 0,
		"completed_quests": [],
		"equipment": create_empty_equipment(),
		"inventory": [],
		"pockets": create_empty_pockets(),
		"current_square": "6_2",
		"first_battle_completed": false,
		"car": null,
		"car_condition": 100.0,
		"car_equipped": false,
		"current_driver": null
	}

# ===== ИНИЦИАЛИЗАЦИЯ ЧЛЕНА БАНДЫ =====
static func initialize_gang_member(name: String, hp: int = 80, damage: int = 10) -> Dictionary:
	return {
		"name": name,
		"health": hp,
		"hp": hp,
		"max_hp": hp,
		"damage": damage,
		"strength": damage,
		"defense": 0,
		"morale": 80,
		"accuracy": 0.65,
		"equipment": create_empty_equipment(),
		"inventory": [],
		"pockets": create_empty_pockets(),
		"is_active": false,
		"weapon": "Кулаки"
	}

# ===== ВАЛИДАЦИЯ ДАННЫХ ЧЛЕНА БАНДЫ =====
static func validate_gang_member(member: Dictionary) -> Dictionary:
	if not member.has("hp"):
		member["hp"] = member.get("health", 80)
	if not member.has("max_hp"):
		member["max_hp"] = member["hp"]
	if not member.has("damage"):
		member["damage"] = member.get("strength", 10)
	if not member.has("defense"):
		member["defense"] = 0
	if not member.has("morale"):
		member["morale"] = 80
	if not member.has("accuracy"):
		member["accuracy"] = 0.65
	if not member.has("equipment"):
		member["equipment"] = create_empty_equipment()
	if not member.has("inventory"):
		member["inventory"] = []
	if not member.has("pockets"):
		member["pockets"] = create_empty_pockets()
	if not member.has("is_active"):
		member["is_active"] = false
	return member

# ===== БЕЗОПАСНОЕ ПОЛУЧЕНИЕ ЗНАЧЕНИЙ =====
static func get_balance(player_data: Dictionary) -> int:
	return player_data.get("balance", 0)

static func get_health(player_data: Dictionary) -> int:
	return player_data.get("health", 100)

static func get_reputation(player_data: Dictionary) -> int:
	return player_data.get("reputation", 0)

static func get_equipment(player_data: Dictionary) -> Dictionary:
	return player_data.get("equipment", create_empty_equipment())

static func get_inventory(player_data: Dictionary) -> Array:
	return player_data.get("inventory", [])

static func get_pockets(player_data: Dictionary) -> Array:
	return player_data.get("pockets", create_empty_pockets())
