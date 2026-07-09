extends VBoxContainer
## Lists an album's tracks with selectable buttons.
##
## Button-selectable user interface for displaying all the track in an album
## for the given [SVJukeboxUIController]

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController:
	set(value):
		ui_controller = value
		update_album()
	get():
		return ui_controller

@export_group("Title Labels")
## [LabelSettings] for styling disc titles.
@export var disc_title_label_settings: LabelSettings:
	set(value):
		disc_title_label_settings = value
		for label in _disc_title_labels:
			label.label_settings = value
	get():
		return disc_title_label_settings

## [LabelSettings] for styling side titles.
@export var side_title_label_settings: LabelSettings:
	set(value):
		side_title_label_settings = value
		for label in _side_title_labels:
			label.label_settings = value
	get():
		return disc_title_label_settings

@export_group("Track Buttons")
## Set to true to display a number before the name of each track.
@export var number_track_name := true:
	set(value):
		number_track_name = value
		for track_buttons in _track_buttons_nodes:
			track_buttons.number_track_name = number_track_name
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
		for track_buttons in _track_buttons_nodes:
			track_buttons.number_format_template = number_format_template
	get:
		return number_format_template
## Set to true to allow double-clicking the track to play it.
@export var double_click_track_to_play := true:
	set(value):
		double_click_track_to_play = value
		for track_buttons in _track_buttons_nodes:
			track_buttons.double_click_track_to_play = double_click_track_to_play
	get:
		return double_click_track_to_play
## Duration of window for double clicks to register if [member double_click_track_to_play]
## is [code]true[/code]
@export var double_click_time_secs := 0.5:
	set(value):
		double_click_time_secs = value
		for track_buttons in _track_buttons_nodes:
			track_buttons.double_click_time_secs = double_click_time_secs
	get:
		return double_click_time_secs
## Set to true to show a separate play button before the track name button.
@export var show_play_button := true:
	set(value):
		show_play_button = value
		for track_buttons in _track_buttons_nodes:
			track_buttons.show_play_button = show_play_button
	get:
		return show_play_button
## Set to true to show a loop button (for looping this single track) before the
## track name button, but after the play button if it is present.
@export var show_loop_button := true:
	set(value):
		show_loop_button = value
		for track_buttons in _track_buttons_nodes:
			track_buttons.show_loop_button = show_loop_button
	get:
		return show_loop_button

## Icon to display on the play button if [member show_play_button] is [code]true[/code].
@export var play_button_icon: Texture2D:
	set(value):
		play_button_icon = value
		for track_buttons in _track_buttons_nodes:
			track_buttons.play_button_icon = value
	get:
		return play_button_icon
## Icon to display on the loop button if [member show_loop_button] is [code]true[/code].
@export var loop_button_icon: Texture2D:
	set(value):
		loop_button_icon = value
		for track_buttons in _track_buttons_nodes:
			track_buttons.loop_button_icon = loop_button_icon
	get:
		return loop_button_icon

var _track_buttons_scene: PackedScene = preload("res://addons/sv_jukebox/ui/buttons_track_selector/track_buttons/track_buttons.tscn")

var _ready_called := false
var _disc_title_labels: Array[Label] = []
var _side_title_labels: Array[Label] = []
var _track_buttons_nodes: Array[Control] = []


# Override
func _ready() -> void:
	_ready_called = true
	update_album()


## Call after making changes to the album assigned on the [member ui_controller].
## Automatically called when [member ui_controller] is changed and on ready.
func update_album() -> void:
	if not _ready_called or not is_inside_tree():
		return
	
	if ui_controller == null:
		push_error("UI controller not set on buttons track selector.")
		return
	
	var album := ui_controller.get_album()
	
	if album == null:
		push_error("Buttons track selector cannot update_album() as there is no album set on the UI controller.")
		return
	
	_clear()
	
	var show_disc_titles := album.discs.size() > 1
	var disc_number: int = 0
	
	for disc in album.discs:
		disc_number += 1
		
		var show_side_titles := not (disc.side_a.is_empty() or disc.side_b.is_empty())
		
		if show_disc_titles:
			_add_disc_title(disc, disc_number)
		
		if show_side_titles:
			_add_side_a_title(disc)
		
		_add_all_tracks_from_disc_side(disc.side_a)
		
		if show_side_titles:
			_add_side_b_title(disc)
		
		_add_all_tracks_from_disc_side(disc.side_b)
	
	# TODO: anything else?


func _add_disc_title(disc: AlbumDiscInfo, disc_number: int) -> void:
	var label := Label.new()
	
	label.text = disc.get_title_format_string() % disc_number
	label.label_settings = disc_title_label_settings
	
	_disc_title_labels.append(label)
	add_child(label)


func _add_side_title(disc: AlbumDiscInfo, side_a: bool) -> void:
	var label := Label.new()
	
	label.text = disc.get_side_a_title() if side_a else disc.get_side_b_title()
	label.label_settings = side_title_label_settings
	
	_side_title_labels.append(label)
	add_child(label)


func _add_side_a_title(disc: AlbumDiscInfo) -> void:
	_add_side_title(disc, true)


func _add_side_b_title(disc: AlbumDiscInfo) -> void:
	_add_side_title(disc, false)


func _add_track_buttons(track_id: String, track_number: int) -> void:
	var track_buttons := _track_buttons_scene.instantiate()
	
	track_buttons.track_id = track_id
	track_buttons.track_number = track_number
	
	# Pass-through values
	track_buttons.ui_controller = ui_controller
	track_buttons.number_track_name = number_track_name
	track_buttons.number_format_template = number_format_template
	track_buttons.double_click_track_to_play = double_click_track_to_play
	track_buttons.double_click_time_secs = double_click_time_secs
	track_buttons.show_play_button = show_play_button
	track_buttons.show_loop_button = show_loop_button
	track_buttons.play_button_icon = play_button_icon
	track_buttons.loop_button_icon = loop_button_icon
	
	_track_buttons_nodes.append(track_buttons)
	add_child(track_buttons)


func _add_all_tracks_from_disc_side(disc_side: Array[TrackInfo]) -> void:
	var next_track_number := 1
	for track in disc_side:
		_add_track_buttons(track.id, next_track_number)
		next_track_number += 1


func _clear() -> void:
	for child in get_children():
		remove_child(child)
	
	_disc_title_labels = []
	_side_title_labels = []
	_track_buttons_nodes = []
