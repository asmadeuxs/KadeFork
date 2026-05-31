package data;

import data.AccuracyAlgorithm.Simple;
import data.AccuracyAlgorithm.Wife3;
import data.Highscore;
import data.JudgementManager.Judgement;
import data.JudgementManager;
import gameplay.note.Note;

class PlaySession {
	public var score:Int = 0;
	public var misses(get, never):Int;

	inline function get_misses():Int {
		var i:Int = 0;
		if (judgeMan != null) {
			var miss:Judgement = judgeMan.getMiss();
			if (miss != null)
				i = miss.hits;
		}
		return i;
	}

	public var comboBreaks:Int = 0;
	public var invalid:Bool = false;
	public var combo:Int = 0;

	public var accuracy:AccuracyAlgorithm;
	public var judgeMan:JudgementManager;

	public function new():Void {
		reset();
	}

	public function toSave():Highscore.ScoreSave {
		return {
			score: this.score,
			misses: this.misses,
			comboBreaks: this.comboBreaks,
			accuracy: this.calculateAccuracy(),
			system: Preferences.user.accuracySystem,
			combo: this.combo,
		}
	}

	public function reset():Void {
		judgeMan = new JudgementManager();
		if (accuracy == null) {
			// made it a string in case I ever added new systems in the future
			// also its a bit nice to be explicit i feel like
			accuracy = switch Preferences.user.accuracySystem.toLowerCase() {
				case "wife3": new Wife3();
				case _: new Simple();
			}
			trace('Using $accuracy');
		}
		else
			accuracy.reset();
		comboBreaks = 0;
		score = 0;
		combo = 0;
	}

	public function scoreNote(daNote:Note):Void {
		if (daNote.judgement == null) {
			daNote.hitDifference = daNote.strumTime - Conductor.time;
			daNote.judgement = judgeMan.judgeTime(Math.abs(daNote.hitDifference));
		}
		daNote.judgement.hits++;
		score += Math.round(daNote.judgement.score);
		switch (daNote.judgement.comboBehavior) {
			case INCREASE:
				increaseCombo(1);
			case BREAK:
				breakCombo();
			case NONE:
		}
		accuracy?.registerHit(daNote);
	}

	public function increaseCombo(by:Int = 1):Int {
		if (combo < 0)
			combo = 0;
		combo += by;
		return combo;
	}

	public function breakCombo():Void {
		comboBreaks++;
		if (combo > 0)
			combo = 0;
		else
			combo--;
	}

	public function calculateAccuracy():Float {
		return accuracy.get();
	}
}
