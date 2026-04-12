package gameplay;

import data.ScriptLoader;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import gameplay.PlayState;

using StringTools;

typedef NoteData = {
	noteData:Int,
	noteOwner:Int,
	strumTime:Float,
	sustainLength:Float,
	?noteType:String,
}

class Note extends gameplay.FunkinSprite {
	public var noteData:Int = 0;
	public var strumTime:Float = 0;
	public var sustainLength:Float = 0;
	public var prevNote:Note;

	public var noteType(default, set):String = null;

	private var noteScript:Script;

	function set_noteType(type:String):String {
		noteType = type;
		switch type {
			default:
				noteScript = ScriptLoader.findScript(Paths.getPath('scripts/notetypes/$type'));
				noteScript?.callFunc('generateNoteType', [this]);
		}
		return noteType;
	}

	public var canBeHit(get, never):Bool;

	function get_canBeHit():Bool {
		if (!mustPress || wasGoodHit || missed || tooLate)
			return false;
		var pos:Float = Conductor.songPosition;
		var safeZone:Float = PlayState.judgementData.maxHitWindow ?? 180.0;
		return strumTime >= pos - (safeZone * hitMultiplier[0]) && strumTime <= pos + (safeZone * hitMultiplier[1]);
	}

	public var mustPress:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var isSustainNote:Bool = false;
	public var missed:Bool = false;

	public var isMine:Bool = false;
	public var isFake:Bool = false;

	/**
	 * Left is *Early Window*, Right is *Late Window*.
	 */
	public var hitMultiplier:Array<Float> = [1.0, 1.0];

	public var judgement:data.JudgementData.Judgement;

	var colorArray:Array<String> = ["purple", "blue", "green", "red"];

	public function new() {
		super(0, 4000);
	}

	public function setup(strumTime:Float, noteData:Int, ?sustainLength:Float = 0.0, ?prevNote:Note):Note {
		setPosition(0, 4000);

		this.isMine = false;
		this.isFake = false;

		if (prevNote == null)
			prevNote = this;
		this.prevNote = prevNote;
		this.isSustainNote = false; // sustainLength > 0.0;
		this.strumTime = strumTime;
		if (this.strumTime < 0)
			this.strumTime = 0;
		this.noteData = noteData;

		// reset gameplay values
		this.wasGoodHit = false;
		this.tooLate = false;
		this.missed = false;

		noteScript?.callFunc("noteRegenerated", [this, strumTime, noteData, sustainLength, prevNote]);

		// old checks

		/*
			// we make sure its downscroll and its a SUSTAIN NOTE (aka a trail, not a note)
			// and flip it so it doesn't look weird.
			// THIS DOESN'T FUCKING FLIP THE NOTE, CONTRIBUTERS DON'T JUST COMMENT THIS OUT JESUS
			if (Preferences.user.scrollType == 1 && isSustainNote)
				flipY = true;

			if (isSustainNote && prevNote != null) {
				alpha = 0.6;
				x += width / 2;
				// updateHitbox();
				x -= width / 2;

				if (PlayState.curStage.startsWith('school'))
					x += 30;

				if (prevNote.isSustainNote) {
					prevNote.animation.play(colorArray[noteData] + 'hold');
					prevNote.scale.y *= Conductor.semiquaver / 100 * 1.8 * Preferences.user.scrollSpeed;
					// prevNote.updateHitbox();
				}
		}*/
		return this;
	}

	public function loadDefaultNoteAnimations() {
		frames = Paths.getSparrowAtlas('gameplay/noteskins/NOTE_assets');

		animation.addByPrefix('greenScroll', 'green0');
		animation.addByPrefix('redScroll', 'red0');
		animation.addByPrefix('blueScroll', 'blue0');
		animation.addByPrefix('purpleScroll', 'purple0');

		animation.addByPrefix('purpleholdend', 'pruple end hold');
		animation.addByPrefix('greenholdend', 'green hold end');
		animation.addByPrefix('redholdend', 'red hold end');
		animation.addByPrefix('blueholdend', 'blue hold end');

		animation.addByPrefix('purplehold', 'purple hold piece');
		animation.addByPrefix('greenhold', 'green hold piece');
		animation.addByPrefix('redhold', 'red hold piece');
		animation.addByPrefix('bluehold', 'blue hold piece');

		setGraphicSize(Std.int(width * 0.7));
		// updateHitbox();
		antialiasing = true;

		if (!isSustainNote)
			animation.play(colorArray[noteData] + "Scroll");
		else {
			animation.play(colorArray[noteData] + 'holdend');
			if (prevNote.isSustainNote)
				prevNote.animation.play(colorArray[noteData] + 'hold');
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		noteScript?.callFunc("update", [elapsed, this]);
		if (tooLate) {
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
