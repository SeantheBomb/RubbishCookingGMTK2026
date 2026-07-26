@tool
class_name StatProfile
extends Resource
## A shape's data: one value per axis id. Used for both the challenge
## target and the cooked dish.
## @tool so get_value() still works when StatShape draws in the editor
## - without this, the editor loads it as an inert placeholder.

@export var values: Dictionary = {} # StringName axis id -> float

func get_value(axis_id: StringName) -> float:
	return values.get(axis_id, 0.0)

func set_value(axis_id: StringName, value: float) -> void:
	values[axis_id] = value
