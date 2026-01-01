class_name PlayerFish
extends Area2D

signal ate_fish(fish_size: float)
signal took_hit(damage: int)

@export var base_speed: float = 220.0
@export var size_scale: float = 1.5
@export var bite_radius: float = 14.0
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

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	invuln_timer.timeout.connect(_on_invuln_timer_timeout)
	_update_visuals()

func set_bounds(new_bounds: Rect2) -> void:
	bounds = new_bounds
	_set_camera_limits()

func set_size_scale(new_scale: float) -> void:
	size_scale = new_scale
	_update_visuals()

func _process(delta: float) -> void:
	var direction: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
	if direction.x != 0.0:
		body.flip_h = direction.x < 0.0

	var velocity: Vector2 = direction * base_speed * size_scale
	position += velocity * delta
	position.x = clamp(position.x, bounds.position.x, bounds.position.x + bounds.size.x)
	position.y = clamp(position.y, bounds.position.y, bounds.position.y + bounds.size.y)
	_resolve_blocking()
	_update_poison(delta)

func _on_area_entered(area: Area2D) -> void:
	if not (area is NpcFish):
		return

	var npc: NpcFish = area
	if npc.size_scale <= size_scale:
		emit_signal("ate_fish", npc.size_scale)
		if npc.is_poisonous:
			_apply_poison()
		npc.queue_free()
	else:
		if invulnerable:
			return
		invulnerable = true
		emit_signal("took_hit", 1)
		if npc.is_poisonous:
			_apply_poison()
		_start_invuln()

func _start_invuln() -> void:
	modulate = Color(1, 1, 1, 0.5)
	invuln_timer.start(invuln_seconds)

func _on_invuln_timer_timeout() -> void:
	invulnerable = false
	modulate = Color(1, 1, 1, 1)

func _update_visuals() -> void:
	body.scale = Vector2.ONE * size_scale
	var radius: float = bite_radius * size_scale
	var shape: CircleShape2D = hit_shape.shape
	if shape:
		shape.radius = radius

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
	poison_time_left = max(poison_time_left, applied_duration)
	if poison_time_left == applied_duration:
		poison_tick_time = 0.0

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
