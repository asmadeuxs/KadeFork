package;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.util.FlxSignal;
import moonchart.formats.BasicFormat;
import openfl.media.Sound;

@:structInit @:publicFields class TimingPoint {
	public var time:Float = 0;
	public var bpm:Float = 100.0;

	public var denominator:Float = 4.0; // steps per beat
	public var numerator:Float = 4.0; // beats per bar

	public function toString()
		return 'Time:$time | BPM: $bpm | Time Signature: $denominator/$numerator';
}

/**
 * bitch
 *
 * @author SrtHero278
 */
class Conductor extends flixel.FlxBasic {
	public static var current:Conductor;

	public static var timingPoints:Array<TimingPoint> = [{}];
	public static var bpm(default, set):Float = 100;
	public static var denominator:Float = 4.0;
	public static var numerator:Float = 4.0;

	public static var crotchet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var semiquaver:Float = crotchet / denominator; // steps in milliseconds

	public static var time:Float = 0;
	public static var rate:Float = 1.0;
	public static var lastTime:Float = 0;
	public static var offset:Float = 0;

	public static var beatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var stepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var barHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

	public static var currentBeat:Float = 0.0;
	public static var currentStep:Float = 0.0;
	public static var currentBar:Float = 0.0; // "SECTION"

	public var music:FlxSound;
	public var tracks:Array<FlxSound> = [];

	private static var synchedObjects:Array<IBeatSynched> = [];

	public static function connectSynched(instance:IBeatSynched):IBeatSynched {
		synchedObjects.push(instance);
		return instance;
	}

	public static function disconnectSynched(instance:IBeatSynched):IBeatSynched {
		synchedObjects.remove(instance);
		return instance;
	}

	public static function disconnectAllSynched():Void {
		for (i in synchedObjects)
			synchedObjects.remove(i);
	}

	public function new():Void {
		super();
		current = this;
		active = false;
	}

	public static function setTime(newTime:Float):Void {
		Conductor.time = newTime;
		Conductor.lastTime = newTime;
		Conductor.current.update(1.0);
	}

	public static function toggleActive(active:Bool)
		Conductor.current.active = active;

	public function loadMusic(stream:Sound):FlxSound {
		if (music == null) {
			music = new FlxSound();
			FlxG.sound.list.add(music);
		}
		music.loadEmbedded(stream);
		music.time = 0;
		return music;
	}

	public function addTrack(stream:Sound):FlxSound {
		var track = new FlxSound();
		track.loadEmbedded(stream);
		FlxG.sound.list.add(track);
		tracks.push(track);
		track.time = 0;
		return track;
	}

	public function addAditionalTracks(tracks:Array<Sound>):Array<FlxSound> {
		for (i in 0...tracks.length)
			if (tracks[i] != null)
				addTrack(tracks[i]);
		return this.tracks;
	}

	public function clearTracks():Void {
		if (music != null) {
			music.pause();
			music.stop();
			music.destroy();
		}
		for (i in 0...tracks.length) {
			tracks[i].pause();
			tracks[i].stop();
			tracks[i].destroy();
		}
		tracks.resize(0);
	}

	public function togglePauseTracks(pause:Bool):Void {
		for (i in tracks)
			if (pause)
				i.pause();
			else
				i.play(false, i.time);
		if (pause)
			music.pause();
		else
			music.play(false, music.time);
	}

	public function pauseMusic():Void
		return togglePauseTracks(true);

	public function playMusic():Void
		return togglePauseTracks(false);

	public function stopMusic():Void {
		for (i in tracks)
			i.stop();
		music.stop();
	}

	public function snapTime(to:Float):Void {
		Conductor.setTime(to);
		music.time = to;
		for (i in tracks)
			i.time = to;
	}

	public function resyncTracks():Void {
		for (i in tracks)
			i.pause();
		music.play(false, music.time);
		Conductor.time = music.time;
		for (i in tracks)
			i.play(false, Conductor.time);
	}

	override function update(elapsed:Float):Void {
		if (current == null || !active)
			return;
		// if (lastTime > time)
		//	time = lastTime;
		time += elapsed * 1000;

		var lastBeat = Math.floor(currentBeat);
		var lastStep = Math.floor(currentStep);
		var lastBar = Math.floor(currentBar);

		var curPoint = timingPoints[0];
		var pointStep = 0.0;
		var pointBeat = 0.0;
		var pointBar = 0.0;
		final sixtyDiv = 1 / 60;
		for (i in 1...timingPoints.length) {
			if (time < timingPoints[i].time)
				break;
			final beatDist = (timingPoints[i].time - curPoint.time) * 0.001 * (curPoint.bpm * sixtyDiv);

			pointBeat += beatDist;
			pointStep += beatDist * curPoint.denominator;
			pointBar += beatDist / curPoint.numerator;
			curPoint = timingPoints[i];
		}
		denominator = curPoint.denominator;
		numerator = curPoint.numerator;
		bpm = curPoint.bpm;
		final beatDist = (time - curPoint.time) * 0.001 * (curPoint.bpm * sixtyDiv);
		currentStep = pointStep + (beatDist * denominator);
		currentBeat = pointBeat + beatDist;
		currentBar = pointBar + (beatDist / numerator);

		var newBeat = Math.floor(currentBeat);
		var newStep = Math.floor(currentStep);
		var newBar = Math.floor(currentBar);
		// @formatter:off
		for (step in (lastStep + 1)...(newStep + 1)) onStep(step);
		for (beat in (lastBeat + 1)...(newBeat + 1)) onBeat(beat);
		for (bar in (lastBar + 1)...(newBar + 1)) onBar(bar);
		// @formatter:on
		lastTime = time;
	}

	public static function getStepDuration(tp:TimingPoint):Float {
		var secondsPerBeat:Float = 60.0 / tp.bpm;
		var secondsPerStep:Float = secondsPerBeat / tp.denominator;
		return secondsPerStep * 1000;
	}

	// stole from my Mad Rat Dead pc recreation lolll
	public static function secondsToBeats(seconds:Float, bpm:Float):Float {
		return seconds * (bpm / 60.0);
	}

	public static function beatsToSeconds(beats:Float, bpm:Float):Float {
		return beats / (bpm / 60.0);
	}

	public static function timeToBeat(beat:Float, bpm:Float):Float {
		return (time * bpm) / 60.0;
	}

	public function onStep(step:Int):Void {
		checkNeedResync();
		for (i in synchedObjects)
			i.stepHit(step);
		stepHit.dispatch(step);
	}

	public function onBeat(beat:Int):Void {
		beatHit.dispatch(beat);
		for (i in synchedObjects)
			i.beatHit(beat);
	}

	public function onBar(bar:Int):Void {
		barHit.dispatch(bar);
		for (i in synchedObjects)
			i.barHit(bar);
	}

	public function checkNeedResync():Void {
		if (music != null && music.playing && tracks.length != 0)
			if (music.time > Conductor.time + 20 || music.time < Conductor.time - 20)
				resyncTracks();
	}

	public static function mapTimingPoints(song:DynamicFormat) {
		timingPoints = [
			for (bpm in song.getChartMeta().bpmChanges) {
				{
					time: bpm.time,
					bpm: bpm.bpm,
					denominator: bpm.stepsPerBeat ?? 4,
					numerator: bpm.beatsPerMeasure ?? 4
				}
			}
		];
		Conductor.bpm = timingPoints[0].bpm;
		trace("new Timing Points BUDDY " + timingPoints);
	}

	public static function set_bpm(newBpm:Float) {
		if (bpm == newBpm)
			return bpm;

		bpm = newBpm;
		crotchet = ((60 / bpm) * 1000);
		semiquaver = crotchet / denominator;
		return newBpm;
	}
}
