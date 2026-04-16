package gameplay.hud;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;

class BaseHUD extends FlxSpriteGroup {
	var hudScript:Script = null;

	public function new(?hudScript:Script):Void {
		super();
		this.hudScript = hudScript;
		if (hudScript != null) {
			hudScript.setVar("__name", "Unknown");
			hudScript.setVar("add", this.add);
			hudScript.setVar("remove", this.remove);
			hudScript.callFunc("generateHUD", [this]);
		}
	}

	public static function loadHUD(hudName:String):BaseHUD {
		//var path:String = ScriptLoader.getScriptFile(Paths.getPath('data/huds'), hudName);
		//var custom = ScriptLoader.findScript(path, true);
		//return custom == null ? new gameplay.hud.Kade() : new gameplay.hud.BaseHUD(custom);

		// ^ scripted huds are very unstable right now and we might think about it a little bit more before adding...
		return new gameplay.hud.Kade();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (hudScript != null)
			hudScript.callFunc("update", [elapsed, this]);
	}

	public function updateScoreText(?miss:Bool) {
		if (hudScript != null)
			hudScript.callFunc("updateScoreText", [miss, this]);
	}

	public function stepHit(step:Int):Void {
		if (hudScript != null)
			hudScript.callFunc("stepHit", [step, this]);
	}

	public function beatHit(beat:Int):Void {
		if (hudScript != null)
			hudScript.callFunc("beatHit", [beat, this]);
	}
}
