package;

import flixel.FlxG;
import openfl.events.KeyboardEvent;
import flixel.input.keyboard.FlxKey;

typedef ActionMap = Map<String, Array<FlxKey>>;

class Controls
{
	public static final defaultActions:ActionMap = [
		// Gameplay
		"note_left" => [FlxKey.A, FlxKey.LEFT],
		"note_down" => [FlxKey.S, FlxKey.DOWN],
		"note_up" => [FlxKey.W, FlxKey.UP],
		"note_right" => [FlxKey.D, FlxKey.RIGHT],
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

	public function new(actions:ActionMap):Void
	{
		Controls.connected.push(this);
		if (Controls.current == null)
			Controls.current = Controls.connected[0];
		this.actions = actions;
	}

	public function justPressed(action:String):Bool
	{
		var state:Bool = false;
		if (actions.exists(action))
		{
			var actions:Array<FlxKey> = actions[action];
			for (i => key in actions)
			{
				if (FlxG.keys.checkStatus(key, JUST_PRESSED))
				{
					state = true;
					break;
				}
			}
		}
		return state;
	}

	public function pressed(action:String):Bool
	{
		var state:Bool = false;
		if (actions.exists(action))
		{
			var actions:Array<FlxKey> = actions[action];
			for (i => key in actions)
			{
				if (FlxG.keys.checkStatus(key, PRESSED))
				{
					state = true;
					break;
				}
			}
		}
		return state;
	}

	public function justReleased(action:String):Bool
	{
		var state:Bool = false;
		if (actions.exists(action))
		{
			var actions:Array<FlxKey> = actions[action];
			for (i => key in actions)
			{
				if (FlxG.keys.checkStatus(key, JUST_RELEASED))
				{
					state = true;
					break;
				}
			}
		}
		return state;
	}

	// SHORTCUTS for compatibility with the older system
	// you do NOT need to use any of these since you can simply use Controls.main
	public var LEFT_P(get, never):Bool;
	public var DOWN_P(get, never):Bool;
	public var UP_P(get, never):Bool;
	public var RIGHT_P(get, never):Bool;
	public var PAUSE_P(get, never):Bool;
	public var ACCEPT_P(get, never):Bool;
	public var BACK_P(get, never):Bool;
	public var RESET_P(get, never):Bool;

	private function get_LEFT_P():Bool
		return justPressed("ui_left");

	private function get_DOWN_P():Bool
		return justPressed("ui_down");

	private function get_UP_P():Bool
		return justPressed("ui_up");

	private function get_RIGHT_P():Bool
		return justPressed("ui_right");

	private function get_PAUSE_P():Bool
		return justPressed("ui_pause");

	private function get_ACCEPT_P():Bool
		return justPressed("ui_accept");

	private function get_BACK_P():Bool
		return justPressed("ui_back");

	private function get_RESET_P():Bool
		return justPressed("reset");

	public var LEFT(get, never):Bool;
	public var DOWN(get, never):Bool;
	public var UP(get, never):Bool;
	public var RIGHT(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var RESET(get, never):Bool;

	private function get_LEFT():Bool
		return pressed("ui_left");

	private function get_DOWN():Bool
		return pressed("ui_down");

	private function get_UP():Bool
		return pressed("ui_up");

	private function get_RIGHT():Bool
		return pressed("ui_right");

	private function get_PAUSE():Bool
		return pressed("ui_pause");

	private function get_ACCEPT():Bool
		return pressed("ui_accept");

	private function get_BACK():Bool
		return pressed("ui_back");

	private function get_RESET():Bool
		return pressed("reset");

	public var LEFT_R(get, never):Bool;
	public var DOWN_R(get, never):Bool;
	public var UP_R(get, never):Bool;
	public var RIGHT_R(get, never):Bool;
	public var PAUSE_R(get, never):Bool;
	public var ACCEPT_R(get, never):Bool;
	public var BACK_R(get, never):Bool;
	public var RESET_R(get, never):Bool;

	private function get_LEFT_R():Bool
		return justReleased("ui_left");

	private function get_DOWN_R():Bool
		return justReleased("ui_down");

	private function get_UP_R():Bool
		return justReleased("ui_up");

	private function get_RIGHT_R():Bool
		return justReleased("ui_right");

	private function get_PAUSE_R():Bool
		return justReleased("ui_pause");

	private function get_ACCEPT_R():Bool
		return justReleased("ui_accept");

	private function get_BACK_R():Bool
		return justReleased("ui_back");

	private function get_RESET_R():Bool
		return justReleased("reset");
}
