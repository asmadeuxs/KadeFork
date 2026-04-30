package gameplay;

import data.Highscore;
import data.hscript.Script;
import data.hscript.ScriptLoader;
import data.song.KadeForkChart;
import data.song.Song;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import gameplay.note.Note;
import gameplay.note.NoteRenderer;
import gameplay.note.Strumline;
import moonchart.formats.BasicFormat;
import openfl.events.KeyboardEvent;

using util.CoolUtil;

class DummyPlayState extends MusicBeatState {
	var chart(default, set):DynamicFormat;
	var chartMeta:BasicMetaData;
	var songName:String = "bopeebo";
	var difficulty:String = 'hard';

	function set_chart(to:DynamicFormat) {
		chartMeta = to.getChartMeta();
		return chart = to;
	}

	var unspawnNotes:Array<NoteData> = [];
	var strumlines:FlxTypedSpriteGroup<Strumline>;
	var opponentStrums:Strumline;
	var playerStrums:Strumline;
	var notes:NoteRenderer;

	var scrollSpeed:Float = 1.0;
	var generatedMusic:Bool = false;
	var perfectMode:Bool = false;

	var holdInputs:Array<Bool> = [false, false, false, false];
	var inputQueue:Array<Array<Note>> = [];
	var inputMgr:InputManager;

	override function create() {
		super.create();

		Conductor.current.active = false;
		Conductor.setTime(0.0);

		var formattedSong:String = Highscore.formatSong(songName, difficulty);
		chart = Song.loadFromFile(formattedSong, songName);
		generateSong();

		inputMgr = new InputManager(keyPressed, keyReleased);
		inputQueue.resize(PlayState.noteActions.length);
		for (i in 0...inputQueue.length)
			inputQueue[i] = [];
		for (noteData in 0...PlayState.noteActions.length) {
			var action = PlayState.noteActions[noteData];
			var keys:Array<FlxKey> = Controls.current.actions[action];
			for (key in keys)
				inputMgr.remapKeyCode(key, noteData);
		}
		inputMgr.init(); // NEED to do this

		strumlines = new FlxTypedSpriteGroup();
		notes = new NoteRenderer(unspawnNotes);
		notes.noteSpawned.add(queueInputNote);
		notes.noteKilled.add(removeNoteFromInputQueue);
		add(strumlines);
		add(notes);

		opponentStrums = new Strumline();
		playerStrums = new Strumline();
		opponentStrums.x = (FlxG.width - opponentStrums.width) * 0.05;
		playerStrums.x = (FlxG.width - playerStrums.width) * 0.8;
		strumlines.add(opponentStrums);
		strumlines.add(playerStrums);

		Conductor.current.active = true;
		Conductor.setTime(-Conductor.crotchet * 6.7);
	}

	private function generateSong():Void {
		Conductor.mapTimingPoints(chart);
		Conductor.current.loadMusic(Paths.inst(songName));
		Conductor.current.addTrack(Paths.voices(songName));

		Conductor.bpm = chartMeta.bpmChanges[0].bpm;
		scrollSpeed = chartMeta.scrollSpeeds.get(difficulty) ?? 2.5;

		var noteTypes:Array<String> = [];
		unspawnNotes.resize(0);

		for (note in chart.getNotes(difficulty)) {
			var strumTime:Float = note.time /*+ Prefences.user.noteOffset*/;
			var noteLane:Int = note.lane;
			if (strumTime < 0)
				continue;
			var oldNote:NoteData = null;
			if (unspawnNotes.length > 0)
				oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
			final owner:Int = Std.int(noteLane / 4);
			final lane:Int = Std.int(noteLane % 4);
			if (oldNote != null)
				if (Math.abs(oldNote.time - strumTime) < 0.00001 && oldNote.lane == lane && oldNote.owner == owner)
					continue;
			// @formatter:off
			var swagNote:NoteData = {time: strumTime, lane: lane, type: note.type, length: note.length, owner: owner};
			unspawnNotes.push(swagNote);
			// @formatter:on
			if (!noteTypes.contains(swagNote.type))
				noteTypes.push(swagNote.type);
		}
		unspawnNotes.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));

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

	override function destroy() {
		Conductor.current.active = false;
		Conductor.current.stopMusic();
		Conductor.current.clearTracks();
		inputMgr.destroy();
	}

	var starting:Bool = true;

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (starting && Conductor.time >= 0) {
			Conductor.current.playMusic();
			starting = false;
		}
		notes.updateNotes(Conductor.time, strumlines.members, scrollSpeed);
		if (generatedMusic)
			noteUpdate(Conductor.time);
	}

	function noteUpdate(time:Float):Void {
		for (daNote in notes.getActiveNotes()) {
			var noteKill:Bool = false;
			var autoHit:Bool = !daNote.mustPress || (daNote.mustPress && perfectMode);
			if (autoHit) {
				if (daNote.strumTime <= time && !daNote.isFake) {
					for (vocal in Conductor.current.tracks)
						vocal.volume = 1;
					daNote.wasGoodHit = true;
					if (daNote.isSustain)
						daNote.sustainProgress -= time / daNote.sustainLength;
					noteKill = !daNote.isSustain || daNote.sustainProgress <= 0.0;
				}
			} else if (daNote.mustPress) {
				var safeZone:Float = 180.0;
				if (daNote.strumTime < (time + daNote.sustainLength) - safeZone)
					daNote.tooLate = true;
				if (daNote.wasGoodHit) {
					if (holdInputs[daNote.noteData] == true && daNote.isSustain) {
						daNote.sustainProgress -= time / daNote.sustainLength;
						noteKill = daNote.sustainProgress <= 0.0;
					}
				} else {
					if (!daNote.missed && (daNote.strumTime + daNote.sustainLength) - time < -(150 + daNote.sustainLength)) {
						for (vocal in Conductor.current.tracks)
							vocal.volume = 0;
						daNote.missed = true;
						noteKill = true;
					}
				}
			}
			if (noteKill)
				notes.removeNote(daNote);
		}
	}

	public function queueInputNote(note:Note):Void {
		var lane:Int = note.noteData;
		var placeInQ = inputQueue[lane];
		var i:Int = 0;
		while (i < placeInQ.length && placeInQ[i].strumTime < note.strumTime)
			i++;
		placeInQ.insert(i, note);
	}

	function removeNoteFromInputQueue(note:Note):Void {
		var lane:Int = note.noteData;
		var placeInQ = inputQueue[lane];
		var i = placeInQ.indexOf(note);
		if (i != -1)
			placeInQ.splice(i, 1);
	}

	public function keyPressed(key:Int):Void {
		var on:Bool = inputMgr != null && !perfectMode;
		if (!on || key == -1 || !generatedMusic)
			return;

		var lane:Int = key;
		var queue:Array<Note> = inputQueue[lane];
		var next:Note = (queue.length != 0) ? queue[0] : null;
		holdInputs[key] = true;

		if (next != null && next.canBeHit) {
			queue.shift();
			next.wasGoodHit = true;
			next.hitDifference = Math.abs(next.strumTime - Conductor.time);
			if (!next.isSustain)
				notes.removeNote(next);
			else {
				next.visible = false;
				if (next.holdBody != null)
					next.holdBody.visible = true;
				if (next.holdEnd != null)
					next.holdEnd.visible = true;
			}
			playerStrums.playAnim(key, "confirm");
			for (vocal in Conductor.current.tracks)
				vocal.volume = 1;
		} else
			playerStrums.playAnim(key, "pressed");
	}

	public function keyReleased(key:Int):Void {
		var on:Bool = inputMgr != null && !perfectMode;
		if (!on || key == -1 || !generatedMusic)
			return;
		holdInputs[key] = false;
		playerStrums.playAnim(key, "static");
	}
}
