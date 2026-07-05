extends Label
## Timestamp label for SV Jukebox playback.
##
## Label that displays the current timestamp (i.e. position in the audio stream)
## in a format appropriate for the length of the song. Can also be configured
## to display other values, such as length or difference with the track length.


## Timestamp types.
enum TimestampType {
	## Always display all zeroes (e.g. 0:00)
	ZERO,
	## Display the current playback position (e.g. 1:23)
	POSITION,
	## Display the length of the track (e.g. 4:56)
	LENGTH,
	## Display the difference between the current playback position and the
	## length of the track (e.g. 3:33)
	DIFFERENCE,
	## Display the difference between the current playback position and the
	## length of the track, with a negative sign prepended (e.g. -3:33)
	DIFFERENCE_NEGATIVE
}

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController

## The type of data to display with this label. See [enum TimestampType]
## for possible values.
@export var type: TimestampType = TimestampType.POSITION

## Pad the the leading segment (e.g. the [code]1[/code] in [code]1:23[/code]) with
## zeroes (e.g. [code]1:23[/code] becomes [code]01:23[/code])
@export var pad_leading_zeroes := false

## Always include at least a minutes section (e.g. [code]0:23[/code] instead of
## [code]23[/code])
@export var always_include_minutes := true


# Override
func _process(delta: float) -> void:
	text = _get_timestamp()


func _get_timestamp() -> String:
	var format_string := _get_format_string()
	var time := _get_time()
	
	return format_string % _get_segments_for_format_string(format_string, time)


func _get_time() -> float:
	if ui_controller == null:
		push_error("UI controller not set on time label. Returning default seek position.")
		return 0.0
	
	match type:
		TimestampType.ZERO:
			return 0.0
		TimestampType.POSITION:
			return ui_controller.get_playback_or_seek_position()
		TimestampType.LENGTH:
			return SVJukebox.get_track_length()
		TimestampType.DIFFERENCE, TimestampType.DIFFERENCE_NEGATIVE: # Negative sign is done using formatting, so underlying number is the same.
			return max(0, SVJukebox.get_track_length() - ui_controller.get_playback_or_seek_position())
		_:
			push_error("Time label has invalid timestamp type.")
			return 0.0


func _get_format_string() -> String:
	var length := SVJukebox.get_track_length()
	
	var format_string: String
	
	if length < 60.0 and not always_include_minutes:
		format_string = "%02d" if pad_leading_zeroes else "%d"
	elif length < 3600.0:
		format_string = "%02d:%02d" if pad_leading_zeroes else "%d:%02d"
	else:
		format_string = "%02d:%02d:%02d" if pad_leading_zeroes else "%d:%02d:%02d"
	
	if type == TimestampType.DIFFERENCE_NEGATIVE:
		format_string = "-" + format_string
	
	return format_string


func _get_segments_for_format_string(format_string: String, time: float) -> Array[int]:
	var segment_count := format_string.count("%")
	
	var segments: Array[int] = []
	
	if segment_count >= 3:
		segments.append(_get_hours_segment(time))
	
	if segment_count >= 2:
		segments.append(_get_minutes_segment(time))
	
	if segment_count >= 1:
		segments.append(_get_seconds_segment(time))
	
	return segments


func _get_seconds_segment(time: float) -> int:
	return floori(time) % 60


func _get_minutes_segment(time: float) -> int:
	return (floori(time) / 60) % 3600


func _get_hours_segment(time: float) -> int:
	return floori(time) / 3600
