package input;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

interface IInputDevice {
	function update(elapsed:Float):Void;
	function isPressed(action:String):Bool;
	function getActions():Array<String>;
}

class Controls {
	public static var current:Controls = null;
	public static var connected:Array<Controls> = [];

	public static var devices:Array<IInputDevice> = [];

	public static function connectDevice(device:IInputDevice):IInputDevice {
		devices.push(device);
		return device;
	}

	public static function disconnectDevice(device:IInputDevice):Bool {
		for (i in devices.length...0) {
			if (devices[i] == device) {
				devices.remove(device);
				return true;
			}
		}
		return false;
	}

	// instance stuff
	public var repeatDelay:Float = 0.25;
	public var repeatInterval:Float = 0.05;

	public var disabled:Bool = false;

	private var _time:Float = 0.0;

	public function new():Void {
		if (!Controls.connected.contains(this))
			Controls.connected.push(this);
		if (Controls.current == null)
			Controls.current = Controls.connected[0];
	}

	// action states
	private var _pressed:Map<String, Bool> = new Map<String, Bool>();
	private var _justPressed:Map<String, Bool> = new Map<String, Bool>();
	private var _justReleased:Map<String, Bool> = new Map<String, Bool>();
	private var _justRepeated:Map<String, Bool> = new Map<String, Bool>();

	// key repetition code
	// so your actions trigger several times when you hold down a key
	private var _jPressedQueue:Map<String, Bool> = new Map<String, Bool>();
	private var _lastRepeats:Map<String, Float> = new Map<String, Float>();
	private var _repeatTimers:Map<String, Float> = new Map<String, Float>();

	public function update(elapsed:Float):Void {
		if (disabled)
			return;
		for (key in _justRepeated.keys())
			_justRepeated[key] = false;

		_time += elapsed;

		for (dev in devices)
			dev.update(elapsed);

		var allActions:Array<String> = [];
		for (dev in devices) {
			var actions = dev.getActions();
			for (action in actions) {
				if (allActions.indexOf(action) == -1)
					allActions.push(action);
			}
		}

		for (action in allActions) {
			var nowPressed:Bool = false;
			for (dev in devices) {
				if (dev.isPressed(action)) {
					nowPressed = true;
					break;
				}
			}

			var wasPressed:Bool = _pressed[action] == true;
			_justPressed[action] = nowPressed && !wasPressed;
			_justReleased[action] = !nowPressed && wasPressed;
			_pressed[action] = nowPressed;

			if (nowPressed) {
				if (_repeatTimers[action] == null) {
					_repeatTimers[action] = _time;
					_lastRepeats[action] = null;
				}
				var holdTime = _time - _repeatTimers[action];
				if (holdTime >= repeatDelay) {
					var lastRepeat = _lastRepeats[action];
					if (lastRepeat == null || (_time - lastRepeat) >= repeatInterval) {
						_justRepeated[action] = true;
						_lastRepeats[action] = _time;
					}
					else
						_justRepeated[action] = false;
				}
				else
					_justRepeated[action] = false;
			}
			else {
				_repeatTimers.remove(action);
				_lastRepeats.remove(action);
				_justRepeated[action] = false;
			}
		}
	}

	public function justPressed(action:String):Bool
		return _justPressed[action] == true;

	public function pressed(action:String):Bool
		return _pressed[action] == true;

	public function justReleased(action:String):Bool
		return _justReleased[action] == true;

	public function justRepeated(action:String):Bool
		return _justRepeated[action] == true;

	// @formatter:off

	// SHORTCUTS for compatibility with the older system
	// you do NOT need to use any of these since you can simply use Controls.current
	public var LEFT_P(get, never):Bool;
	public var DOWN_P(get, never):Bool;
	public var UP_P(get, never):Bool;
	public var RIGHT_P(get, never):Bool;
	public var PAUSE_P(get, never):Bool;
	public var ACCEPT_P(get, never):Bool;
	public var BACK_P(get, never):Bool;
	public var RESET_P(get, never):Bool;

	private function get_LEFT_P():Bool return justPressed("ui_left");
	private function get_DOWN_P():Bool return justPressed("ui_down");
	private function get_UP_P():Bool return justPressed("ui_up");
	private function get_RIGHT_P():Bool return justPressed("ui_right");
	private function get_PAUSE_P():Bool return justPressed("ui_pause");
	private function get_ACCEPT_P():Bool return justPressed("ui_accept");
	private function get_BACK_P():Bool return justPressed("ui_back");
	private function get_RESET_P():Bool return justPressed("reset");

	public var LEFT(get, never):Bool;
	public var DOWN(get, never):Bool;
	public var UP(get, never):Bool;
	public var RIGHT(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var RESET(get, never):Bool;

	private function get_LEFT():Bool return pressed("ui_left");
	private function get_DOWN():Bool return pressed("ui_down");
	private function get_UP():Bool return pressed("ui_up");
	private function get_RIGHT():Bool return pressed("ui_right");
	private function get_PAUSE():Bool return pressed("ui_pause");
	private function get_ACCEPT():Bool return pressed("ui_accept");
	private function get_BACK():Bool return pressed("ui_back");
	private function get_RESET():Bool return pressed("reset");

	public var LEFT_R(get, never):Bool;
	public var DOWN_R(get, never):Bool;
	public var UP_R(get, never):Bool;
	public var RIGHT_R(get, never):Bool;
	public var PAUSE_R(get, never):Bool;
	public var ACCEPT_R(get, never):Bool;
	public var BACK_R(get, never):Bool;
	public var RESET_R(get, never):Bool;

	private function get_LEFT_R():Bool return justReleased("ui_left");
	private function get_DOWN_R():Bool return justReleased("ui_down");
	private function get_UP_R():Bool return justReleased("ui_up");
	private function get_RIGHT_R():Bool return justReleased("ui_right");
	private function get_PAUSE_R():Bool return justReleased("ui_pause");
	private function get_ACCEPT_R():Bool return justReleased("ui_accept");
	private function get_BACK_R():Bool return justReleased("ui_back");
	private function get_RESET_R():Bool return justReleased("reset");

	public var LEFT_RPT(get, never):Bool;
	public var DOWN_RPT(get, never):Bool;
	public var UP_RPT(get, never):Bool;
	public var RIGHT_RPT(get, never):Bool;
	public var PAUSE_RPT(get, never):Bool;
	public var ACCEPT_RPT(get, never):Bool;
	public var BACK_RPT(get, never):Bool;
	public var RESET_RPT(get, never):Bool;

	private function get_LEFT_RPT():Bool return justRepeated("ui_left");
	private function get_DOWN_RPT():Bool return justRepeated("ui_down");
	private function get_UP_RPT():Bool return justRepeated("ui_up");
	private function get_RIGHT_RPT():Bool return justRepeated("ui_right");
	private function get_PAUSE_RPT():Bool return justRepeated("ui_pause");
	private function get_ACCEPT_RPT():Bool return justRepeated("ui_accept");
	private function get_BACK_RPT():Bool return justRepeated("ui_back");
	private function get_RESET_RPT():Bool return justRepeated("reset");

	// @formatter:on
}
