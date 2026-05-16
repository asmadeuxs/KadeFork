package editor;

import data.Noteskin;
import data.song.KadeForkChart;
import editor.obj.ChartingGrid;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import gameplay.PlayState;
import gameplay.note.Note;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFLegacy;

using StringTools;
using util.CoolUtil;

class ChartEditor extends MusicBeatState {
	var songName:String = "Test";
	var rawSongName:String = "test";
	var difficultyName:String = "HARD";

	var chart:KadeForkChart;
	var chartMeta:BasicMetaData;

	// editor stuff
	var bpmText:FlxText;
	var gridGroup:FlxTypedSpriteGroup<ChartingGrid>;
	var GRID_SIZE:Int = 40;
	var keyCount:Int = 4;
	var players:Int = 2;

	var noteGroup:FlxTypedSpriteGroup<Note>;
	var placedNotes:Array<Array<NoteData>> = [];

	// events
	var eventMarkers:FlxTypedSpriteGroup<EventMarker>;
	var eventList:Array<ChartEventArray> = [];
	var eventGrid:ChartingGrid;

	override function create():Void {
		super.create();
		Conductor.setTime(0.0);
		FlxG.mouse.visible = true;
		songName = PlayState.songTitle;
		rawSongName = PlayState.songName;
		difficultyName = PlayState.difficulty;
		chart = new KFCHandler().fromFormat(PlayState.playlist.getCurrent());
		chartMeta = chart.getChartMeta();
		Conductor.mapTimingPoints(chart);
		#if hxdiscord_rpc
		DiscordClient.changePresence('${songName} (${difficultyName.toUpperCase()})', 'Editing Chart');
		#end

		var bg:FlxSprite = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		bg.alpha = 0.6;
		add(bg);

		var backgroundBF:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/backgrounds/menuDesat'));
		backgroundBF.scrollFactor.set();
		backgroundBF.alpha = 0.6;
		add(backgroundBF);

		add(gridGroup = new FlxTypedSpriteGroup());
		add(noteGroup = new FlxTypedSpriteGroup());
		add(eventMarkers = new FlxTypedSpriteGroup<EventMarker>());
		add(bpmText = new FlxText(5, 0, 0, "BPM: 0"));

		bpmText.setFormat(null, 18, 0xFFFFFFFF, LEFT);
		bpmText.setBorderStyle(OUTLINE, 0xFF000000, 2.0);

		loadNotesFromChart();
		reloadPlayers();
		refreshGrid();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		// @formatter:off
		bpmText.text = 'BPM: ' + FlxMath.roundDecimal(Conductor.bpm, 3)
			+ ' - Beat: ' + FlxMath.roundDecimal(Conductor.currentBeat, 3)
		  + '\nStep: ' + FlxMath.roundDecimal(Conductor.currentStep, 3)
			+ ' - Bar: ' + FlxMath.roundDecimal(Conductor.currentBar, 3);
		bpmText.y = (FlxG.height - bpmText.height) - 5;
		// @formatter:on
		if (eventGrid != null) {
			if (FlxG.mouse.overlaps(eventGrid)) {
				// event placing/removing
				if (FlxG.mouse.justPressed) {
					var localY = FlxG.mouse.y - eventGrid.y;
					var row:Int = Math.floor(scrollOffset + localY / GRID_SIZE);
					if (row >= 0 && row < maxRows)
						addEventAtRow(row);
				}
				if (FlxG.mouse.justPressedRight) {
					var localY = FlxG.mouse.y - eventGrid.y;
					var row:Int = Math.floor(scrollOffset + localY / GRID_SIZE);
					if (row >= 0 && row < maxRows)
						removeEventAtRow(row);
				}
			}
		}

		if (gridGroup != null && gridGroup.members.length != 0) {
			for (id in 0...players) {
				var grid:ChartingGrid = gridGroup.members[id];
				if (grid == null || !FlxG.mouse.overlaps(grid))
					continue;
				if (FlxG.mouse.justPressed) {
					var localX = FlxG.mouse.x - grid.x;
					var localY = FlxG.mouse.y - grid.y;
					var lane = Math.floor(localX / GRID_SIZE);
					var row = Math.floor(scrollOffset + localY / GRID_SIZE);
					if (lane >= 0 && lane < grid.columns && row >= 0 && row < maxRows)
						addNoteAtRow(row, lane, id);
				}
				if (FlxG.mouse.justPressedRight) {
					var localX = FlxG.mouse.x - grid.x;
					var localY = FlxG.mouse.y - grid.y;
					var lane = Math.floor(localX / GRID_SIZE);
					var row = Math.floor(scrollOffset + localY / GRID_SIZE);
					if (lane >= 0 && lane < grid.columns && row >= 0 && row < maxRows)
						removeNoteAtRow(row, lane, id);
				}
			}
		}

		var scrollDelta:Float = 0.0;
		if (FlxG.mouse.wheel != 0)
			scrollDelta = -Std.int(FlxG.mouse.wheel);
		if (FlxG.keys.justPressed.UP)
			scrollDelta = -1;
		if (FlxG.keys.justPressed.DOWN)
			scrollDelta = 1;

		if (scrollDelta != 0.0) {
			var newOffset:Float = scrollOffset + scrollDelta;
			if (newOffset >= 0 && newOffset + visibleRows <= maxRows) {
				scrollOffset = newOffset;
				updateGridScroll();
				refreshGrid();
			}
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			if (rawSongName == PlayState.songName)
				FlxG.switchState(new gameplay.PlayState());
			else
				FlxG.switchState(new menus.TitleState());
			FlxG.mouse.visible = false;
		}
	}

	var scrollOffset:Float = 0;
	var visibleRows:Float = 20;
	var maxRows:Float = 2000;
	var scrollBar:FlxSprite;

	function updateGridScroll():Void {
		var offsetY:Float = -scrollOffset * GRID_SIZE;
		gridGroup.y = offsetY;
		eventMarkers.y = offsetY;
		noteGroup.y = offsetY;
	}

	function addNoteAtRow(row:Int, lane:Int, owner:Int):Void {
		if (placedNotes[owner] == null)
			placedNotes[owner] = [];
		if (getNoteAtRow(row, lane, owner) != null) {
			removeNoteAtRow(row, lane, owner);
			return;
		}
		var time:Float = getTimeFromStep(row);
		var noteData:NoteData = {
			time: time,
			lane: lane,
			type: null,
			length: 0,
			owner: owner
		};
		var strumline = chart.data.strumlines[owner];
		if (strumline == null) {
			chart.data.strumlines[owner] = {skin: "default", keyCount: 4};
			strumline = chart.data.strumlines[owner];
		}
		chart.data.notes.push(noteData);
		placedNotes[owner].push(noteData);
		placedNotes[owner].sort(PlayState.sortByShit);

		var daNote = new Note().setup(null, noteData);
		daNote.setSkin(Noteskin.loadNoteskinFile(strumline.skin));
		if (daNote.skin != null)
			daNote.skin.generateArrow(noteData.lane, daNote);
		daNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
		daNote.updateHitbox();
		daNote.x = getNoteX(owner, noteData.lane);
		daNote.y = getNoteY(row);
		daNote.debugMode = true;
		noteGroup.add(daNote);
	}

	function getNoteAtRow(row:Int, lane:Int, owner:Int):NoteData {
		var time:Float = getTimeFromStep(row);
		for (n in placedNotes[owner])
			if (Math.abs(n.time - time) < 0.1 && n.lane == lane)
				return n;
		return null;
	}

	function removeNoteAtRow(row:Int, lane:Int, owner:Int):Void {
		var time:Float = getTimeFromStep(row);
		if (chart.data.notes != null)
			chart.data.notes = chart.data.notes.filter(n -> !(Math.abs(n.time - time) < 0.1 && n.lane == lane));
		placedNotes[owner] = placedNotes[owner].filter(n -> !(Math.abs(n.time - time) < 0.1 && n.lane == lane));
		for (daNote in noteGroup.members) {
			if (daNote == null)
				continue;
			if (Math.abs(daNote.strumTime - time) < 0.1 && daNote.noteData == lane) {
				daNote.destroy();
				noteGroup.remove(daNote);
				break;
			}
		}
	}

	function getNoteX(owner:Int, lane:Int):Float {
		var grid:ChartingGrid = gridGroup.members[owner];
		return grid.x + lane * GRID_SIZE;
	}

	function getNoteY(row:Int):Float {
		var startRow:Float = scrollOffset;
		var visibleStartY:Float = gridGroup.members[0].y;
		return visibleStartY + (row - startRow) * GRID_SIZE;
	}

	function addEventAtRow(row:Int):Void {
		if (getEventAtRow(row) != null) {
			removeEventAtRow(row);
			return;
		}

		var targetTime:Float = getTimeFromStep(row);
		var defaultEvent:PlaySongEvent = ChangeBPM(Conductor.bpm);
		eventList.push({time: targetTime, timeline: [defaultEvent]});
		sortEvents();

		var markerX = eventGrid.x;
		var markerY = eventGrid.y + row * GRID_SIZE;
		var marker = new EventMarker(markerX, markerY, 'Change BPM', row, targetTime);
		eventMarkers.add(marker);
	}

	function getEventAtRow(row:Int):ChartEventArray {
		var targetTime:Float = getTimeFromStep(row);
		for (e in eventList)
			if (Math.abs(e.time - targetTime) < 0.1)
				return e;
		return null;
	}

	function removeEventAtRow(row:Int):Void {
		var targetTime:Float = getTimeFromStep(row);
		eventList = eventList.filter(e -> Math.abs(e.time - targetTime) >= 0.1);
		var toRemove = [for (m in eventMarkers.members) if (m.eventRow == row) m];
		for (m in toRemove) {
			eventMarkers.remove(m);
			m.destroy();
		}
	}

	function sortEvents():Void {
		eventList.sort((a, b) -> Std.int(a.time - b.time));
	}

	function getTimeFromStep(step:Int):Float {
		if (Conductor.timingPoints.length == 0)
			return 0.0;
		var points = Conductor.timingPoints.copy();
		points.sort((a, b) -> Std.int(a.time - b.time));

		var currentTime:Float = 0.0;
		var currentStep:Int = 0;

		for (i in 0...points.length) {
			var tp = points[i];
			var stepAtChange = Math.round(tp.time / Conductor.getStepDuration(tp));
			if (step >= stepAtChange) {
				var stepsInSection = stepAtChange - currentStep;
				currentTime += stepsInSection * Conductor.getStepDuration(tp);
				currentStep = stepAtChange;
			} else
				break;
		}
		var lastTp = points[points.length - 1];
		currentTime += (step - currentStep) * Conductor.getStepDuration(lastTp);
		return currentTime;
	}

	function getStepFromTime(time:Float):Int {
		if (Conductor.timingPoints.length == 0)
			return 0;
		var points = Conductor.timingPoints.copy();
		points.sort((a, b) -> Std.int(a.time - b.time));

		var curStep:Int = 0;
		var curTime:Float = 0.0;
		for (i in 0...points.length) {
			var tp = points[i];
			var stepDur:Float = Conductor.getStepDuration(tp);
			var next:Float = (tp.time - curTime) / stepDur;
			if (time < tp.time) {
				curStep += Math.floor((time - curTime) / stepDur);
				return curStep;
			}
			curStep += Math.floor(next);
			curTime = tp.time;
		}
		var lastTp = points[points.length - 1];
		var stepDur:Float = Conductor.getStepDuration(lastTp);
		curStep += Math.floor((time - curTime) / stepDur);
		return curStep;
	}

	function getTotalSteps():Int {
		if (chart == null)
			return 200;
		var notes = chart.getNotes();
		var lastNote = notes[notes.length - 1];
		var lastEvent = eventList[eventList.length - 1];
		var lastTime:Float = 0.0;
		if (lastNote.time > lastTime)
			lastTime = lastNote.time;
		if (lastEvent.time > lastTime)
			lastTime = lastEvent.time;
		return getStepFromTime(lastTime) + 10;
	}

	function addPlayer(?quantity:Int = 1):Int {
		players += quantity;
		reloadPlayers();
		return players;
	}

	function reloadPlayers():Void {
		placedNotes.resize(0);
		for (_ in 0...players)
			placedNotes.push([]);
	}

	function refreshGrid():Void {
		visibleRows = Math.floor(FlxG.height / GRID_SIZE) - 1;
		var startRow:Float = scrollOffset;
		var endRow:Float = Math.min(scrollOffset + visibleRows, maxRows);
		var rows:Int = Math.floor(endRow - startRow);
		var totalHeight:Float = rows * GRID_SIZE;
		var gap:Float = 10;

		if (gridGroup.members.length <= 0) {
			for (i in 0...players) {
				var playerGrid = new ChartingGrid(0, 0, 4, rows, GRID_SIZE);
				if (i == 0) {
					playerGrid.y = (FlxG.height - totalHeight) * 0.5;
				} else {
					var lp = gridGroup.members[gridGroup.members.length - 1];
					playerGrid.setPosition(lp.x + lp.width + gap, lp.y);
				}
				trace('rows $rows - grid height: ${playerGrid.height}');
				gridGroup.add(playerGrid);
			}
			var p1 = gridGroup.members[0];
			eventGrid = new ChartingGrid(0, p1.y, 1, rows, GRID_SIZE);
			eventGrid.changeCheckerColor(0xFFAAAAAA, 0xFFDDDDDD);
			eventGrid.x = p1.x - GRID_SIZE - gap;
			gridGroup.add(eventGrid);
			gridGroup.screenCenter(X);
		}

		refreshEvents();
		refreshNotes();
	}

	public function refreshEvents() {
		eventMarkers.forEachAlive((m) -> m.destroy());
		eventMarkers.clear();

		var startRow:Float = scrollOffset;
		var endRow:Float = Math.min(scrollOffset + visibleRows, maxRows);
		var rows:Int = Math.floor(endRow - startRow);

		for (event in eventList) {
			var row:Int = getStepFromTime(event.time);
			if (row >= startRow && row < endRow) {
				var markerY:Float = eventGrid.y + (row - startRow) * GRID_SIZE;
				var eventName:String = KFCHandler.eventToString(event.timeline[0]);
				var marker = new EventMarker(eventGrid.x, markerY, eventName, row, event.time);
				eventMarkers.add(marker);
			}
		}
	}

	function refreshNotes():Void {
		noteGroup.forEachAlive(n -> n.destroy());
		noteGroup.clear();

		var startRow = scrollOffset;
		var endRow = scrollOffset + visibleRows;
		for (owner in 0...players) {
			if (chart.data.strumlines == null)
				continue;
			var strumline = chart.data.strumlines[owner];
			if (strumline == null)
				continue;
			for (note in placedNotes[owner]) {
				var row = getStepFromTime(note.time);
				if (row >= startRow && row < endRow) {
					var daNote = new Note().setup(null, note);
					daNote.setSkin(Noteskin.loadNoteskinFile(strumline.skin));
					if (daNote.skin != null)
						daNote.skin.generateArrow(note.lane, daNote);
					daNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
					daNote.updateHitbox();
					daNote.x = getNoteX(owner, note.lane);
					daNote.y = getNoteY(row);
					daNote.debugMode = true;
					noteGroup.add(daNote);
				}
			}
		}
	}

	function loadNotesFromChart():Void {
		if (chart.data.notes == null) {
			chart.data.notes = [];
			return;
		}

		while (placedNotes.length < players)
			placedNotes.push([]);
		for (i in 0...players)
			placedNotes[i] = [];

		for (note in chart.data.notes) {
			if (note.owner >= players)
				continue;
			placedNotes[note.owner].push(note);
		}

		for (owner in 0...players)
			placedNotes[owner].sort((a, b) -> Std.int(a.time - b.time));
	}
}

class EventMarker extends FlxSprite {
	public var eventName:String;
	public var eventTime:Float;
	public var eventRow:Int;

	public function new(x:Float, y:Float, name:String, row:Int, time:Float) {
		super(x, y);
		eventName = name;
		eventRow = row;
		eventTime = time;
		var img:String = Paths.resolveAssetPath('images/gameplay/ui/$eventName.png');
		if (Paths.fileExists(img))
			loadGraphic(Paths.getPath(img, IMAGE));
		else
			makeGraphic(40, 40, FlxColor.RED);
		alpha = 0.7;
	}
}
