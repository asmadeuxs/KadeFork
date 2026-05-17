package util;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import data.hscript.ScriptedState;
import data.hscript.ScriptedSubstate;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;

class StateOverride {
	public static function switchState(className:String, ?args:Array<Dynamic>):Void {
		var state = createState(className, args);
		FlxG.switchState(state);
	}

	public static function openSubState(className:String, ?args:Array<Dynamic>):Void {
		var substate = createSubState(className, args);
		FlxG.state.openSubState(substate);
	}

	public static function createState(className:String, ?args:Array<Dynamic>):FlxState {
		if (args == null)
			args = [];
		var scriptPath = getScriptPathForClass(className);
		if (scriptPath != null)
			return new ScriptedState(scriptPath, args);
		var stateClass = Type.resolveClass(className);
		if (stateClass == null)
			throw 'State class not found: $className';
		return Type.createInstance(stateClass, args);
	}

	public static function createSubState(className:String, ?args:Array<Dynamic>):FlxSubState {
		if (args == null)
			args = [];
		var scriptPath = getScriptPathForClass(className);
		if (scriptPath != null)
			return new ScriptedSubstate(scriptPath, args);
		var substateClass = Type.resolveClass(className);
		if (substateClass == null)
			throw 'Substate class not found: $className';
		return Type.createInstance(substateClass, args);
	}

	static function getScriptPathForClass(className:String):String {
		var simpleName:String = className.split('.').pop();
		var prefixes:Array<String> = ['states/', 'menus/'];
		for (prefix in prefixes) {
			var full = Paths.getScriptPath(prefix + className, Mods.getMenuPriorityMod());
			if (full == null) {
				full = Paths.getScriptPath(prefix + simpleName, Mods.getMenuPriorityMod());
				if (full != null)
					return full;
			}
			else
				return full;
		}
		return null;
	}
}
