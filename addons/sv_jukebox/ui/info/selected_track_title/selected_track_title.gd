extends Label
## Track title label for SV Jukebox
##
## Displays the title of the currently selected track. Falls back on the title
## of the album if no track is selected.

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
	_show_album_title()


func _show_album_title() -> void:
	if ui_controller == null:
		push_error("Selected track title label does not have a UI Controller set, so can't get album info.")
		return
	
	var album := ui_controller.get_album()
	
	if album == null:
		push_error("UI Controller did not have an album for track title label. Text will not be updated.")
		return
	
	text = album.title


# Signal connection
func _on_ui_controller_track_selected(track: TrackInfo) -> void:
	if track == null:
		_show_album_title()
		return
	
	text = track.title


func _connect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if not ui_controller.track_selected.is_connected(_on_ui_controller_track_selected):
		ui_controller.track_selected.connect(_on_ui_controller_track_selected)


func _disconnect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if ui_controller.track_selected.is_connected(_on_ui_controller_track_selected):
		ui_controller.track_selected.disconnect(_on_ui_controller_track_selected)


# Override
func _exit_tree() -> void:
	_disconnect_controller_signals()
