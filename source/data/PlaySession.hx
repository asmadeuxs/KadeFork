package data;

import data.JudgementManager;
import gameplay.note.Note;

class PlaySession {
	public var score:Int = 0;
	public var misses:Int = 0;
	public var comboBreaks:Int = 0;
	public var invalid:Bool = false;
	public var combo:Int = 0;

	public var totalNotesHit:Float = 0.0;
	public var totalPlayed:Int = 0;

	public var judgeMan:JudgementManager;

	public function new():Void {
		judgeMan = new JudgementManager();
	}

	public function reset():Void {
		judgeMan = new JudgementManager();
		totalNotesHit = 0.0;
		comboBreaks = 0;
		totalPlayed = 0;
		misses = 0;
		score = 0;
		combo = 0;
	}

	public function scoreNote(daNote:Note):Void {
		if (daNote.judgement == null) {
			var diff:Float = Math.abs(daNote.strumTime - Conductor.time);
			daNote.judgement = judgeMan.judgeTime(diff);
			daNote.hitDifference = diff;
		}
		// if (Preferences.user.etternaMode)
		//	totalNotesHit += util.EtternaFunctions.wife3(judgementData.maxHitWindow, daNote.hitDifference);
		// else
		totalNotesHit += daNote.judgement.accuracy;
		score += Math.round(daNote.judgement.score);
		daNote.judgement.hits++;
		if (daNote.judgement.comboBreak == true)
			breakCombo();
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

	public function calculateAccuracy():Float
		return totalNotesHit < 1 ? 0.00 : Math.max(0, totalNotesHit / totalPlayed * 100);
}
