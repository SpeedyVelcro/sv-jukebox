extends Button
## Download album button for SV Jukebox
##
## This button opens the download URL set on [AlbumInfo] in the user's browser.

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController


func _on_pressed() -> void:
	if ui_controller == null:
		push_error("No UI controller set on download album button.")
		return
	
	var album := ui_controller.get_album()
	
	if album == null:
		push_error("Download button cannot get URL from album as UI controller does not have an album.")
		return
	
	var url := album.download_url
	
	if url.is_empty():
		push_error("Cannot open download URL in browser as download URL is not set on album.")
		return
	
	OS.shell_open(url)
