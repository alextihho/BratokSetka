# location_menu_handler.gd - Обработчик меню локаций
extends Node

var main_node = null
var current_location = null
var menu_open = false

func setup(p_main_node):
	main_node = p_main_node

func show_location_menu(location_name: String):
	current_location = location_name
	menu_open = true
	print("🏢 Открываем меню: " + location_name)

	if main_node and main_node.has_method("add_to_log"):
		main_node.add_to_log("📍 Зашли в: " + location_name)

	var old_menu = main_node.get_node_or_null("BuildingMenu")
	if old_menu:
		old_menu.queue_free()
		await main_node.get_tree().process_frame

	var building_menu_script = load("res://scripts/ui/building_menu.gd")
	var building_menu = building_menu_script.new()
	building_menu.name = "BuildingMenu"
	main_node.add_child(building_menu)

	var actions = main_node.locations[location_name]["actions"]
	building_menu.setup(location_name, actions)

	building_menu.action_selected.connect(func(action_index):
		handle_location_action(action_index)
	)

	building_menu.menu_closed.connect(func():
		close_location_menu()
	)

func handle_location_action(action_index: int):
	if current_location == null:
		return

	print("🎯 Действие %d в локации %s" % [action_index, current_location])

	# ✅ ОБРАБОТКА АВТОСАЛОНА
	if current_location == "АВТОСАЛОН":
		if main_node.car_system:
			print("✅ Передаём управление CarSystem")
			close_location_menu()
			main_node.car_system.show_car_dealership_menu(main_node, main_node.player_data)
		else:
			print("❌ CarSystem не загружен!")
			if main_node.has_method("show_message"):
				main_node.show_message("❌ Автосалон недоступен")
		return

	# ✅ ОБРАБОТКА БАРА
	if current_location == "БАР":
		if action_index == 0 or action_index == 1:  # Отдохнуть или Бухать
			if main_node.bar_system:
				print("✅ Передаём управление BarSystem")
				close_location_menu()
				main_node.bar_system.show_bar_menu(main_node, main_node.player_data, main_node.gang_members)
			else:
				print("❌ BarSystem не загружен!")
				if main_node.has_method("show_message"):
					main_node.show_message("❌ Бар недоступен")
		elif action_index == 2:  # Уйти
			close_location_menu()
		return

	# ✅ ОБРАБОТКА ОСТАЛЬНЫХ ЛОКАЦИЙ через action_handler
	if main_node.action_handler:
		main_node.action_handler.handle_location_action(current_location, action_index, main_node)
	else:
		print("❌ ActionHandler не создан!")

	# ✅ Время на действие
	if main_node.time_system:
		var time_cost = randi_range(5, 15)
		main_node.time_system.add_minutes(time_cost)

func close_location_menu():
	var layer = main_node.get_node_or_null("BuildingMenu")
	if layer:
		layer.queue_free()
	menu_open = false
	current_location = null
	print("✅ Меню локации закрыто")

func on_location_clicked(location_name: String):
	show_location_menu(location_name)
	if main_node.action_handler:
		main_node.action_handler.trigger_location_events(location_name, main_node)
