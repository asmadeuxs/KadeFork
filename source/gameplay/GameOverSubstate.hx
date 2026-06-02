package gameplay;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameplay.PlayState;

class GameOverSubstate extends MusicBeatSubstate {
	var bf:Character;
	var camFollow:FlxObject;
	var dier:Character;

	public function new(dier:Character) {
		Conductor.current.active = false;
		this.dier = dier;
		super();

		Conductor.bpm = 100;
		Conductor.setTime(0.0);

		var x:Float = dier.getScreenPosition().x;
		var y:Float = dier.getScreenPosition().y;

		add(bf = new Character(x, y, dier.deathCharacter, PLAYER));
		add(camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1));

		FlxG.sound.play(Paths.sound(dier.deathCrackSfx));

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width * 0.5, FlxG.height * 0.5));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.ACCEPT)
			endBullshit();

		if (controls.BACK) {
			FlxG.sound.music.stop();
			if (PlayState.playlist != null && PlayState.playlist.isStory())
				util.StateOverride.switchState("menus.StoryMenuState");
			else
				util.StateOverride.switchState("menus.FreeplayState");
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
			FlxG.camera.follow(camFollow, LOCKON, 0.01);

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished) {
			FlxG.sound.playMusic(Paths.music(dier.gameOverMusic));
			Conductor.current.active = true;
		}
	}

	override function beatHit(beat:Int) {
		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
			bf.playAnim('deathLoop');
	}

	var isEnding:Bool = false;

	function endBullshit():Void {
		if (!isEnding) {
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(dier.deathConfirmSfx));
			new FlxTimer().start(0.7, function(tmr:FlxTimer) {
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
					FlxG.switchState(new gameplay.PlayState());
				});
			});
		}
	}
}
