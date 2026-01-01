class_name BackgroundGrid
extends ColorRect

@export var top_color: Color = Color(0.06, 0.25, 0.4, 1)
@export var mid_color: Color = Color(0.05, 0.2, 0.3, 1)
@export var bottom_color: Color = Color(0.02, 0.12, 0.18, 1)
@export var gradient_step: float = 6.0
@export var wave_color: Color = Color(0.18, 0.45, 0.6, 0.18)
@export var wave_spacing: float = 120.0
@export var wave_thickness: float = 2.0
@export var bubble_color: Color = Color(0.75, 0.9, 1.0, 0.35)
@export var bubble_count: int = 50
@export var bubble_min_radius: float = 2.0
@export var bubble_max_radius: float = 7.0
@export var bubble_seed: int = 1337
@export var gravel_color_a: Color = Color(0.2, 0.3, 0.32, 0.6)
@export var gravel_color_b: Color = Color(0.1, 0.2, 0.22, 0.6)
@export var gravel_height: float = 40.0
@export var border_color: Color = Color(0.7, 0.9, 1.0, 0.6)
@export var border_width: float = 3.0
@export var glass_highlight_color: Color = Color(0.9, 0.98, 1.0, 0.12)
@export var glass_highlight_width: float = 10.0
@export var outside_color: Color = Color(0.06, 0.08, 0.1, 1)
@export var outside_margin: float = 60.0
@export var table_color: Color = Color(0.35, 0.23, 0.16, 1)
@export var table_height: float = 80.0
@export var water_alpha: float = 0.5
@export var kitchen_texture: Texture2D = preload("res://art/kitchen_mockup.svg")
@export var tank_width_ratio: float = 0.62
@export var tank_height_ratio: float = 0.78
@export var tank_top_margin: float = 40.0
@export var tank_bottom_inset: float = 6.0
@export var wall_color: Color = Color(0.96, 0.77, 0.52, 1)
@export var wall_shadow: Color = Color(0.9, 0.7, 0.46, 1)
@export var baseboard_color: Color = Color(0.78, 0.58, 0.38, 1)
@export var cabinet_color: Color = Color(0.97, 0.86, 0.66, 1)
@export var cabinet_shadow: Color = Color(0.9, 0.78, 0.6, 1)
@export var cabinet_knob_color: Color = Color(0.85, 0.7, 0.45, 1)
@export var backsplash_color: Color = Color(0.99, 0.9, 0.74, 1)
@export var counter_color: Color = Color(0.7, 0.45, 0.25, 1)
@export var counter_top_color: Color = Color(0.78, 0.55, 0.32, 1)
@export var floor_color: Color = Color(0.18, 0.2, 0.24, 1)
@export var fridge_color: Color = Color(0.78, 0.86, 0.92, 1)
@export var fridge_shadow: Color = Color(0.64, 0.73, 0.8, 1)
@export var appliance_dark: Color = Color(0.25, 0.22, 0.2, 1)
@export var accent_blue: Color = Color(0.36, 0.7, 0.9, 1)
@export var window_frame_color: Color = Color(0.92, 0.92, 0.96, 1)
@export var window_glass_color: Color = Color(0.55, 0.78, 0.96, 0.6)

var bubbles: Array[Dictionary] = []
var gravel_points: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_generate_decor()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_generate_decor()
		queue_redraw()

func _generate_decor() -> void:
	bubbles.clear()
	gravel_points.clear()
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var tank_rect: Rect2 = _get_tank_rect()
	if tank_rect.size.x <= 0.0 or tank_rect.size.y <= 0.0:
		return

	rng.seed = bubble_seed
	for _i in range(bubble_count):
		var radius: float = rng.randf_range(bubble_min_radius, bubble_max_radius)
		bubbles.append({
			"pos": Vector2(
				rng.randf_range(tank_rect.position.x + 12.0, tank_rect.position.x + tank_rect.size.x - 12.0),
				rng.randf_range(tank_rect.position.y + 12.0, tank_rect.position.y + tank_rect.size.y - 60.0)
			),
			"radius": radius
		})

	var gravel_count: int = int(tank_rect.size.x / 18.0)
	for _i in range(gravel_count):
		var gx: float = rng.randf_range(tank_rect.position.x, tank_rect.position.x + tank_rect.size.x)
		var gy: float = rng.randf_range(tank_rect.position.y + tank_rect.size.y - gravel_height, tank_rect.position.y + tank_rect.size.y)
		var radius: float = rng.randf_range(2.0, 6.0)
		var color: Color = gravel_color_a if rng.randf() < 0.5 else gravel_color_b
		gravel_points.append({
			"pos": Vector2(gx, gy),
			"radius": radius,
			"color": color
		})

func _draw() -> void:
	var size_local: Vector2 = size
	if size_local.x <= 0.0 or size_local.y <= 0.0:
		return

	var table_top: float = max(size_local.y - table_height, 0.0)
	draw_rect(Rect2(Vector2.ZERO, size_local), outside_color)
	if kitchen_texture:
		draw_texture_rect(kitchen_texture, Rect2(Vector2.ZERO, size_local), false)
	else:
		draw_rect(Rect2(0, 0, size_local.x, table_top), wall_color)
		draw_rect(Rect2(0, table_top - 10.0, size_local.x, 10.0), wall_shadow)
		draw_rect(Rect2(0, table_top - 6.0, size_local.x, 6.0), baseboard_color)
		draw_rect(Rect2(0, table_top, size_local.x, size_local.y - table_top), table_color)

	var tank_rect: Rect2 = _get_tank_rect()
	if tank_rect.size.x <= 0.0 or tank_rect.size.y <= 0.0:
		return

	var kitchen_left: float = tank_rect.position.x + tank_rect.size.x * 0.06
	var kitchen_right: float = tank_rect.position.x + tank_rect.size.x * 0.94
	var kitchen_width: float = kitchen_right - kitchen_left

	var y: float = 0.0
	while y < tank_rect.size.y:
		var t: float = clamp(y / max(tank_rect.size.y, 1.0), 0.0, 1.0)
		var color: Color = top_color.lerp(bottom_color, t)
		if t > 0.3 and t < 0.7:
			color = color.lerp(mid_color, 0.25)
		color.a = water_alpha
		draw_rect(Rect2(tank_rect.position.x, tank_rect.position.y + y, tank_rect.size.x, gradient_step), color)
		y += gradient_step

	var wave_y: float = wave_spacing * 0.5
	while wave_y < tank_rect.size.y:
		var wave_pos: float = tank_rect.position.y + wave_y
		var wave_tint: Color = wave_color
		wave_tint.a = min(wave_tint.a, water_alpha)
		draw_line(Vector2(tank_rect.position.x, wave_pos), Vector2(tank_rect.position.x + tank_rect.size.x, wave_pos), wave_tint, wave_thickness)
		wave_y += wave_spacing

	for bubble: Dictionary in bubbles:
		draw_circle(bubble["pos"] as Vector2, bubble["radius"] as float, bubble_color)

	for gravel: Dictionary in gravel_points:
		draw_circle(gravel["pos"] as Vector2, gravel["radius"] as float, gravel["color"] as Color)

	draw_rect(Rect2(tank_rect.position.x, tank_rect.position.y, glass_highlight_width, tank_rect.size.y), glass_highlight_color)
	draw_rect(Rect2(tank_rect.position.x, tank_rect.position.y, tank_rect.size.x, glass_highlight_width), glass_highlight_color)
	draw_rect(tank_rect, border_color, false, border_width)

func _get_tank_rect() -> Rect2:
	var size_local: Vector2 = size
	var table_top: float = max(size_local.y - table_height, 0.0)
	var tank_width: float = clamp(size_local.x * tank_width_ratio, 240.0, size_local.x - outside_margin * 2.0)
	var tank_height: float = clamp((table_top - tank_top_margin) * tank_height_ratio, 180.0, table_top - tank_top_margin)
	var left: float = (size_local.x - tank_width) * 0.5
	var top: float = max(tank_top_margin, table_top - tank_height - tank_bottom_inset)
	return Rect2(left, top, tank_width, tank_height)

func get_tank_rect() -> Rect2:
	return _get_tank_rect()
