package gameplay.hud;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;

class BaseHUD extends FlxSpriteGroup {
	public var healthBar:FlxBar;
	public var scoreTxt:FlxText;

	public function new():Void {
		super();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
	}

	public function updateScoreText(?miss:Bool) {}

	public function stepHit(step:Int):Void {}

	public function beatHit(beat:Int):Void {}
}
