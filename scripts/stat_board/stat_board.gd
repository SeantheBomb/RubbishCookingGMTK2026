class_name StatBoard
extends Node2D
## Draws the pentagon frame: web rings, spokes, outline, axis icons/labels.
## Purely a function of config + theme_data - reskin by swapping resources.

@export var config: StatBoardConfig
@export var theme_data: StatBoardTheme

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	if config == null or theme_data == null or config.axes.is_empty():
		return

	var frame_points := StatShapeMath.get_frame_points(config)

	for ring in range(1, theme_data.web_ring_count + 1):
		var ratio := float(ring) / float(theme_data.web_ring_count)
		var ring_points := PackedVector2Array()
		for p in frame_points:
			ring_points.append(p * ratio)
		ring_points.append(ring_points[0])
		draw_polyline(ring_points, theme_data.web_color, 1.0)

	for p in frame_points:
		draw_line(Vector2.ZERO, p, theme_data.web_color, 1.0)

	var closed_frame := frame_points.duplicate()
	closed_frame.append(frame_points[0])
	draw_polyline(closed_frame, theme_data.outline_color, 2.0)

	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	for i in config.axes.size():
		var axis := config.axes[i]
		var label_pos: Vector2 = frame_points[i] * 1.2
		if axis.icon:
			draw_texture(axis.icon, label_pos - axis.icon.get_size() / 2.0, axis.color)
		else:
			var text_size := font.get_string_size(axis.display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			draw_string(font, label_pos - text_size / 2.0, axis.display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, axis.color)
