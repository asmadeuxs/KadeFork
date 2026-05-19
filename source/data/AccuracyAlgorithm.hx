package data;

import data.PlaySession;
import gameplay.note.Note;

class AccuracyAlgorithm {
	public var totalNotesHit:Float = 0.0;
	public var totalPlayed:Int = 0;

	public function new():Void {
		reset();
	}

	public function reset():Void {
		this.totalNotesHit = 0.0;
		this.totalPlayed = 0;
	}

	public function registerHit(note:Note):Void {}

	public function get():Float {
		var tp:Int = getTotalPlayed();
		var tnh:Float = getTotalNotesHit();
		var acc:Float = tnh < 1 ? 0.0 : Math.max(0, tnh / tp * 100);
		return acc;
	}

	public function ghostMiss(_:PlaySession):Void {}

	public function getTotalNotesHit():Float
		return this.totalNotesHit;

	public function getTotalPlayed():Int
		return this.totalPlayed;
}

class Simple extends AccuracyAlgorithm {
	override public function registerHit(daNote:Note):Void {
		totalNotesHit += daNote.judgement.accuracy;
		totalPlayed += daNote.judgement.comboBreak ? -1 : 1;
	}

	override public function ghostMiss(_:PlaySession):Void {
		totalNotesHit -= 1;
	}

	public function toString():String
		return 'Simple Accuracy Algorithm';
}

// https://github.com/etternagame/etterna/blob/0a7bd768cffd6f39a3d84d76964097e43011ce33/src/RageUtil/Utils/RageUtil.h
class Wife3 extends AccuracyAlgorithm {
	override public function registerHit(daNote:Note):Void {
		if (daNote.isMine)
			totalNotesHit += Wife3.MINE_WEIGHT;
		else if (daNote.missed)
			totalNotesHit += Wife3.MISS_WEIGHT;
		else
			totalNotesHit += getWifePoints(Math.abs(daNote.hitDifference));
		totalPlayed += 1;
	}

	override public function ghostMiss(_:PlaySession):Void {
		totalNotesHit -= 1;
	}

	public function toString():String
		return 'Etterna Wife3 Accuracy Algorithm';

	private static final MISS_WEIGHT:Float = -5.5;
	private static final MINE_WEIGHT:Float = -7.0;
	private static final HOLD_DROP_WEIGHT:Float = -4.5;

	private static inline final a1:Float = 0.254829592;
	private static inline final a2:Float = -0.284496736;
	private static inline final a3:Float = 1.421413741;
	private static inline final a4:Float = -1.453152027;
	private static inline final a5:Float = 1.061405429;
	private static inline final p:Float = 0.3275911;

	public static var timeScale:Float = 1;

	public static function werwerwerwerf(x:Float):Float {
		var neg:Bool = x < 0;
		x = Math.abs(x);
		var t:Float = 1 / (1 + p * x);
		var y:Float = 1 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);
		return neg ? -y : y;
	}

	public static function getWifePoints(noteDiff:Float, ?ts:Float):Float {
		if (ts == null)
			ts = timeScale;
		if (ts > 1)
			ts = 1;
		var jPow:Float = 0.75;
		var maxPoints:Float = 2.0;
		var ridic:Float = 5 * ts;
		var shitWeight:Float = 200;
		var absDiff:Float = Math.abs(noteDiff);
		var zero:Float = 65 * Math.pow(ts, jPow);
		var dev:Float = 22.7 * Math.pow(ts, jPow);

		if (absDiff <= ridic)
			return maxPoints;
		else if (absDiff <= zero)
			return maxPoints * werwerwerwerf((zero - absDiff) / dev);
		else if (absDiff <= shitWeight)
			return (absDiff - zero) * MISS_WEIGHT / (shitWeight - zero);
		return MISS_WEIGHT;
	}
}
