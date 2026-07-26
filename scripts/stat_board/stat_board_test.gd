class_name StatBoardTest
extends Control
## Test harness: renders the board, lets you drag the dish's sliders,
## swap between scenario resources, and throw darts to see the score.
## This is the reference for how a real cooking screen would wire in.

@export var config: StatBoardConfig
@export var theme_data: StatBoardTheme
@export var scenarios: Array[StatBoardScenario] = []

@onready var board: StatBoard = %Board
@onready var challenge_shape: StatShape = %ChallengeShape
@onready var dish_shape: StatShape = %DishShape
@onready var dart_tester: DartTester = %DartTester
@onready var slider_container: VBoxContainer = %SliderContainer
@onready var scenario_option: OptionButton = %ScenarioOption
@onready var score_label: Label = %ScoreLabel
@onready var throw_button: Button = %ThrowButton

var _dish_profile: StatProfile
var _sliders: Dictionary = {} # StringName axis id -> HSlider

func _ready() -> void:
	board.config = config
	board.theme_data = theme_data

	challenge_shape.config = config
	challenge_shape.fill_color = theme_data.challenge_fill_color
	challenge_shape.outline_color = theme_data.challenge_outline_color

	dish_shape.config = config
	dish_shape.fill_color = theme_data.dish_fill_color
	dish_shape.outline_color = theme_data.dish_outline_color

	dart_tester.challenge_shape = challenge_shape
	dart_tester.dish_shape = dish_shape

	_build_sliders()
	_populate_scenarios()
	throw_button.pressed.connect(_on_throw_pressed)

	if scenarios.size() > 0:
		_load_scenario(0)

func _build_sliders() -> void:
	for child in slider_container.get_children():
		child.queue_free()
	_sliders.clear()

	for axis in config.axes:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = axis.display_name
		label.custom_minimum_size.x = 80
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = config.max_value
		slider.step = 0.01
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(_on_slider_changed.bind(axis.id))
		row.add_child(label)
		row.add_child(slider)
		slider_container.add_child(row)
		_sliders[axis.id] = slider

func _populate_scenarios() -> void:
	scenario_option.clear()
	for scenario in scenarios:
		scenario_option.add_item(scenario.scenario_name)
	scenario_option.item_selected.connect(_load_scenario)

func _load_scenario(index: int) -> void:
	var scenario := scenarios[index]
	challenge_shape.set_profile(scenario.challenge_profile)
	_dish_profile = scenario.starting_dish_profile.duplicate(true)
	dish_shape.set_profile(_dish_profile)

	for axis in config.axes:
		var slider: HSlider = _sliders[axis.id]
		slider.set_value_no_signal(_dish_profile.get_value(axis.id))

	score_label.text = "Score: -"

func _on_slider_changed(value: float, axis_id: StringName) -> void:
	_dish_profile.set_value(axis_id, value)
	dish_shape.queue_redraw()

func _on_throw_pressed() -> void:
	dart_tester.throw_darts()
	score_label.text = "Score: %d/%d" % [dart_tester.get_score(), dart_tester.dart_count]
