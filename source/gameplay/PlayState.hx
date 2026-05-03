package gameplay;

import data.Highscore;
import data.JudgementManager.Judgement;
import data.PlaySession;
import data.hscript.Script;
import data.hscript.ScriptLoader;
import data.song.KadeForkChart.NoteData;
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
import gameplay.hud.*;
import gameplay.note.Note;
import gameplay.note.NoteRenderer;
import gameplay.note.Strumline;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacyMetaValues;
import moonchart.formats.fnf.legacy.FNFPsych;
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
		return (moonSong is FNFPsych) ? cast(moonSong).data.song : null; // for now (menacing face cuz i can so do that) -srt

	static function set_SONG(to:SwagSong) {
		moonSong = new FNFPsych(to);
		return to;
	}

	static function get_songTitle():String
		return moonMeta?.title ?? songName ?? 'Unknown Song';

	public static var campaignScore:Int = 0;
	public static var session:PlaySession;

	public static var nps:Int = 0;
	public static var maxNps:Int = 0;

	public var stage:StageBG;
	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	public var notes:NoteRenderer;
	public var scrollSpeed:Float = 2.5;
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

	// find a way to customise this later          VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
	public static var noteActions:Array<String> = ["note_left", "note_down", "note_up", "note_right"];

	public var holdInputs:Array<Bool> = [false, false, false, false];
	public var inputEnabled:Bool = false;

	var inputQueue:Array<Array<Note>> = [];
	var twoPlayerMode:Bool = false;
	var inputMgr:InputManager;

	override public function create() {
		super.create();
		current = this;
		Conductor.current.active = false;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (session != null)
			session.reset();
		else
			session = new PlaySession();

		inputMgr = new InputManager(keyPressed, keyReleased);
		inputQueue.resize(noteActions.length);
		for (i in 0...inputQueue.length)
			inputQueue[i] = [];
		for (noteData in 0...noteActions.length) {
			var action = noteActions[noteData];
			var keys:Array<FlxKey> = Controls.current.actions[action];
			for (key in keys)
				inputMgr.remapKeyCode(key, noteData);
		}
		inputMgr.init(); // NEED to do this
		#if hxdiscord_rpc
		iconRPC = moonMeta.extraData.get(PLAYER_2) ?? "bf";

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? 'on Story Mode (Level $storyWeek)' : "in Freeplay";

		// Updating Discord Rich Presence.
		DiscordClient.changePresence('${moonMeta.title} (${difficulty.toUpperCase()})', detailsText, iconRPC);
		#end

		camGame = FlxG.camera;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camFollow = new FlxObject(0, 0, 1, 1);
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		camGame.follow(camFollow, LOCKON, 0.04);
		// camGame.setScrollBounds(0, FlxG.width, 0, FlxG.height);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;

		persistentUpdate = true;
		persistentDraw = true;

		if (moonSong == null)
			moonSong = Song.loadFromFile('core', 'test');
		generateSong();

		curStage = moonMeta.extraData.exists(STAGE) ? moonMeta.extraData.get(STAGE) : "stage";
		stage = new StageBG(curStage);
		defaultCamZoom = stage.cameraZoom;
		add(stage);

		gf = new Character(400, 130, moonMeta.extraData.exists(PLAYER_3) ? moonMeta.extraData.get(PLAYER_3) : "bf");
		dad = new Character(100, 100, moonMeta.extraData.exists(PLAYER_2) ? moonMeta.extraData.get(PLAYER_2) : "bf");
		boyfriend = new Character(770, 450, moonMeta.extraData.exists(PLAYER_1) ? moonMeta.extraData.get(PLAYER_1) : "bf", true);

		positionCharacters();
		add(gf);
		add(dad);
		add(boyfriend);

		camGame.zoom = defaultCamZoom;
		camGame.focusOn(camFollow.getPosition());

		var underlay:FlxSprite = null;
		if (Preferences.user.strumUnderlay > 0) { // always creating it if its supposed to be visible for the sake adding it for both cases.
			var width:Int = Preferences.user.strumUnderlayType == 1 ? FlxG.width : 1;
			underlay = new FlxSprite().makeScaledGraphic(width, FlxG.height, 0xFF000000);
			underlay.camera = camHUD; // always on camHUD so it renders properly
			underlay.alpha = Preferences.user.strumUnderlay * 0.01;
			if (Preferences.user.strumUnderlayType == 1)
				add(underlay);
		}

		currentHUD = BaseHUD.loadHUD(Preferences.user.hudStyle);
		comboDisplay = new FlxSpriteGroup();
		strumlines = new FlxTypedSpriteGroup();
		notes = new NoteRenderer(unspawnNotes);
		notes.noteSpawned.add(queueInputNote);
		notes.noteKilled.add(removeNoteFromInputQueue);

		perfectText = new FlxText(0, 0, 0, "[BOTPLAY]");
		perfectText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
		perfectText.visible = false;
		perfectText.screenCenter();

		currentHUD.camera = camHUD;
		perfectText.camera = camHUD;
		comboDisplay.camera = camHUD;
		strumlines.camera = camHUD;
		notes.camera = camHUD;

		opponentStrums = new Strumline();
		playerStrums = new Strumline();

		opponentStrums.x = (FlxG.width - opponentStrums.width) * 0.05;
		if (Preferences.user.centerStrums) {
			playerStrums.x = (FlxG.width - playerStrums.width) * 0.5;
			opponentStrums.visible = false;
		} else
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

		startSongCutscene();
	}

	public function startSongCutscene() {
		switch (songName.toLowerCase()) {
			default:
				startCountdown();
		}
		startingSong = true;
	}

	override public function destroy() {
		Conductor.current.active = false;
		Conductor.current.stopMusic();
		Conductor.current.clearTracks();
		inputMgr.destroy();
		session.judgeMan = null;
		current = null;
	}

	// For stage reloading
	public function positionCharacters() {
		// this looks ugly.
		if (boyfriend != null && stage.characterOffsets.exists('player')) {
			var o:Array<Float> = stage.characterOffsets.get('player');
			boyfriend.x = 770 + o[0];
			boyfriend.y = 450 + o[1];
		}
		if (dad != null && stage.characterOffsets.exists('opponent')) {
			var o:Array<Float> = stage.characterOffsets.get('opponent');
			dad.x = 100 + o[0];
			dad.y = 100 + o[1];
		}
		if (gf != null && stage.characterOffsets.exists('metronome')) {
			var o:Array<Float> = stage.characterOffsets.get('metronome');
			gf.x = 400 + o[0];
			gf.y = 130 + o[1];
		}
		// gf.scrollFactor.set(0.95, 0.95);
		if (dad != null) {
			if (gf != null && dad.characterId == gf.characterId) {
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
					tweenCamIn();
			}
			var mid = dad.getMidpoint();
			var off = dad.cameraOffset;
			var camPos:FlxPoint = new FlxPoint(mid.x + off.x, mid.y + off.y);
			camFollow.setPosition(camPos.x, camPos.y);
		}
	}

	var startTimer:FlxTimer;
	var perfectText:FlxText;

	function startCountdown():Void {
		inCutscene = false;
		startedCountdown = true;
		inputEnabled = true;

		Conductor.current.active = true;
		Conductor.setTime(-Conductor.crotchet * 8);

		var swagCounter:Int = 0;
		startTimer = new FlxTimer().start(Conductor.crotchet * 0.001, function(tmr:FlxTimer) {
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
	}

	private function generateSong():Void {
		Conductor.bpm = moonMeta.bpmChanges[0].bpm;
		Conductor.mapTimingPoints(moonSong);
		Conductor.current.loadMusic(Paths.inst(PlayState.songName, PlayState.difficulty, util.Mods.currentMod));
		if (moonMeta.extraData.get(NEEDS_VOICES) == true) // TODO: separate Player and Opponent vocals
			Conductor.current.addTrack(Paths.voices(PlayState.songName, PlayState.difficulty, util.Mods.currentMod));
		songLength = Conductor.current.music.length;
		scrollSpeed = moonMeta.scrollSpeeds.get(difficulty) ?? 2.5;

		unspawnNotes.resize(0);
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
			// @formatter:off
			var swagNote:NoteData = {time: daStrumTime, lane: lane, type: note.type, length: 0, owner: owner};
			unspawnNotes.push(swagNote);
			// @formatter:on
			if (!noteTypes.contains(swagNote.type))
				noteTypes.push(swagNote.type);
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
				Conductor.current.snapTime(timeBeforePause);
				Conductor.current.playMusic();
				Conductor.current.active = true;
			}
			FlxTimer.globalManager.forEach((timer:FlxTimer) -> if (!timer.finished && !timer.active) timer.active = true);
			FlxTween.globalManager.forEach((tween:FlxTween) -> if (!tween.finished && !tween.active) tween.active = true);
			paused = false;
			#if hxdiscord_rpc
			if (startTimer.finished)
				DiscordClient.changePresence('${moonMeta.title} (${difficulty.toUpperCase()})', detailsText, iconRPC, true, songLength - Conductor.time);
			else
				DiscordClient.changePresence('${moonMeta.title} (${difficulty.toUpperCase()})', detailsText, iconRPC);
			#end
		}
		super.closeSubState();
	}

	var paused:Bool = false;
	var timeBeforePause:Float = 0;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;

	public function pause(?pauseDrawing:Bool = false):Void {
		timeBeforePause = Conductor.time;
		persistentUpdate = false;
		persistentDraw = !pauseDrawing;
		paused = true;
	}

	override public function update(elapsed:Float) { // debug keys
		#if debug
		if (FlxG.keys.justPressed.ONE) {
			session.invalid = true;
			endSong();
		}
		if (FlxG.keys.justPressed.SEVEN && startedCountdown)
			FlxG.switchState(new editor.ChartEditor());
		#end
		if (FlxG.keys.justPressed.F6) {
			session.invalid = true;
			perfectMode = !perfectMode;
			perfectText.visible = perfectMode;
		}
		if (FlxG.keys.justPressed.FIVE) {
			pause();
			openSubState(new ui.DeveloperMenu());
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

		if (startingSong && startedCountdown && Conductor.time >= 0)
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
			return;
		}

		if (generatedMusic) {
			notes.updateNotes(Conductor.time, strumlines.members, scrollSpeed);
			noteUpdate(Conductor.time);
		}
	}

	public function noteUpdate(time:Float):Void {
		for (daNote in notes.getActiveNotes()) {
			var noteKill:Bool = false;
			if (!daNote.mustPress || (daNote.mustPress && perfectMode)) {
				if (daNote.strumTime <= Conductor.time && !daNote.isFake) {
					if (daNote.mustPress)
						goodNoteHit(daNote);
					else
						daNote.wasGoodHit = true;
					noteKill = false;
				}
			} else if (daNote.mustPress) {
				var safeZone:Float = session.judgeMan.maxHitWindow ?? 180.0;
				if (daNote.strumTime < Conductor.time - safeZone)
					daNote.tooLate = true;
				if (!daNote.missed && daNote.strumTime - Conductor.time < -(150 + daNote.sustainLength)) {
					health -= 0.075;
					for (vocal in Conductor.current.tracks)
						vocal.volume = 0;
					noteMiss(daNote.noteData, daNote);
					daNote.missed = true;
					noteKill = true;
				}
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
				notes.removeNote(daNote);
			}
			if (noteKill)
				notes.removeNote(daNote);
		}
	}

	// ok listen I was so paranoid because inputs were taking 10ms (max, can be less) to hit
	// and that sounds like I'm worrying too much I know but this is a rhythm game and I'm SURPRISED filtering is kinda slow
	// so I completely changed how note input works just to make it faster
	// god I need a hug. -asmadeuxs
	public function queueInputNote(note:Note):Void {
		if (!note.mustPress)
			return;
		var lane:Int = note.noteData;
		var placeInQ = inputQueue[lane];
		var i:Int = 0;
		while (i < placeInQ.length && placeInQ[i].strumTime < note.strumTime)
			i++;
		placeInQ.insert(i, note);
	}

	function removeNoteFromInputQueue(note:Note):Void {
		if (!note.mustPress)
			return;
		var lane:Int = note.noteData;
		var placeInQ = inputQueue[lane];
		var i = placeInQ.indexOf(note);
		if (i != -1)
			placeInQ.splice(i, 1);
	}

	public function keyPressed(key:Int):Void {
		var on:Bool = inputMgr != null && inputEnabled && !perfectMode;
		if (!on || key == -1 || paused || inCutscene || !generatedMusic || endingSong)
			return;

		// okay now that I'm done with this code and it works I'm genuinely SO confused
		// why the fuck was it taking 10ms before to hit a note but that DIDN'T happen in DummyPlayState
		// the fuck is in this cursed class man, I didn't rewrite it entirely because that'd be time consuming
		// but WHY was this taking 10ms max to respond, why, I don't get it. -asmadeuxs

		var lane:Int = key;
		var queue:Array<Note> = inputQueue[lane];
		var next:Note = (queue.length != 0) ? queue[0] : null;

		if (next != null && next.canBeHit) {
			queue.shift();
			goodNoteHit(next);
			playerStrums.playAnim(key, "confirm");
		} else {
			playerStrums.playAnim(key, "pressed");
			if (!Preferences.user.ghostTapping)
				noteMiss(key);
		}
	}

	public function keyReleased(key:Int):Void {
		var on:Bool = inputMgr != null && inputEnabled && !perfectMode;
		if (!on || key == -1 || paused || inCutscene || !generatedMusic || endingSong)
			return;
		playerStrums.playAnim(key, "static");
	}

	function endSong():Void {
		canPause = false;
		Conductor.current.stopMusic();
		if (!session.invalid)
			Highscore.saveScore(songName, difficulty, session.score);

		/*
			if (isStoryMode) {
				campaignScore += Math.round(session.score);
				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0) {
					Conductor.current.clearTracks();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;
					FlxG.switchState(new StoryMenuState());
					StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;
					if (!session.invalid)
						Highscore.saveWeekScore(storyWeek, campaignScore, difficulty);
					FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
					FlxG.save.flush();
				} else {
					trace('LOADING NEXT SONG');
					trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					PlayState.moonSong = Song.loadFromFile(util.Mods.currentMod, PlayState.storyPlaylist[0].toLowerCase(), difficulty);
					prevCamFollow = camFollow;

					Conductor.current.active = false;
					Conductor.current.stopMusic();
					FlxG.switchState(new gameplay.PlayState());
				}
		} else*/ {
			trace('WENT BACK TO FREEPLAY??');
			if (!FlxG.sound.music.playing) {
				FlxG.sound.playMusic(Paths.inst(PlayState.songName, PlayState.difficulty, util.Mods.currentMod), 0);
				FlxG.sound.music.time = FlxG.random.int(0, Std.int(FlxG.sound.music.length * 0.5));
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
			FlxG.switchState(new menus.FreeplayState());
		}
	}

	var endingSong:Bool = false;
	var hits:Array<Float> = [];
	var currentTimingShown:FlxText = null;
	var showRating:Bool = true;
	var showComboNumbers:Bool = true;
	var showComboSprite:Bool = false;

	public function popUpScore(daNote:Note):Void {
		if (showRating)
			popUpRating(daNote.judgement.image);
		popUpCombo(session.combo, daNote.judgement);
		var noteDiff:Float = Math.abs(Conductor.time - daNote.strumTime);
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

		var numScoreScale:Float = 0.5;
		var seperatedScore:Array<String> = Std.string(combo).split('');
		for (daLoop => i in seperatedScore) {
			var numScore:FlxSprite = new FlxSprite(0, comboSpr.y + 30).loadGraphic(Paths.image('gameplay/ui/score/num$i'));
			numScore.setGraphicSize(Std.int(numScore.width * numScoreScale));
			numScore.x = comboSpr.x + (43 * daLoop) - 50;
			numScore.updateHitbox();
			numScore.color = color;

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			if (showComboNumbers)
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

	function noteMiss(direction:Int = 1, ?daNote:Note):Void {
		if (boyfriend.stunned)
			return;

		if (daNote != null && daNote.noteScript != null) {
			var caller = daNote.noteScript.callFunc('onNoteMiss', [daNote, direction]).value;
			if (caller == ScriptLoader.STOP_FUNC)
				return;
		}
		session.score -= 10;
		if (session.combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');
		session.breakCombo();
		var missJudge = session.judgeMan.getMiss();
		if (missJudge != null) {
			health += session.judgeMan.getHealthBonus(missJudge, health);
			if (daNote != null) {
				daNote.judgement = missJudge;
				session.scoreNote(daNote);
			} else
				missJudge.hits++;
			if (Preferences.user.showMissPopups) {
				popUpRating(missJudge.image);
				popUpCombo(session.combo, missJudge);
			}
		}
		// if (daNote != null && Preferences.user.etternaMode)
		//		session.totalNotesHit += util.EtternaFunctions.wife3(Math.abs(daNote.strumTime - Conductor.time), 1.7);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		boyfriend.miss(direction, true);
		boyfriend.danceCooldown = (Conductor.semiquaver) * 0.2;
		if (currentHUD != null)
			currentHUD.updateScoreText();
	}

	function goodNoteHit(note:Note):Void {
		if (note != null && note.noteScript != null) {
			var caller = note.noteScript.callFunc('onNoteHit', [note]).value;
			if (caller == ScriptLoader.STOP_FUNC)
				return;
		}
		if (note.isMine) {
			noteMiss(note.noteData, note);
			return;
		}
		boyfriend.sing(note.noteData, true);
		boyfriend.danceCooldown = (Conductor.semiquaver) + note.sustainLength;
		note.wasGoodHit = true;
		if (!note.isSustain) {
			session.scoreNote(note);
			session.increaseCombo(1);
			health += session.judgeMan.getHealthBonus(note.judgement, health);
			if (Preferences.user.noteSplashes && note.judgement.splash)
				playerStrums.spawnSplash(note.noteData);
			notesHitArray.push(Date.now());
			popUpScore(note);
		} else
			session.totalNotesHit += 1;
		session.totalPlayed += 1;
		notes.removeNote(note);
		for (vocal in Conductor.current.tracks)
			vocal.volume = 1;
		if (currentHUD != null)
			currentHUD.updateScoreText();
	}

	override function stepHit(curStep:Int) {
		if (stage != null)
			stage.stepHit(curStep);
		if (currentHUD != null)
			currentHUD.stepHit(curStep);
	}

	override function beatHit(curBeat:Int) {
		if (camZooming && camGame.zoom < 1.35 && curBeat % 4 == 0) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (stage != null)
			stage.beatHit(curBeat);
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
