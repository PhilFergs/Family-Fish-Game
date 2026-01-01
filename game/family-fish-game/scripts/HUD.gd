class_name HUD
extends CanvasLayer

signal restart_requested
signal main_menu_requested

@onready var tier_label: Label = $TopCenter/Panel/Margin/Stack/TierLabel
@onready var objective_label: Label = $TopCenter/Panel/Margin/Stack/ObjectiveLabel
@onready var bites_bar: ProgressBar = $TopCenter/Panel/Margin/Stack/FishRow/FishBar
@onready var bites_value: Label = $TopCenter/Panel/Margin/Stack/FishRow/FishValue
@onready var health_bar: ProgressBar = $TopCenter/Panel/Margin/Stack/HealthRow/HealthBar
@onready var health_value: Label = $TopCenter/Panel/Margin/Stack/HealthRow/HealthValue
@onready var message_label: Label = $MessageLabel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/Margin/Stack/RestartButton
@onready var menu_button: Button = $GameOverPanel/Margin/Stack/MenuButton

var message_token: int = 0

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func update_status(tier: int, bites: int, bites_needed: int, health: int, max_health: int) -> void:
	tier_label.text = "TIER %d" % tier
	bites_bar.max_value = max(1, bites_needed)
	bites_bar.value = clamp(bites, 0, bites_needed)
	bites_value.text = "%d/%d" % [bites, bites_needed]
	health_bar.max_value = max(1, max_health)
	health_bar.value = clamp(health, 0, max_health)
	health_value.text = "%d/%d" % [health, max_health]

func update_objective(text: String) -> void:
	objective_label.text = text

func show_message(message: String, seconds: float = 2.0) -> void:
	message_token += 1
	var token := message_token
	message_label.text = message
	message_label.visible = message != ""
	if seconds <= 0.0 or message == "":
		return
	await get_tree().create_timer(seconds).timeout
	if token == message_token:
		message_label.visible = false

func show_game_over() -> void:
	game_over_panel.visible = true
	game_over_panel.grab_focus()

func hide_game_over() -> void:
	game_over_panel.visible = false

func _on_restart_pressed() -> void:
	emit_signal("restart_requested")

func _on_menu_pressed() -> void:
	emit_signal("main_menu_requested")
