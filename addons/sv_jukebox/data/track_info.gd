class_name TrackInfo
extends Resource
## Data class storing track info.
##
## This data class stores audio file info and metadata for a single music
## track in SV Jukebox.

## Unique [String] identifier used to play the track using SVJukebox. You must
## set this to a non-empty value. It is recommended to use a hyphen-separated
## lowercase format e.g. [code]"groovy-boss-music"[/code]
@export var id: String = ""

@export_group("Audio")
## File path to a looping version of the track. This is the version of the track
## that will be played in-game, unless it is left empty in which case
## [member linear_stream_path] will be used instead and the track will not loop.
##
## This is also the version that plays when looping a single track via the
## jukebox UI. If left empty, [member linear_stream_path] will be looped
## instead.
##
## At least one of [member looping_stream_path] and [member linear_stream_path]
## must be set to a non-empty path.
@export_file("*.ogg","*.wav","*.mp3","*.qoa") var looping_stream_path: String = ""

## File path to a linear (non-looping) version of the track. This is the version
## of the track that will be played via the jukebox UI, unless it is left empty,
## in which case a single loop of [member looping_stream_path] will be played
## instead.
##
## At least one of [member looping_stream_path] and [member linear_stream_path]
## must be set to a non-empty path.
@export_file("*.ogg","*.wav","*.mp3","*.qoa") var linear_stream_path: String = ""

@export_group("Metadata")
## Human readable
@export var title: String = ""

## Liner notes for this track. Descriptive text that is displayed when this
## track is played in the SV Jukebox UI. If this is left blank, the album's
## liner notes will be displayed instead.
@export_multiline var liner_notes: String = ""

## Main artists to which the track is credited.
@export var artists: Array[String] = []

# TODO: Other roles e.g. composer, arranger, lyricist, producer
