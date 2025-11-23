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

# ===== ВАЛИДАЦИЯ ДАННЫХ ИГРОКА =====
static func validate_player_data(player_data: Dictionary) -> void:
	if not player_data.has("equipment"):
		player_data["equipment"] = create_empty_equipment()
	if not player_data.has("inventory"):
		player_data["inventory"] = []
	if not player_data.has("pockets"):
		player_data["pockets"] = create_empty_pockets()

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
