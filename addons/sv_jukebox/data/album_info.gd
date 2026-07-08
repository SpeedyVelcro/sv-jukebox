class_name AlbumInfo
extends Resource
## Data class storing info about an album.
##
## This data class stores all the info about an album and all its tracks in
## SV Jukebox. This includes metadata, album structure, and [AudioStream]s used
## for playing the tracks. Much of this information is stored on sub-resources
## that are members of this class.

## All discs on the album. If this album does not have discs, just use a
## single entry and the SV Jukebox UI will not use headers for discs.
@export var discs: Array[AlbumDiscInfo] = []

## Liner notes for the entire album. This is a description shown in the jukebox
## when no track is selected.
@export_multiline var liner_notes: String = ""

## Fill in this field to display a download button in the jukebox UI.
@export var download_url: String = ""

## Tracks that are registered with SV Jukebox but not displayed in the jukebox
## UI. Useful for tracks that you want to play in game using SV Jukebox, but
## not be part of the album.
@export var hidden_tracks: Array[TrackInfo]

## Returns all the tracks in this album in order. You can pass in an optional
## argument to exclude hidden tracks.
func get_all_tracks(include_hidden := true) -> Array[TrackInfo]:
	var tracks: Array[TrackInfo] = []
	for disc in discs:
		tracks.append_array(disc.get_all_tracks())
	if include_hidden:
		for track in hidden_tracks:
			tracks.append(track)
	return tracks


## Gets the [TrackInfo] for track with given id, and all the following tracks
## in the album. Useful for queueing upcoming tracks.
##
## Returns an empty array and pushes an error if the track with the given id
## isn't found. You can pass in an optional argument to suppress errors.
func get_tracks_from(id: String, show_errors := true) -> Array[TrackInfo]:
	var tracks: Array[TrackInfo] = []
	
	for disc in discs:
		const SHOW_DISC_ERROR := false
		if tracks.is_empty():
			tracks.append_array(disc.get_tracks_from(id, SHOW_DISC_ERROR))
		else:
			tracks.append_array(disc.get_all_tracks())
	
	if tracks.is_empty() and show_errors:
		push_error("Failed to get tracks from track id %s, as this track id wasn't found." % id)
	
	return tracks


## Gets the [TrackInfo] for the track immediately before the track with given
## id.
##
## Returns null and fails silently if there are no previous tracks
## (because you gave the first track on the album). Pushes an error and returns
## null if the id you gave isn't on the album.
func get_previous_track(id: String) -> TrackInfo:
	# TODO: inefficient implementation. get_all_tracks() iterates past the track we're looking for
	
	var tracks := get_all_tracks(false)
	
	var index := tracks.find_custom(func (t) -> bool: return t.id == id)
	
	if index < 0:
		push_error("Track with id \"%s\" not found on album." % id)
		return null
	
	if index == 0:
		return null
	
	return tracks[index - 1]


## Gets the last track on the album. Returns null and pushes an error if there
## are no tracks on the album.
func get_first_track(show_error := true) -> TrackInfo:
	# TODO: inefficient implementation, as get_all_tracks() will iterate past
	# the disc with the first track on it.
	
	var tracks := get_all_tracks(false)
	
	if tracks.is_empty():
		if show_error:
			push_error("Cannot get the first track on the album as the album is empty.")
		return null
	
	return tracks.front()


## Gets the last track on the album. Returns null and pushes an error if there
## are no tracks on the album.
func get_last_track(show_error := true) -> TrackInfo:
	# TODO: inefficient implementation, better to check starting from back manually
	# as get_all_tracks() iterates from the front.
	
	var tracks := get_all_tracks(false)
	
	if tracks.is_empty():
		if show_error:
			push_error("Cannot get the last track on the album as the album is empty.")
		return null
	
	return tracks.back()


## Returns true if the track with given id is the first track on the album.
func is_first_track(id: String) -> bool:
	var track := get_first_track(false)
	
	if track == null:
		return false
	
	return track.id == id


## Gets the [TrackInfo] for the track on this album that has given id. Returns
## null and pushes an error if the track isn't found. You can pass in an
## optional argument to suppress errors. Does not include hidden tracks.
func get_track_info(id: String, show_errors := true) -> TrackInfo:
	var track_info: TrackInfo = null
	
	for disc in discs:
		var show_disc_error = false
		track_info = disc.get_track_info(id, show_disc_error)
		if track_info != null:
			break
	
	if track_info == null:
		push_error("Could not find track with id %s on album." % id)
	
	return track_info


## Get the track number of the given track id. The track number is counted starting
## from [code]1[/code] at the beginning of its disc, or the beginning of the side for two-sided
## discs.
##
## Returns [code]-1[/code] if the track isn't present on this disc and pushes
## an error. You can optionally pass an argument to suppress errors.
func get_track_number_of(id: String, show_error := true) -> int:
	var number: int = -1
	
	for disc in discs:
		const SHOW_DISC_ERROR := false # We will do an error at the top level anyway if show_error is true.
		number = disc.get_track_number_of(id, SHOW_DISC_ERROR)
		
		if number >= 0:
			break
	
	if show_error and (number < 0):
		push_error("Could not find track with id %s on album." % id)
	
	return number


## Returns true if this album has the track with given id. Does not include
## hidden tracks.
func has_track(id: String) -> bool:
	var show_errors := false
	return get_track_info(id, show_errors) != null
