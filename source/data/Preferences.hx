package data;

import Controls.ActionMap;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import util.Mods;

@:publicFields class Save {
	// General Gameplay
	var keybinds:ActionMap = Controls.defaultActions.copy();
	var frameRate:Int = 120; // How many frames per second the game runs at
	var scrollType:Int = 0; // Changes where the notes scroll to
	var centerStrums:Bool = false; // Centers your strums and hides the opponent's
	var ghostTapping:Bool = true; // Lets you mash without penalty
	var noteOffset:Float = 0.0; // By how much should notes be offsetted?
	var scrollSpeed:Float = 1.0; // Overrides the chart's scroll speed with your own (provided you change Scroll Speed Type below)
	var scrollSpeedType:Int = 0; // What should the scroll speed setting do?
	var etternaMode:Bool = true; // Changes the accuracy system to use Wife3

	// Visuals & Accessibility
	var strumUnderlay:Int = 0; // Enables a background behind the strums or stage (goes from 0 - 100)
	var strumUnderlayType:Int = 0; // Where should the underlay be layered on
	var noteSplashes:Bool = false; // Shows a funny note splash that gives you a boner
	var skipTransitions:Bool = false; // Skips transitions between screens

	// HUD
	var hudStyle:String = "Detailed"; // Changes the style of the HUD
	var showSongPosition:Bool = false; // Shows a progress bar for the song in the HUD
	var showNps:Bool = false; // Shows a NPS counter on the Score Text
	var showJudgeCounts:Bool = true; // Displays a judgement counter during gameplay on the left side of the screen
	var showMissPopups:Bool = true; // Displays miss popups when you miss notes

	// OTHER VISUALS
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

	public static function save(?saveName:String = 'settings') {
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/$saveName', company);

		for (_ => pref in Reflect.fields(user)) {
			var value:Dynamic = Reflect.field(Preferences.user, pref);
			if (value == null)
				value = Reflect.field(Preferences.deft, pref);
			Reflect.setField(FlxG.save.data, pref, value);
		}

		var saveModOptions:Dynamic = {};
		for (mod => options in modOptions) {
			var modObj:Dynamic = {};
			for (opt => val in options) {
				Reflect.setField(modObj, opt, val);
			}
			Reflect.setField(saveModOptions, mod, modObj);
		}
		FlxG.save.data.modOptions = saveModOptions;
		FlxG.save.flush();
	}

	public static function load(?saveName:String = 'settings') {
		FlxG.autoPause = false;
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/$saveName', company);

		for (_ => pref in Reflect.fields(user)) {
			var value:Dynamic = Reflect.field(FlxG.save.data, pref);
			if (value == null)
				value = Reflect.field(Preferences.deft, pref);
			Reflect.setField(user, pref, value);
		}

		var savedModOptions = FlxG.save.data.modOptions;
		if (savedModOptions != null) {
			for (mod in Reflect.fields(savedModOptions)) {
				var modData = Reflect.field(savedModOptions, mod);
				if (modData != null) {
					var optMap:Map<String, Dynamic> = new Map();
					for (opt in Reflect.fields(modData)) {
						optMap.set(opt, Reflect.field(modData, opt));
					}
					modOptions.set(mod, optMap);
				}
			}
		}

		loadKeybinds();
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;
		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		Preferences.setFPSCap(Preferences.user.frameRate);
		migrateSave();
	}

	public static function migrateSave():Void {
		// To migrate options from older version of the fork
		// Not useful if you have a completely clean save
		if (FlxG.save.data.accuracyDisplay != null) {
			var inf:Bool = FlxG.save.data.accuracyDisplay;
			Preferences.user.hudStyle = inf ? "Detailed" : "Classic";
			FlxG.save.data.hudStyle = Preferences.user.hudStyle;
			FlxG.save.data.accuracyDisplay = null;
		}
	}

	public static function loadKeybinds():Void {
		for (action in Preferences.user.keybinds.keys()) {
			var userKeys = Preferences.user.keybinds.get(action);
			if (!Controls.current.actions.exists(action))
				Controls.current.actions.set(action, []);
			for (i in 0...userKeys.length)
				Controls.current.actions.get(action)[i] = userKeys[i];
		}
	}

	private static var modOptions:Map<String, Map<String, Dynamic>> = new Map();

	public static function setFPSCap(newFramerate:Int) {
		if (newFramerate > FlxG.drawFramerate) {
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		} else {
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

	public static function getModOption(mod:String, option:String):Dynamic {
		var v:Dynamic = null;
		if (modOptions[mod] != null && modOptions[mod].get(option) != null)
			v = modOptions[mod].get(option);
		return v;
	}

	public static function setModOption(mod:String, option:String, value:Dynamic):Void {
		if (modOptions.get(mod) == null)
			modOptions.set(mod, new Map());
		modOptions[mod].set(option, value);
		if (FlxG.save.data.modOptions == null)
			FlxG.save.data.modOptions = {};
		var modData = FlxG.save.data.modOptions;
		if (!Reflect.hasField(modData, mod))
			Reflect.setField(modData, mod, {});
		Reflect.setField(Reflect.field(modData, mod), option, value);
		FlxG.save.flush();
	}
}
