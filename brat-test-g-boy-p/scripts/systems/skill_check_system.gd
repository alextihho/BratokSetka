# skill_check_system.gd - Система проверки навыков
extends Node

# Проверка навыка + инструмента vs уровень цели
static func check_skill(player_data: Dictionary, player_stats, stat_name: String, min_stat: int, security_level: int, tool_required = null) -> Dictionary:
	var result = {
		"success": false,
		"stat_used": stat_name,
		"xp_gained": 0,
		"reason": "",
		"time_spent": 0
	}

	# Проверка инструмента
	var has_tool = true
	var tool_level = 0

	if tool_required != null and tool_required != "":
		has_tool = player_data.get(tool_required, false)
		if not has_tool:
			result["reason"] = "❌ Требуется: " + get_tool_name(tool_required)
			result["time_spent"] = 5  # Потратили время на осознание проблемы
			return result

		# Уровень инструмента
		tool_level = player_data.get(tool_required + "_level", 1)

	# Получить навык
	var stat_value = 0
	if player_stats:
		stat_value = player_stats.get_stat(stat_name)

	# Проверка минимального требования
	if stat_value < min_stat:
		result["reason"] = "❌ Недостаточно навыка %s\n\nТребуется: %d\nУ вас: %d" % [stat_name, min_stat, stat_value]
		result["xp_gained"] = 1  # Немного опыта за попытку
		result["time_spent"] = randi_range(10, 20)
		return result

	# Формула: (навык + уровень_инструмента) vs (security_level * 2)
	var player_power = stat_value + tool_level
	var target_dc = security_level * 2  # DC = Difficulty Check

	# Добавляем случайность (d6)
	var roll = randi_range(1, 6)
	var total = player_power + roll

	print("🎲 Проверка навыка %s: %d (навык) + %d (инструмент) + %d (бросок) = %d vs %d (DC)" % [stat_name, stat_value, tool_level, roll, total, target_dc])

	if total >= target_dc:
		result["success"] = true
		result["xp_gained"] = 2 + security_level  # Больше опыта за сложные цели
		result["time_spent"] = randi_range(5, 15)
	else:
		result["success"] = false
		result["xp_gained"] = 1 + (security_level / 2)  # Опыт за попытку
		result["time_spent"] = randi_range(15, 30)  # Провал занимает больше времени
		result["reason"] = get_failure_reason(stat_name, total - target_dc)

	return result

# Получить название инструмента
static func get_tool_name(tool_key: String) -> String:
	match tool_key:
		"lockpick": return "Отмычка"
		"melee_weapon": return "Оружие ближнего боя"
		"crowbar": return "Лом"
		"hacking_device": return "Взломщик"
		_: return tool_key

# Получить причину провала
static func get_failure_reason(stat_name: String, deficit: int) -> String:
	var reasons = {
		"STR": [
			"Вас заметил случайный прохожий и решил проследить за вами, вы решили стряхнуть хвост и гуляли с этим чучелом более 2х часов",
			"Окно оказалось прочнее чем вы думали. Пришлось отступить",
			"Не хватило силы чтобы взломать защиту. Слишком много шума"
		],
		"AGI": [
			"Отмычка сломалась. Нужна новая",
			"Замок оказался сложнее чем казалось. Пальцы не слушаются",
			"Вы потратили слишком много времени, пришлось уйти"
		],
		"CHA": [
			"Охранник вас не послушал. Придется искать другой способ",
			"Вас заподозрили в чем-то нехорошем",
			"Ваши слова не убедили. Слишком подозрительно выглядите"
		],
		"INT": [
			"Сигнализация сложнее чем вы думали",
			"Не смогли найти уязвимость в системе",
			"Код постоянно меняется, не успеваете"
		]
	}

	var reason_list = reasons.get(stat_name, ["Что-то пошло не так"])
	return reason_list[randi() % reason_list.size()]
