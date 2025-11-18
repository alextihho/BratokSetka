# car_system.gd - ТЕСТОВАЯ МИНИМАЛЬНАЯ ВЕРСИЯ ДЛЯ ОТЛАДКИ
extends Node

signal car_purchased(car_name: String)
signal car_repaired()
signal driver_changed(member_index: int)

func _ready():
	print("=" * 60)
	print("🚗🚗🚗 АВТОСАЛОН СИСТЕМА ЗАГРУЖЕНА! 🚗🚗🚗")
	print("=" * 60)

func show_car_dealership_menu(main_node: Node, player_data: Dictionary):
	print("✅ CarSystem.show_car_dealership_menu() вызван!")
	main_node.show_message("🚗 ТЕСТ: Автосалон система работает!")
