class_name StatShape
extends Node2D
## One filled polygon on the board, driven by a StatProfile. Used for
## both the challenge outline and the cooked dish - just swap colors.

@export var config: StatBoardConfig
@export var profile: StatProfile
@export var fill_color: Color = Color(1, 1, 1, 0.3)
@export var outline_color: Color = Color.WHITE
@export var outline_width: float = 2.0

func _ready() -> void:
	queue_redraw()

func set_profile(new_profile: StatProfile) -> void:
	profile = new_profile
	queue_redraw()

func get_polygon_points() -> PackedVector2Array:
	if config == null or profile == null:
		return PackedVector2Array()
	return StatShapeMath.get_axis_points(config, profile)

func _draw() -> void:
	var points := get_polygon_points()
	if points.size() < 3:
		return
	draw_colored_polygon(points, fill_color)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, outline_color, outline_width)
