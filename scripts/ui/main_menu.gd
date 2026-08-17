class_name MainMenu
extends Control

@onready var _instructions_overlay: Control = %InstructionsOverlay


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/sneaky_snacks_main.tscn")


func _on_instructions_pressed() -> void:
	_instructions_overlay.visible = true


func _on_instructions_close_pressed() -> void:
	_instructions_overlay.visible = false


func _on_exit_pressed() -> void:
	get_tree().quit()
