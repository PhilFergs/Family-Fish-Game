class_name NpcFish
extends Area2D

@export var size_scale: float = 1.5
@export var speed: float = 120.0
@export var is_predator: bool = false
@export var is_poisonous: bool = false
@export var awareness_range: float = 150.0
@export var predator_awareness_range: float = 150.0
@export var turn_speed: float = 2.5
@export var drift_strength: float = 0.35
@export var drift_speed: float = 0.9
@export var prey_palette: Array[Color] = [
	Color(0.93, 0.83, 0.36, 1),
	Color(0.41, 0.78, 0.98, 1),
	Color(0.56, 0.9, 0.58, 1)
]
@export var predator_palette: Array[Color] = [
	Color(0.96, 0.42, 0.39, 1),
	Color(0.89, 0.55, 0.22, 1),
	Color(0.31, 0.79, 0.69, 1)
]
@export var poison_palette: Array[Color] = [
	Color(0.9, 0.82, 0.2, 1),
	Color(0.62, 0.9, 0.2, 1),
	Color(0.98, 0.62, 0.2, 1)
]
@export var base_brightness: float = 1.12
@export var shade_variance: float = 0.06
@export var threat_glow_color: Color = Color(1, 0.2, 0.2, 1)
@export var threat_glow_alpha: float = 0.32
@export var threat_glow_scale: float = 1.5
@export var poison_glow_color: Color = Color(0.18, 0.55, 0.2, 1)
@export var poison_glow_alpha: float = 0.35
@export var poison_glow_scale: float = 1.9

const PREY_TEXTURE: Texture2D = preload("res://art/fish_prey.svg")
const PREDATOR_TEXTURE: Texture2D = preload("res://art/fish_predator.svg")

@onready var body: Sprite2D = $Body
@onready var threat_glow: Sprite2D = $ThreatGlow
@onready var hit_shape: CollisionShape2D = $HitShape

var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(2000, 1200))
var player_ref: PlayerFish
var wander_direction: Vector2 = Vector2.RIGHT
var wander_time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var noise: FastNoiseLite = FastNoiseLite.new()
var noise_time: float = 0.0
var current_direction: Vector2 = Vector2.RIGHT
var base_tint: Color = Color(1, 1, 1, 1)
var shade_offset: float = 0.0
var glow_material: CanvasItemMaterial
static var glow_texture: Texture2D

func _ready() -> void:
	rng.randomize()
	noise.seed = rng.randi()
	noise.frequency = 0.15
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_apply_type()
	if glow_texture == null:
		glow_texture = _create_glow_texture()
	glow_material = CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	threat_glow.material = glow_material
	threat_glow.texture = glow_texture
	threat_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_update_visuals()
	_update_threat_tint()
	_pick_wander_direction()
	current_direction = wander_direction

func set_predator(value: bool) -> void:
	is_predator = value
	if is_inside_tree():
		_apply_type()

func set_poisonous(value: bool) -> void:
	is_poisonous = value
	if is_inside_tree():
		_apply_type()

func _apply_type() -> void:
	add_to_group("npc_fish")
	remove_from_group("poison")
	remove_from_group("predator")
	remove_from_group("prey")
	if is_predator:
		add_to_group("predator")
		body.texture = PREDATOR_TEXTURE
	else:
		add_to_group("prey")
		body.texture = PREY_TEXTURE
	if is_poisonous:
		add_to_group("poison")
	_assign_style()

func configure(new_bounds: Rect2, player: PlayerFish) -> void:
	bounds = new_bounds
	player_ref = player

func _process(delta: float) -> void:
	wander_time -= delta
	if wander_time <= 0.0:
		_pick_wander_direction()

	noise_time += delta * drift_speed
	var drift_angle: float = noise.get_noise_1d(noise_time) * PI
	var drift: Vector2 = Vector2(cos(drift_angle), sin(drift_angle)) * drift_strength

	var desired_direction: Vector2 = wander_direction + drift
	if player_ref:
		var to_player: Vector2 = player_ref.position - position
		var distance: float = to_player.length()
		var threat_range := awareness_range
		if is_predator:
			threat_range = predator_awareness_range
		if distance < threat_range:
			if is_predator and player_ref.size_scale < size_scale:
				desired_direction = to_player.normalized()
			elif not is_predator and player_ref.size_scale > size_scale:
				desired_direction = (-to_player).normalized()

	if desired_direction.length_squared() < 0.001:
		desired_direction = wander_direction
	desired_direction = desired_direction.normalized()
	current_direction = current_direction.lerp(desired_direction, clamp(turn_speed * delta, 0.0, 1.0)).normalized()

	if current_direction.x != 0.0:
		body.flip_h = current_direction.x < 0.0

	position += current_direction * speed * delta
	_keep_in_bounds()
	_update_threat_tint()

func _pick_wander_direction() -> void:
	wander_time = rng.randf_range(0.8, 2.2)
	var x: float = rng.randf_range(-1.0, 1.0)
	var y: float = rng.randf_range(-0.55, 0.55)
	wander_direction = Vector2(x, y).normalized()

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
	var glow_scale: float = threat_glow_scale
	if is_poisonous:
		glow_scale = poison_glow_scale
	threat_glow.scale = Vector2.ONE * size_scale * glow_scale
	var radius: float = 10.0 * size_scale
	var shape: CircleShape2D = hit_shape.shape
	if shape:
		shape.radius = radius

func _update_threat_tint() -> void:
	if not player_ref:
		body.modulate = base_tint
		threat_glow.visible = false
		return
	var brightness: float = base_brightness
	var show_threat: bool = false
	if size_scale > player_ref.size_scale:
		show_threat = true
	if is_poisonous:
		show_threat = true
	brightness = clamp(brightness + shade_offset, 0.8, 1.4)
	body.modulate = base_tint * brightness
	threat_glow.visible = show_threat
	if is_poisonous:
		threat_glow.modulate = Color(poison_glow_color.r, poison_glow_color.g, poison_glow_color.b, poison_glow_alpha)
	else:
		threat_glow.modulate = Color(threat_glow_color.r, threat_glow_color.g, threat_glow_color.b, threat_glow_alpha)

func _create_glow_texture() -> Texture2D:
	var size_px: int = 64
	var image: Image = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size_px * 0.5, size_px * 0.5)
	var max_dist: float = size_px * 0.5
	for y in range(size_px):
		for x in range(size_px):
			var dist: float = Vector2(x, y).distance_to(center)
			var t: float = clamp(1.0 - dist / max_dist, 0.0, 1.0)
			var alpha: float = pow(t, 2.4)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)

func _assign_style() -> void:
	var palette: Array[Color] = prey_palette
	if is_predator:
		palette = predator_palette
	if is_poisonous and not poison_palette.is_empty():
		palette = poison_palette
	if palette.is_empty():
		base_tint = Color(1, 1, 1, 1)
	else:
		base_tint = palette[rng.randi_range(0, palette.size() - 1)]
	shade_offset = rng.randf_range(-shade_variance, shade_variance)
