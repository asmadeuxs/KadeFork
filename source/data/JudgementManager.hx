package data;

import flixel.util.FlxColor;

// stole this from troll engine -asmadeuxs
enum ComboBehavior {
	INCREASE;
	BREAK;
	NONE;
}

@:structInit class Judgement {
	public var name:String = "Unknown";
	public var image:String = "combo";
	public var hitWindow:Float = 0.0;

	@:optional public var hittable:Bool = true;
	@:optional public var healthBonus:Float->Float = null;
	@:optional public var comboBehavior:ComboBehavior = ComboBehavior.INCREASE;
	@:optional public var color:FlxColor = 0xFFFFFFFF;
	@:optional public var accuracy:Float = 0.0;
	@:optional public var splash:Bool = false;
	@:optional public var score:Int = 0;
	@:optional public var hits:Int = 0;
}

class JudgementManager {
	public var maxHitWindow:Float = 200.0;
	public var activeList:Array<Judgement>;

	public static final defaultHitWindows:Array<Float> = [22.5, 45.0, 90.0, 135.0, 180.0];

	public static final difficultyScales:Array<Float> = [
		// lol https://github.com/troll-slaiyers/FNF-Troll-Engine/blob/bc3bdb226a6d785f6d1747ed869b8dde854aecda/source/funkin/data/JudgmentManager.hx#L369
		1.50,
		1.33,
		1.16,
		1.0, // Default Scale is 4
		0.84,
		0.66,
		0.5,
		0.33,
		0.2 // JUSTICE
	];

	public function new(?maxHitWindow:Null<Float>):Void {
		activeList = getDefaultJudgements();
		if (maxHitWindow != null && maxHitWindow > 0.0)
			this.maxHitWindow = maxHitWindow;
	}

	public function getBest()
		return activeList[0];

	public function getWorst()
		return activeList[activeList.length - 2];

	public function getMiss()
		return activeList[activeList.length - 1];

	public function getJudgeDifficultyScale():Float
		return difficultyScales[Preferences.user.judgeDifficulty];

	public function getDefaultJudgements():Array<Judgement> {
		var fifthJudge:Bool = #if FIFTH_JUDGEMENT Preferences.user.fifthJudgement #else false #end;
		return [
			{
				name: "Kino",
				image: "kino",
				splash: true,
				color: 0xFF97FFFF,
				comboBehavior: INCREASE,
				healthBonus: (health:Float) -> return health < 2 ? 0.15 : 0.0,
				hittable: fifthJudge,
				hitWindow: 22.5,
				accuracy: 1.0,
				score: 500
			},
			{
				name: "Sick",
				image: "sick",
				splash: true,
				comboBehavior: INCREASE,
				healthBonus: (health:Float) -> return health < 2 ? 0.1 : 0.0,
				accuracy: fifthJudge ? 0.95 : 1.0,
				color: 0xFFEAFF74,
				hitWindow: 45.0,
				score: 350
			},
			{
				name: "Good",
				image: "good",
				comboBehavior: INCREASE,
				healthBonus: (health:Float) -> return health < 2 ? 0.04 : 0.0,
				color: 0xFF97FF9F,
				hitWindow: 90.0,
				accuracy: 0.75,
				score: 200
			},
			{
				name: "Bad",
				image: "bad",
				comboBehavior: BREAK,
				healthBonus: (health:Float) -> return health > 0.01 ? -0.06 : 0.0,
				color: 0xFFDC7487,
				hitWindow: 135.0,
				accuracy: 0.50,
				score: 0
			},
			{
				name: "Shit",
				image: "shit",
				comboBehavior: BREAK,
				healthBonus: (health:Float) -> return health > 0.1 ? -0.2 : 0.0,
				color: 0xFFE02447,
				hitWindow: 180.0,
				accuracy: 0.25,
				score: -300,
			},
			{
				name: "Miss",
				image: "miss",
				comboBehavior: BREAK,
				healthBonus: (health:Float) -> return health > 0.05 ? -0.06 : 0.0,
				hitWindow: maxHitWindow + 5,
				color: 0xFFFF0000,
				hittable: false,
				accuracy: -0.5,
				score: -350,
			}
		];
	}

	// if you do add a judgement, modify this function, just in case it has a clear flag

	public function getClearFlag():String {
		var misses:Int = getMiss().hits ?? 0;
		if (misses > 0) // Single Miss = Miss Flag | <10 Misses = Single Digit Combo Breaks
			return misses == 1 ? "MF" : misses < 10 ? "SDCB" : "Clear";
		// get lowest judgement fc
		var lowestFC:Int = -1;
		for (i in 0...activeList.length)
			if (activeList[i].hits > 0)
				lowestFC = i;
		if (lowestFC == -1)
			return "N/A";
		var breaks:Int = gameplay.PlayState.session?.comboBreaks ?? 0;
		return switch lowestFC {
			case 0: "KFC"; // Kino Full Combo
			case 1: activeList[1].hits == 1 ? "WF" : "SFC"; // White Flag / Sick Full Combo
			case 2: return activeList[2].hits == 1 ? "BF" : "GFC"; // Black Flag / Good Full Combo
			case _: return breaks > 0 ? "NM" : "FC"; // No Misses / Full Combo
		}
	}

	public function getHealthBonus(judgement:Judgement, health:Float)
		return judgement.healthBonus != null ? judgement.healthBonus(health) : 0.0;

	public function judgeTime(noteDiff:Float):Null<Judgement> {
		var scale:Float = getJudgeDifficultyScale();
		for (judgement in activeList)
			if (judgement.hittable && noteDiff <= (judgement.hitWindow * scale))
				return judgement;
		return getWorst();
	}
}
