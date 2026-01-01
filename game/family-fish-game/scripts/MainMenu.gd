extends Control

signal start_requested
signal quit_requested

@onready var start_button: Button = $Panel/VBox/StartButton
@onready var quit_button: Button = $Panel/VBox/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	emit_signal("start_requested")

func _on_quit_pressed() -> void:
	emit_signal("quit_requested")
