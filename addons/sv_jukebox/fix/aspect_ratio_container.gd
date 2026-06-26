class_name AspectRatioContainerJukeboxFix
extends AspectRatioContainer
# See https://github.com/godotengine/godot/issues/75169
# NB: This workaround overwrites any custom_minimum_size so does not
# work as a general solution; only for our use case in SV Jukebox.


# Override
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			var x := 0.0
			var y := 0.0
			for child in get_children():
				x = max(x, child.size.x)
				y = max(y, child.size.y)
			custom_minimum_size = Vector2(x, y)
