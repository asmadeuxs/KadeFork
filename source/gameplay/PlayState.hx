package gameplay;

import data.Highscore;
import data.JudgementData;
import data.Section;
import data.Song;
import effects.WiggleEffect;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import gameplay.Strumline;
import haxe.Json;
import lime.app.Application;
import lime.graphics.Image;
import lime.media.AudioContext;
import lime.media.AudioManager;
import lime.utils.Assets;
import menus.StoryMenuState;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import openfl.geom.Matrix;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetManifest;
import openfl.utils.AssetType;
import ui.HealthIcon;

using CoolUtil;
using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end
#if sys
import sys.FileSystem;
#end

class PlayState extends MusicBeatState {
	public static var current:PlayState;
	public static var SONG:SwagSong;

	public static var curStage:String = '';
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public static var judgementData:JudgementData;
	public static var invalidSession:Bool = false;

	var songLength:Float = 0;

	var storyDifficultyText:String = "";
	#if discord_rpc
	// Discord RPC variables
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	private var inst:FlxSound;
	private var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var noteSpawnIndex:Int = 0;

	public var strumlines:FlxTypedSpriteGroup<Strumline>;
	public var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public var opponentStrums:Strumline;
	public var playerStrums:Strumline;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	public static var misses:Int = 0;
	public static var comboBreaks:Int = 0;

	private var accuracy:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalPlayed:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;
	private var songPositionBar:Float = 0;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	public var hudDisplay:FlxSpriteGroup;
	public var comboDisplay:FlxSpriteGroup;

	var notesHitArray:Array<Date> = [];
	var currentFrames:Int = 0;

	var songScore:Int = 0;
	var scoreTxt:FlxText;

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;
	var inCutscene:Bool = false;

	// Will decide if she's even allowed to headbang at all depending on the song
	private var allowedToHeadbang:Bool = false;

	// Per song additive offset
	public static var songOffset:Float = 0;

	override public function create() {
		super.create();
		current = this;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		misses = 0;
		comboBreaks = 0;
		judgementData = new JudgementData();

		storyDifficultyText = switch (storyDifficulty) {
			case 0: "Easy";
			case 1: "Normal";
			case 2: "Hard";
			case _: "UnknownDifficulty";
		}

		#if discord_rpc
		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		iconRPC = switch (iconRPC) {
			case 'senpai-angry': 'senpai';
			case 'monster-christmas': 'monster';
			case 'mom-car': 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? 'Story Mode: Week  $storyWeek' : "Freeplay";

		// String for when the game is paused
		detailsPausedText = 'Paused - $detailsText';

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText + ' ${SONG.song} ($storyDifficultyText)' iconRPC);
		#end

		camGame = FlxG.camera;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		trace('INFORMATION ABOUT WHAT U PLAYIN WIT:\nFRAMES: '
			+ Conductor.safeFrames
			+ '\nZONE: '
			+ Conductor.safeZoneOffset
			+ '\nTS: '
			+ Conductor.timeScale);

		switch (SONG.song.toLowerCase()) {
			default:
				defaultCamZoom = 0.9;
				curStage = 'stage';
				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stages/week1/stageback'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				add(bg);

				var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stages/week1/stagefront'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				add(stageFront);

				var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stages/week1/stagecurtains'));
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				stageCurtains.antialiasing = true;
				stageCurtains.scrollFactor.set(1.3, 1.3);
				stageCurtains.active = false;

				add(stageCurtains);
		}
		var gfVersion:String = 'gf';
		gf = new Character(400, 130, gfVersion);
		dad = new Character(100, 100, SONG.player2);
		boyfriend = new Character(770, 450, SONG.player1, true);
		gf.scrollFactor.set(0.95, 0.95);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
		switch (SONG.player2) {
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode) {
					camPos.x += 600;
					tweenCamIn();
				}
			case 'dad':
				camPos.x += 400;
		}
		add(gf);
		add(dad);
		add(boyfriend);

		Conductor.songPosition = -5000;

		hudDisplay = new FlxSpriteGroup();
		hudDisplay.camera = camHUD;
		add(hudDisplay);

		comboDisplay = new FlxSpriteGroup();
		comboDisplay.camera = camHUD;
		add(comboDisplay);

		strumlines = new FlxTypedSpriteGroup(0, 0);
		strumlines.camera = camHUD;
		add(strumlines);

		var strumY:Float = 30;
		if (Preferences.user.scrollType == 1)
			strumY = FlxG.height - 145;
		opponentStrums = new Strumline(0, strumY);
		playerStrums = new Strumline(0, strumY);

		opponentStrums.x = (FlxG.width - opponentStrums.width) * 0.05;
		playerStrums.x = (FlxG.width - playerStrums.width) * 0.8;

		strumlines.add(playerStrums);
		strumlines.add(opponentStrums);

		notes = new FlxTypedGroup<Note>();
		notes.camera = camHUD;
		add(notes);

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		camGame.follow(camFollow, LOCKON, 0.04 * (30 / Preferences.user.frameRate));
		// camGame.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.zoom = defaultCamZoom;
		camGame.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;

		if (Preferences.user.showSongPosition) // I dont wanna talk about this code :(
		{
			var songPosBG = new FlxSprite(0, 10).loadGraphic(Paths.image('gameplay/ui/healthBar'));
			if (Preferences.user.scrollType == 1)
				songPosBG.y = FlxG.height * 0.9 + 45;
			songPosBG.screenCenter(X);
			hudDisplay.add(songPosBG);

			var songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
				'songPositionBar', 0, 90000);
			songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
			hudDisplay.add(songPosBar);

			var songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20, songPosBG.y, 0, SONG.song, 16);
			if (Preferences.user.scrollType == 1)
				songName.y -= 3;
			songName.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			hudDisplay.add(songName);
		}

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('gameplay/ui/healthBar'));
		if (Preferences.user.scrollType == 1)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		hudDisplay.add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		hudDisplay.add(healthBar);

		scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 50, 0, "", 20);
		if (!Preferences.user.accuracyDisplay)
			scoreTxt.x = healthBarBG.x + healthBarBG.width / 2;
		scoreTxt.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hudDisplay.add(scoreTxt);

		var songText:FlxText = new FlxText(5, 0, 0, '${SONG.song} ${storyDifficultyText} - KE v${Main.versions.KADE}', 12);
		songText.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songText.y = (FlxG.height - songText.height) - 3;
		hudDisplay.add(songText);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		hudDisplay.add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		hudDisplay.add(iconP2);

		startingSong = true;

		switch (curSong.toLowerCase()) {
			default:
				startCountdown();
		}

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyShit);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, keyUnshit);
	}

	override public function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUnshit);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyShit);
		judgementData = null;
		current = null;
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void {
		inCutscene = false;
		startedCountdown = true;

		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;
		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			characterDance(swagCounter);

			var introPath:String = 'gameplay/ui/countdown/';
			var introAlts:Array<String> = ['ready', 'set', 'go'];
			var altSuffix:String = "";

			switch (swagCounter) {
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[0]));
					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						onComplete: function(twn:FlxTween) ready.destroy(),
						ease: FlxEase.cubeInOut
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[1]));
					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						onComplete: function(twn:FlxTween) set.destroy(),
						ease: FlxEase.cubeInOut
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[2]));
					if (curStage.startsWith('school'))
						go.setGraphicSize(Std.int(go.width * CoolUtil.pixelScale));
					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						onComplete: function(twn:FlxTween) go.destroy(),
						ease: FlxEase.cubeInOut
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:
			}

			swagCounter += 1;
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;
	var songStarted = false;

	function startSong():Void {
		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused) {
			inst.play();
			inst.onComplete = endSong;
		}
		inst.onComplete = endSong;
		vocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = inst.length;

		#if discord_rpc // Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText + ' ${SONG.song} ($storyDifficultyText)\n${scoreTxt.text}' iconRPC);
		#end
	}

	private function generateSong(dataPath:String):Void {
		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(PlayState.SONG.song));
		FlxG.sound.list.add(inst);

		vocals = new FlxSound();
		if (SONG.needsVoices)
			vocals.loadEmbedded(Paths.voices(PlayState.SONG.song));
		FlxG.sound.list.add(vocals);

		var noteData:Array<SwagSection> = songData.notes;

		// Per song offset check
		#if desktop
		var songPath = Paths.getPath('songs/${PlayState.SONG.song.toLowerCase()}/');
		for (file in sys.FileSystem.readDirectory(songPath)) {
			var path = haxe.io.Path.join([songPath, file]);
			if (!sys.FileSystem.isDirectory(path)) {
				if (path.endsWith('.offset')) {
					trace('Found offset file: ' + path);
					songOffset = Std.parseFloat(file.substring(0, file.indexOf('.off')));
					break;
				} else {
					trace('Offset file not found. Creating one @: ' + songPath);
					sys.io.File.saveContent(songPath + songOffset + '.offset', '');
				}
			}
		}
		#end

		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0] /*+ Prefences.user.noteOffset*/ + songOffset;
				if (daStrumTime < 0)
					continue;
				var oldNote:Note = null;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;
				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				// delete duplicates
				if (oldNote != null)
					if (Math.abs(oldNote.strumTime - daStrumTime) < 0.00001 && oldNote.noteData == daNoteData)
						continue;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.mustPress = gottaHitNote;
				// var susLength:Float = swagNote.sustainLength;
				// susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				/*
					for (susNote in 0...Math.floor(susLength))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						unspawnNotes.push(sustainNote);
					}
				 */
			}
		}
		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function tweenCamIn():Void
		FlxTween.tween(camGame, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			if (inst != null) {
				inst.pause();
				vocals.pause();
			}

			#if discord_rpc
			DiscordClient.changePresence('PAUSED on ${SONG.song} ($storyDifficultyText)', iconRPC);
			#end
			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused) {
			if (inst != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if discord_rpc
			if (startTimer.finished)
				DiscordClient.changePresence(detailsText + '${SONG.song} ($storyDifficultyText)', iconRPC, true, songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconRPC);
			#end
		}

		super.closeSubState();
	}

	function resyncVocals():Void {
		vocals.pause();
		inst.play();
		Conductor.songPosition = inst.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	function generateRanking():String {
		if (accuracy == 0)
			return "N/A";
		var ranking:String = judgementData.getClearFlag();
		if (ranking == "N/A")
			return ranking;
		else
			ranking = '($ranking) ';

		// WIFE TIME :)))) (based on Wife3)
		ranking += switch (accuracy) {
			case(_ >= 99.9935) => true: "AAAAA";
			case(_ >= 99.980) => true: "AAAA:";
			case(_ >= 99.970) => true: "AAAA.";
			case(_ >= 99.955) => true: "AAAA";
			case(_ >= 99.90) => true: "AAA:";
			case(_ >= 99.80) => true: "AAA.";
			case(_ >= 99.70) => true: "AAA";
			case(_ >= 99) => true: "AA:";
			case(_ >= 96.50) => true: "AA.";
			case(_ >= 93) => true: "AA";
			case(_ >= 90) => true: "A:";
			case(_ >= 85) => true: "A.";
			case(_ >= 80) => true: "A";
			case(_ >= 70) => true: "B";
			case(_ >= 60) => true: "C";
			case(_ < 60) => true: "D";
			case _: "N/A";
		}
		return ranking;
	}

	override public function update(elapsed:Float) { // debug keys
		#if debug
		if (FlxG.keys.justPressed.F6) {
			perfectMode = true;
			invalidSession = true;
		}
		#end

		if (FlxG.keys.justPressed.SEVEN) {
			#if discord_rpc DiscordClient.changePresence("Chart Editor", null, null, true); #end
			FlxG.switchState(new editor.ChartingState());
		}

		if (FlxG.keys.justPressed.EIGHT) {
			#if discord_rpc DiscordClient.changePresence("Animation Debug", null, null, true); #end
			FlxG.switchState(new editor.AnimationDebug(SONG.player2));
		}
		// end of debug keys

		if (currentFrames == Preferences.user.frameRate) {
			for (i in 0...notesHitArray.length) {
				var cock:Date = notesHitArray[i];
				if (cock != null)
					if (cock.getTime() + 2000 < Date.now().getTime())
						notesHitArray.remove(cock);
			}
			nps = Math.floor(notesHitArray.length / 2);
			currentFrames = 0;
		} else
			currentFrames++;

		if (FlxG.keys.justPressed.NINE) {
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		super.update(elapsed);

		updateScoreText();
		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			if (FlxG.random.bool(0.1))
				FlxG.switchState(new menus.GitarooPause());
			else
				openSubState(new menus.PauseSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (startingSong) {
			if (startedCountdown) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		} else {
			Conductor.songPosition += FlxG.elapsed * 1000;
			songPositionBar = Conductor.songPosition;

			if (!paused) {
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition) {
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
			}
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null) { // Make sure Girlfriend cheers only for certain songs
			if (allowedToHeadbang) { // Don't animate GF if something else is already animating her (eg. train passing)
				if (gf.animation.curAnim.name == 'danceLeft'
					|| gf.animation.curAnim.name == 'danceRight'
					|| gf.animation.curAnim.name == 'idle') { // Per song treatment since some songs will only have the 'Hey' at certain times
					switch (curSong) {
						case 'Bopeebo':
							// Where it starts || where it ends
							if (curBeat > 5 && curBeat < 130) {
								if (curBeat % 8 == 7)
									gf.playAnim('cheer');
							}
					}
				}
			}

			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection) {
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100) {
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
				if (SONG.song.toLowerCase() == 'tutorial')
					FlxTween.tween(camGame, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
			}
		}

		if (camZooming) {
			camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh') {
			switch (curBeat) {
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
			}
		}

		if (health <= 0) {
			boyfriend.stunned = true;
			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			inst.stop();

			openSubState(new gameplay.GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if discord_rpc
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("GAME OVER -- " + '${SONG.song} ($storyDifficultyText)', iconRPC);
			#end
		}

		if (unspawnNotes[noteSpawnIndex] != null) {
			if (unspawnNotes[noteSpawnIndex].strumTime - Conductor.songPosition < 1500) {
				notes.add(unspawnNotes[noteSpawnIndex]);
				noteSpawnIndex++;
			}
		}

		if (generatedMusic) {
			if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !holdInputs.contains(true))
				if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
					boyfriend.dance();

			notes.forEachAlive(function(daNote:Note) {
				if (daNote.y > FlxG.height) {
					daNote.active = false;
					daNote.visible = false;
				} else {
					daNote.visible = true;
					daNote.active = true;
				}

				if (!daNote.mustPress && daNote.wasGoodHit) {
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";
					if (SONG.notes[Math.floor(curStep / 16)] != null)
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					switch (Math.abs(daNote.noteData)) {
						case 2:
							dad.playAnim('singUP' + altAnim, true);
						case 3:
							dad.playAnim('singRIGHT' + altAnim, true);
						case 1:
							dad.playAnim('singDOWN' + altAnim, true);
						case 0:
							dad.playAnim('singLEFT' + altAnim, true);
					}
					dad.holdTimer = 0;
					if (SONG.needsVoices)
						vocals.volume = 1;
					daNote.active = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				var downscroll:Bool = Preferences.user.scrollType == 1;
				var difference:Float = (Conductor.songPosition - daNote.strumTime);
				var scrollSpeed:Float = FlxMath.roundDecimal(Preferences.user.scrollSpeed == 1 ? SONG.speed : Preferences.user.scrollSpeed, 2);
				var noteScroll:Float = difference * ((0.45 * scrollSpeed) * (downscroll ? -1 : 1));

				var noteData:Int = Math.floor(Math.abs(daNote.noteData));
				if (daNote.mustPress) {
					var curStrum = playerStrums.members[noteData];
					daNote.y = curStrum.y - noteScroll;
					daNote.visible = curStrum.visible;
					if (!daNote.isSustainNote)
						daNote.angle = curStrum.angle;
					daNote.alpha = curStrum.alpha;
					daNote.x = curStrum.x;
				} else if (!daNote.wasGoodHit) {
					var curStrum = opponentStrums.members[noteData];
					daNote.y = curStrum.y - noteScroll;
					daNote.visible = curStrum.visible;
					if (!daNote.isSustainNote)
						daNote.angle = curStrum.angle;
					daNote.alpha = curStrum.alpha;
					daNote.x = curStrum.x;
				}

				var noteKill:Bool = false;
				if (!daNote.mustPress) {
					if (daNote.wasGoodHit && daNote.strumTime - Conductor.songPosition <= 0.0)
						noteKill = false;
				} else {
					if (daNote.strumTime - Conductor.songPosition < -(150 + daNote.sustainLength)) {
						health -= 0.075;
						vocals.volume = 0;
						noteMiss(daNote.noteData, daNote);
						noteKill = true;
					}
				}
				if (noteKill) {
					daNote.active = false;
					daNote.visible = false;
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}

	function updateScoreText():Void {
		var layout:String;
		if (Preferences.user.showNps)
			layout = '$nps NPS | ';
		else
			layout = '';
		if (Preferences.user.accuracyDisplay) {
			layout += 'Score:$songScore';
			layout += ' | Misses:$misses';
			layout += ' | Accuracy:${FlxMath.roundDecimal(accuracy, 2)} % | ${generateRanking()}';
		} else
			layout += 'Score:$songScore';
		scoreTxt.text = layout;
	}

	function endSong():Void {
		canPause = false;
		vocals.volume = 0;
		inst.volume = 0;
		if (!invalidSession)
			Highscore.saveScore(SONG.song, Math.round(songScore), storyDifficulty);

		if (isStoryMode) {
			campaignScore += Math.round(songScore);
			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.switchState(new StoryMenuState());

				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;
				if (!invalidSession)
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			} else {
				var difficulty:String = "";
				if (storyDifficulty == 0)
					difficulty = '-easy';
				if (storyDifficulty == 2)
					difficulty = '-hard';

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog') {
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * camGame.zoom,
						-FlxG.height * camGame.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;
					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				inst.stop();

				FlxG.switchState(new gameplay.PlayState());
			}
		} else {
			trace('WENT BACK TO FREEPLAY??');
			FlxG.switchState(new menus.FreeplayState());
		}
	}

	var endingSong:Bool = false;
	var hits:Array<Float> = [];

	var timeShown = 0;
	var currentTimingShown:FlxText = null;

	var showJudgement:Bool = true;
	var showComboNumbers:Bool = true;
	var showComboSprite:Bool = false;

	private function popUpScore(daNote:Note):Void {
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		coolText.y -= 350;
		coolText.cameras = [camHUD];

		var daRating:String = daNote.judgement.name;
		var rating:FlxSprite = new FlxSprite();

		rating.loadGraphic(Paths.image('gameplay/ui/score/$daRating'));
		rating.screenCenter();
		rating.y -= 50;
		rating.x = coolText.x - 125;

		if (FlxG.save.data.changedHit) {
			rating.x = FlxG.save.data.changedHitX;
			rating.y = FlxG.save.data.changedHitY;
		}
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var msTiming = FlxMath.roundDecimal(noteDiff, 3);

		if (currentTimingShown != null)
			comboDisplay.remove(currentTimingShown);

		currentTimingShown = new FlxText(0, 0, 0, "0ms");
		timeShown = 0;
		currentTimingShown.color = switch (daRating) {
			case 'shit' | 'bad': FlxColor.RED;
			case 'good': FlxColor.GREEN;
			case 'sick': FlxColor.CYAN;
			case _: FlxColor.WHITE;
		}
		currentTimingShown.borderStyle = OUTLINE;
		currentTimingShown.borderSize = 1;
		currentTimingShown.borderColor = FlxColor.BLACK;
		currentTimingShown.text = msTiming + "ms";
		currentTimingShown.size = 20;

		if (currentTimingShown.alpha != 1)
			currentTimingShown.alpha = 1;

		comboDisplay.add(currentTimingShown);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gameplay/ui/score/combo'));
		comboSpr.screenCenter();
		comboSpr.x = rating.x;
		comboSpr.y = rating.y + 100;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		currentTimingShown.screenCenter();
		currentTimingShown.x = comboSpr.x + 100;
		currentTimingShown.y = rating.y + 100;
		currentTimingShown.acceleration.y = 600;
		currentTimingShown.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		currentTimingShown.velocity.x += comboSpr.velocity.x;
		comboDisplay.add(rating);
		if (showComboSprite)
			comboDisplay.add(comboSpr);

		var ratingSprScale:Float = 0.65;

		if (!curStage.startsWith('school')) {
			rating.setGraphicSize(Std.int(rating.width * ratingSprScale));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * ratingSprScale));
			comboSpr.antialiasing = true;
		} else {
			rating.setGraphicSize(Std.int(rating.width * CoolUtil.pixelScale * ratingSprScale));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * CoolUtil.pixelScale * ratingSprScale));
		}

		currentTimingShown.updateHitbox();
		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		var comboSplit:Array<String> = (combo + "").split('');
		if (comboSplit.length == 2)
			seperatedScore.push(0);
		for (i in 0...comboSplit.length) {
			var str:String = comboSplit[i];
			seperatedScore.push(Std.parseInt(str));
		}

		var daLoop:Int = 0;
		if (combo >= 10 || combo == 0) {
			var numScoreScale:Float = 0.5;
			for (i in seperatedScore) {
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gameplay/ui/score/num${Std.int(i)}'));
				numScore.screenCenter();
				numScore.x = rating.x + (43 * daLoop) - 50;
				numScore.y = rating.y + 100;
				numScore.cameras = [camHUD];

				if (!curStage.startsWith('school')) {
					numScore.antialiasing = true;
					numScore.setGraphicSize(Std.int(numScore.width * numScoreScale));
				} else
					numScore.setGraphicSize(Std.int(numScore.width * CoolUtil.pixelScale * numScoreScale));
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);
				comboDisplay.add(numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween) numScore.destroy(),
					startDelay: Conductor.crochet * 0.002
				});

				daLoop++;
			}
		}
		coolText.text = Std.string(seperatedScore);
		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001,
			onUpdate: function(tween:FlxTween) {
				if (currentTimingShown != null)
					currentTimingShown.alpha -= 0.02;
				timeShown++;
			}
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween) {
				coolText.destroy();
				comboSpr.destroy();
				if (currentTimingShown != null && timeShown >= 20) {
					comboDisplay.remove(currentTimingShown);
					currentTimingShown = null;
				}
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	// find a way to customise this later          VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
	private static var noteActions:Array<String> = ["note_left", "note_down", "note_up", "note_right"];

	public var holdInputs:Array<Bool> = [false, false, false, false];

	public static function getStrumFromKey(key:FlxKey):Int {
		if (key != NONE) {
			for (i in 0...noteActions.length) { // it didn't let me just use `controls.` for some reason.
				var keys:Array<FlxKey> = Controls.current.actions[noteActions[i]];
				for (noteKey in keys)
					if (key == noteKey && (FlxG.keys.checkStatus(key, JUST_PRESSED) || FlxG.keys.checkStatus(key, JUST_RELEASED)))
						return i;
			}
		}
		return -1;
	}

	public function keyShit(event:KeyboardEvent):Void {
		var key:Int = getStrumFromKey(event.keyCode);
		if (perfectMode || key < 0 || paused || inCutscene || !generatedMusic || endingSong || boyfriend.stunned)
			return;

		var strum = playerStrums.members[key];
		var gottaHits:Array<Note> = notes.members.filter(function(nt:Note):Bool return nt != null && nt.canBeHit && !nt.isSustainNote && nt.noteData == key);
		gottaHits.sort(function(a:Note, b:Note):Int return Std.int(a.strumTime - b.strumTime));
		holdInputs[key] = true;

		if (gottaHits.length != 0) {
			goodNoteHit(gottaHits[0]);
			playerStrums.playAnim(key, "confirm");
		} else {
			playerStrums.playAnim(key, "pressed");
			if (!Preferences.user.ghostTapping)
				noteMiss(key);
		}
	}

	public function keyUnshit(event:KeyboardEvent):Void {
		var key:Int = getStrumFromKey(event.keyCode);
		if (perfectMode || key < 0 || paused || inCutscene || !generatedMusic || endingSong || boyfriend.stunned)
			return;
		holdInputs[key] = false;
		playerStrums.playAnim(key, "static");
	}

	function noteMiss(direction:Int = 1, ?daNote:Note):Void {
		if (!boyfriend.stunned) {
			health -= 0.04;
			songScore -= 10;
			if (combo > 5 && gf.animOffsets.exists('sad'))
				gf.playAnim('sad');
			combo = 0;
			misses++;
			comboBreaks++;

			if (daNote != null) {
				var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
				if (Preferences.user.etternaMode)
					totalNotesHit += data.EtternaFunctions.wife3(noteDiff, 1.7);
			}
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			switch (direction) {
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
			}

			updateAccuracy();
		}
	}

	function updateAccuracy() {
		totalPlayed += 1;
		accuracy = Math.max(0, totalNotesHit / totalPlayed * 100);
	}

	var nps:Int = 0;

	function goodNoteHit(note:Note):Void {
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		note.judgement = judgementData.judgeTime(noteDiff);

		if (!note.isSustainNote)
			notesHitArray.push(Date.now());

		if (!note.wasGoodHit) {
			if (!note.isSustainNote) {
				scoreNote(note);
				popUpScore(note);
				combo += 1;
			} else
				totalNotesHit += 1;

			switch (note.noteData) {
				case 2:
					boyfriend.playAnim('singUP', true);
				case 3:
					boyfriend.playAnim('singRIGHT', true);
				case 1:
					boyfriend.playAnim('singDOWN', true);
				case 0:
					boyfriend.playAnim('singLEFT', true);
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			note.kill();
			notes.remove(note, true);
			note.destroy();

			updateAccuracy();
		}
	}

	private function scoreNote(daNote:Note):Void {
		var score:Float = daNote.judgement.score;
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		if (Preferences.user.etternaMode)
			totalNotesHit += data.EtternaFunctions.wife3(noteDiff, Conductor.timeScale);
		else
			totalNotesHit += daNote.judgement.accuracy;
		health += judgementData.getHealthBonus(daNote.judgement.name);
		daNote.judgement.hits++;
		songScore += Math.round(score);
		if (daNote.judgement.comboBreak == true) {
			comboBreaks++; // unused until I figure something out
			combo = 0;
		}
	}

	override function stepHit() {
		super.stepHit();
		if (inst.time > Conductor.songPosition + 20 || inst.time < Conductor.songPosition - 20)
			resyncVocals();

		#if discord_rpc
		DiscordClient.changePresence(detailsText + ' ${SONG.song} ($storyDifficultyText) ${scoreTxt.text}', iconRPC, true, songLength - Conductor.songPosition);
		#end
	}

	override function beatHit() {
		super.beatHit();

		if (generatedMusic)
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);

		if (SONG.notes[Math.floor(curStep / 16)] != null)
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
				Conductor.bpm = SONG.notes[Math.floor(curStep / 16)].bpm;

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && camGame.zoom < 1.35) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && camGame.zoom < 1.35 && curBeat % 4 == 0) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		characterDance(curBeat);
		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
			boyfriend.playAnim('hey', true);

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48) {
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}
	}

	function characterDance(beat:Int) {
		if (curBeat % dad.beatsToDance == 0)
			dad.dance();
		if (curBeat % (gf.beatsToDance * gfSpeed) == 0)
			gf.dance();
		var bfSinging:Bool = boyfriend.animation.curAnim.name.startsWith("sing");
		if (!bfSinging && curBeat % boyfriend.beatsToDance == 0)
			boyfriend.dance();
	}
}
