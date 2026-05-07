package gameplay.note;

import data.JudgementManager.Judgement;
import data.hscript.Script;
import data.hscript.ScriptLoader;
import data.song.KadeForkChart.NoteData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import gameplay.PlayState;
import moonchart.formats.BasicFormat;

using StringTools;
using util.CoolUtil;

class Note extends gameplay.FunkinSprite {
	public var strumline:Strumline = null;

	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var noteOwner:Int = -1;

	public var sustainLength:Float = 0;
	public var sustainProgress:Float = 0;

	public var noteType(default, set):String = null;

	@:allow(gameplay.PlayState, gameplay.DummyPlayState, gameplay.note.Strumline, gameplay.note.NoteRenderer)
	private var noteScript:Script;

	function set_noteType(type:String):String {
		noteType = type;
		switch type {
			default:
				var file:String = ScriptLoader.getScriptFile(Paths.getPath('scripts/notetypes'), type);
				if (file != null) {
					noteScript = ScriptLoader.findScript(file);
					noteScript?.callFunc('generateNoteType', [this]);
				}
		}
		return noteType;
	}

	public var canBeHit(get, never):Bool;

	function get_canBeHit():Bool {
		if (!mustPress || wasGoodHit || missed || tooLate)
			return false;
		var pos:Float = Conductor.time;
		var safeZone:Float = PlayState.session?.judgeMan?.maxHitWindow ?? 180.0;
		return strumTime >= pos - (safeZone * hitMultiplier[0]) && strumTime <= pos + (safeZone * hitMultiplier[1]);
	}

	public var mustPress:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var isSustain:Bool = false;
	public var holdBody:FlxSprite;
	public var holdEnd:FlxSprite;

	public var isMine:Bool = false;
	public var isFake:Bool = false;

	/**
	 * Left is *Early Window*, Right is *Late Window*.
	 */
	public var hitMultiplier:Array<Float> = [1.0, 1.0];

	public var hitDifference:Float = 0.0;
	public var judgement:Judgement;

	public function new() {
		super(0, 4000);
	}

	public function setup(strumline:Strumline, data:NoteData):Note {
		setPosition(0, 4000);

		this.isMine = false;
		this.isFake = false;
		this.isSustain = data.length > 0.0;
		this.sustainProgress = data.length;
		this.sustainLength = data.length;
		this.strumTime = data.time;
		if (this.strumTime < 0)
			this.strumTime = 0;
		this.strumline = strumline;
		this.noteData = data.lane;
		this.noteOwner = data.owner;
		this.noteType = data.type;

		// reset gameplay values
		this.judgement = null;
		this.hitDifference = 0.0;
		this.wasGoodHit = false;
		this.tooLate = false;
		this.missed = false;

		noteScript?.callFunc("noteRegenerated", [this, strumTime, noteData, sustainLength]);
		return this;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		noteScript?.callFunc("update", [elapsed, this]);
		if (tooLate) {
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	public function updateSustain(time:Float, scrollSpeed:Float):Void {
		if (!isSustain || strumline == null)
			return;
		if (holdEnd != null)
			holdEnd.objectCenter(this, X);
		if (holdBody != null) {
			holdBody.objectCenter(this, X);
			var startY:Float = y;
			var curStrum = strumline.getStrum(noteData);
			var downscroll:Int = strumline.getDownscrollMult(noteData);
			var sustainScroll:Float = 0.45 * scrollSpeed;
			var endTime:Float = strumTime + sustainProgress;
			var endY:Float = curStrum.y - (time - endTime) * sustainScroll * downscroll;
			var totalHeight:Float = (endY - startY) * downscroll;
			if (totalHeight < 0)
				totalHeight = -totalHeight;
			var endHeight:Float = holdEnd != null ? holdEnd.height : height;
			var sustainHeight:Float = Math.max(0, totalHeight - endHeight);
			if (holdBody.height > 0) {
				holdBody.scale.y = sustainHeight / holdBody.frameHeight;
				holdBody.updateHitbox();
			}
			holdBody.y = startY + endHeight * downscroll;
			if (holdEnd != null) {
				holdEnd.y = holdBody.y + holdBody.height;
				holdEnd.updateHitbox();
			}
		} else if (holdEnd != null)
			holdEnd.y = y + height;
	}
}
