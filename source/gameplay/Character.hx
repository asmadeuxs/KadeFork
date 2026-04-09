package gameplay;

import data.ScriptLoader;
import flixel.FlxG;
import haxe.Json5;

using StringTools;

class Character extends gameplay.FunkinSprite {
	public static final DEFAULT_CHARACTER:String = "bf";

	public static final DEFAULT_IDLE_ANIMATIONS:Array<String> = ["idle"];
	public static final DEFAULT_SING_ANIMATIONS:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
	public static final DEFAULT_MISS_ANIMATIONS:Array<String> = ["singLEFTmiss", "singDOWNmiss", "singUPmiss", "singRIGHTmiss"];

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

	public var idleSuffix:String = "";

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
			if (animation.curAnim.name != idleAnimations[currentDance] + idleSuffix) {
				danceCooldown -= elapsed * (singDuration * (Conductor.stepCrochet * 0.25));
				if (danceCooldown <= 0.0)
					dance();
			}

			if (isMissing() && animation.curAnim.finished)
				dance(true, false, 10);
		}
	}

	public function isSinging():Bool
		return animation.curAnim != null && singAnimations.contains(animation.curAnim.name + idleSuffix);

	public function isMissing():Bool
		return animation.curAnim != null && missAnimations.contains(animation.curAnim.name + idleSuffix);

	public function dance(?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		if (placeholder)
			return;
		playAnim(idleAnimations[currentDance], force, reversed, frame);
		currentDance = flixel.math.FlxMath.wrap(currentDance + 1, 0, idleAnimations.length - 1);
	}

	public function sing(direction:Int, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		if (placeholder)
			return;
		playAnim(singAnimations[direction], force, reversed, frame);
	}

	public function miss(direction:Int, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		if (placeholder)
			return;
		playAnim(missAnimations[direction], force, reversed, frame);
	}

	private function findCharacterFile(character:String):String {
		var paths = [
			Paths.getPath('images/gameplay/characters/$character/config.json'),
			Paths.getPath('images/gameplay/characters/$character/$character.json'),
			Paths.getPath('images/gameplay/characters/$character/$character-config.json')
		];
		var path:String = paths[0];
		var found:Bool = false;
		for (i in paths) {
			if (Paths.fileExists(i)) {
				path = i;
				break;
			}
		}
		return path;
	}

	private function parseJsonIndicesField(field:Dynamic):Array<Int> {
		var indices:Array<Int> = field ?? null;
		if (field is String) {
			var minmax:Array<String> = field.split("...");
			indices = CoolUtil.numberArray(Std.parseInt(minmax[0]), Std.parseInt(minmax[1]));
		} else if (field is Array)
			indices = field;
		return indices;
	}

	public function loadCharacter(characterName:String):Character {
		switch (characterName) {
			default:
				var file:String = findCharacterFile(characterName);
				if (!Paths.fileExists(file)) {
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

				var file:Dynamic = Json5.parse(Paths.getText(file));
				trace('loading character $characterName');
				this.idleAnimations = file.idleAnimations ?? DEFAULT_IDLE_ANIMATIONS;
				this.singAnimations = file.singAnimations ?? DEFAULT_SING_ANIMATIONS;
				this.missAnimations = file.missAnimations ?? DEFAULT_MISS_ANIMATIONS;
				this.beatsToDance = file.beatsToDance ?? singAnimations.length >= 2 ? 1 : 2;
				this.singDuration = file.singDuration ?? 4.0;
				this.displayName = file.name ?? file.displayName ?? "idk";
				this.isPlayer = file.facesLeft ?? file.isPlayer ?? false;

				// TODO: file.atlasType, OR auto-detection based on files in folder -asmadeuxs
				if (file.texture != null)
					frames = Paths.getSparrowAtlas('${file.texture}');
				else
					frames = Paths.getSparrowAtlas('gameplay/characters/$characterName/$characterName');

				if (file.offsets != null) {
					for (key in Reflect.fields(file.offsets)) {
						var offset:Dynamic = Reflect.field(file.offsets, key);
						if (offset != null) {
							if (offset is Array)
								addOffset(key, offset[0] ?? 0, offset[1] ?? 0);
							else if (offset is Dynamic)
								addOffset(key, offset.x ?? 0, offset.y ?? 0);
						}
					}
				}
				if (file.animations != null) {
					var defaultFramerate:Int = file.defaultFramerate ?? 24;
					for (key in Reflect.fields(file.animations)) {
						var stuff:Dynamic = Reflect.field(file.animations, key);
						switch Type.typeof(stuff) {
							case TObject:
								stuff.looped = Std.string(stuff.looped);
								if (stuff.indices != null) {
									var indies:Array<Int> = parseJsonIndicesField(stuff.indices);
									animation.addByIndices(key, stuff.prefix, indies, "", stuff.frameRate ?? defaultFramerate, stuff.looped == "true");
								} else
									animation.addByPrefix(key, stuff.prefix, stuff.frameRate ?? defaultFramerate, stuff.looped == "true");
								if (stuff.offset != null) {
									if (stuff.offset is Array)
										addOffset(key, stuff.offset[0] ?? 0, stuff.offset[1] ?? 0);
									else if (stuff.offset is Dynamic)
										addOffset(key, stuff.offset.x ?? 0, stuff.offset.y ?? 0);
								}
							case TClass(String):
								animation.addByPrefix(key, stuff, defaultFramerate, false);
							case _:
								continue;
						}
					}
				}
				dance(true);
		}
		return this;
	}
}
