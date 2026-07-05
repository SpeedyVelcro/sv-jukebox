extends HSlider
## Seek bar for SV Jukebox
##
## Horizontal slider that uses SV Jukebox to seek through the currently playing
## track. Also automatically updates the slider position to reflect current
## progress through the track while playing.

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController

var _is_dragging := false


# Override
func _process(delta: float) -> void:
	var length := SVJukebox.get_track_length()
	
	if length <= 0.0:
		# No track playing. Disable and use some default values.
		editable = false
		min_value = 0.0
		max_value = 60.0
		value = 0.0
		return
	
	editable = true
	
	min_value = 0.0
	max_value = length
	
	if not _is_dragging:
		value = SVJukebox.get_playback_position()


# Signal connection
func _on_drag_started() -> void:
	_is_dragging = true
	
	if ui_controller == null:
		push_error("UI Controller not set on seek bar.")
		return
	
	ui_controller.start_seek(value)


# Signal connection
func _on_drag_ended(value_changed: bool) -> void:
	_is_dragging = false
	
	if ui_controller == null:
		push_error("UI Controller not set on seek bar.")
		return
	
	ui_controller.update_seek(value)
	ui_controller.end_seek()


# Signal connection
func _on_value_changed(value: float) -> void:
	if not _is_dragging:
		return
	
	if ui_controller == null:
		push_error("UI Controller not set on seek bar.")
		return
	
	ui_controller.update_seek(value)
