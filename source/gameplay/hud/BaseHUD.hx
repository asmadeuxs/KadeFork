package gameplay.hud;

import flixel.group.FlxSpriteGroup;

class BaseHUD extends FlxSpriteGroup {
	override public function new():Void {
		super();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
	}

	public function stepHit(step:Int):Void {}

	public function beatHit(beat:Int):Void {}
}
