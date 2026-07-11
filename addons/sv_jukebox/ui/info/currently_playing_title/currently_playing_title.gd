extends Label
## Currently playing title label for SV Jukebox
##
## Displays the title of the currently playing track, falling back on a default
## string. Optionally, it can also display the name of the album.

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController:
	set(value):
		_disconnect_controller_signals()
		ui_controller = value
		_connect_controller_signals()
		_update_text()
	get():
		return ui_controller

## Display both the album and the track (e.g. as "Cool Game OST - Boss Music").
## If this is [code]false[/code], only the track is displayed. See
## [member album_and_title_format_string] for the exact formatting when this is
## [code]true[/code].
@export var display_album := true:
	set(value):
		display_album = value
		_update_text()
	get():
		return display_album

## How to format the album and track title when a track is playing and
## [member display_album] is [code]true[/code]. This is passed through
## [method String.format], and will look for the [code]{album}[/code] and
## [code]{track}[/code] placeholders, so make sure you include these.
@export var album_and_title_format_string := "{album} - {track}":
	set(value):
		album_and_title_format_string = value
		_update_text()
	get():
		return album_and_title_format_string

## Default title to display when no track is playing. Replaces the entire label
## text, even if [member display_album] is [code]true[/code].
@export var default_title := "---":
	set(value):
		default_title = value
		_update_text()
	get():
		return default_title


var _readied := false


# Override
func _ready() -> void:
	_readied = true
	_update_text()


func _update_text() -> void:
	if ui_controller == null:
		# Fail silently if not ready. This can be called if other export variables
		# are set before the ui_controller, which is normal.
		if not _readied:
			push_error("UI controller not set on currently playing title label. Text will be default.")
		text = default_title
		return
	
	var track = ui_controller.get_playing_track_info()
	var album := ui_controller.get_playing_album_info()
	
	if track == null:
		text = default_title
		return
	
	if track.title.is_empty():
		push_error("Track did not have a title for currently playing title label. Default title will be displayed.")
		text = default_title
		return
	
	var display_both := display_album
	
	if display_both and (album == null):
		push_error("UI Controller did not have an album for currently playing title label. Only track title will be displayed.")
		display_both = false
	
	if display_both and (album.title.is_empty()):
		push_error("Album did not have a title for currently playing title label. Only track title will be displayed.")
		display_both = false
	
	if display_both:
		text = album_and_title_format_string.format({"album": album.title, "track": track.title})
	else:
		text = track.title


# Signal connection
func _on_ui_controller_playing_track(track: TrackInfo) -> void:
	_update_text()


# Signal connection
func _on_ui_controller_stopping() -> void:
	_update_text()


func _connect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if not ui_controller.playing_track.is_connected(_on_ui_controller_playing_track):
		ui_controller.playing_track.connect(_on_ui_controller_playing_track)
	
	if not ui_controller.stopping.is_connected(_on_ui_controller_stopping):
		ui_controller.stopping.connect(_on_ui_controller_stopping)


func _disconnect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if ui_controller.playing_track.is_connected(_on_ui_controller_playing_track):
		ui_controller.playing_track.disconnect(_on_ui_controller_playing_track)
	
	if ui_controller.stopping.is_connected(_on_ui_controller_stopping):
		ui_controller.stopping.disconnect(_on_ui_controller_stopping)


# Override
func _exit_tree() -> void:
	_disconnect_controller_signals()
