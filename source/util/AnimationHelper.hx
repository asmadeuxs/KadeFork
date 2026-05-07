package util;

import data.ConfigTypes;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfTwo;
import gameplay.FunkinSprite;

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
			var offset:FlxPoint = FlxPoint.get(0, 0);
			var looped:Bool = false;

			if (Std.isOfType(def, String))
				prefix = cast(def, String);
			else {
				var obj:JsonAnimation = cast def;
				if (obj == null || obj.prefix == null)
					continue;
				prefix = ConfigTypes.getAnimationPrefix(obj.prefix);
				if (obj.indices != null)
					indices = ConfigTypes.getAnimationIndices(obj.indices);
				if (obj.frameRate != null)
					frameRate = obj.frameRate;
				looped = obj.looped == true;
				if (obj.offset != null)
					offset = FlxPoint.get(obj.offset.x ?? 0, obj.offset.y ?? 0);
			}

			if (prefix == null)
				continue;

			if (indices != null && indices.length > 0)
				sprite.animation.addByIndices(animName, prefix, indices, "", frameRate, looped);
			else
				sprite.animation.addByPrefix(animName, prefix, frameRate, looped);

			if (offset != null && Std.isOfType(sprite, FunkinSprite)) {
				var fs:FunkinSprite = cast sprite;
				fs.addOffset(animName, offset.x, offset.y);
			}
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
}
