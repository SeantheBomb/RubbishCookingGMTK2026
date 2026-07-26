class_name StatBoardTheme
extends Resource
## Everything the artist owns for reskinning the board's look.
## Swap this resource (or its fields) without touching any script.

@export var web_color: Color = Color(0.5, 0.45, 0.2, 0.5)
@export var outline_color: Color = Color.WHITE
@export var web_ring_count: int = 4

@export var challenge_outline_color: Color = Color(0.9, 0.8, 0.3)
@export var challenge_fill_color: Color = Color(0.9, 0.8, 0.3, 0.15)

@export var dish_outline_color: Color = Color(0.5, 0.9, 0.5)
@export var dish_fill_color: Color = Color(0.5, 0.9, 0.5, 0.35)

@export var dart_hit_color: Color = Color.GREEN
@export var dart_miss_color: Color = Color.RED
