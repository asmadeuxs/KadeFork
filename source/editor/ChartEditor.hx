package editor;

import data.song.KadeForkChart.NoteData;
import editor.obj.ChartingGrid;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import gameplay.Note;
import gameplay.PlayState;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFLegacy;

using StringTools;
using util.CoolUtil;

class ChartEditor extends MusicBeatState {
	var songName:String = "Test";
	var rawSongName:String = "test";
	var difficultyName:String = "HARD";

	var chart(default, set):DynamicFormat;
	var chartMeta:BasicMetaData;

	function set_chart(to:DynamicFormat) {
		chartMeta = to.getChartMeta();
		return chart = to;
	}

	// editor stuff
	var bpmText:FlxText;
	var gridGroup:FlxTypedSpriteGroup<ChartingGrid>;
	var GRID_SIZE:Int = 40;
	var keyCount:Int = 4;
	var players:Int = 2;

	var noteGroup:FlxTypedSpriteGroup<Note>;
	var placedNotes:Array<Array<NoteData>> = [];

	public function new():Void {
		super();
		if (PlayState.current != null) {
			songName = PlayState.songTitle;
			rawSongName = PlayState.songName;
			difficultyName = PlayState.difficulty;
		}
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
		add(bpmText = new FlxText(5, 0, 0, "BPM: 0"));

		bpmText.setFormat(null, 24, 0xFFFFFFFF, LEFT);
		bpmText.setBorderStyle(OUTLINE, 0xFF000000, 2.0);

		reloadPlayers();
		loadGrid();
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
		if (FlxG.keys.justPressed.ESCAPE) {
			if (songName == PlayState.songTitle)
				FlxG.switchState(new gameplay.PlayState());
			else
				FlxG.switchState(new menus.TitleState());
		}
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

	function addNote(time:Float, id:Int, owner:Int, type:String):Note {
		var noteSprite = new Note().setup(time, id, 0, owner, type);
		noteGroup.add(noteSprite);
		return noteSprite;
	}

	function loadGrid():Void {
		var rows = 200;
		var cell = 40;
		var gap = 10;
		var totalHeight = rows * cell;
		for (i in 0...players) {
			var playerGrid = new ChartingGrid(0, 0, 4, rows, cell);
			if (i == 0) {
				playerGrid.y = (FlxG.height - totalHeight) * 0.5;
			} else {
				var lp = gridGroup.members[gridGroup.members.length - 1];
				playerGrid.setPosition(lp.x + lp.width + gap, lp.y);
			}
			gridGroup.add(playerGrid);
		}
		var p1 = gridGroup.members[0];
		var eventGrid = new ChartingGrid(0, p1.y, 1, rows, cell);
		eventGrid.changeCheckerColor(0xFFAAAAAA, 0xFFDDDDDD);
		eventGrid.x = p1.x - cell - gap;
		gridGroup.add(eventGrid);
		gridGroup.screenCenter(X);
	}
}
