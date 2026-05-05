package gameplay;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.FlxG;
import flixel.math.FlxPoint;
import util.Mods;

using StringTools;
using util.AnimationHelper;

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
	@:allow(gameplay.PlayState)
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
			if (isSinging() && danceCooldown > 0.0) {
				danceCooldown -= elapsed / singDuration;
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
		var v = scriptFuncCall('preDance', [this, force, reversed, frame]);
		if (v == null || v.value != ScriptLoader.STOP_FUNC) {
			playAnim(idleAnimations[currentDance] + idleSuffix, force, reversed, frame);
			currentDance = flixel.math.FlxMath.wrap(currentDance + 1, 0, idleAnimations.length - 1);
		}
		scriptFuncCall('onDance', [this, force, reversed, frame]);
	}

	public function sing(direction:Int, ?suffix:String = "", ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		if (placeholder)
			return;
		var v = scriptFuncCall('preSing', [this, direction, suffix, force, reversed, frame]);
		if (v == null || v.value != ScriptLoader.STOP_FUNC)
			playAnim(singAnimations[direction] + suffix, force, reversed, frame);
		scriptFuncCall('onSing', [this, direction, suffix, force, reversed, frame]);
	}

	public function miss(direction:Int, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		if (placeholder)
			return;
		var v = scriptFuncCall('preMiss', [this, direction, force, reversed, frame]);
		if (v == null || v.value != ScriptLoader.STOP_FUNC)
			playAnim(missAnimations[direction], force, reversed, frame);
		scriptFuncCall('onMiss', [this, direction, force, reversed, frame]);
	}

	private function findCharacterFile(character:String):String {
		var begin:String = 'images/gameplay/characters';
		var paths = [
			'$begin/$character/config',
			'$begin/$character/$character',
			'$begin/$character/$character-config',
			'$begin/$character',
		];
		var path:String = Paths.getPath(paths[0] + '.json');
		for (i in paths) {
			for (ext in Paths.jsonExtensions) {
				var target:String = Paths.getPath('$i.$ext');
				if (Paths.fileExists(target)) {
					path = target;
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
				this.characterId = null;
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
					var file:Dynamic = haxe.Json5.parse(Paths.getText(file));
					this.idleAnimations = file.idleAnimations ?? DEFAULT_IDLE_ANIMATIONS;
					this.singAnimations = file.singAnimations ?? DEFAULT_SING_ANIMATIONS;
					this.missAnimations = file.missAnimations ?? DEFAULT_MISS_ANIMATIONS;
					this.beatsToDance = file.beatsToDance ?? singAnimations.length >= 2 ? 1 : 2;
					if ((file.facesLeft || file.isPlayer) && !isPlayer)
						flipX = true;
					this.singDuration = file.singDuration ?? 4.0;
					this.displayName = file.name ?? file.displayName ?? "idk";
					this.isPlayer = file.facesLeft ?? file.isPlayer ?? false;
					this.antialiasing = file.antialiasing ?? DEFAULT_ANTIALIASING;

					// TODO: file.atlasType, OR auto-detection based on files in folder -asmadeuxs
					if (file.texture != null)
						frames = Paths.getSparrowAtlas(file.texture);
					else
						frames = Paths.getSparrowAtlas('gameplay/characters/$characterName/$characterName');
					if (file.offsets != null)
						this.addOffsetsFromJson(file.offsets);
					if (file.animations != null)
						this.addFromJson(file.animations, file.defaultFramerate ?? 24);
					if (file.cameraOffset != null) {
						var coff:Dynamic = file.cameraOffset;
						if (coff is Array)
							cameraOffset.set(coff[0] ?? 0, coff[1] ?? 0);
						else if (coff is Dynamic)
							cameraOffset.set(coff.x ?? 0, coff.y ?? 0);
					}
					placeholder = false; // make sure this is disabled
					this.characterId = characterName;
					var scriptPath:String = Paths.getPath('images/gameplay/characters/$characterName');
					characterScript = ScriptLoader.findScript(ScriptLoader.getScriptFile(scriptPath, characterName));
					scriptFuncCall('onLoad', [this]);
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
