extends Button
## Skip backward button for SV Jukebox
##
## This button skips to the beginning of the current track or - if already
## at the beginning - skips to the previous track (provided there is one to
## skip to). It does this using the assigned [SVJukeboxUIController]

# Note that this button is always enabled when a track is playing (unlike the
# skip forward button which needs to check if there is a next track). This is
# because "skip backward" is functionality that works without a previous track
# as the UI controller can always fall back on skipping to the beginning of the
# current track.

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController:
	set(value):
		_disconnect_controller_signals()
		ui_controller = value
		_connect_controller_signals()
	get():
		return ui_controller


# Override
func _ready() -> void:
	disabled = true
	_connect_controller_signals()


# Signal connection
func _on_pressed() -> void:
	if ui_controller == null:
		push_error("UI controller not set on skip backward button.")
		return
	
	ui_controller.skip_backward()


# Signal connection
func _on_ui_controller_playing_track(track: TrackInfo) -> void:
	disabled = false


# Signal connection
func _on_ui_controller_stopping() -> void:
	disabled = true


# Signal connection
func _on_ui_controller_pausing() -> void:
	# Should already have been disabled when the track started playing, but doing
	# it again just in case UI Controller was manipulated in a weird way doesn't hurt.
	disabled = false


# Signal connection
func _on_ui_controller_resuming() -> void:
	# Should already have been disabled when the track started playing, but doing
	# it again just in case UI Controller was manipulated in a weird way doesn't hurt.
	disabled = false


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
