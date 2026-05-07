package gameplay;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class FunkinSprite extends FlxSprite {
	public var animOffsets:Map<String, Array<Float>>;

	public function new(x:Float, y:Float):Void {
		super(x, y);
		animOffsets = new Map<String, Array<Float>>();
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		animation.play(AnimName, Force, Reversed, Frame);
		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		// else
		//	offset.set(0, 0);
	}

	public function getOffset(name:String):Array<Float>
		return animOffsets[name];

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void
		animOffsets[name] = [x, y];
}
