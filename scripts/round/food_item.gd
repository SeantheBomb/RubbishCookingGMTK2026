class_name FoodItem
extends RigidBody2D

## No FoodItem data asset yet (deliberately out of scope) - this only proves
## out collision/selection/toss-into-bin behavior with a placeholder circle.

const PLACEHOLDER_COLOR := Color(0.85, 0.55, 0.25)
const SELECTED_COLOR := Color(0.95, 0.75, 0.35)

const LAYER_FOOD := 1 << 1 # layer 2
const MASK_BIN_AND_FOOD := (1 << 0) | (1 << 1) # layers 1 + 2

## Toss-into-bin arc tuning. The apex rises further above whichever is more
## constraining - the drop point or the bin's rim (+ clearance) - and gets a
## bonus the closer the drop point is to the bin horizontally, so a toss from
## right beside the bin arcs sharply up-and-over while a far toss stays low
## and gentle.
const TOSS_BASE_ARC_HEIGHT := 70.0
const TOSS_CLOSE_RANGE_ARC_BONUS := 260.0
const TOSS_CLOSE_RANGE_DISTANCE := 100.0
const TOSS_FAR_RANGE_DISTANCE := 500.0
const TOSS_WALL_CLEARANCE := 20.0
## How far past the rim (into the bin) the curve's "clear the lip" point
## sits, so it visibly clears the opening instead of just grazing the top.
const TOSS_RIM_CLEAR_INSET := 28.0
const TOSS_SPEED := 1400.0 # px/sec along the curve, controls flight duration
const TOSS_MIN_DURATION := 0.25
const TOSS_MAX_DURATION := 1.1
const TOSS_SQUASH_SCALE := Vector2(1.25, 0.75)
const TOSS_SQUASH_DURATION := 0.07
const TOSS_LAND_SCALE := Vector2(1.2, 0.8)
const TOSS_LAND_DURATION := 0.15

## Draws the toss curve as a line for as long as it's in flight. Handy while
## tuning the arc constants above.
@export var debug_draw_curve: bool = false

@onready var _shape: CollisionShape2D = $Shape

var _radius: float = 24.0
var _is_selected: bool = false
var _toss_tween: Tween
var _toss_curve: Curve2D
var _debug_curve_line: Line2D
var _last_toss_global_position: Vector2
var _last_toss_velocity: Vector2
var _toss_bin: Bin
var _toss_landed: bool = false
var _is_tossing: bool = false


func _ready() -> void:
	input_event.connect(_on_input_event)
	var circle: CircleShape2D = _shape.shape as CircleShape2D
	if circle:
		_radius = circle.radius


func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius, SELECTED_COLOR if _is_selected else PLACEHOLDER_COLOR)


func _process(_delta: float) -> void:
	if _is_selected:
		global_position = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if not _is_selected:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_deselect()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_selected:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select()


func _select() -> void:
	_is_selected = true
	freeze = true
	collision_layer = 0
	collision_mask = 0
	queue_redraw()


func _deselect() -> void:
	_is_selected = false
	queue_redraw()

	var bin: Bin = get_tree().get_first_node_in_group("bin") as Bin
	if bin and bin.is_food_inside(self):
		_drop_in_place()
	else:
		_toss_into_bin()


func _drop_in_place() -> void:
	collision_layer = LAYER_FOOD
	collision_mask = MASK_BIN_AND_FOOD
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


func _toss_into_bin() -> void:
	var parent: Node2D = get_parent()
	var bin: Bin = get_tree().get_first_node_in_group("bin") as Bin
	_toss_bin = bin
	_toss_landed = false
	_is_tossing = true

	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	# Stays frozen (kinematically driven via position=) for the whole flight,
	# but collision is back on - normal contact detection (below) is what
	# cuts the flight short the instant it actually touches something.
	collision_layer = LAYER_FOOD
	collision_mask = MASK_BIN_AND_FOOD

	var start_global: Vector2 = global_position
	var clear_global: Vector2 = start_global # past the rim, before falling further
	var floor_global: Vector2 = start_global # fallback endpoint: the bin floor
	var rim_y_global: float = start_global.y

	if bin:
		var rect: Rect2 = bin.get_interior_global_rect()
		var inset: float = _radius + 6.0
		var min_x: float = rect.position.x + inset
		var max_x: float = rect.end.x - inset
		var target_x: float = clamp(start_global.x, min_x, max(min_x, max_x))
		rim_y_global = rect.position.y
		clear_global = Vector2(target_x, rect.position.y + TOSS_RIM_CLEAR_INSET)
		floor_global = Vector2(target_x, rect.end.y - _radius)

	var start: Vector2 = parent.to_local(start_global) if parent else start_global
	var clear_point: Vector2 = parent.to_local(clear_global) if parent else clear_global
	var floor_point: Vector2 = parent.to_local(floor_global) if parent else floor_global
	var rim_y: float = parent.to_local(Vector2(start_global.x, rim_y_global)).y if parent else rim_y_global

	_toss_curve = _build_toss_curve(start, clear_point, floor_point, rim_y)
	_last_toss_global_position = start_global
	_last_toss_velocity = Vector2.ZERO

	if debug_draw_curve:
		_show_debug_curve(parent)
	else:
		_clear_debug_curve()

	var duration: float = clamp(
		_toss_curve.get_baked_length() / TOSS_SPEED, TOSS_MIN_DURATION, TOSS_MAX_DURATION
	)

	if _toss_tween:
		_toss_tween.kill()

	_toss_tween = create_tween()
	_toss_tween.tween_property(self, "scale", TOSS_SQUASH_SCALE, TOSS_SQUASH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_toss_tween.tween_property(self, "scale", Vector2.ONE, TOSS_SQUASH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# EASE_IN (not IN_OUT) so speed keeps building toward the end, like a real
	# object accelerating as it falls - that also means there's real velocity
	# left to hand off to physics, instead of the tween easing to a stop.
	_toss_tween.tween_method(_apply_curve_position, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_toss_tween.tween_callback(_land_in_bin)


func _build_toss_curve(start: Vector2, clear_point: Vector2, floor_point: Vector2, rim_y: float) -> Curve2D:
	var horizontal_distance: float = abs(clear_point.x - start.x)
	var closeness: float = 1.0 - clamp(
		(horizontal_distance - TOSS_CLOSE_RANGE_DISTANCE)
			/ max(1.0, TOSS_FAR_RANGE_DISTANCE - TOSS_CLOSE_RANGE_DISTANCE),
		0.0, 1.0
	)
	var apex_rise: float = TOSS_BASE_ARC_HEIGHT + TOSS_CLOSE_RANGE_ARC_BONUS * closeness

	# Apex must clear both the drop point and the bin's rim (+ margin) -
	# whichever sits lower on screen is the binding constraint.
	var constraint_y: float = min(start.y, rim_y - TOSS_WALL_CLEARANCE)
	var apex_y: float = constraint_y - apex_rise

	# Out-tangent at start: up-ish, leaning toward the target. In-tangent at
	# clear_point: purely vertical, so it clears the lip moving straight down.
	var out_handle_start: Vector2 = Vector2((clear_point.x - start.x) * 0.3, apex_y - start.y)
	var in_handle_clear: Vector2 = Vector2(0.0, apex_y - clear_point.y)

	# From clear_point onward it's a straight vertical drop toward the floor
	# point - both tangents there point straight down so there's no kink.
	var vertical_handle_length: float = (floor_point.y - clear_point.y) * 0.4
	var out_handle_clear: Vector2 = Vector2(0.0, vertical_handle_length)
	var in_handle_floor: Vector2 = Vector2(0.0, vertical_handle_length * 0.5)

	var curve := Curve2D.new()
	curve.add_point(start, Vector2.ZERO, out_handle_start)
	curve.add_point(clear_point, in_handle_clear, out_handle_clear)
	curve.add_point(floor_point, in_handle_floor, Vector2.ZERO)
	return curve


func _apply_curve_position(t: float) -> void:
	var length: float = _toss_curve.get_baked_length()
	var offset: float = t * length
	position = _toss_curve.sample_baked(offset, true)

	var delta: float = get_process_delta_time()
	if delta > 0.0:
		_last_toss_velocity = (global_position - _last_toss_global_position) / delta
	_last_toss_global_position = global_position

	var ahead: Vector2 = _toss_curve.sample_baked(min(offset + 12.0, length), true)
	var tangent: Vector2 = ahead - position
	if tangent.length_squared() > 0.001:
		rotation = tangent.angle()

	_check_for_impact()


## A frozen body kinematically swept through positions via position= doesn't
## reliably generate collision signals (tried both an Area2D sensor and the
## body's own body_entered - neither caught food-on-food contact). Querying
## the physics world directly each frame sidesteps that entirely: it's a
## fresh geometric check against the current state, not dependent on the
## engine's contact-event bookkeeping.
func _check_for_impact() -> void:
	if _toss_landed:
		return
	# Only counts as "landed" once we're actually over the bin - ignore any
	# early contact on the way up and over the wall from outside.
	if _toss_bin == null or not _toss_bin.is_food_inside(self):
		return

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape.shape
	query.transform = global_transform
	query.collision_mask = MASK_BIN_AND_FOOD
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var results: Array[Dictionary] = space_state.intersect_shape(query, 1)
	if not results.is_empty():
		_land_in_bin()


func _show_debug_curve(parent: Node2D) -> void:
	_clear_debug_curve()
	if not parent or not _toss_curve:
		return
	_debug_curve_line = Line2D.new()
	_debug_curve_line.points = _toss_curve.get_baked_points()
	_debug_curve_line.width = 3.0
	_debug_curve_line.default_color = Color(1.0, 0.3, 0.85, 0.9)
	parent.add_child(_debug_curve_line)


func _clear_debug_curve() -> void:
	if _debug_curve_line:
		_debug_curve_line.queue_free()
		_debug_curve_line = null


## Called either when the curve tween finishes naturally (reached the floor
## point without hitting anything) or early, the instant real contact with
## the bin or another food item is detected (see _check_for_impact). Either
## way, this is the one place that hands control back to physics.
func _land_in_bin() -> void:
	if _toss_landed:
		return
	_toss_landed = true
	_is_tossing = false

	if _toss_tween:
		_toss_tween.kill()

	collision_layer = LAYER_FOOD
	collision_mask = MASK_BIN_AND_FOOD
	freeze = false
	linear_velocity = _last_toss_velocity
	_clear_debug_curve()

	if _toss_bin:
		_toss_bin.shake()

	var land_tween: Tween = create_tween()
	land_tween.tween_property(self, "scale", TOSS_LAND_SCALE, TOSS_LAND_DURATION * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	land_tween.tween_property(self, "scale", Vector2.ONE, TOSS_LAND_DURATION * 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
