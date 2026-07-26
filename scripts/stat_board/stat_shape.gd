@tool
class_name StatShape
extends Node2D
## One filled polygon on the board, driven by a StatProfile. Used for
## both the challenge outline and the cooked dish - just swap colors.
## @tool makes this render live in the editor's 2D view.

@export var config: StatBoardConfig:
	set(value):
		config = value
		queue_redraw()
@export var profile: StatProfile:
	set(value):
		profile = value
		queue_redraw()
@export var fill_color: Color = Color(1, 1, 1, 0.3):
	set(value):
		fill_color = value
		queue_redraw()
@export var outline_color: Color = Color.WHITE:
	set(value):
		outline_color = value
		queue_redraw()
@export var outline_width: float = 2.0:
	set(value):
		outline_width = value
		queue_redraw()

func _ready() -> void:
	queue_redraw()

func set_profile(new_profile: StatProfile) -> void:
	profile = new_profile

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
