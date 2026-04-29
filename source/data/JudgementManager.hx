package data;

import flixel.util.FlxColor;

@:structInit class Judgement {
	public var name:String = "Unknown";
	public var image:String = "combo";
	public var hitWindow:Float = 0.0;

	@:optional public var hittable:Bool = true;
	@:optional public var healthBonus:Float->Float = null;
	@:optional public var comboBreak:Bool = false;
	@:optional public var accuracy:Float = 0.0;
	@:optional public var score:Int = 0;
	@:optional public var hits:Int = 0;
	@:optional public var color:FlxColor = 0xFFFFFFFF;
	@:optional public var splash:Bool = false;
}

class JudgementManager {
	public var maxHitWindow:Float = 200.0;
	public var activeList:Array<Judgement>;

	public function new(?maxHitWindow:Null<Float>):Void {
		activeList = getDefaultJudgements();
		if (maxHitWindow != null && maxHitWindow > 0.0)
			this.maxHitWindow = maxHitWindow;
	}

	public function getPerfect()
		return activeList[0];

	public function getGreat()
		return activeList[1];

	public function getWorst()
		return activeList[activeList.length - 2];

	public function getMiss()
		return activeList[activeList.length - 1];

	public function getDefaultJudgements():Array<Judgement> {
		return [
			{
				name: "Sick",
				image: "sick",
				splash: true,
				color: 0xFF97FFFF,
				healthBonus: (health:Float) -> return health < 2 ? 0.12 : 0.0,
				hitWindow: 22.5,
				accuracy: 1.0,
				score: 500
			},
			{
				name: "Great",
				image: "great",
				splash: true,
				healthBonus: (health:Float) -> return health < 2 ? 0.1 : 0.0,
				color: 0xFFEAFF74,
				hitWindow: 45.0,
				accuracy: 0.95,
				score: 350
			},
			{
				name: "Good",
				image: "good",
				healthBonus: (health:Float) -> return health < 2 ? 0.04 : 0.0,
				color: 0xFF97FF9F,
				hitWindow: 90.0,
				accuracy: 0.75,
				score: 200
			},
			{
				name: "Bad",
				image: "bad",
				healthBonus: (_:Float) -> return -0.06,
				color: 0xFFDC7487,
				hitWindow: 135.0,
				accuracy: 0.50,
				score: 0
			},
			{
				name: "Shit",
				image: "shit",
				comboBreak: true,
				healthBonus: (_:Float) -> return -0.2,
				color: 0xFFE02447,
				hitWindow: 180.0,
				accuracy: 0.25,
				score: -300,
			},
			{
				name: "Miss",
				image: "miss",
				healthBonus: (_:Float) -> return -0.04,
				color: 0xFFFF0000,
				hittable: false,
				accuracy: 0.0,
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
			case 0: "MFC"; // Marvelous (Sick) Full Combo
			case 1: activeList[1].hits == 1 ? "WF" : "GFC+"; // White Flag / Great Full Combo
			case 2: return activeList[2].hits == 1 ? "BF" : "GFC"; // Black Flag / Good Full Combo
			case _: return breaks > 0 ? "NM" : "FC"; // No Misses / Full Combo
		}
	}

	public function getHealthBonus(judgement:Judgement, health:Float)
		return judgement.healthBonus != null ? judgement.healthBonus(health) : 0.0;

	public function judgeTime(noteDiff:Float):Null<Judgement> {
		for (judgement in activeList)
			if (judgement.hittable == true && noteDiff <= judgement.hitWindow)
				return judgement;
		return activeList[activeList.length - 1];
	}
}
