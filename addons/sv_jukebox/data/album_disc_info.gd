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
