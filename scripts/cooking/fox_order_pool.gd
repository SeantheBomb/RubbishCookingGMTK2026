class_name FoxOrderPool
extends Resource
## The set of orders a new fox can be assigned from. Ordered easiest to
## hardest - pick_progressive() relies on that order to ramp difficulty
## over a run instead of picking uniformly at random forever.

@export var orders: Array[FoxOrder] = []

## fed_count = how many foxes have been successfully fed this run.
## Targets the order at that index (clamped to the array), with a small
## +/-1 window of randomness so it's not perfectly predictable - but
## never repeats previous_order back-to-back.
func pick_progressive(rng: RandomNumberGenerator, fed_count: int, previous_order: FoxOrder = null) -> FoxOrder:
	if orders.is_empty():
		return null
	var last_index := orders.size() - 1
	var target := clampi(fed_count, 0, last_index)
	var lo := maxi(0, target - 1)
	var hi := mini(last_index, target + 1)

	var candidates: Array[FoxOrder] = []
	for i in range(lo, hi + 1):
		if orders[i] != previous_order:
			candidates.append(orders[i])

	if candidates.is_empty():
		return orders[rng.randi_range(lo, hi)] # window only contained previous_order - allow the repeat rather than fail
	return candidates[rng.randi_range(0, candidates.size() - 1)]
