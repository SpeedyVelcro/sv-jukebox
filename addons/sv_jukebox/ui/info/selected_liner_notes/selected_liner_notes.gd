extends RichTextLabel
## Liner notes label for SV Jukebox
##
## Displays the liner notes for the album, or for the currently selected track
## if any is selected.

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
	_show_album_liner_notes()


func _show_album_liner_notes() -> void:
	if ui_controller == null:
		push_error("Selected liner notes label does not have a UI Controller set, so can't get album info.")
		return
	
	var album := ui_controller.get_album()
	
	if album == null:
		push_error("UI Controller did not have an album for liner notes label. Text will not be updated.")
		return
	
	text = album.liner_notes
	scroll_to_line(0)


# Signal connection
func _on_ui_controller_track_selected(track: TrackInfo) -> void:
	if track == null:
		_show_album_liner_notes()
		return
	
	text = track.liner_notes
	scroll_to_line(0)


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
