extends Node2D

@export var tank_size: Vector2 = Vector2(2000, 1200)
@export var tier_bites: Array[int] = [5, 5, 5, 8, 8, 8, 10, 10, 10]
@export var size_growth_per_tier: float = 0.22
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
var last_announced_tier: int = 0

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

	if spawner is FishSpawner:
		var fish_spawner: FishSpawner = spawner
		fish_spawner.configure(bounds, player, fish_container)

	_update_tier_stats(true)
	_announce_tier(true)
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

	max_health = 3 + (tier - 1)
	if reset_health:
		health = max_health

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
