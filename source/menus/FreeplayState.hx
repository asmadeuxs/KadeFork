package menus;

import data.ConfigTypes.LevelData;
import data.Highscore;
import data.song.Song;
import data.song.SongMetadata;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import gameplay.PlayState;
import lime.utils.Assets;
import registry.LevelRegistry;
import ui.AlphabetMenu;
import ui.HealthIcon;
import util.Mods;

using StringTools;
using util.CoolUtil;

class FreeplayState extends GenericMenuState {
	static var prevSong:String = null;

	var songs:Array<SongMetadata> = [];
	var iconArray:Array<HealthIcon> = [];

	var lastDifficultyArray:Array<String> = null;
	var grpSongs:AlphabetMenu;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var infoText:FlxText;

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	// holyyyy shiiiiit -asmadeuxs
	var playlistVisible:Bool = false;
	var playlistGroup:FlxTypedGroup<FlxText>;
	var selectedSongs:Array<SongMetadata> = [];

	override function create() {
		super.create();
		#if hxdiscord_rpc
		DiscordClient.changePresence('Freeplay Menu', "Browsing Menus");
		#end
		this.menuScrollType = BOTH;
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Mods.menuMusic("freakyMenu"), 0.7);
		Conductor.current.active = false;
		Conductor.setTime(0.0);

		var foldersPushed:Array<String> = [];
		var modIDs:Array<String> = util.Mods.getEnabled();
		for (modId in modIDs) {
			// level songs (weeks whatever)
			var levels:Array<LevelData> = LevelRegistry.current.getLevelData(modId);
			if (levels != null && levels.length != 0) {
				for (level in levels) {
					if (level == null || level.songs.length == 0)
						continue;
					for (song in level.songs) {
						if (foldersPushed.contains(song.folder))
							continue;
						var diffs:Array<String> = song.difficulties ?? level.difficulties;
						songs.push(new SongMetadata(song.name, song.folder, song.icon ?? "face", modId, diffs));
						if (!foldersPushed.contains(song.folder))
							foldersPushed.push(song.folder);
					}
				}
			}
			// custom songs (just for compatibility sake)
			var initSonglist = CoolUtil.coolTextFile(Paths.getPath('data/freeplaySonglist.txt', modId));
			for (i in 0...initSonglist.length) {
				var data:Array<String> = initSonglist[i].split(':');
				var diffs:Array<String> = null;
				if (data.length > 2 && data[3].length > 0)
					diffs = data[3].split(",");
				if (foldersPushed.contains(data[1]))
					continue;
				songs.push(new SongMetadata(data[0], data[1], data[2], modId, diffs));
				if (!foldersPushed.contains(data[1]))
					foldersPushed.push(data[1]);
			}
		}

		foldersPushed.resize(0);
		foldersPushed = null;

		add(new FlxSprite().loadGraphic(Mods.menuImage('ui/backgrounds/menuBGBlue')));
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
		scoreText.setFormat(Mods.menuFont("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite().makeScaledGraphic(Std.int(FlxG.width * 0.35), 100, 0xFF000000);
		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		infoText = new FlxText(scoreText.x, diffText.y + 36, scoreBG.width - 10, "", 32);
		diffText.font = scoreText.font;
		infoText.font = diffText.font;
		infoText.alignment = CENTER;
		infoText.size = 20;

		add(scoreBG);
		add(diffText);
		add(infoText);
		add(scoreText);

		playlistGroup = new FlxTypedGroup();
		playlistGroup.visible = playlistVisible;
		add(playlistGroup);

		togglePlaylist(playlistVisible);
		changeVertical();
	}

	function togglePlaylist(v:Bool) {
		scoreBG.updateHitbox();
		playlistVisible = v;
		scoreBG.scale.y = v ? FlxG.height : 100;
		scoreBG.alpha = v ? 0.7 : 0.6;
		scoreBG.updateHitbox();
		scoreBG.x = scoreText.x - 6;
		refreshPlaylistDisplay();
	}

	function refreshPlaylistDisplay() {
		playlistGroup.visible = playlistVisible;
		while (playlistGroup.members.length != 0)
			playlistGroup.members.pop().destroy();
		if (!playlistVisible) {
			infoText.text = "Press CTRL to view playlist";
			return;
		}
		refreshPlaylistItems();
	}

	function refreshPlaylistItems() {
		var text:String = "Empty (TAB to add selected song)";
		if (selectedSongs != null && selectedSongs.length > 0)
			text = "=== PLAYLIST ===";
		infoText.text = text;
		while (playlistGroup.members.length != 0)
			playlistGroup.members.pop().destroy();
		var yPos:Float = infoText.y + 50;
		var xPos:Float = infoText.x;
		for (song in selectedSongs) {
			var lineText:FlxText = playlistGroup.recycle(FlxText);
			lineText.setFormat(Mods.menuFont("vcr.ttf"), 22, FlxColor.WHITE);
			lineText.text = song.songName + ' [${song.curDifficulty.toUpperCase()}]';
			lineText.setPosition(xPos, yPos);
			playlistGroup.add(lineText);
			if (yPos > FlxG.height - 40)
				break;
			yPos += lineText.height;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.keys.justPressed.CONTROL)
			togglePlaylist(!playlistVisible);
		if (FlxG.keys.justPressed.TAB && playlistVisible) {
			var curSong = songs[curVertical];
			var index:Int = selectedSongs.indexOf(curSong);
			if (index != -1)
				selectedSongs.splice(index, 1);
			else {
				curSong.curDifficulty = lastDifficultyArray[curHorizontal].toLowerCase();
				selectedSongs.push(curSong);
			}
			refreshPlaylistItems();
		}
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
		var curSong = songs[song];
		PlayState.playlist.clear();
		PlayState.playlist.toggleStory(false);
		if (selectedSongs.length > 0) {
			curSong = selectedSongs[0];
			for (song in selectedSongs)
				PlayState.playlist.addSongFromMetadata(song, song.curDifficulty);
		} else {
			curSong.curDifficulty = lastDifficultyArray[curHorizontal].toLowerCase();
			PlayState.playlist.addSongFromMetadata(curSong, curSong.curDifficulty);
		}
		var songID:String = '${curSong.mod}:${curSong.songFolder}';
		if (prevSong == songID)
			Paths.skipNextClear = true;
		prevSong = songID;

		PlayState.playlist.getCurrent(); // set the song to the current one.
		FlxG.switchState(new gameplay.PlayState());
	}

	override function onBackPressed():Void {
		if (playlistVisible) {
			togglePlaylist(false);
			return;
		}
		util.StateOverride.switchState("menus.MainMenuState");
		Mods.currentMod = null;
	}

	override function onVerticalChanged(index:Int) {
		if (songs[curVertical].mod != Mods.currentMod)
			Mods.currentMod = songs[curVertical].mod;
		FlxG.sound.play(Mods.menuSound("scrollMenu"));
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

	override function changeHorizontal(next:Int = 0):Void {
		var prev:Int = curHorizontal;
		curHorizontal = flixel.math.FlxMath.wrap(curHorizontal + next, minHorizontals, maxHorizontals);
		onHorizontalChanged(curHorizontal);
		if (curHorizontal != prev) // so your ears don't blow up
			FlxG.sound.play(Mods.menuSound("scrollMenu"));
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
