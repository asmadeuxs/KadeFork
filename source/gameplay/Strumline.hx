package gameplay;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import gameplay.FunkinSprite;
import data.ScriptLoader;

class Strumline extends FlxTypedSpriteGroup<FunkinSprite> {
	public var keyCount:Int = 4;

	private var noteScript:Script;

	public function new(x:Float = 0, y:Float = 0, ?keyCount:Int = 4):Void {
		super(x, y);
		this.keyCount = keyCount;
		var skin:String = 'default'; // hardcoded for now
		var skinPath:String = Paths.getPath('images/gameplay/noteskins');
		var path = ScriptLoader.getScriptFile(skinPath, skin);
		noteScript = ScriptLoader.loadScript(path);
		generateStrums();
	}

	public function generateStrums():Void {
		var spacing:Float = 160;
		for (i in 0...this.keyCount) {
			var strum:FunkinSprite = new FunkinSprite(0, 0);
			if (noteScript != null)
				noteScript.callFunc("generateStrum", [strum, i]);
			strum.x = (spacing * strum.scale.x) * i;
			// strum.updateHitbox();
			add(strum);
		}
	}

	public function playAnim(direction:Int = 0, animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		var strum:FunkinSprite = this.members[direction];
		if (strum != null) {
			if (noteScript != null && noteScript.hasFunction("onPlayAnim")) {
				var ret = noteScript.callFunc("onPlayAnim", [strum, direction, animName, force, reversed, frame]);
				if (ret.value == ScriptLoader.STOP_FUNC)
					return;
			}
			strum.playAnim(animName, force, reversed, frame);
			strum.centerOrigin();
			strum.centerOffsets();
			if (noteScript != null && noteScript.hasFunction("postPlayAnim"))
				noteScript.callFunc("postPlayAnim", [strum, direction, animName, force, reversed, frame]);
		}
	}
}
