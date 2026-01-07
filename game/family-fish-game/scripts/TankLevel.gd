extends Node2D

@export var tank_size: Vector2 = Vector2(1536, 1024)
@export var tier_bites: Array[int] = [5, 5, 5, 8, 8, 8, 10, 10, 10]
@export var size_growth_per_tier: float = 0.22
@export var speed_scale_start: float = 0.4
@export var speed_scale_max_tier: int = 15
@export var default_base_speed: float = 220.0
@export var default_spawn_interval: float = 1.0
@export var win_tier: int = 10
@export var tier_objectives: Array[String] = [
	"Eat 5 small fish to grow.",
	"Eat 5 fish. Watch for poison fish.",
	"Predators appear. Eat 5 fish to grow.",
	"Eat 8 fish. Stay out of corners.",
	"Eat 8 fish. Schooling prey move together.",
	"Eat 8 fish. Poison fish deal damage.",
	"Eat 10 fish. Predators are faster now.",
	"Eat 10 fish. Keep moving.",
	"Eat 10 fish. You're almost there.",
	"Eat 10 fish to become the biggest fish."
]

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/MainMenu.tscn")
const WIN_SCREEN_SCENE: PackedScene = preload("res://scenes/WinScreen.tscn")
const SETTINGS_PATH: String = "user://settings.cfg"
const SETTINGS_SECTION: String = "settings"

@onready var background: BackgroundGrid = $Background
@onready var player: PlayerFish = $Player
@onready var fish_container: Node2D = $FishContainer
@onready var spawner: Node = $FishSpawner
@onready var hud: CanvasLayer = $HUD

var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1536, 1024))
var tier: int = 1
var bites: int = 0
var bites_needed: int = 5
var health: int = 3
var max_health: int = 3
var won: bool = false
var game_over: bool = false
var last_announced_tier: int = 0
var overlay_layer: CanvasLayer
var menu_overlay: Control
var win_overlay: Control
var paused: bool = false

func _ready() -> void:
	background.size = tank_size
	background.position = Vector2.ZERO
	bounds = background.get_tank_rect()
	player.position = bounds.position + bounds.size / 2.0
	player.set_bounds(bounds)
	player.ate_fish.connect(_on_player_ate_fish)
	player.took_hit.connect(_on_player_took_hit)
	player.poisoned.connect(_on_player_poisoned)
	if hud is HUD:
		(hud as HUD).restart_requested.connect(_on_restart_requested)
		(hud as HUD).main_menu_requested.connect(_on_main_menu_requested)
		(hud as HUD).pause_requested.connect(_on_pause_requested)
		(hud as HUD).resume_requested.connect(_on_resume_requested)
		(hud as HUD).settings_requested.connect(_on_settings_requested)
		(hud as HUD).volume_changed.connect(_on_volume_changed)
		(hud as HUD).base_speed_changed.connect(_on_base_speed_changed)
		(hud as HUD).spawn_rate_changed.connect(_on_spawn_rate_changed)
		(hud as HUD).settings_reset_requested.connect(_on_settings_reset_requested)

	if spawner is FishSpawner:
		var fish_spawner: FishSpawner = spawner
		fish_spawner.configure(bounds, player, fish_container)

	_update_tier_stats(true)
	_announce_tier(true)
	_update_hud()
	_setup_overlays()
	_load_settings()
	_apply_settings_defaults()
	_open_menu()

func _on_player_ate_fish(_fish_size: float) -> void:
	if won:
		return
	bites += 1
	if bites >= bites_needed:
		tier += 1
		bites = 0
		_update_tier_stats(true)
		if tier >= win_tier:
			_win()
		else:
			_announce_tier(false)
	_update_hud()

func _on_player_took_hit(damage: int) -> void:
	if won:
		return
	health = max(0, health - damage)
	if hud is HUD and damage > 0:
		(hud as HUD).show_message("Ouch! -" + str(damage) + " health", 1.4)
	_update_hud()
	if health <= 0:
		print("You got eaten")
		_game_over()

func _update_tier_stats(reset_health: bool) -> void:
	var tier_index: int = min(tier - 1, tier_bites.size() - 1)
	bites_needed = tier_bites[tier_index]

	var size_scale: float = 1.0 + (tier - 1) * size_growth_per_tier
	player.set_size_scale(size_scale)
	var speed_scale: float = _get_speed_scale()
	player.set_speed_scale(speed_scale)
	if spawner is FishSpawner:
		(spawner as FishSpawner).set_speed_scale(speed_scale)
	_update_fish_speed_scale(speed_scale)

	max_health = 3 + (tier - 1)
	if reset_health:
		health = max_health

func _get_speed_scale() -> float:
	var max_tier: int = max(speed_scale_max_tier, 2)
	var t: float = clamp(float(tier - 1) / float(max_tier - 1), 0.0, 1.0)
	return lerp(speed_scale_start, 1.0, t)

func _update_fish_speed_scale(scale: float) -> void:
	for child in fish_container.get_children():
		if child is NpcFish:
			(child as NpcFish).set_speed_scale(scale)

func _update_hud() -> void:
	if hud is HUD:
		(hud as HUD).update_status(tier, bites, bites_needed, health, max_health)

func _announce_tier(is_start: bool) -> void:
	if last_announced_tier == tier and not is_start:
		return
	last_announced_tier = tier
	var objective: String = _get_objective_text(tier)
	if hud is HUD:
		(hud as HUD).update_objective(objective)
		if is_start:
			(hud as HUD).show_message("Objective: " + objective, 2.2)
		else:
			(hud as HUD).show_message("Tier %d reached! Next: %s" % [tier, objective], 2.6)

func _get_objective_text(current_tier: int) -> String:
	var index: int = current_tier - 1
	if index >= 0 and index < tier_objectives.size():
		return tier_objectives[index]
	return "Eat %d fish to reach Tier %d." % [bites_needed, current_tier + 1]

func _on_player_poisoned(_duration: float) -> void:
	if hud is HUD:
		(hud as HUD).show_message("Poisoned! Health will tick down.", 2.0)

func _setup_overlays() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 5
	add_child(overlay_layer)
	menu_overlay = MAIN_MENU_SCENE.instantiate()
	win_overlay = WIN_SCREEN_SCENE.instantiate()
	overlay_layer.add_child(menu_overlay)
	overlay_layer.add_child(win_overlay)
	menu_overlay.visible = false
	win_overlay.visible = false
	if menu_overlay.has_signal("start_requested"):
		menu_overlay.start_requested.connect(_on_menu_start_requested)
	if menu_overlay.has_signal("quit_requested"):
		menu_overlay.quit_requested.connect(_on_menu_quit_requested)
	if win_overlay.has_signal("replay_requested"):
		win_overlay.replay_requested.connect(_on_win_replay_requested)
	if win_overlay.has_signal("menu_requested"):
		win_overlay.menu_requested.connect(_on_win_menu_requested)

func _open_menu() -> void:
	if menu_overlay:
		menu_overlay.visible = true
	if win_overlay:
		win_overlay.visible = false
	if hud:
		hud.visible = false
	if player:
		player.set_input_enabled(false)
	if spawner is FishSpawner:
		(spawner as FishSpawner).set_spawning(true)
	paused = false
	get_tree().paused = false

func _close_menu() -> void:
	if menu_overlay:
		menu_overlay.visible = false
	if win_overlay:
		win_overlay.visible = false
	if hud:
		hud.visible = true
	if player:
		player.set_input_enabled(true)
	if hud is HUD:
		(hud as HUD).hide_pause_menu()
	paused = false
	get_tree().paused = false

func _show_win_screen() -> void:
	if win_overlay:
		win_overlay.visible = true
	if menu_overlay:
		menu_overlay.visible = false
	if hud:
		hud.visible = false
	if player:
		player.set_input_enabled(false)
	if spawner is FishSpawner:
		(spawner as FishSpawner).set_spawning(false)
	paused = false
	get_tree().paused = false

func _reset_run() -> void:
	won = false
	game_over = false
	tier = 1
	bites = 0
	_update_tier_stats(true)
	last_announced_tier = 0
	if hud is HUD:
		(hud as HUD).hide_game_over()
	_clear_fish()
	if spawner is FishSpawner:
		(spawner as FishSpawner).set_spawning(true)
	player.reset_state(bounds, bounds.position + bounds.size / 2.0)
	_announce_tier(true)
	_update_hud()
	paused = false
	get_tree().paused = false

func _clear_fish() -> void:
	for child in fish_container.get_children():
		if child is NpcFish:
			child.queue_free()

func _on_menu_start_requested() -> void:
	_reset_run()
	_close_menu()

func _on_menu_quit_requested() -> void:
	get_tree().quit()

func _on_win_replay_requested() -> void:
	_reset_run()
	_close_menu()

func _on_win_menu_requested() -> void:
	_open_menu()

func _game_over() -> void:
	if game_over:
		return
	game_over = true
	if hud is HUD:
		(hud as HUD).show_game_over()
	if spawner is FishSpawner:
		(spawner as FishSpawner).set_spawning(false)
	player.set_input_enabled(false)
	paused = false
	get_tree().paused = false

func _on_restart_requested() -> void:
	_reset_run()
	_close_menu()

func _on_main_menu_requested() -> void:
	_open_menu()

func _win() -> void:
	won = true
	_show_win_screen()

func _on_pause_requested() -> void:
	if game_over or won or menu_overlay.visible:
		return
	paused = true
	get_tree().paused = true
	if hud is HUD:
		(hud as HUD).show_pause_menu()
	if player:
		player.set_input_enabled(false)

func _on_resume_requested() -> void:
	if not paused:
		return
	paused = false
	get_tree().paused = false
	if hud is HUD:
		(hud as HUD).hide_pause_menu()
	if player:
		player.set_input_enabled(true)

func _on_settings_requested() -> void:
	if hud is HUD:
		(hud as HUD).show_settings_menu()

func _apply_settings_defaults() -> void:
	if not (hud is HUD):
		return
	var volume := _get_master_volume_linear()
	var base_speed: float = player.base_speed if player else default_base_speed
	var spawn_interval: float = (spawner as FishSpawner).spawn_interval if spawner is FishSpawner else default_spawn_interval
	var spawn_rate: float = 1.0 / max(spawn_interval, 0.001)
	(hud as HUD).set_settings_values(volume, base_speed, spawn_rate)
	_save_settings()

func _on_volume_changed(value: float) -> void:
	_set_master_volume_linear(value)
	_save_settings()

func _on_base_speed_changed(value: float) -> void:
	if player:
		player.base_speed = value
	_save_settings()

func _on_spawn_rate_changed(value: float) -> void:
	if spawner is FishSpawner:
		var clamped: float = max(value, 0.1)
		(spawner as FishSpawner).set_spawn_interval(1.0 / clamped)
	_save_settings()

func _on_settings_reset_requested() -> void:
	_on_base_speed_changed(default_base_speed)
	var reset_spawn_rate: float = 1.0 / max(default_spawn_interval, 0.001)
	_on_spawn_rate_changed(reset_spawn_rate)
	if hud is HUD:
		var volume := _get_master_volume_linear()
		(hud as HUD).set_settings_values(volume, default_base_speed, reset_spawn_rate)
	_save_settings()

func _get_master_volume_linear() -> float:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return 1.0
	var db := AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(db)

func _set_master_volume_linear(value: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	if config.has_section_key(SETTINGS_SECTION, "volume"):
		_set_master_volume_linear(float(config.get_value(SETTINGS_SECTION, "volume")))
	if config.has_section_key(SETTINGS_SECTION, "base_speed"):
		_on_base_speed_changed(float(config.get_value(SETTINGS_SECTION, "base_speed")))
	if config.has_section_key(SETTINGS_SECTION, "spawn_rate"):
		_on_spawn_rate_changed(float(config.get_value(SETTINGS_SECTION, "spawn_rate")))

func _save_settings() -> void:
	var config := ConfigFile.new()
	var volume := _get_master_volume_linear()
	var base_speed: float = player.base_speed if player else default_base_speed
	var spawn_interval: float = (spawner as FishSpawner).spawn_interval if spawner is FishSpawner else default_spawn_interval
	var spawn_rate: float = 1.0 / max(spawn_interval, 0.001)
	config.set_value(SETTINGS_SECTION, "volume", volume)
	config.set_value(SETTINGS_SECTION, "base_speed", base_speed)
	config.set_value(SETTINGS_SECTION, "spawn_rate", spawn_rate)
	config.save(SETTINGS_PATH)
