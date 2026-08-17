class_name NightCountdownSingleton
extends Node

## Autoload. Tracks the single round timer (22:00 - 5:00 over ROUND_DURATION_SECONDS)
## and the in-game clock string derived from it. Only ticks while a round has been
## started (see start_round/stop_round) and no pause has been requested.

const ROUND_DURATION_SECONDS: float = 300.0
const START_HOUR: float = 22.0
const IN_GAME_SPAN_HOURS: float = 7.0

signal time_updated(elapsed_seconds: float, in_game_time_string: String)
signal round_ended

var elapsed_seconds: float = 0.0
var is_running: bool = false

var _pause_requests: int = 0


func is_paused() -> bool:
	return _pause_requests > 0


func start_round() -> void:
	elapsed_seconds = 0.0
	is_running = true
	_pause_requests = 0
	time_updated.emit(elapsed_seconds, get_in_game_time_string())


func stop_round() -> void:
	is_running = false


func pause() -> void:
	_pause_requests += 1


func resume() -> void:
	_pause_requests = max(0, _pause_requests - 1)


func get_in_game_hour_and_minute(at_elapsed_seconds: float = elapsed_seconds) -> Vector2i:
	var fraction: float = at_elapsed_seconds / ROUND_DURATION_SECONDS
	var game_hour: float = fmod(START_HOUR + fraction * IN_GAME_SPAN_HOURS, 24.0)
	var hour: int = int(game_hour)
	var minute: int = int((game_hour - hour) * 60.0)
	if hour == 0:
		hour = 24 # 1-24 clock: midnight displays as 24, not 0
	return Vector2i(hour, minute)


func get_in_game_time_string() -> String:
	var parts: Vector2i = get_in_game_hour_and_minute()
	return "%02d:%02d" % [parts.x, parts.y]


func _process(delta: float) -> void:
	if not is_running or is_paused():
		return

	elapsed_seconds = min(elapsed_seconds + delta, ROUND_DURATION_SECONDS)
	time_updated.emit(elapsed_seconds, get_in_game_time_string())

	if elapsed_seconds >= ROUND_DURATION_SECONDS:
		is_running = false
		round_ended.emit()
