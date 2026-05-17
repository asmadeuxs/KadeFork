package flixel.addons.transition;

import flixel.FlxState;

/**
 * A `FlxState` which can perform visual transitions
 *
 * Usage:
 *
 * First, extend `FlxTransitionableState` as ie, `FooState`.
 *
 * Method 1:
 *
 * ```haxe
 * var in:TransitionData = new TransitionData(...); // add your data where "..." is
 * var out:TransitionData = new TransitionData(...);
 *
 * FlxG.switchState(new FooState(in,out));
 * ```
 *
 * Method 2:
 *
 * ```haxe
 * FlxTransitionableState.defaultTransIn = new TransitionData(...);
 * FlxTransitionableState.defaultTransOut = new TransitionData(...);
 *
 * FlxG.switchState(new FooState());
 * ```
 */
class FlxTransitionableState extends FlxState {
	private static var prevTransCam:FlxCamera;

	// global default transitions for ALL states, used if transIn/transOut are null
	public static var defaultTransIn:TransitionData = null;
	public static var defaultTransOut:TransitionData = null;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	// beginning & ending transitions for THIS state:
	public var transIn:TransitionData;
	public var transOut:TransitionData;

	public var hasTransIn(get, never):Bool;
	public var hasTransOut(get, never):Bool;

	public var transCam:FlxCamera;

	/**
	 * Create a state with the ability to do visual transitions
	 * @param	TransIn		Plays when the state begins
	 * @param	TransOut	Plays when the state ends
	 */
	public function new(?TransIn:TransitionData, ?TransOut:TransitionData) {
		transIn = TransIn;
		transOut = TransOut;
		if (transIn == null && defaultTransIn != null)
			transIn = defaultTransIn;
		if (transOut == null && defaultTransOut != null)
			transOut = defaultTransOut;
		super();
	}

	override function destroy():Void {
		prevTransCam = transCam;
		transCam = null;
		transIn = null;
		transOut = null;
		_onExit = null;
		super.destroy();
	}

	override function create():Void {
		var index:Int = FlxG.cameras.list.indexOf(prevTransCam);
		if (index != -1)
			transCam = prevTransCam;
		else
			transCam = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		super.create();
		transitionIn();
	}

	override function startOutro(onOutroComplete:() -> Void) {
		if (!hasTransOut)
			onOutroComplete();
		else if (!_exiting) {
			// play the exit transition, and when it's done call FlxG.switchState
			_exiting = true;
			transitionOut(onOutroComplete);
			if (skipNextTransOut) {
				skipNextTransOut = false;
				finishTransOut();
			}
		}
	}

	/**
	 * Starts the in-transition. Can be called manually at any time.
	 */
	public function transitionIn():Void {
		if (transIn != null && transIn.type != NONE) {
			if (skipNextTransIn) {
				skipNextTransIn = false;
				if (finishTransIn != null)
					finishTransIn();
				return;
			}

			var _trans = createTransition(transIn);
			if (transCam != null)
				_trans.camera = transCam;
			_trans.setStatus(FULL);
			openSubState(_trans);

			_trans.finishCallback = finishTransIn;
			_trans.start(OUT);
		}
	}

	/**
	 * Starts the out-transition. Can be called manually at any time.
	 */
	public function transitionOut(?OnExit:Void->Void):Void {
		_onExit = OnExit;
		if (hasTransOut) {
			var _trans = createTransition(transOut);
			if (transCam != null)
				_trans.camera = transCam;
			_trans.setStatus(EMPTY);
			openSubState(_trans);
			_trans.finishCallback = finishTransOut;
			_trans.start(IN);
		}
		else {
			_onExit();
		}
	}

	var transOutFinished:Bool = false;

	var _exiting:Bool = false;
	var _onExit:Void->Void;

	function get_hasTransIn():Bool {
		return transIn != null && transIn.type != NONE;
	}

	function get_hasTransOut():Bool {
		return transOut != null && transOut.type != NONE;
	}

	function createTransition(data:TransitionData):Transition {
		return switch (data.type) {
			case TILES: new Transition(data);
			case FADE: new Transition(data);
			default: null;
		}
	}

	function finishTransIn() {
		closeSubState();
	}

	function finishTransOut() {
		transOutFinished = true;
		if (!_exiting)
			closeSubState();
		if (_onExit != null)
			_onExit();
	}
}
