class_name AlbumDiscInfo
extends Resource
## Data class for disc info.
##
## This data class stores info about a single disc of an album in SV Jukebox.

## Custom title to be displayed in UI. Leave blank to use numbered disc headers
## instead such as "Disc 1", "Disc 2", etc.
##
## If you want you may specify a format string with the [code]%d[/code] placeholder,
## which will be used for the disc number. However, this usually isn't necessary
## as you can set custom titles for individual discs anyway.
@export var custom_title: String = ""

## Custom title for side A to be displayed in the UI. Leave blank to simply use
## "Side A".
@export var custom_side_a_title: String = ""

## Custom title for side A to be displayed in the UI. Leave blank to simply use
## "Side B".
@export var custom_side_b_title: String = ""

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
	tracks.append_array(side_a)
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


## Get the track number of the given track id. The track number is counted starting
## from [code]1[/code] at the beginning of the disc, or the beginning of the side for two-sided
## discs.
##
## Returns [code]-1[/code] if the track isn't present on this disc and pushes
## an error. You can optionally pass an argument to suppress errors.
func get_track_number_of(id: String, show_error := true) -> int:
	var a_index: int = side_a.find_custom(func (t: TrackInfo) -> bool: return t.id == id)
	if a_index >= 0:
		return a_index + 1
	
	var b_index: int = side_b.find_custom(func (t: TrackInfo) -> bool: return t.id == id)
	if b_index >= 0:
		return b_index + 1
	
	if show_error:
		push_error("Cannot find track with id %s on album disc." % id)
	
	return -1


## Get the title of this disc as a format string. This may or may not contain the
## placeholder character [code]%d[/code], which will be substituted with the
## disc number.
##
## Unlike getting [member custom_title] directly, this will return the default
## title if no custom title is set.
func get_title_format_string() -> String:
	return "Disc %d" \
			if custom_title.is_empty() \
			else custom_title


## Get the title of side A of this disc.
##
## Unlike getting [member custom_side_a_title] directly, this will return the
## default title if no custom title is set.
func get_side_a_title() -> String:
	return "Side A" \
			if custom_side_a_title.is_empty() \
			else custom_side_a_title


## Get the title of side B of this disc.
##
## Unlike getting [member custom_side_b_title] directly, this will return the
## default title if no custom title is set.
func get_side_b_title() -> String:
	return "Side B" \
			if custom_side_b_title.is_empty() \
			else custom_side_b_title
