package ui;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.FlxObject;
import flixel.system.FlxAssets.GraphicLogo;
import gameplay.FunkinSprite;
import gameplay.PlayState;
import haxe.io.Path;
import moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacyMetaValues;

using StringTools;

class HealthIcon extends FunkinSprite {
	public var sprTracker:FlxObject;

	var iconPath:String = null;
	var iconScript:Script;
	var animCount:Int = 1;

	// so Custom HUDs can get icon data
	public static function getPlayerIcon()
		return PlayState.moonMeta?.extraData.get(PLAYER_1) ?? "bf";

	public static function getOpponentIcon()
		return PlayState.moonMeta?.extraData.get(PLAYER_2) ?? "bf";

	public function new(char:String = 'bf', ?isPlayer:Bool = false) {
		super(0, 0);
		loadIcon(char);
		flipX = isPlayer;
	}

	public function loadIconScript(character:String):Void {
		var iconPath:String = Paths.getPath('images/gameplay/characters/$character/icon-$character');
		var path = ScriptLoader.getScriptFile(iconPath, character);
		iconScript = ScriptLoader.loadScript(path);
	}

	public function loadIcon(character:String):HealthIcon {
		switch character { // just so its easier to hardcode
			default:
				if (iconScript != null) {
					var caller = iconScript.callFunc("loadIcon", [this, character]);
					if (caller != null && caller.value == ScriptLoader.STOP_FUNC)
						return this;
				}
				var noSuffix:String = character.substring(0, character.lastIndexOf("-"));
				var paths = [
					'gameplay/characters/$character/icon-$character',
					'gameplay/characters/$noSuffix/icon-$character',
					'gameplay/characters/$noSuffix/icon-$noSuffix'
				];
				var fail:Bool = true;
				var mainPath:String = paths[0];
				for (checkPath in paths) {
					if (Paths.fileExists(Paths.getPath("images/" + checkPath + ".png"))) {
						mainPath = checkPath;
						fail = false;
						break;
					}
				}
				if (fail) {
					makeGraphic(100, 100, 0xFF00FFFF);
					return this;
				}
				iconPath = mainPath;
				if (Paths.fileExists(Paths.getPath("images/" + mainPath.replace(".png", ".xml")))) {
					frames = Paths.getSparrowAtlas(mainPath);
					animation.addByPrefix("idle", "idle", 24, false);
					animation.addByPrefix("winning", "winning", 24, false);
					animation.addByPrefix("losing", "losing", 24, false);
				} else {
					var tex = Paths.image(Path.withoutExtension(mainPath));
					// simple icon
					// if there's 1 frame on the image then its only that one frmae
					// 2 is idle/losing
					// 3 is idle/losing/winning
					// additional frames aren't counted
					loadGraphic(tex, true, 150, 150);
					animation.add("idle", [0]);
					if (frames.frames.length > 1)
						animation.add("losing", [1]);
					if (frames.frames.length > 2)
						animation.add("winning", [2]);
				}
				antialiasing = !character.endsWith('-pixel');
				animCount = animation.exists("winning") ? 3 : (animation.exists("losing") ? 2 : 1);
				switchState("idle", true);
		}
		scrollFactor.set();
		return this;
	}

	///
	public function switchState(to:String, ?force:Bool = false) {
		if (to == "winning" && animCount >= 3)
			playAnim("winning", force);
		else if (to == "losing" && animCount >= 2)
			playAnim("losing", force);
		else
			playAnim("idle", force);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	// if you want man idk if this makes you happy ://// -asmadeuxs >:))))) -srt
	private function loadIconGrid(character:String) {
		loadGraphic(Paths.image('gameplay/characters/iconGrid'), true, 150, 150);

		if (iconScript != null) {
			iconScript.callFunc("loadIconGrid", [character]);
		} else {
			animation.add('bf', [0, 1], 0, false);
			animation.add('bf-car', [0, 1], 0, false);
			animation.add('bf-christmas', [0, 1], 0, false);
			animation.add('bf-pixel', [21, 21], 0, false);
			animation.add('spooky', [2, 3], 0, false);
			animation.add('pico', [4, 5], 0, false);
			animation.add('mom', [6, 7], 0, false);
			animation.add('mom-car', [6, 7], 0, false);
			animation.add('tankman', [8, 9], 0, false);
			animation.add('face', [10, 11], 0, false);
			animation.add('dad', [12, 13], 0, false);
			animation.add('senpai', [22, 22], 0, false);
			animation.add('senpai-angry', [22, 22], 0, false);
			animation.add('spirit', [23, 23], 0, false);
			animation.add('bf-old', [14, 15], 0, false);
			animation.add('gf', [16], 0, false);
			animation.add('gf-christmas', [16], 0, false);
			animation.add('gf-pixel', [16], 0, false);
			animation.add('parents-christmas', [17, 18], 0, false);
			animation.add('monster', [19, 20], 0, false);
			animation.add('monster-christmas', [19, 20], 0, false);
		}

		var anim = animation.getByName(animation.exists(character) ? character : "face");
		animation.add("idle", [anim.frames[0]]);
		animation.add("losing", [anim.frames[1]]);
		animCount = 2;
	}
}
