class_name StatBoardConfig
extends Resource
## Defines the board itself: how many axes, in what order, how big.
## Add/remove flavors by editing this array - no scene changes needed.

@export var axes: Array[StatAxis] = []
@export var radius: float = 200.0
@export var max_value: float = 1.0
