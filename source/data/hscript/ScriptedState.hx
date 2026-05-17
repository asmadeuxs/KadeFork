package data.hscript;

import flixel.FlxG;

class ScriptedState extends MusicBeatState {
	public var script:Script;

	var constructorArgs:Array<Dynamic>;

	public function new(scriptPath:String, ?args:Array<Dynamic>) {
		super();
		script = ScriptLoader.findScript(scriptPath);
		if (script == null)
			throw 'Missing script: $scriptPath';
		constructorArgs = args;
		script.setVar("add", this.add);
		script.setVar("remove", this.remove);
		script.setVar("replace", this.replace);
		script.setVar("insert", this.insert);
	}

	override function create():Void {
		super.create();
		script.callFunc("create", [this]);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		script.callFunc("update", [this, elapsed]);
	}

	override function destroy():Void {
		script.callFunc("destroy", [this]);
		super.destroy();
	}
}
