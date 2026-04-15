package data.song;

import moonchart.Moonchart;
import moonchart.backend.FormatData;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacyMetaValues;
import moonchart.formats.fnf.FNFGlobal;

using StringTools;

typedef NoteData = BasicNote & {owner:Int};

class KadeForkChart extends BasicFormat<KFCFormat, KFCMeta> {
	public var noteTypeResolver(default, null):FNFNoteTypeResolver;

	public static function __getFormat():FormatData {
		return {
			ID: "KADE_FORK",
			name: "Kade Fork",
			extension: "kfc",
			metaFileExtension: "json",
			description: "Welcome to FNF Engine number 1225 today we're adding to the problem of having too many chart formats.",
			hasMetaFile: POSSIBLE,
			specialValues: ['"euskara":'],
			handler: KadeForkChart
		}
	}

	public function new(?data:KFCFormat, ?meta:KFCMeta) {
		super({timeFormat: MILLISECONDS, supportsDiffs: true, supportsEvents: true});
		noteTypeResolver = FNFGlobal.createNoteTypeResolver();
		this.data = data;
		this.meta = meta;
	}

	override function getNotes(?diff:String):Array<BasicNote> {
		var notes:Array<BasicNote> = [];
		for (slid => strumline in data.strumlines) {
			for (note in strumline.notes) {
				notes.push({
					time: note.time,
					lane: note.lane + ((strumline.keyCount ?? 4) * slid),
					length: note.length,
					type: note.type
				});
			}
		}
		Timing.sortNotes(notes);
		return notes;
	}

	public override function fromFile(path:String, ?meta:StringInput, ?diff:FormatDifficulty):KadeForkChart {
		// TODO: meta
		return fromKfc(Paths.getText(path));
	}

	override function getEvents():Array<BasicEvent> {
		var events:Array<BasicEvent> = [];
		return events;
	}

	public function getStrumlines():Array<ChartStrumline>
		return data.strumlines;

	override function getChartMeta():BasicMetaData {
		var bpmChanges:Array<BasicBPMChange> = [];

		for (change in data.bpmChanges) {
			bpmChanges.push({
				time: change.time,
				bpm: change.bpm,
				beatsPerMeasure: change.denominator,
				stepsPerBeat: change.numerator
			});
		}
		Timing.sortBPMChanges(bpmChanges);

		return {
			offset: 0.0,
			title: meta?.name,
			bpmChanges: bpmChanges,
			scrollSpeeds: [diffs[0] => data.velocityChanges[0].speed],
			extraData: [
				PLAYER_1 => meta?.player ?? "bf",
				PLAYER_2 => meta?.opponent ?? "bf",
				PLAYER_3 => meta?.metronome ?? "bf",
				SONG_ARTIST => meta?.artist ?? Moonchart.DEFAULT_ARTIST,
				SONG_CHARTER => meta?.charter ?? Moonchart.DEFAULT_CHARTER,
				"STRUMS_LENGTH" => [for (sl in data.strumlines) sl.keyCount],
				STAGE => meta?.stage ?? "default",
			]
		}
	};

	public function fromKfc(str:String):KadeForkChart {
		var file:String = str;
		var chart:KFCFormat = {
			bpmChanges: [],
			velocityChanges: [],
			strumlines: [],
			events: [],
			euskara: true, // set value so library can auto-detect
		}

		var lines:Array<String> = file.split("\n");
		var currentStrumline:ChartStrumline = null;
		var strumlineIndex:Int = -1;
		var parsing:Int = -1;
		for (raw in lines) {
			var line:String = raw.trim();
			if (line.length == 0)
				continue;

			if (line == "[BpmChanges]") {
				parsing = 0;
				continue;
			} else if (line == "[VelocityChanges]") {
				parsing = 1;
				continue;
			} else if (line.startsWith("[Strumline:")) {
				if (currentStrumline != null)
					chart.strumlines.push(currentStrumline);
				var slIndex:String = line.substring(10, line.length - 1);
				strumlineIndex = Std.parseInt(slIndex);
				currentStrumline = {notes: [], skin: "default", keyCount: 4};
				parsing = 2;
				continue;
			}
			if (!line.contains("="))
				continue;
			var parts = line.split("=");
			var key = parts[0];
			var value = parts[1];

			switch parsing {
				case 0: // BPM Changes
					var time:Float = Std.parseFloat(key);
					var bpm:Float = 100.0;
					var denom:Float = 4.0;
					var num:Float = 4.0;
					if (value.contains(",")) {
						var timeEvent = value.split(",");
						bpm = Std.parseFloat(timeEvent[0]);
						denom = Std.parseFloat(timeEvent[1]);
						num = Std.parseFloat(timeEvent[2]);
					} else
						bpm = Std.parseFloat(value);
					// @formatter:off
					chart.bpmChanges.push({time: time, bpm: bpm, denominator: denom, numerator: num});
					// @formatter:on
				case 1: // Velocity Changes
					var time:Float = Std.parseFloat(key);
					var speed:Float = 100.0;
					var strumline:Int = -1;
					if (value.contains(",")) {
						var velEvent = value.split(",");
						speed = Std.parseFloat(velEvent[0]);
						strumline = Std.parseInt(velEvent[1]);
					} else
						speed = Std.parseFloat(value);
					chart.velocityChanges.push({time: time, speed: speed, strumline: strumline});

				case 2: // Notes
					if (currentStrumline == null)
						continue;
					switch key {
						case "skin":
							currentStrumline.skin = value;
						case "keyCount":
							currentStrumline.keyCount = Std.parseInt(value);
						case "notes":
							if (!value.contains("|")) // invalid note
								continue;
							var daNote = value.split("|");
							for (token in daNote) {
								if (token.length == 0)
									continue;
								var noteInfo = token.split(",");
								if (noteInfo.length < 2)
									continue;
								var time:Float = Std.parseFloat(noteInfo[0]);
								var lane:Int = Std.parseInt(noteInfo[1]);
								var type:String = Std.string(noteInfo[2]);
								var length:Float = Std.parseFloat(noteInfo[3]);
								var owner:Int = strumlineIndex;
								// @formatter:off
								currentStrumline.notes.push({time: time, lane: lane, type: type, length: length, owner: owner});
								// @formatter:on
							}
					}
			}
		}

		if (currentStrumline != null)
			chart.strumlines.push(currentStrumline);

		return new KadeForkChart(chart, null);
	}
}

private typedef EventTimeline = {name:String, args:Array<String>}
private typedef TrackMeta = {file:String, ?bpm:Float}

//
typedef ChartStrumline = {notes:Array<NoteData>, skin:String, keyCount:Int}
typedef ChartEvent = {time:Float, timeline:Array<EventTimeline>}
typedef TimeChangeEvent = {time:Float, bpm:Float, ?denominator:Float, ?numerator:Float}
typedef VelocityChangeEvent = {time:Float, speed:Float, ?strumline:Int}

typedef KFCFormat = {
	bpmChanges:Array<TimeChangeEvent>,
	velocityChanges:Array<VelocityChangeEvent>,
	strumlines:Array<ChartStrumline>,
	?events:Array<ChartEvent>,

	/**
	 * Don't delete this from the file
	 * its just so moonchart's auto-detect functions can detect this format properly.
	**/
	euskara:Bool
}

typedef KFCMeta = {
	player:String,
	opponent:String,
	metronome:String,
	stage:String,
	tracks:Map<String, TrackMeta>,
	charter:String,
	artist:String,
	name:String,
}
