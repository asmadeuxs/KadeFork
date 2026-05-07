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
			extension: "json",
			metaFileExtension: "json",
			description: "Welcome to FNF Engine number 1225 today we're adding to the problem of having too many chart formats.",
			specialValues: ['"euskara":'],
			hasMetaFile: POSSIBLE,
			handler: KadeForkChart
		}
	}

	public function new(?data:KFCFormat, ?meta:KFCMeta) {
		super({timeFormat: STEPS, supportsDiffs: true, supportsEvents: true});
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

	override function fromFile(path:String, ?meta:StringInput, ?diff:FormatDifficulty):KadeForkChart {
		return null;
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
			case "ChangeStage": ChangeStage(event.data.to);
			case "StartCountdown": StartCountdown;
			case _:
				var data = event.data;
				Custom(event.name, Reflect.fields(data).map(field -> Std.string(Reflect.field(data, field))));
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
		var scrollSpeedMap = data.scrollSpeeds;
		if (!scrollSpeedMap.exists(curDiff))
			scrollSpeedMap[curDiff] = 1.0;

		return {
			offset: 0.0,
			title: meta?.name,
			bpmChanges: bpmChanges,
			scrollSpeeds: scrollSpeedMap,
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
	ChangeStage(to:String);
	// Other
	Custom(name:String, values:Array<String>);
}

typedef ChartEventSingle = BasicTimingObject & {event:PlaySongEvent}
typedef ChartEventArray = BasicTimingObject & {timeline:Array<PlaySongEvent>}
typedef ChartStrumline = {notes:Array<NoteData>, skin:String, keyCount:Int}

typedef KFCFormat = {
	bpmChanges:Array<ChartEventSingle>,
	strumlines:Array<ChartStrumline>,
	?events:Array<ChartEventArray>,
	scrollSpeeds:Map<String, Float>,

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
