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

static func get_bounding_box(polygon: PackedVector2Array) -> Rect2:
	var min_pos := polygon[0]
	var max_pos := polygon[0]
	for p in polygon:
		min_pos.x = minf(min_pos.x, p.x)
		min_pos.y = minf(min_pos.y, p.y)
		max_pos.x = maxf(max_pos.x, p.x)
		max_pos.y = maxf(max_pos.y, p.y)
	return Rect2(min_pos, max_pos - min_pos)

## An empty dish (no ingredients placed) still has one point per axis,
## all collapsed to the origin - a zero-area "polygon" that would
## otherwise register every dart as a free hit. Callers should refuse
## to throw darts into a polygon this returns false for.
static func polygon_has_area(polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3:
		return false
	var bounds := get_bounding_box(polygon)
	return bounds.size.x > 0.01 and bounds.size.y > 0.01

static func random_point_in_polygon(polygon: PackedVector2Array, rng: RandomNumberGenerator) -> Vector2:
	if polygon.size() < 3:
		return Vector2.ZERO

	var bounds := get_bounding_box(polygon)

	# Rejection sampling: cheap and plenty accurate for a 5-6 sided convex-ish shape.
	for attempt in 100:
		var candidate := Vector2(
			rng.randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			rng.randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
		if Geometry2D.is_point_in_polygon(candidate, polygon):
			return candidate
	return polygon[0]

static func _angle_for_index(index: int, count: int) -> float:
	return -PI / 2.0 + (TAU * index / float(count))
