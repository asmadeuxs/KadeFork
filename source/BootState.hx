package;

import flixel.FlxG;

class BootState extends flixel.FlxState {
	// This is just a class to initialise variables
	// Preferably only mess with it if you need to do some save-file related stuff
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
		new Controls(Controls.defaultActions.copy());
		data.Preferences.load();
		data.Highscore.load();
		util.Mods.loadMods();
		util.Mods.scan(true);
		// yes we're calling them levels and not weeks
		// they call it levels in base game so we will call it levels here -asmadeuxs
		var levelRegistry = new registry.LevelRegistry();
		for (id in util.Mods.getEnabled())
			levelRegistry.loadLevels(id);
		levelRegistry = null;
		lime.app.Application.current.onExit.add(function(e:Int) {
			data.Preferences.save();
			util.Mods.saveMods();
		});
		#if FEATURE_TRANSLATIONS
		new data.Locale(Preferences.user.language);
		#end
		util.Mods.saveMods();
		// this is not great but it, its fine for now.
		FlxG.signals.preStateSwitch.add(() -> Paths.clearCache());

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
		#elseif CHARTING
		FlxG.switchState(new editor.ChartEditor());
		#else
		FlxG.switchState(Type.createInstance(Main.initialState, []));
		#end
	}
}
