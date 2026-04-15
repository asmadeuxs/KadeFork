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

	var stageSuffix:String = "";

	public function new(x:Float, y:Float) {
		stageSuffix = PlayState.current.boyfriend.gameOverSuffix;

		super();

		Conductor.bpm = 100;
		Conductor.current.active = false;
		Conductor.setTime(0.0);

		add(bf = new Character(x, y, PlayState.current.boyfriend.deathCharacter, true));
		add(camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1));

		FlxG.sound.play(Paths.sound('fnf_loss_sfx$stageSuffix'));

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
			// if (PlayState.isStoryMode)
			//	FlxG.switchState(new menus.StoryMenuState());
			// else
			FlxG.switchState(new menus.FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
			FlxG.camera.follow(camFollow, LOCKON, 0.01);

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
			FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));
		if (FlxG.sound.music.playing)
			Conductor.current.active = true;
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
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer) {
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
					FlxG.switchState(new gameplay.PlayState());
				});
			});
		}
	}
}
