extends Control

@onready var replay_button: Button = $Panel/VBox/ReplayButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	replay_button.pressed.connect(_on_replay_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_replay_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TankLevel.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
