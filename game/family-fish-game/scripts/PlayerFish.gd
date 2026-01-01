class_name PlayerFish
extends Area2D

signal ate_fish(fish_size: float)
signal took_hit(damage: int)
signal poisoned(duration: float)

@export var base_speed: float = 220.0
@export var size_scale: float = 1.5
@export var speed_scale: float = 1.0
@export var bite_radius: float = 14.0
@export var base_sprite_size: float = 24.0
@export var camera_zoom: float = 1.15
@export var invuln_seconds: float = 1.0
@export var poison_duration: float = 3.0
@export var poison_tick_interval: float = 1.4
@export var poison_tick_damage: int = 1

@onready var body: Sprite2D = $Body
@onready var hit_shape: CollisionShape2D = $HitShape
@onready var invuln_timer: Timer = $InvulnTimer
@onready var camera: Camera2D = $Camera2D

var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(2000, 1200))
var invulnerable: bool = false
var poison_time_left: float = 0.0
var poison_tick_time: float = 0.0
var shake_time: float = 0.0
var shake_strength: float = 0.0
var shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var input_enabled: bool = true
var default_size_scale: float = 1.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	invuln_timer.timeout.connect(_on_invuln_timer_timeout)
	shake_rng.randomize()
	default_size_scale = size_scale
	_apply_camera_zoom()
	_update_visuals()

func set_bounds(new_bounds: Rect2) -> void:
	bounds = new_bounds
	_set_camera_limits()

func set_size_scale(new_scale: float) -> void:
	size_scale = new_scale
	_update_visuals()

func set_speed_scale(new_scale: float) -> void:
	speed_scale = max(new_scale, 0.1)

func _process(delta: float) -> void:
	if not input_enabled:
		_update_camera_shake(delta)
		return
	var direction: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
	if direction.x != 0.0:
		body.flip_h = direction.x < 0.0

	var velocity: Vector2 = direction * base_speed * size_scale * speed_scale
	position += velocity * delta
	var radius: float = _get_collision_radius()
	position.x = clamp(position.x, bounds.position.x + radius, bounds.position.x + bounds.size.x - radius)
	position.y = clamp(position.y, bounds.position.y + radius, bounds.position.y + bounds.size.y - radius)
	_resolve_blocking()
	_update_poison(delta)
	_update_camera_shake(delta)

func _on_area_entered(area: Area2D) -> void:
	if not (area is NpcFish):
		return

	var npc: NpcFish = area
	if npc.size_scale <= size_scale:
		emit_signal("ate_fish", npc.size_scale)
		if npc.is_poisonous:
			_apply_poison()
		_start_shake(2.5, 0.08)
		npc.queue_free()
	else:
		if invulnerable:
			return
		invulnerable = true
		emit_signal("took_hit", 1)
		if npc.is_poisonous:
			_apply_poison()
		_start_shake(6.0, 0.2)
		_start_invuln()

func _start_invuln() -> void:
	modulate = Color(1, 1, 1, 0.5)
	invuln_timer.start(invuln_seconds)

func _on_invuln_timer_timeout() -> void:
	invulnerable = false
	modulate = Color(1, 1, 1, 1)

func _update_visuals() -> void:
	var texture_scale := _get_texture_scale()
	body.scale = Vector2.ONE * size_scale * texture_scale
	var shape: Shape2D = hit_shape.shape
	if shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		var sprite_size := _get_sprite_size() * size_scale * texture_scale
		rect_shape.size = sprite_size
	elif shape is CircleShape2D:
		var circle_shape := shape as CircleShape2D
		circle_shape.radius = _get_collision_radius()

func _get_texture_scale() -> float:
	if not body or not body.texture:
		return 1.0
	var size: Vector2 = body.texture.get_size()
	var max_dim: float = max(size.x, size.y)
	if max_dim <= 0.0:
		return 1.0
	return base_sprite_size / max_dim

func _get_sprite_size() -> Vector2:
	if not body or not body.texture:
		return Vector2.ONE * base_sprite_size
	return body.texture.get_size()

func _get_collision_radius() -> float:
	var texture_scale := _get_texture_scale()
	var sprite_size := _get_sprite_size() * size_scale * texture_scale
	return max(sprite_size.x, sprite_size.y) * 0.5

func _resolve_blocking() -> void:
	var areas := get_overlapping_areas()
	if areas.is_empty():
		return
	var player_radius: float = bite_radius * size_scale
	for area in areas:
		if not (area is NpcFish):
			continue
		var npc: NpcFish = area
		if npc.size_scale <= size_scale:
			continue
		var npc_radius: float = 10.0 * npc.size_scale
		var offset: Vector2 = position - npc.position
		var distance: float = offset.length()
		if distance == 0.0:
			offset = Vector2.RIGHT
			distance = 0.001
		var min_dist: float = player_radius + npc_radius
		if distance < min_dist:
			position += offset.normalized() * (min_dist - distance)

func _apply_poison(duration: float = -1.0) -> void:
	var applied_duration: float = duration
	if applied_duration <= 0.0:
		applied_duration = poison_duration
	var was_poisoned: bool = poison_time_left > 0.0
	poison_time_left = max(poison_time_left, applied_duration)
	if poison_time_left == applied_duration:
		poison_tick_time = 0.0
	if not was_poisoned:
		emit_signal("poisoned", poison_time_left)

func _update_poison(delta: float) -> void:
	if poison_time_left <= 0.0:
		return
	poison_time_left = max(poison_time_left - delta, 0.0)
	poison_tick_time += delta
	while poison_tick_time >= poison_tick_interval:
		poison_tick_time -= poison_tick_interval
		emit_signal("took_hit", poison_tick_damage)

func _set_camera_limits() -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.position.x + bounds.size.x)
	camera.limit_bottom = int(bounds.position.y + bounds.size.y)
	_apply_camera_zoom()

func _start_shake(strength: float, duration: float) -> void:
	shake_strength = max(shake_strength, strength)
	shake_time = max(shake_time, duration)

func _update_camera_shake(delta: float) -> void:
	if shake_time <= 0.0:
		camera.offset = Vector2.ZERO
		return
	shake_time = max(shake_time - delta, 0.0)
	var offset := Vector2(
		shake_rng.randf_range(-shake_strength, shake_strength),
		shake_rng.randf_range(-shake_strength, shake_strength)
	)
	camera.offset = offset

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)
	if hit_shape:
		hit_shape.disabled = not enabled
	if not enabled:
		invuln_timer.stop()
		invulnerable = false
		modulate = Color(1, 1, 1, 1)

func reset_state(new_bounds: Rect2, start_pos: Vector2) -> void:
	set_bounds(new_bounds)
	position = start_pos
	invulnerable = false
	poison_time_left = 0.0
	poison_tick_time = 0.0
	shake_time = 0.0
	shake_strength = 0.0
	camera.offset = Vector2.ZERO
	modulate = Color(1, 1, 1, 1)
	set_size_scale(default_size_scale)
	set_input_enabled(true)

func _apply_camera_zoom() -> void:
	if not camera:
		return
	var zoom_value: float = max(camera_zoom, 0.2)
	camera.zoom = Vector2.ONE * zoom_value
