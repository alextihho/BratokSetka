# bar_system.gd - ТЕСТОВАЯ МИНИМАЛЬНАЯ ВЕРСИЯ
extends Node

func _ready():
	print("🍺🍺🍺 БАРНАЯ СИСТЕМА ЗАГРУЖЕНА УСПЕШНО! 🍺🍺🍺")

func show_bar_menu(main_node: Node, player_data: Dictionary, gang_members: Array):
	print("✅ show_bar_menu вызвана!")
	main_node.show_message("🍺 Тест: Бар работает!")
