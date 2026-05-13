package gameplay.hud;

import data.hscript.Script;
import data.hscript.ScriptLoader;

class ScriptHUD extends BaseHUD {
	var script:Script;

	public function new(scriptName:String, ?mod:String) {
		super();
		var path = ScriptLoader.getScriptFile(Paths.getPath('scripts/huds'), scriptName);
		script = ScriptLoader.findScript(path);
		if (script == null)
			throw 'Script HUD not found: $scriptName';

		script.setVar("hud", this);
		script.setVar("add", this.add);
		script.setVar("remove", this.remove);
		script.setVar("replace", this.replace);
		script.setVar("insert", this.insert);
		script.callFunc("generateHUD", [this]);
	}

	public function callFunc(funcName:String, ?args:Array<Dynamic>):HScriptFunction {
		return script != null ? script.callFunc(funcName, args) : null;
	}

	public function hasVar(varname:String):Bool {
		return script != null ? script.hasVar(varname) : false;
	}

	public function getVar(varname:String):Dynamic {
		return script != null ? script.getVar(varname) : null;
	}

	public function setVar(varname:String, value:Dynamic):Dynamic {
		if (script != null) {
			script.setVar(varname, value);
			return script.getVar(varname);
		}
		return null;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (script != null)
			script.callFunc("update", [elapsed]);
	}

	override public function destroy() {
		if (script != null) {
			script.destroy();
			script = null;
		}
		super.destroy();
	}

	override public function onSettingsChanged() {
		if (script != null)
			script.callFunc("onSettingsChanged");
	}

	override public function updateScoreText(?miss:Bool) {
		if (script != null)
			script.callFunc("updateScoreText", [miss]);
	}

	override public function stepHit(step:Int):Void {
		if (script != null)
			script.callFunc("stepHit", [step]);
	}

	override public function beatHit(beat:Int):Void {
		if (script != null)
			script.callFunc("beatHit", [beat]);
	}
}
