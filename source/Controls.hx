package;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

typedef ActionMap = Map<String, Array<FlxKey>>;

class Controls {
	public static final defaultActions:ActionMap = [
		// Gameplay
		"note_left" => [FlxKey.D, FlxKey.LEFT],
		"note_down" => [FlxKey.F, FlxKey.DOWN],
		"note_up" => [FlxKey.J, FlxKey.UP],
		"note_right" => [FlxKey.K, FlxKey.RIGHT],
		"reset" => [FlxKey.R],
		// UI
		"ui_left" => [FlxKey.A, FlxKey.LEFT],
		"ui_down" => [FlxKey.S, FlxKey.DOWN],
		"ui_up" => [FlxKey.W, FlxKey.UP],
		"ui_right" => [FlxKey.D, FlxKey.RIGHT],
		"ui_pause" => [FlxKey.ENTER],
		"ui_accept" => [FlxKey.ENTER],
		"ui_back" => [FlxKey.ESCAPE, FlxKey.BACKSPACE],
	];

	public static var current:Controls = null;
	public static var connected:Array<Controls> = [];

	// instance stuff
	public var actions:ActionMap;

	public var repeatDelay:Float = 0.5;
	public var repeatInterval:Float = 0.1;

	private var _time:Float = 0.0;

	// gonna use these for keyRepeat
	private var _prevPressed:Map<String, Bool> = new Map<String, Bool>();

	private var _repeatStart:Map<String, Float> = new Map<String, Float>();
	private var _repeatLast:Map<String, Float> = new Map<String, Float>();
	private var _justRepeated:Map<String, Bool> = new Map<String, Bool>();

	// TODO: controller support

	public function new(actions:ActionMap):Void {
		Controls.connected.push(this);
		if (Controls.current == null)
			Controls.current = Controls.connected[0];
		this.actions = actions;
	}

	public function update(elapsed:Float):Void {
		_time += elapsed;
		for (key in _justRepeated.keys())
			_justRepeated[key] = false;

		for (action in actions.keys()) {
			var isPressedNow:Bool = pressed(action);
			var wasPressed:Bool = _prevPressed.exists(action) ? _prevPressed[action] : false;

			if (isPressedNow && !wasPressed) {
				_repeatStart[action] = _time;
				_repeatLast[action] = null;
			}
			else if (isPressedNow && wasPressed) {
				var startTime:Null<Float> = _repeatStart[action];
				if (startTime != null && _time - startTime >= repeatDelay) {
					var lastRepeat:Null<Float> = _repeatLast[action];
					if (lastRepeat == null || _time - lastRepeat >= repeatInterval) {
						_justRepeated[action] = true;
						_repeatLast[action] = _time;
					}
				}
			}
			else if (!isPressedNow && wasPressed) {
				_repeatStart.remove(action);
				_repeatLast.remove(action);
				_justRepeated.remove(action);
			}
			_prevPressed[action] = isPressedNow;
		}
	}

	public function justPressed(action:String):Bool {
		var state:Bool = false;
		if (actions.exists(action)) {
			var actions:Array<FlxKey> = actions[action];
			for (i => key in actions) {
				if (FlxG.keys.checkStatus(key, JUST_PRESSED)) {
					state = true;
					break;
				}
			}
		}
		return state;
	}

	public function justRepeated(action:String):Bool
		return _justRepeated.exists(action) && _justRepeated[action];

	public function pressed(action:String):Bool {
		var state:Bool = false;
		if (actions.exists(action)) {
			var actions:Array<FlxKey> = actions[action];
			for (i => key in actions) {
				if (FlxG.keys.checkStatus(key, PRESSED)) {
					state = true;
					break;
				}
			}
		}
		return state;
	}

	public function justReleased(action:String):Bool {
		var state:Bool = false;
		if (actions.exists(action)) {
			var actions:Array<FlxKey> = actions[action];
			for (i => key in actions) {
				if (FlxG.keys.checkStatus(key, JUST_RELEASED)) {
					state = true;
					break;
				}
			}
		}
		return state;
	}

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
