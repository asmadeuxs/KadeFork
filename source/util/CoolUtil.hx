package util;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;

class CoolUtil {
	public static var pixelScale:Float = 6;
	public static var defaultDifficulties:Array<String> = ['easy', "normal", "hard"];

	public static function formatEscapeStrings(text:String):String {
		return text.replace("\\\\", "\\").replace("\\r", "\r").replace("\\n", "\n").replace("\\t", "\r").replace("\\'", "'");
	}

	public static function coolList(str:String):Array<String> {
		var daList:Array<String> = str.trim().split('\n');
		return [for (i in 0...daList.length) daList[i] = daList[i].trim()];
	}

	public static function makeScaledGraphic(sprite:FlxSprite, x:Float, y:Float, color:FlxColor = FlxColor.WHITE, ?updateHitbox:Bool = true):FlxSprite {
		if (sprite == null)
			sprite = new FlxSprite();
		sprite.makeGraphic(1, 1, color);
		sprite.scale.set(x, y);
		if (updateHitbox)
			sprite.updateHitbox();
		return sprite;
	}

	public static function objectCenter(o1:FlxObject, o2:FlxObject, centerType:FlxAxes = FlxAxes.XY) {
		if (centerType == X || centerType == XY)
			o1.x = o2.x + (o2.width - o1.width) * 0.5;
		if (centerType == Y || centerType == XY)
			o1.y = o2.y + (o2.height - o1.height) * 0.5;
		return o1;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];

	private var commentStarters = ["//", "#", "--"];

	public static function isComment(line:String):Bool
		return line.startsWith("#") || line.startsWith("//") || line.startsWith("--") || line.startsWith("/*") && line.endsWith("*/");

	public static function coolTextFile(path:String, ?noTrim:Bool = false):Array<String> {
		var file:String = Paths.getText(path);
		if (!noTrim)
			file = file.trim();
		var daList:Array<String> = file.split('\n');
		for (i => t in daList) {
			t = t.trim();
			if (t.length == 0 || isComment(t))
				daList.remove(t);
		}
		return [for (i in 0...daList.length) daList[i] = !noTrim ? daList[i].trim() : daList[i]];
	}
}
