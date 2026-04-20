package gameplay;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.FlxG;
import flixel.math.FlxPoint;
import haxe.Json5;
import util.AnimationHelper;

using StringTools;

class Character extends gameplay.FunkinSprite {
	public static final DEFAULT_CHARACTER:String = "bf";

	public static final DEFAULT_IDLE_ANIMATIONS:Array<String> = ["idle"];
	public static final DEFAULT_SING_ANIMATIONS:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
	public static final DEFAULT_MISS_ANIMATIONS:Array<String> = ["singLEFTmiss", "singDOWNmiss", "singUPmiss", "singRIGHTmiss"];

	public static final DEFAULT_ANTIALIASING:Bool = true;

	public var displayName:String = "idk";
	public var characterId:String = DEFAULT_CHARACTER;
	public var healthIconPath:String;

	public var singDuration:Float = 4.0;
	public var animationTimer:Float = 0.0;
	public var beatsToDance:Int = 2;

	public var danceCooldown:Float = 0.0;

	public var isPlayer:Bool = false;
	public var stunned:Bool = false;

	public var idleAnimations:Array<String> = DEFAULT_IDLE_ANIMATIONS;
	public var missAnimations:Array<String> = DEFAULT_SING_ANIMATIONS;
	public var singAnimations:Array<String> = DEFAULT_MISS_ANIMATIONS;

	public var cameraOffset:FlxPoint = new FlxPoint(0, 0);
	public var idleSuffix:String = "";
	public var deathCharacter:String = 'bf';
	public var gameOverSuffix:String = '';

	/**
	 * This scuffed ass variable is used specifically when the character parsing fails
	 *
	 * It's a weird way of fixing an issue that could be solved by hardcoding a character
	 *
	 * It'll be kept here for now until we find a better way
	 */
	private var placeholder:Bool = false;

	private var characterScript:Script;
	private var currentDance:Int = 0;

	public function new(x:Float = 0, y:Float = 0, character:String, ?isPlayer:Bool = false):Void {
		super(x, y);
		this.isPlayer = isPlayer;
		this.characterId = character;
		loadCharacter(this.characterId);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (!placeholder) {
			var v = scriptFuncCall('update', [this, elapsed]);
			if (v != null && v.value == ScriptLoader.STOP_FUNC)
				return;
			if (isSinging()) {
				danceCooldown -= elapsed * (singDuration * (Conductor.semiquaver * 0.25));
				if (danceCooldown <= 0.0)
					dance();
			}
			if (isMissing() && animation.curAnim.finished)
				dance(true, false, 10);
			scriptFuncCall('postUpdate', [this]);
		}
	}

	public function isSinging():Bool
		return animation.curAnim != null && singAnimations.contains(animation.curAnim.name);

	public function isMissing():Bool
		return animation.curAnim != null && missAnimations.contains(animation.curAnim.name);

	public function dance(?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		if (placeholder)
			return;
		scriptFuncCall('preDance', [this, force, reversed, frame]);
		playAnim(idleAnimations[currentDance] + idleSuffix, force, reversed, frame);
		currentDance = flixel.math.FlxMath.wrap(currentDance + 1, 0, idleAnimations.length - 1);
		scriptFuncCall('onDance', [this, force, reversed, frame]);
	}

	public function sing(direction:Int, ?suffix:String = "", ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		if (placeholder)
			return;
		scriptFuncCall('preSing', [this, direction, suffix, force, reversed, frame]);
		playAnim(singAnimations[direction] + suffix, force, reversed, frame);
		scriptFuncCall('onSing', [this, direction, suffix, force, reversed, frame]);
	}

	public function miss(direction:Int, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		if (placeholder)
			return;
		scriptFuncCall('preMiss', [this, direction, force, reversed, frame]);
		playAnim(missAnimations[direction], force, reversed, frame);
		scriptFuncCall('onMiss', [this, direction, force, reversed, frame]);
	}

	private function findCharacterFile(character:String):String {
		var paths = [
			Paths.getPath('images/gameplay/characters/$character/config'),
			Paths.getPath('images/gameplay/characters/$character/$character'),
			Paths.getPath('images/gameplay/characters/$character/$character-config')
		];
		var path:String = paths[0] + '.json';
		for (i in paths) {
			for (ext in Paths.jsonExtensions) {
				if (Paths.fileExists(i + ext)) {
					path = i;
					break;
				}
			}
		}
		return path;
	}

	public function scriptFuncCall(funcName:String, ?args:Array<Dynamic>):HScriptFunction {
		if (characterScript == null)
			return null;
		return characterScript.callFunc(funcName, args);
	}

	private function parseJsonIndicesField(field:Dynamic):Array<Int> {
		var indices:Array<Int> = field ?? null;
		if (field is String) {
			var minmax:Array<String> = field.split("...");
			indices = CoolUtil.numberArray(Std.parseInt(minmax[1]), Std.parseInt(minmax[0]));
		} else if (field is Array)
			indices = field;
		return indices;
	}

	private function loadPlaceholder():Character {
		placeholder = true;
		displayName = "Placeholder";
		characterId = "placeholder";
		makeGraphic(200, 100, 0xFFFF7070);
		// just to prevent crashes
		for (i in idleAnimations)
			animation.add(i, [0], 0, false);
		for (i in singAnimations)
			animation.add(i, [0], 0, false);
		for (i in missAnimations)
			animation.add(i, [0], 0, false);
		return this;
	}

	public function loadCharacter(characterName:String):Character {
		switch characterName {
			default:
				if (characterName == null) {
					visible = false;
					return loadPlaceholder();
				}
				var file:String = findCharacterFile(characterName);
				if (!Paths.fileExists(file))
					return loadPlaceholder();
				try {
					trace('loading character $characterName');
					if (characterScript != null) {
						scriptFuncCall('onCharacterChange', [this.characterId, characterName]);
						characterScript.destroy();
						characterScript = null;
					}
					var file:Dynamic = Json5.parse(Paths.getText(file));
					this.idleAnimations = file.idleAnimations ?? DEFAULT_IDLE_ANIMATIONS;
					this.singAnimations = file.singAnimations ?? DEFAULT_SING_ANIMATIONS;
					this.missAnimations = file.missAnimations ?? DEFAULT_MISS_ANIMATIONS;
					this.beatsToDance = file.beatsToDance ?? singAnimations.length >= 2 ? 1 : 2;
					if (file.cameraOffset != null) {
						var coff:Dynamic = file.cameraOffset; // casting so it actually works
						if (coff is Array)
							cameraOffset.set(coff[0] ?? 0, coff[1] ?? 0);
						else if (coff is Dynamic)
							cameraOffset.set(coff.x ?? 0, coff.y ?? 0);
					}
					if (file.facesLeft == true && !isPlayer)
						flipX = true;
					this.singDuration = file.singDuration ?? 4.0;
					this.displayName = file.name ?? file.displayName ?? "idk";
					this.isPlayer = file.facesLeft ?? file.isPlayer ?? false;
					this.antialiasing = file.antialiasing ?? DEFAULT_ANTIALIASING;

					// TODO: file.atlasType, OR auto-detection based on files in folder -asmadeuxs
					if (file.texture != null)
						frames = Paths.getSparrowAtlas('${file.texture}');
					else
						frames = Paths.getSparrowAtlas('gameplay/characters/$characterName/$characterName');
					if (file.offsets != null)
						AnimationHelper.addOffsetsFromJson(this, file.offsets);
					if (file.animations != null)
						AnimationHelper.addFromJson(this, file.animations, file.defaultFramerate ?? 24);
					placeholder = false; // make sure this is disabled

					var scriptPath:String = Paths.getPath('images/gameplay/characters/$characterName');
					characterScript = ScriptLoader.findScript(ScriptLoader.getScriptFile(scriptPath, characterName), true);
					characterScript?.callFunc('onLoad', [this]);
					this.characterId = characterName;
					dance(true);
				}
				catch (e:haxe.Exception) {
					trace('Error loading character $characterName - ${e.message}');
					return loadPlaceholder();
				}
		}
		return this;
	}
}
