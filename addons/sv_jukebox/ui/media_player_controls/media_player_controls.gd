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

## Icon for the stop button.
@export var stop_icon: Texture2D:
	set(value):
		stop_icon = value
		_update_stop_icon()
	get:
		return stop_icon

## Icon for the skip backward button.
@export var skip_backward_icon: Texture2D:
	set(value):
		skip_backward_icon = value
		_update_skip_backward_icon()
	get:
		return skip_backward_icon

## Icon for the skip forward button.
@export var skip_forward_icon: Texture2D:
	set(value):
		skip_forward_icon = value
		_update_skip_forward_icon()
	get:
		return skip_forward_icon

## Icon for the shuffle button when shuffle is on.
@export var shuffle_on_icon: Texture2D:
	set(value):
		shuffle_on_icon = value
		_update_shuffle_on_icon()
	get:
		return shuffle_on_icon

## Icon for the shuffle button when shuffle is off.
@export var shuffle_off_icon: Texture2D:
	set(value):
		shuffle_off_icon = value
		_update_shuffle_off_icon()
	get:
		return shuffle_off_icon

## Icon for the loop button when looping is off.
@export var loop_off_icon: Texture2D:
	set(value):
		loop_off_icon = value
		_update_loop_off_icon()
	get:
		return loop_off_icon

## Icon for the loop button when normal looping is on.
@export var loop_icon: Texture2D:
	set(value):
		loop_icon = value
		_update_loop_icon()
	get:
		return loop_icon

## Icon for the loop button when looping an individual track.
@export var loop_one_icon: Texture2D:
	set(value):
		loop_one_icon = value
		_update_loop_one_icon()
	get:
		return loop_one_icon

@onready var _stop_button: Control = $StopButton
@onready var _skip_backward_button: Control = $SkipBackwardButton
@onready var _play_pause_button: Control = $PlayPauseButton
@onready var _skip_forward_button: Control = $SkipForwardButton
@onready var _shuffle_button: Control = $ShuffleButton
@onready var _loop_button: Control = $LoopButton


# Override
func _ready() -> void:
	_update_ui_controller()
	_update_icons()


func _update_ui_controller() -> void:
	if _stop_button != null:
		_stop_button.ui_controller = ui_controller
	
	if _skip_backward_button != null:
		_skip_backward_button.ui_controller = ui_controller
	
	if _play_pause_button != null:
		_play_pause_button.ui_controller = ui_controller
	
	if _skip_forward_button != null:
		_skip_forward_button.ui_controller = ui_controller
	
	if _shuffle_button != null:
		_shuffle_button.ui_controller = ui_controller
	
	if _loop_button != null:
		_loop_button.ui_controller = ui_controller


func _update_icons() -> void:
	_update_stop_icon()
	_update_skip_backward_icon()
	_update_play_icon()
	_update_pause_icon()
	_update_skip_forward_icon()
	_update_shuffle_on_icon()
	_update_shuffle_off_icon()
	_update_loop_off_icon()
	_update_loop_icon()
	_update_loop_one_icon()


func _update_stop_icon() -> void:
	if _stop_button == null:
		return
	
	_stop_button.icon = stop_icon


func _update_play_icon() -> void:
	if _play_pause_button == null:
		return
	
	_play_pause_button.play_icon = play_icon


func _update_pause_icon() -> void:
	if _play_pause_button == null:
		return
	
	_play_pause_button.pause_icon = pause_icon


func _update_skip_backward_icon() -> void:
	if _skip_backward_button == null:
		return
	
	_skip_backward_button.icon = skip_backward_icon


func _update_skip_forward_icon() -> void:
	if _skip_forward_button == null:
		return
	
	_skip_forward_button.icon = skip_forward_icon


func _update_shuffle_on_icon() -> void:
	if _shuffle_button == null:
		return
	
	_shuffle_button.shuffle_on_icon = shuffle_on_icon


func _update_shuffle_off_icon() -> void:
	if _shuffle_button == null:
		return
	
	_shuffle_button.shuffle_off_icon = shuffle_off_icon


func _update_loop_off_icon() -> void:
	if _loop_button == null:
		return
	
	_loop_button.loop_off_icon = loop_off_icon


func _update_loop_icon() -> void:
	if _loop_button == null:
		return
	
	_loop_button.loop_icon = loop_icon


func _update_loop_one_icon() -> void:
	if _loop_button == null:
		return
	
	_loop_button.loop_one_icon = loop_one_icon
