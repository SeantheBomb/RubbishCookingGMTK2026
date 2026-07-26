class_name StatShapeMath
extends RefCounted
## Pure geometry: turns axis values into polygon points, and answers
## point-in-polygon questions for the dart minigame.

static func get_axis_points(config: StatBoardConfig, profile: StatProfile) -> PackedVector2Array:
	var points := PackedVector2Array()
	var axis_count := config.axes.size()
	if axis_count == 0:
		return points
	for i in axis_count:
		var axis := config.axes[i]
		var value: float = clampf(profile.get_value(axis.id), 0.0, config.max_value)
		var ratio: float = value / config.max_value if config.max_value > 0.0 else 0.0
		var angle := _angle_for_index(i, axis_count)
		points.append(Vector2(cos(angle), sin(angle)) * config.radius * ratio)
	return points

static func get_frame_points(config: StatBoardConfig) -> PackedVector2Array:
	var points := PackedVector2Array()
	var axis_count := config.axes.size()
	for i in axis_count:
		var angle := _angle_for_index(i, axis_count)
		points.append(Vector2(cos(angle), sin(angle)) * config.radius)
	return points

static func polygon_contains_point(polygon: PackedVector2Array, point: Vector2) -> bool:
	return polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon)

static func random_point_in_polygon(polygon: PackedVector2Array, rng: RandomNumberGenerator) -> Vector2:
	if polygon.size() < 3:
		return Vector2.ZERO

	var min_x := polygon[0].x
	var max_x := polygon[0].x
	var min_y := polygon[0].y
	var max_y := polygon[0].y
	for p in polygon:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)

	# Rejection sampling: cheap and plenty accurate for a 5-6 sided convex-ish shape.
	for attempt in 100:
		var candidate := Vector2(rng.randf_range(min_x, max_x), rng.randf_range(min_y, max_y))
		if Geometry2D.is_point_in_polygon(candidate, polygon):
			return candidate
	return polygon[0]

static func _angle_for_index(index: int, count: int) -> float:
	return -PI / 2.0 + (TAU * index / float(count))
