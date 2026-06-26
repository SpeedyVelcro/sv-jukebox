class_name SVJukeboxUIController
extends Node
## Controller node for SV Jukebox UI scenes.
##
## This node mediates between the various SV Jukebox UI Scenes and the
## SVJukebox autoload to play music and display album and track info.

## How to loop playing tracks if at all. Similar to the behaviour of looping
## in common media players.
enum LoopBehavior {
	## Track will not loop
	NONE,
	## Loop the album (i.e. after the last track, play the first track).
	LOOP,
	## Loop the currently playing track.
	LOOP_ONE
}

# TODO: rename album to album_override, as it would be a more accurate name
## Album to play and navigate using this controller. If this is set to null, the
## album loaded by the SVJukebox autoload on game start will be used instead.
@export var album : AlbumInfo = null

## Emitted when a track is selected or deselected with [method select_track]. [param track]
## includes the track, and is null if a track was deselected.
signal track_selected(track: TrackInfo)
## Emitted when shuffle is turned on or off
signal shuffle_changed(to: bool)
## Emitted when shuffle is enabled
signal shuffle_enabled
## Emitted when shuffle is disabled
signal shuffle_disabled
## Emitted when loop behavior is changed
signal loop_behavior_changed(to: LoopBehavior)
## Emitted when loop behavior is changed to normal looping
signal loop_enabled
## Emitted when loop behavior is changed to looping a single track
signal loop_one_enabled
## Emitted when looping is disabled.
signal loop_disabled

var _selected_track_id := ""
var _playing_track_id := ""
var _loop: LoopBehavior = LoopBehavior.NONE
var _shuffle := false
var _queued_tracks: Array[String]
var _stream_is_linear = false


# Override
func _ready() -> void:
	_connect_jukebox_signals()


## Get the [TrackInfo] of the currently selected track. Returns null and
## pushes an error if no track is selected or the track doesn't exist. You
## can pass in an argument to suppress errors.
func get_selected_track_info(show_error := true) -> TrackInfo:
	if _selected_track_id.is_empty():
		if show_error:
			push_error("Tried to get selected track info but no track was selected.")
		return null
	
	return get_album().get_track_info(_selected_track_id, show_error)


## Gets the album. Differs from accessing [member album] directly as it falls
## back on the album provided by the SVJukebox autoload.
func get_album() -> AlbumInfo:
	if album == null:
		return SVJukebox.get_album()
	
	return album


## Selects the track with given ID if it exists. If the track doesn't exist on
## the album, an error will be pushed and track selection won't be changed. Call with
## an empty string to deselect.
func select_track(id: String) -> void:
	if id == _selected_track_id:
		return # To avoid repeat signals
	
	if id.is_empty():
		_selected_track_id = ""
		track_selected.emit(null)
		return
	
	var show_errors := true
	var track_info := get_album().get_track_info(id, show_errors)
	
	if track_info == null:
		push_error("Could not select track with id %s as it does not appear on album." % id)
		return
	
	_selected_track_id = id
	track_selected.emit(track_info)


## Equivalent to calling [method select_track] with an empty [String].
func deselect_track() -> void:
	select_track("")


## Play the given track. By default, the track will also be selected. Pass in
## [param select] to change this behavior.
func play_track(id: String, select := true, queue_following := true, force := false) -> void:
	if _playing_track_id == id and not force:
		return
	
	var tracks: Array[TrackInfo] = get_album().get_tracks_from(id)
	if tracks.is_empty():
		push_error("Jukebox UI controller failed to play track with ID %s." % id)
		return
	
	var track := tracks.pop_front()
	
	var use_linear: bool = false
	if track.looping_stream_path.is_empty():
		use_linear = true
	if _loop != LoopBehavior.LOOP_ONE and not track.linear_stream_path.is_empty():
		use_linear = true
	
	var stream_path: String = track.linear_stream_path if use_linear else track.looping_stream_path
	if stream_path == "":
		push_error("Track with id %s does not have any streams set, so UI controller cannot play it." % id)
		return
	
	var stream_untyped = load(stream_path)
	if stream_untyped == null or stream_untyped is not AudioStream:
		push_error("Failed to load audio stream of track with id %s at path %s." % [id, stream_path])
		return
	var stream: AudioStream = stream_untyped
	
	if not SVJukebox.play_stream(stream, id): # TODO: Transitions are configurable with export variables
		push_error("Failed to play audio stream.")
		return
	
	_playing_track_id = id
	_stream_is_linear = use_linear
	if select:
		select_track(id)
	
	if queue_following:
		_queued_tracks.assign(tracks.map(func (t) -> String: return t.id))
		if _shuffle:
			_queued_tracks.shuffle()


## Pause playback if currently playing a track.
func pause() -> void:
	if _playing_track_id.is_empty():
		return
	
	SVJukebox.pause() # TODO: Transitions are configurable with export variables


## Stop playback of the current track and clear it as the "currently played"
## track. The track will still be selected, so you can resume playback from the
## beginning and display info. You can optionally pass in [param keep_selection]
## to change this behavior.
func stop(keep_selection := true) -> void:
	if _playing_track_id.is_empty():
		return
	
	SVJukebox.stop() # TODO: Transitions are configurable with export variables
	
	if not keep_selection:
		deselect_track()


## Sets looping behavior to the given [enum LoopBehavior]
func set_loop_behavior(behavior: LoopBehavior) -> void:
	if _loop == behavior:
		return # So signals aren't un-necessarily emitted and we don't waste resources relaoding audio tracks etc.
	
	var previous_behavior = _loop
	_loop = behavior
	
	match behavior:
		LoopBehavior.NONE:
			_swap_to_linear_stream_if_available()
			loop_disabled.emit()
		LoopBehavior.LOOP:
			_swap_to_linear_stream_if_available()
			loop_enabled.emit()
		LoopBehavior.LOOP_ONE:
			_swap_to_looping_stream_if_available()
			loop_one_enabled.emit()
	
	loop_behavior_changed.emit(behavior)


## Sets looping behavior to loop the entire album.
func loop() -> void:
	set_loop_behavior(LoopBehavior.LOOP)


## Sets looping behavior to loop a single track.
func loop_one() -> void:
	set_loop_behavior(LoopBehavior.LOOP_ONE)


## Turn off looping behavior.
func disable_loop() -> void:
	set_loop_behavior(LoopBehavior.NONE)


## Turns shuffle on or off.
func set_shuffle_behavior(shuffle: bool):
	if shuffle == _shuffle:
		return # Avoid pointlessly reshuffling, etc.
	
	_shuffle = shuffle
	
	if shuffle:
		_queued_tracks.shuffle()
	else:
		_queued_tracks = get_album() \
				.get_tracks_from(_playing_track_id) \
				.map(func(t): return t.id)
		_queued_tracks.pop_front() # TODO: highly inefficient. Might be better if queued tracks was reversed
	
	shuffle_changed.emit(shuffle)
	if shuffle:
		shuffle_enabled.emit()
	else:
		shuffle_disabled.emit()


func _swap_to_linear_stream_if_available() -> void:
	if _playing_track_id == "":
		return
	
	if _stream_is_linear:
		return # Already linear
	
	var playing_track_info = get_album().get_track_info(_playing_track_id)
	
	if playing_track_info.linear_stream_path.is_empty():
		return
	
	var stream_untyped = load(playing_track_info.linear_stream_path)
	if stream_untyped == null or stream_untyped is not AudioStream:
		push_error("Failed to load linear stream for track id %s." % _playing_track_id)
		return
	var stream: AudioStream = stream_untyped
	
	SVJukebox.swap_stream(stream) # TODO: add offset property to TrackInfo and use it here as optional argument
	_stream_is_linear = true


func _swap_to_looping_stream_if_available() -> void:
	if _playing_track_id == "":
		return
	
	if not _stream_is_linear:
		return # Already looping
	
	var playing_track_info = get_album().get_track_info(_playing_track_id)
	
	if playing_track_info.looping_stream_path.is_empty():
		return
	
	var stream_untyped = load(playing_track_info.looping_stream_path)
	if stream_untyped == null or stream_untyped is not AudioStream:
		push_error("Failed to load looping stream for track id %s." % _playing_track_id)
		return
	var stream: AudioStream = stream_untyped
	
	SVJukebox.swap_stream(stream) # TODO: add offset property to TrackInfo and use it here as optional argument
	_stream_is_linear = false


# Signal connection
func _on_sv_jukebox_loop_complete(id: String) -> void:
	if id.is_empty() or id != _playing_track_id:
		return
	
	match _loop:
		LoopBehavior.NONE:
			if _queued_tracks.is_empty():
				# TODO: configurable transition
				const KEEP_SELECTION := true
				stop(KEEP_SELECTION)
			else:
				var next := _queued_tracks.pop_front()
				const SELECT := false
				const QUEUE_FOLLOWING := false
				play_track(next, SELECT, QUEUE_FOLLOWING)
		LoopBehavior.LOOP:
			if _queued_tracks.is_empty():
				const INCLUDE_HIDDEN := false
				_queued_tracks.assign(album.get_all_tracks(INCLUDE_HIDDEN).map(func(t): return t.id))
			var next := _queued_tracks.pop_front()
			const SELECT := false
			const QUEUE_FOLLOWING := false
			play_track(next, SELECT, QUEUE_FOLLOWING)
		LoopBehavior.LOOP_ONE:
			pass # No action necessary; track is already looping.


# Signal connection
func _on_sv_jukebox_track_finished(id: String) -> void:
	if id.is_empty() or id != _playing_track_id:
		return
	
	match _loop:
		LoopBehavior.NONE:
			_playing_track_id = ""
			if not _queued_tracks.is_empty():
				var next := _queued_tracks.pop_front()
				const SELECT := false
				const QUEUE_FOLLOWING := false
				play_track(next, SELECT, QUEUE_FOLLOWING)
		LoopBehavior.LOOP:
			if _queued_tracks.is_empty():
				const INCLUDE_HIDDEN := false
				_queued_tracks.assign(album.get_all_tracks(INCLUDE_HIDDEN).map(func(t): return t.id))
			var next := _queued_tracks.pop_front()
			const SELECT := false
			const QUEUE_FOLLOWING := false
			play_track(next, SELECT, QUEUE_FOLLOWING)
		LoopBehavior.LOOP_ONE:
			const SELECT := false
			const QUEUE_FOLLOWING := false
			const FORCE := true # Needs to be forced as ID is same
			play_track(_playing_track_id, SELECT, QUEUE_FOLLOWING, FORCE)


func _connect_jukebox_signals() -> void:
	SVJukebox.loop_complete.connect(_on_sv_jukebox_loop_complete)
	SVJukebox.track_finished.connect(_on_sv_jukebox_track_finished)


func _disconnect_jukebox_signals() -> void:
	SVJukebox.loop_complete.disconnect(_on_sv_jukebox_loop_complete)
	SVJukebox.track_finished.disconnect(_on_sv_jukebox_track_finished)


# Override
func _exit_tree() -> void:
	_disconnect_jukebox_signals()
