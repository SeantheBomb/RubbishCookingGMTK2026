class_name RoundTimerDisplay
extends PanelContainer

const BASE_COLOR := Color(0.74902, 0.74510, 0.67059) # bfbeab
const WARNING_COLOR := Color(0.76078, 0.49020, 0.10196) # c27d1a
const CRITICAL_COLOR := Color(0.74510, 0.18431, 0.26275) # be2f43

const WARNING_HOURS_REMAINING := 1.0
const CRITICAL_MINUTES_REMAINING := 30.0

const DISPLAY_MINUTE_STEP := 10

enum UrgencyState { NORMAL, WARNING, CRITICAL }

@onready var _time_label: Label = %TimeLabel

var _urgency_state: UrgencyState = UrgencyState.NORMAL
var _current_color: Color = BASE_COLOR
var _flash_tween: Tween


func _ready() -> void:
	NightCountdown.time_updated.connect(_on_time_updated)


func _on_time_updated(elapsed_seconds: float, _in_game_time_string: String) -> void:
	var parts: Vector2i = NightCountdown.get_in_game_hour_and_minute(elapsed_seconds)
	var rounded_minute: int = (parts.y / DISPLAY_MINUTE_STEP) * DISPLAY_MINUTE_STEP
	_time_label.text = "%02d:%02d" % [parts.x, rounded_minute]

	var remaining_seconds: float = NightCountdown.ROUND_DURATION_SECONDS - elapsed_seconds
	var remaining_game_hours: float = (
		remaining_seconds / NightCountdown.ROUND_DURATION_SECONDS * NightCountdown.IN_GAME_SPAN_HOURS
	)
	var remaining_game_minutes: float = remaining_game_hours * 60.0

	if _urgency_state < UrgencyState.CRITICAL and remaining_game_minutes <= CRITICAL_MINUTES_REMAINING:
		_urgency_state = UrgencyState.CRITICAL
		_flash_and_settle(CRITICAL_COLOR, 1.0, 2)
	elif _urgency_state < UrgencyState.WARNING and remaining_game_hours <= WARNING_HOURS_REMAINING:
		_urgency_state = UrgencyState.WARNING
		_flash_and_settle(WARNING_COLOR, 1.5, 3)


func _flash_and_settle(target_color: Color, total_duration: float, blink_count: int) -> void:
	if _flash_tween:
		_flash_tween.kill()

	var start_color: Color = _current_color
	var half_step: float = total_duration / float(blink_count * 2)

	_flash_tween = create_tween()
	for i in range(blink_count):
		_flash_tween.tween_method(_set_label_color, start_color, target_color, half_step)
		if i < blink_count - 1:
			_flash_tween.tween_method(_set_label_color, target_color, start_color, half_step)
	_flash_tween.tween_callback(func() -> void: _current_color = target_color)


func _set_label_color(color: Color) -> void:
	_time_label.add_theme_color_override("font_color", color)
