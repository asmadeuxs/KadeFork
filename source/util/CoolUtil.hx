package util;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import lime.utils.Assets;

using StringTools;

@:keep
class CoolUtil {
	public static var stringFormatters:Map<String, (Dynamic) -> String> = [
		"moneyEN" => (v:Float) -> FlxStringUtil.formatMoney(v, true, true),
		"moneyEU" => (v:Float) -> FlxStringUtil.formatMoney(v, true, false),
		"time" => (v:Float) -> FlxStringUtil.formatTime(v, false),
		"timeMs" => (v:Float) -> FlxStringUtil.formatTime(v, true),
		"bytes" => (v:Float) -> FlxStringUtil.formatBytes(v, 2),
		"percent" => (v:Float) -> return '${FlxMath.roundDecimal(v * 100, 1)}%'
	];

	public static function formatValue(value:Float, format:String):String {
		if (stringFormatters.exists(format))
			return stringFormatters.get(format)(value);

		if (format.indexOf("%d") >= 0 || format.indexOf("%i") >= 0)
			return Std.string(Std.int(value));

		var decimalPlaces:Int = -1;
		var regex = ~/%\.([0-9]+)f/;
		if (regex.match(format))
			decimalPlaces = Std.parseInt(regex.matched(1));
		else if (format.indexOf("%f") >= 0)
			decimalPlaces = 6;

		if (decimalPlaces >= 0) {
			var rounded:Float = FlxMath.roundDecimal(value, decimalPlaces);
			var str = Std.string(rounded);
			if (!str.contains("."))
				str += ".";
			var frac:String = str.split(".")[1];
			while (frac.length < decimalPlaces) {
				frac += "0";
				str = str.split(".")[0] + "." + frac;
			}
			return str;
		}
		return Std.string(value);
	}

	public static function arrayEquals(a:Array<Dynamic>, b:Array<Dynamic>):Bool {
		if (a.length != b.length)
			return false;
		for (i in 0...a.length)
			if (a[i] != b[i])
				return false;
		return true;
	}

	public static function formatEscapeStrings(text:String):String {
		return text.replace("\\\\", "\\").replace("\\r", "\r").replace("\\n", "\n").replace("\\t", "\r").replace("\\'", "'");
	}

	public static var pixelScale:Float = 6;
	public static var defaultDifficulties:Array<String> = ['easy', "normal", "hard"];

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

	// i stole this from neb thanks neb NebulaZorua -asmadeuxs
	public static function dominantColor(sprite:FlxSprite, ?ignoreColors:Array<FlxColor>):Int {
		if (sprite.pixels == null)
			return FlxColor.TRANSPARENT;
		var counts:Map<Int, Int> = [];
		var colorsToDiscard:Map<Int, Bool> = null;

		if (ignoreColors != null && ignoreColors.length > 0) {
			colorsToDiscard = [];
			for (col in ignoreColors)
				colorsToDiscard[col] = true;
		}
		var mapLen:Int = 0;

		for (x in 0...sprite.pixels.width) {
			for (y in 0...sprite.pixels.height) {
				var col:FlxColor = sprite.pixels.getPixel32(x, y);
				if (col.alphaFloat <= 0.05)
					continue;
				var current:FlxColor = FlxColor.fromRGB(col.red, col.green, col.blue, 255);
				if (colorsToDiscard != null && colorsToDiscard.exists(current))
					continue;
				counts[current] = (counts[current] ?? 0) + 1;
				mapLen++;
			}
		}

		colorsToDiscard.clear();
		ignoreColors.resize(0);
		colorsToDiscard = null;
		ignoreColors = null;

		if (mapLen <= 0)
			return FlxColor.TRANSPARENT;

		var maxCount:Int = 0;
		var dominant:FlxColor = 0;
		for (colorInt => count in counts) {
			if (count > maxCount) {
				maxCount = count;
				dominant = colorInt;
			}
		}
		return dominant;
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
