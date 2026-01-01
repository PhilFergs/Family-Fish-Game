extends Control

signal replay_requested
signal menu_requested

@onready var replay_button: Button = $Panel/VBox/ReplayButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	replay_button.pressed.connect(_on_replay_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_replay_pressed() -> void:
	emit_signal("replay_requested")

func _on_menu_pressed() -> void:
	emit_signal("menu_requested")
