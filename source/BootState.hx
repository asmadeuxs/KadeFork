package;

import flixel.FlxG;

// This is just a class to initialise variables
// Preferably only mess with it if you need to do some save-file related stuff
class BootState extends flixel.FlxState {
	override function create() { // new controls system
		new Controls(Controls.defaultActions.copy());
		/*\#if sys
			if (!sys.FileSystem.exists(Sys.getCwd() + "/assets/replays"))
				sys.FileSystem.createDirectory(Sys.getCwd() + "/assets/replays");
			#end */
		#if discord_rpc
		DiscordClient.initialize();
		Application.current.onExit.add(function(exitCode) DiscordClient.shutdown());
		#end

		data.Preferences.load();
		data.Highscore.load();

		Preferences.setFPSCap(Preferences.user.frameRate);

		/* // we're just gonna rewrite story mode altogether,
			// the current one is genuinely hell to work with and was basically unmaintained -asmadeuxs
			if (FlxG.save.data.weekUnlocked != null) { // FIX LATER!!!
				// WEEK UNLOCK PROGRESSION!!
				// StoryMenuState.weekUnlocked = FlxG.save.data.weekUnlocked;
				if (StoryMenuState.weekUnlocked.length < 4)
					StoryMenuState.weekUnlocked.insert(0, true);
				// QUICK PATCH OOPS!
				if (!StoryMenuState.weekUnlocked[0])
					StoryMenuState.weekUnlocked[0] = true;
		}*/
		#if FREEPLAY
		FlxG.switchState(new menus.FreeplayState());
		#else
		FlxG.switchState(Type.createInstance(Main.initialState, []));
		#end
	}
}
