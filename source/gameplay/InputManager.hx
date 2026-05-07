package gameplay;

import flixel.FlxG;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

class InputManager {
	public var held:Map<Int, Bool> = new Map<Int, Bool>();
	public var onKeyPress:Int->Void;
	public var onKeyRelease:Int->Void;

	var _keyMap:Map<Int, Int> = new Map<Int, Null<Int>>();

	public function new(keyPressFunc:Int->Void, keyReleaseFunc:Int->Void):Void {
		this.onKeyPress = keyPressFunc;
		this.onKeyRelease = keyReleaseFunc;
	}

	public function init():Void {
		if (FlxG.stage != null) {
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
	}

	public function destroy():Void {
		if (FlxG.stage != null) {
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
	}

	public function getRemappedKeyCode(originalCode:Int, ?defaultCode:Int = -1):Int
		return _keyMap.get(originalCode) != null ? _keyMap.get(originalCode) : defaultCode;

	public function remapKeyCode(originalCode:Int, newCode:Int):Int {
		_keyMap.set(originalCode, newCode);
		return _keyMap.get(originalCode);
	}

	public function onKeyDown(e:KeyboardEvent):Void {
		var key:Int = getRemappedKeyCode(e.keyCode);
		held.set(key, true);
		if (onKeyPress != null)
			onKeyPress(key);
	}

	public function onKeyUp(e:KeyboardEvent):Void {
		var key:Int = getRemappedKeyCode(e.keyCode);
		held.set(key, false);
		if (onKeyRelease != null)
			onKeyRelease(key);
	}
}
