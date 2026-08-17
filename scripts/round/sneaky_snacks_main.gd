extends Control


func _ready() -> void:
	RoundManager.start_next_round()


func _exit_tree() -> void:
	NightCountdown.stop_round()
