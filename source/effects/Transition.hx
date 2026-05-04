package effects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

using util.CoolUtil;

typedef TransitionOptions = {
	?color:Null<FlxColor>,
	?duration:Null<Float>,
	?ease:EaseFunction,
	?onFinish:Void->Void,
	out:Bool,
}

class Transition extends FlxSubState {
	public static var skipNextStateIn:Bool = false;
	public static var skipNextStateOut:Bool = false;

	public static var skipNextSubstateIn:Bool = false;
	public static var skipNextSubstateOut:Bool = false;

	public static function playTransition(target:flixel.FlxState, options:TransitionOptions) {
		var isSub:Bool = Std.isOfType(target, FlxSubState) || Std.isOfType(target, MusicBeatSubstate);
		if (isSub) {
			if (!skipNextSubstateIn && !skipNextSubstateOut)
				target.openSubState(new Transition(options));
		} else {
			if (!skipNextStateIn && !skipNextStateOut)
				target.openSubState(new Transition(options));
		}
		skipNextSubstateOut = false;
		skipNextSubstateOut = false;
		skipNextStateIn = false;
		skipNextStateOut = false;
	}

	var onFinish:Void->Void;
	var options:TransitionOptions;
	var defaultColor:FlxColor = FlxColor.BLACK;
	var defaultEaseIn:EaseFunction = FlxEase.cubeIn;
	var defaultEaseOut:EaseFunction = FlxEase.cubeOut;
	var defaultDuration:Float = 1.0;

	public function new(options:TransitionOptions):Void {
		if (options.duration == null)
			options.duration = defaultDuration;
		if (options.ease == null)
			options.ease = options.out ? defaultEaseOut : defaultEaseIn;
		if (options.color == null)
			options.color = defaultColor;
		this.onFinish = options.onFinish;
		this.options = options;
		super();
	}

	var tween:FlxTween;

	override function create() {
		super.create();
		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		var colors:Array<FlxColor> = [FlxColor.TRANSPARENT, FlxColor.TRANSPARENT];
		colors[options.out ? 1 : 0] = FlxColor.BLACK;

		var grad:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, colors);
		grad.scrollFactor.set();
		grad.screenCenter(X);
		grad.updateHitbox();
		add(grad);

		var complete = (_:FlxTween) -> {
			if (onFinish != null)
				onFinish();
			close();
		}
		if (!options.out) {
			grad.y = 0;
			tween = FlxTween.tween(grad, {y: grad.height}, options.duration, {
				ease: options.ease,
				onComplete: complete
			});
		} else {
			grad.y = grad.height;
			tween = FlxTween.tween(grad, {y: 0}, options.duration, {
				ease: options.ease,
				onComplete: complete
			});
		}
	}
}
