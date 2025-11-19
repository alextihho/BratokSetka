# robbery_generator.gd - Генерация художественного текста ограблений
extends Node

# Генерация художественного текста ограбления
static func generate_story(robbery_state: Dictionary, robbery: Dictionary, caught: bool, reward: int) -> String:
	var story = ""

	# Вступление (подход)
	match robbery_state["approach"]:
		"stealth":
			story += "Вы решили действовать тихо и осторожно. "
		"aggressive":
			story += "Вы ворвались быстро и агрессивно. "
		"clever":
			story += "Вы использовали хитрость и обман. "

	# Проникновение
	match robbery_state["entry_method"]:
		"lockpick":
			story += "Взломали замок за считанные секунды - пальцы работали как часы. "
		"window":
			story += "Пролезли через окно, стараясь не шуметь. "
		"talk":
			story += "Уговорили охранника пропустить вас внутрь. "

	# Действие
	match robbery_state["loot_amount"]:
		"quick":
			story += "Схватили самое ценное и приготовились уходить. "
		"medium":
			story += "Методично собрали всё ценное, что попалось под руку. "
		"greedy":
			story += "Жадно набили карманы всем, что можно унести! "

	# Побег
	match robbery_state["escape_method"]:
		"sneak":
			story += "Незаметно выскользнули, растворившись в темноте. "
		"run":
			story += "Рванули бегом, не оглядываясь назад! "
		"car":
			story += "Запрыгнули в машину и умчались с визгом шин! "

	# Результат
	if caught:
		story += "\n\n⚠️ Но что-то пошло не так! Вас заметили. "
		if randf() < 0.5:
			story += "Успели смыться с частью добычи (+%d руб.)" % reward
		else:
			story += "Пришлось бросить часть награбленного. Всего взяли: %d руб." % reward
	else:
		story += "\n\n✅ Всё прошло идеально! "
		story += "Чистая работа. В кармане теперь %d руб." % reward

	return story
