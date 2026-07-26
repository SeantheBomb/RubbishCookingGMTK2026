class_name PlaceIngredientsTray
extends Control
## Drop target for IngredientTokens. The tokens placed here ARE the
## state - no separate tracking list - so dragging one back out to the
## trash can or rearranging it within the tray just works. Combines
## whatever's currently a child into one StatProfile (average per axis)
## for the existing StatShape drawing code to preview unmodified.

signal contents_changed(profile: StatProfile)

@export var config: StatBoardConfig

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("source_token")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var token: IngredientToken = data.get("source_token")
	if token == null:
		return
	token.move_to(self, at_position)
	_recompute_profile()

func clear() -> void:
	for token in _get_ingredient_tokens():
		token.queue_free()
	# queue_free() defers actual removal, so get_combined_profile() would
	# still see these tokens if we recomputed from children right now -
	# clearing means empty, so just say so directly.
	contents_changed.emit(StatProfile.new())

func get_combined_profile() -> StatProfile:
	var tokens := _get_ingredient_tokens()
	var profile := StatProfile.new()
	if config == null or tokens.is_empty():
		return profile

	for axis in config.axes:
		var total := 0.0
		var count := 0
		for token in tokens:
			if token.ingredient and token.ingredient.flavor_profile:
				total += token.ingredient.flavor_profile.get_value(axis.id)
				count += 1
		if count > 0:
			profile.set_value(axis.id, total / float(count))
	return profile

func _get_ingredient_tokens() -> Array[IngredientToken]:
	var tokens: Array[IngredientToken] = []
	for child in get_children():
		if child is IngredientToken:
			tokens.append(child)
	return tokens

func _recompute_profile() -> void:
	contents_changed.emit(get_combined_profile())
