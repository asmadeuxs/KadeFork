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

class GenericMenuState extends MusicBeatState {
	public var menuScrollType:MenuVerticalStyle = MenuVerticalStyle.VERTICAL;
	public var canInput:Bool = true;

	public var curVertical:Int = 0;
	public var minVerticals:Int = 0;
	public var maxVerticals:Int = 1;

	public var curHorizontal:Int = 0;
	public var minHorizontals:Int = 0;
	public var maxHorizontals:Int = 1;

	public var verticalKeyRepeat:Bool = true;
	public var horizontalKeyRepeat:Bool = true;

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
		if (canInput) {
			if (verticalKeyRepeat || horizontalKeyRepeat)
				Controls.current.update(elapsed);
			handleInput();
		}
	}

	public function handleInput():Void {
		if (controls.BACK_P)
			onBackPressed();
		if (controls.ACCEPT_P)
			onAcceptPressed(curVertical, curHorizontal);

		if (menuScrollType == VERTICAL || menuScrollType == BOTH) {
			var up:Bool = controls.UP_P;
			var vf:Int = verticalFactor;
			if (verticalKeyRepeat) {
				var uprpt:Bool = controls.UP_RPT;
				if (up || uprpt || controls.DOWN_P || controls.DOWN_RPT)
					changeVertical(((up || uprpt) ? -vf : vf));
			}
			else
				changeVertical(up ? -vf : vf);
		}
		if (menuScrollType == HORIZONTAL || menuScrollType == BOTH) {
			var left:Bool = controls.LEFT_P;
			var hf:Int = horizontalFactor;
			if (horizontalKeyRepeat) {
				var leftrpt:Bool = controls.LEFT_RPT;
				if (left || leftrpt || controls.RIGHT_P || controls.RIGHT_RPT)
					changeHorizontal((left || leftrpt) ? -hf : hf);
			}
			else
				changeHorizontal(left ? -hf : hf);
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
