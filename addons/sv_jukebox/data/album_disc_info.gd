class_name AlbumDiscInfo
extends Resource
## Data class for disc info.
##
## This data class stores info about a single disc of an album in SV Jukebox.

## Custom title to be displayed in UI. Leave blank to use numbered disc headers
## instead such as "Disc 1", "Disc 2", etc.
@export var custom_title: String = ""

@export_group("Tracks")
## Music tracks on this disc. Effectively the same as [member side_b]. The
## distincition between sides only affects how the tracks are displayed in the
## SV Jukebox UI.
##
## For a disc that does not have sides, use this variable only and leave
## [member side_b] empty.
@export var side_a: Array[TrackInfo]

## Music tracks on this disc. Effectively the same as [member side_a]. The
## distincition between sides only affects how the tracks are displayed in the
## SV Jukebox UI.
##
## For a disc that does not have sides, leave this variable empty and use
## [member side_a] only.
@export var side_b: Array[TrackInfo]


## Returns all the tracks on this disc in order..
func get_all_tracks() -> Array[TrackInfo]:
	var tracks: Array[TrackInfo] = []
	tracks.append_array( side_a)
	tracks.append_array(side_b)
	return tracks


## Gets the [TrackInfo] for the track with given id from this disc, and all
## the following tracks. Useful for queueing up the following tracks on the
## disc.
##
## Returns an empty array and pushes an error to the console if the track isn't
## found on this disc. Optionally, you can suppress errors.
func get_tracks_from(id: String, show_error := true) -> Array[TrackInfo]:
	var tracks: Array[TrackInfo] = []
	
	for track in get_all_tracks():
		if (not tracks.is_empty()) or track.id == id:
			tracks.append(track)
	
	if show_error:
		push_error("Could not get tracks from track id %s on this disc because track with that id was not found." % id)
	
	return tracks


## Gets the track with given id from this disc. Returns null and pushes an error
## to the console if the track doesn't exist on this disc. Optionally, you
## can suppress errors.
func get_track_info(id: String, show_error := true) -> TrackInfo:
	var a_index: int = side_a.find_custom(func (t: TrackInfo) -> bool: return t.id == id)
	
	if a_index < 0:
		var b_index: int = side_b.find_custom(func (t: TrackInfo) -> bool: return t.id == id)
		if b_index < 0:
			if show_error:
				push_error("Cannot find track with id %s on album disc." % id)
			return null
		return side_b[b_index]
	
	return side_a[a_index]
