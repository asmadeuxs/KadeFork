package;

import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Lib;

class MusicBeatState extends flixel.addons.transition.FlxTransitionableState implements IBeatSynched {
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
		Conductor.connectSynched(this);
	}

	override function destroy() {
		Conductor.disconnectSynched(this);
		super.destroy();
	}

	public function stepHit(step:Int):Void {}

	public function beatHit(beat:Int):Void {}

	public function barHit(bar:Int):Void {}
}
