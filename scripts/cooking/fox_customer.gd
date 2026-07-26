class_name FoxCustomer
extends Control
## One active order: tracks cumulative dart hits toward 3 and the
## patience countdown. Countdown keeps running across multiple cook
## attempts - only stops when the order is fulfilled.

signal patience_expired

@onready var _name_label: Label = %OrderLabel
@onready var _patience_bar: ProgressBar = %PatienceBar
@onready var _timer: Timer = %PatienceTimer

var current_order: FoxOrder
var hits_needed: int = 3

func _ready() -> void:
	_timer.timeout.connect(_on_patience_timer_timeout)

func start_order(order: FoxOrder) -> void:
	current_order = order
	hits_needed = 3
	_name_label.text = order.order_name
	_patience_bar.max_value = order.patience_seconds
	_patience_bar.value = order.patience_seconds
	_timer.wait_time = order.patience_seconds
	_timer.start()

func register_hits(hit_count: int) -> bool:
	hits_needed = maxi(hits_needed - hit_count, 0)
	if hits_needed <= 0:
		_timer.stop()
		return true
	return false

func _process(_delta: float) -> void:
	if _timer.time_left > 0.0:
		_patience_bar.value = _timer.time_left

func _on_patience_timer_timeout() -> void:
	patience_expired.emit()
