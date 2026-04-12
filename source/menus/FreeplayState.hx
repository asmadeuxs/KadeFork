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
import registry.LevelRegistry;
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

	var curPlaying:Bool = false;
	var iconArray:Array<HealthIcon> = [];

	override function create() {
		Conductor.current.active = false;
		Conductor.setTime(0.0);

		// to not add the same song twice
		var foldersPushed:Array<String> = [];
		var categories:Array<String> = util.Mods.getEnabled();
		if (categories[0] != "core") // make sure hardcoded categories are there
			categories.insert(0, "core");

		for (modId in categories) {
			var registry = LevelRegistry.current;
			for (id in registry.getOrderedLevels()) {
				var level:LevelData = registry.get('$modId:$id');
				if (level != null && level.songs != null) {
					for (info in level.songs) {
						var diffs:Array<String> = info.difficulties ?? level.difficulties;
						songs.push(new SongMetadata(info.name, info.folder, info.icon ?? "face", diffs));
						foldersPushed.push(info.folder);
					}
				}
			}
		}

		// custom songs (just for compatibility sake)
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length) {
			var data:Array<String> = initSonglist[i].split(':');
			if (foldersPushed.contains(data[1]))
				continue;
			var diffs:Array<String> = null;
			if (data.length > 2 && data[3].length > 0)
				diffs = data[3].split(",");
			songs.push(new SongMetadata(data[0], data[1], data[2], diffs));
			foldersPushed.push(data[1]);
		}

		// cool we don't need the array anymore
		foldersPushed.resize(0);
		foldersPushed = null;

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
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

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

		if (FlxG.sound.music != null && FlxG.sound.music.playing && FlxG.sound.music.volume < 0.7)
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
			PlayState.isStoryMode = false;
			var curSong = songs[curSelected];
			PlayState.difficulty = getDifficultyList()[curDifficulty].toLowerCase();
			var poop:String = Highscore.formatSong(curSong.songFolder, PlayState.difficulty);
			PlayState.songName = curSong.songFolder;
			PlayState.moonSong = Song.loadFromFile(poop, curSong.songFolder);
			FlxG.switchState(new gameplay.PlayState());
		}
	}

	function getDifficultyList() {
		var difficulties:Array<String> = CoolUtil.defaultDifficulties;
		if (songs[curSelected].difficulties != null && songs[curSelected].difficulties.length > 0)
			difficulties = songs[curSelected].difficulties;
		return difficulties;
	}

	function changeDiff(change:Int = 0) {
		var difficulties:Array<String> = getDifficultyList();
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, difficulties.length - 1);
		// check to prevent null difficulties
		if (lastDifficultyArray != difficulties) {
			lastDifficultyArray = difficulties;
			curDifficulty = Math.round(difficulties.length / 2);
			if (curDifficulty > difficulties.length - 1)
				curDifficulty = 0;
		}
		var diffic:String = difficulties[curDifficulty];
		intendedScore = Highscore.getScore(songs[curSelected].songFolder, diffic);
		if (difficulties.length > 1)
			diffText.text = '< ${diffic.toUpperCase()} >';
		else
			diffText.text = diffic.toUpperCase();
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		changeDiff(); // recalculate score

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
