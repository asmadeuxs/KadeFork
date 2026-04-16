package gameplay;

import data.Highscore;
import data.JudgementData;
import data.hscript.Script;
import data.hscript.ScriptLoader;
import data.song.KadeForkChart.NoteData;
import data.song.Song.Section;
import data.song.Song;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import gameplay.Strumline;
import gameplay.hud.*;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFLegacy;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import sys.FileSystem;
import ui.HealthIcon;

using StringTools;
using util.CoolUtil;

class PlayState extends MusicBeatState {
	public static var current:PlayState;

	// level info
	public static var SONG(get, set):SwagSong;
	public static var moonSong(default, set):DynamicFormat;
	public static var moonMeta:BasicMetaData;
	public static var curStage:String = '';
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];

	public static var songName:String = "test";
	public static var songTitle(get, never):String;
	public static var difficulty:String = "";
	public static var songLength:Float = 1.0;

	static function set_moonSong(to:DynamicFormat) {
		moonMeta = to.getChartMeta();
		return moonSong = to;
	}

	static function get_SONG()
		return (moonSong is FNFLegacy) ? cast(moonSong, FNFLegacy).data.song : null; // for now (menacing face cuz i can so do that) -srt

	static function set_SONG(to:SwagSong) {
		moonSong = new FNFLegacy(to);
		return to;
	}

	static function get_songTitle():String
		return moonMeta?.title ?? songName ?? 'Unknown Song';

	// okay seriously we really need to replace this
	// I'm thinking some shit like this
	/*
		typedef PlaySession = {
			story:Bool,
			difficulty:String, // not a number
			levelName:String, // level file instead of level ID
		}
	 */
	// then we pass it on PlayState.new
	// also ofc softcoding curStage and gfVersion because we're not caveman
	// probabgly once moonchart is implemented
	// -asmadeuxs
	// level info end
	public static var judgementData:JudgementData;
	public static var invalidSession:Bool = false;

	public static var campaignScore:Int = 0;

	// Score shit | TODO: move this to a class so we can save and load
	// probably after highscore rewrite -asmadeuxs
	public static var songScore:Int = 0;

	// keeping this variable around just for compatibility sake
	public static var misses(get, never):Int;

	static function get_misses():Int
		return judgementData?.getMiss()?.hits ?? 0;

	public static var comboBreaks:Int = 0;
	public static var combo:Int = 0;

	public static var nps:Int = 0;
	public static var maxNps:Int = 0;

	public static var accuracy:Float = 0.00;
	public static var totalNotesHit:Float = 0;
	public static var totalPlayed:Int = 0;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	public var scrollSpeed:Float = 2.5;
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<NoteData> = [];
	public var noteSpawnIndex:Int = 0;

	public var comboDisplay:FlxSpriteGroup;
	public var strumlines:FlxTypedSpriteGroup<Strumline>;
	public var camFollow:FlxObject;

	static var prevCamFollow:FlxObject;

	public var opponentStrums:Strumline;
	public var playerStrums:Strumline;
	public var perfectMode:Bool = false;

	public var maxHealth:Float = 2.0;
	public var minHealth:Float = 0.0;

	var gfSpeed:Int = 1;
	var camZooming:Bool = false;
	var health(default, set):Float = 1;

	function set_health(newHealth:Float):Float
		return health = Math.min(Math.max(newHealth, minHealth), maxHealth);

	var generatedMusic:Bool = false;
	var startingSong:Bool = false;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;

	var notesHitArray:Array<Date> = [];
	var tilNpsUpdate:Float = 1;

	var currentHUD:BaseHUD;

	var defaultCamZoom:Float = 1.05;
	var inCutscene:Bool = false;

	#if hxdiscord_rpc
	// Discord RPC variables
	var iconRPC:String = "";
	var detailsText:String = "";
	#end

	/**
	 * Re-enables some old input behaviour where inputs would freeze if boyfriend gets stunned
	 *
	 * Stunning Sources are:
	 * - Dying (permanent until retry)
	 * - Missing a Note (brief)
	**/
	var stunningPausesInput:Bool = false;

	public function resetScoring() {
		combo = 0;
		songScore = 0;
		comboBreaks = 0;
		totalNotesHit = 0;
		totalPlayed = 0;
		accuracy = 0;
	}

	override public function create() {
		super.create();
		current = this;
		Conductor.current.active = false;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		resetScoring();
		judgementData = new JudgementData();

		#if hxdiscord_rpc
		iconRPC = moonMeta.extraData.get(PLAYER_2) ?? "bf";

		// To avoid having duplicate images in Discord assets
		iconRPC = switch iconRPC {
			case 'senpai-angry': 'senpai';
			case 'monster-christmas': 'monster';
			case 'mom-car': 'mom';
			case _: iconRPC;
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? 'on Story Mode (Level $storyWeek)' : "in Freeplay";

		// Updating Discord Rich Presence.
		DiscordClient.changePresence('${moonMeta.title} (${difficulty.toUpperCase()})', detailsText, iconRPC);
		#end

		camGame = FlxG.camera;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		persistentUpdate = true;
		persistentDraw = true;

		if (moonSong == null)
			moonSong = Song.loadFromFile('tutorial');

		switch (moonMeta.extraData.exists(STAGE) ? moonMeta.extraData.get(STAGE) : "stage") {
			default:
				defaultCamZoom = 0.9;
				curStage = 'stage';
				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stages/week1/stageback'));
				bg.scrollFactor.set(0.9, 0.9);
				bg.antialiasing = true;
				bg.active = false;
				add(bg);

				var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stages/week1/stagefront'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.updateHitbox();
				stageFront.antialiasing = true;
				stageFront.active = false;
				add(stageFront);

				if (!Preferences.user.lowQualityMode) { // the fuck else am i supposed to hide? -asmadeuxs
					var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stages/week1/stagecurtains'));
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.scrollFactor.set(1.3, 1.3);
					stageCurtains.updateHitbox();
					stageCurtains.antialiasing = true;
					stageCurtains.active = false;
					add(stageCurtains);
				}
		}

		var gfVersion:String = 'gf';
		gf = new Character(400, 130, gfVersion);
		dad = new Character(100, 100, moonMeta.extraData.exists(PLAYER_2) ? moonMeta.extraData.get(PLAYER_2) : "bf");
		boyfriend = new Character(770, 450, moonMeta.extraData.exists(PLAYER_1) ? moonMeta.extraData.get(PLAYER_1) : "bf", true);
		gf.scrollFactor.set(0.95, 0.95);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
		switch (moonMeta.extraData.exists(PLAYER_2) ? moonMeta.extraData.get(PLAYER_2) : "bf") {
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

		Conductor.setTime(-5000);

		var underlay:FlxSprite = null;
		if (Preferences.user.strumUnderlay > 0) { // always creating it if its supposed to be visible for the sake adding it for both cases.
			var width:Int = Preferences.user.strumUnderlayType == 1 ? FlxG.width : 1;
			underlay = new FlxSprite().makeScaledGraphic(width, FlxG.height, 0xFF000000);
			underlay.camera = camHUD; // always on camHUD so it renders properly
			underlay.alpha = Preferences.user.strumUnderlay * 0.01;
			if (Preferences.user.strumUnderlayType == 1)
				add(underlay);
		}

		currentHUD = BaseHUD.loadHUD('example');
		comboDisplay = new FlxSpriteGroup();
		strumlines = new FlxTypedSpriteGroup();
		notes = new FlxTypedGroup<Note>();

		perfectText = new FlxText(0, 0, 0, "[BOTPLAY]");
		perfectText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
		perfectText.visible = false;
		perfectText.screenCenter();

		var cacheNotes:Int = 16;
		for (_ in 0...cacheNotes) {
			var note = new Note();
			notes.add(note);
			note.kill();
		}

		currentHUD.camera = camHUD;
		perfectText.camera = camHUD;
		comboDisplay.camera = camHUD;
		strumlines.camera = camHUD;
		notes.camera = camHUD;

		var strumY:Float = 30;
		if (Preferences.user.scrollType == 1)
			strumY = FlxG.height - 185;
		opponentStrums = new Strumline(0, strumY);
		playerStrums = new Strumline(0, strumY);

		opponentStrums.x = (FlxG.width - opponentStrums.width) * 0.05;
		playerStrums.x = (FlxG.width - playerStrums.width) * 0.8;
		strumlines.add(opponentStrums);
		strumlines.add(playerStrums);

		// and underlay to strums if option allows it
		if (underlay != null && Preferences.user.strumUnderlayType == 0) {
			underlay.scale.x = playerStrums.width; // fill strumline region
			underlay.objectCenter(playerStrums, X); // move to last strum
			add(underlay);
		}

		add(currentHUD);
		add(strumlines);
		add(notes);
		add(comboDisplay);
		add(perfectText);

		generateSong();

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		camGame.follow(camFollow, LOCKON, 0.04);
		// camGame.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.zoom = defaultCamZoom;
		camGame.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;

		startingSong = true;

		switch (songName.toLowerCase()) {
			default:
				startCountdown();
		}
	}

	override public function destroy() {
		Conductor.current.active = false;
		Conductor.current.stopMusic();
		Conductor.current.clearTracks();
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUnshit);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyShit);
		judgementData = null;
		current = null;
	}

	var startTimer:FlxTimer;
	var perfectText:FlxText;

	function startCountdown():Void {
		inCutscene = false;
		startedCountdown = true;

		Conductor.current.active = true;
		Conductor.setTime(-Conductor.crotchet * 6.7);

		var swagCounter:Int = 0;
		startTimer = new FlxTimer().start(Conductor.crotchet * 0.001, function(tmr:FlxTimer) {
			characterDance(swagCounter + 1);

			var introPath:String = 'gameplay/ui/countdown/';
			var introAlts:Array<String> = ['ready', 'set', 'go'];
			var altSuffix:String = "";

			switch (swagCounter) {
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[0]));
					ready.scrollFactor.set();
					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crotchet * 0.001, {
						onComplete: function(twn:FlxTween) ready.destroy(),
						ease: FlxEase.cubeInOut
					});
				case 2:
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[1]));
					set.scrollFactor.set();
					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crotchet * 0.001, {
						onComplete: function(twn:FlxTween) set.destroy(),
						ease: FlxEase.cubeInOut
					});
				case 3:
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[2]));
					go.scrollFactor.set();
					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crotchet * 0.001, {
						onComplete: function(twn:FlxTween) go.destroy(),
						ease: FlxEase.cubeInOut
					});
			}

			swagCounter += 1;
		}, 5);
	}

	function startSong():Void {
		canPause = true; // temporary
		// need to figure out why the song just doesn't start if you pause or go to chart editing early -asmadeuxs
		startingSong = false;
		Conductor.current.playMusic();
		Conductor.current.music.onComplete = endSong;
		songLength = Conductor.current.music.length;
	}

	private function generateSong():Void {
		Conductor.bpm = moonMeta.bpmChanges[0].bpm;
		Conductor.mapTimingPoints(moonSong);
		Conductor.current.loadMusic(Paths.inst(PlayState.songName));
		if (moonMeta.extraData.get(NEEDS_VOICES) == true)
			Conductor.current.addTrack(Paths.voices(PlayState.songName));
		scrollSpeed = moonMeta.scrollSpeeds.get(difficulty) ?? 2.5;

		var noteTypes:Array<String> = [];

		for (note in moonSong.getNotes(difficulty)) {
			var daStrumTime:Float = note.time;
			if (daStrumTime < 0)
				continue;
			var oldNote:NoteData = null;
			if (unspawnNotes.length > 0)
				oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

			final lane = Std.int(note.lane % 4);
			final owner = Math.floor(note.lane / 4);
			// delete duplicates
			if (oldNote != null)
				if (Math.abs(oldNote.time - daStrumTime) < 0.00001 && oldNote.lane == lane && oldNote.owner == owner)
					continue;
			var swagNote:NoteData = {
				time: daStrumTime,
				lane: lane,
				type: note.type,
				length: note.length,
				owner: owner
			};
			if (!noteTypes.contains(swagNote.type))
				noteTypes.push(swagNote.type);
			unspawnNotes.push(swagNote);
		}
		unspawnNotes.sort(sortByShit);

		// preload scripts
		for (i in noteTypes) {
			var file:String = ScriptLoader.getScriptFile(Paths.getPath('scripts/notetypes'), i);
			if (file != null)
				ScriptLoader.findScript(file);
		}

		noteTypes.resize(0);
		noteTypes = null;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyShit);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, keyUnshit);
		generatedMusic = true;
	}

	function sortByShit(Obj1:NoteData, Obj2:NoteData):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);

	function tweenCamIn():Void
		FlxTween.tween(camGame, {zoom: 1.3}, (Conductor.semiquaver * 4 * 0.001), {ease: FlxEase.elasticInOut});

	override function openSubState(substate:flixel.FlxSubState) {
		if (paused) {
			Conductor.current.active = false;
			Conductor.current.pauseMusic();
		}
		super.openSubState(substate);
		FlxTimer.globalManager.forEach((timer:FlxTimer) -> if (!timer.finished && timer.active) timer.active = false);
		FlxTween.globalManager.forEach((tween:FlxTween) -> if (!tween.finished && tween.active) tween.active = false);
	}

	override function closeSubState() {
		if (paused) {
			if (!startingSong) {
				Conductor.current.snapTime(positionWhenPaused);
				Conductor.current.playMusic();
				Conductor.current.active = true;
			}
			FlxTimer.globalManager.forEach((timer:FlxTimer) -> if (!timer.finished && !timer.active) timer.active = true);
			FlxTween.globalManager.forEach((tween:FlxTween) -> if (!tween.finished && !tween.active) tween.active = true);
			paused = false;
			#if hxdiscord_rpc
			if (startTimer.finished)
				DiscordClient.changePresence('${moonMeta.title} (${difficulty.toUpperCase()})', detailsText, iconRPC, true, songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence('${moonMeta.title} (${difficulty.toUpperCase()})', detailsText, iconRPC);
			#end
		}
		super.closeSubState();
	}

	private var paused:Bool = false;
	var positionWhenPaused:Float = 0;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;

	public function pause(?pauseDrawing:Bool = false):Void {
		positionWhenPaused = Conductor.songPosition;
		persistentUpdate = false;
		persistentDraw = !pauseDrawing;
		paused = true;
	}

	override public function update(elapsed:Float) { // debug keys
		#if debug
		if (FlxG.keys.justPressed.ONE) {
			invalidSession = true;
			endSong();
		}
		if (FlxG.keys.justPressed.SEVEN && startedCountdown)
			FlxG.switchState(new editor.ChartEditor());
		#end
		if (FlxG.keys.justPressed.F6) {
			invalidSession = true;
			perfectMode = !perfectMode;
			perfectText.visible = perfectMode;
		}
		// end of debug keys

		tilNpsUpdate -= elapsed;
		if (tilNpsUpdate <= 0) {
			for (i in 0...notesHitArray.length) {
				var cock:Date = notesHitArray[i];
				if (cock != null)
					if (cock.getTime() + 2000 < Date.now().getTime())
						notesHitArray.remove(cock);
			}
			nps = Math.floor(notesHitArray.length * 0.5);
			if (nps > maxNps)
				maxNps = nps;
			tilNpsUpdate = 1;
		}

		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause) {
			pause();
			Conductor.current.stopMusic();
			#if hxdiscord_rpc
			DiscordClient.changePresence('${moonMeta.title} (${difficulty.toUpperCase()})', 'Paused $detailsText', iconRPC);
			#end
			openSubState(new menus.PauseSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (startingSong && startedCountdown && Conductor.songPosition >= 0)
			startSong();

		if (camZooming) {
			camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		if (health <= 0) {
			pause(true);
			boyfriend.stunned = true;
			Conductor.current.stopMusic();
			openSubState(new gameplay.GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if hxdiscord_rpc
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence('${moonMeta.title} (${difficulty.toUpperCase()})', 'Game Over!', iconRPC);
			#end
		}

		while (noteSpawnIndex < unspawnNotes.length) {
			var nextNote:NoteData = unspawnNotes[noteSpawnIndex];
			if (nextNote.time - Conductor.songPosition > 1500)
				break;
			var strumline:Strumline = strumlines.members[nextNote.owner];
			if (strumline != null) {
				var oldNote:Note = (notes.members.length > 0) ? notes.members[notes.members.length - 1] : null;
				var swagNote:Note = notes.recycle(Note).setup(nextNote.time, nextNote.lane, nextNote.owner, nextNote.length, nextNote.type, oldNote);
				if (nextNote.type == null || nextNote.type == 'default' || nextNote.type == '0')
					strumline.noteskin.generateArrow(nextNote.lane, swagNote);
				swagNote.mustPress = (strumline == playerStrums);
			}
			noteSpawnIndex++;
		}

		if (generatedMusic) {
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.y > FlxG.height) {
					daNote.active = false;
					daNote.visible = false;
				} else {
					daNote.visible = true;
					daNote.active = true;
				}

				if (!daNote.mustPress && daNote.wasGoodHit) {
					if (songName != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";
					if (curSection != null && curSection.altAnim)
						altAnim = '-alt';
					dad.sing(daNote.noteData, altAnim, true);
					dad.danceCooldown = (Conductor.semiquaver) + daNote.sustainLength;
					for (vocal in Conductor.current.tracks)
						vocal.volume = 1;
					daNote.active = false;
					daNote.kill();
				}

				var downscroll:Bool = Preferences.user.scrollType == 1;
				var difference:Float = (Conductor.songPosition - daNote.strumTime);
				var scrollSpeed:Float = FlxMath.roundDecimal(Preferences.user.scrollSpeed == 1 ? scrollSpeed : Preferences.user.scrollSpeed, 2);
				var noteScroll:Float = difference * ((0.45 * scrollSpeed) * (downscroll ? -1 : 1));
				var curStrum = strumlines.members[daNote.noteOwner].getStrum(daNote.noteData);
				if (curStrum != null) {
					daNote.y = curStrum.y - noteScroll;
					daNote.visible = curStrum.visible;
					if (!daNote.isSustainNote)
						daNote.angle = curStrum.angle;
					daNote.alpha = curStrum.alpha;
					daNote.objectCenter(curStrum, X);
				}

				var noteKill:Bool = false;
				var autoHit:Bool = !daNote.mustPress || (daNote.mustPress && perfectMode);
				if (autoHit) {
					if (daNote.strumTime <= Conductor.songPosition && !daNote.isFake) {
						if (daNote.mustPress)
							goodNoteHit(daNote);
						else
							daNote.wasGoodHit = true;
						noteKill = false;
					}
				} else if (daNote.mustPress) {
					var safeZone:Float = judgementData.maxHitWindow ?? 180.0;
					if (daNote.strumTime < Conductor.songPosition - safeZone)
						daNote.tooLate = true;
					if (!daNote.missed && daNote.strumTime - Conductor.songPosition < -(150 + daNote.sustainLength)) {
						health -= 0.075;
						for (vocal in Conductor.current.tracks)
							vocal.volume = 0;
						noteMiss(daNote.noteData, daNote);
						daNote.missed = true;
						noteKill = true;
					}
				}
				if (noteKill) {
					daNote.active = false;
					daNote.visible = false;
					daNote.kill();
				}
			});
		}
	}

	function endSong():Void {
		canPause = false;
		Conductor.current.stopMusic();
		if (!invalidSession)
			Highscore.saveScore(songName, Math.round(songScore), difficulty);

		/*
			if (isStoryMode) {
				campaignScore += Math.round(songScore);
				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0) {
					Conductor.current.clearTracks();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;
					FlxG.switchState(new StoryMenuState());
					StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;
					if (!invalidSession)
						Highscore.saveWeekScore(storyWeek, campaignScore, difficulty);
					FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
					FlxG.save.flush();
				} else {
					trace('LOADING NEXT SONG');
					trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					PlayState.moonSong = Song.loadFromFile(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
					prevCamFollow = camFollow;

					Conductor.current.active = false;
					Conductor.current.stopMusic();
					FlxG.switchState(new gameplay.PlayState());
				}
		} else*/ {
			trace('WENT BACK TO FREEPLAY??');
			if (!FlxG.sound.music.playing) {
				FlxG.sound.playMusic(Paths.inst(PlayState.songName), 0);
				FlxG.sound.music.time = FlxG.random.int(0, Std.int(FlxG.sound.music.length * 0.5));
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
			FlxG.switchState(new menus.FreeplayState());
		}
	}

	var endingSong:Bool = false;
	var hits:Array<Float> = [];
	var currentTimingShown:FlxText = null;
	var showJudgement:Bool = true;
	var showComboNumbers:Bool = true;
	var showComboSprite:Bool = false;

	public function popUpScore(daNote:Note):Void {
		popUpRating(daNote.judgement.image);
		popUpCombo(combo, daNote.judgement);
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		popUpMillisecondDisplay(FlxMath.roundDecimal(noteDiff, 3), daNote.judgement);
	}

	public function popUpRating(image:String):Void {
		var position:Float = FlxG.width * 0.55;
		var rating:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gameplay/ui/score/$image'));
		rating.screenCenter(Y);
		rating.x = position - 125;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.y -= 50;

		var ratingSprScale:Float = 0.65;
		rating.setGraphicSize(Std.int(rating.width * ratingSprScale));
		rating.updateHitbox();
		comboDisplay.add(rating);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: (tween:FlxTween) -> rating.destroy(),
			startDelay: Conductor.crotchet * 0.001
		});
	}

	public function popUpCombo(combo:Int, ?judgement:Judgement = null):Void {
		var comboSprScale:Float = 0.65;
		var color:FlxColor = judgement.color ?? FlxColor.WHITE;
		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gameplay/ui/score/combo'));
		comboSpr.screenCenter();
		comboSpr.x += 100;
		comboSpr.y += 50;

		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.velocity.x += FlxG.random.int(1, 10);
		comboSpr.setGraphicSize(Std.int(comboSpr.width * comboSprScale));
		comboSpr.updateHitbox();
		comboSpr.color = color;
		if (showComboSprite)
			comboDisplay.add(comboSpr);

		var seperatedScore:Array<String> = Std.string(combo).split('');
		var numScoreScale:Float = 0.5;
		for (daLoop => i in seperatedScore) {
			var numScore:FlxSprite = new FlxSprite(0, comboSpr.y + 30).loadGraphic(Paths.image('gameplay/ui/score/num$i'));
			numScore.setGraphicSize(Std.int(numScore.width * numScoreScale));
			numScore.x = comboSpr.x + (43 * daLoop) - 50;
			numScore.updateHitbox();
			numScore.color = color;

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			comboDisplay.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: (tween:FlxTween) -> numScore.destroy(),
				startDelay: Conductor.crotchet * 0.002
			});
		}
		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: (tween:FlxTween) -> comboSpr.destroy(),
			startDelay: Conductor.crotchet * 0.001
		});
	}

	public function popUpMillisecondDisplay(timing:Float, ?judgement:Judgement = null) {
		if (currentTimingShown != null) {
			FlxTween.cancelTweensOf(currentTimingShown, ['alpha']);
			comboDisplay.remove(currentTimingShown);
		}
		var color:FlxColor = judgement.color ?? FlxColor.WHITE;
		var position:Float = FlxG.width * 0.55;
		currentTimingShown = new FlxText(position - 125, 50, 0, timing + "ms");
		currentTimingShown.setFormat(null, 20, color, LEFT);
		currentTimingShown.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		currentTimingShown.alpha = 1;

		currentTimingShown.screenCenter();
		currentTimingShown.x += 150;
		currentTimingShown.y += 100;
		currentTimingShown.acceleration.y = 600;
		currentTimingShown.velocity.y -= 150;
		currentTimingShown.moves = true;
		currentTimingShown.velocity.x += FlxG.random.int(1, 10);
		currentTimingShown.updateHitbox();
		comboDisplay.add(currentTimingShown);

		FlxTween.tween(currentTimingShown, {alpha: 0}, 0.2, {
			startDelay: Conductor.crotchet * 0.001,
			onComplete: function(tween:FlxTween) {
				if (currentTimingShown != null) {
					comboDisplay.remove(currentTimingShown);
					currentTimingShown = null;
				}
			},
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
		var stunned:Bool = boyfriend.stunned && stunningPausesInput;
		if (perfectMode || key == -1 || paused || inCutscene || !generatedMusic || endingSong || stunned)
			return;

		var strum = playerStrums.members[key];
		var gottaHits:Array<Note> = notes.members.filter(function(nt:Note):Bool return nt != null && nt.canBeHit && !nt.isSustainNote && nt.noteData == key);
		gottaHits.sort(function(a:Note, b:Note):Int return Std.int(a.strumTime - b.strumTime));
		holdInputs[key] = true;

		if (gottaHits.length != 0) {
			if (gottaHits[0].isMine)
				noteMiss(key, gottaHits[0]);
			else
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
		var stunned:Bool = boyfriend.stunned && stunningPausesInput;
		if (perfectMode || key == -1 || paused || inCutscene || !generatedMusic || endingSong || stunned)
			return;
		holdInputs[key] = false;
		playerStrums.playAnim(key, "static");
	}

	function noteMiss(direction:Int = 1, ?daNote:Note):Void {
		if (boyfriend.stunned)
			return;

		if (daNote != null && daNote.noteScript != null) {
			var caller = daNote.noteScript.callFunc('onNoteMiss', [daNote, direction]).value;
			if (caller == ScriptLoader.STOP_FUNC)
				return;
		}
		songScore -= 10;
		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');
		comboBreaks++;
		if (combo > 0)
			combo = 0;
		else
			combo--;
		var missJudge = judgementData.getMiss();
		missJudge.hits++;
		health += judgementData.getHealthBonus(missJudge, health);
		popUpRating(missJudge.image);
		popUpCombo(combo, missJudge);

		if (daNote != null) {
			var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
			if (Preferences.user.etternaMode)
				totalNotesHit += util.EtternaFunctions.wife3(noteDiff, 1.7);
		}
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		boyfriend.miss(direction, true);
		boyfriend.danceCooldown = (Conductor.semiquaver) * 0.2;
		updateAccuracy();
		if (currentHUD != null)
			currentHUD.updateScoreText();
	}

	function updateAccuracy() {
		totalPlayed += 1;
		accuracy = Math.max(0, totalNotesHit / totalPlayed * 100);
	}

	function goodNoteHit(note:Note):Void {
		if (note != null && note.noteScript != null) {
			var caller = note.noteScript.callFunc('onNoteHit', [note]).value;
			if (caller == ScriptLoader.STOP_FUNC)
				return;
		}

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		note.judgement = judgementData.judgeTime(noteDiff);

		if (!note.isSustainNote)
			notesHitArray.push(Date.now());

		if (!note.isSustainNote) {
			scoreNote(note);
			if (combo < 0)
				combo = 0;
			combo += 1;
			popUpScore(note);
			if (Preferences.user.noteSplashes && note.judgement.splash)
				playerStrums.spawnSplash(note.noteData);
		} else
			totalNotesHit += 1;

		boyfriend.sing(note.noteData, true);
		boyfriend.danceCooldown = (Conductor.semiquaver) + note.sustainLength;
		note.wasGoodHit = true;
		for (vocal in Conductor.current.tracks)
			vocal.volume = 1;
		note.kill();
		updateAccuracy();
		if (currentHUD != null)
			currentHUD.updateScoreText();
	}

	private function scoreNote(daNote:Note):Void {
		var score:Float = daNote.judgement.score;
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		if (Preferences.user.etternaMode)
			totalNotesHit += util.EtternaFunctions.wife3(judgementData.maxHitWindow, noteDiff);
		else
			totalNotesHit += daNote.judgement.accuracy;
		health += judgementData.getHealthBonus(daNote.judgement, health);
		daNote.judgement.hits++;
		songScore += Math.round(score);
		if (daNote.judgement.comboBreak == true) {
			comboBreaks++; // unused until I figure something out
			combo = 0;
		}
	}

	override function beatHit(curBeat:Int) {
		if (generatedMusic)
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);

		if (camZooming && camGame.zoom < 1.35 && curBeat % 4 == 0) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (currentHUD != null)
			currentHUD.beatHit(curBeat);
		characterDance(curBeat);

		switch songName.toLowerCase() {
			case 'tutorial':
				if (curBeat % 16 == 15 && dad.characterId == 'gf' && curBeat > 16 && curBeat < 48) {
					boyfriend.playAnim('hey', true);
					dad.playAnim('cheer', true);
				}
			case 'bopeebo':
				if (curBeat % 8 == 7)
					boyfriend.playAnim('hey', true);
				if (curBeat > 5 && curBeat < 130 && curBeat % 8 == 7)
					gf.playAnim('cheer');
			case 'fresh':
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
	}

	var curSection:SwagSection;

	override function barHit(bar:Int) {
		curSection = SONG.notes[bar];

		if (generatedMusic && curSection != null) {
			var mustHitSec:Bool = curSection.mustHitSection;
			var nextChar:Character = mustHitSec ? boyfriend : dad;
			var mid = nextChar.getMidpoint();
			var off = nextChar.cameraOffset;
			camFollow.setPosition(mid.x + off.x, mid.y + off.y);
			// do not remove this line its funny as fuck PLEASEEEEE don't remove it lmao -asmadeuxs
			// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

			if (songName.toLowerCase() == 'tutorial')
				FlxTween.tween(camGame, {zoom: 1}, (Conductor.semiquaver * 4 * 0.001), {ease: FlxEase.elasticInOut});
		}
	}

	function characterDance(beat:Int) {
		if (beat % dad.beatsToDance == 0)
			dad.dance();
		if (beat % Math.floor(gf.beatsToDance * gfSpeed) == 0)
			gf.dance();
		if (!boyfriend.isSinging() && beat % boyfriend.beatsToDance == 0)
			boyfriend.dance();
	}
}
