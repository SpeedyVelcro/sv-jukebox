extends Node


func _on_quit_button_pressed() -> void:
	SVJukebox.save_unlocks()
	get_tree().quit()


func _on_play_invasion_button_pressed() -> void:
	SVJukebox.play("invasion")


func _on_play_invasion_no_unlock_button_pressed() -> void:
	SVJukebox.play_no_unlock("invasion")


func _on_unlock_invasion_button_pressed() -> void:
	SVJukebox.unlock("invasion")


func _on_play_anxiety_button_pressed() -> void:
	SVJukebox.play("anxiety")


func _on_play_anxiety_no_unlock_button_pressed() -> void:
	SVJukebox.play_no_unlock("anxiety")


func _on_unlock_anxiety_button_pressed() -> void:
	SVJukebox.unlock("anxiety")


func _on_play_petra_button_pressed() -> void:
	SVJukebox.play("petra")


func _on_play_petra_no_unlock_button_pressed() -> void:
	pass # Replace with function body.


func _on_unlock_petra_button_pressed() -> void:
	SVJukebox.unlock("petra")


func _on_unlock_all_button_pressed() -> void:
	SVJukebox.unlock_all()


func _on_remove_all_unlocks_button_pressed() -> void:
	SVJukebox.remove_all_unlocks()


func _on_to_jukebox_button_pressed() -> void:
	$Control/SimControl.visible = false
	$Control/JukeboxControl.visible = true


func _on_jukebox_back_button_pressed() -> void:
	$Control/SimControl.visible = true
	$Control/JukeboxControl.visible = false
