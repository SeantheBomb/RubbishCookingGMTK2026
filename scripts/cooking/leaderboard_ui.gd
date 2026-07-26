class_name LeaderboardUI
extends Control
## Bare game-over screen: final score, saved top scores, play again.

signal play_again_pressed

@onready var _score_label: Label = %FinalScoreLabel
@onready var _list_label: Label = %ScoresList
@onready var _play_again_button: Button = %PlayAgainButton

func _ready() -> void:
	_play_again_button.pressed.connect(func(): play_again_pressed.emit())

func show_results(final_score: int, top_scores: Array) -> void:
	show()
	_score_label.text = "You scored: %d" % final_score
	var lines: PackedStringArray = []
	for i in top_scores.size():
		lines.append("%d. %d" % [i + 1, top_scores[i]])
	_list_label.text = "\n".join(lines)
