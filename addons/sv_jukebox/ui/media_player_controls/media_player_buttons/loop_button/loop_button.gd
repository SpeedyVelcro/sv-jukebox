extends Button
## Loop button for SV Jukebox
##
## This button cycles through looping behavior (in the order Loop Off, Loop On,
## Loop One) using its assigned [SVJukeboxUIController]

## Shared jukebox UI controller. Place an [SVJukeboxUIController] in your scene
## and assign it here.
@export var ui_controller: SVJukeboxUIController:
	set(value):
		_disconnect_controller_signals()
		ui_controller = value
		_connect_controller_signals()
		update_icon()
	get():
		return ui_controller

## Icon to display when looping is disabled.
@export var loop_off_icon: Texture2D:
	set(value):
		loop_off_icon = value
		update_icon()
	get():
		return loop_off_icon

## Icon to display when normal looping is enabled.
@export var loop_icon: Texture2D:
	set(value):
		loop_icon = value
		update_icon()
	get():
		return loop_icon

## Icon to display when looping a single track.
@export var loop_one_icon: Texture2D:
	set(value):
		loop_one_icon = value
		update_icon()
	get():
		return loop_one_icon


# Override
func _ready() -> void:
	_connect_controller_signals()
	update_icon()


## Updates the icon displayed by this button according to the current looping
## behavior on the [member ui_controller].
func update_icon() -> void:
	if ui_controller == null:
		return # Fail silently because parent node may just have not set it yet before its ready step.
	
	match ui_controller.get_loop_behavior():
		SVJukeboxUIController.LoopBehavior.NONE:
			icon = loop_off_icon
		SVJukeboxUIController.LoopBehavior.LOOP:
			icon = loop_icon
		SVJukeboxUIController.LoopBehavior.LOOP_ONE:
			icon = loop_one_icon


# Signal connection
func _on_pressed() -> void:
	if ui_controller == null:
		push_error("UI controller not set on loop button.")
		return
	
	match ui_controller.get_loop_behavior():
		SVJukeboxUIController.LoopBehavior.NONE:
			ui_controller.loop()
		SVJukeboxUIController.LoopBehavior.LOOP:
			ui_controller.loop_one()
		SVJukeboxUIController.LoopBehavior.LOOP_ONE:
			ui_controller.disable_loop()


func _on_ui_controller_loop_behavior_changed(to: SVJukeboxUIController.LoopBehavior) -> void:
	update_icon()


func _connect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if not ui_controller.loop_behavior_changed.is_connected(_on_ui_controller_loop_behavior_changed):
		ui_controller.loop_behavior_changed.connect(_on_ui_controller_loop_behavior_changed)


func _disconnect_controller_signals() -> void:
	if ui_controller == null:
		return
	
	if ui_controller.loop_behavior_changed.is_connected(_on_ui_controller_loop_behavior_changed):
		ui_controller.loop_behavior_changed.disconnect(_on_ui_controller_loop_behavior_changed)


# Override
func _exit_tree() -> void:
	_disconnect_controller_signals()
