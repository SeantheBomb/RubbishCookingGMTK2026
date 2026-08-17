class_name RoundManagerSingleton
extends Node

## Autoload. Single source of truth for "is a round currently running, or are we
## between rounds, and which round is this." Other systems (NightCountdown, the
## timer display, fox/food spawning later) should read round state from here
## rather than tracking it themselves.

enum State { BETWEEN_ROUNDS, ROUND_ACTIVE }

signal round_started(round_number: int)
signal round_ended(round_number: int)

var state: State = State.BETWEEN_ROUNDS
var current_round_number: int = 0


func _ready() -> void:
	NightCountdown.round_ended.connect(_on_night_countdown_round_ended)


func is_round_active() -> bool:
	return state == State.ROUND_ACTIVE


func start_next_round() -> void:
	current_round_number += 1
	state = State.ROUND_ACTIVE
	NightCountdown.start_round()
	round_started.emit(current_round_number)


func _on_night_countdown_round_ended() -> void:
	state = State.BETWEEN_ROUNDS
	round_ended.emit(current_round_number)
