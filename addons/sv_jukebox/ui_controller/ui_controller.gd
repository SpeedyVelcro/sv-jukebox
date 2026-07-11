class_name SVJukeboxUIController
extends Node
## Controller node for SV Jukebox UI scenes.
##
## This node mediates between the various SV Jukebox UI Scenes and the
## SVJukebox autoload to play music and display album and track info.
# TODO: Spaghetti code mess, needs refactoring. Although the contract is fairly
# clear so maybe unit testing would be a good enough stopgap.
# TODO: There is an inevitable bug remaining where an error will occur if a track
# is locked while it is queued, and playback continues to that track. Not super
# dangerous since it will just stop playback and log the error to the console,
# and this is an exceedingly unlikely scenario anyway since there is almost never
# a good reason to lock tracks. Still, I should fix it by removing an id from
# the queued tracks when it gets locked.

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

## Time window at the beginning of each track where the [method skip_backward]
## method skips to the previous track instead of the beginning of the current
## track (provided there is actually a previous track to skip to).
@export var skip_backward_window_secs: float = 5.0

## When [code]true[/code], will block locked tracks from playback and selection
## (you must first unlock them with [method SVJukebox.unlock]).
@export var respect_track_lock_status := true

## Emitted when a track is being played with [method play_track].
signal playing_track(track: TrackInfo)
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
## Emitted when pausing a track
signal pausing
## Emitted when resuming a previously paused track.
signal resuming
## Emitting when stopping playback, either with a [method stop] call, or because
## a track has finished without looping set and no further tracks are queued.
##
## This signal is emitted AFTER all the relevant variables have been applied
## (so, for example, [method get_playing_track_info] will return null), but
## there may still be a fadeout to complete based on transition settings, hence
## the name "stopping".
signal stopping

var _selected_track_id := ""
var _playing_track_id := ""
var _loop: LoopBehavior = LoopBehavior.NONE
var _shuffle := false
var _queued_tracks: Array[String]
## Tracks queued in this array are considered part of the next loop and will not
## be played if looping is off.
var _queued_tracks_next_loop: Array[String]
var _shuffle_history: Array[String]
var _stream_is_linear = false
var _is_seeking := false
var _seek: float = 0.0


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


## Get the [TrackInfo] of the currently playing track. Returns null if no track
## is playing, and returns null AND pushes an error if the track doesn't exist.
## You can pass in an argument to suppress errors.
func get_playing_track_info(show_error := true) -> TrackInfo:
	if _playing_track_id.is_empty():
		return null
	
	return get_album().get_track_info(_playing_track_id, show_error)


## Gets the [AlbumInfo] of the album of the currently playing track.
func get_playing_album_info() -> AlbumInfo:
	# Currently, because the UI controller only supports a single album, this
	# is the same as [method get_album]. In future, this might be different if
	# the jukebox UI is updated to support multiple albums.
	return get_album()


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


## Plays the entire album starting from the first track (or a random track if
## shuffle is on).
func play_album() -> void:
	var id: String
	if respect_track_lock_status:
		var tracks := get_album().get_all_tracks()
		var track_index: int = tracks.find_custom(func (t) -> bool: return SVJukebox.is_unlocked(t.id))
		if track_index < 0:
			push_error("Cannot play album while there are no tracks unlocked if UI controller's respect_track_unlock_status is true.")
			return
		id = tracks[track_index].id
	else:
		id = get_album().get_first_track().id
	
	const SELECT := false
	const QUEUE_FOLLOWING := true
	const FORCE_SAME := true
	play_track(id, SELECT, QUEUE_FOLLOWING, FORCE_SAME)


## Play the given track. By default, the track will also be selected. Pass in
## [param select] to change this behavior.
##
## [param queue_following] basically just clears the queue (and shuffle history if
## applicable) and repopulates the queue with the following tracks in the album
## (or a shuffled playlist if applicable). I might rename this at some point to
## something more descriptive, like "new_playlist" or something, idk.
##
## [param force_same] forces playback even if the [param id] is the some as the
## currently playing track (this will likely just start playback from the
## beginning of the same track again).
##
## [param force_locked] forces playback even if track with given [param id] is
## locked. Queued tracks will still be filtered though (this is all provided that
## [member respect_track_lock_status] is true).
func play_track(id: String, select := true, queue_following := true, force_same := false, force_locked := false) -> void:
	if _playing_track_id == id and not force_same:
		return
	
	if force_locked or (respect_track_lock_status and SVJukebox.is_locked(id)):
		push_error("UI controller cannot play locked track %s while respect_track_lock_status is true." % id)
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
	
	if queue_following:
		_shuffle_history.clear()
		if _shuffle:
			const INCLUDE_HIDDEN := false
			_queued_tracks.assign(get_album() \
					.get_all_tracks(INCLUDE_HIDDEN) \
					.filter(func (t) -> bool: return t.id != id) \
					.map(func(t): return t.id))
			_queued_tracks.shuffle()
		else:
			_queued_tracks.assign(tracks.map(func (t) -> String: return t.id))
	
	if respect_track_lock_status:
		_queued_tracks.assign(_queued_tracks.filter(func (id) -> bool: return SVJukebox.is_unlocked(id)))
	
	_playing_track_id = id
	_stream_is_linear = use_linear
	if select:
		select_track(id)
	
	playing_track.emit(track)


## Pause playback if currently playing a track.
func pause() -> void:
	if _playing_track_id.is_empty():
		return
	
	SVJukebox.pause() # TODO: Transitions are configurable with export variables
	pausing.emit()


## Resume playback previously paused with [method pause].
func resume() -> void:
	if _playing_track_id.is_empty():
		return
	
	SVJukebox.resume() # TODO: Transitions are configurable with export variables
	resuming.emit()


## Stop playback of the current track and clear it as the "currently played"
## track. The track will still be selected, so you can resume playback from the
## beginning and display info. You can optionally pass in [param keep_selection]
## to change this behavior.
func stop(keep_selection := true) -> void:
	if _playing_track_id.is_empty():
		return
	
	SVJukebox.stop() # TODO: Transitions are configurable with export variables
	_playing_track_id = ""
	stopping.emit()
	
	if not keep_selection:
		deselect_track()


## Skips backwards to the beginning of the current track.
func skip_to_track_beginning() -> void:
	if _playing_track_id.is_empty():
		return
	
	const SELECT := false
	const QUEUE_FOLLOWING := false
	const FORCE_SAME := true # Needs to be forced as ID might be the same in the case of loop one.
	const FORCE_LOCKED := true
	play_track(_playing_track_id, SELECT, QUEUE_FOLLOWING, FORCE_SAME, FORCE_LOCKED)


## If there were previously tracks queued before this one (or looping is enabled),
## this method skips to the previous track. Otherwise does nothing.
##
## In the case of looping being set to loop one, the previous track is actually
## the same track, so this skips to the beginning of the track instead as that
## is functionally equivalent.
func skip_to_previous_track() -> void:
	if _playing_track_id.is_empty():
		return
	
	if _loop == LoopBehavior.LOOP_ONE:
		skip_to_track_beginning()
		return
	
	if _shuffle:
		if _shuffle_history.is_empty():
			if _loop == LoopBehavior.LOOP:
				_shuffle_history.assign(get_album().get_all_tracks().map(func(t): return t.id))
				_shuffle_history.shuffle()
				_queued_tracks_next_loop = [_playing_track_id] + _queued_tracks.duplicate()
				_queued_tracks.clear()
			else:
				return
		else:
			_queued_tracks.push_front(_playing_track_id)
		
		const SELECT := false
		const QUEUE_FOLLOWING := false
		play_track(_shuffle_history.pop_back(), SELECT, QUEUE_FOLLOWING)
		return
	
	if get_album().is_first_track(_playing_track_id):
		if _loop == LoopBehavior.LOOP:
			const SELECT := false
			const QUEUE_FOLLOWING := true # No info to retain because we are unshuffled, and we want to clear the queue as we're going to a previous loop
			play_track(get_album().get_last_track().id, SELECT, QUEUE_FOLLOWING)
		return
	
	const SELECT := false
	const QUEUE_FOLLOWING := true # No info to retain because we are unshuffled; convenient as it saves having to prepend current track to queue
	play_track(get_album().get_previous_track(_playing_track_id).id, SELECT, QUEUE_FOLLOWING)


## Skips backwards by typical rules for media players. Specifically, skips to
## previous track if there is one and we are inside the window defined by
## [member skip_backward_window_secs]. Otherwise skips to beginning.
func skip_backward() -> void:
	if SVJukebox.get_playback_position() > skip_backward_window_secs:
		skip_to_track_beginning()
		return
	
	if _loop == LoopBehavior.LOOP or _loop == LoopBehavior.LOOP_ONE:
		skip_to_previous_track()
		return
	
	if _shuffle and not _shuffle_history.is_empty():
		skip_to_previous_track()
		return
	
	if (not _shuffle) and not get_album().is_first_track(_playing_track_id):
		skip_to_previous_track()
		return
	
	# There is no previous track.
	skip_to_track_beginning()


## If a track is currently playing and there is something queued up (or looping is
## enabled), this method skips to the next track. Otherwise does nothing.
##
## In the case of looping being set to loop one, the next track is actually
## the same track, so this skips backward to the beginning of the track instead as that
## is functionally equivalent.
func skip_to_next_track() -> void:
	if _playing_track_id.is_empty():
		return
	
	if _loop == LoopBehavior.LOOP_ONE:
		skip_to_track_beginning()
		return
	
	if _queued_tracks.is_empty():
		if _loop == LoopBehavior.LOOP:
			play_album()
		return
	
	var next := _queued_tracks.pop_front()
	const SELECT := false
	const QUEUE_FOLLOWING := false
	play_track(next, SELECT, QUEUE_FOLLOWING)


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


## Returns the current loop behavior, as set by [method set_loop_behavior] or any
## of the other loop methods.
func get_loop_behavior() -> LoopBehavior:
	return _loop


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
func set_shuffle_behavior(shuffle: bool) -> void:
	if shuffle == _shuffle:
		return # Avoid pointlessly reshuffling, etc.
	
	_shuffle = shuffle
	
	if shuffle:
		const INCLUDE_HIDDEN := false
		_queued_tracks.assign(get_album() \
				.get_all_tracks(INCLUDE_HIDDEN) \
				.filter(func (t) -> bool: return t.id != _playing_track_id) \
				.map(func(t): return t.id))
		_queued_tracks.shuffle()
	else:
		_queued_tracks.assign(get_album() \
				.get_tracks_from(_playing_track_id) \
				.map(func(t): return t.id))
		_queued_tracks.pop_front() # TODO: highly inefficient. Might be better if queued tracks was reversed
	
	if respect_track_lock_status:
		_queued_tracks.assign(_queued_tracks.filter(func (id) -> bool: return SVJukebox.is_unlocked(id)))
	
	shuffle_changed.emit(shuffle)
	if shuffle:
		shuffle_enabled.emit()
	else:
		shuffle_disabled.emit()


## Returns true if shuffle is on.
func is_shuffle_on() -> bool:
	return _shuffle


## Returns true if there is a track after the currently queued track; either
## a literal next track or through looping. With looping set to loop one, this
## is a little ambiguous as the next track is the same track, so you can specify
## whether you want that to count as having a track queued with [param including_loop_one].
func is_any_track_queued(including_loop_one := true) -> bool:
	if _playing_track_id.is_empty():
		return false
	
	return not _queued_tracks.is_empty() \
			or _loop == LoopBehavior.LOOP \
			or (including_loop_one and _loop == LoopBehavior.LOOP_ONE)


## Starts seeking through the currently playing track. This is for "drag-and-hold"
## type seeking where the controls update continuously but you don't actually jump
## to the new location until you release the seek control. If you need to seek
## immediately, use the SVJukebox singleton directly instead.
func start_seek(value: float) -> void:
	_is_seeking = true
	_seek = value


## Update the timestamp while seeking. See [method start_seek].
func update_seek(value) -> void:
	if not _is_seeking:
		return
	
	_seek = value


## Ends the current seek and applies it (i.e. jumps playback to the new location).
## See [method start_seek].
func end_seek() -> void:
	if not _is_seeking:
		return
	
	_is_seeking = false
	
	SVJukebox.seek(_seek)


## Returns true if the user is currently using the UI to seek through the track.
## See [method start_seek].
func is_seeking() -> bool:
	return _is_seeking


## Gets seek position if currently [method is_seeking], falling back on playback
## or pause position of the current track, further falling back on zero.
func get_playback_or_seek_position() -> float:
	if not is_seeking():
		return SVJukebox.get_playback_position()
	
	return _seek


func _swap_to_linear_stream_if_available() -> void:
	if _playing_track_id.is_empty():
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
	if _playing_track_id.is_empty():
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
			if is_any_track_queued():
				skip_to_next_track()
			else:
				# TODO: configurable transition
				stop()
		LoopBehavior.LOOP:
			skip_to_next_track()
		LoopBehavior.LOOP_ONE:
			pass # No action necessary; track is already looping.


# Signal connection
func _on_sv_jukebox_track_finished(id: String) -> void:
	if id.is_empty() or id != _playing_track_id:
		return
	
	match _loop:
		LoopBehavior.NONE:
			if is_any_track_queued():
				skip_to_next_track()
			else:
				_playing_track_id = ""
				stopping.emit()
		LoopBehavior.LOOP, LoopBehavior.LOOP_ONE:
			skip_to_next_track()


func _connect_jukebox_signals() -> void:
	SVJukebox.loop_complete.connect(_on_sv_jukebox_loop_complete)
	SVJukebox.track_finished.connect(_on_sv_jukebox_track_finished)


func _disconnect_jukebox_signals() -> void:
	SVJukebox.loop_complete.disconnect(_on_sv_jukebox_loop_complete)
	SVJukebox.track_finished.disconnect(_on_sv_jukebox_track_finished)


# Override
func _exit_tree() -> void:
	_disconnect_jukebox_signals()
