@tool
class_name Bin
extends StaticBody2D

## Distance to keep the Bin's origin from the viewport's bottom-right corner.
## Tune this in the Inspector - the bin's own art/collision offsets (Visual,
## the wall shapes, InteriorZone) are unaffected and stay relative to it.
## @tool so this previews live in the editor - but note this only reflects the
## real runtime placement while editing INSIDE sneaky_snacks_main.tscn, where
## Bin sits in the real SubViewport. Opening bin.tscn standalone will position
## it relative to the editor's own 2D view instead; ignore position there.
@export var corner_margin: Vector2 = Vector2(52, 20)

## Quick decaying rotation jostle, played via shake(). Rotates the whole
## StaticBody2D (walls included) around its own origin, which already sits
## at the bin's bottom/floor by convention - so resting food gets physically
## jostled too, not just the art. Remove the shake() call in food_item.gd's
## _on_toss_finished() to disable without touching this file.
const SHAKE_MIN_ANGLE_DEGREES := 3.0
const SHAKE_MAX_ANGLE_DEGREES := 5.0
const SHAKE_MIN_DURATION := 0.22
const SHAKE_MAX_DURATION := 0.38

@onready var _interior_zone: Area2D = $InteriorZone

var _shake_tween: Tween


func _ready() -> void:
	get_viewport().size_changed.connect(_update_position)
	_update_position()

	if Engine.is_editor_hint():
		return

	add_to_group("bin")


func _update_position() -> void:
	position = ViewportAnchor.corner_position(
		Vector2(get_viewport().size), ViewportAnchor.Corner.BOTTOM_RIGHT, corner_margin
	)


## A fresh geometric check, not Area2D.overlaps_body() - that relies on the
## Area's own tracked enter/exit events, which go stale for a body whose
## collision_layer gets zeroed while dragged (no clean "exited" fires), so it
## can keep reporting "inside" long after the food has visibly left the bin.
func is_food_inside(food: Node2D) -> bool:
	return get_interior_global_rect().has_point(food.global_position)


func shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
	rotation = 0.0

	var peak_angle: float = deg_to_rad(randf_range(SHAKE_MIN_ANGLE_DEGREES, SHAKE_MAX_ANGLE_DEGREES))
	var direction: float = 1.0 if randf() < 0.5 else -1.0
	var total_duration: float = randf_range(SHAKE_MIN_DURATION, SHAKE_MAX_DURATION)

	# Proportional phase split with a little jitter, so consecutive shakes
	# don't all move at the same relative speed either.
	var weights: Array[float] = [
		0.18 + randf_range(-0.04, 0.04),
		0.28 + randf_range(-0.05, 0.05),
		0.24 + randf_range(-0.05, 0.05),
		0.30 + randf_range(-0.04, 0.04),
	]
	var weight_sum: float = weights[0] + weights[1] + weights[2] + weights[3]

	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "rotation", direction * peak_angle, total_duration * weights[0] / weight_sum).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(self, "rotation", -direction * peak_angle, total_duration * weights[1] / weight_sum).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shake_tween.tween_property(self, "rotation", direction * peak_angle * 0.4, total_duration * weights[2] / weight_sum).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shake_tween.tween_property(self, "rotation", 0.0, total_duration * weights[3] / weight_sum).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## Global-space bounding rect of the bin's interior opening - the rim (top
## edge, smallest Y since Y+ is down) and left/right walls. Used to aim a
## toss so it clears the walls instead of clipping through them.
func get_interior_global_rect() -> Rect2:
	var shape_node: CollisionShape2D = _interior_zone.get_node("InteriorShape")
	var rect_shape: RectangleShape2D = shape_node.shape as RectangleShape2D
	var half_size: Vector2 = rect_shape.size * 0.5
	var xform: Transform2D = shape_node.global_transform

	var rect := Rect2(xform * Vector2(-half_size.x, -half_size.y), Vector2.ZERO)
	rect = rect.expand(xform * Vector2(half_size.x, -half_size.y))
	rect = rect.expand(xform * Vector2(half_size.x, half_size.y))
	rect = rect.expand(xform * Vector2(-half_size.x, half_size.y))
	return rect
