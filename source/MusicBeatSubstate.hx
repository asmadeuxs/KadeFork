package;

import flixel.FlxG;

class MusicBeatSubstate extends flixel.FlxSubState implements IBeatSynched {
	private var controls(get, never):Controls;

	public var curStep(get, never):Int;
	public var curBeat(get, never):Int;

	inline function get_controls():Controls
		return Controls.current;

	function get_curStep()
		return Math.floor(Conductor.currentStep);

	function get_curBeat()
		return Math.floor(Conductor.currentBeat);

	public function new() {
		super();
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
