package gameplay;

import flixel.FlxG;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

class CharacterBase extends gameplay.FunkinSprite {
	public static final DEFAULT_CHARACTER:String = "bf";
	public static final DEFAULT_SING_ANIMATIONS:Array<String> = "singLEFT,singDOWN,singUP,singRIGHT".split(",");

	public var displayName:String = "idk";
	public var characterFile:String = DEFAULT_CHARACTER;

	public var singDuration:Float = 4.0;
	public var animationTimer:Float = 0.0;
	public var isPlayer:Bool = false;

	public var singingAnimations:Array<String> = [];
	public var missingAnimations:Array<String> = [];

	public function new(x:Float = 0, y:Float = 0, filename:String):Void {
		super(x, y);
		this.characterFile = filename;
		loadCharacter(this.characterFile);
	}

	private function findCharacterFile(character:String):String {
		var paths = [
			Paths.getPath('gameplay/characters/$character/config.json', TEXT),
			Paths.getPath('gameplay/characters/$character/$character.json', TEXT),
			Paths.getPath('gameplay/characters/$character/$character-config.json', TEXT)
		];
		var path:String = paths[0];
		var found:Bool = false;
		var index:Int = 0;
		while (!found) {
			if (Assets.exists(paths[index])) {
				path = paths[index];
				found = true;
				break;
			}
			index++;
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

	public function loadCharacter(filename:String):Void {
		switch (filename) {
			default:
				var file:Dynamic = Json.parse(Assets.getText(findCharacterFile(filename)));
				this.singingAnimations = file.singingAnimations ?? DEFAULT_SING_ANIMATIONS;
				if (file.missingAnimations != null)
					this.missingAnimations = file.missingAnimations;
				this.singDuration = file.singDuration ?? 4.0;
				this.displayName = file.name ?? file.displayName ?? "idk";
				this.isPlayer = file.facesLeft ?? file.isPlayer ?? false;

				if (file.texture != null)
					frames = Paths.getSparrowAtlas('${file.texture}');
				else
					frames = Paths.getSparrowAtlas('gameplay/characters/$filename/$filename');

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
		}
	}
}
