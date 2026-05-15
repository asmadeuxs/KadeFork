package;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;

class BootState extends flixel.FlxState {
	function setupTransition() {
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.6, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.3, new FlxPoint(0, 1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
	}

	// This is just a class to initialise variables
	// Preferably only mess with it if you need to do some save-file related stuff
	override function create() {
		setupTransition();
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

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
		FlxG.signals.preStateSwitch.add(() -> {
			if (!Paths.skipNextClear)
				Paths.clearCache();
			Paths.skipNextClear = false;
		});

		#if FREEPLAY
		util.StateOverride.switchState("menus.FreeplayState");
		#elseif CHARTING
		FlxG.switchState(new editor.ChartEditor());
		#else
		FlxG.switchState(Type.createInstance(Main.initialState, []));
		#end
	}
}
