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
typedef KadeForkChart = BasicFormat<KFCFormat, KFCMeta>;

class KFCHandler extends BasicFormat<KFCFormat, KFCMeta> {
	public var noteTypeResolver(default, null):FNFNoteTypeResolver;

	public static function __getFormat():FormatData {
		return {
			ID: "KADE_FORK",
			name: "Kade Fork",
			extension: "json",
			metaFileExtension: "json",
			description: "Welcome to FNF Engine number 1225 today we're adding to the problem of having too many chart formats.",
			specialValues: ['"euskara":'],
			hasMetaFile: POSSIBLE,
			handler: KFCHandler
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
		var cumulativeLanes:Array<Int> = [];
		var total:Int = 0;
		for (sl in data.strumlines) {
			cumulativeLanes.push(total);
			total += sl.keyCount;
		}
		for (note in data.notes) {
			var absoluteLane = cumulativeLanes[note.owner] + note.lane;
			notes.push({
				time: note.time,
				lane: absoluteLane,
				length: note.length,
				type: note.type
			});
		}
		Timing.sortNotes(notes);
		return notes;
	}

	override function fromFile(path:String, ?meta:StringInput, ?diff:FormatDifficulty):KadeForkChart {
		var data:KFCFormat = haxe.Json.parse(sys.io.File.getContent(path));
		this.data = data;

		if (meta != null) {
			var meta:KFCMeta = haxe.Json.parse(sys.io.File.getContent(meta));
			this.meta = meta;
		}
		else {
			var metaPath = path.substr(0, path.length - 5) + "_meta.json";
			if (Paths.fileExists(metaPath)) {
				var meta:KFCMeta = haxe.Json.parse(sys.io.File.getContent(meta));
				this.meta = meta;
			}
		}

		if (this.meta == null) {
			this.meta = {
				name: "Unknown",
				artist: Moonchart.DEFAULT_ARTIST,
				player: "none",
				opponent: "none",
				metronome: "none",
				stage: "stage",
				tracks: new Map(),
				charter: "Unknown"
			};
		}
		return this;
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):BasicFormat<KFCFormat, KFCMeta> {
		var chartResolve = resolveDiffsNotes(chart, diff);
		var diff:String = chartResolve.diffs[0];

		final basicData = chart.data;
		final basicMeta = chart.meta;

		data = {
			strumlines: [],
			bpmChanges: [],
			scrollSpeed: 1.0,
			events: [],
			notes: [],
			euskara: true
		};

		for (change in basicMeta.bpmChanges) {
			data.bpmChanges.push({
				time: change.time,
				event: ChangeBPM(change.bpm, change.stepsPerBeat, change.beatsPerMeasure)
			});
		}
		data.scrollSpeed = basicMeta.scrollSpeeds[diff] ?? 1.0;

		var keyCounts:Array<Int> = [4, 4];
		if (basicMeta.extraData.exists("STRUMS_LENGTH")) {
			var lengths:Array<Int> = chart.meta.extraData.get("STRUMS_LENGTH");
			for (i in 0...lengths.length)
				keyCounts[i] = lengths[i] ?? 4;
		}

		if (data.strumlines == null)
			data.strumlines = [];

		var notes:Array<BasicNote> = chartResolve.notes[diff];
		if (notes == null) {
			trace('[KadeForkChart.fromBasicFormat] No notes found for chart (difficulty: $diff)');
			notes = [];
		}
		var ownerLength:Int = -1;
		for (note in notes) {
			var cumul:Int = 0;
			var owner:Int = 0;
			for (kc in keyCounts) {
				if (note.lane < cumul + kc)
					break;
				cumul += kc;
				owner++;
			}
			var daNoteData:NoteData = {
				time: note.time,
				lane: note.lane - cumul,
				type: note.type ?? null,
				length: note.length ?? 0.0,
				owner: owner
			};
			if (data.strumlines[owner] == null)
				data.strumlines[owner] = {skin: "default", keyCount: keyCounts[owner] ?? 4};
			data.notes.push(daNoteData);
		}
		data.notes.sort((a, b) -> Std.int(a.time - b.time));

		if (data.events == null)
			data.events = [];

		if (basicData.events != null && basicData.events.length != 0) {
			for (basicEvent in basicData.events) {
				var solvedEvent:ChartEventArray = {time: basicEvent.time, timeline: []};
				solvedEvent.timeline.push(eventFromBasic(basicEvent));
				data.events.push(solvedEvent);
			}
			data.events.sort((a, b) -> Std.int(a.time - b.time));
		}

		meta = {
			player: chart.meta.extraData.get(PLAYER_1) ?? "none",
			opponent: chart.meta.extraData.get(PLAYER_2) ?? "none",
			metronome: chart.meta.extraData.get(PLAYER_3) ?? "none",
			stage: chart.meta.extraData.get(STAGE) ?? "stage",
			charter: chart.meta.extraData.get(SONG_CHARTER) ?? "Unknown",
			artist: chart.meta.extraData.get(SONG_ARTIST) ?? Moonchart.DEFAULT_ARTIST,
			name: chart.meta.title ?? "Unknown Song",
			tracks: new Map()
		};

		return this;
	}

	override function getEvents():Array<BasicEvent> {
		var events:Array<BasicEvent> = [];
		if (data.events != null)
			for (e in data.events)
				for (playEvent in e.timeline)
					events.push(eventToBasic(e.time, playEvent));
		return events;
	}

	function eventToBasic(time:Float, event:PlaySongEvent):BasicEvent {
		return switch event {
			case ChangeBPM(newBpm, denominator, numerator): {time: time, name: "ChangeBPM", data: {bpm: newBpm, denominator: denominator, numerator: numerator}};
			case ChangeNoteVelocity(speed, strumline): {time: time, name: "ChangeNoteVelocity", data: {speed: speed, strumline: strumline}};
			case ChangeNoteScrollType(newScrollType): {time: time, name: "ChangeNoteScrollType", data: {scrollType: newScrollType}};
			case ZoomCamera(newZoom, smoothingSpeed): {time: time, name: "ZoomCamera", data: {zoom: newZoom, smoothingSpeed: smoothingSpeed}};
			case ShakeCamera(intensity): {time: time, name: "ShakeCamera", data: {intensity: intensity}};
			case FocusCamera(focusOn): {time: time, name: "FocusCamera", data: {focusOn: focusOn}};
			case ChangeCharacter(who, to): {time: time, name: "ChangeCharacter", data: {who: who, to: to}};
			case PlayAnimation(who, anim): {time: time, name: "PlayAnimation", data: {who: who, anim: anim}};
			case ChangeStage(to): {time: time, name: "ChangeStage", data: {to: to}};
			case StartCountdown: {time: time, name: "StartCountdown", data: null};
			case Custom(name, values): {time: time, name: name, data: values};
		}
	}

	function eventFromBasic(event:BasicEvent):PlaySongEvent {
		return switch event.name {
			case "ChangeBPM": ChangeBPM(event.data.bpm, event.data.denominator, event.data.numerator);
			case "ChangeNoteVelocity": ChangeNoteVelocity(event.data.speed, event.data.strumline);
			case "ChangeNoteScrollType": ChangeNoteScrollType(event.data.speed, event.data.strumline);
			case "ZoomCamera": ZoomCamera(event.data.zoom, event.data.smoothingSpeed);
			case "ShakeCamera": ShakeCamera(event.data.intensity);
			case "FocusCamera": FocusCamera(event.data.focusOn);
			case "ChangeCharacter": ChangeCharacter(event.data.who, event.data.to);
			case "PlayAnimation": PlayAnimation(event.data.who, event.data.anim);
			case "ChangeStage": ChangeStage(event.data.to);
			case "StartCountdown": StartCountdown;
			case "FNF_MUST_HIT_SECTION": FocusCamera(event.data.mustHitSection == true ? 1 : 0);
			case _:
				var data = event.data;
				Custom(event.name, Reflect.fields(data).map(field -> Std.string(Reflect.field(data, field))));
		}
	}

	public static function eventToString(event:PlaySongEvent):String {
		return switch event {
			case ChangeBPM(_, _, _): "Change BPM";
			case ChangeNoteVelocity(_, _): "Cahnge Scroll Speed";
			case ChangeNoteScrollType(_): "Change Scroll Direction";
			case ZoomCamera(_, _): "Zoom Camera";
			case ShakeCamera(_): "Shake Camera";
			case FocusCamera(_): "Focus Camera";
			case ChangeCharacter(_, _): "Change Character";
			case PlayAnimation(_, _): "Play Animation";
			case ChangeStage(_): "Change Stage";
			case StartCountdown: "Start Countdown";
			case Custom(name, values): name;
			case _: "Unknown Event";
		}
	}

	override function getChartMeta():BasicMetaData {
		var bpmChanges:Array<BasicBPMChange> = [];
		for (change in data.bpmChanges) {
			switch change.event {
				case ChangeBPM(newBpm, denominator, numerator):
					bpmChanges.push({
						time: change.time,
						beatsPerMeasure: numerator ?? 4.0,
						stepsPerBeat: denominator ?? 4.0,
						bpm: newBpm
					});
				case _:
			}
		}
		Timing.sortBPMChanges(bpmChanges);

		var curDiff:String = diffs[0];
		return {
			offset: 0.0,
			title: meta?.name,
			bpmChanges: bpmChanges,
			scrollSpeeds: [curDiff => data.scrollSpeed],
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
	}
}

private typedef EventTimeline = {name:String, args:Array<String>}
private typedef TrackMeta = {file:String, ?bpm:Float}

enum PlaySongEvent {
	// Time Modiifers
	ChangeBPM(newBpm:Float, ?denominator:Float, ?numerator:Float);
	// Note Modifiers
	ChangeNoteVelocity(speed:Float, ?strumline:Int);
	ChangeNoteScrollType(scrollType:Int, ?strumline:Int);
	// Camera
	ZoomCamera(newZoom:Float, ?smoothingSpeed:Float);
	ShakeCamera(intensity:Float);
	FocusCamera(focusOn:Int);
	// Gameplay
	StartCountdown();
	ChangeCharacter(who:Int, to:String);
	PlayAnimation(who:Int, anim:String, ?forced:Bool);
	ChangeStage(to:String);
	// Other
	Custom(name:String, values:Array<String>);
}

typedef ChartEventSingle = BasicTimingObject & {event:PlaySongEvent}
typedef ChartEventArray = BasicTimingObject & {timeline:Array<PlaySongEvent>}
typedef ChartStrumline = {skin:String, keyCount:Int}

typedef KFCFormat = {
	bpmChanges:Array<ChartEventSingle>,
	strumlines:Array<ChartStrumline>,
	?events:Array<ChartEventArray>,
	notes:Array<NoteData>,
	// TODO: support multiple difficulties in one file
	// for now this will be a single value
	scrollSpeed:Float,

	/**
	 * Don't delete this from the file
	 * its just so moonchart's auto-detect functions can detect this format properly.
	**/
	euskara:Bool
}

typedef KFCMeta = {
	name:String,
	artist:String,
	player:String,
	opponent:String,
	metronome:String,
	stage:String,
	tracks:Map<String, TrackMeta>,
	charter:String,
}
