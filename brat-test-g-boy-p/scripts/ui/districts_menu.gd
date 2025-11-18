extends CanvasLayer

signal district_selected(district_name: String)
signal influence_action(district_name: String, action_type: String)
signal menu_closed()

var districts_system

func _ready():
	districts_system = get_node_or_null("/root/DistrictsSystem")

func setup():
	create_ui()

func create_ui():
	for child in get_children():
		child.queue_free()
	
	if not districts_system:
		print("❌ DistrictsSystem не найдена!")
		return
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	bg.name = "DistrictsBG"
	add_child(bg)
	
	var title = Label.new()
	title.text = "🏙️ РАЙОНЫ ТВЕРИ"
	title.position = Vector2(240, 160)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	add_child(title)
	
	# Общая информация
	var total_income = districts_system.get_total_player_income()
	var income_label = Label.new()
	income_label.text = "💰 Пассивный доход: " + str(total_income) + " руб./день"
	income_label.position = Vector2(30, 210)
	income_label.add_theme_font_size_override("font_size", 18)
	income_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	add_child(income_label)
	
	# Подсказка
	var hint = Label.new()
	hint.text = "💡 Увеличивайте влияние, посещая локации и побеждая в боях"
	hint.position = Vector2(30, 235)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	add_child(hint)

	# ScrollContainer для районов
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 270)
	scroll.size = Vector2(680, 790)  # ✅ Увеличено до 790 (было 780)
	scroll.name = "DistrictsScroll"
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO  # ✅ Автоскролл
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # ✅ Отключен горизонтальный
	add_child(scroll)

	# VBoxContainer для автоматического размещения
	var vbox = VBoxContainer.new()
	vbox.name = "DistrictsVBox"
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# Список районов
	var districts = districts_system.get_all_districts()

	for district in districts:
		create_district_card_scrollable(district, vbox)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1070)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		menu_closed.emit()
		queue_free()
	)
	
	add_child(close_btn)

func create_district_card(district: Dictionary, y_pos: int):
	var district_bg = ColorRect.new()
	district_bg.size = Vector2(680, 160)
	district_bg.position = Vector2(20, y_pos)
	district_bg.color = district["color"] * 0.3
	district_bg.name = "DistrictCard_" + district["name"]
	add_child(district_bg)
	
	# Название района
	var district_name = Label.new()
	district_name.text = "📍 " + district["name"]
	district_name.position = Vector2(30, y_pos + 10)
	district_name.add_theme_font_size_override("font_size", 22)
	district_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	add_child(district_name)
	
	# Владелец
	var owner_label = Label.new()
	var owner_color = Color(0.7, 0.7, 0.7, 1.0)
	if district["owner"] == "Игрок":
		owner_color = Color(0.3, 1.0, 0.3, 1.0)
	elif district["owner"] != "Нейтральный":
		owner_color = Color(1.0, 0.3, 0.3, 1.0)
	
	owner_label.text = "Владелец: " + district["owner"]
	owner_label.position = Vector2(30, y_pos + 40)
	owner_label.add_theme_font_size_override("font_size", 16)
	owner_label.add_theme_color_override("font_color", owner_color)
	add_child(owner_label)
	
	# Влияние игрока
	var player_influence = district["influence"].get("Игрок", 0)
	var influence_label = Label.new()
	influence_label.text = "Ваше влияние: " + str(player_influence) + "%"
	influence_label.position = Vector2(30, y_pos + 65)
	influence_label.add_theme_font_size_override("font_size", 16)
	influence_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	add_child(influence_label)
	
	# Прогресс-бар влияния
	create_progress_bar(player_influence, Vector2(30, y_pos + 90))
	
	# Доход
	var income = districts_system.get_district_income(district["name"], "Игрок")
	var income_text = Label.new()
	income_text.text = "💵 Ваш доход: " + str(income) + " руб./день"
	income_text.position = Vector2(30, y_pos + 120)
	income_text.add_theme_font_size_override("font_size", 14)
	income_text.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7, 1.0))
	add_child(income_text)
	
	# Кнопка подробностей
	var details_btn = Button.new()
	details_btn.custom_minimum_size = Vector2(180, 45)
	details_btn.position = Vector2(500, y_pos + 100)
	details_btn.text = "ПОДРОБНЕЕ"
	
	var style_details = StyleBoxFlat.new()
	style_details.bg_color = Color(0.3, 0.4, 0.5, 1.0)
	details_btn.add_theme_stylebox_override("normal", style_details)
	
	var style_details_hover = StyleBoxFlat.new()
	style_details_hover.bg_color = Color(0.4, 0.5, 0.6, 1.0)
	details_btn.add_theme_stylebox_override("hover", style_details_hover)
	
	details_btn.add_theme_font_size_override("font_size", 16)
	
	var district_name_str = district["name"]
	details_btn.pressed.connect(func():
		district_selected.emit(district_name_str)
	)
	add_child(details_btn)

func create_progress_bar(value: int, pos: Vector2):
	# Фон прогресс-бара
	var progress_bg = ColorRect.new()
	progress_bg.size = Vector2(300, 20)
	progress_bg.position = pos
	progress_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	add_child(progress_bg)
	
	# Заполнение прогресс-бара
	var progress_fill = ColorRect.new()
	var fill_width = 300 * (value / 100.0)
	progress_fill.size = Vector2(fill_width, 20)
	progress_fill.position = pos
	
	# Цвет зависит от уровня влияния
	if value >= 50:
		progress_fill.color = Color(0.3, 1.0, 0.3, 1.0)  # Зеленый - контроль
	elif value >= 25:
		progress_fill.color = Color(0.8, 0.8, 0.3, 1.0)  # Желтый - среднее влияние
	else:
		progress_fill.color = Color(1.0, 0.4, 0.4, 1.0)  # Красный - малое влияние
	
	add_child(progress_fill)
	
	# Текст процента
	var percent_label = Label.new()
	percent_label.text = str(value) + "%"
	percent_label.position = pos + Vector2(135, 2)
	percent_label.add_theme_font_size_override("font_size", 14)
	percent_label.add_theme_color_override("font_color", Color.BLACK)
	add_child(percent_label)

# Новая функция для создания карточки внутри ScrollContainer
func create_district_card_scrollable(district: Dictionary, container: VBoxContainer):
	var card = Control.new()
	card.custom_minimum_size = Vector2(660, 160)
	card.name = "DistrictCard_" + district["name"]
	container.add_child(card)

	# Фон карточки
	var district_bg = ColorRect.new()
	district_bg.size = Vector2(660, 160)
	district_bg.position = Vector2(0, 0)
	district_bg.color = district["color"] * 0.3
	card.add_child(district_bg)

	# Название района
	var district_name = Label.new()
	district_name.text = "📍 " + district["name"]
	district_name.position = Vector2(10, 10)
	district_name.add_theme_font_size_override("font_size", 22)
	district_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	card.add_child(district_name)

	# Владелец
	var owner_label = Label.new()
	var owner_color = Color(0.7, 0.7, 0.7, 1.0)
	if district["owner"] == "Игрок":
		owner_color = Color(0.3, 1.0, 0.3, 1.0)
	elif district["owner"] != "Нейтральный":
		owner_color = Color(1.0, 0.3, 0.3, 1.0)

	owner_label.text = "Владелец: " + district["owner"]
	owner_label.position = Vector2(10, 40)
	owner_label.add_theme_font_size_override("font_size", 16)
	owner_label.add_theme_color_override("font_color", owner_color)
	card.add_child(owner_label)

	# Влияние игрока
	var player_influence = district["influence"].get("Игрок", 0)
	var influence_label = Label.new()
	influence_label.text = "Ваше влияние: " + str(player_influence) + "%"
	influence_label.position = Vector2(10, 65)
	influence_label.add_theme_font_size_override("font_size", 16)
	influence_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	card.add_child(influence_label)

	# Прогресс-бар влияния
	create_progress_bar_in_card(player_influence, Vector2(10, 90), card)

	# Доход
	var income = districts_system.get_district_income(district["name"], "Игрок")
	var income_text = Label.new()
	income_text.text = "💵 Ваш доход: " + str(income) + " руб./день"
	income_text.position = Vector2(10, 120)
	income_text.add_theme_font_size_override("font_size", 14)
	income_text.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7, 1.0))
	card.add_child(income_text)

	# Кнопка подробностей
	var details_btn = Button.new()
	details_btn.custom_minimum_size = Vector2(180, 45)
	details_btn.position = Vector2(470, 100)
	details_btn.text = "ПОДРОБНЕЕ"

	var style_details = StyleBoxFlat.new()
	style_details.bg_color = Color(0.3, 0.4, 0.5, 1.0)
	details_btn.add_theme_stylebox_override("normal", style_details)

	var style_details_hover = StyleBoxFlat.new()
	style_details_hover.bg_color = Color(0.4, 0.5, 0.6, 1.0)
	details_btn.add_theme_stylebox_override("hover", style_details_hover)

	details_btn.add_theme_font_size_override("font_size", 16)

	var district_name_str = district["name"]
	details_btn.pressed.connect(func():
		district_selected.emit(district_name_str)
	)
	card.add_child(details_btn)

# Прогресс-бар для карточки внутри ScrollContainer
func create_progress_bar_in_card(value: int, pos: Vector2, parent: Control):
	var progress_bg = ColorRect.new()
	progress_bg.size = Vector2(300, 20)
	progress_bg.position = pos
	progress_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	parent.add_child(progress_bg)

	var progress_fill = ColorRect.new()
	var fill_width = 300 * (value / 100.0)
	progress_fill.size = Vector2(fill_width, 20)
	progress_fill.position = pos

	if value >= 50:
		progress_fill.color = Color(0.3, 1.0, 0.3, 1.0)
	elif value >= 25:
		progress_fill.color = Color(0.8, 0.8, 0.3, 1.0)
	else:
		progress_fill.color = Color(1.0, 0.4, 0.4, 1.0)

	parent.add_child(progress_fill)

	var percent_label = Label.new()
	percent_label.text = str(value) + "%"
	percent_label.position = pos + Vector2(135, 2)
	percent_label.add_theme_font_size_override("font_size", 14)
	percent_label.add_theme_color_override("font_color", Color.BLACK)
	parent.add_child(percent_label)
