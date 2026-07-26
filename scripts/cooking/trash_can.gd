class_name TrashCan
extends Control
## Scatters random IngredientTokens inside its own rect, drawing from a
## shuffle-bag (one of each ingredient in random order per cycle, then
## reshuffled) instead of independent random picks - pseudorandom order,
## but no ingredient goes on a long streak or a long drought. Call
## refill() to restock everything at once (run start / play again). Also
## trickles in one new random ingredient every replenish_interval_seconds
## on its own, up to max_tokens, so the pantry doesn't run permanently
## dry over a run. Also accepts drops, so tokens can be rearranged here
## or dragged back in from the tray.

@export var pool: IngredientPool
@export var token_scene: PackedScene
@export var spawn_count: int = 10
@export var token_size: Vector2 = Vector2(72, 72)

@export_group("Passive Replenish")
@export var replenish_interval_seconds: float = 4.0
@export var max_tokens: int = 16

@onready var _replenish_timer: Timer = %ReplenishTimer

var _rng := RandomNumberGenerator.new()
var _bag: Array[Ingredient] = []

func _ready() -> void:
	_rng.randomize()
	_replenish_timer.wait_time = replenish_interval_seconds
	_replenish_timer.timeout.connect(_on_replenish_timer_timeout)
	_replenish_timer.start()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("source_token")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var token: IngredientToken = data.get("source_token")
	if token:
		token.move_to(self, at_position)

func refill() -> void:
	for token in _get_ingredient_tokens():
		token.queue_free()
	_bag.clear()
	for i in spawn_count:
		_spawn_one()

func _on_replenish_timer_timeout() -> void:
	if _get_ingredient_tokens().size() >= max_tokens:
		return
	var token := _spawn_one()
	if token:
		Juice.pop(token)

func _spawn_one() -> IngredientToken:
	if pool == null or token_scene == null:
		return null
	var ingredient := _draw_from_bag()
	if ingredient == null:
		return null
	var token: IngredientToken = token_scene.instantiate()
	token.size = token_size
	token.position = Vector2(
		_rng.randf_range(0.0, maxf(size.x - token_size.x, 0.0)),
		_rng.randf_range(0.0, maxf(size.y - token_size.y, 0.0))
	)
	add_child(token)
	token.ingredient = ingredient
	return token

## Refills + reshuffles whenever the bag runs dry, so every ingredient
## is guaranteed to appear once per cycle before any repeats.
func _draw_from_bag() -> Ingredient:
	if pool == null:
		return null
	if _bag.is_empty():
		_bag = pool.build_bag()
		_shuffle_bag()
	return _bag.pop_back()

func _shuffle_bag() -> void:
	for i in range(_bag.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := _bag[i]
		_bag[i] = _bag[j]
		_bag[j] = tmp

func _get_ingredient_tokens() -> Array[IngredientToken]:
	var tokens: Array[IngredientToken] = []
	for child in get_children():
		if child is IngredientToken:
			tokens.append(child)
	return tokens
