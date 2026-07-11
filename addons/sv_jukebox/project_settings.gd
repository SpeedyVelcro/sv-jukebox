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
	
	if not ProjectSettings.has_setting(SVJukeboxConstants.SETTINGS_UNLOCKS_FILE_PATH):
		ProjectSettings.set_setting(SVJukeboxConstants.SETTINGS_UNLOCKS_FILE_PATH, SVJukeboxConstants.DEFAULT_UNLOCKS_PATH) 
	ProjectSettings.set_initial_value(SVJukeboxConstants.SETTINGS_UNLOCKS_FILE_PATH, SVJukeboxConstants.DEFAULT_UNLOCKS_PATH)
	ProjectSettings.add_property_info({
		"name": SVJukeboxConstants.SETTINGS_UNLOCKS_FILE_PATH,
		"type": TYPE_STRING
	})
	
	# TODO: Currently new elements default to the string "<null>". Not sure if
	# there is a way to fix this yet. Might need to open an issue.
	if not ProjectSettings.has_setting(SVJukeboxConstants.SETTINGS_ALWAYS_UNLOCKED_PATH):
		ProjectSettings.set_setting(SVJukeboxConstants.SETTINGS_ALWAYS_UNLOCKED_PATH, []) 
	ProjectSettings.set_initial_value(SVJukeboxConstants.SETTINGS_ALWAYS_UNLOCKED_PATH, [])
	ProjectSettings.add_property_info({
		"name": SVJukeboxConstants.SETTINGS_ALWAYS_UNLOCKED_PATH,
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_ARRAY_TYPE,
		"hint_string": "String"
	})


## Get the current value of the album path setting
static func get_album_path() -> String:
	return _get_string_setting(SVJukeboxConstants.SETTINGS_ALBUM_PATH)


## Get the current value of the audio bus name setting
static func get_audio_bus_name() -> String:
	return _get_string_setting(SVJukeboxConstants.SETTINGS_AUDIO_BUS_NAME, "Master") # TODO: Move default bus name to a constant


## Get the current value of the unlocks file setting
static func get_unlocks_file() -> String:
	return _get_string_setting(SVJukeboxConstants.SETTINGS_UNLOCKS_FILE_PATH, SVJukeboxConstants.DEFAULT_UNLOCKS_PATH)


## Gets the current value of the always unlocked setting.
static func get_always_unlocked() -> Array[String]:
	if not ProjectSettings.has_setting(SVJukeboxConstants.SETTINGS_ALWAYS_UNLOCKED_PATH):
		return []
	
	var setting = ProjectSettings.get_setting_with_override(SVJukeboxConstants.SETTINGS_ALWAYS_UNLOCKED_PATH)
	if setting is not Array[String]:
		if setting is not Array:
			return []
		
		var arr: Array[String] = []
		arr.assign(setting.filter(func (el) -> bool: return el is String))
		return arr
	
	return setting


static func _get_string_setting(path: String, default_value := "") -> String:
	if not ProjectSettings.has_setting(path):
		return default_value
	
	var setting = ProjectSettings.get_setting_with_override(path)
	if setting is not String:
		return default_value
	
	return setting
