class_name ViewportAnchor
extends RefCounted

## Shared math for pinning a Node2D to a corner of its enclosing SubViewport,
## since Node2D has no anchor system of its own (unlike Control). Call from
## _ready() and again whenever Viewport.size_changed fires.

enum Corner { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }


static func corner_position(viewport_size: Vector2, corner: int, margin: Vector2) -> Vector2:
	match corner:
		Corner.TOP_LEFT:
			return margin
		Corner.TOP_RIGHT:
			return Vector2(viewport_size.x - margin.x, margin.y)
		Corner.BOTTOM_LEFT:
			return Vector2(margin.x, viewport_size.y - margin.y)
		Corner.BOTTOM_RIGHT:
			return viewport_size - margin
	return Vector2.ZERO
