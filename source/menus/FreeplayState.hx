package menus;

import data.Highscore;
import data.song.Song;
import data.song.SongMetadata;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import gameplay.PlayState;
import lime.utils.Assets;
import ui.AlphabetMenu;
import ui.HealthIcon;

using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end

class FreeplayState extends MusicBeatState {
	var songs:Array<SongMetadata> = [];
	var lastDifficultyArray:Array<String> = null;
	var grpSongs:AlphabetMenu;

	var seslector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 0;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	private var curPlaying:Bool = false;
	private var iconArray:Array<HealthIcon> = [];

	override function create() {
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length) {
			var data:Array<String> = initSonglist[i].split(':');
			var diffs:Array<String> = null;
			if (data.length > 2 && data[3].length > 0)
				diffs = data[3].split(",");
			songs.push(new SongMetadata(data[0], data[1], data[2], diffs));
		}

		#if discord_rpc
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/backgrounds/menuBGBlue'));
		add(bg);

		// limitation: AlphabetMenu only accepts strings and SongMetadata is a struct
		grpSongs = new AlphabetMenu(0, 0).generateMenu([for (i in 0...songs.length) songs[i].songName]);
		add(grpSongs);

		for (i in 0...songs.length) {
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = grpSongs.members[i];
			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, RIGHT);

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();

		super.create();
	}

	public function addSong(songName:String, songFolder:String, songCharacter:String)
		songs.push(new SongMetadata(songName, songFolder, songCharacter));

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));
		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = 'PERSONAL BEST:$lerpScore';

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;
		var leftP = controls.LEFT_P;

		if (upP || downP)
			changeSelection(upP ? -1 : 1);
		if (leftP || controls.RIGHT_P)
			changeDiff(leftP ? -1 : 1);
		if (controls.BACK)
			FlxG.switchState(new menus.MainMenuState());

		if (accepted) {
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
			trace(poop);
			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			trace('CUR WEEK' + PlayState.storyWeek);
			FlxG.switchState(new gameplay.PlayState());
		}
	}

	function changeDiff(change:Int = 0) {
		var difficulties:Array<String> = CoolUtil.defaultDifficulties;
		if (songs[curSelected].difficulties != null && songs[curSelected].difficulties.length > 0)
			difficulties = songs[curSelected].difficulties;
		if (difficulties != CoolUtil.defaultDifficulties) {
			// check to prevent null difficulties
			if (lastDifficultyArray != difficulties) {
				lastDifficultyArray = difficulties;
				if (difficulties.length > 2)
					curDifficulty = Math.round(difficulties.length / 2);
				else
					curDifficulty = difficulties.length - 1;
			}
		}
		trace(difficulties);
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, difficulties.length - 1);
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		diffText.text = difficulties[curDifficulty].toUpperCase();
		trace(difficulties[curDifficulty]);
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		changeDiff();

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;
		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
				item.alpha = 1;
		}
	}
}
