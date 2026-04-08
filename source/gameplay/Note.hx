package gameplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import gameplay.PlayState;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var prevNote:Note;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	/**
	 * Left is *Early Window*, Right is *Late Window*.
	 */
	public var hitMultiplier:Array<Float> = [1.0, 1.0];

	public var noteScore:Float = 1;

	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var judgement:data.JudgementData.Judgement;

	var colorArray:Array<String> = ["purple", "blue", "green", "red"];

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super(0, 4000);

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.strumTime = strumTime;
		if (this.strumTime < 0)
			this.strumTime = 0;
		this.noteData = noteData;

		var daStage:String = PlayState.curStage;

		switch (daStage)
		{
			default:
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
		}

		animation.play(colorArray[noteData] + "Scroll");

		// we make sure its downscroll and its a SUSTAIN NOTE (aka a trail, not a note)
		// and flip it so it doesn't look weird.
		// THIS DOESN'T FUCKING FLIP THE NOTE, CONTRIBUTERS DON'T JUST COMMENT THIS OUT JESUS
		if (Preferences.user.scrollType == 1 && sustainNote)
			flipY = true;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			x += width / 2;
			animation.play(colorArray[noteData] + 'holdend');
			// updateHitbox();
			x -= width / 2;

			if (PlayState.curStage.startsWith('school'))
				x += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colorArray[noteData] + 'hold');
				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.8 * Preferences.user.scrollSpeed;
				// prevNote.updateHitbox();
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			var safeZone:Null<Float> = PlayState.judgementData.maxHitWindow;
			if (safeZone != null)
			{
				var pos:Float = Conductor.songPosition;
				if (!wasGoodHit)
				{
					canBeHit = strumTime >= pos - (safeZone * hitMultiplier[0]) && strumTime <= pos + (safeZone * hitMultiplier[1]);
					if (strumTime < pos - safeZone)
						tooLate = true;
				}
			}
		}
		else
		{
			canBeHit = false;
			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
