class_name SVJukeboxProjectSettings
extends Object


## Populate [ProjectSettings] with SV Jukebox settings.
static func add_settings() -> void:
	if not ProjectSettings.has_setting(SVJukeboxConstants.SETTINGS_ALBUM_PATH):
		ProjectSettings.set_setting(SVJukeboxConstants.SETTINGS_ALBUM_PATH, "")
	ProjectSettings.set_initial_value(SVJukeboxConstants.SETTINGS_ALBUM_PATH, "")
	ProjectSettings.add_property_info({
		"name": SVJukeboxConstants.SETTINGS_ALBUM_PATH,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres,*.res"
	})
	
	if not ProjectSettings.has_setting(SVJukeboxConstants.SETTINGS_AUDIO_BUS_NAME):
		ProjectSettings.set_setting(SVJukeboxConstants.SETTINGS_AUDIO_BUS_NAME, "Master") # TODO: Move default bus name to a constant
	ProjectSettings.set_initial_value(SVJukeboxConstants.SETTINGS_AUDIO_BUS_NAME, "Master") # TODO: Move default bus name to a constant
	ProjectSettings.add_property_info({
		"name": SVJukeboxConstants.SETTINGS_AUDIO_BUS_NAME,
		"type": TYPE_STRING
	})


## Get the current value of the album path setting
static func get_album_path() -> String:
	return _get_string_setting(SVJukeboxConstants.SETTINGS_ALBUM_PATH)


## Get the current value of the audio bus name setting
static func get_audio_bus_name() -> String:
	return _get_string_setting(SVJukeboxConstants.SETTINGS_AUDIO_BUS_NAME, "Master") # TODO: Move default bus name to a constant


static func _get_string_setting(path: String, default_value := "") -> String:
	if not ProjectSettings.has_setting(path):
		return default_value
	
	var setting = ProjectSettings.get_setting_with_override(path)
	if setting is not String:
		return default_value
	
	return setting
