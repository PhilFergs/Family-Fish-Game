class_name PlayerFish
extends Area2D

signal ate_fish(fish_size: float)
signal took_hit(damage: int)

@export var base_speed: float = 220.0
@export var size_scale: float = 1.0
@export var bite_radius: float = 14.0
@export var invuln_seconds: float = 1.0

@onready var body: Sprite2D = $Body
@onready var hit_shape: CollisionShape2D = $HitShape
@onready var invuln_timer: Timer = $InvulnTimer
@onready var camera: Camera2D = $Camera2D

var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(2000, 1200))
var invulnerable: bool = false

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

func _on_area_entered(area: Area2D) -> void:
	if not (area is NpcFish):
		return

	var npc: NpcFish = area
	if npc.size_scale <= size_scale:
		emit_signal("ate_fish", npc.size_scale)
		npc.queue_free()
	else:
		if invulnerable:
			return
		invulnerable = true
		emit_signal("took_hit", 1)
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

func _set_camera_limits() -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.position.x + bounds.size.x)
	camera.limit_bottom = int(bounds.position.y + bounds.size.y)
