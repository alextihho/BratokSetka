# robbery_definitions.gd - Определения типов ограблений
extends Node

# Типы ограблений (ключи соответствуют локациям)
const ROBBERIES = {
	"ЛАРЁК": {
		"name": "Ограбить ларёк",
		"icon": "🏪",
		"difficulty": 1,  # 1-5
		"min_reward": 500,
		"max_reward": 2000,
		"duration": 3.0,  # минуты игрового времени
		"alarm_chance": 0.2,  # 20% шанс сигнализации
		"police_chance": 0.3,  # 30% шанс патруля
		"required_stats": {"AGI": 3, "LCK": 2},
		"ua_gain": 15,  # Прирост УА при обнаружении
		"description": "Быстрое ограбление ларька. Низкий риск, небольшая награда.",
		"xp_gain": {"AGI": 5, "LCK": 3, "CHA": 2}
	},
	"КВАРТИРА": {
		"name": "Ограбить квартиру",
		"icon": "🏠",
		"difficulty": 2,
		"min_reward": 1000,
		"max_reward": 5000,
		"duration": 5.0,
		"alarm_chance": 0.35,
		"police_chance": 0.25,
		"required_stats": {"AGI": 5, "INT": 4},
		"ua_gain": 20,
		"description": "Взлом квартиры. Средний риск и награда.",
		"xp_gain": {"AGI": 8, "INT": 6, "LCK": 4}
	},
	"СКЛАД": {
		"name": "Ограбить склад",
		"icon": "🏭",
		"difficulty": 3,
		"min_reward": 3000,
		"max_reward": 10000,
		"duration": 8.0,
		"alarm_chance": 0.5,
		"police_chance": 0.4,
		"required_stats": {"STR": 6, "AGI": 6, "INT": 5},
		"ua_gain": 30,
		"description": "Ограбление склада. Требует силы и ловкости. Высокая награда.",
		"xp_gain": {"STR": 10, "AGI": 10, "INT": 8, "LCK": 5}
	},
	"АВТОСАЛОН": {
		"name": "Ограбить автосалон",
		"icon": "🚗",
		"difficulty": 4,
		"min_reward": 5000,
		"max_reward": 20000,
		"duration": 10.0,
		"alarm_chance": 0.7,
		"police_chance": 0.6,
		"required_stats": {"AGI": 8, "INT": 7, "DRV": 5},
		"ua_gain": 40,
		"description": "Кража машины из автосалона. Очень высокий риск!",
		"xp_gain": {"AGI": 15, "INT": 12, "DRV": 10, "LCK": 6}
	},
	"БАНК": {
		"name": "Ограбить банк",
		"icon": "🏦",
		"difficulty": 5,
		"min_reward": 10000,
		"max_reward": 50000,
		"duration": 15.0,
		"alarm_chance": 0.9,
		"police_chance": 0.8,
		"required_stats": {"STR": 10, "AGI": 10, "INT": 10, "CHA": 8},
		"ua_gain": 60,
		"description": "Ограбление банка. Экстремальный риск! Требует команды и подготовки.",
		"xp_gain": {"STR": 20, "AGI": 20, "INT": 20, "CHA": 15, "LCK": 10}
	}
}

func get_robberies() -> Dictionary:
	return ROBBERIES
