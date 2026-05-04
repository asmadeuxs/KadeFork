package;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;

class MusicBeatSubstate extends FlxSubState {
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.current;

	public function new() {
		super();
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
