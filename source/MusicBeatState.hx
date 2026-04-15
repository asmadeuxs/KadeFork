package;

import data.ScriptLoader;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Lib;

class MusicBeatState extends FlxUIState {
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.current;

	public var curStep(get, never):Int;
	public var curBeat(get, never):Int;

	function get_curStep()
		return Math.floor(Conductor.currentStep);

	function get_curBeat()
		return Math.floor(Conductor.currentBeat);

	override function create() {
		super.create();
		Conductor.stepHit.add(stepHit);
		Conductor.beatHit.add(beatHit);
		Conductor.barHit.add(barHit);
	}

	override function destroy() {
		super.destroy();
		Conductor.stepHit.remove(stepHit);
		Conductor.beatHit.remove(beatHit);
		Conductor.barHit.remove(barHit);
	}

	public function stepHit(step:Int):Void {}

	public function beatHit(beat:Int):Void {}

	public function barHit(bar:Int):Void {}
}
