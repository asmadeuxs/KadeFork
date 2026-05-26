package data.hscript;

import flixel.FlxG;

class ScriptedState extends MusicBeatState {
	public var script:Script;

	var constructorArgs:Array<Dynamic>;

	public function new(scriptPath:String, ?args:Array<Dynamic>) {
		super();
		constructorArgs = args;

		try script = ScriptLoader.findScript(scriptPath)
		catch (e:haxe.Exception)
			throw('Failed to load custom state ($scriptPath): ${e.details()}');
		if (script == null) {
			this.persistentUpdate = false;
			this.persistentDraw = false;
			throw 'Missing script: $scriptPath';
			this.destroy();
		}

		script.setVar("add", this.add);
		script.setVar("remove", this.remove);
		script.setVar("replace", this.replace);
		script.setVar("insert", this.insert);
	}

	override function create():Void {
		var caller = script?.callFunc("preCreate", [this]);
		if (caller == null || caller.value != ScriptLoader.STOP_FUNC)
			super.create();
		script?.callFunc("create", [this]);
	}

	override function update(elapsed:Float):Void {
		var caller = script?.callFunc("preUpdate", [this, elapsed]);
		if (caller == null || caller.value != ScriptLoader.STOP_FUNC)
			super.update(elapsed);
		script?.callFunc("update", [this, elapsed]);
	}

	override function draw():Void {
		var caller = script?.callFunc("preDraw", [this]);
		if (caller == null || caller.value != ScriptLoader.STOP_FUNC)
			super.draw();
		script?.callFunc("draw", [this]);
	}

	override function onFocus() {
		script?.callFunc("onFocus", [this]);
	}

	override function onFocusLost() {
		script?.callFunc("onFocusLost", [this]);
	}

	override function onResize(w:Int, h:Int) {
		script?.callFunc("onResize", [this, w, h]);
	}

	override function destroy():Void {
		script?.callFunc("destroy", [this]);
		super.destroy();
	}
}
