package gameplay.note;

import data.Noteskin;
import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import gameplay.FunkinSprite;
import util.ObjectPool;

using util.CoolUtil;

@:access(gameplay.Note)
class Strumline extends FlxTypedSpriteGroup<FunkinSprite> {
	public var scrollSpeed:Null<Float> = null;
	public var keyCount:Int = 4;
	public var noteskin:Noteskin;

	public var strums:Array<FunkinSprite> = [];

	var splashPool:ObjectPool<FunkinSprite>;
	var speeds:Array<Null<Float>> = [];
	var downscroll:Array<Int> = [];

	public function new(?keyCount:Int = 4):Void {
		super(0, 0);
		this.keyCount = keyCount;
		var skin:String = 'default'; // hardcoded for now
		noteskin = Noteskin.loadNoteskinFile(skin);
		splashPool = new ObjectPool(16, (_) -> return add(noteskin.generateNoteSplashSprite()));
		generateStrums();
	}

	public function spawnSplash(noteData:Int, ?note:Note, ?x:Float = 0, ?y:Float = 0):Bool {
		var splash:FunkinSprite = splashPool.get();
		if (splash != null) {
			splash.alpha = 0.6;
			splash.setPosition(0, 0);
			var strum = getStrum(noteData);
			if (strum != null)
				splash.objectCenter(strum, XY);
			splash.x += x;
			splash.y += y;
			var played:Bool = false;
			if (note != null && note.noteScript != null) {
				var scriptCall = note.noteScript?.callFunc('generateNoteSplash', [splash, noteData, note]);
				played = scriptCall.value != null;
			} else
				played = noteskin.playSplashAnimation(splash, noteData);
			if (played) {
				splash.revive();
				splash.animation.finishCallback = function(_) {
					splash.kill();
					splashPool.release(splash);
					splash.animation.finishCallback = null;
				};
			} else
				splash.kill();
		}
		return splash != null;
	}

	public function getStrum(noteData:Int)
		return strums[noteData];

	public function getScrollSpeed(noteData:Int):Null<Float>
		return speeds[noteData] ?? scrollSpeed;

	public function setStrumScrollSpeed(noteData:Int, noteSpeed:Float):Null<Float> {
		speeds[noteData] = noteSpeed;
		return speeds[noteData];
	}

	public function getDownscrollMult(noteData:Int):Int
		return downscroll[noteData];

	public function isStrumDownscroll(noteData:Int):Bool
		return downscroll[noteData] == -1;

	var strumSpacing:Float = 160;

	public function generateStrums():Void {
		speeds.resize(this.keyCount);
		downscroll.resize(this.keyCount);
		for (i in 0...this.keyCount) {
			var strum:FunkinSprite = noteskin.generateStrum(i);
			strums.push(strum);
			// strum.updateHitbox();
			changeScrollDirection(i, Preferences.user.scrollType);
			add(strum);
		}
	}

	public function repositionStrum(noteData:Int):Void {
		var i:Int = noteData % strums.length;
		var strum:FunkinSprite = strums[i];
		if (strum != null) {
			strum.x = (strumSpacing * strum.scale.x) * i;
			strum.y = (downscroll[i] == -1) ? FlxG.height - 185 : 30;
		}
	}

	/**
	 * Changes the scroll direction for one of the receptors
	 *
	 * @param noteData Int
	 * @param scrollType Int [1 = down | 2 = split | anything else = up]
	**/
	public function changeScrollDirection(noteData:Int, scrollType:Int):Void {
		if (downscroll.length < strums.length)
			downscroll.resize(strums.length);
		downscroll[noteData] = switch scrollType {
			case 2: (noteData % 4 >= 2) ? -1 : 1; // Split
			case 1: -1; // Downscroll
			case _: 1; // Default upscroll
		};
		repositionStrum(noteData);
	}

	public function playAnim(direction:Int = 0, animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		var strum:FunkinSprite = getStrum(direction);
		if (strum != null) {
			strum.playAnim(animName, force, reversed, frame);
			strum.centerOrigin();
			strum.centerOffsets();
		}
	}
}
