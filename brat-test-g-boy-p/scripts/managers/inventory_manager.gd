# inventory_manager.gd - Менеджер инвентаря (autoload)
extends Node

# ✅ ГЛАВНАЯ ФУНКЦИЯ для открытия инвентаря члена банды
func show_inventory_for_member(main_node: Node, member_index: int, gang_members: Array, player_data: Dictionary):
	# ✅ ОПРЕДЕЛЯЕМ ПРАВИЛЬНЫЙ СЛОВАРЬ ДАННЫХ
	var current_data: Dictionary
	if member_index == 0:
		current_data = player_data
		# Инициализируем поля игрока
		if not player_data.has("equipment"):
			player_data["equipment"] = {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null}
		if not player_data.has("inventory"):
			player_data["inventory"] = []
		if not player_data.has("pockets"):
			player_data["pockets"] = [null, null, null]
	else:
		# Инвентарь члена банды
		if gang_members.size() > member_index:
			current_data = gang_members[member_index]
			# Инициализируем поля члена банды
			if not current_data.has("equipment"):
				current_data["equipment"] = {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null}
			if not current_data.has("inventory"):
				current_data["inventory"] = []
			if not current_data.has("pockets"):
				current_data["pockets"] = [null, null, null]
		else:
			current_data = player_data  # Fallback

	# Создаем экземпляр меню инвентаря
	var inv_menu_script = load("res://scripts/ui/inventory_menu.gd")
	var inv_menu = inv_menu_script.new()
	inv_menu.name = "InventoryMenu"
	main_node.add_child(inv_menu)

	# Настраиваем меню
	inv_menu.setup(player_data, member_index, gang_members)

	# Обрабатываем клики по предметам - передаем ПРАВИЛЬНЫЙ словарь данных!
	inv_menu.item_clicked.connect(func(item_name, from_pocket, pocket_index):
		show_item_popup(main_node, item_name, from_pocket, pocket_index, current_data, inv_menu, member_index, gang_members, player_data)
	)

	# ✅ НОВОЕ: Возврат в меню банды
	inv_menu.back_to_gang.connect(func():
		var gang_manager = get_node("/root/GangManager")
		if gang_manager:
			gang_manager.show_gang_menu(main_node, gang_members)
	)

# Показать попап действий с предметом
func show_item_popup(main_node: Node, item_name: String, from_pocket: bool, pocket_index: int, current_data: Dictionary, inv_menu: CanvasLayer, member_index: int, gang_members: Array, player_data: Dictionary):
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
			use_item(item_name, from_pocket, pocket_index, current_data, main_node)
			popup.queue_free()
			inv_menu.queue_free()
			show_inventory_for_member(main_node, member_index, gang_members, player_data)
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
			equip_item(item_name, from_pocket, pocket_index, current_data, main_node, member_index, player_data)
			popup.queue_free()
			inv_menu.queue_free()
			show_inventory_for_member(main_node, member_index, gang_members, player_data)
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
			move_to_pocket(item_name, current_data, main_node)
			popup.queue_free()
			inv_menu.queue_free()
			show_inventory_for_member(main_node, member_index, gang_members, player_data)
		)
		popup.add_child(pocket_btn)
		btn_y += 70

	# ✅ НОВОЕ: Кнопка ПЕРЕДАТЬ (только если есть другие члены банды)
	if gang_members.size() > 1:
		var transfer_btn = Button.new()
		transfer_btn.custom_minimum_size = Vector2(540, 50)
		transfer_btn.position = Vector2(90, btn_y)
		transfer_btn.text = "📦 ПЕРЕДАТЬ"
		transfer_btn.add_theme_font_size_override("font_size", 20)

		var style_transfer = StyleBoxFlat.new()
		style_transfer.bg_color = Color(0.3, 0.4, 0.6, 1.0)
		transfer_btn.add_theme_stylebox_override("normal", style_transfer)

		var style_transfer_hover = StyleBoxFlat.new()
		style_transfer_hover.bg_color = Color(0.4, 0.5, 0.7, 1.0)
		transfer_btn.add_theme_stylebox_override("hover", style_transfer_hover)

		transfer_btn.pressed.connect(func():
			popup.queue_free()
			show_transfer_menu(main_node, item_name, from_pocket, pocket_index, current_data, member_index, gang_members, player_data)
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

func use_item(item_name: String, from_pocket: bool, pocket_index: int, current_data: Dictionary, main_node: Node):
	var items_db = get_node("/root/ItemsDB")
	var item_data = items_db.get_item(item_name)

	if not item_data:
		return

	# ✅ ИСПРАВЛЕНО: Правильная структура данных из items_db
	if item_data.get("effect", "") == "heal":
		var heal_value = item_data.get("value", 0)
		current_data["health"] = min(100, current_data.get("health", 100) + heal_value)
		main_node.show_message("❤️ Восстановлено " + str(heal_value) + " HP")

	# Удаляем предмет из правильного инвентаря
	if from_pocket:
		current_data["pockets"][pocket_index] = null
	else:
		current_data["inventory"].erase(item_name)

	main_node.update_ui()

func equip_item(item_name: String, from_pocket: bool, pocket_index: int, current_data: Dictionary, main_node: Node, member_index: int, player_data: Dictionary):
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

	# Снимаем старый предмет если есть из ПРАВИЛЬНОГО инвентаря
	if current_data["equipment"][slot]:
		current_data["inventory"].append(current_data["equipment"][slot])

	# Экипируем новый в ПРАВИЛЬНЫЙ слот
	current_data["equipment"][slot] = item_name

	# Удаляем из инвентаря/кармана ПРАВИЛЬНОГО персонажа
	if from_pocket:
		current_data["pockets"][pocket_index] = null
	else:
		current_data["inventory"].erase(item_name)

	main_node.show_message("✅ Экипировано: " + item_name)

	# ✅ ВАЖНО: Обновляем статы ТОЛЬКО для игрока (member_index == 0)
	if member_index == 0:
		var player_stats = get_node_or_null("/root/PlayerStats")
		if player_stats and player_stats.has_method("recalculate_equipment_bonuses"):
			player_stats.recalculate_equipment_bonuses(player_data["equipment"], items_db)

	main_node.update_ui()

func move_to_pocket(item_name: String, current_data: Dictionary, main_node: Node):
	for i in range(3):
		if current_data["pockets"][i] == null:
			current_data["pockets"][i] = item_name
			current_data["inventory"].erase(item_name)
			main_node.show_message("🎒 Предмет помещён в карман " + str(i + 1))
			return

	main_node.show_message("❌ Карманы заполнены!")

# ✅ НОВАЯ ФУНКЦИЯ: Снять экипировку
func unequip_item(slot_key: String, current_data: Dictionary, main_node: Node):
	if not current_data.has("equipment"):
		main_node.show_message("❌ Ошибка: нет данных экипировки")
		return

	var equipped_item = current_data["equipment"].get(slot_key, null)
	if not equipped_item:
		main_node.show_message("❌ В этом слоте ничего не экипировано")
		return

	# Снимаем предмет и добавляем в инвентарь
	current_data["equipment"][slot_key] = null
	current_data["inventory"].append(equipped_item)

	main_node.show_message("✅ Снято: " + equipped_item)
	main_node.update_ui()

# ✅ НОВАЯ ФУНКЦИЯ: Меню выбора получателя предмета
func show_transfer_menu(main_node: Node, item_name: String, from_pocket: bool, pocket_index: int, current_data: Dictionary, from_member_index: int, gang_members: Array, player_data: Dictionary):
	var transfer_menu = CanvasLayer.new()
	transfer_menu.name = "TransferMenu"
	transfer_menu.layer = 230  # Поверх всего
	main_node.add_child(transfer_menu)

	# Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	transfer_menu.add_child(overlay)

	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(600, 800)
	bg.position = Vector2(60, 240)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	transfer_menu.add_child(bg)

	# Заголовок
	var title = Label.new()
	title.text = "📦 ПЕРЕДАТЬ: " + item_name
	title.position = Vector2(120, 260)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	transfer_menu.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Выберите кому передать предмет:"
	subtitle.position = Vector2(140, 300)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	transfer_menu.add_child(subtitle)

	var btn_y = 350

	# Кнопки для каждого члена банды (кроме себя)
	for i in range(gang_members.size()):
		if i == from_member_index:
			continue  # Пропускаем себя

		var member = gang_members[i]
		var member_btn = Button.new()
		member_btn.custom_minimum_size = Vector2(540, 60)
		member_btn.position = Vector2(90, btn_y)

		var member_name = member.get("name", "Боец " + str(i))
		member_btn.text = "👤 " + member_name
		member_btn.add_theme_font_size_override("font_size", 20)

		var style_member = StyleBoxFlat.new()
		style_member.bg_color = Color(0.2, 0.3, 0.5, 1.0)
		member_btn.add_theme_stylebox_override("normal", style_member)

		var style_member_hover = StyleBoxFlat.new()
		style_member_hover.bg_color = Color(0.3, 0.4, 0.6, 1.0)
		member_btn.add_theme_stylebox_override("hover", style_member_hover)

		var to_index = i
		member_btn.pressed.connect(func():
			transfer_item(item_name, from_pocket, pocket_index, current_data, gang_members[to_index], main_node)
			transfer_menu.queue_free()
			show_inventory_for_member(main_node, from_member_index, gang_members, player_data)
		)
		transfer_menu.add_child(member_btn)
		btn_y += 70

	# Кнопка отмены
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(540, 60)
	cancel_btn.position = Vector2(90, 950)
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.add_theme_font_size_override("font_size", 20)

	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)

	var style_cancel_hover = StyleBoxFlat.new()
	style_cancel_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	cancel_btn.add_theme_stylebox_override("hover", style_cancel_hover)

	cancel_btn.pressed.connect(func(): transfer_menu.queue_free())
	transfer_menu.add_child(cancel_btn)

# Передача предмета другому члену банды
func transfer_item(item_name: String, from_pocket: bool, pocket_index: int, from_data: Dictionary, to_data: Dictionary, main_node: Node):
	# Удаляем из инвентаря отправителя
	if from_pocket:
		from_data["pockets"][pocket_index] = null
	else:
		from_data["inventory"].erase(item_name)

	# Добавляем в инвентарь получателя
	if not to_data.has("inventory"):
		to_data["inventory"] = []
	to_data["inventory"].append(item_name)

	main_node.show_message("✅ Передано: " + item_name + " → " + to_data.get("name", "Боец"))
	main_node.update_ui()
