package editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import gameplay.PlayState;

using StringTools;
using util.CoolUtil;

class ChartEditor extends MusicBeatSubstate {
	var songName:String = "Test";
	var rawSongName:String = "test";
	var difficultyName:String = "HARD";

	public function new():Void {
		super();
		if (PlayState.current != null) {
			songName = PlayState.songTitle;
			rawSongName = PlayState.songName;
			difficultyName = PlayState.difficulty;
		}
		#if hxdiscord_rpc
		DiscordClient.changePresence('${songName} (${difficultyName.toUpperCase()})', 'Editing Chart');
		#end

		var bg:FlxSprite = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.6;
		add(bg);

		var info:FlxText = new FlxText(20, 15, FlxG.width, "Chart Editor is unfinished, Please come back later.\nPress ESC to Exit");
		info.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		info.setBorderStyle(OUTLINE, FlxColor.BLACK, 2.0);
		info.scrollFactor.set();
		info.screenCenter(Y);
		info.updateHitbox();
		add(info);

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE)
			close();
	}

	override function beatHit(beat:Int):Void {}

	override function stepHit(step:Int):Void {}
}
