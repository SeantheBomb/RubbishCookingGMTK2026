@tool
class_name FoodSpawner
extends Node2D

## The Lid Area2D doubles as an "is the bin full" sensor: while any settled
## food overlaps it, spawning pauses. The item currently being spawned is
## ignored while it passes through on its way down, via _newly_spawned_food.
##
## @tool so the corner-anchored position previews live in the editor - but
## everything else in _ready() (Timer, RoundManager/NightCountdown wiring)
## is skipped in the editor, since those autoloads only exist at real runtime.

const FOOD_SCENE: PackedScene = preload("res://scenes/food_item.tscn")
const SPAWN_INTERVAL_SECONDS: float = 2.0

## Distance to keep the spawner's origin from the viewport's top-right corner.
@export var corner_margin: Vector2 = Vector2(80, 60)

## How far left/right (in pixels) each spawn's X position can vary from
## the SpawnPoint, so food doesn't fall in an identical line every time.
@export var spawn_x_variation: float = 100.0

@onready var _timer: Timer = $SpawnTimer
@onready var _lid: Area2D = $Lid
@onready var _spawn_point: Marker2D = $SpawnPoint

var _overlapping_food: Array[Node2D] = []
var _newly_spawned_food: Node2D = null


func _ready() -> void:
	get_viewport().size_changed.connect(_update_position)
	_update_position()

	if Engine.is_editor_hint():
		return

	add_to_group("food_spawner")
	_timer.wait_time = SPAWN_INTERVAL_SECONDS
	_timer.timeout.connect(_on_timer_timeout)
	_lid.body_entered.connect(_on_lid_body_entered)
	_lid.body_exited.connect(_on_lid_body_exited)

	RoundManager.round_started.connect(_on_round_started)
	RoundManager.round_ended.connect(_on_round_ended)

	if RoundManager.is_round_active():
		_on_round_started(RoundManager.current_round_number)


func _update_position() -> void:
	position = ViewportAnchor.corner_position(
		Vector2(get_viewport().size), ViewportAnchor.Corner.TOP_RIGHT, corner_margin
	)


func is_active() -> bool:
	return _overlapping_food.is_empty()


func get_spawn_point() -> Vector2:
	return _spawn_point.global_position


func _on_round_started(_round_number: int) -> void:
	_timer.start()


func _on_round_ended(_round_number: int) -> void:
	_timer.stop()


func _on_timer_timeout() -> void:
	if not is_active():
		return
	_spawn_food()


func _spawn_food() -> void:
	var food: Node2D = FOOD_SCENE.instantiate()
	var x_offset: float = randf_range(-spawn_x_variation, spawn_x_variation)
	var target_global: Vector2 = _spawn_point.global_position + Vector2(x_offset, 0.0)

	var parent: Node2D = get_parent()
	food.position = parent.to_local(target_global) if parent else target_global
	parent.add_child(food)
	_newly_spawned_food = food


func _on_lid_body_entered(body: Node2D) -> void:
	if body == _newly_spawned_food:
		return
	if body not in _overlapping_food:
		_overlapping_food.append(body)


func _on_lid_body_exited(body: Node2D) -> void:
	_overlapping_food.erase(body)
	if body == _newly_spawned_food:
		_newly_spawned_food = null
