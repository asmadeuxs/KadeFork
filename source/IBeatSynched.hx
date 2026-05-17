package;

// leaving this here so I don't have to type Conductor.IBeatSynched
interface IBeatSynched {
	public function stepHit(curStep:Int):Void;
	public function beatHit(curBeat:Int):Void;
	public function barHit(curBar:Int):Void;
}
