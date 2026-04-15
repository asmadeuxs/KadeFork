package;

import flixel.FlxG;

// This is just a class to initialise variables
// Preferably only mess with it if you need to do some save-file related stuff
class BootState extends flixel.FlxState {
	override function create() {
		/*\#if sys
			if (!sys.FileSystem.exists(Sys.getCwd() + "/assets/replays"))
				sys.FileSystem.createDirectory(Sys.getCwd() + "/assets/replays");
			#end */
		#if hxdiscord_rpc
		DiscordClient.initialize();
		lime.app.Application.current.onExit.add(function(exitCode) DiscordClient.shutdown());
		#end

		// init user settings and scores
		data.Preferences.load();
		data.Highscore.load();
		Preferences.setFPSCap(Preferences.user.frameRate);
		// init other data
		new Controls(Controls.defaultActions.copy());

		util.Mods.scan(true);
		// yes we're calling them levels and not weeks
		// they call it levels in base game so we will call it levels here -asmadeuxs
		var registry = new registry.LevelRegistry();
		var cats = util.Mods.getEnabled();
		if (cats[0] != "core")
			cats.insert(0, "core");
		for (id in cats)
			registry.loadLevels(id);

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
