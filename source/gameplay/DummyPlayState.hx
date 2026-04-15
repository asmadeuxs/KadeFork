package gameplay;

import data.song.KadeForkChart;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import gameplay.Note;
import moonchart.formats.BasicFormat;
import openfl.events.KeyboardEvent;

class DummyPlayState extends MusicBeatState {
	var chart(default, set):KadeForkChart;
	var chartMeta:BasicMetaData;

	function set_chart(to:KadeForkChart) {
		chartMeta = to.getChartMeta();
		return chart = to;
	}

	var strumlines:FlxTypedSpriteGroup<Strumline>;
	var notes:FlxTypedGroup<Note>;
	var opponentStrums:Strumline;
	var playerStrums:Strumline;

	var scrollSpeed:Float = 1.0;
	var generatedMusic:Bool = false;
	var perfectMode:Bool = false;

	var unspawnNotes:Array<NoteData> = [];
	var noteSpawnIndex:Int = 0;

	var songName:String = "test";

	override function create() {
		super.create();

		var path = Paths.getPath('songs/$songName/$songName.kfc');
		chart = new KadeForkChart().fromFile(path, null, "normal");

		var chartStrumlines = chart.getStrumlines();
		trace('Chart has ${chartStrumlines.length} strumlines.');
		for (i in 0...chartStrumlines.length)
			trace('Strumline $i has ${chartStrumlines[i].notes.length} notes.');

		strumlines = new FlxTypedSpriteGroup();
		notes = new FlxTypedGroup<Note>();

		var cacheNotes:Int = 16;
		for (_ in 0...cacheNotes) {
			var note = new Note();
			notes.add(note);
			note.kill();
		}

		add(strumlines);
		add(notes);

		var strumY:Float = 30;
		if (Preferences.user.scrollType == 1)
			strumY = FlxG.height - 185;
		opponentStrums = new Strumline(0, strumY);
		playerStrums = new Strumline(0, strumY);

		opponentStrums.x = (FlxG.width - opponentStrums.width) * 0.05;
		playerStrums.x = (FlxG.width - playerStrums.width) * 0.8;
		strumlines.add(opponentStrums);
		strumlines.add(playerStrums);

		generateSong();

		Conductor.setTime(-Conductor.crotchet * 6.7);
	}

	private function generateSong():Void {
		Conductor.timingPoints = [
			for (bpm in chartMeta.bpmChanges) {
				{
					time: bpm.time,
					bpm: bpm.bpm,
					denominator: bpm.stepsPerBeat ?? 4,
					numerator: bpm.beatsPerMeasure ?? 4
				}
			}
		];
		Conductor.current.loadMusic(Paths.inst(songName));
		Conductor.current.addTrack(Paths.voices(songName));

		Conductor.bpm = chart.data.bpmChanges[0].bpm;
		scrollSpeed = chart.data.velocityChanges[0].speed;

		for (note in chart.getNotes()) {
			var strumTime:Float = note.time /*+ Prefences.user.noteOffset*/;
			var noteLane:Int = note.lane;
			if (strumTime < 0)
				continue;
			var oldNote:NoteData = null;
			if (unspawnNotes.length > 0)
				oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

			//final keyCount = chartMeta.extraData.get("STRUMS_LENGTH")[0] ?? 4;
			final owner:Int = Std.int(noteLane / 4);
			final lane = Std.int(noteLane % 4);
			if (oldNote != null)
				if (Math.abs(oldNote.time - strumTime) < 0.00001 && oldNote.lane == lane && oldNote.owner == owner)
					continue;
			unspawnNotes.push({
				time: strumTime,
				lane: lane,
				type: note.type,
				length: note.length,
				owner: owner
			});
		}
		unspawnNotes.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));
		generatedMusic = true;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyShit);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, keyUnshit);
	}

	override function destroy() {
		Conductor.current.active = false;
		Conductor.current.stopMusic();
		Conductor.current.clearTracks();
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUnshit);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyShit);
	}

	var starting:Bool = true;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (starting && Conductor.songPosition >= 0) {
			starting = true;
			Conductor.current.playMusic();
		}

		while (noteSpawnIndex < unspawnNotes.length) {
			var nextNote:NoteData = unspawnNotes[noteSpawnIndex];
			if (nextNote.time - Conductor.songPosition > 1500)
				break;
			var strumline:Strumline = strumlines.members[nextNote.owner];
			if (strumline != null) {
				var oldNote:Note = (notes.members.length > 1) ? notes.members[notes.members.length - 1] : null;
				var swagNote:Note = notes.recycle(Note).setup(nextNote.time, nextNote.lane, nextNote.length, oldNote);
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

				var downscroll:Bool = Preferences.user.scrollType == 1;
				var difference:Float = (Conductor.songPosition - daNote.strumTime);
				var scrollSpeed:Float = FlxMath.roundDecimal(Preferences.user.scrollSpeed == 1 ? scrollSpeed : Preferences.user.scrollSpeed, 2);
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
				var autoHit:Bool = !daNote.mustPress || (daNote.mustPress && perfectMode);
				if (autoHit) {
					if (daNote.strumTime <= Conductor.songPosition && !daNote.isFake) {
						daNote.wasGoodHit = true;
						noteKill = true;
					}
				} else if (daNote.mustPress) {
					var safeZone:Float = 180.0;
					if (daNote.strumTime < Conductor.songPosition - safeZone)
						daNote.tooLate = true;
					if (!daNote.missed && daNote.strumTime - Conductor.songPosition < -(150 + daNote.sustainLength)) {
						for (vocal in Conductor.current.tracks)
							vocal.volume = 0;
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

	public var holdInputs:Array<Bool> = [false, false, false, false];

	public function keyShit(event:KeyboardEvent):Void {
		var key:Int = gameplay.PlayState.getStrumFromKey(event.keyCode);
		if (perfectMode || key == -1)
			return;

		var strum = playerStrums.members[key];
		var gottaHits:Array<Note> = notes.members.filter(function(nt:Note):Bool return nt != null && nt.canBeHit && !nt.isSustainNote && nt.noteData == key);
		gottaHits.sort(function(a:Note, b:Note):Int return Std.int(a.strumTime - b.strumTime));
		holdInputs[key] = true;

		if (gottaHits.length != 0) {
			gottaHits[0].wasGoodHit = true;
			playerStrums.playAnim(key, "confirm");
		} else
			playerStrums.playAnim(key, "pressed");
	}

	public function keyUnshit(event:KeyboardEvent):Void {
		var key:Int = gameplay.PlayState.getStrumFromKey(event.keyCode);
		if (perfectMode || key < 0)
			return;
		holdInputs[key] = false;
		playerStrums.playAnim(key, "static");
	}
}
