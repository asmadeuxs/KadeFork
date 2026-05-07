package data;

import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfTwo;
import haxe.DynamicAccess;

class ConfigTypes {
	// helper functions
	// i don't like them. -asmadeuxs
	public static function normalizeAnimation(def:AnimationDef, defaultFramerate:Int):AnimationDef {
		if (Std.isOfType(def, String)) {
			return {
				prefix: cast(def, String),
				frameRate: defaultFramerate,
				offset: {x: 0, y: 0},
				indices: null,
				looped: false
			};
		}
		var obj:JsonAnimation = cast def;
		if (obj.frameRate == null)
			obj.frameRate = defaultFramerate;
		return obj;
	}

	public static function getTexturePath(raw:Dynamic):String
		return Std.isOfType(raw, String) ? raw : raw.path;

	public static function getAtlasType(raw:Dynamic, defaultType:String = "sparrow"):String
		return Std.isOfType(raw, String) ? defaultType : (raw.atlasType ?? defaultType);

	public static function getAnimationPrefix(raw:Dynamic):String
		return Std.isOfType(raw, String) ? raw : raw.prefix;

	public static function getAnimationIndices(raw:Dynamic):Array<Int> {
		if (Std.isOfType(raw, String))
			return null;

		var indices:Dynamic = raw.indices;
		if (indices == null)
			return null;

		if (Std.isOfType(indices, String)) {
			var parts:Array<String> = Std.string(indices).split("...");
			var start:Int = Std.parseInt(parts[0]);
			var end:Int = Std.parseInt(parts[1]);
			return [for (i in start...end + 1) i];
		}

		if (Std.isOfType(indices, Array)) {
			var arr:Array<Dynamic> = indices;
			var result:Array<Int> = [];
			for (item in arr) {
				if (Std.isOfType(item, Int)) {
					result.push(item);
				} else if (Std.isOfType(item, String)) {
					var parts:Array<String> = Std.string(item).split("...");
					var start:Int = Std.parseInt(parts[0]);
					var end:Int = Std.parseInt(parts[1]);
					for (i in start...end + 1)
						result.push(i);
				}
			}
			return result;
		}

		return indices;
	}

	public static function getAnimationOffset(raw:Dynamic):Null<{x:Float, y:Float}> {
		if (Std.isOfType(raw, String))
			return null;
		var off:Dynamic = raw.offset;
		if (off == null)
			return null;
		if (Std.isOfType(off, Array))
			return {x: off[0], y: off[1]};
		return off;
	}
}

typedef TextureConfig = {path:String, ?atlasType:String};
// --- Animations ---

typedef JsonOffsetField = {x:Float, y:Float}

typedef JsonAnimation = {
	prefix:String,
	?indices:Array<Int>,
	?offset:JsonOffsetField,
	?frameRate:Int,
	?looped:Bool,
}

typedef AnimationDef = OneOfTwo<String, JsonAnimation>;

// --- Level Data ---

typedef LevelLabel = {
	texture:TextureConfig,
	?animations:AnimationDef,
	?offsets:JsonOffsetField
}

typedef LevelSong = {
	name:String,
	folder:String,
	?album:String,
	?icon:String,
	?difficulties:Array<String>,
}

typedef LevelData = {
	tagline:String,
	difficulties:Array<String>,
	labelObject:LevelLabel,
	songs:Array<LevelSong>
}

// --- Character Data ---

typedef CharacterConfig = {
	name:String,
	displayName:String,
	texture:TextureConfig,
	facesLeft:Bool,
	?idleAnimations:Array<String>,
	?singAnimations:Array<String>,
	?missAnimations:Array<String>,
	?beatsToDance:Int,
	?singDuration:Float,
	?antialiasing:Bool,
	?defaultFramerate:Int,
	?animations:AnimationDef,
	?offsets:JsonOffsetField,
	?cameraOffset:JsonOffsetField
}

// --- Stage Data ---

typedef StageFile = {
	?name:String,
	?cameraZoom:Float,
	?defaultAntialiasing:Bool,
	?characterOffsets:Dynamic,
	objects:Array<StageObject>
}

typedef StageObject = {
	name:String,
	texture:DynamicAccess<TextureConfig>,
	position:Array<Float>,
	?defaultFramerate:Int,
	?defaultAnimation:String,
	?visible:OneOfTwo<String, Bool>,
	?animations:AnimationDef,
	?scrollFactor:OneOfTwo<Array<Float>, Float>,
	?scale:OneOfTwo<Array<Float>, Float>,
	?color:OneOfTwo<Array<Int>, String>,
	?antialiasing:Bool,
	?id:Int
}

// --- Noteskin Data ---

private typedef StrumConfig = {
	animations:StrumAnimations,
	?atlas:TextureConfig,
	?antialiasing:Bool,
	?scale:Float
}

typedef NoteskinFile = {
	?name:String,
	?author:String,
	?atlasType:String,
	?keyCount:Int,
	?defaultFramerate:Int,
	?offsets:Array<Float>,
	defaultAtlas:TextureConfig,
	strums:StrumConfig,
	?holds:NoteAnimations,
	?arrows:NoteAnimations & {?scale:Float},
	?splashes:NoteAnimations & {?scale:Float}
}

typedef StrumAnimations = {
	animStatic:Array<AnimationDef>,
	animPressed:Array<AnimationDef>,
	animConfirm:Array<AnimationDef>,
	?animHolding:Array<AnimationDef>
}

typedef NoteAnimations = {
	animations:Array<AnimationDef>,
	?antialiasing:Bool,
	?atlas:TextureConfig
}
