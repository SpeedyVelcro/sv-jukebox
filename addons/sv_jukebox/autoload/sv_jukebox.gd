extends Node
## Autoload node for interacting with the SV Jukebox plugin.
##
## Autoloaded as SVJukebox. This singleton node provides methods for basic
## music playing functionality and managing music unlocks.
# TODO: Consider using AudioStreamPolyphonic instead of having multiple AudioStreamPlayers.

## How to transition between tracks when playing a new one with [method play].
enum TransitionType {
	## Instantly stop the current track and start the new one.
	INSTANT,
	## Fade the current track out, then start the new track instantly. Preferred
	## if your new track has an introduction.
	FADE_OUT,
	## Fade the current track out, then fade the new one in.
	FADE_OUT_IN,
	## Cross-fade between the two tracks.
	CROSS_FADE
}

var _album: AlbumInfo = null
var _players: Array[AudioStreamPlayer] = []
var _audio_stream_paths: Dictionary[String, String] = {} # [id, path]
var _unlocked_ids: Array[String]
var _always_unlocked_ids: Array[String]
var _current_id := ""
var _current_player: AudioStreamPlayer = null
# TODO: configurable max players
var _max_players := 10 # To stop an explosion of players when misusing SV Jukebox. Exceeding this will cause errors and incorrect behaviour though.
var _last_loop_count: int = 0

## Emitted when the current track finishes playing. Note that this does not
## include manually stopping or switching the track.
##
## This only emits for linear streams. For looping streams, connect to
## [signal loop_complete]
signal track_finished(id: String)
## Emitted roughly when the current track gets to the end of a loop, each time it
## gets to the end of a loop. Does not emit for linear streams. For linear streams,
## connect to [signal track_finished] instead.
signal loop_complete(id: String)
## Emitted when a track is unlocked.
signal unlocked(id: String)
## Emitted when a track unlock is removed i.e. the reverse of [signal unlocked]
## has happened.
signal unlock_removed(id: String)


# Override
func _ready() -> void:
	# TODO: Make initial number of players configurable
	
	var album_path := SVJukeboxProjectSettings.get_album_path()
	if not (album_path.is_absolute_path() or album_path.is_relative_path()):
		push_error("Album path %s is not a valid path. SV Jukebox will not be able to register any of its music." % album_path)
	else:
		var resource = load(album_path)
		if resource == null or resource is not AlbumInfo:
			push_error("Album at path %s does not appear to either exist or be a valid AlbumInfo resource. SV Jukebox will not be able to register any of its music." % album_path)
		else:
			_album = resource
			for track in _album.get_all_tracks():
				register(track.id, track.looping_stream_path if not track.looping_stream_path.is_empty() else track.linear_stream_path)
	
	_add_player()
	_add_player()
	
	_always_unlocked_ids.assign(SVJukeboxProjectSettings.get_always_unlocked())
	for id in _always_unlocked_ids:
		unlocked.emit(id)
	
	load_unlocks()


# Override
func _process(delta: float) -> void:
	if _current_player != null:
		var playback := _current_player.get_stream_playback()
		if playback != null:
			var loop_count := playback.get_loop_count()
			if loop_count > _last_loop_count:
				loop_complete.emit(_current_id)
			_last_loop_count = loop_count


## Returns the album that was loaded at start. Note that modifying this will
## not have any impact on the ids that are available to play. To add new music
## use [method register] instead.
func get_album() -> AlbumInfo:
	return _album


## Play the music track with given ID. This will play the track's looping stream,
## falling back on its linear stream if the looping stream is undefined.
func play(id: String, from_position: float = 0.0, transition: TransitionType = TransitionType.INSTANT, transition_duration_secs: float = 1.0, unlock_track := true) -> void:
	if id == _current_id:
		return
	
	if unlock_track:
		unlock(id)
	
	var path = _audio_stream_paths.get(id)
	if path == null:
		push_error("Requested ID %s is not registered with SV Jukebox. Requested music will not play." % id)
		return
	
	var stream = load(path)
	if stream == null or stream is not AudioStream:
		push_error("SV Jukebox couldn't load the AudioStream, or it was a different kind of resource. Requested music with ID %s will not play." % id)
		return


# TODO: play_no_unlock method so that you don't have to pass every other argument.


## Plays the given [AudioStream]. Similar to [method play], but allows you to
## play unregistered tracks. Returns true if successful.
func play_stream(stream: AudioStream, as_id: String, from_position: float = 0.0, transition: TransitionType = TransitionType.INSTANT, transition_duration_secs: float = 1.0) -> bool:
	var free_player := _get_free_player()
	
	if free_player == null:
		push_error("SV Jukebox could not get a free player. Requested music will not play.")
		return false
	
	free_player.stream =  stream
	
	var out_player := _current_player
	var in_player := free_player
	
	match transition:
		TransitionType.INSTANT:
			in_player.volume_linear = 1.0
			if out_player != null:
				out_player.stop()
				out_player.stream = null
			in_player.play(from_position)
		TransitionType.FADE_OUT:
			in_player.volume_linear = 1.0
			var tween: Tween = get_tree().create_tween()
			if out_player != null and not out_player.stream_paused:
				tween.tween_property(out_player, "volume_linear", 0.0, transition_duration_secs)
			if out_player != null:
				tween.tween_callback(func () -> void: out_player.stop())
				tween.tween_callback(func () -> void: out_player.stream = null)
			tween.tween_callback(func () -> void: in_player.play(from_position))
			tween.play()
		TransitionType.FADE_OUT_IN:
			in_player.volume_linear = 0.0
			var tween: Tween = get_tree().create_tween()
			if out_player != null and not out_player.stream_paused:
				tween.tween_property(out_player, "volume_linear", 0.0, transition_duration_secs / 2)
			if out_player != null:
				tween.tween_callback(func () -> void: out_player.stop())
				tween.tween_callback(func () -> void: out_player.stream = null)
			tween.tween_callback(func () -> void: in_player.play(from_position))
			tween.tween_property(in_player, "volume_linear", 1.0, transition_duration_secs / 2)
			tween.play()
		TransitionType.CROSS_FADE:
			in_player.volume_linear = 0.0
			in_player.play(from_position)
			var tween: Tween = get_tree().create_tween()
			tween.set_parallel(true)
			if out_player != null:
				tween.tween_property(out_player, "volume_linear", 0.0, transition_duration_secs)
			tween.tween_property(in_player, "volume_linear", 1.0, transition_duration_secs)
			tween.set_parallel(false)
			if out_player != null:
				tween.tween_callback(func () -> void: out_player.stop())
				tween.tween_callback(func () -> void: out_player.stream = null)
			tween.play()
	
	_current_player = free_player
	_current_id = as_id
	
	return true


## Stop playing the current track.
func stop(transition: TransitionType = TransitionType.INSTANT, transition_duration_secs: float = 1.0) -> void:
	if _current_player == null:
		return
	
	match transition:
		TransitionType.INSTANT:
			_current_player.stop()
			_current_player.stream = null
		TransitionType.FADE_OUT, TransitionType.CROSS_FADE:
			var tween: Tween = get_tree().create_tween()
			if not _current_player.stream_paused:
				tween.tween_property(_current_player, "volume_linear", 0.0, transition_duration_secs)
			tween.tween_callback(func () -> void: _current_player.stop())
			tween.tween_callback(func () -> void: _current_player.stream = null)
			tween.play()
		TransitionType.FADE_OUT_IN:
			# Half-duration to match behaviour of playing a new track.
			var tween: Tween = get_tree().create_tween()
			if not _current_player.stream_paused:
				tween.tween_property(_current_player, "volume_linear", 0.0, transition_duration_secs / 2)
			tween.tween_callback(func () -> void: _current_player.stop())
			tween.tween_callback(func () -> void: _current_player.stream = null)
			tween.play()
	
	_current_id = ""
	_current_player = null


## Pauses the currently playing track so it can be resumed later with [method resume].
func pause(transition: TransitionType = TransitionType.INSTANT, transition_duration_secs: float = 1.0) -> void:
	if _current_player == null:
		return
	
	if _current_player.stream_paused:
		return
	
	match transition:
		TransitionType.INSTANT:
			_current_player.stream_paused = true
		TransitionType.FADE_OUT, TransitionType.CROSS_FADE:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(_current_player, "volume_linear", 0.0, transition_duration_secs)
			tween.tween_callback(func () -> void: _current_player.stream_paused = true)
			tween.play()
		TransitionType.FADE_OUT_IN:
			# Half-duration to match behaviour of playing a new track.
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(_current_player, "volume_linear", 0.0, transition_duration_secs / 2)
			tween.tween_callback(func () -> void: _current_player.stream_paused = true)
			tween.play()


## Resumes playback if it was previously paused using [method pause].
func resume(transition: TransitionType = TransitionType.INSTANT, transition_duration_secs: float = 1.0) -> void:
	if _current_player == null:
		return
	
	if not _current_player.stream_paused:
		return
	
	match transition:
		TransitionType.INSTANT, TransitionType.FADE_OUT:
			_current_player.stream_paused = false
		TransitionType.CROSS_FADE:
			_current_player.stream_paused = false
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(_current_player, "volume_linear", 1.0, transition_duration_secs)
			tween.tween_callback(func () -> void: _current_player.stream_paused = false) # Force unpause in case of overlap with pausing tween
			tween.play()
		TransitionType.FADE_OUT_IN:
			# Half-duration to match behaviour of playing a new track.
			_current_player.stream_paused = false
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(_current_player, "volume_linear", 1.0, transition_duration_secs / 2)
			tween.tween_callback(func () -> void: _current_player.stream_paused = false) # Force unpause in case of overlap with pausing tween
			tween.play()


## Seeks to the given position for the currently playing track.
func seek(to_position: float) -> void:
	if _current_player == null:
		return
	
	# TODO: should it be possible to do a transition for this? Wouldn't be dependent on implementing
	# force_play() for playing tracks with same id, because we would just use play_stream() to support
	# tracks started with both play() and play_stream(). But you would need a way to do play_stream()
	# while preserving _current_id.
	_current_player.seek(to_position)


## Attempts to seamlessly swap the currently playing audio stream with another
## stream and keep playing from the same position. Provided so that
## [SVJukeboxUIController] can switch from linear to looping versions of
## tracks when looping is enabled.
##
## If the position is out of bounds of the new stream, the new stream will play
## from the current position minus the length of the new stream.
##
## Pass in [param position_offset] if the two streams you are transitioning
## between aren't perfectly aligned. The offset will be added to the new
## position, and wrapping will apply according to the length of the new stream.
## The offset can be negative.
func swap_stream(new_stream: AudioStream, position_offset: float = 0.0) -> void:
	if _current_player == null:
		return
	
	var was_paused = _current_player.stream_paused
	
	var current_position = _current_player.get_playback_position()
	var new_position = current_position
	new_position += position_offset
	if new_position > new_stream.get_length():
		# TODO: Probably should add the difference to the loop start instead.
		new_position = new_position - new_stream.get_length()
	elif new_position < 0.0:
		new_position = new_stream.get_length() + new_position
	
	_current_player.stop()
	_current_player.stream = new_stream
	_current_player.play(new_position)
	
	if was_paused:
		_current_player.stream_paused = true


## Get the position of the currently playing track. Equivalent to calling
## [method AudioStreamPlayer.get_playback_position] on an [AudioStreamPlayer],
## but with all details of the players abstracted away as with the rest of this
## class.
##
## Returns 0.0 if no track is playing/paused.
func get_playback_position() -> float:
	if _current_player == null:
		return 0.0
	
	return _current_player.get_playback_position()


## Returns the length of the currently playing track.
##
## Returns 0.0 if no track is playing/paused.
func get_track_length() -> float:
	if _current_player == null:
		return 0.0
	
	if _current_player.stream == null:
		push_error("Current player has no stream assigned, returning 0.0 for length.")
		return 0.0
	
	return _current_player.stream.get_length()


## Unlock the given music track (i.e. allow it to be played in the jukebox UI)
func unlock(id: String) -> void:
	if not is_unlocked(id):
		_unlocked_ids.append(id)
		unlocked.emit(id)


## Locks the given track so it can't be played in the jukebox UI. Opposite of
## [method unlock]. Cannot lock tracks that are marked as "always unlocked" in
## project settings.
func remove_unlock(id: String) -> void:
	if _unlocked_ids.has(id):
		_unlocked_ids.erase(id)
		unlock_removed.emit(id)


## Unlocks all tracks. See [method unlock]
func unlock_all() -> void:
	for id in _audio_stream_paths.keys():
		unlock(id)


## Locks all tracks so they can't be played in the jukebox UI. Only tracks that
## are marked as "always unlocked" in project settings will remain.
func remove_all_unlocks() -> void:
	var ids := _unlocked_ids.duplicate() # Because _unlocked_ids will be modified as we iterate through it
	for id in ids:
		remove_unlock(id)


## Returns true if the given music track is unlocked e.g. by using [method unlock].
func is_unlocked(id: String) -> bool:
	return _always_unlocked_ids.has(id) or _unlocked_ids.has(id)


## Returns [code]true[/code] if the given music track has not been unlocked.
func is_locked(id: String) -> bool:
	return not is_unlocked(id)


## Save progress unlocking music tracks for the jukebox. This is automatically
## called when closing the game via the desktop/window, however you will have
## to call this manually when quitting the game yourself (e.g. when calling
## get_tree().quit())
func save_unlocks() -> void:
	var file_path := SVJukeboxProjectSettings.get_unlocks_file()
	
	if not file_path.is_absolute_path():
		push_error("Cannot save music unlocks to file \"%s\" as it is not a valid absolute path. You probably need to start the path with \"user://\"." % file_path)
		return
	
	var base_dir := file_path.get_base_dir()
	var dir_error := DirAccess.make_dir_recursive_absolute(base_dir)
	if dir_error != OK:
		push_error("Failed to create directory \"%s\" with error %d when saving music unlocks. This may prevent music unlocks from saving." % [base_dir, dir_error])
	
	var dict := _serialize_unlocks()
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to open file music unlock file \"%s\". Error code was %d." % [file_path, FileAccess.get_open_error()])
		return
	
	file.store_string(JSON.stringify(dict, "\t"))
	
	file.close()


func load_unlocks() -> void:
	var file_path := SVJukeboxProjectSettings.get_unlocks_file()
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		var err := FileAccess.get_open_error()
		if err != ERR_FILE_NOT_FOUND: # File not found can fail silently because it's probably just the first launch.
			push_error("Failed to open file music unlock file \"%s\". Error code was %d." % [file_path, err])
		return
	
	var json := file.get_as_text()
	
	var dict = JSON.parse_string(json)
	
	if dict == null:
		push_error("Failed to parse music unlock file at path \"%s\"" % file_path)
		return
	
	if dict is not Dictionary:
		push_error("Parsed music unlock file at path \"%s\" as wrong type. It should be a dictionary." % file_path)
		return
	
	_deserialize_unlocks(dict)


func _serialize_unlocks() -> Dictionary:
	# We use a dictionary rather than storing the array directly, just in case we
	# need to store other properties in future.
	var dict: Dictionary = {}
	
	# TODO: Move unlocked_ids to a constant
	dict["unlocked_ids"] = []
	dict["unlocked_ids"].assign(_unlocked_ids)
	
	# We will also save those marked "always unlocked" so they will still be
	# unlocked even if future updates to the game remove those tracks from
	# project settings.
	for id in _always_unlocked_ids:
		if not dict["unlocked_ids"].has(id):
			dict["unlocked_ids"].append(id)
	
	return dict


func _deserialize_unlocks(dict: Dictionary) -> void:
	# TODO: Move unlocked_ids to a constant
	if (not dict.has("unlocked_ids")) or dict["unlocked_ids"] is not Array:
		push_error("unlocked_ids section missing from music_unlocks or wrong type. Assuming no unlocks.")
		remove_all_unlocks()
		return
	
	remove_all_unlocks()
	
	# TODO: Move unlocked_ids to a constant
	for id in dict["unlocked_ids"]:
		if id is not String:
			push_error("One of the ids in the music unlocks file is not a string. It will be skipped.")
			continue
		
		unlock(id)


## Register the [AudioStream] file at the given path with the given id, so it
## can be played using [method play] later.
func register(id: String, path: String) -> void:
	if not (path.is_absolute_path() or path.is_relative_path()):
		push_error("Cannot register audio stream at %s with SV Jukebox as it is not a valid file path." % path)
		return
	
	if id.is_empty():
		push_error("Cannot register an audio stream with SV Jukebox using an empty ID.")
		return
	
	_audio_stream_paths[id] = path


# Returns null if would exceed max players
func _add_player() -> AudioStreamPlayer:
	if _players.size() >= _max_players:
		push_error("SV Jukebox exceeded max number of audio players. Make sure you are not spamming track switches.")
		return null
	
	var new_player := AudioStreamPlayer.new()
	add_child(new_player)
	_players.append(new_player)
	
	var audio_bus_name := SVJukeboxProjectSettings.get_audio_bus_name()
	if not audio_bus_name.is_empty():
		var index := AudioServer.get_bus_index(audio_bus_name)
		if index < 0:
			push_error("Bus %s does not exist. SV Jukebox will play music through the default bus." % audio_bus_name)
		else:
			new_player.bus = audio_bus_name
	
	new_player.finished.connect(_on_audio_stream_player_finished.bind(new_player))
	
	return new_player


# Returns null if would exceed max players
# TODO: force argument that forces a player to be free instead of returning null if there are none left
func _get_free_player() -> AudioStreamPlayer:
	var first_free_player: AudioStreamPlayer = null
	
	for player in _players:
		if player.stream == null:
			first_free_player = player
			break
	
	return _add_player() if first_free_player == null else first_free_player


func _disconnect_signals() -> void:
	# Don't ask me how it works but apparently get_incoming_connections() also
	# returns connections to callables created using .bind() on this object's
	# methods.
	for connection in get_incoming_connections():
		connection["signal"].disconnect(connection["callable"])


# Signal connection
func _on_audio_stream_player_finished(player: AudioStreamPlayer) -> void:
	if _current_player == player:
		# TODO: Add a force loop variable and check it here.
		var finished_id := _current_id
		_current_player.stream = null
		_current_player = null
		_current_id = ""
		track_finished.emit(finished_id)


# Override
func _exit_tree() -> void:
	_destructor()


# Override
func _notification(what: int) -> void:
	# We can't detect calls to get_tree().quit(), but we can at least handle all ways of quitting
	# through the OS here.
	# See https://docs.godotengine.org/en/stable/tutorials/inputs/handling_quit_requests.html
	
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_CRASH:
			_destructor()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if ProjectSettings.get_setting_with_override("application/config/quit_on_go_back"):
				_destructor()


func _destructor() -> void:
	_disconnect_signals()
	save_unlocks()
