class_name FishSpawner
extends Node

@export var prey_scene: PackedScene
@export var predator_scene: PackedScene
@export var max_prey: int = 12
@export var max_predators: int = 4
@export var spawn_interval: float = 1.0
@export var poison_prey_chance: float = 0.15

@onready var spawn_timer: Timer = $SpawnTimer

var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(2000, 1200))
var player_ref: PlayerFish
var container: Node
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func configure(new_bounds: Rect2, player: PlayerFish, fish_container: Node) -> void:
	bounds = new_bounds
	player_ref = player
	container = fish_container

func _on_spawn_timer_timeout() -> void:
	if not container or not player_ref:
		return

	var prey_count: int = _count_group("prey")
	var predator_count: int = _count_group("predator")

	_cull_predators(predator_count)

	if prey_count < max_prey and predator_count < max_predators:
		if rng.randf() < 0.8:
			_spawn_prey()
		else:
			_spawn_predator()
	elif prey_count < max_prey:
		_spawn_prey()
	elif predator_count < max_predators:
		_spawn_predator()

func _cull_predators(predator_count: int) -> void:
	if predator_count <= max_predators:
		return
	for child in container.get_children():
		if predator_count <= max_predators:
			break
		if child is NpcFish and child.is_in_group("predator"):
			var npc: NpcFish = child
			if player_ref and npc.position.distance_to(player_ref.position) > 650.0:
				npc.queue_free()
				predator_count -= 1

func _count_group(group_name: String) -> int:
	var count: int = 0
	for child in container.get_children():
		if child.is_in_group(group_name):
			count += 1
	return count

func _spawn_prey() -> void:
	if not prey_scene:
		return
	var fish: NpcFish = prey_scene.instantiate()
	fish.set_predator(false)
	if rng.randf() < poison_prey_chance:
		fish.set_poisonous(true)
	_assign_prey_behavior(fish)
	container.add_child(fish)
	fish.configure(bounds, player_ref)
	var target_scale: float = rng.randf_range(0.65, 1.25) * player_ref.size_scale
	fish.set_size_scale(target_scale)
	var prey_speed_scale: float = clamp(fish.size_scale / max(player_ref.size_scale, 0.01), 0.4, 1.0)
	fish.speed = rng.randf_range(90.0, 140.0) * player_ref.size_scale * prey_speed_scale
	var min_distance: float = 140.0
	if target_scale > player_ref.size_scale:
		min_distance = 220.0
	fish.position = _random_point(min_distance)

func _spawn_predator() -> void:
	if not predator_scene:
		return
	var fish: NpcFish = predator_scene.instantiate()
	fish.set_predator(true)
	_assign_predator_behavior(fish)
	container.add_child(fish)
	fish.configure(bounds, player_ref)
	var base_speed: float = player_ref.base_speed * 0.75 * player_ref.size_scale
	fish.speed = rng.randf_range(base_speed * 0.85, base_speed * 1.05)
	var target_scale: float = rng.randf_range(0.85, 1.6) * player_ref.size_scale
	fish.set_size_scale(target_scale)
	var min_distance: float = 140.0
	if target_scale > player_ref.size_scale:
		min_distance = 240.0
	fish.position = _random_point(min_distance)

func _random_point(min_distance: float = 140.0) -> Vector2:
	var point: Vector2 = Vector2.ZERO
	for _i in range(4):
		point = Vector2(
			rng.randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			rng.randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
		if player_ref and player_ref.position.distance_to(point) > min_distance:
			return point
	return point

func _assign_prey_behavior(fish: NpcFish) -> void:
	var roll: float = rng.randf()
	if roll < 0.5:
		fish.set_behavior(NpcFish.Behavior.SCHOOL)
	elif roll < 0.85:
		fish.set_behavior(NpcFish.Behavior.SKITTISH)
	else:
		fish.set_behavior(NpcFish.Behavior.WANDER)

func _assign_predator_behavior(fish: NpcFish) -> void:
	if rng.randf() < 0.55:
		fish.set_behavior(NpcFish.Behavior.AMBUSH)
	else:
		fish.set_behavior(NpcFish.Behavior.WANDER)
