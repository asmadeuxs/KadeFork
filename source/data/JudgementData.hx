package data;

import flixel.util.FlxColor;

@:structInit class Judgement {
	public var name:String = "Unknown";
	public var image:String = "combo";
	public var hitWindow:Float = 0.0;

	@:optional public var comboBreak:Bool = false;
	@:optional public var accuracy:Float = 0.0;
	@:optional public var score:Int = 0;
	@:optional public var hits:Int = 0;
	@:optional public var color:FlxColor = 0xFFFFFFFF;
	@:optional public var splash:Bool = false;
}

class JudgementData {
	public var maxHitWindow:Float = 200.0;
	public var activeList:Array<Judgement>;

	public function new(?maxHitWindow:Null<Float>):Void {
		activeList = getDefaultJudgements();
		// maybe I need a miss judgement
		if (maxHitWindow != null && maxHitWindow > 0.0)
			this.maxHitWindow = maxHitWindow;
	};

	public function getDefaultJudgements():Array<Judgement> {
		return [
			{
				name: "kino",
				image: "kino",
				splash: true,
				color: 0xFF97FFFF,
				hitWindow: 22.5,
				accuracy: 1.0,
				score: 500
			},
			{
				name: "sick",
				image: "sick",
				splash: true,
				color: 0xFFEAFF74,
				hitWindow: 45.0,
				accuracy: 0.95,
				score: 350
			},
			{
				name: "good",
				image: "good",
				color: 0xFF97FF9F,
				hitWindow: 90.0,
				accuracy: 0.75,
				score: 200
			},
			{
				name: "bad",
				image: "bad",
				color: 0xFFDC7487,
				hitWindow: 135.0,
				accuracy: 0.50,
				score: 0
			},
			{
				name: "shit",
				image: "shit",
				color: 0xFFE02447,
				hitWindow: 180.0,
				accuracy: 0.25,
				score: -300,
				comboBreak: true
			},
		];
	}

	public function getHealthBonus(judgementName:String) {
		var health:Float = 0.0;
		switch (judgementName) {
			case 'shit':
				health -= 0.2;
			case 'bad':
				health -= 0.06;
			case 'good':
				if (health < 2)
					health += 0.04;
			case 'sick':
				if (health < 2)
					health += 0.1;
			case 'kino':
				if (health < 2)
					health += 0.12;
		}
		return health;
	}

	public function judgeTime(noteDiff:Float):Null<Judgement> {
		for (judgement in activeList)
			if (noteDiff <= judgement.hitWindow)
				return judgement;
		return activeList[activeList.length - 1];
	}

	public function getClearFlag():String { // made these static JUST for this btw :friendly_hearts:
		var breaks:Int = gameplay.PlayState.comboBreaks;
		var misses:Int = gameplay.PlayState.misses;

		var clearFlag:String = "N/A";
		var kinos:Int = activeList[0].hits;
		var sicks:Int = activeList[1].hits;
		var goods:Int = activeList[2].hits;
		var bads:Int = activeList[3].hits;
		var shits:Int = activeList[4].hits;
		if (misses == 0) {
			if (bads == 0 && shits == 0 && goods == 0 && sicks == 0) // Marvelous (SICK) Full Combo
				clearFlag = "KFC";
			else if (bads == 0 && shits == 0 && goods == 0 && sicks >= 1) // White Flag / Good Full Combo (Nothing but Goods & Sicks)
				clearFlag = sicks == 1 ? "WF" : "SFC";
			else if (bads == 0 && shits == 0 && goods >= 1) // White Flag / Good Full Combo (Nothing but Goods & Sicks)
				clearFlag = goods == 1 ? "BF" : "GFC";
			else
				clearFlag = breaks > 0 ? "NM" : "FC"; // No Misses / Full Combo
		} else {
			if (misses == 1)
				clearFlag = "MF"; // Miss Flag
			else if (misses < 10)
				clearFlag = "SDCB"; // Single Digit Combo Breaks
			else
				clearFlag = "Clear";
		}
		return clearFlag;
	}
}
