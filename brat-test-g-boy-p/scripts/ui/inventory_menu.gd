# inventory_menu.gd (ИСПРАВЛЕНО - layer 200)
extends CanvasLayer

signal back_to_gang
signal item_clicked(item_name: String, from_pocket: bool, pocket_index: int)
signal equip_requested(item_name: String)

var items_db
var player_data
var current_member_index = 0
var gang_members = []

func _ready():
	layer = 200  # ✅ КРИТИЧНО! ВЫШЕ сетки (5) и UI (50)
	items_db = get_node("/root/ItemsDB")

func setup(p_data, member_index: int, p_gang_members: Array):
	player_data = p_data
	current_member_index = member_index
	gang_members = p_gang_members

	# ✅ ИСПРАВЛЕНИЕ: Инициализируем нужные поля для всех
	if current_member_index == 0:
		# Инвентарь игрока
		if not player_data.has("pockets"):
			player_data["pockets"] = [null, null, null]
		if not player_data.has("equipment"):
			player_data["equipment"] = {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null}
		if not player_data.has("inventory"):
			player_data["inventory"] = []
	else:
		# Инвентарь члена банды
		if gang_members.size() > current_member_index:
			var member = gang_members[current_member_index]
			if not member.has("pockets"):
				member["pockets"] = [null, null, null]
			if not member.has("equipment"):
				member["equipment"] = {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null}
			if not member.has("inventory"):
				member["inventory"] = []

	create_ui()

# ✅ НОВАЯ ФУНКЦИЯ: Получить правильный словарь данных (игрок или член банды)
func get_current_data() -> Dictionary:
	if current_member_index == 0:
		return player_data
	elif gang_members.size() > current_member_index:
		return gang_members[current_member_index]
	else:
		return player_data  # Fallback

func create_ui():
	for child in get_children():
		child.queue_free()
	
	# ✅ Overlay для блокировки кликов
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1060)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	bg.name = "InventoryBG"
	add_child(bg)
	
	var member_name = "ИНВЕНТАРЬ"
	if gang_members.size() > current_member_index:
		member_name = gang_members[current_member_index]["name"] + " - ИНВЕНТАРЬ"
	
	var title = Label.new()
	title.text = member_name
	title.position = Vector2(200, 160)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	add_child(title)

	# ✅ НОВОЕ: HP машины для ГГ
	if current_member_index == 0 and player_data.get("car"):
		var car_hp_label = Label.new()
		var car_condition = player_data.get("car_condition", 100)
		car_hp_label.text = "🚗 Машина: %d%% HP" % int(car_condition)
		car_hp_label.position = Vector2(250, 190)
		car_hp_label.add_theme_font_size_override("font_size", 16)

		# Цвет в зависимости от состояния
		if car_condition >= 70:
			car_hp_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		elif car_condition >= 40:
			car_hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		else:
			car_hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))

		add_child(car_hp_label)

	# ✅ НОВОЕ: ScrollContainer для контента инвентаря
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(700, 940)  # Высота до кнопки закрытия
	scroll_container.position = Vector2(10, 200)
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll_container)

	# ✅ Control для контента
	var scroll_content = Control.new()
	scroll_content.custom_minimum_size = Vector2(680, 0)  # Высота рассчитается автоматически
	scroll_container.add_child(scroll_content)

	var equip_y = 20  # ✅ Начинаем с малого отступа внутри scroll
	var equipment_slots = [
		["helmet", "🧢 Головной убор"],
		["armor", "🦺 Броня"],
		["melee", "🔪 Ближний бой"],
		["ranged", "🔫 Дальний бой"],
		["gadget", "📱 Гаджет"]
	]

	# ✅ ИСПРАВЛЕНИЕ: Используем правильный словарь данных
	var current_data = get_current_data()

	for slot in equipment_slots:
		var slot_key = slot[0]
		var slot_name = slot[1]
		var equipped_item = current_data["equipment"][slot_key]
		
		var slot_bg = ColorRect.new()
		slot_bg.size = Vector2(680, 50)
		slot_bg.position = Vector2(10, equip_y)  # ✅ Относительно scroll_content
		slot_bg.color = Color(0.2, 0.2, 0.25, 1.0)
		scroll_content.add_child(slot_bg)
		
		var slot_label = Label.new()
		var display_text = slot_name + ": "
		if equipped_item:
			display_text += equipped_item
		else:
			display_text += "—"
		slot_label.text = display_text
		slot_label.position = Vector2(30, equip_y + 15)
		slot_label.add_theme_font_size_override("font_size", 18)
		slot_label.add_theme_color_override("font_color", Color.WHITE)
		scroll_content.add_child(slot_label)

		# ✅ НОВОЕ: Кнопка "СНЯТЬ" для экипированных предметов
		if equipped_item:
			var unequip_btn = Button.new()
			unequip_btn.custom_minimum_size = Vector2(120, 40)
			unequip_btn.position = Vector2(560, equip_y + 5)
			unequip_btn.text = "СНЯТЬ"
			unequip_btn.name = "UnequipBtn_" + slot_key

			var style_unequip = StyleBoxFlat.new()
			style_unequip.bg_color = Color(0.6, 0.3, 0.3, 1.0)
			unequip_btn.add_theme_stylebox_override("normal", style_unequip)

			var style_unequip_hover = StyleBoxFlat.new()
			style_unequip_hover.bg_color = Color(0.7, 0.4, 0.4, 1.0)
			unequip_btn.add_theme_stylebox_override("hover", style_unequip_hover)

			unequip_btn.add_theme_font_size_override("font_size", 16)

			var eq_slot_key = slot_key  # Capture для callback
			unequip_btn.pressed.connect(func():
				# Вызываем сигнал для снятия экипировки
				var inv_manager = get_node("/root/InventoryManager")
				if inv_manager:
					inv_manager.unequip_item(eq_slot_key, current_data, get_parent())
					queue_free()
					inv_manager.show_inventory_for_member(get_parent(), current_member_index, gang_members, player_data)
			)
			scroll_content.add_child(unequip_btn)

		equip_y += 60
	
	var pocket_title = Label.new()
	pocket_title.text = "🎒 КАРМАНЫ (быстрый доступ):"
	pocket_title.position = Vector2(30, equip_y + 20)
	pocket_title.add_theme_font_size_override("font_size", 22)
	pocket_title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8, 1.0))
	scroll_content.add_child(pocket_title)
	
	equip_y += 60

	for i in range(3):
		var pocket_item = current_data["pockets"][i]
		
		var pocket_bg = ColorRect.new()
		pocket_bg.size = Vector2(680, 50)
		pocket_bg.position = Vector2(10, equip_y)
		pocket_bg.color = Color(0.15, 0.25, 0.15, 1.0)
		pocket_bg.name = "Pocket_" + str(i)
		scroll_content.add_child(pocket_bg)
		
		var pocket_label = Label.new()
		var pocket_text = "Карман " + str(i + 1) + ": "
		if pocket_item:
			pocket_text += pocket_item
		else:
			pocket_text += "пусто"
		pocket_label.text = pocket_text
		pocket_label.position = Vector2(30, equip_y + 15)
		pocket_label.add_theme_font_size_override("font_size", 18)
		pocket_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		scroll_content.add_child(pocket_label)
		
		if pocket_item:
			var pocket_btn = Button.new()
			pocket_btn.custom_minimum_size = Vector2(120, 40)
			pocket_btn.position = Vector2(560, equip_y + 5)
			pocket_btn.text = "Действия"
			pocket_btn.name = "PocketBtn_" + str(i)
			
			var style_pocket = StyleBoxFlat.new()
			style_pocket.bg_color = Color(0.3, 0.5, 0.3, 1.0)
			pocket_btn.add_theme_stylebox_override("normal", style_pocket)
			
			var style_pocket_hover = StyleBoxFlat.new()
			style_pocket_hover.bg_color = Color(0.4, 0.6, 0.4, 1.0)
			pocket_btn.add_theme_stylebox_override("hover", style_pocket_hover)
			
			pocket_btn.add_theme_font_size_override("font_size", 16)
			
			var pocket_idx = i
			pocket_btn.pressed.connect(func():
				item_clicked.emit(pocket_item, true, pocket_idx)
			)
			scroll_content.add_child(pocket_btn)
		
		equip_y += 60

	# ✅ НОВОЕ: СЕКЦИЯ МАШИНЫ (только для игрока, не для членов банды)
	if current_member_index == 0 and player_data.get("car"):
		var car_system = get_node_or_null("/root/CarSystem")
		var car_data = null
		if car_system and car_system.cars_db.has(player_data["car"]):
			car_data = car_system.cars_db[player_data["car"]]

		var car_title = Label.new()
		car_title.text = "🚗 МАШИНА:"
		car_title.position = Vector2(30, equip_y + 20)
		car_title.add_theme_font_size_override("font_size", 22)
		car_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
		scroll_content.add_child(car_title)

		equip_y += 60

		# Информация о машине
		var car_info = Label.new()
		if car_data:
			var driver_text = "Водитель: "
			var current_driver = player_data.get("current_driver", null)
			if current_driver == null:
				driver_text += "не выбран"
			elif current_driver == -1:
				driver_text += "Вы"
			elif current_driver >= 0 and gang_members.size() > current_driver:
				driver_text += gang_members[current_driver].get("name", "Боец")
			else:
				driver_text += "не выбран"

			var in_car = player_data.get("in_car", false)
			var car_status = "🟢 В машине" if in_car else "🔴 Пешком"

			car_info.text = "%s\n%s | %s" % [car_data["name"], driver_text, car_status]
		else:
			car_info.text = player_data.get("car", "Неизвестная машина")

		car_info.position = Vector2(20, equip_y)
		car_info.add_theme_font_size_override("font_size", 18)
		car_info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		scroll_content.add_child(car_info)

		equip_y += 60

		# Кнопка "ВЫБРАТЬ ВОДИТЕЛЯ"
		var driver_btn = Button.new()
		driver_btn.custom_minimum_size = Vector2(330, 50)
		driver_btn.position = Vector2(10, equip_y)
		driver_btn.text = "👤 ВЫБРАТЬ ВОДИТЕЛЯ"

		var style_driver = StyleBoxFlat.new()
		style_driver.bg_color = Color(0.4, 0.6, 0.4, 1.0)
		driver_btn.add_theme_stylebox_override("normal", style_driver)

		var style_driver_hover = StyleBoxFlat.new()
		style_driver_hover.bg_color = Color(0.5, 0.7, 0.5, 1.0)
		driver_btn.add_theme_stylebox_override("hover", style_driver_hover)

		driver_btn.add_theme_font_size_override("font_size", 18)
		driver_btn.pressed.connect(func():
			if car_system:
				queue_free()
				car_system.show_driver_selection_menu(get_parent(), player_data)
		)
		scroll_content.add_child(driver_btn)

		# Кнопка "СЕСТЬ/ВЫЙТИ"
		var toggle_car_btn = Button.new()
		toggle_car_btn.custom_minimum_size = Vector2(330, 50)
		toggle_car_btn.position = Vector2(370, equip_y)

		var in_car = player_data.get("in_car", false)
		if in_car:
			toggle_car_btn.text = "🚶 ВЫЙТИ ИЗ МАШИНЫ"
			var style_exit = StyleBoxFlat.new()
			style_exit.bg_color = Color(0.6, 0.4, 0.2, 1.0)
			toggle_car_btn.add_theme_stylebox_override("normal", style_exit)
		else:
			toggle_car_btn.text = "🚗 СЕСТЬ В МАШИНУ"
			var style_enter = StyleBoxFlat.new()
			style_enter.bg_color = Color(0.3, 0.5, 0.7, 1.0)
			toggle_car_btn.add_theme_stylebox_override("normal", style_enter)

		toggle_car_btn.add_theme_font_size_override("font_size", 18)
		toggle_car_btn.pressed.connect(func():
			player_data["in_car"] = not player_data.get("in_car", false)
			if player_data["in_car"]:
				get_parent().show_message("🚗 Вы сели в машину")
			else:
				get_parent().show_message("🚶 Вы вышли из машины")
			queue_free()
		)
		scroll_content.add_child(toggle_car_btn)

		equip_y += 70

	var inv_title = Label.new()
	inv_title.text = "🎒 РЮКЗАК:"
	inv_title.position = Vector2(30, equip_y + 20)
	inv_title.add_theme_font_size_override("font_size", 22)
	inv_title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	scroll_content.add_child(inv_title)

	equip_y += 60

	if current_data["inventory"].size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Рюкзак пуст"
		empty_label.position = Vector2(20, equip_y)
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		scroll_content.add_child(empty_label)
	else:
		for i in range(current_data["inventory"].size()):
			var item = current_data["inventory"][i]
			
			var item_bg = ColorRect.new()
			item_bg.size = Vector2(680, 45)
			item_bg.position = Vector2(10, equip_y)
			item_bg.color = Color(0.15, 0.15, 0.2, 1.0)
			item_bg.name = "InvItem_" + str(i)
			scroll_content.add_child(item_bg)
			
			var item_label = Label.new()
			item_label.text = "• " + item
			item_label.position = Vector2(30, equip_y + 12)
			item_label.add_theme_font_size_override("font_size", 18)
			item_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
			scroll_content.add_child(item_label)
			
			var action_btn = Button.new()
			action_btn.custom_minimum_size = Vector2(120, 35)
			action_btn.position = Vector2(560, equip_y + 5)
			action_btn.text = "Действия"
			action_btn.name = "ActionBtn_" + str(i)
			
			var style_action = StyleBoxFlat.new()
			style_action.bg_color = Color(0.3, 0.4, 0.5, 1.0)
			action_btn.add_theme_stylebox_override("normal", style_action)
			
			var style_action_hover = StyleBoxFlat.new()
			style_action_hover.bg_color = Color(0.4, 0.5, 0.6, 1.0)
			action_btn.add_theme_stylebox_override("hover", style_action_hover)
			
			action_btn.add_theme_font_size_override("font_size", 16)
			
			var item_name = item
			action_btn.pressed.connect(func():
				item_clicked.emit(item_name, false, -1)
			)
			scroll_content.add_child(action_btn)
			
			equip_y += 50

	# ✅ НОВОЕ: Устанавливаем высоту контента
	scroll_content.custom_minimum_size.y = equip_y + 20

	var stats_btn = Button.new()
	stats_btn.custom_minimum_size = Vector2(210, 50)
	stats_btn.position = Vector2(20, 1110)
	stats_btn.text = "📊 СТАТЫ"
	stats_btn.name = "StatsButton"
	
	var style_stats = StyleBoxFlat.new()
	style_stats.bg_color = Color(0.2, 0.3, 0.5, 1.0)
	stats_btn.add_theme_stylebox_override("normal", style_stats)
	
	var style_stats_hover = StyleBoxFlat.new()
	style_stats_hover.bg_color = Color(0.3, 0.4, 0.6, 1.0)
	stats_btn.add_theme_stylebox_override("hover", style_stats_hover)
	
	stats_btn.add_theme_font_size_override("font_size", 20)
	stats_btn.pressed.connect(func(): show_stats_window())
	add_child(stats_btn)
	
	var back_btn = Button.new()
	back_btn.custom_minimum_size = Vector2(210, 50)
	back_btn.position = Vector2(245, 1110)
	back_btn.text = "← БАНДА"
	back_btn.name = "BackToGang"
	
	var style_back = StyleBoxFlat.new()
	style_back.bg_color = Color(0.4, 0.4, 0.1, 1.0)
	back_btn.add_theme_stylebox_override("normal", style_back)
	
	var style_back_hover = StyleBoxFlat.new()
	style_back_hover.bg_color = Color(0.5, 0.5, 0.2, 1.0)
	back_btn.add_theme_stylebox_override("hover", style_back_hover)
	
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(func():
		back_to_gang.emit()
		queue_free()
	)
	add_child(back_btn)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(210, 50)
	close_btn.position = Vector2(470, 1110)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.name = "CloseInventory"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): queue_free())
	add_child(close_btn)

func show_stats_window():
	var player_stats = get_node("/root/PlayerStats")
	if not player_stats:
		return
	
	var stats_popup = CanvasLayer.new()
	stats_popup.name = "StatsPopup"
	stats_popup.layer = 210  # ✅ Еще выше
	get_parent().add_child(stats_popup)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_popup.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(680, 950)
	bg.position = Vector2(20, 165)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	stats_popup.add_child(bg)
	
	var title = Label.new()
	title.text = "📊 СТАТИСТИКА ПЕРСОНАЖА"
	title.position = Vector2(180, 185)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	stats_popup.add_child(title)
	
	var stats_text = player_stats.get_stats_text()
	var label = Label.new()
	label.text = stats_text
	label.position = Vector2(40, 235)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color.WHITE)
	stats_popup.add_child(label)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(640, 50)
	close_btn.position = Vector2(40, 1050)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): stats_popup.queue_free())
	
	stats_popup.add_child(close_btn)
