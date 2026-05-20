package gameplay;

import animate.FlxAnimate;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class FunkinSprite extends FlxAnimate {
	public var pivot:SpritePivot = SpritePivot.TOP_LEFT;
	public var animOffsets:Map<String, Array<Float>>;

	public function new(x:Float, y:Float):Void {
		super(x, y);
		animOffsets = new Map<String, Array<Float>>();
	}

	public function addAnimByPrefix(name:String, prefix:String, frameRate = 30.0, looped = true, flipX = false, flipY = false) {
		if (isAnimate)
			return anim.addBySymbol(name, prefix, frameRate, looped, flipX, flipY);
		else
			return animation.addByPrefix(name, prefix, frameRate, looped, flipX, flipY);
	}

	public function addAnimByIndices(name:String, prefix:String, indices:Array<Int>, frameRate:Float = 30, looped:Bool = true, flipX:Bool = false,
			flipY:Bool = false) {
		if (isAnimate)
			return anim.addBySymbolIndices(name, prefix, indices, frameRate, looped, flipX, flipY);
		else
			return animation.addByIndices(name, prefix, indices, "", frameRate, looped);
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		animation.play(AnimName, Force, Reversed, Frame);
		var off = animOffsets.get(AnimName);
		if (off != null) {
			var daOffsetX:Float = off[0];
			var daOffsetY:Float = off[1];
			if (checkFlipX())
				daOffsetX = -daOffsetX;
			if (checkFlipY())
				daOffsetY = -daOffsetY;
			offset.set(daOffsetX, daOffsetY);
		}
		else {
			offset.set(0, 0);
		}
	}

	public function updatePivot():Void {
		if (frameWidth <= 0 || frameHeight <= 0)
			return;
		origin.set(pivot.getPivotBaseX() * frameWidth, pivot.getPivotBaseY() * frameHeight);
	}

	public function getOffset(name:String):Array<Float>
		return animOffsets[name];

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void
		animOffsets[name] = [x, y];
}

enum abstract SpritePivot(String) from String to String {
	var TOP_LEFT = 'top_left'; // Original value
	var TOP_CENTER = 'top_center';
	var TOP_RIGHT = 'top_right';
	var CENTER_LEFT = 'center_left';
	var CENTER = 'center';
	var CENTER_RIGHT = 'center_right';
	var BOTTOM_LEFT = 'bottom_left';
	var BOTTOM_CENTER = 'bottom_center';
	var BOTTOM_RIGHT = 'bottom_right';

	public function getPivotBaseX():Float {
		return switch (this) {
			case TOP_LEFT, CENTER_LEFT, BOTTOM_LEFT: 0;
			case TOP_CENTER, CENTER, BOTTOM_CENTER: 0.5;
			case TOP_RIGHT, CENTER_RIGHT, BOTTOM_RIGHT: 1;
			case _: 0;
		}
	}

	public function getPivotBaseY():Float {
		return switch (this) {
			case TOP_LEFT, TOP_CENTER, TOP_RIGHT: 0;
			case CENTER_LEFT, CENTER, CENTER_RIGHT: 0.5;
			case BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT: 1;
			case _: 0;
		}
	}
}
