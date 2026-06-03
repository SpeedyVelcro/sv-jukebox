extends Node


func _on_quit_button_pressed() -> void:
	SVJukebox.save_unlocks()
	get_tree().quit()


func _on_play_invasion_button_pressed() -> void:
	SVJukebox.play("invasion")


func _on_unlock_invasion_button_2_pressed() -> void:
	SVJukebox.unlock("invasion")


func _on_play_anxiety_button_pressed() -> void:
	SVJukebox.play("anxiety")


func _on_unlock_anxiety_button_pressed() -> void:
	SVJukebox.unlock("anxiety")


func _on_play_petra_button_pressed() -> void:
	SVJukebox.play("petra")


func _on_unlock_petra_button_pressed() -> void:
	SVJukebox.unlock("petra")
