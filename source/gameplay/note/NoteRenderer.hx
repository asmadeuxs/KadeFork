package gameplay.note;

import data.song.KadeForkChart.NoteData;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.typeLimit.OneOfTwo;
import gameplay.note.Note;
import util.ObjectPool;

using util.CoolUtil;

class NoteRenderer extends FlxBasic {
	var notePool:ObjectPool<Note>;
	var activeNotes:Array<Note> = [];
	var unspawnNotes:Array<NoteData>;
	var spawnDelay:Float = 1500.0;
	var spawnIndex:Int = 0;

	public function new(unspawnNotes:Array<NoteData>, poolSize:Int = 64) {
		super();
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
		scrollSpeed = FlxMath.roundDecimal(Preferences.user.scrollSpeed == 1 ? scrollSpeed : Preferences.user.scrollSpeed, 2);
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
					note.holdBody.alpha = 0.7;
					note.holdEnd.alpha = note.holdBody.alpha;
				}
				note.revive();
				activeNotes.push(note);
			} else {
				note.kill();
				notePool.release(note);
			}
			spawnIndex++;
		}
	}

	public function updateNotePositions(time:Float, strumlines:Array<Strumline>, scrollSpeed:Float):Void {
		scrollSpeed = FlxMath.roundDecimal(Preferences.user.scrollSpeed == 1 ? scrollSpeed : Preferences.user.scrollSpeed, 2);
		var i:Int = 0;
		while (i < activeNotes.length) {
			var note:Note = activeNotes[i];
			var strumline:Strumline = strumlines[note.noteOwner];
			var downscroll:Int = strumline.getDownscrollMult(note.noteData);
			if (strumline == null) {
				killNote(note, i);
				continue;
			}
			var curStrum = strumline.getStrum(note.noteData);
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
}
