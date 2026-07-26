class_name IngredientToken
extends Control
## One draggable ingredient sitting in the trash can. Hovering shows a
## mini version of the stat board plotting this ingredient's flavor,
## via _make_custom_tooltip - easier to read at a glance than 8 lines
## of percentages.

@export var ingredient: Ingredient:
	set(value):
		ingredient = value
		_refresh_display()
@export var mini_board_config: StatBoardConfig
@export var tooltip_theme: StatBoardTheme

@onready var _label: Label = %NameLabel
@onready var _primary_fill: ColorRect = %PrimaryFill
@onready var _secondary_border: ColorRect = %SecondaryBorder

func _refresh_display() -> void:
	if ingredient == null or _label == null:
		return
	_label.text = ingredient.display_name
	tooltip_text = ingredient.display_name
	_apply_flavor_colors()

## Primary fill = the ingredient's single strongest flavor; the border
## behind it = its second-strongest. Axis colors come straight from
## mini_board_config.axes, so reskinning an axis color updates every
## ingredient card that uses it automatically.
func _apply_flavor_colors() -> void:
	if ingredient.flavor_profile == null or mini_board_config == null:
		return
	if mini_board_config.axes.size() < 2:
		return

	var ranked := mini_board_config.axes.duplicate()
	ranked.sort_custom(func(a, b): return ingredient.flavor_profile.get_value(a.id) > ingredient.flavor_profile.get_value(b.id))

	_primary_fill.color = ranked[0].color
	_secondary_border.color = ranked[1].color

func _make_custom_tooltip(_for_text: String) -> Object:
	if ingredient == null or ingredient.flavor_profile == null or mini_board_config == null:
		return null

	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.text = ingredient.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var preview_size := mini_board_config.radius * 2.4
	var board_root := Control.new()
	board_root.custom_minimum_size = Vector2(preview_size, preview_size)
	vbox.add_child(board_root)

	var origin := Node2D.new()
	origin.position = Vector2(preview_size / 2.0, preview_size / 2.0)
	board_root.add_child(origin)

	var board := StatBoard.new()
	board.config = mini_board_config
	board.theme_data = tooltip_theme
	origin.add_child(board)

	var shape := StatShape.new()
	shape.config = mini_board_config
	shape.profile = ingredient.flavor_profile
	shape.fill_color = Color(0.95, 0.6, 0.25, 0.45)
	shape.outline_color = Color(0.95, 0.6, 0.25, 1)
	origin.add_child(shape)

	return panel

func _get_drag_data(_at_position: Vector2) -> Variant:
	if ingredient == null:
		return null
	var preview := Label.new()
	preview.text = ingredient.display_name
	set_drag_preview(preview)
	return {"source_token": self}

## Reparents this token under new_parent (any drop zone: TrashCan or
## PlaceIngredientsTray) and centers it on at_position, which the drop
## zone already gives us in its own local space. Notifies the zone this
## token is LEAVING too, if it cares (PlaceIngredientsTray recomputes
## its combined profile so the dish preview reflects the removal).
func move_to(new_parent: Node, at_position: Vector2) -> void:
	var old_parent := get_parent()
	if old_parent != new_parent:
		if old_parent:
			old_parent.remove_child(self)
			if old_parent.has_method("_recompute_profile"):
				old_parent._recompute_profile()
		new_parent.add_child(self)
	position = at_position - size / 2.0
