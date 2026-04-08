package data;

import flixel.FlxG;

// this is just for code formatting.
private enum abstract ScrollType(Int) from Int to Int {
	final UP = 0;
	final DOWN = 1;
}

private enum abstract StrumUnderlayType(Int) from Int to Int {
	final ON_STRUMS = 0;
	final ON_STAGE = 1;
}

@:publicFields class Save { // General Gameplay
	var frameRate:Int = 120; // How many frames per second the game runs at
	var scrollType:Int = ScrollType.UP; // Changes where the notes scroll to
	var centerStrums:Bool = false; // Centers your strums and hides the opponent's
	var ghostTapping:Bool = true; // Lets you mash without penalty
	var noteOffset:Float = 0.0; // By how much should notes be offsetted?
	// Scroll Speed.
	var scrollSpeed:Float = 1.0; // Overrides the chart's scroll speed with your own (applies if it's not set to 1)
	// Visuals & Accessibility
	var strumUnderlay:Bool = false; // Enables a background behind the strums or stage
	var strumUnderlayType:Int = StrumUnderlayType.ON_STRUMS; // Where should the underlay be layered on
	var accuracyDisplay:Bool = true; // Shows Misses and Accuracy in the Score Text
	var showSongPosition:Bool = false; // Shows a progress bar for the song in the HUD
	var showNps:Bool = false; // Shows a NPS counter on the Score Text
	var etternaMode:Bool = true; // Changes the accuracy system to use Wife3

	// I feel like this will be very annoying to implement for Alphabet
	// I do have roughly an idea on how I wanna do it realistically
	// It's like for accent marks (á, à ç, ş, etc) I could like uhhh
	// I could put the accent marks on a separate spritesheet then render them *above* the actual character if it needs to
	// will also be a little bit hard to deal with Cyrillic and the Greek Alphabet and yada yada
	// I'll just make fallbacks for it to just use raw FlxText if it comes down to it
	var language:String = "en";

	/*
	 * Disables some stage visuals such as:
	 *
	 * - Week 2 Thunderstorm (Background is a static image instead of a spritesheet.)
	 * - Week 3 Window Lights (Disables its code.)
	 * - Week 4 Blend Mode (Disables its code, making it look closer to vanilla in the process.)
	 * - Week 5 Background Characters
	 * - Nothing happens in week 6 nothing ever happens.
	 * - Moving objects in Week 7 (excluding the tankmen attacking in Stress)
	 * - Shaders in Weekend 1
	 */
	var lowQualityMode:Bool = false;
	/*
	 * Disables special stage events such as:
	 *
	 * - Thunderstorm Sounds in Week 2
	 * - Train Sounds in Week 3
	 * - Car Sounds in Week 4
	 */
	var distractions:Bool = true;

	public function new():Void {}
}

class Preferences {
	public static final deft:Save = new Save();
	public static var user:Save = new Save();

	public static function setFPSCap(newFramerate:Int) {
		if (newFramerate > FlxG.drawFramerate) {
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		} else {
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

	public static function save() {
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/settings', company);
		for (_ => pref in Reflect.fields(user)) {
			var value:Dynamic = Reflect.field(Preferences.user, pref);
			if (value == null)
				value = Reflect.field(Preferences.deft, pref);
			Reflect.setField(FlxG.save.data, pref, value);
		}
		FlxG.save.flush();
	}

	public static function load() {
		FlxG.autoPause = false;
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/settings', company);
		for (_ => pref in Reflect.fields(user)) {
			var value:Dynamic = Reflect.field(FlxG.save.data, pref);
			if (value == null)
				value = Reflect.field(Preferences.deft, pref);
			Reflect.setField(Preferences.user, pref, value);
		}
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;
		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		Preferences.setFPSCap(Preferences.user.frameRate);
	}
}
