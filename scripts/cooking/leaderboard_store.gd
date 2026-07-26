class_name LeaderboardStore
extends RefCounted
## Tiny local high-score file - no server, no account, just user://.

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10

static func submit_score(score: int) -> void:
	var scores := get_top_scores()
	scores.append(score)
	scores.sort()
	scores.reverse()
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(scores))
		file.close()

static func get_top_scores() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return []
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		return parsed
	return []
