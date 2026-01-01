class_name HUD
extends CanvasLayer

signal restart_requested
signal main_menu_requested
signal pause_requested
signal resume_requested
signal settings_requested
signal volume_changed(value: float)
signal base_speed_changed(value: float)
signal spawn_rate_changed(value: float)
signal settings_reset_requested

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
@onready var pause_panel: PanelContainer = $PausePanel
@onready var resume_button: Button = $PausePanel/Margin/Stack/ResumeButton
@onready var pause_restart_button: Button = $PausePanel/Margin/Stack/RestartButton
@onready var pause_menu_button: Button = $PausePanel/Margin/Stack/MenuButton
@onready var settings_button: Button = $PausePanel/Margin/Stack/SettingsButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_back_button: Button = $SettingsPanel/Margin/Stack/BackButton
@onready var settings_reset_button: Button = $SettingsPanel/Margin/Stack/ResetButton
@onready var volume_slider: HSlider = $SettingsPanel/Margin/Stack/VolumeRow/VolumeSlider
@onready var base_speed_slider: HSlider = $SettingsPanel/Margin/Stack/SpeedRow/SpeedSlider
@onready var spawn_rate_slider: HSlider = $SettingsPanel/Margin/Stack/SpawnRow/SpawnSlider

var message_token: int = 0
var _paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_restart_button.pressed.connect(_on_restart_pressed)
	pause_menu_button.pressed.connect(_on_menu_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	settings_reset_button.pressed.connect(_on_settings_reset_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	base_speed_slider.value_changed.connect(_on_base_speed_changed)
	spawn_rate_slider.value_changed.connect(_on_spawn_rate_changed)

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
	if restart_button:
		restart_button.grab_focus()

func hide_game_over() -> void:
	game_over_panel.visible = false

func show_pause_menu() -> void:
	_paused = true
	pause_panel.visible = true
	settings_panel.visible = false
	if resume_button:
		resume_button.grab_focus()

func hide_pause_menu() -> void:
	_paused = false
	pause_panel.visible = false
	settings_panel.visible = false

func show_settings_menu() -> void:
	settings_panel.visible = true
	pause_panel.visible = false
	if settings_back_button:
		settings_back_button.grab_focus()

func set_settings_values(volume: float, base_speed: float, spawn_rate: float) -> void:
	volume_slider.value = volume
	base_speed_slider.value = base_speed
	spawn_rate_slider.value = spawn_rate

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if game_over_panel.visible:
			return
		if _paused:
			emit_signal("resume_requested")
		else:
			emit_signal("pause_requested")
		get_viewport().set_input_as_handled()

func _on_restart_pressed() -> void:
	emit_signal("restart_requested")

func _on_menu_pressed() -> void:
	emit_signal("main_menu_requested")

func _on_resume_pressed() -> void:
	emit_signal("resume_requested")

func _on_settings_pressed() -> void:
	emit_signal("settings_requested")

func _on_settings_back_pressed() -> void:
	show_pause_menu()

func _on_volume_changed(value: float) -> void:
	emit_signal("volume_changed", value)

func _on_base_speed_changed(value: float) -> void:
	emit_signal("base_speed_changed", value)

func _on_spawn_rate_changed(value: float) -> void:
	emit_signal("spawn_rate_changed", value)

func _on_settings_reset_pressed() -> void:
	emit_signal("settings_reset_requested")
