class_name FoxOrder
extends Resource
## One fox's request: what flavor shape they want, how long they'll
## wait, and what it's worth. Add new orders as new .tres files.

@export var order_name: String = ""
@export var challenge_profile: StatProfile
@export var patience_seconds: float = 30.0
@export var reward_points: int = 10
