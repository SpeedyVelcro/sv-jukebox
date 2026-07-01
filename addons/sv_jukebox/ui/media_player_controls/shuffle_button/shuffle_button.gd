extends Button
## Shuffle button for SV Jukebox
##
## This button toggles shuffle mod using its assigned [SVJukeboxUIController].

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController:
	set(value):
		_disconnect_controller_signals()
		ui_controller = value
		_connect_controller_signals()
		update_icon() # Might have a different shuffle status
	get():
		return ui_controller

## Icon to display when shuffle is enabled.
@export var shuffle_on_icon: Texture2D:
	set(value):
		shuffle_on_icon = value
		update_icon()
	get:
		return shuffle_on_icon

## Icon to display when shuffle is disabled.
@export var shuffle_off_icon: Texture2D:
	set(value):
		shuffle_off_icon = value
		update_icon()
	get:
		return shuffle_off_icon


# Override
func _ready() -> void:
	_connect_controller_signals()
	update_icon()


## Updates the icon according to the [member ui_controller]'s shuffle behavior.
func update_icon() -> void:
	if ui_controller == null:
		return # Fail silently because parent node may just have not set it yet before its ready step.
	
	icon = shuffle_on_icon \
			if ui_controller.is_shuffle_on() \
			else shuffle_off_icon
	


# Signal connection
func _on_pressed() -> void:
	if ui_controller == null:
		push_error("UI controller not set on shuffle button.")
		return
	
	ui_controller.set_shuffle_behavior(not ui_controller.is_shuffle_on())


# Signal connection
func _on_ui_controller_shuffle_changed(to: bool) -> void:
	update_icon()


func _connect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if not ui_controller.shuffle_changed.is_connected(_on_ui_controller_shuffle_changed):
		ui_controller.shuffle_changed.connect(_on_ui_controller_shuffle_changed)


func _disconnect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if ui_controller.shuffle_changed.is_connected(_on_ui_controller_shuffle_changed):
		ui_controller.shuffle_changed.disconnect(_on_ui_controller_shuffle_changed)


# Override
func _exit_tree() -> void:
	_disconnect_controller_signals()
