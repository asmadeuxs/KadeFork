package gameplay;

import data.ConfigTypes;
import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfTwo;
import util.Mods;

using StringTools;
using util.AnimationHelper;

enum abstract CharacterType(String) from String to String {
	var PLAYER:String = 'player';
	var OPPONENT:String = 'opponent';
	var METRONOME:String = 'metronome';
}

@:allow(editor.CharacterEditor)
class Character extends gameplay.FunkinSprite {
	public static final DEFAULT_CHARACTER:String = "bf";

	public static final DEFAULT_IDLE_ANIMATIONS:Array<String> = ["idle"];
	public static final DEFAULT_SING_ANIMATIONS:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
	public static final DEFAULT_MISS_ANIMATIONS:Array<String> = ["singLEFTmiss", "singDOWNmiss", "singUPmiss", "singRIGHTmiss"];

	public static final DEFAULT_ANTIALIASING:Bool = true;

	public var displayName:String = "idk";
	public var characterId:String = DEFAULT_CHARACTER;
	public var healthIconPath:String;

	public var singDuration:Float = 1.0;
	public var animationTimer:Float = 0.0;

	public var beatsToDance:Float = 2;
	public var danceSpeed:Float = 1;

	public var danceCooldown:Float = 0.0;
	public var charType:String = CharacterType.OPPONENT;
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
	private var placeholder:Bool = true;

	private var debugMode:Bool = false;
	private var facesLeft:Bool = false;
	private var filePath:String = null;

	private var characterScript:Script;
	private var currentDance:Int = 0;

	public var isPlayer(get, never):Bool;

	function get_isPlayer():Bool
		return charType == CharacterType.PLAYER;

	public function new(x:Float = 0, y:Float = 0, character:String, ?charType:CharacterType = OPPONENT):Void {
		super(x, y);
		this.charType = charType;
		this.characterId = character;
		loadCharacter(character);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (placeholder)
			return;
		if (!debugMode && !stunned) {
			danceCheck();
			if (isSinging()) {
				danceCooldown -= elapsed / singDuration;
				if (danceCooldown <= 0.0)
					dance(true);
			}
		}
		scriptFuncCall('update', [this, elapsed]);
	}

	var _nextDanceBeat:Float = -1.0;
	var _lastInterval:Float = -1.0;

	public function danceCheck():Void {
		var interval:Float = beatsToDance / danceSpeed;
		trace('interval: $interval');
		if (placeholder || isSinging() || interval <= 0)
			return;

		if (_nextDanceBeat < 0)
			_nextDanceBeat = Conductor.currentBeat + interval;

		if (Conductor.currentBeat >= _nextDanceBeat) {
			dance(true);
			_nextDanceBeat += interval;
			if (Conductor.currentBeat > _nextDanceBeat + interval)
				_nextDanceBeat = Conductor.currentBeat + interval;
		}
	}

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

	public function isSinging():Bool
		return animation.curAnim != null && singAnimations.contains(animation.curAnim.name);

	public function isMissing():Bool
		return animation.curAnim != null && missAnimations.contains(animation.curAnim.name);

	private function findCharacterFile(character:String):String {
		var paths = [
			'images/characters/$character/config',
			'images/characters/$character/$character',
			'images/characters/$character/$character-config',
			'images/characters/$character',
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

	public function loadScript(charName:String):Void {
		var scriptPath:String = Paths.getPath('images/characters/$charName');
		characterScript = ScriptLoader.findScript(ScriptLoader.getScriptFile(scriptPath, charName));
		scriptFuncCall('onLoad', [this]);
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
				if (characterName == null || characterName == 'none') {
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
					filePath = file;

					var file:CharacterConfig = haxe.Json5.parse(Paths.getText(file));
					this.idleAnimations = file.idleAnimations ?? DEFAULT_IDLE_ANIMATIONS;
					this.singAnimations = file.singAnimations ?? DEFAULT_SING_ANIMATIONS;
					this.missAnimations = file.missAnimations ?? DEFAULT_MISS_ANIMATIONS;
					if (file.beatsToDance != null)
						this.beatsToDance = file.beatsToDance;
					else
						this.beatsToDance = idleAnimations.length >= 2 ? 1 : 2;

					var fileFlipX:Bool = file.flipX ?? false;
					this.singDuration = file.singDuration ?? 4.0;
					this.antialiasing = file.antialiasing ?? DEFAULT_ANTIALIASING;
					this.displayName = file.name ?? "idk";
					this.facesLeft = file.facesLeft;
					if (file.facesLeft && !isPlayer)
						flipX = !fileFlipX;
					flipY = file.flipY == true;

					var path:String = 'characters/$characterName/$characterName';
					var atlasType:String = 'sparrow';
					if (file.texture != null) {
						path = ConfigTypes.getTexturePath(file.texture);
						atlasType = ConfigTypes.getAtlasType(file.texture, 'sparrow');
					}
					var tex = switch atlasType {
						case 'spritesheet': Paths.image(path);
						case 'packer': Paths.getPackerAtlas(path);
						case _: Paths.getSparrowAtlas(path);
					}
					if (tex is FlxAtlasFrames)
						frames = cast tex;
					else
						loadGraphic(cast tex);

					if (file.animations != null)
						this.addFromJson(file.animations, file.defaultFramerate ?? 24);
					if (file.offsets != null)
						this.addOffsetsFromJson(file.offsets);
					if (file.cameraOffset != null) {
						var coff:Dynamic = file.cameraOffset;
						if (coff is Array)
							cameraOffset.set(coff[0] ?? 0, coff[1] ?? 0);
						else if (coff is Dynamic)
							cameraOffset.set(coff.x ?? 0, coff.y ?? 0);
					}

					placeholder = false; // make sure this is disabled
					this.characterId = characterName;
					loadScript(characterName);
					pivot = BOTTOM_CENTER;
					updatePivot();
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
