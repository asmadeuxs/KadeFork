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
import util.Mods;
import ui.AlphabetMenu;
import ui.HealthIcon;

using StringTools;

class FreeplayState extends GenericMenu {
	var songs:Array<SongMetadata> = [];
	var iconArray:Array<HealthIcon> = [];

	var lastDifficultyArray:Array<String> = null;
	var grpSongs:AlphabetMenu;

	var scoreText:FlxText;
	var diffText:FlxText;

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	override function create() {
		super.create();
		#if hxdiscord_rpc
		DiscordClient.changePresence('Freeplay Menu', "Browsing Menus");
		#end
		this.menuScrollType = BOTH;
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(menuMusic("freakyMenu"), 0.7);
		Conductor.current.active = false;
		Conductor.setTime(0.0);

		// to not add the same song twice
		var foldersPushed:Array<String> = [];
		var modIDs:Array<String> = util.Mods.getEnabled();

		for (modId in modIDs) {
			var registry = LevelRegistry.current;
			for (id in registry.getOrderedLevels()) {
				var level:LevelData = registry.get('$modId:$id');
				if (level != null && level.songs != null) {
					for (info in level.songs) {
						var diffs:Array<String> = info.difficulties ?? level.difficulties;
						songs.push(new SongMetadata(info.name, info.folder, info.icon ?? "face", modId, diffs));
						foldersPushed.push(info.folder);
					}
				}
			}
			// custom songs (just for compatibility sake)
			var initSonglist = CoolUtil.coolTextFile(Paths.getPath('data/freeplaySonglist.txt', modId));
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
		}

		// cool we don't need the array anymore
		foldersPushed.resize(0);
		foldersPushed = null;

		add(new FlxSprite().loadGraphic(menuImage('ui/backgrounds/menuBGBlue')));
		var itemCreated = function(i:Int, target:Alphabet) {
			if (songs[i].mod != Mods.currentMod)
				Mods.currentMod = songs[i].mod;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = target;
			iconArray.push(icon);
			add(icon);
		}
		add(grpSongs = new AlphabetMenu(0, 0).generateMenu([for (i in 0...songs.length) songs[i].songName], itemCreated));
		Mods.currentMod = null;
		maxVerticals = songs.length - 1;

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(menuFont("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;

		add(scoreBG);
		add(diffText);
		add(scoreText);

		changeVertical();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.sound.music != null && FlxG.sound.music.playing && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));
		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		#if FEATURE_TRANSLATIONS
		scoreText.text = '${Translator.translateString('menus', 'freeplay_PB')}$lerpScore';
		#else
		scoreText.text = 'PERSONAL BEST:$lerpScore';
		#end
	}

	override function onAcceptPressed(song:Int, difficulty:Int):Void {
		PlayState.isStoryMode = false;
		var curSong = songs[song];
		Mods.currentMod = curSong.mod;
		PlayState.difficulty = lastDifficultyArray[difficulty].toLowerCase();
		var poop:String = Highscore.formatSong(curSong.songFolder, PlayState.difficulty);
		PlayState.moonSong = Song.loadFromFile(poop, curSong.songFolder);
		PlayState.songName = curSong.songFolder;
		FlxG.switchState(new gameplay.PlayState());
	}

	override function onBackPressed():Void {
		FlxG.switchState(new menus.MainMenuState());
		Mods.currentMod = null;
	}

	override function onVerticalChanged(index:Int) {
		if (songs[curVertical].mod != Mods.currentMod)
			Mods.currentMod = songs[curVertical].mod;
		refreshDifficulties();
		var bullShit:Int = 0;
		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;
		iconArray[index].alpha = 1;
		for (item in grpSongs.members) {
			item.targetY = bullShit - index;
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == 0)
				item.alpha = 1;
		}
		maxHorizontals = lastDifficultyArray.length - 1;
		changeHorizontal(); // recalculate score
	}

	override function onHorizontalChanged(index:Int) {
		refreshDifficulties();
		var diffic:String = lastDifficultyArray[index];
		var diffn:String = #if FEATURE_TRANSLATIONS Translator.translateString('menus', 'difficulty_${diffic.toLowerCase()}') #else diffic #end;
		intendedScore = Highscore.getScore(songs[curVertical].songFolder, diffic);
		if (lastDifficultyArray.length > 1)
			diffText.text = '< ${diffn.toUpperCase()} >';
		else
			diffText.text = diffn.toUpperCase();
	}

	function refreshDifficulties() {
		var difficulties:Array<String> = getDifficultyList(curVertical);
		// check to prevent null difficulties
		if (lastDifficultyArray != difficulties) {
			lastDifficultyArray = difficulties;
			curHorizontal = Math.round(maxHorizontals * 0.5);
			if (curHorizontal > maxHorizontals)
				curHorizontal = 0;
		}
	}

	function getDifficultyList(index:Int) {
		var difficulties:Array<String> = CoolUtil.defaultDifficulties;
		if (songs[index].difficulties != null && songs[index].difficulties.length > 0)
			difficulties = songs[index].difficulties;
		return difficulties;
	}
}
