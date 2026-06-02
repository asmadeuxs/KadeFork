package gameplay;

/**
 * For sprites that have beat-synched animations
 *
 * WANRING: Dance checks are not done automatically for the sake of control
 *
 * Override the update function manually and call `danceBeatCheck`
 *
 * If you want animation cooldowns to also work, call `danceCooldownCheck` (needs `elapsed` value passed onto the function)
**/
class DancerSprite extends ui.FunkinSprite {
	public static final DEFAULT_IDLE_ANIMATIONS:Array<String> = ["idle"];

	public var idleAnimations:Array<String> = DEFAULT_IDLE_ANIMATIONS;
	public var beatsToDance:Float = 2;
	public var danceSpeed:Float = 1;

	public var danceCooldown:Float = 0.0;
	public var animDuration:Map<String, Float> = ['default' => 1.0];
	public var pauseDance:Bool = false;

	private var currentDance:Int = 0;

	public function danceCooldownCheck(elapsed:Float):Void {
		var dur:Float = getAnimDuration();
		danceCooldown -= elapsed / dur;
		if (danceCooldown <= 0.0)
			dance(true);
	}

	var _nextDanceBeat:Float = -1.0;
	var _lastInterval:Float = -1.0;

	public function danceBeatCheck():Void {
		var interval:Float = beatsToDance / danceSpeed;
		if (interval <= 0)
			return;

		if (_nextDanceBeat < 0)
			_nextDanceBeat = Conductor.currentBeat + interval;

		if (Conductor.currentBeat >= _nextDanceBeat) {
			dance(true);
			_nextDanceBeat += interval;
			if (Conductor.currentBeat > _nextDanceBeat + interval)
				_nextDanceBeat = Conductor.currentBeat + interval;
		}
	}

	public function dance(?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0) {
		playAnim(idleAnimations[currentDance], force, reversed, frame);
		currentDance = flixel.math.FlxMath.wrap(currentDance + 1, 0, idleAnimations.length - 1);
	}

	/**
	 * Returns the current animation duration
	 * @param anim String (leave unspecified to get from the current animation or the default cooldown)
	**/
	public function getAnimDuration(?anim:Null<String>):Float {
		if (anim == null && animation != null && animation.curAnim != null)
			anim = animation?.curAnim?.name;
		var f:Float = 1.0;
		if (animDuration.exists(anim))
			f = animDuration.get(anim);
		else if (animDuration.exists('default'))
			f = animDuration.get('default');
		return f;
	}

	public function getCurrentDanceIndex():Int
		return currentDance;
}
