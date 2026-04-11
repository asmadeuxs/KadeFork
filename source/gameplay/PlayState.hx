package gameplay;

import data.Highscore;
import data.JudgementData;
import data.song.Section;
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
import gameplay.Note.NoteData;
import gameplay.Strumline;
import gameplay.hud.*;
import menus.StoryMenuState;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import ui.HealthIcon;

using util.CoolUtil;
using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end
#if sys
import sys.FileSystem;
#end

typedef PlaySession = {
	story:Bool,
	difficulty:String,
	levelName:String,
}

class PlayState extends MusicBeatState {
	public static var current:PlayState;

	// level info
	public static var SONG:SwagSong;
	public static var curStage:String = '';
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];

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
	public static var difficultyName:String = "";

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
	public var unspawnNotes:Array<NoteData> = [];
	public var noteSpawnIndex:Int = 0;

	public var strumlines:FlxTypedSpriteGroup<Strumline>;
	public var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;
	public static var songLength:Float = 1.0;

	public var opponentStrums:Strumline;
	public var playerStrums:Strumline;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health(default, set):Float = 1;

	function set_health(newHealth:Float):Float
		return health = Math.min(Math.max(newHealth, 0), 2);

	// Score shit | TODO: move this to a class so we can save and load
	// probably after highscore rewrite -asmadeuxs
	public static var songScore:Int = 0;

	// keeping this variable around just for compatibility sake
	public static var misses(get, never):Int;

	static function get_misses():Int
		return judgementData.getMiss().hits ?? 0;

	public static var comboBreaks:Int = 0;
	public static var combo:Int = 0;

	public static var nps:Int = 0;
	public static var maxNps:Int = 0;

	public static var accuracy:Float = 0.00;
	public static var totalNotesHit:Float = 0;
	public static var totalPlayed:Int = 0;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	public var comboDisplay:FlxSpriteGroup;

	var notesHitArray:Array<Date> = [];
	var currentFrames:Int = 0;

	var currentHUD:BaseHUD;

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;
	var inCutscene:Bool = false;

	// Will decide if she's even allowed to headbang at all depending on the song
	private var allowedToHeadbang:Bool = false;

	// Per song additive offset
	public static var songOffset:Float = 0;

	public function new():Void {
		super();
	}

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
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		resetScoring();
		judgementData = new JudgementData();

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
		DiscordClient.changePresence(detailsText + ' ${SONG.song} ($difficultyName)' iconRPC);
		#end

		camGame = FlxG.camera;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camHUD.antialiasing = true;
		FlxG.cameras.add(camHUD, false);

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

		var underlay:FlxSprite = null;
		if (Preferences.user.strumUnderlay > 0) { // always creating it if its supposed to be visible for the sake adding it for both cases.
			var width:Int = Preferences.user.strumUnderlayType == 1 ? FlxG.width : 1;
			underlay = new FlxSprite().makeScaledGraphic(width, FlxG.height, 0xFF000000);
			underlay.camera = camHUD; // always on camHUD so it renders properly
			underlay.alpha = Preferences.user.strumUnderlay * 0.01;
			if (Preferences.user.strumUnderlayType == 1)
				add(underlay);
		}

		currentHUD = new Kade(); // switch? SONG.hudStyle? a script? idfk. replace later -asmadeuxs
		comboDisplay = new FlxSpriteGroup();
		strumlines = new FlxTypedSpriteGroup(0, 0);
		notes = new FlxTypedGroup<Note>();

		var cacheNotes:Int = 16;
		for (_ in 0...cacheNotes)
			notes.add(new Note());

		currentHUD.camera = camHUD;
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

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		camGame.follow(camFollow, LOCKON, 0.04 * (60 / Preferences.user.frameRate));
		// camGame.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.zoom = defaultCamZoom;
		camGame.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;

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
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[0]));
					ready.scrollFactor.set();
					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						onComplete: function(twn:FlxTween) ready.destroy(),
						ease: FlxEase.cubeInOut
					});
				case 2:
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[1]));
					set.scrollFactor.set();
					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						onComplete: function(twn:FlxTween) set.destroy(),
						ease: FlxEase.cubeInOut
					});
				case 3:
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introPath + introAlts[2]));
					go.scrollFactor.set();
					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						onComplete: function(twn:FlxTween) go.destroy(),
						ease: FlxEase.cubeInOut
					});
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
		DiscordClient.changePresence(detailsText + ' ${SONG.song} ($difficultyName)\n${scoreTxt.text}' iconRPC);
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
		/*#if desktop
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
			#end */

		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0] /*+ Prefences.user.noteOffset*/ + songOffset;
				if (daStrumTime < 0)
					continue;
				var oldNote:NoteData = null;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;
				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;
				var owner:Int = gottaHitNote ? 1 : 0;

				// delete duplicates
				if (oldNote != null)
					if (Math.abs(oldNote.strumTime - daStrumTime) < 0.00001 && oldNote.noteData == daNoteData && oldNote.noteOwner == owner)
						continue;
				var swagNote:NoteData = {
					strumTime: daStrumTime,
					noteData: daNoteData,
					sustainLength: songNotes[2],
					noteOwner: owner
				};
				// swagNote.sustainLength = songNotes[2];
				// swagNote.mustPress = gottaHitNote;
				unspawnNotes.push(swagNote);

				/*var susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
					for (susNote in 0...Math.floor(susLength)) {
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						unspawnNotes.push(sustainNote);
				}*/
			}
		}
		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	function sortByShit(Obj1:NoteData, Obj2:NoteData):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function tweenCamIn():Void
		FlxTween.tween(camGame, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});

	override function openSubState(SubState:flixel.FlxSubState) {
		if (paused) {
			if (inst != null) {
				inst.pause();
				vocals.pause();
			}

			#if discord_rpc
			DiscordClient.changePresence('PAUSED on ${SONG.song} ($difficultyName)', iconRPC);
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
				DiscordClient.changePresence(detailsText + '${SONG.song} ($difficultyName)', iconRPC, true, songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, '${SONG.song} ($difficultyName)', iconRPC);
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

	override public function update(elapsed:Float) { // debug keys
		#if debug
		if (FlxG.keys.justPressed.ONE) {
			invalidSession = true;
			endSong();
		}
		if (FlxG.keys.justPressed.F6) {
			invalidSession = true;
			perfectMode = true;
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
			if (nps > maxNps)
				maxNps = nps;
			currentFrames = 0;
		} else
			currentFrames++;

		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			if (FlxG.random.bool(0.1))
				FlxG.switchState(new menus.GitarooPause());
			else
				openSubState(new menus.PauseSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (startingSong) {
			if (startedCountdown) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		} else {
			Conductor.songPosition += FlxG.elapsed * 1000;
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

		var curMeasure:Int = Std.int(curStep / 16);
		if (generatedMusic && PlayState.SONG.notes[curMeasure] != null) {
			var mustHitSec:Bool = PlayState.SONG.notes[curMeasure].mustHitSection;
			var nextChar:Character = mustHitSec ? boyfriend : dad;
			var mid = nextChar.getMidpoint();
			var off = nextChar.cameraOffset;
			camFollow.setPosition(mid.x + off.x, mid.y + off.y);
			// do not remove this line its funny as fuck PLEASEEEEE don't remove it lmao -asmadeuxs
			// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

			if (SONG.song.toLowerCase() == 'tutorial')
				FlxTween.tween(camGame, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
		}

		if (camZooming) {
			camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

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
			DiscordClient.changePresence("GAME OVER -- " + '${SONG.song} ($difficultyName)', iconRPC);
			#end
		}

		var nextNote:NoteData = unspawnNotes[noteSpawnIndex];
		if (nextNote != null) {
			var strumline:Strumline = strumlines.members[nextNote.noteOwner];
			if (nextNote.strumTime - Conductor.songPosition < 1500) {
				var oldNote:Note = notes.members.length > 1 ? notes.members[notes.members.length - 1] : null;
				if (strumline != null) {
					// spawn the note if the strumline is there for it
					var swagNote:Note = notes.recycle(Note).setup(nextNote.strumTime, nextNote.noteData, nextNote.sustainLength, oldNote);
					strumline.noteskin.generateArrow(nextNote.noteData, swagNote);
					swagNote.mustPress = strumline == playerStrums;
					// notes.add(unspawnNotes[noteSpawnIndex]);
				}
				noteSpawnIndex++;
			}
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
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";
					if (SONG.notes[curMeasure] != null && SONG.notes[Math.floor(curStep / 16)].altAnim)
						altAnim = '-alt';
					dad.sing(daNote.noteData, altAnim, true);
					dad.danceCooldown = (Conductor.stepCrochet) + daNote.sustainLength;
					if (SONG.needsVoices)
						vocals.volume = 1;
					daNote.active = false;
					daNote.kill();
				}

				var downscroll:Bool = Preferences.user.scrollType == 1;
				var difference:Float = (Conductor.songPosition - daNote.strumTime);
				var scrollSpeed:Float = FlxMath.roundDecimal(Preferences.user.scrollSpeed == 1 ? SONG.speed : Preferences.user.scrollSpeed, 2);
				var noteScroll:Float = difference * ((0.45 * scrollSpeed) * (downscroll ? -1 : 1));

				var noteData:Int = Math.floor(Math.abs(daNote.noteData));
				if (daNote.mustPress) {
					var curStrum = playerStrums.getStrum(noteData);
					daNote.y = curStrum.y - noteScroll;
					daNote.visible = curStrum.visible;
					if (!daNote.isSustainNote)
						daNote.angle = curStrum.angle;
					daNote.alpha = curStrum.alpha;
					daNote.x = curStrum.x;
				} else if (!daNote.wasGoodHit) {
					var curStrum = opponentStrums.getStrum(noteData);
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
					if (!daNote.missed && daNote.strumTime - Conductor.songPosition < -(150 + daNote.sustainLength)) {
						health -= 0.075;
						vocals.volume = 0;
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
		vocals.volume = 0;
		inst.volume = 0;
		if (!invalidSession)
			Highscore.saveScore(SONG.song, Math.round(songScore), difficultyName);

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
					Highscore.saveWeekScore(storyWeek, campaignScore, difficultyName);
				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			} else {
				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficultyName);
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficultyName, PlayState.storyPlaylist[0]);
				prevCamFollow = camFollow;
				inst.stop();

				FlxG.switchState(new gameplay.PlayState());
			}
		} else {
			trace('WENT BACK TO FREEPLAY??');
			if (!FlxG.sound.music.playing) {
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0);
				FlxG.sound.music.time = FlxG.random.int(0, Std.int(FlxG.sound.music.length / 2));
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
			startDelay: Conductor.crochet * 0.001
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
				startDelay: Conductor.crochet * 0.002
			});
		}
		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: (tween:FlxTween) -> comboSpr.destroy(),
			startDelay: Conductor.crochet * 0.001
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
			startDelay: Conductor.crochet * 0.001,
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
		var tooMany:Bool = key < 0 || key > noteActions.length - 1;
		if (perfectMode || tooMany || paused || inCutscene || !generatedMusic || endingSong || boyfriend.stunned)
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
			comboBreaks++;
			if (combo > 0)
				combo = 0;
			else
				combo--;
			var missJudge = judgementData.getMiss();
			missJudge.hits++;
			popUpRating(missJudge.image);
			popUpCombo(combo, missJudge);

			if (daNote != null) {
				var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
				if (Preferences.user.etternaMode)
					totalNotesHit += util.EtternaFunctions.wife3(noteDiff, 1.7);
			}
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			boyfriend.miss(direction, true);
			boyfriend.danceCooldown = (Conductor.stepCrochet) * 0.2;
			updateAccuracy();
			if (currentHUD != null)
				currentHUD.updateScoreText();
		}
	}

	function updateAccuracy() {
		totalPlayed += 1;
		accuracy = Math.max(0, totalNotesHit / totalPlayed * 100);
	}

	function goodNoteHit(note:Note):Void {
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		note.judgement = judgementData.judgeTime(noteDiff);

		if (!note.isSustainNote)
			notesHitArray.push(Date.now());

		if (!note.wasGoodHit) {
			if (!note.isSustainNote) {
				scoreNote(note);
				popUpScore(note);
				if (Preferences.user.noteSplashes && note.judgement.splash)
					playerStrums.spawnSplash(note.noteData);
				combo += 1;
			} else
				totalNotesHit += 1;

			boyfriend.sing(note.noteData, true);
			boyfriend.danceCooldown = (Conductor.stepCrochet) + note.sustainLength;
			note.wasGoodHit = true;
			vocals.volume = 1;
			note.kill();
			updateAccuracy();
			if (currentHUD != null)
				currentHUD.updateScoreText();
		}
	}

	private function scoreNote(daNote:Note):Void {
		var score:Float = daNote.judgement.score;
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		if (Preferences.user.etternaMode)
			totalNotesHit += util.EtternaFunctions.wife3(noteDiff, Conductor.timeScale);
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
		DiscordClient.changePresence(detailsText + ' ${SONG.song} ($difficultyName) ${scoreTxt.text}', iconRPC, true, songLength - Conductor.songPosition);
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

		if (currentHUD != null)
			currentHUD.beatHit(curBeat);
		characterDance(curBeat);

		switch curSong {
			case 'Tutorial':
				if (curBeat % 16 == 15 && dad.characterId == 'gf' && curBeat > 16 && curBeat < 48) {
					boyfriend.playAnim('hey', true);
					dad.playAnim('cheer', true);
				}
			case 'Bopeebo':
				if (curBeat % 8 == 7)
					boyfriend.playAnim('hey', true);
				if (curBeat > 5 && curBeat < 130 && curBeat % 8 == 7)
					gf.playAnim('cheer');
			case 'Fresh':
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

	function characterDance(beat:Int) {
		if (curBeat % dad.beatsToDance == 0)
			dad.dance();
		if (curBeat % Math.floor(gf.beatsToDance * gfSpeed) == 0)
			gf.dance();
		if (!boyfriend.isSinging() && curBeat % boyfriend.beatsToDance == 0)
			boyfriend.dance();
	}
}
