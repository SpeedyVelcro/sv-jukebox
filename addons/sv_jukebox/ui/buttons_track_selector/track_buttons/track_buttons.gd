extends HBoxContainer
## Row of buttons for a music track
##
## Row of buttons for interacting with a specific music track. Used by
## SVJukeboxButtonsTrackSelector.

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController
## Set to this track's position in the album.
@export var track_number: int = 0:
	set(value):
		track_number = value
		_update_track_button_text()
	get:
		return track_number
## Info of the track these buttons control.
@export var track_id: String:
	set(value):
		track_id = value
		_update_track_button_text()
	get:
		return track_id

@export_group("Functionality")
## Text to display when a track is locked, provided
## [member SVJukeboxUIController.respect_track_lock_status] is [code]true[/code].
## This is displayed in place of the track's title, so it will come after the
## track number if [member number_track_name] is [code]true[/code].
@export var locked_track_text := "???":
	set(value):
		locked_track_text = value
		_update_track_button_text()
	get():
		return locked_track_text
## Set to true to display a number before the name of each track.
@export var number_track_name := true:
	set(value):
		number_track_name = value
		_update_track_button_text()
	get:
		return number_track_name
## Format to use for the number if [member number_track_name] is [code]true[/code]. This
## should include the space separating it from the track name assuming you want
## one.
##
## See [url=https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html]GDScript format strings[/url]
## for the expected format. The string will be formatted with a single integer
## (the track number).
##
## Examples of useful format strings include [code]"%d. "[/code], [code]"%d - "[/code], or
## [code]"%d) "[/code].
@export var number_format_template := "%d. ":
	set(value):
		number_format_template = value
		_update_track_button_text()
	get:
		return number_format_template
## Set to true to allow double-clicking the track to play it.
@export var double_click_track_to_play := true
## Duration of window for double clicks to register if [member double_click_track_to_play]
## is [code]true[/code]
@export var double_click_time_secs := 0.5
## Set to true to show a separate play button before the track name button.
@export var show_play_button := true:
	set(value):
		show_play_button = value
		_update_play_button()
	get:
		return show_play_button
## Set to true to show a loop button (for looping this single track) before the
## track name button, but after the play button if it is present.
@export var show_loop_button := true:
	set(value):
		show_loop_button = value
		_update_loop_button()
	get:
		return show_loop_button

@export_group("Icons")
## Icon to display on the play button if [member show_play_button] is [code]true[/code].
@export var play_button_icon: Texture2D:
	set(value):
		play_button_icon = value
		_update_play_button()
	get:
		return play_button_icon
## Icon to display on the loop button if [member show_loop_button] is [code]true[/code].
@export var loop_button_icon: Texture2D:
	set(value):
		loop_button_icon = value
		_update_loop_button()
	get:
		return loop_button_icon

@onready var _play_button_container: Control = $AspectRatioContainer
@onready var _loop_button_container: Control = $AspectRatioContainer2
@onready var _play_button: Button = $AspectRatioContainer/PlayButton
@onready var _loop_button: Button = $AspectRatioContainer2/LoopButton
@onready var _track_button: Button = $TrackButton
@onready var _double_click_timer: Timer = $DoubleClickTimer

var _in_double_click_window := false


# Override
func _ready() -> void:
	_update_all()
	_connect_signals()
	
	if _is_track_locked():
		_lock_buttons()


func _update_all() -> void:
	_update_track_button_text()
	_update_play_button()
	_update_loop_button()


func _update_track_button_text() -> void:
	if _track_button == null:
		return
	
	_track_button.text = _generate_track_button_text()


func _generate_track_button_text() -> String:
	var track_info := _get_track_info()
	var title: String
	
	if track_info == null:
		title = "Undefined"
	
	title = locked_track_text if _is_track_locked() else track_info.title
	
	if not number_track_name:
		return title
	
	return (number_format_template % track_number) + title


func _update_play_button() -> void:
	if _play_button == null or _play_button_container == null:
		return
	
	if not show_play_button:
		_play_button_container.visible = false
		return
	
	_play_button_container.visible = true
	_play_button.icon = play_button_icon


func _update_loop_button() -> void:
	if _loop_button == null or _loop_button_container == null:
		return
	
	if not show_loop_button:
		_loop_button_container.visible = false
		return
	
	_loop_button_container.visible = true
	_loop_button.icon = loop_button_icon


func _get_track_info() -> TrackInfo:
	if ui_controller == null:
		push_error("SV Jukebox UI controller not set for track buttons.")
		return
	
	var album := ui_controller.get_album()
	
	return album.get_track_info(track_id)


func _is_track_locked() -> bool:
	if ui_controller == null:
		push_error("SV Jukebox UI controller not set for track buttons.")
		return false
	
	return SVJukebox.is_locked(track_id) if ui_controller.respect_track_lock_status else false


func _lock_buttons() -> void:
	# No child null checks; never called before ready.
	
	_play_button.disabled = true
	_loop_button.disabled = true
	_track_button.disabled = true
	_update_track_button_text()


func _unlock_buttons() -> void:
	_play_button.disabled = false
	_loop_button.disabled = false
	_track_button.disabled = false
	_update_track_button_text()


func _connect_signals() -> void:
	if not SVJukebox.unlocked.is_connected(_on_sv_jukebox_unlocked):
		SVJukebox.unlocked.connect(_on_sv_jukebox_unlocked)
	
	if not SVJukebox.unlock_removed.is_connected(_on_sv_jukebox_unlock_removed):
		SVJukebox.unlock_removed.connect(_on_sv_jukebox_unlock_removed)


func _disconnect_signals() -> void:
	if SVJukebox.unlocked.is_connected(_on_sv_jukebox_unlocked):
		SVJukebox.unlocked.disconnect(_on_sv_jukebox_unlocked)
	
	if SVJukebox.unlock_removed.is_connected(_on_sv_jukebox_unlock_removed):
		SVJukebox.unlock_removed.disconnect(_on_sv_jukebox_unlock_removed)


# Signal connection
func _on_play_button_pressed() -> void:
	if ui_controller == null:
		push_error("SV Jukebox UI controller not set for track buttons.")
		return
	
	const SELECT := true
	ui_controller.play_track(track_id, SELECT)


# Signal connection
func _on_loop_button_pressed() -> void:
	if ui_controller == null:
		push_error("SV Jukebox UI controller not set for track buttons.")
		return
	
	ui_controller.loop_one()
	
	const SELECT := true
	ui_controller.play_track(track_id, SELECT)


# Signal connection
func _on_track_button_pressed() -> void:
	if ui_controller == null:
		push_error("SV Jukebox UI controller not set for track buttons.")
		return
	
	if _in_double_click_window:
		const SELECT := true
		ui_controller.play_track(track_id, SELECT)
		_double_click_timer.stop()
		_in_double_click_window = false
		return
	
	ui_controller.select_track(track_id)
	
	_double_click_timer.start(double_click_time_secs)
	_in_double_click_window = true


# Signal connection
func _on_double_click_timer_timeout() -> void:
	_in_double_click_window = false


# Signal connection
func _on_sv_jukebox_unlocked(id: String) -> void:
	if id != track_id:
		return
	
	_unlock_buttons()


# Signal connection
func _on_sv_jukebox_unlock_removed(id: String) -> void:
	if id != track_id:
		return
	
	_lock_buttons()


# Override
func _exit_tree() -> void:
	_disconnect_signals()
