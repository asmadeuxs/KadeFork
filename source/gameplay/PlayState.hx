package gameplay;

import data.Highscore;
import data.JudgementManager.Judgement;
import data.PlaySession;
import data.hscript.Script;
import data.hscript.ScriptLoader;
import data.song.KadeForkChart;
import data.song.Song;
import data.song.SongPlaylist;
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
	public static var songName:String = "test";
	public static var difficulty:String = "";
	public static var songLength:Float = 1.0;

	public static var playlist:SongPlaylist = new SongPlaylist();

	public static var currentChart(get, never):KadeForkChart;
	public static var chartMetadata(get, never):KFCMeta;
	public static var songTitle(get, never):String;

	static function get_currentChart()
		return playlist?.getCurrent() ?? null;

	static function get_chartMetadata()
		return playlist?.getMeta() ?? null;

	static function get_songTitle()
		return chartMetadata.name ?? songName ?? 'Unknown Song';

	public static var campaignScore:Int = 0;
	public static var session:PlaySession;
	public static var nps:Int = 0;
	public static var maxNps:Int = 0;

	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOver:FlxCamera;

	public var stage:StageBG;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	public var strumlines:FlxTypedSpriteGroup<Strumline>;
	public var opponentStrums:Strumline;
	public var playerStrums:Strumline;

	public var notes:NoteRenderer;
	public var scrollSpeed:Float = 2.5;
	public var initialScrollSpeed:Float = 2.5;
	public var unspawnNotes:Array<NoteData> = [];
	public var noteSpawnIndex:Int = 0;

	public var perfectMode:Bool = false;
	public var curStage:String = '';

	public var comboDisplay:FlxSpriteGroup;
	public var camFollow:FlxObject;

	static var prevCamFollow:FlxObject;

	public var maxHealth:Float = 2.0;
	public var minHealth:Float = 0.0;

	var gameplayScripts:Array<Script> = [];

	var events:Array<ChartEventArray> = [];
	var eventPosition:Int = 0;

	var camZooming:Bool = false;
	var health(default, set):Float = 1;

	function set_health(newHealth:Float):Float
		return health = Math.min(Math.max(newHealth, minHealth), maxHealth);

	var generatedMusic:Bool = false;
	var startingSong:Bool = true;

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

	var playerVocals:FlxSound;
	var isMultiVocals:Bool = false;

	var uiDimBackground:FlxSprite;
	var inputQueue:Array<Array<Note>> = [];
	var twoPlayerMode:Bool = false;
	var inputMgr:InputManager;

	// Used for some dynamic setting changes
	var initialJudgeDiff:Int = 4;
	var currentScrollType:Int = 0;

	override public function create() {
		camGame = FlxG.camera;
		camHUD = new FlxCamera();
		camOver = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOver.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOver, false);
		transCam = camOver;

		super.create();
		current = this;
		Conductor.current.active = false;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		nps = maxNps = 0;
		if (session == null)
			session = new PlaySession();
		if (!playlist.isStory())
			session.reset();

		initialJudgeDiff = Preferences.user.judgeDifficulty;
		currentScrollType = Preferences.user.scrollType;

		inputMgr = new InputManager(keyPressed, keyReleased);
		inputQueue.resize(noteActions.length);
		holdInputs.resize(noteActions.length);
		for (i in 0...inputQueue.length) {
			inputQueue[i] = [];
			holdInputs[i] = false;
		}
		setupKeybinds();
		inputMgr.init(); // NEED to do this

		#if hxdiscord_rpc
		iconRPC = chartMetadata.opponent;
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? 'on Story Mode (Level $storyWeek)' : "in Freeplay";
		// Updating Discord Rich Presence.
		DiscordClient.changePresence('${chartMetadata.name} (${difficulty.toUpperCase()})', detailsText, iconRPC);
		#end

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

		// initialise array
		gameplayScripts = ScriptLoader.runScriptsAtDir(Paths.resolveAssetPath('scripts', util.Mods.currentMod), false);

		generateSong();

		// song specific scripts
		var songScripts:Array<Script> = ScriptLoader.runScriptsAtDir(Paths.resolveAssetPath('scripts/songs/$songName', util.Mods.currentMod));
		if (songScripts != null) {
			if (gameplayScripts == null)
				gameplayScripts = [];
			while (songScripts.length > 0)
				gameplayScripts.push(songScripts.shift());
			gameplayScripts.sort(ScriptLoader.sortByPriority);
		}
		songScripts = null;

		setVarInScripts("game", this);
		setVarInScripts("song", PlayState.songName);
		setVarInScripts("songTitle", PlayState.songTitle);
		setVarInScripts("difficulty", PlayState.difficulty);

		callFuncInScripts("preCreate");

		curStage = chartMetadata.stage;
		stage = new StageBG(curStage);
		defaultCamZoom = stage.cameraZoom;
		camGame.zoom = defaultCamZoom;
		add(stage);

		gf = new Character(0, 0, chartMetadata.metronome, METRONOME);
		dad = new Character(0, 0, chartMetadata.opponent, OPPONENT);
		boyfriend = new Character(0, 0, chartMetadata.player, PLAYER);

		positionCharacters();
		add(gf);
		add(dad);
		add(boyfriend);

		uiDimBackground = new FlxSprite().makeScaledGraphic(1, FlxG.height, 0xFF000000);

		var hudName:String = Preferences.user.hudStyle;
		if (hudName.toLowerCase() == "default")
			hudName = getFirstVarInScripts("hudOverride", Preferences.user.hudStyle);

		currentHUD = BaseHUD.loadHUD(hudName);
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

		var opponentNoteskin:String = getFirstVarInScripts("opponentNoteskin", currentChart.data.strumlines[1].skin ?? "default");
		var playerNoteskin:String = getFirstVarInScripts("playerNoteskin", currentChart.data.strumlines[0].skin ?? "default");

		opponentStrums = new Strumline(opponentNoteskin, currentChart.data.strumlines[1].keyCount ?? 4);
		playerStrums = new Strumline(playerNoteskin, currentChart.data.strumlines[0].keyCount ?? 4);
		positionStrumlines();

		strumlines.add(opponentStrums);
		strumlines.add(playerStrums);

		add(currentHUD);
		add(strumlines);
		add(notes);
		add(comboDisplay);
		add(perfectText);

		setupUnderlay();
		startSongCutscene();
		callFuncInScripts("create");
	}

	public function startSongCutscene() {
		var ret = callFirstFuncInScripts("songCutscene");
		if (ret != null && ret.value == ScriptLoader.STOP_FUNC)
			return;
		startingSong = true;
		switch (songName.toLowerCase()) {
			case _:
				startCountdown();
		}
	}

	override public function destroy() {
		if (gameplayScripts != null && gameplayScripts.length > 0) {
			for (i in gameplayScripts)
				i.callFunc("gameEnd");
			gameplayScripts.resize(0);
			gameplayScripts = null;
		}
		if (currentHUD != null)
			currentHUD.destroy();
		Conductor.current.active = false;
		Conductor.current.stopMusic();
		Conductor.current.clearTracks();
		inputMgr.destroy();
		session.judgeMan = null;
		current = null;
		super.destroy();
	}

	public function onSettingsChanged() {
		var currentSave = Preferences.user;
		if (currentSave.scrollType != currentScrollType) {
			changeScrollDirection(currentSave.scrollType);
			currentScrollType = currentSave.scrollType;
		}
		if (currentSave.judgeDifficulty != initialJudgeDiff)
			session.invalid = true;
		// else
		// session.scoreMultiplier = currentSave.judgeDifficulty;
		setupUnderlay();
		setupKeybinds();
		if (currentHUD != null)
			currentHUD.onSettingsChanged();
	}

	public function setupKeybinds() {
		for (noteData in 0...noteActions.length) {
			var action = noteActions[noteData];
			var keys:Array<FlxKey> = controls.actions[action];
			for (key in keys)
				inputMgr.remapKeyCode(key, noteData);
		}
	}

	public function setupUnderlay() {
		if (uiDimBackground == null)
			return;
		remove(uiDimBackground);
		uiDimBackground.visible = Preferences.user.strumUnderlay > 0;
		uiDimBackground.alpha = Preferences.user.strumUnderlay * 0.01;
		uiDimBackground.camera = camHUD;
		if (uiDimBackground.visible) {
			if (Preferences.user.strumUnderlayType == 0) {
				uiDimBackground.scale.x = playerStrums.width; // fill strumline region
				uiDimBackground.objectCenter(playerStrums, X); // move to last strum
				insert(members.indexOf(currentHUD), uiDimBackground);
			}
			else if (Preferences.user.strumUnderlayType == 1) {
				uiDimBackground.scale.x = FlxG.width;
				insert(members.indexOf(stage), uiDimBackground);
				uiDimBackground.screenCenter(X);
			}
			// just making sure
			uiDimBackground.y = 0;
		}
	}

	// For stage reloading
	public function positionCharacters() {
		// this looks ugly.
		if (boyfriend != null) {
			boyfriend.setPosition(770, 450);
			if (stage.characterOffsets.exists('player')) {
				var o:Array<Float> = stage.characterOffsets.get('player');
				boyfriend.x += o[0] ?? 0;
				boyfriend.y += o[1] ?? 0;
			}
		}
		if (dad != null) {
			dad.setPosition(100, 100);
			if (stage.characterOffsets.exists('opponent')) {
				var o:Array<Float> = stage.characterOffsets.get('opponent');
				dad.x += o[0] ?? 0;
				dad.y += o[1] ?? 0;
			}
		}
		if (gf != null) {
			gf.setPosition(400, 130);
			if (stage.characterOffsets.exists('metronome')) {
				var o:Array<Float> = stage.characterOffsets.get('metronome');
				gf.x += o[0] ?? 0;
				gf.y += o[1] ?? 0;
			}
		}
		// gf.scrollFactor.set(0.95, 0.95);
		if (dad != null) {
			if (gf != null && dad.characterId == gf.characterId) {
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
			}
			focusOnCharacter(dad);
		}
	}

	public function positionStrumlines() {
		opponentStrums.x = (FlxG.width - opponentStrums.width) * 0.05;
		if (Preferences.user.centerStrums)
			playerStrums.x = (FlxG.width - playerStrums.width) * 0.5;
		else
			playerStrums.x = (FlxG.width - playerStrums.width) * 0.8;
		opponentStrums.visible = !Preferences.user.centerStrums;
	}

	// For when the scroll option changes
	public function changeScrollDirection(?scrollType:Null<Int>, ?strumlineID:Null<Int>) {
		if (scrollType == null)
			scrollType = Preferences.user.scrollType;
		if (strumlineID == null) {
			for (sl in strumlines.members) {
				sl.x = 0;
				for (i in 0...sl.strums.length)
					sl.changeScrollDirection(i, scrollType);
			}
		}
		else if (strumlines.members[strumlineID] != null) {
			var sl:Strumline = strumlines.members[strumlineID];
			sl.x = 0;
			for (i in 0...sl.strums.length)
				sl.changeScrollDirection(i, scrollType);
		}
		else
			trace('Error positioning strumlines - Strumline $strumlineID not found.');
		positionStrumlines();
	}

	var startTimer:FlxTimer;
	var perfectText:FlxText;

	public function startCountdown():Void {
		inputEnabled = true;

		if (startingSong) {
			inCutscene = false;
			startedCountdown = true;
			Conductor.current.active = true;
			Conductor.setTime(-Conductor.crotchet * 7);
		}

		var scriptHUD:ScriptHUD = null;
		if (currentHUD != null && currentHUD is ScriptHUD)
			scriptHUD = cast currentHUD;

		if (scriptHUD != null)
			scriptHUD.callFunc("countdownStart");
		callFuncInScripts("countdownStart");

		var swagCounter:Int = 0;
		startTimer = new FlxTimer().start(Conductor.crotchet * 0.001, function(tmr:FlxTimer) {
			if (scriptHUD != null) {
				var hudRet = scriptHUD.callFunc("countdownTick", [swagCounter]);
				if (hudRet != null && hudRet.value == ScriptLoader.STOP_FUNC) {
					swagCounter += 1;
					return;
				}
			}
			var ret = callFirstFuncInScripts("countdownTick", [swagCounter]);
			if (ret != null && ret.value == ScriptLoader.STOP_FUNC) {
				swagCounter += 1;
				return;
			}

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

	public function startSong():Void {
		canPause = true;
		startingSong = false;
		Conductor.current.playMusic();
		Conductor.current.music.onComplete = endSong;
	}

	function generateSong():Void {
		Conductor.mapTimingPoints(currentChart);
		Conductor.current.loadMusic(Paths.inst(PlayState.songName, PlayState.difficulty, util.Mods.currentMod));

		// try to find per-player vocals
		var p1 = null;
		for (p1track in [chartMetadata.player, 'Player']) {
			p1 = Paths.songAudio('Voices-$p1track', PlayState.songName, PlayState.difficulty, util.Mods.currentMod);
			if (p1 != null)
				break;
		}
		if (p1 != null) {
			isMultiVocals = true;
			Conductor.current.addTrack(p1);
			var p2 = null;
			for (p2track in [chartMetadata.opponent, 'Opponent']) {
				p2 = Paths.songAudio('Voices-$p2track', PlayState.songName, PlayState.difficulty, util.Mods.currentMod);
				if (p2 != null)
					break;
			}
			if (p2 != null)
				Conductor.current.addTrack(p2);
		}
		if (!isMultiVocals) {
			// fallback to old system
			var voices = Paths.voices(PlayState.songName, PlayState.difficulty, util.Mods.currentMod);
			if (voices != null)
				Conductor.current.addTrack(voices);
		}
		playerVocals = Conductor.current.tracks[0];

		songLength = Conductor.current.music.length;
		scrollSpeed = currentChart.data.scrollSpeed;
		initialScrollSpeed = scrollSpeed;
		unspawnNotes.resize(0);
		var noteTypes:Array<String> = [];

		for (note in currentChart.data.notes) {
			var daStrumTime:Float = note.time;
			if (daStrumTime < 0)
				continue;
			var swagNote:NoteData = {
				time: daStrumTime,
				lane: note.lane,
				type: note.type,
				length: note.length,
				owner: note.owner
			};
			// adjust hold size in case there's a note overlapping it (so Bopeebo.)
			if (unspawnNotes.length > 0) {
				var prevNote:NoteData = unspawnNotes[unspawnNotes.length - 1];
				var prevEnd:Float = prevNote.time + prevNote.length;
				var currStart:Float = daStrumTime;
				if (prevNote.owner == swagNote.owner && prevNote.lane == swagNote.lane && prevNote.length > 0) {
					if (prevEnd > currStart)
						prevNote.length = Math.max(0, currStart - prevNote.time - 5);
				}
			}
			unspawnNotes.push(swagNote);
			if (swagNote.type != null && !noteTypes.contains(swagNote.type))
				noteTypes.push(swagNote.type);
		}
		unspawnNotes.sort(sortByShit);

		var uniqueNotes:Array<NoteData> = [];
		for (i in 0...unspawnNotes.length) {
			if (i == 0) {
				uniqueNotes.push(unspawnNotes[i]);
				continue;
			}
			var prev = uniqueNotes[uniqueNotes.length - 1];
			var curr = unspawnNotes[i];
			if (Math.abs(prev.time - curr.time) < 0.00001 && prev.lane == curr.lane && prev.owner == curr.owner)
				continue;
			uniqueNotes.push(curr);
		}
		unspawnNotes = uniqueNotes;

		events = currentChart.data.events;

		// preload scripts
		for (i in noteTypes) {
			var file:String = ScriptLoader.getScriptFile(Paths.getPath('scripts/notetypes'), i);
			if (file != null)
				ScriptLoader.findScript(file);
		}

		preloadEvents();
		noteTypes.resize(0);
		noteTypes = null;
		generatedMusic = true;
	}

	public function preloadEvents():Void {
		if (events == null || events.length == 0)
			return;
		for (idx in 0...events.length) {
			var scheduled = events[idx];
			for (event in scheduled.timeline)
				preloadEvent(event);
		}
	}

	var _charMap:Map<String, Character>;

	public function preloadEvent(event:PlaySongEvent):Void {
		if (event == null)
			return;
		switch event {
			case ChangeCharacter(who, to):
				if (_charMap == null)
					_charMap = new Map<String, Character>();
				// preloading character
				var dummyCharacter = new Character(0, 0, to);
				dummyCharacter.alpha = 0.0000001;
				dummyCharacter.scrollFactor.set();
				dummyCharacter.screenCenter(XY);
				_charMap.set(to, dummyCharacter);
				add(dummyCharacter);
			case ChangeStage(to):
				if (stage != null)
					stage.loadStage(to);
			case _:
		}
	}

	public static function sortByShit(Obj1:NoteData, Obj2:NoteData):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);

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
			Conductor.current.active = true;
			Conductor.current.playMusic();
			FlxTimer.globalManager.forEach((timer:FlxTimer) -> if (!timer.finished && !timer.active) timer.active = true);
			FlxTween.globalManager.forEach((tween:FlxTween) -> if (!tween.finished && !tween.active) tween.active = true);
			paused = false;
			#if hxdiscord_rpc
			if (startTimer.finished)
				DiscordClient.changePresence('${chartMetadata.name} (${difficulty.toUpperCase()})', detailsText, iconRPC, true, songLength - Conductor.time);
			else
				DiscordClient.changePresence('${chartMetadata.name} (${difficulty.toUpperCase()})', detailsText, iconRPC);
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

	override public function update(elapsed:Float) {
		#if debug
		if (FlxG.keys.justPressed.ONE) {
			session.invalid = true;
			endSong();
		}
		if (startedCountdown) {
			if (FlxG.keys.justPressed.FIVE && canPause) {
				pause();
				openSubState(new ui.DeveloperMenu());
			}
			if (FlxG.keys.justPressed.SEVEN)
				FlxG.switchState(new editor.ChartEditor());
			if (FlxG.keys.justPressed.EIGHT) {
				Paths.skipNextClear = true;
				var ids = [boyfriend.characterId, dad.characterId];
				if (gf != null && gf.visible && gf.characterId != 'placeholder')
					ids.push(gf.characterId);
				var name:String = Type.getClassName(Type.getClass(this));
				FlxG.switchState(new editor.CharacterEditor(name, ids, curStage));
			}
		}
		#end
		if (FlxG.keys.justPressed.F6) {
			session.invalid = true;
			perfectMode = !perfectMode;
			perfectText.visible = perfectMode;
		}

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

		var ret = callFirstFuncInScripts("preUpdate", [elapsed]);
		if (ret != null && ret.value == ScriptLoader.STOP_FUNC)
			return;

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause) {
			pause();
			Conductor.current.stopMusic();
			#if hxdiscord_rpc
			DiscordClient.changePresence('${chartMetadata.name} (${difficulty.toUpperCase()})', 'Paused $detailsText', iconRPC);
			#end
			util.StateOverride.openSubState("menus.PauseSubstate", [boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y]);
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
			callFuncInScripts("playerDeath", []);
			openSubState(new gameplay.GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			#if hxdiscord_rpc
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence('${chartMetadata.name} (${difficulty.toUpperCase()})', 'Game Over!', iconRPC);
			#end
			return;
		}

		if (generatedMusic) {
			updateEvents(Conductor.time);
			var actualSpeed:Float = NoteRenderer.getScrollSpeedMod(scrollSpeed);
			notes.updateNotes(Conductor.time, strumlines.members, actualSpeed);
			noteUpdate(Conductor.time, elapsed);
			callFuncInScripts("update song", [elapsed]);
		}
	}

	public function updateEvents(time:Float):Void {
		if (events == null || events.length == 0)
			return;
		var scheduled = events[eventPosition];
		if (scheduled.time - time > 10)
			return;
		if (scheduled == null) {
			eventPosition++;
			return;
		}
		for (event in scheduled.timeline)
			processEvent(event);
		eventPosition++;
	}

	public function processEvent(event:PlaySongEvent):Void {
		if (event == null)
			return;
		// TODO: add the rest of the events
		switch event {
			case FocusCamera(on):
				focusOnCharacter(switch on {
					case 2: gf;
					case 1: boyfriend;
					case _: dad;
				});
			case ChangeNoteVelocity(speed, strumline):
				if (strumline == null || strumline > strumlines.members.length - 1) {
					if (strumline != null)
						trace('(ChangeNoteVelocity) Strumline $strumline not found, changing speed for both strumlines');
					scrollSpeed = speed;
				}
				else
					strumlines.members[strumline].scrollSpeed = speed;
			case ChangeNoteScrollType(scrollType, strumline):
				changeScrollDirection(scrollType, strumline);
			case ChangeCharacter(who, to):
				switch who {
					case 0: boyfriend.loadCharacter(to);
					case 1: dad.loadCharacter(to);
					case 2: gf.loadCharacter(to);
					case _:
				}
				if (_charMap.exists(to)) {
					_charMap.get(to).destroy();
					remove(_charMap.get(to));
					_charMap.remove(to);
				}
			case ChangeStage(to):
				if (stage != null) {
					stage.clear();
					stage.stageFile = to;
					positionCharacters();
					curStage = to;
				}
			case _:
		}
	}

	function noteUpdate(time:Float, elapsed:Float):Void {
		for (daNote in notes.getActiveNotes()) {
			var noteKill:Bool = false;

			// Auto‑hit notes when perfectMode is on (or opponent notes)
			if (!daNote.mustPress || (daNote.mustPress && perfectMode)) {
				if (daNote.strumTime <= Conductor.time && !daNote.isFake) {
					noteKill = false;
					if (daNote.mustPress && !daNote.wasGoodHit)
						goodNoteHit(daNote);
					else if (!daNote.mustPress) {
						opponentNoteHit(daNote);
						noteKill = !daNote.isSustain;
						if (daNote.isSustain) {
							daNote.isLocked = true;
							daNote.sustainProgress -= elapsed * 1000.0;
							if (daNote.sustainProgress <= 0)
								noteKill = true;
						}
					}
				}
			}

			// Handle active hold notes (works for perfectMode as well)
			if (daNote.mustPress && daNote.wasGoodHit && daNote.isSustain) {
				var isHolding:Bool = perfectMode || holdInputs[daNote.noteData];
				if (isHolding) {
					if (daNote.holdReleased) { // not resetting the timer here, you had your chance
						daNote.holdReleased = false;
						daNote.alpha = daNote.baseHoldAlpha;
					}
					daNote.sustainProgress -= elapsed * 1000.0;
					if (daNote.sustainProgress <= 0) {
						daNote.strumline.playAnim(daNote.noteData, "pressed");
						noteKill = true;
					}
					else {
						var sustainScroll:Float = NoteRenderer.getScrollSpeedMod(scrollSpeed);
						var curStrum = daNote.strumline.getStrum(daNote.noteData);
						if (Preferences.user.scrollSpeedType < 2) {
							var slScrollSpeed:Null<Float> = daNote.strumline.getScrollSpeed(daNote.noteData);
							if (slScrollSpeed != null && Math.abs(sustainScroll - slScrollSpeed) > 0.00000001)
								sustainScroll = slScrollSpeed;
						}
						daNote.updateSustain(time, scrollSpeed);
					}
				}
				else {
					// not holding, miss if you didn't hold it for too long
					var grace:Float = daNote.holdGracePeriod;
					if (!daNote.holdReleased) {
						daNote.holdReleased = true;
						daNote.holdTimer = grace;
					}
					daNote.holdTimer -= elapsed;
					daNote.alpha = Math.max(0, daNote.holdTimer / grace);
					if (daNote.holdTimer <= 0) {
						noteMiss(daNote.noteData, daNote);
						daNote.missed = true;
						noteKill = true;
					}
				}
			}
			else if (daNote.mustPress && !daNote.wasGoodHit && !daNote.missed) {
				// normal note miss
				var missLimit:Int = 150;
				var safeZone:Float = session.judgeMan.maxHitWindow ?? 180.0;
				if (daNote.strumTime < Conductor.time - safeZone)
					daNote.tooLate = true;
				if (daNote.strumTime - Conductor.time < -(missLimit + daNote.sustainLength)) {
					noteMiss(daNote.noteData, daNote);
					daNote.missed = true;
					noteKill = true;
				}
			}

			if (noteKill) {
				if (daNote.missed && playerVocals != null)
					playerVocals.volume = 0;
				notes.removeNote(daNote);
			}
		}
	}

	function opponentNoteHit(note:Note) {
		if (!note.wasGoodHit)
			note.wasGoodHit = true;
		var altAnim:String = "";
		// if (curSection != null && curSection.altAnim)
		//	altAnim = '-alt';
		dad.sing(note.noteData, altAnim, true);
		dad.danceCooldown = dad.singDuration + note.sustainLength;
		callFuncInScripts("opponentNoteHit", [note]);
		if (playerVocals != null && !isMultiVocals)
			playerVocals.volume = 1;
	}

	function queueInputNote(note:Note):Void {
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

		var lane:Int = key;
		var queue:Array<Note> = inputQueue[lane];
		var next:Note = (queue.length != 0) ? queue[0] : null;
		holdInputs[lane] = true;

		if (next != null && next.canBeHit) {
			queue.shift();
			if (next.isSustain)
				next.holdTimer = 1.0;
			goodNoteHit(next);
			playerStrums.playAnim(key, "confirm");
		}
		else {
			// in case you're regrabbing a hold
			var sustainNote:Note = null;
			for (note in notes.getActiveNotes()) {
				if (note.mustPress && note.isSustain && note.wasGoodHit && !note.missed && note.noteData == lane) {
					sustainNote = note;
					break;
				}
			}
			if (sustainNote != null) {
				sustainNote.holdTimer = 0;
				sustainNote.holdReleased = false;
				playerStrums.playAnim(key, "confirm");
			}
			else {
				playerStrums.playAnim(key, "pressed");
				if (!Preferences.user.ghostTapping)
					noteMiss(lane);
			}
		}
	}

	public function keyReleased(key:Int):Void {
		var on:Bool = inputMgr != null && inputEnabled && !perfectMode;
		if (!on || key == -1 || paused || inCutscene || !generatedMusic || endingSong)
			return;
		holdInputs[key] = false;
		playerStrums.playAnim(key, "static");
	}

	public function endSong():Void {
		var ret = callFirstFuncInScripts("songEnd");
		if (ret != null && ret.value == ScriptLoader.STOP_FUNC)
			return;

		canPause = false;
		Conductor.current.stopMusic();
		if (!session.invalid)
			Highscore.saveScore(songName, difficulty, session.score);

		Paths.skipNextClear = true;
		function goBackToFreeplay() {
			trace('WENT BACK TO FREEPLAY??');
			if (!FlxG.sound.music.playing) {
				FlxG.sound.playMusic(Paths.inst(PlayState.songName, PlayState.difficulty, util.Mods.currentMod), 0);
				FlxG.sound.music.time = FlxG.random.int(0, Std.int(FlxG.sound.music.length * 0.5));
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
			playlist.clear();
			util.StateOverride.switchState("menus.FreeplayState");
		}

		if (playlist == null) {
			goBackToFreeplay();
			return;
		}

		if (playlist.getNext() != null) {
			playlist.next();
			playlist.updateSong();
			// campaignScore += Math.round(session.score);
			Conductor.current.active = false;
			Conductor.current.stopMusic();
			trace('LOADING NEXT SONG ($songTitle)');
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			prevCamFollow = camFollow;
			FlxG.switchState(new gameplay.PlayState());
		}
		/*else if (playlist.isStory()) {
			Conductor.current.clearTracks();
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;
			util.StateOverride.switchState("menus.StoryMenuState");
			StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;
			if (!session.invalid)
				Highscore.saveWeekScore(storyWeek, campaignScore, difficulty);
			FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
			FlxG.save.flush();
		}*/
		else
			goBackToFreeplay();
	}

	var endingSong:Bool = false;
	var hits:Array<Float> = [];
	var currentTimingShown:FlxText = null;

	var showRating:Bool = true;
	var showComboNumbers:Bool = true;
	var showComboSprite:Bool = false;

	public function popUpScore(daNote:Note):Void {
		var scriptHUD:ScriptHUD = null;
		if (currentHUD != null && currentHUD is ScriptHUD) {
			scriptHUD = cast currentHUD;
			var ret = scriptHUD.callFunc("popUpScore", [daNote]);
			if (ret != null && ret.value == ScriptLoader.STOP_FUNC)
				return;
		}
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

	public function noteMiss(direction:Int = 1, ?daNote:Note):Void {
		if (daNote != null && daNote.noteScript != null) {
			var caller = daNote.noteScript.callFunc('onNoteMiss', [daNote, direction]).value;
			if (caller == ScriptLoader.STOP_FUNC)
				return;
		}
		session.score -= 10;
		if (session.combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');
		session.breakCombo();

		callFuncInScripts("noteMiss", [direction, daNote]);

		var missJudge = session.judgeMan.getMiss();
		if (missJudge != null) {
			health += session.judgeMan.getHealthBonus(missJudge, health);
			if (daNote != null) {
				daNote.judgement = missJudge;
				session.scoreNote(daNote);
			}
			else
				missJudge.hits++;
			if (Preferences.user.showMissPopups) {
				popUpRating(missJudge.image);
				popUpCombo(session.combo, missJudge);
			}
		}

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		boyfriend.miss(direction, true);
		boyfriend.danceCooldown = 1.0;
		if (currentHUD != null)
			currentHUD.updateScoreText();
	}

	var notesHitArray:Array<Date> = [];
	var tilNpsUpdate:Float = 1;

	public function goodNoteHit(note:Note):Void {
		if (note != null && note.noteScript != null) {
			var caller = note.noteScript.callFunc('onNoteHit', [note]).value;
			if (caller == ScriptLoader.STOP_FUNC)
				return;
		}

		if (note.isMine) {
			noteMiss(note.noteData, note);
			return;
		}

		callFuncInScripts("goodNoteHit", [note]);

		boyfriend.sing(note.noteData, null, true);
		boyfriend.danceCooldown = boyfriend.singDuration + note.sustainLength;
		note.wasGoodHit = true;
		function scoreNote() {
			session.scoreNote(note);
			session.increaseCombo(1);
			health += session.judgeMan.getHealthBonus(note.judgement, health);
			if (Preferences.user.noteSplashes && note.judgement.splash)
				playerStrums.spawnSplash(note.noteData);
			notesHitArray.push(Date.now());
			session.totalPlayed += 1;
			popUpScore(note);
		}
		if (!note.isSustain) {
			scoreNote();
			notes.removeNote(note);
		}
		else {
			note.isLocked = true;
			note.holdReleased = false;
			note.sustainProgress = note.sustainLength;
			note.holdTimer = 0.0;
			scoreNote();
			// edge case just so holds hit too late shrimk properly
			var lateThreshold:Float = 50.0;
			if (note.hitDifference > lateThreshold) {
				var maxWindow:Float = session.judgeMan.maxHitWindow ?? 180.0;
				var lateAmount:Float = Math.min(note.hitDifference, maxWindow);
				var shrinkFactor:Float = 1.0 - (lateAmount - lateThreshold) / (maxWindow - lateThreshold);
				shrinkFactor = Math.max(0.2, shrinkFactor);
				note.sustainProgress *= shrinkFactor;
			}
		}
		if (playerVocals != null)
			playerVocals.volume = 1;
		if (currentHUD != null)
			currentHUD.updateScoreText();
	}

	override function stepHit(curStep:Int) {
		if (stage != null)
			stage.stepHit(curStep);
		if (currentHUD != null)
			currentHUD.stepHit(curStep);
		callFuncInScripts("stepHit", [curStep]);
	}

	public var cameraBumpFrequency:Int = 4;
	public var hudBumpFrequency:Int = 4;

	override function beatHit(curBeat:Int) {
		if (camZooming && camGame.zoom < 1.35 && curBeat % cameraBumpFrequency == 0)
			camGame.zoom += 0.015;
		if (camZooming && camHUD.zoom < 1.35 && curBeat % hudBumpFrequency == 0)
			camHUD.zoom += 0.03;

		if (stage != null)
			stage.beatHit(curBeat);
		if (currentHUD != null)
			currentHUD.beatHit(curBeat);

		callFuncInScripts("beatHit", [curBeat]);
	}

	public function focusOnCharacter(nextChar:Character):Void {
		if (!generatedMusic)
			return;
		var mid = nextChar.getMidpoint();
		var off = nextChar.cameraOffset;
		camFollow.setPosition(mid.x + off.x, mid.y + off.y);
		// do not remove this line its funny as fuck PLEASEEEEE don't remove it lmao -asmadeuxs
		// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);
	}

	public function setVarInScripts(varName:String, value:Dynamic):Void {
		if (gameplayScripts == null || gameplayScripts.length == 0)
			return;
		for (script in gameplayScripts)
			if (script != null)
				script.setVar(varName, value);
	}

	public function callFuncInScripts(funcName:String, ?args:Array<Dynamic>):Map<String, HScriptFunction> {
		if (gameplayScripts == null || gameplayScripts.length == 0)
			return null;
		var results:Map<String, HScriptFunction> = new Map<String, HScriptFunction>();
		for (script in gameplayScripts) {
			if (!ScriptLoader.isValid(script)) {
				gameplayScripts.remove(script);
				continue;
			}
			var result = script.callFunc(funcName, args);
			if (result != null)
				results.set(script.fileName, result);
		}
		return results;
	}

	public function getFirstVarInScripts(varName:String, ?defaultValue:Dynamic = null):Dynamic {
		if (gameplayScripts == null || gameplayScripts.length == 0)
			return defaultValue;
		for (script in gameplayScripts) {
			if (!ScriptLoader.isValid(script)) {
				gameplayScripts.remove(script);
				continue;
			}
			return script.getVar(varName);
		}
		return defaultValue;
	}

	public function callFirstFuncInScripts(funcName:String, ?args:Array<Dynamic>):Null<HScriptFunction> {
		if (gameplayScripts == null || gameplayScripts.length == 0)
			return null;
		for (script in gameplayScripts) {
			if (!ScriptLoader.isValid(script)) {
				gameplayScripts.remove(script);
				continue;
			}
			var result = script.callFunc(funcName, args);
			if (result != null)
				return result;
		}
		return null;
	}
}
