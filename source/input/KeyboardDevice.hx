package input;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import input.Controls.IInputDevice;
import openfl.events.KeyboardEvent;

typedef KeyboardActionMap = Map<String, Array<FlxKey>>;

class KeyboardDevice implements IInputDevice {
	public static final defaultActions:KeyboardActionMap = [
		// Gameplay
		"note_left" => [D, LEFT],
		"note_down" => [F, DOWN],
		"note_up" => [J, UP],
		"note_right" => [K, RIGHT],
		"reset" => [R],
		// UI
		"ui_left" => [A, LEFT],
		"ui_down" => [S, DOWN],
		"ui_up" => [W, UP],
		"ui_right" => [D, RIGHT],
		"ui_pause" => [ENTER],
		"ui_accept" => [ENTER],
		"ui_back" => [ESCAPE, BACKSPACE],
	];

	public var actions:KeyboardActionMap;

	public function new(actions:KeyboardActionMap) {
		this.actions = actions;
	}

	public function isPressed(action:String):Bool {
		var keys = actions.get(action);
		if (keys == null)
			return false;
		return FlxG.keys.anyPressed(keys);
	}

	public function update(elapsed:Float):Void {}

	public function getActions():Array<String> {
		return [for (key in actions.keys()) key];
	}
}
