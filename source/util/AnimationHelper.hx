package util;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfTwo;
import gameplay.FunkinSprite;

// private typedef OffsetField = {x:Float, y:Float};

typedef AnimationDef = {
	?prefix:String,
	?indices:OneOfTwo<String, Array<Int>>,
	?frameRate:Int,
	?looped:Bool,
	?offset:Dynamic
}

class AnimationHelper {
	public static function addFromJson(sprite:FlxSprite, data:Dynamic, defaultFramerate:Int, ?onAddAnim:(name:String) -> Void):Void {
		if (data == null)
			return;

		var fields = Reflect.fields(data);
		for (name in fields) {
			var def = Reflect.field(data, name);
			if (def == null)
				continue;

			var animName:String = name;
			var prefix:String = null;
			var indices:Array<Int> = null;
			var frameRate:Int = defaultFramerate;
			var looped:Bool = false;
			var offset:FlxPoint = null;

			if (Std.isOfType(def, String)) {
				prefix = cast(def, String);
			} else if (Std.isOfType(def, Dynamic)) {
				var obj:AnimationDef = def;
				prefix = obj.prefix;
				if (obj.indices != null)
					indices = parseIndices(obj.indices);
				frameRate = obj.frameRate != null ? obj.frameRate : defaultFramerate;
				looped = obj.looped == true;
				if (obj.offset != null)
					offset = parseOffset(obj.offset);
			} else
				continue;

			if (prefix == null)
				continue;

			if (indices != null && indices.length > 0)
				sprite.animation.addByIndices(animName, prefix, indices, "", frameRate, looped);
			else
				sprite.animation.addByPrefix(animName, prefix, frameRate, looped);

			if (offset != null && sprite is FunkinSprite)
				cast(sprite, FunkinSprite).addOffset(animName, offset.x ?? 0, offset.y ?? 0);

			if (onAddAnim != null)
				onAddAnim(animName);
		}
	}

	public static function addOffsetsFromJson(sprite:FunkinSprite, data:Dynamic):Void {
		if (data == null)
			return;
		for (key in Reflect.fields(data)) {
			var offset:Dynamic = Reflect.field(data, key);
			if (offset != null) {
				if (offset is Array)
					sprite.addOffset(key, offset[0] ?? 0, offset[1] ?? 0);
				else if (offset is Dynamic)
					sprite.addOffset(key, offset.x ?? 0, offset.y ?? 0);
			}
		}
	}

	private static function parseIndices(indicesDef:OneOfTwo<String, Array<Int>>):Array<Int> {
		if (indicesDef is String) {
			var parts = Std.string(indicesDef).split("...");
			var start = Std.parseInt(parts[0]);
			var end = Std.parseInt(parts[1]);
			return [for (i in start...end + 1) i];
		} else if (indicesDef is Array)
			return indicesDef;
		else
			return [];
	}

	private static function parseOffset(offsetDef:Dynamic):FlxPoint {
		if (offsetDef is Array)
			return FlxPoint.get(offsetDef[0] ?? 0, offsetDef[1] ?? 0);
		else if (offsetDef is Dynamic)
			return FlxPoint.get(offsetDef.x ?? 0, offsetDef.y ?? 0);
		else
			return FlxPoint.get(0, 0);
	}
}
