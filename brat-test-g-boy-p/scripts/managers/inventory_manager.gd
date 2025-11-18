# inventory_manager.gd - Менеджер инвентаря (autoload)
extends Node

# ✅ ГЛАВНАЯ ФУНКЦИЯ для открытия инвентаря члена банды
func show_inventory_for_member(main_node: Node, member_index: int, gang_members: Array, player_data: Dictionary):
	# ✅ ПРОВЕРКА: Инициализируем все необходимые поля
	if not player_data.has("equipment"):
		player_data["equipment"] = {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null}

	if not player_data.has("inventory"):
		player_data["inventory"] = []

	if not player_data.has("pockets"):
		player_data["pockets"] = [null, null, null]

	# Создаем экземпляр меню инвентаря
	var inv_menu_script = load("res://scripts/ui/inventory_menu.gd")
	var inv_menu = inv_menu_script.new()
	inv_menu.name = "InventoryMenu"
	main_node.add_child(inv_menu)

	# Настраиваем меню
	inv_menu.setup(player_data, member_index, gang_members)

	# Обрабатываем клики по предметам
	inv_menu.item_clicked.connect(func(item_name, from_pocket, pocket_index):
		show_item_popup(main_node, item_name, from_pocket, pocket_index, player_data, inv_menu)
	)

# Показать попап действий с предметом
func show_item_popup(main_node: Node, item_name: String, from_pocket: bool, pocket_index: int, player_data: Dictionary, inv_menu: CanvasLayer):
	var items_db = get_node("/root/ItemsDB")
	if not items_db:
		return

	var item_data = items_db.get_item(item_name)
	if not item_data:
		main_node.show_message("⚠️ Предмет не найден: " + item_name)
		return

	var popup = CanvasLayer.new()
	popup.name = "ItemPopup"
	popup.layer = 220
	main_node.add_child(popup)

	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(overlay)

	var bg = ColorRect.new()
	bg.size = Vector2(600, 600)
	bg.position = Vector2(60, 340)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	popup.add_child(bg)

	var title = Label.new()
	title.text = item_name
	title.position = Vector2(200, 360)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	popup.add_child(title)

	var desc = Label.new()
	desc.text = item_data.get("description", "Описание отсутствует")
	desc.position = Vector2(80, 410)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	popup.add_child(desc)

	var btn_y = 480
	var item_type = item_data.get("type", "consumable")

	# Кнопки в зависимости от типа предмета
	if item_type == "consumable":
		var use_btn = Button.new()
		use_btn.custom_minimum_size = Vector2(540, 50)
		use_btn.position = Vector2(90, btn_y)
		use_btn.text = "ИСПОЛЬЗОВАТЬ"
		use_btn.add_theme_font_size_override("font_size", 20)
		use_btn.pressed.connect(func():
			use_item(item_name, from_pocket, pocket_index, player_data, main_node)
			popup.queue_free()
			inv_menu.queue_free()
			show_inventory_for_member(main_node, 0, main_node.gang_members, player_data)
		)
		popup.add_child(use_btn)
		btn_y += 70

	if item_type in ["weapon", "armor", "helmet", "gadget", "melee", "ranged"]:
		var equip_btn = Button.new()
		equip_btn.custom_minimum_size = Vector2(540, 50)
		equip_btn.position = Vector2(90, btn_y)
		equip_btn.text = "ЭКИПИРОВАТЬ"
		equip_btn.add_theme_font_size_override("font_size", 20)
		equip_btn.pressed.connect(func():
			equip_item(item_name, from_pocket, pocket_index, player_data, main_node)
			popup.queue_free()
			inv_menu.queue_free()
			show_inventory_for_member(main_node, 0, main_node.gang_members, player_data)
		)
		popup.add_child(equip_btn)
		btn_y += 70

	if not from_pocket:
		var pocket_btn = Button.new()
		pocket_btn.custom_minimum_size = Vector2(540, 50)
		pocket_btn.position = Vector2(90, btn_y)
		pocket_btn.text = "В КАРМАН"
		pocket_btn.add_theme_font_size_override("font_size", 20)
		pocket_btn.pressed.connect(func():
			move_to_pocket(item_name, player_data, main_node)
			popup.queue_free()
			inv_menu.queue_free()
			show_inventory_for_member(main_node, 0, main_node.gang_members, player_data)
		)
		popup.add_child(pocket_btn)
		btn_y += 70

	# ✅ НОВОЕ: Кнопка передачи предмета другому члену банды
	if main_node.gang_members.size() > 1:
		var transfer_btn = Button.new()
		transfer_btn.custom_minimum_size = Vector2(540, 50)
		transfer_btn.position = Vector2(90, btn_y)
		transfer_btn.text = "ПЕРЕДАТЬ ЧЛЕНУ БАНДЫ"
		transfer_btn.add_theme_font_size_override("font_size", 20)

		var style_transfer = StyleBoxFlat.new()
		style_transfer.bg_color = Color(0.3, 0.3, 0.5, 1.0)
		transfer_btn.add_theme_stylebox_override("normal", style_transfer)

		var style_transfer_hover = StyleBoxFlat.new()
		style_transfer_hover.bg_color = Color(0.4, 0.4, 0.6, 1.0)
		transfer_btn.add_theme_stylebox_override("hover", style_transfer_hover)

		transfer_btn.pressed.connect(func():
			show_transfer_menu(main_node, item_name, from_pocket, pocket_index, player_data, popup, inv_menu)
		)
		popup.add_child(transfer_btn)
		btn_y += 70

	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(540, 50)
	close_btn.position = Vector2(90, 850)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): popup.queue_free())
	popup.add_child(close_btn)

func use_item(item_name: String, from_pocket: bool, pocket_index: int, player_data: Dictionary, main_node: Node):
	var items_db = get_node("/root/ItemsDB")
	var item_data = items_db.get_item(item_name)

	if not item_data:
		return

	# ✅ ИСПРАВЛЕНО: Правильная структура данных из items_db
	if item_data.get("effect", "") == "heal":
		var heal_value = item_data.get("value", 0)
		player_data["health"] = min(100, player_data["health"] + heal_value)
		main_node.show_message("❤️ Восстановлено " + str(heal_value) + " HP")

	# Удаляем предмет
	if from_pocket:
		player_data["pockets"][pocket_index] = null
	else:
		player_data["inventory"].erase(item_name)

	main_node.update_ui()

func equip_item(item_name: String, from_pocket: bool, pocket_index: int, player_data: Dictionary, main_node: Node):
	var items_db = get_node("/root/ItemsDB")
	var item_data = items_db.get_item(item_name)

	if not item_data:
		return

	var item_type = item_data.get("type", "")

	# ✅ ИСПРАВЛЕНО: Правильная карта слотов
	var slot_map = {
		"helmet": "helmet",
		"armor": "armor",
		"melee": "melee",
		"ranged": "ranged",
		"weapon": "melee",
		"gadget": "gadget"
	}

	var slot = slot_map.get(item_type, "")
	if slot == "":
		main_node.show_message("❌ Этот предмет нельзя экипировать")
		return

	# Снимаем старый предмет если есть
	if player_data["equipment"][slot]:
		player_data["inventory"].append(player_data["equipment"][slot])

	# Экипируем новый
	player_data["equipment"][slot] = item_name

	# Удаляем из инвентаря/кармана
	if from_pocket:
		player_data["pockets"][pocket_index] = null
	else:
		player_data["inventory"].erase(item_name)

	main_node.show_message("✅ Экипировано: " + item_name)

	# ✅ ВАЖНО: Обновляем статы игрока
	var player_stats = get_node_or_null("/root/PlayerStats")
	if player_stats and player_stats.has_method("recalculate_equipment_bonuses"):
		player_stats.recalculate_equipment_bonuses(player_data["equipment"], items_db)

	main_node.update_ui()

func move_to_pocket(item_name: String, player_data: Dictionary, main_node: Node):
	for i in range(3):
		if player_data["pockets"][i] == null:
			player_data["pockets"][i] = item_name
			player_data["inventory"].erase(item_name)
			main_node.show_message("🎒 Предмет помещён в карман " + str(i + 1))
			return

	main_node.show_message("❌ Карманы заполнены!")

# ✅ НОВАЯ ФУНКЦИЯ: Меню выбора члена банды для передачи предмета
func show_transfer_menu(main_node: Node, item_name: String, from_pocket: bool, pocket_index: int, player_data: Dictionary, item_popup: CanvasLayer, inv_menu: CanvasLayer):
	var transfer_menu = CanvasLayer.new()
	transfer_menu.name = "TransferMenu"
	transfer_menu.layer = 230
	main_node.add_child(transfer_menu)

	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	transfer_menu.add_child(overlay)

	var bg = ColorRect.new()
	bg.size = Vector2(600, 800)
	bg.position = Vector2(60, 240)
	bg.color = Color(0.05, 0.05, 0.1, 0.98)
	transfer_menu.add_child(bg)

	var title = Label.new()
	title.text = "КОМУ ПЕРЕДАТЬ: " + item_name
	title.position = Vector2(120, 260)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	transfer_menu.add_child(title)

	var member_y = 320

	# Перебираем всех членов банды, кроме текущего (игрока)
	for i in range(main_node.gang_members.size()):
		if i == 0:  # Пропускаем главного игрока
			continue

		var member = main_node.gang_members[i]

		var member_bg = ColorRect.new()
		member_bg.size = Vector2(560, 80)
		member_bg.position = Vector2(80, member_y)
		member_bg.color = Color(0.15, 0.15, 0.2, 1.0)
		transfer_menu.add_child(member_bg)

		var member_label = Label.new()
		member_label.text = member["name"]
		if member.has("background"):
			member_label.text += " (" + member["background"] + ")"
		member_label.position = Vector2(100, member_y + 10)
		member_label.add_theme_font_size_override("font_size", 18)
		member_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		transfer_menu.add_child(member_label)

		var transfer_to_btn = Button.new()
		transfer_to_btn.custom_minimum_size = Vector2(240, 50)
		transfer_to_btn.position = Vector2(360, member_y + 15)
		transfer_to_btn.text = "ПЕРЕДАТЬ"

		var style_btn = StyleBoxFlat.new()
		style_btn.bg_color = Color(0.2, 0.5, 0.3, 1.0)
		transfer_to_btn.add_theme_stylebox_override("normal", style_btn)

		var style_btn_hover = StyleBoxFlat.new()
		style_btn_hover.bg_color = Color(0.3, 0.6, 0.4, 1.0)
		transfer_to_btn.add_theme_stylebox_override("hover", style_btn_hover)

		transfer_to_btn.add_theme_font_size_override("font_size", 18)

		var target_index = i
		transfer_to_btn.pressed.connect(func():
			transfer_item_to_member(item_name, from_pocket, pocket_index, player_data, main_node.gang_members[target_index], main_node)
			transfer_menu.queue_free()
			item_popup.queue_free()
			inv_menu.queue_free()
			show_inventory_for_member(main_node, 0, main_node.gang_members, player_data)
		)
		transfer_menu.add_child(transfer_to_btn)

		member_y += 100

	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(560, 50)
	cancel_btn.position = Vector2(80, 980)
	cancel_btn.text = "ОТМЕНА"

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)

	var style_cancel_hover = StyleBoxFlat.new()
	style_cancel_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	cancel_btn.add_theme_stylebox_override("hover", style_cancel_hover)

	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func(): transfer_menu.queue_free())
	transfer_menu.add_child(cancel_btn)

# ✅ НОВАЯ ФУНКЦИЯ: Передача предмета члену банды
func transfer_item_to_member(item_name: String, from_pocket: bool, pocket_index: int, from_data: Dictionary, to_member: Dictionary, main_node: Node):
	# Удаляем предмет из инвентаря/кармана отправителя
	if from_pocket:
		from_data["pockets"][pocket_index] = null
	else:
		from_data["inventory"].erase(item_name)

	# Инициализируем инвентарь получателя, если его нет
	if not to_member.has("inventory"):
		to_member["inventory"] = []

	# Добавляем предмет в инвентарь получателя
	to_member["inventory"].append(item_name)

	main_node.show_message("✅ %s передан члену банды %s" % [item_name, to_member["name"]])
	main_node.update_ui()
