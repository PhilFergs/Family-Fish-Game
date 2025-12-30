class_name NpcFish
extends Area2D

@export var size_scale: float = 1.0
@export var speed: float = 120.0
@export var is_predator: bool = false
@export var awareness_range: float = 260.0
@export var predator_awareness_range: float = 120.0
@export var threat_tint: Color = Color(1, 0.6, 0.6, 1)
@export var normal_tint: Color = Color(1, 1, 1, 1)

const PREY_TEXTURE: Texture2D = preload("res://art/fish_prey.svg")
const PREDATOR_TEXTURE: Texture2D = preload("res://art/fish_predator.svg")

@onready var body: Sprite2D = $Body
@onready var hit_shape: CollisionShape2D = $HitShape

var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(2000, 1200))
var player_ref: PlayerFish
var wander_direction: Vector2 = Vector2.RIGHT
var wander_time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_apply_type()
	rng.randomize()
	_update_visuals()
	_pick_wander_direction()

func set_predator(value: bool) -> void:
	is_predator = value
	if is_inside_tree():
		_apply_type()

func _apply_type() -> void:
	add_to_group("npc_fish")
	remove_from_group("predator")
	remove_from_group("prey")
	if is_predator:
		add_to_group("predator")
		body.texture = PREDATOR_TEXTURE
	else:
		add_to_group("prey")
		body.texture = PREY_TEXTURE

func configure(new_bounds: Rect2, player: PlayerFish) -> void:
	bounds = new_bounds
	player_ref = player

func _process(delta: float) -> void:
	wander_time -= delta
	if wander_time <= 0.0:
		_pick_wander_direction()

	var direction: Vector2 = wander_direction
	if player_ref:
		var to_player: Vector2 = player_ref.position - position
		var distance: float = to_player.length()
		var threat_range := awareness_range
		if is_predator:
			threat_range = predator_awareness_range
		if distance < threat_range:
			if is_predator and player_ref.size_scale < size_scale:
				direction = to_player.normalized()
			elif not is_predator and player_ref.size_scale > size_scale:
				direction = (-to_player).normalized()

	if direction.x != 0.0:
		body.flip_h = direction.x < 0.0

	position += direction * speed * delta
	_keep_in_bounds()
	_update_threat_tint()

func _pick_wander_direction() -> void:
	wander_time = rng.randf_range(0.8, 2.2)
	var angle: float = rng.randf_range(0.0, TAU)
	wander_direction = Vector2(cos(angle), sin(angle)).normalized()

func _keep_in_bounds() -> void:
	var min_x: float = bounds.position.x
	var min_y: float = bounds.position.y
	var max_x: float = bounds.position.x + bounds.size.x
	var max_y: float = bounds.position.y + bounds.size.y
	var margin := 24.0

	if is_predator:
		if position.x < min_x - margin or position.x > max_x + margin or position.y < min_y - margin or position.y > max_y + margin:
			queue_free()
			return
		if position.x < min_x or position.x > max_x or position.y < min_y or position.y > max_y:
			return

	if position.x < min_x or position.x > max_x:
		position.x = clamp(position.x, min_x, max_x)
		wander_direction.x = -wander_direction.x
	if position.y < min_y or position.y > max_y:
		position.y = clamp(position.y, min_y, max_y)
		wander_direction.y = -wander_direction.y

func set_size_scale(new_scale: float) -> void:
	size_scale = new_scale
	_update_visuals()

func _update_visuals() -> void:
	body.scale = Vector2.ONE * size_scale
	var radius: float = 10.0 * size_scale
	var shape: CircleShape2D = hit_shape.shape
	if shape:
		shape.radius = radius

func _update_threat_tint() -> void:
	if not player_ref:
		body.modulate = normal_tint
		return
	if size_scale > player_ref.size_scale:
		body.modulate = threat_tint
	else:
		body.modulate = normal_tint
