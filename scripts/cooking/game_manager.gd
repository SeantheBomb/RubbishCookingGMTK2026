class_name GameManager
extends Control
## Wires the trash can, tray, stat board, dart tester, and fox together
## into the actual play loop. Reuses the stat-board pieces unmodified.

@export var board_config: StatBoardConfig
@export var theme_data: StatBoardTheme
@export var order_pool: FoxOrderPool

@export_group("Juice Timing")
@export var dart_reveal_pause: float = 0.6 ## let the pop-in animation finish before reacting to the result
@export var result_hold_pause: float = 2.0 ## how long the darts + result stay on screen (hit or miss) before resetting for the next attempt
@export var game_over_pause: float = 1.0 ## dramatic pause before the leaderboard shows

@onready var gameplay_root: Control = %GameplayRoot
@onready var board: StatBoard = %Board
@onready var challenge_shape: StatShape = %ChallengeShape
@onready var dish_shape: StatShape = %DishShape
@onready var dart_tester: DartTester = %DartTester
@onready var trash_can: TrashCan = %TrashCan
@onready var tray: PlaceIngredientsTray = %Tray
@onready var fox: FoxCustomer = %Fox
@onready var cook_button: Button = %CookButton
@onready var score_label: Label = %ScoreLabel
@onready var remaining_label: Label = %RemainingLabel
@onready var leaderboard_ui: LeaderboardUI = %LeaderboardUI

var _rng := RandomNumberGenerator.new()
var _score: int = 0
var _fed_count: int = 0 ## drives FoxOrderPool.pick_progressive - the difficulty curve

func _ready() -> void:
	_rng.randomize()

	board.config = board_config
	board.theme_data = theme_data

	challenge_shape.config = board_config
	challenge_shape.fill_color = theme_data.challenge_fill_color
	challenge_shape.outline_color = theme_data.challenge_outline_color

	dish_shape.config = board_config
	dish_shape.fill_color = theme_data.dish_fill_color
	dish_shape.outline_color = theme_data.dish_outline_color

	dart_tester.challenge_shape = challenge_shape
	dart_tester.dish_shape = dish_shape

	tray.config = board_config
	tray.contents_changed.connect(_on_tray_contents_changed)

	cook_button.pressed.connect(_on_cook_pressed)
	fox.patience_expired.connect(_on_patience_expired)

	leaderboard_ui.hide()
	leaderboard_ui.play_again_pressed.connect(_start_new_run)

	_start_new_run()

func _start_new_run() -> void:
	leaderboard_ui.hide()
	gameplay_root.show()
	_score = 0
	_fed_count = 0
	_update_score_label()
	trash_can.refill()
	_start_next_order()

func _start_next_order() -> void:
	var previous_order := fox.current_order
	dart_tester.clear_hits()
	dart_tester.clear_misses()
	tray.clear() # emits contents_changed with an empty profile, which clears dish_shape
	var order := order_pool.pick_progressive(_rng, _fed_count, previous_order)
	fox.start_order(order)
	challenge_shape.set_profile(order.challenge_profile)
	_update_remaining_label()

func _on_tray_contents_changed(profile: StatProfile) -> void:
	dish_shape.set_profile(profile)

func _on_cook_pressed() -> void:
	cook_button.disabled = true
	dart_tester.throw_darts()
	await get_tree().create_timer(dart_reveal_pause).timeout

	var hits := dart_tester.get_score()
	var fulfilled := fox.register_hits(hits)
	if fulfilled:
		_score += fox.current_order.reward_points
		_fed_count += 1
		_update_score_label()
		Juice.pop(fox)
	_update_remaining_label()

	await get_tree().create_timer(result_hold_pause).timeout
	dart_tester.clear_misses()

	if fulfilled:
		_start_next_order() # also clears hits + tray, for the new order
	else:
		tray.clear()

	cook_button.disabled = false

func _on_patience_expired() -> void:
	Juice.flash(fox, Color(1.0, 0.35, 0.35))
	await get_tree().create_timer(game_over_pause).timeout
	LeaderboardStore.submit_score(_score)
	leaderboard_ui.show_results(_score, LeaderboardStore.get_top_scores())
	gameplay_root.hide()

func _update_score_label() -> void:
	score_label.text = "Score: %d" % _score

func _update_remaining_label() -> void:
	remaining_label.text = "Darts needed: %d" % fox.hits_needed
