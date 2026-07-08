extends Button
## Shuffle all button for SV Jukebox
##
## Button for SV Jukebox that plays the entire album sequentially in shuffle
## mode. Also ensures loop one is off by switching it to normal looping if
## (otherwise leaves looping alone). This is so that the whole album can be
## played as you would expect from a "shuffle all" button.

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController


func _on_pressed() -> void:
	if ui_controller == null:
		push_error("No UI controller set on shuffle all button.")
		return
	
	if ui_controller.get_loop_behavior() == SVJukeboxUIController.LoopBehavior.LOOP_ONE:
		ui_controller.loop() # Loop one would prevent playing the whole album.
	
	if not ui_controller.is_shuffle_on():
		ui_controller.set_shuffle_behavior(true)
	
	ui_controller.play_album()
