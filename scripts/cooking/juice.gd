class_name Juice
extends RefCounted
## Small, swappable game-feel helpers for meaningful moments. Each
## effect is one function with a couple of tunable numbers - change the
## numbers, replace a function body, or swap a call site for your own
## animation/particle/sound entirely. Nothing else depends on how these
## look, only that they run.

## A quick scale bounce - use for "something good just happened" (fed a fox, scored a hit).
static func pop(node: Control, amount: float = 1.25, duration: float = 0.28) -> void:
	node.pivot_offset = node.size / 2.0
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * amount, duration * 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## A brief color flash that fades back to normal - use for "something bad just happened" (patience ran out).
static func flash(node: CanvasItem, color: Color = Color.WHITE, duration: float = 0.3) -> void:
	var original := node.modulate
	node.modulate = color
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", original, duration)
