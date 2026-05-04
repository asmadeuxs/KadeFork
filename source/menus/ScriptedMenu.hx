package menus;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import effects.Transition;
import flixel.FlxG;
import util.Mods;

class ScriptedMenu extends GenericMenu {
	public var script:Script;

	private static function getScriptPath(className:String, mod:String):String {
		var path:String = null;
		for (ext in Paths.scriptExtensions) {
			var candidate:String = Paths.resolveAssetPath('scripts/menus/$className.$ext', mod);
			if (Paths.fileExists(candidate)) {
				path = candidate;
				break;
			}
		}
		return path;
	}

	public static function switchToMenu(className:String, ?args:Array<Dynamic>, ?transition:TransitionOptions) {
		if (transition == null)
			transition = {out: false, onFinish: () -> FlxG.switchState(ScriptedMenu.getMenu(className, args))};
		if (!Preferences.user.skipTransitions)
			FlxG.switchState(ScriptedMenu.getMenu(className));
		else
			FlxG.state.openSubState(new Transition(transition));
	}

	public static function openMenu(className:String, ?args:Array<Dynamic>, ?transition:TransitionOptions) {
		if (transition == null)
			transition = {out: false, onFinish: () -> FlxG.state.openSubState(ScriptedMenu.getMenu(className, args))};
		if (!Preferences.user.skipTransitions)
			FlxG.state.openSubState(ScriptedMenu.getMenu(className));
		else
			FlxG.state.openSubState(new Transition(transition));
	}

	public static function getMenu(className:String, ?args:Array<Dynamic>):MusicBeatSubstate {
		if (args == null)
			args = [];
		try {
			var scriptPath = getScriptPath(className, Mods.getMenuPriorityMod());
			if (scriptPath != null)
				return Type.createInstance(ScriptedMenu, [scriptPath, args]);
		} catch (e:haxe.Exception)
			Sys.println('Unable to load scripted menu for $className - ${e.details()}');
		return Type.createInstance(Type.resolveClass('menus.' + className), args);
	}

	var constructorArgs:Array<Dynamic> = null;

	public function new(scriptPath:String, ?args:Array<Dynamic>):Void {
		super();
		script = ScriptLoader.findScript(scriptPath);
		if (script == null)
			throw 'Missing script: $scriptPath';
		this.constructorArgs = args;
		script.setVar("add", this.add);
		script.setVar("remove", this.remove);
		script.setVar("replace", this.replace);
		script.setVar("insert", this.insert);
		if (FlxG.state != null) { // substate-specific
			script.setVar("close", this.close);
			this.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		}
	}

	override function create():Void {
		super.create();
		script.callFunc("onCreate", [this]);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		script.callFunc("onUpdate", [this, elapsed]);
	}

	override function onAcceptPressed(v:Int, h:Int):Void {
		var caller = script.callFunc("onAcceptPressed", [this, v, h]);
		if (caller == null || caller.value != ScriptLoader.STOP_FUNC)
			super.onAcceptPressed(v, h);
	}

	override function onBackPressed():Void {
		var caller = script.callFunc("onBackPressed", [this]);
		if (caller == null || caller.value != ScriptLoader.STOP_FUNC)
			super.onBackPressed();
	}

	override function onVerticalChanged(index:Int):Void {
		script.callFunc("onVerticalChanged", [this, index]);
		super.onVerticalChanged(index);
	}

	override function onHorizontalChanged(index:Int):Void {
		script.callFunc("onHorizontalChanged", [this, index]);
		super.onHorizontalChanged(index);
	}
}
