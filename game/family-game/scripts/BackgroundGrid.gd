extends ColorRect

@export var grid_size: float = 160.0
@export var dot_spacing: float = 48.0
@export var dot_radius: float = 2.0
@export var dot_color: Color = Color(0.4, 0.65, 0.85, 0.25)
@export var line_color: Color = Color(0.2, 0.4, 0.55, 0.35)
@export var border_color: Color = Color(0.7, 0.9, 1.0, 0.8)
@export var border_width: float = 3.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var size_local := size
	var x := 0.0
	while x <= size_local.x:
		draw_line(Vector2(x, 0), Vector2(x, size_local.y), line_color, 1.0)
		x += grid_size

	var y := 0.0
	while y <= size_local.y:
		draw_line(Vector2(0, y), Vector2(size_local.x, y), line_color, 1.0)
		y += grid_size

	var dot_y := 0.0
	while dot_y <= size_local.y:
		var dot_x := 0.0
		while dot_x <= size_local.x:
			draw_circle(Vector2(dot_x, dot_y), dot_radius, dot_color)
			dot_x += dot_spacing
		dot_y += dot_spacing

	draw_rect(Rect2(Vector2.ZERO, size_local), border_color, false, border_width)
