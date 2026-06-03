extends Node
## Autoload node for interacting with the SV Jukebox plugin.
##
## Autoloaded as SVJukebox. This singleton node provides methods for basic
## music playing functionality and managing music unlocks.

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

var _players: Array[AudioStreamPlayer] = []
var _audio_stream_paths: Dictionary[String, String] = {} # [id, path]
var _unlocked_ids: Array[String]
var _current_id = ""
var _current_player: AudioStreamPlayer = null
# TODO: configurable max players
var _max_players = 10 # To stop an explosion of players when misusing SV Jukebox. Exceeding this will cause errors and incorrect behaviour though.

## Emitted when a track is unlocked.
signal unlocked(id: String)
## Emitted when a track unlock is removed i.e. the reverse of [signal unlocked]
## has happened.
signal unlock_removed(id: String)


# Override
func _ready() -> void:
	# TODO: Make initial number of players configurable
	# TODO: Load unlocks
	
	var album_path := SVJukeboxProjectSettings.get_album_path()
	if not (album_path.is_absolute_path() or album_path.is_relative_path()):
		push_error("Album path %s is not a valid path. SV Jukebox will not be able to register any of its music." % album_path)
	else:
		var resource = load(album_path)
		if resource == null or resource is not AlbumInfo:
			push_error("Album at path %s does not appear to either exist or be a valid AlbumInfo resource. SV Jukebox will not be able to register any of its music." % album_path)
		else:
			var album: AlbumInfo = resource
			for track in album.get_all_tracks():
				register(track.id, track.looping_stream_path if not track.looping_stream_path.is_empty() else track.linear_stream_path)
	
	_add_player()
	_add_player()


## Play the music track with given ID
func play(id: String, transition: TransitionType = TransitionType.INSTANT, transition_duration_secs: float = 1.0, unlock_track := true) -> void:
	if id == _current_id:
		return
	
	if unlock_track:
		unlock(id)
	
	var free_player := _get_free_player()
	
	if free_player == null:
		push_error("SV Jukebox could not get a free player. Requested music with ID %s will not play." % id)
		return
	
	var path = _audio_stream_paths.get(id)
	if path == null:
		push_error("Requested ID %s is not registered with SV Jukebox. Requested music will not play." % id)
		return
	
	var stream = load(path)
	if stream == null or stream is not AudioStream:
		push_error("SV Jukebox couldn't load the AudioStream, or it was a different kind of resource. Requested music with ID %s will not play." % id)
		return
	
	free_player.stream =  stream
	
	var out_player := _current_player
	var in_player := free_player
	
	match transition:
		TransitionType.INSTANT:
			in_player.volume_linear = 1.0
			if out_player != null:
				out_player.stop()
				out_player.stream = null
			in_player.play()
		TransitionType.FADE_OUT:
			in_player.volume_linear = 1.0
			var tween: Tween = get_tree().create_tween()
			if out_player != null:
				tween.tween_property(out_player, "volume_linear", 0.0, transition_duration_secs)
				tween.tween_callback(func () -> void: out_player.stop())
				tween.tween_callback(func () -> void: out_player.stream = null)
			tween.tween_callback(func () -> void: in_player.play())
			tween.play()
		TransitionType.FADE_OUT_IN:
			in_player.volume_linear = 0.0
			var tween: Tween = get_tree().create_tween()
			if out_player != null:
				tween.tween_property(out_player, "volume_linear", 0.0, transition_duration_secs / 2)
				tween.tween_callback(func () -> void: out_player.stop())
				tween.tween_callback(func () -> void: out_player.stream = null)
			tween.tween_callback(func () -> void: in_player.play())
			tween.tween_property(in_player, "volume_linear", 1.0, transition_duration_secs / 2)
			tween.play()
		TransitionType.CROSS_FADE:
			in_player.volume_linear = 0.0
			in_player.play()
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
	_current_id = id


# TODO: play_no_unlock method so that you don't have to pass every other argument.


## Stop playing the current track.
func stop(transition: TransitionType, transition_duration_secs: float = 1.0) -> void:
	if _current_player == null:
		return
	
	match transition:
		TransitionType.INSTANT:
			_current_player.stop()
			_current_player.stream = null
		TransitionType.FADE_OUT, TransitionType.CROSS_FADE:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(_current_player, "volume_linear", 0.0, transition_duration_secs)
			tween.tween_callback(func () -> void: _current_player.stop())
			tween.tween_callback(func () -> void: _current_player.stream = null)
			tween.play()
		TransitionType.FADE_OUT_IN:
			# Half-duration to match behaviour of playing a new track.
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(_current_player, "volume_linear", 0.0, transition_duration_secs / 2)
			tween.tween_callback(func () -> void: _current_player.stop())
			tween.tween_callback(func () -> void: _current_player.stream = null)
			tween.play()
	
	_current_id = ""
	_current_player = null


## Unlock the given music track (i.e. allow it to be played in the jukebox UI)
func unlock(id: String) -> void:
	if not _unlocked_ids.has(id):
		_unlocked_ids.append(id)
		unlocked.emit(id)


## Unlocks all tracks. See [method unlock]
func unlock_all() -> void:
	for id in _audio_stream_paths.keys():
		unlock(id)

## Save progress unlocking music tracks for the jukebox. This is automatically
## called when closing the game via the desktop/window, however you will have
## to call this manually when quitting the game yourself (e.g. when calling
## get_tree().quit())
func save_unlocks() -> void:
	pass # TODO


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
	# Only way this wouldn't be true is if you're rapidly switching between
	# short linear tracks, but I think doing nothing would still be the correct
	# action in that circumstance.
	if _current_player == player:
		_current_player.stream = null
		_current_player = null
		_current_id = null


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
