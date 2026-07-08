extends Button
## Play all button for SV Jukebox
##
## Button for SV Jukebox that plays the entire album sequentially. This means
## shuffle will be turned off if it is currently on, and if loop one is enabled
## normal looping will be enabled instead (looping is untouched otherwise).

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController


func _on_pressed() -> void:
	if ui_controller == null:
		push_error("No UI controller set on play all button.")
		return
	
	if ui_controller.get_loop_behavior() == SVJukeboxUIController.LoopBehavior.LOOP_ONE:
		ui_controller.loop() # Loop one would prevent playing the whole album.
	
	if ui_controller.is_shuffle_on():
		ui_controller.set_shuffle_behavior(false)
	
	ui_controller.play_album()
