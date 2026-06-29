extends HBoxContainer
## Row of media player controls for SV Jukebox.
##
## Media player control buttons arranged in a reasonably common horizontal
## layout. Should this layout not suffice, you can place the individual scenes
## instead as this scene doesn't provide any extra functionality other than
## conveniently grouping them together.

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController:
	set(value):
		ui_controller = value
		_update_ui_controller()
	get():
		return ui_controller

## Icon for the play button.
@export var play_icon: Texture2D:
	set(value):
		play_icon = value
		_update_play_icon()
	get:
		return play_icon

## Icon for the pause button.
@export var pause_icon: Texture2D:
	set(value):
		pause_icon = value
		_update_pause_icon()
	get:
		return pause_icon

@onready var _play_pause_button: Control = $PlayPauseButton
@onready var _stop_button: Control = $StopButton


# Override
func _ready() -> void:
	_update_ui_controller()
	_update_icons()


func _update_ui_controller() -> void:
	
	if _play_pause_button != null:
		_play_pause_button.ui_controller = ui_controller
	
	if _stop_button != null:
		_stop_button.ui_controller = ui_controller


func _update_icons() -> void:
	_update_play_icon()
	_update_pause_icon()


func _update_play_icon() -> void:
	if _play_pause_button == null:
		return
	
	_play_pause_button.play_icon = play_icon


func _update_pause_icon() -> void:
	if _play_pause_button == null:
		return
	
	_play_pause_button.pause_icon = pause_icon
