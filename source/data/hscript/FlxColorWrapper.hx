package data.hscript;

import flixel.util.FlxColor;

// copy of FlxColor but as a class so hscript can use it.
class FlxColorWrapper {
	public final TRANSPARENT:FlxColor = 0x00000000;
	public final WHITE:FlxColor = 0xFFFFFFFF;
	public final GRAY:FlxColor = 0xFF808080;
	public final BLACK:FlxColor = 0xFF000000;
	public final GREEN:FlxColor = 0xFF008000;
	public final LIME:FlxColor = 0xFF00FF00;
	public final YELLOW:FlxColor = 0xFFFFFF00;
	public final ORANGE:FlxColor = 0xFFFFA500;
	public final RED:FlxColor = 0xFFFF0000;
	public final PURPLE:FlxColor = 0xFF800080;
	public final BLUE:FlxColor = 0xFF0000FF;
	public final BROWN:FlxColor = 0xFF8B4513;
	public final PINK:FlxColor = 0xFFFFC0CB;
	public final MAGENTA:FlxColor = 0xFFFF00FF;
	public final CYAN:FlxColor = 0xFF00FFFF;

	public function new():Void {}

	public function fromInt(Value:Int):FlxColor
		return FlxColor.fromInt(Value);

	public function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
		return FlxColor.fromRGB(Red, Green, Blue, Alpha);

	public function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
		return FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);

	public function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
		return FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);

	public function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor
		return FlxColor.fromHSB(Hue, Saturation, Brightness, Alpha);

	public function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor
		return FlxColor.fromHSL(Hue, Saturation, Lightness, Alpha);

	public function fromString(str:String):Null<FlxColor>
		return FlxColor.fromString(str);
}
