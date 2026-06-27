extends Button
## Play/Pause button for SV Jukebox.
##
## This button allows playing or pausing a currently playing track using
## [SVJukeboxUIController].

## The type of a play/pause button, as it can morph between a play and pause
## button or disable based on the state of playback.
enum ButtonType {
	## Button is not usable.
	DISABLED,
	## Button will play the currently paused track.
	PLAY,
	## Button will pause the currently playing track.
	PAUSE
}

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController:
	set(value):
		_disconnect_controller_signals()
		ui_controller = value
		_connect_controller_signals()
	get():
		return ui_controller

## Icon to display when the button has "play" functionality, or by default when
## the button is disabled.
@export var play_icon: Texture2D:
	set(value):
		play_icon = value
		_update_icon()
	get:
		return play_icon

## Icon to display when the button has "pause" functionality.
@export var pause_icon: Texture2D:
	set(value):
		pause_icon = value
		_update_icon()
	get:
		return pause_icon

## Currently type (i.e. whether it's a play button or a pause button or outright
## disabled) of the button.
var button_type: ButtonType:
	set(value):
		button_type = value
		disabled = button_type == ButtonType.DISABLED
		_update_icon()
	get():
		return button_type


# Override
func _ready() -> void:
	button_type = ButtonType.DISABLED
	_connect_controller_signals()
	_update_icon()


func _update_icon() -> void:
	match button_type:
		ButtonType.DISABLED, ButtonType.PLAY:
			icon = play_icon
		ButtonType.PAUSE:
			icon = pause_icon


# Signal connection
func _on_pressed() -> void:
	if ui_controller == null:
		push_error("UI controller not set on play/pause button.")
		return
	
	# Looks at first glance like an identity crisis pattern but actually this
	# button really does morph it's behavior constantly. Maybe "ButtonType" needs
	# renaming, since it's not really a different button type but rather different
	# functionality.
	match button_type:
		ButtonType.DISABLED:
			pass # Do nothing
		ButtonType.PLAY:
			ui_controller.resume()
		ButtonType.PAUSE:
			ui_controller.pause()


func _on_ui_controller_playing_track(track: TrackInfo) -> void:
	button_type = ButtonType.PAUSE


func _on_ui_controller_stopping() -> void:
	button_type = ButtonType.DISABLED


func _on_ui_controller_pausing() -> void:
	button_type = ButtonType.PLAY


func _on_ui_controller_resuming() -> void:
	button_type = ButtonType.PAUSE


func _connect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if not ui_controller.playing_track.is_connected(_on_ui_controller_playing_track):
		ui_controller.playing_track.connect(_on_ui_controller_playing_track)
	
	if not ui_controller.stopping.is_connected(_on_ui_controller_stopping):
		ui_controller.stopping.connect(_on_ui_controller_stopping)
	
	if not ui_controller.pausing.is_connected(_on_ui_controller_pausing):
		ui_controller.pausing.connect(_on_ui_controller_pausing)
	
	if not ui_controller.resuming.is_connected(_on_ui_controller_resuming):
		ui_controller.resuming.connect(_on_ui_controller_resuming)


func _disconnect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if ui_controller.playing_track.is_connected(_on_ui_controller_playing_track):
		ui_controller.playing_track.disconnect(_on_ui_controller_playing_track)
	
	if ui_controller.stopping.is_connected(_on_ui_controller_stopping):
		ui_controller.stopping.disconnect(_on_ui_controller_stopping)
	
	if ui_controller.pausing.is_connected(_on_ui_controller_pausing):
		ui_controller.pausing.disconnect(_on_ui_controller_pausing)
	
	if ui_controller.resuming.is_connected(_on_ui_controller_resuming):
		ui_controller.resuming.disconnect(_on_ui_controller_resuming)


# Override
func _exit_tree() -> void:
	_disconnect_controller_signals()
