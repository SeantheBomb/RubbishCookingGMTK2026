class_name DartTester
extends Node2D
## Throws N random darts inside the challenge shape and scores how many
## also land inside the dish shape. Green (hit) darts persist across
## attempts against the same fox - so you can see cumulative progress
## toward 3 - and only clear via clear_hits() when a new fox arrives.
## Red (miss) darts are always transient; clear_misses() wipes them
## after each attempt's hold. Reassign challenge/dish_shape to test any
## pair of shapes without touching gameplay code.

signal darts_thrown(results: Array[bool])

@export var dart_count: int = 3
@export var dart_radius: float = 5.0
@export var challenge_shape: StatShape
@export var dish_shape: StatShape
@export var reveal_duration: float = 0.25 ## darts pop in over this long - 0 disables it. Swap _animate_reveal()/_draw() for your own effect freely, nothing else depends on how this looks.

var _rng := RandomNumberGenerator.new()
var _hit_points: PackedVector2Array = []
var _miss_points: PackedVector2Array = []
var _reveal_scale: float = 1.0
var _last_hit_count: int = 0

func _ready() -> void:
	_rng.randomize()

func throw_darts() -> Array[bool]:
	_miss_points.clear()
	var results: Array[bool] = []

	if challenge_shape == null or dish_shape == null:
		return results

	var challenge_polygon := challenge_shape.get_polygon_points()
	var dish_polygon := dish_shape.get_polygon_points()
	if not StatShapeMath.polygon_has_area(challenge_polygon):
		return results

	for i in dart_count:
		var point := StatShapeMath.random_point_in_polygon(challenge_polygon, _rng)
		var hit := StatShapeMath.polygon_contains_point(dish_polygon, point)
		results.append(hit)
		if hit:
			_hit_points.append(point)
		else:
			_miss_points.append(point)

	_last_hit_count = 0
	for hit in results:
		if hit:
			_last_hit_count += 1

	_animate_reveal()
	darts_thrown.emit(results)
	return results

func get_score() -> int:
	return _last_hit_count

## Call after the player has had time to read a miss - clears just the
## red darts, leaving any accumulated green hits in place.
func clear_misses() -> void:
	_miss_points.clear()
	queue_redraw()

## Call when a new fox order starts - wipes the accumulated green hits.
func clear_hits() -> void:
	_hit_points.clear()
	queue_redraw()

func _animate_reveal() -> void:
	_reveal_scale = 0.0
	queue_redraw()
	if reveal_duration <= 0.0:
		_reveal_scale = 1.0
		queue_redraw()
		return
	var tween := create_tween()
	tween.tween_method(_set_reveal_scale, 0.0, 1.0, reveal_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_reveal_scale(value: float) -> void:
	_reveal_scale = value
	queue_redraw()

func _draw() -> void:
	for p in _hit_points:
		draw_circle(p, dart_radius * _reveal_scale, Color.GREEN)
	for p in _miss_points:
		draw_circle(p, dart_radius * _reveal_scale, Color.RED)
