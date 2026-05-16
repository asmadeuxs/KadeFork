package gameplay.note;

import data.JudgementManager.Judgement;
import data.Noteskin;
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

	// mainly for chart editor
	public var debugMode:Bool = false;
	public var rawNoteData:NoteData = null;
	public var skin:Noteskin;

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
					noteScript?.setVar("note", this);
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

	public var baseHoldScaleY:Float = 1.0;
	public var baseHoldAlpha:Float = 0.6;

	// for hold inputs
	public var holdTimer:Float = 0.0;
	public var isLocked:Bool = false;
	public var holdReleased:Bool = false;

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
		this.rawNoteData = data;
		this.isSustain = data.length > 0.0;
		this.sustainProgress = data.length;
		this.sustainLength = data.length;
		this.strumTime = data.time;
		if (this.strumTime < 0)
			this.strumTime = 0;
		this.strumline = strumline;
		this.skin = strumline?.noteskin;
		this.noteData = data.lane;
		this.noteOwner = data.owner;
		this.noteType = data.type;

		// reset gameplay values
		this.judgement = null;
		this.wasGoodHit = false;
		this.holdReleased = false;
		this.isLocked = false;
		this.tooLate = false;
		this.missed = false;

		this;baseHoldScaleY = 1.0;
		this.hitDifference = 0.0;
		this.holdTimer = 0.0;

		noteScript?.callFunc("noteRegenerated", [this, strumTime, noteData, sustainLength]);
		return this;
	}

	public function setSkin(skin:Noteskin) {
		this.skin = skin ?? strumline?.noteskin ?? null;
		return this;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (debugMode)
			return;
		noteScript?.callFunc("update", [elapsed, this]);
		if (tooLate) {
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	public function updateSustain(time:Float, scrollSpeed:Float):Void {
		if (!isSustain)
			return;

		if (holdEnd != null)
			holdEnd.objectCenter(this, X);
		if (holdBody != null)
			holdBody.objectCenter(this, X);
		if (isLocked && wasGoodHit && holdBody != null) {
			holdBody.scale.y = Math.max(0, (sustainProgress / sustainLength) * baseHoldScaleY);
			holdBody.updateHitbox();
		} else
			growSustainToBaseSize(time, scrollSpeed);

		if (holdBody != null && holdEnd != null) {
			holdEnd.y = holdBody.y + holdBody.height;
			holdEnd.updateHitbox();
		}
	}

	// making this a separate function for use in the chart editor -asmadeuxs
	public function growSustainToBaseSize(time:Float, scrollSpeed:Float) {
		if (holdBody == null)
			return;

		var startY:Float = y;
		var downscroll:Int = strumline?.getDownscrollMult(noteData) ?? 1;
		var endTime:Float = strumTime + sustainProgress;
		var sustainScroll:Float = 0.45 * scrollSpeed;
		var strumY:Float = (strumline?.getStrum(noteData)?.y) ?? (y + (strumTime - time) * sustainScroll);
		var endY:Float = strumY - (time - endTime) * sustainScroll * downscroll;

		var totalHeight:Float = (endY - startY) * downscroll;
		if (totalHeight < 0)
			totalHeight = -totalHeight;

		var endHeight:Float = (holdEnd != null) ? holdEnd.height : height;
		var sustainHeight:Float = Math.max(0, totalHeight - endHeight);

		holdBody.scale.y = sustainHeight / holdBody.frameHeight;
		baseHoldScaleY = holdBody.scale.y;
		holdBody.updateHitbox();
		holdBody.y = startY + endHeight * downscroll;
	}
}
