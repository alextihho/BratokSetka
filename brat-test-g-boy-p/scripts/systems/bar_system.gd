# bar_system.gd - ТЕСТОВАЯ МИНИМАЛЬНАЯ ВЕРСИЯ ДЛЯ ОТЛАДКИ
extends Node

signal rest_completed()
signal party_completed()

func _ready():
	print("=" * 60)
	print("🍺🍺🍺 БАР СИСТЕМА ЗАГРУЖЕНА! 🍺🍺🍺")
	print("=" * 60)

func show_bar_menu(main_node: Node, player_data: Dictionary, gang_members: Array):
	print("✅ BarSystem.show_bar_menu() вызван!")
	main_node.show_message("🍺 ТЕСТ: Барная система работает!")
