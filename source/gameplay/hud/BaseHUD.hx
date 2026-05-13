package gameplay.hud;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;

class BaseHUD extends FlxSpriteGroup {
	public function new():Void {
		super();
	}

	public static function listHUDs():Array<String> {
		var names:Array<String> = ["Default", "Detailed", "Classic"];
		var mods = util.Mods.getEnabled();
		for (modId in mods) {
			var scriptPath:String = Paths.getPath('scripts/huds', modId);
			if (!Paths.fileExists(scriptPath))
				continue;
			for (file in Paths.listFiles(scriptPath)) {
				var ext:String = haxe.io.Path.extension(file).toLowerCase();
				if (!Paths.scriptExtensions.contains(ext))
					continue;
				var baseName:String = haxe.io.Path.withoutExtension(file);
				if (!names.contains(baseName))
					names.push(baseName);
			}
		}
		return names;
	}

	public static function loadHUD(?hudName:String = null):BaseHUD {
		var jsonPath = Paths.getJsonPath('data/huds/$hudName');
		// @formatter:off
		var scriptPath = ScriptLoader.getScriptFile(Paths.getPath('scripts/huds'), hudName);
		if (scriptPath != null && Paths.fileExists(scriptPath)) {
			try return new ScriptHUD(hudName)
			catch (e:Dynamic) trace('Failed to load scripted HUD "$hudName" - $e');
		}
		// @formatter:on
		return switch (hudName.toLowerCase()) {
			case "classic": new Classic();
			default: new Kade();
		}
	}

	public function onSettingsChanged() {}

	public function updateScoreText(?miss:Bool) {}

	public function stepHit(step:Int):Void {}

	public function beatHit(beat:Int):Void {}
}
