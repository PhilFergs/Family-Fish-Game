extends Node2D

@export var tank_size: Vector2 = Vector2(2000, 1200)
@export var tier_bites: Array[int] = [5, 5, 5, 8, 8, 8, 10, 10, 10]
@export var size_growth_per_tier: float = 0.22
@export var win_tier: int = 10

@onready var background: BackgroundGrid = $Background
@onready var player: PlayerFish = $Player
@onready var fish_container: Node2D = $FishContainer
@onready var spawner: Node = $FishSpawner
@onready var hud: CanvasLayer = $HUD

var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(2000, 1200))
var tier: int = 1
var bites: int = 0
var bites_needed: int = 5
var health: int = 3
var max_health: int = 3
var won: bool = false
var game_over: bool = false

func _ready() -> void:
	background.size = tank_size
	background.position = Vector2.ZERO
	bounds = background.get_tank_rect()
	player.position = bounds.position + bounds.size / 2.0
	player.set_bounds(bounds)
	player.ate_fish.connect(_on_player_ate_fish)
	player.took_hit.connect(_on_player_took_hit)
	if hud is HUD:
		(hud as HUD).restart_requested.connect(_on_restart_requested)
		(hud as HUD).main_menu_requested.connect(_on_main_menu_requested)

	if spawner is FishSpawner:
		var fish_spawner: FishSpawner = spawner
		fish_spawner.configure(bounds, player, fish_container)

	_update_tier_stats(true)
	_update_hud()

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
	_update_hud()

func _on_player_took_hit(damage: int) -> void:
	if won:
		return
	health = max(0, health - damage)
	_update_hud()
	if health <= 0:
		print("You got eaten")
		_game_over()

func _update_tier_stats(reset_health: bool) -> void:
	var tier_index: int = min(tier - 1, tier_bites.size() - 1)
	bites_needed = tier_bites[tier_index]

	var size_scale: float = 1.0 + (tier - 1) * size_growth_per_tier
	player.set_size_scale(size_scale)

	max_health = 3 + (tier - 1)
	if reset_health:
		health = max_health

func _update_hud() -> void:
	if hud is HUD:
		(hud as HUD).update_status(tier, bites, bites_needed, health, max_health)

func _game_over() -> void:
	if game_over:
		return
	game_over = true
	if hud is HUD:
		(hud as HUD).show_game_over()
	get_tree().paused = true

func _on_restart_requested() -> void:
	if not game_over:
		return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/TankLevel.tscn")

func _on_main_menu_requested() -> void:
	if not game_over:
		return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _win() -> void:
	won = true
	if spawner is FishSpawner:
		(spawner as FishSpawner).queue_free()
	get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
