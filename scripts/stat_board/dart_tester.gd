class_name DartTester
extends Node2D
## Throws N random darts inside the challenge shape and scores how many
## also land inside the dish shape. Reassign challenge/dish_shape to
## test any pair of shapes without touching gameplay code.

signal darts_thrown(results: Array[bool])

@export var dart_count: int = 3
@export var dart_radius: float = 5.0
@export var challenge_shape: StatShape
@export var dish_shape: StatShape

var _rng := RandomNumberGenerator.new()
var _last_results: Array[bool] = []
var _last_points: PackedVector2Array = []

func _ready() -> void:
	_rng.randomize()

func throw_darts() -> Array[bool]:
	_last_results.clear()
	_last_points.clear()

	if challenge_shape == null or dish_shape == null:
		return _last_results

	var challenge_polygon := challenge_shape.get_polygon_points()
	var dish_polygon := dish_shape.get_polygon_points()
	if challenge_polygon.size() < 3:
		return _last_results

	for i in dart_count:
		var point := StatShapeMath.random_point_in_polygon(challenge_polygon, _rng)
		var hit := StatShapeMath.polygon_contains_point(dish_polygon, point)
		_last_points.append(point)
		_last_results.append(hit)

	queue_redraw()
	darts_thrown.emit(_last_results)
	return _last_results

func get_score() -> int:
	var score := 0
	for hit in _last_results:
		if hit:
			score += 1
	return score

func _draw() -> void:
	for i in _last_points.size():
		var color: Color = Color.GREEN if _last_results[i] else Color.RED
		draw_circle(_last_points[i], dart_radius, color)
