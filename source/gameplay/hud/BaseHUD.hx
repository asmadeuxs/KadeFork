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

	public static function loadHUD(?hudName:String = null):BaseHUD {
		if (hudName == null)
			return new gameplay.hud.Kade();
		var custom = ScriptLoader.findScript(ScriptLoader.getScriptFile(Paths.getPath('scripts/huds'), hudName), true);
		return custom == null ? new gameplay.hud.Kade() : new gameplay.hud.BaseHUD(custom);
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
