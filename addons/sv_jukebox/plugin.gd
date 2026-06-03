@tool
extends EditorPlugin


# Override
func _enable_plugin() -> void:
	add_autoload_singleton(SVJukeboxConstants.AUTOLOAD_NAME, "res://addons/sv_jukebox/autoload/sv_jukebox.gd")


# Override
func _disable_plugin() -> void:
	remove_autoload_singleton(SVJukeboxConstants.AUTOLOAD_NAME)


# Override
func _enter_tree() -> void:
	SVJukeboxProjectSettings.add_settings()
