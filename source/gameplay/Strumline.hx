package gameplay;

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
	public var keyCount:Int = 4;
	public var noteskin:Noteskin;

	public var strums:Array<FunkinSprite> = [];

	private var splashPool:ObjectPool<FunkinSprite>;

	public function new(x:Float = 0, y:Float = 0, ?keyCount:Int = 4):Void {
		super(x, y);
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

	public function generateStrums():Void {
		var spacing:Float = 160;
		for (i in 0...this.keyCount) {
			var strum:FunkinSprite = noteskin.generateStrum(i);
			strum.x = (spacing * strum.scale.x) * i;
			// strum.updateHitbox();
			strums.push(strum);
			add(strum);
		}
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
