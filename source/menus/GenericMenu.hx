package menus;

import flixel.FlxG;
import util.Mods;

typedef SimpleMenuButton = {
	name:String,
	func:() -> Void
}

enum MenuVerticalStyle {
	VERTICAL;
	HORIZONTAL;

	/**
	 * "BOTH" as in Both- Horizontal and Vertical
	**/
	BOTH;
}

class GenericMenu extends MusicBeatSubstate {
	public var menuScrollType:MenuVerticalStyle = MenuVerticalStyle.VERTICAL;
	public var canInput:Bool = true;

	public var curVertical:Int = 0;
	public var minVerticals:Int = 0;
	public var maxVerticals:Int = 1;

	public var curHorizontal:Int = 0;
	public var minHorizontals:Int = 0;
	public var maxHorizontals:Int = 1;

	/**
	 * Changes the item by this much when pressing up/down
	**/
	public var verticalFactor:Int = 1;

	/**
	 * Changes the item by this much when pressing left/right
	**/
	public var horizontalFactor:Int = 1;

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (canInput)
			handleInput();
	}

	public function handleInput():Void {
		if (controls.BACK_P)
			onBackPressed();
		if (controls.ACCEPT_P)
			onAcceptPressed(curVertical, curHorizontal);

		if (menuScrollType == VERTICAL || menuScrollType == BOTH) {
			var up:Bool = controls.UP_P;
			if (up || controls.DOWN_P)
				changeVertical(up ? -verticalFactor : verticalFactor);
		}
		if (menuScrollType == HORIZONTAL || menuScrollType == BOTH) {
			var left:Bool = controls.LEFT_P;
			if (left || controls.RIGHT_P)
				changeHorizontal(left ? -horizontalFactor : horizontalFactor);
		}
	}

	public function changeVertical(next:Int = 0) {
		curVertical = flixel.math.FlxMath.wrap(curVertical + next, minVerticals, maxVerticals);
		onVerticalChanged(curVertical);
	}

	public function changeHorizontal(next:Int = 0) {
		curHorizontal = flixel.math.FlxMath.wrap(curHorizontal + next, minHorizontals, maxHorizontals);
		onHorizontalChanged(curHorizontal);
	}

	public function onBackPressed():Void {}

	public function onVerticalChanged(selected:Int):Void {}

	public function onHorizontalChanged(selected:Int):Void {}

	public function onAcceptPressed(v:Int, h:Int):Void {}
}
