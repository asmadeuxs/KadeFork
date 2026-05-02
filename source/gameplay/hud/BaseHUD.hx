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

	public static function listHUDs():Array<String> {
		var hudList:Array<String> = ["Detailed", "Classic"];
		function findThenPush(modId:String = 'core') {
			var dir:String = Paths.getPath('scripts/huds', modId);
			if (Paths.fileExists(dir)) {
				for (i in Paths.listFiles(dir)) {
					if (!Paths.scriptExtensions.contains(haxe.io.Path.extension(i)))
						continue;
					var hudName:String = haxe.io.Path.withoutExtension(i);
					if (!hudList.contains(hudName))
						hudList.push(hudName);
				}
			}
		}
		var modIDs:Array<String> = util.Mods.getEnabled();
		for (modId in modIDs)
			findThenPush(modId);
		return hudList;
	}

	public static function loadHUD(?hudName:String = null):BaseHUD {
		var custom = ScriptLoader.findScript(ScriptLoader.getScriptFile(Paths.getPath('scripts/huds'), hudName), true);
		if (custom != null)
			return new gameplay.hud.BaseHUD(custom);
		else {
			return switch hudName.toLowerCase() {
				case "classic": new gameplay.hud.Classic();
				case _: new gameplay.hud.Kade();
			}
		}
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
