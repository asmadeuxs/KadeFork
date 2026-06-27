package input;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import input.Controls.IInputDevice;

typedef GamepadActionMap = Map<String, Array<FlxGamepadInputID>>;

class GamepadDevice implements IInputDevice {
	public static var defaultActions:GamepadActionMap = [
		// Gameplay
		"note_left" => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		"note_down" => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		"note_up" => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		"note_right" => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		"reset" => [GUIDE],
		// UI
		"ui_left" => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		"ui_down" => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		"ui_up" => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		"ui_right" => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		"ui_pause" => [START],
		"ui_accept" => [A, START],
		"ui_back" => [B, BACK],
	];

	public var actions:GamepadActionMap;

	var gamepadID:Int = -1;

	public function new(actions:GamepadActionMap, gamepadID:Int = 0) {
		this.actions = actions;
		this.gamepadID = gamepadID;
	}

	public function isPressed(action:String):Bool {
		var pad = FlxG.gamepads.getByID(gamepadID);
		var buttons = actions.get(action);
		if (buttons == null || pad == null)
			return false;
		return pad.anyPressed(buttons);
	}

	public function update(elapsed:Float):Void {}

	public function getActions():Array<String> {
		return [for (key in actions.keys()) key];
	}
}
