package;

import flixel.FlxObject;
import flixel.util.FlxAxes;
import lime.utils.Assets;

using StringTools;

class CoolUtil {
	public static var pixelScale:Float = 6;
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];

	public static function objectCenter(o1:FlxObject, o2:FlxObject, centerType:FlxAxes = FlxAxes.XY) {
		if (centerType == X || centerType == XY)
			o1.x = o2.x + (o2.width - o1.width) * 0.5;
		if (centerType == Y || centerType == XY)
			o2.y = o2.y + (o2.height - o1.height) * 0.5;
		return o1;
	}

	public static function difficultyString(difficulty:Int):String
		return difficultyArray[difficulty];

	public static function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];

	public static function coolTextFile(path:String):Array<String> {
		var daList:Array<String> = Paths.getText(path).trim().split('\n');
		return [for (i in 0...daList.length) daList[i] = daList[i].trim()];
	}

	public static function coolStringFile(path:String):Array<String> {
		var daList:Array<String> = path.trim().split('\n');
		return [for (i in 0...daList.length) daList[i] = daList[i].trim()];
	}
}
