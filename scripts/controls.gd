extends Node
## Default controls. They are added here at startup so the game always works out of the box;
## a rebinding screen arrives in a later milestone.
##   Steer: mouse (captured), WASD / arrow keys, gamepad left stick or d-pad.
##   Pause: Esc / P / gamepad Start.   Fullscreen: F11 or Alt+Enter.

const BINDINGS := {
	move_left = {keys = [KEY_A, KEY_LEFT], axis = [JOY_AXIS_LEFT_X, -1.0], button = JOY_BUTTON_DPAD_LEFT},
	move_right = {keys = [KEY_D, KEY_RIGHT], axis = [JOY_AXIS_LEFT_X, 1.0], button = JOY_BUTTON_DPAD_RIGHT},
	move_up = {keys = [KEY_W, KEY_UP], axis = [JOY_AXIS_LEFT_Y, -1.0], button = JOY_BUTTON_DPAD_UP},
	move_down = {keys = [KEY_S, KEY_DOWN], axis = [JOY_AXIS_LEFT_Y, 1.0], button = JOY_BUTTON_DPAD_DOWN},
	pause = {keys = [KEY_ESCAPE, KEY_P], button = JOY_BUTTON_START},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in BINDINGS:
		if InputMap.has_action(action):
			continue
		var b: Dictionary = BINDINGS[action]
		InputMap.add_action(action, 0.2)
		for k in b.keys:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		if b.has("axis"):
			var m := InputEventJoypadMotion.new()
			m.axis = b.axis[0]
			m.axis_value = b.axis[1]
			InputMap.action_add_event(action, m)
		if b.has("button"):
			var j := InputEventJoypadButton.new()
			j.button_index = b.button
			InputMap.action_add_event(action, j)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_viewport().set_input_as_handled()
