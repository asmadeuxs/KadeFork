package;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Lib;

class MusicBeatState extends FlxUIState {
	private var controls(get, never):Controls;

	public var curStep(get, never):Int;
	public var curBeat(get, never):Int;

	function get_curStep()
		return Math.floor(Conductor.currentStep);

	function get_curBeat()
		return Math.floor(Conductor.currentBeat);

	inline function get_controls():Controls
		return Controls.current;

	override function create() {
		super.create();
		// if (!Preferences.user.skipTransitions)
		//	effects.Transition.playTransition(this, {out: true});
		Conductor.stepHit.add(stepHit);
		Conductor.beatHit.add(beatHit);
		Conductor.barHit.add(barHit);
	}

	// override function startOutro(_) {
	//	if (!Preferences.user.skipTransitions)
	//		effects.Transition.playTransition(this, {out: false});
	//	return super.startOutro(_);
	// }

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
