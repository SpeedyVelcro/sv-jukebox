class_name SVJukeboxConstants
extends Object

const _SETTINGS_ROOT_PATH := "sv_jukebox"
const _SETTINGS_GENERAL_PATH := _SETTINGS_ROOT_PATH + "/general"

## Name to be given to the main autoload for interacting with the plugin.
const AUTOLOAD_NAME := "SVJukebox"

## Path for the setting in [ProjectSettings] that stores the filepath to the
## [AlbumInfo].
const SETTINGS_ALBUM_PATH := _SETTINGS_GENERAL_PATH + "/album"
## Path for the settings in [ProjectSettings] that sets the bus music played
## out of SV Jukebox will play on. If this setting is left, empty, it is played
## through the default bus.
const SETTINGS_AUDIO_BUS_NAME := _SETTINGS_GENERAL_PATH + "/audio_bus_name"
