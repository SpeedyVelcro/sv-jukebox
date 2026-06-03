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
@export var liner_notes: String = ""

## Fill in this field to display a download button in the jukebox UI.
@export var download_url: String = ""

## Tracks that are registered with SV Jukebox but not displayed in the jukebox
## UI. Useful for tracks that you want to play in game using SV Jukebox, but
## not be part of the album.
@export var hidden_tracks: Array[TrackInfo]

## Returns all the tracks in this album in order.
func get_all_tracks(include_hidden := true) -> Array[TrackInfo]:
	var tracks: Array[TrackInfo] = []
	for disc in discs:
		tracks.append_array(disc.get_all_tracks())
	if include_hidden:
		for track in hidden_tracks:
			tracks.append(track)
	return tracks
