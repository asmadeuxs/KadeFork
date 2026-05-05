package gameplay.note;

import data.song.KadeForkChart.NoteData;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.typeLimit.OneOfTwo;
import flixel.util.FlxSignal;
import gameplay.note.Note;
import util.ObjectPool;

using util.CoolUtil;

class NoteRenderer extends FlxBasic {
	public var noteSpawned(get, never):FlxTypedSignal<Note->Void>;
	public var noteKilled(get, never):FlxTypedSignal<Note->Void>; // fnf note found dead in the bronx

	var notePool:ObjectPool<Note>;
	var activeNotes:Array<Note> = [];
	var unspawnNotes:Array<NoteData>;
	var spawnDelay:Float = 1500.0;
	var spawnIndex:Int = 0;

	public function new(unspawnNotes:Array<NoteData>, poolSize:Int = 64) {
		super();
		_noteSpawned = new FlxTypedSignal();
		_noteKilled = new FlxTypedSignal();
		this.unspawnNotes = unspawnNotes;
		notePool = new ObjectPool<Note>(poolSize, (_) -> new Note());
		notePool.initiatePool();
	}

	public function updateNotes(time:Float, strumlines:Array<Strumline>, scrollSpeed:Float):Void {
		if (active) {
			spawnNotes(time, strumlines, scrollSpeed);
			updateNotePositions(time, strumlines, scrollSpeed);
		}
	}

	public function spawnNotes(time:Float, strumlines:Array<Strumline>, scrollSpeed:Float):Void {
		while (spawnIndex < unspawnNotes.length) {
			var noteData:NoteData = unspawnNotes[spawnIndex];
			var timeToNote:Float = noteData.time - time;
			if (timeToNote > spawnDelay)
				break;
			var note:Note = notePool.get();
			if (note == null)
				note = new Note();
			var strumline:Strumline = strumlines[noteData.owner];
			if (strumline != null) {
				note.setup(strumline, noteData);
				if (noteData.type == null || noteData.type == 'default' || noteData.type == '0')
					strumline.noteskin.generateArrow(noteData.lane, note);
				note.mustPress = (strumline == strumlines[1]);
				note.cameras = this.cameras;
				if (note.isSustain) {
					note.holdBody = strumline.noteskin.generateSustain(note.noteData, false);
					note.holdEnd = strumline.noteskin.generateSustain(note.noteData, true);
					note.holdBody.cameras = note.cameras;
					note.holdEnd.cameras = note.cameras;
				}
				note.revive();
				activeNotes.push(note);
				if (noteSpawned != null)
					noteSpawned.dispatch(note);
			} else {
				note.kill();
				notePool.release(note);
			}
			spawnIndex++;
		}
	}

	// idk where else to put this -asmadeuxs
	public static function getScrollSpeedMod(defaultSpeed:Float):Float {
		var userSS:Float = Preferences.user.scrollSpeed;
		var result:Float = switch Preferences.user.scrollSpeedType {
			case 3: (Conductor.bpm / 60.0) + userSS;
			case 1: defaultSpeed + userSS;
			case 2: userSS;
			case _: defaultSpeed;
		}
		return FlxMath.roundDecimal(result, 3);
	}

	public function updateNotePositions(time:Float, strumlines:Array<Strumline>, speed:Float):Void {
		var i:Int = 0;
		while (i < activeNotes.length) {
			var note:Note = activeNotes[i];
			var strumline:Strumline = strumlines[note.noteOwner];
			var downscroll:Int = strumline.getDownscrollMult(note.noteData);
			if (strumline == null) {
				killNote(note, i);
				continue;
			}

			var scrollSpeed:Float = speed;
			var curStrum = strumline.getStrum(note.noteData);
			if (Preferences.user.scrollSpeedType < 2) { // C-Mod or X-Mod
				var slScrollSpeed:Null<Float> = strumline.getScrollSpeed(note.noteData);
				if (slScrollSpeed != null && Math.abs(scrollSpeed - slScrollSpeed) > 0.00000001)
					scrollSpeed = slScrollSpeed;
			}
			if (curStrum != null) {
				var difference:Float = (time - note.strumTime);
				var noteScroll:Float = difference * ((0.45 * scrollSpeed) * downscroll);
				note.y = curStrum.y - noteScroll;
				note.visible = curStrum.visible;
				if (!note.isSustain)
					note.angle = curStrum.angle;
				note.alpha = curStrum.alpha;
				note.objectCenter(curStrum, X);
			}
			note.updateSustain(time, scrollSpeed);
			var noteHeight:Float = note.sustainLength;
			var timeOffset:Float = (note.strumTime + noteHeight) - time;
			if (timeOffset < -2000 || timeOffset > 2500) {
				killNote(note, i);
				continue;
			}
			i++;
		}
	}

	function killNote(note:Note, index:Int):Void {
		note.kill();
		if (note.holdBody != null)
			note.holdBody.kill();
		if (note.holdEnd != null)
			note.holdEnd.kill();
		notePool.release(note);
		activeNotes.splice(index, 1);
		if (noteKilled != null)
			noteKilled.dispatch(note);
	}

	override function draw():Void {
		for (note in activeNotes)
			if (note.visible && note.exists && note.active) {
				if (note.isSustain) {
					if (note.holdBody != null)
						note.holdBody.draw();
					if (note.holdEnd != null)
						note.holdEnd.draw();
				}
				note.draw();
			}
	}

	public function getActiveNotes():Array<Note>
		return activeNotes;

	public function filter(func:Note->Bool):Array<Note>
		return activeNotes.filter(func);

	public function seek(newTime:Float):Void {
		var left = 0;
		var right = unspawnNotes.length - 1;
		var newIndex = unspawnNotes.length;
		while (left <= right) {
			var mid = (left + right) >> 1;
			if (unspawnNotes[mid].time >= newTime) {
				newIndex = mid;
				right = mid - 1;
			} else
				left = mid + 1;
		}
		spawnIndex = newIndex;
		var i = 0;
		while (i < activeNotes.length) {
			var note = activeNotes[i];
			if (note.strumTime > newTime + spawnDelay)
				killNote(note, i);
			else
				i++;
		}
	}

	public function clearAll():Void {
		for (note in activeNotes) {
			note.kill();
			if (note.holdBody != null)
				note.holdBody.kill();
			if (note.holdEnd != null)
				note.holdEnd.kill();
			notePool.release(note);
		}
		activeNotes.resize(0);
		spawnIndex = 0;
	}

	public function removeNote(note:Note):Void {
		var index:Int = activeNotes.indexOf(note);
		if (index != -1)
			killNote(note, index);
	}

	override public function set_camera(Value:FlxCamera):FlxCamera {
		for (note in activeNotes)
			note.camera = Value;
		return super.set_camera(Value);
	}

	@:noCompletion var _noteSpawned:FlxTypedSignal<Note->Void>;
	@:noCompletion var _noteKilled:FlxTypedSignal<Note->Void>;

	@:noCompletion function get_noteSpawned():FlxTypedSignal<Note->Void>
		return _noteSpawned;

	@:noCompletion function get_noteKilled():FlxTypedSignal<Note->Void>
		return _noteKilled;
}
