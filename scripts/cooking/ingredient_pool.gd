class_name IngredientPool
extends Resource
## The set of ingredients the trash can draws from. Add new foods by
## adding one Ingredient .tres and dropping it in this array.

@export var ingredients: Array[Ingredient] = []

## Expands each ingredient into round(spawn_weight) copies (minimum 1) -
## the raw list TrashCan's shuffle-bag draws from. Every copy in the bag
## gets served before any repeats, so a full bag cycle serves each
## ingredient a proportionate, even number of times - spawn_weight still
## lets you make one rarer/more common without reintroducing pure-luck
## streaks or droughts.
func build_bag() -> Array[Ingredient]:
	var bag: Array[Ingredient] = []
	for ingredient in ingredients:
		var copies := maxi(1, roundi(ingredient.spawn_weight))
		for i in copies:
			bag.append(ingredient)
	return bag
