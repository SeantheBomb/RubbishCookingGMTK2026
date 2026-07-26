class_name Ingredient
extends Resource
## One ingredient the player can drag into a dish. Artist adds icon art
## here later; flavor_profile is what actually drives gameplay.

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export var flavor_profile: StatProfile
@export var spawn_weight: float = 1.0
