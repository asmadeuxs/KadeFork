package registry;

import data.Option;
import util.Mods;

typedef OptionCategory = {
	name:String,
	?type:Int,
	options:Array<Option>
}

class OptionRegistry extends BaseRegistry<OptionCategory> {
	public static var current:OptionRegistry;

	public function new(?withDefaults:Bool = true, ?loadMods:Bool = true):Void {
		super("OptionsRegistry");
		if (withDefaults)
			registerDefaults();
		if (loadMods)
			for (modId in Mods.getEnabled())
				registerModded(modId);
	}

	public function registerModded(mod:String):Void {
		var jsonFile:String = Paths.getJsonPath('data/options', mod);
		if (jsonFile == null) {
			trace('Mod "$mod" has no custom options.');
			return;
		}
		try {
			var modOptions:Dynamic = cast haxe.Json5.parse(Paths.getText(jsonFile));
			var cat:Array<Option> = null;
			if (modOptions != null && modOptions.options != null) {
				var options:Array<Dynamic> = modOptions.options;
				for (d in options) {
					if (d.name == null || d.variable == null)
						continue;
					if (cat == null)
						cat = [];
					cat.push({
						fromMod: mod,
						name: d.name,
						variable: d.variable,
						type: d.type ?? "bool",
						defaultValue: d.defaultValue ?? null,
						description: d.description ?? "No description provided.",
						translationPrefix: d.translationPrefix ?? 'mod_${mod}_',
						numberBoundLeft: d.numberBoundLeft ?? 0.0,
						numberBoundRight: d.numberBoundRight ?? 1.0,
						numberStep: d.numberStep ?? 1.0,
						choices: d.choices ?? null,
						// TODO: setFunc, openSubstate
					});
				}
			}
			if (cat != null && cat.length > 0) {
				var modName:String = Mods.getConfig(mod).name;
				register(modName, {name: modName, options: cat});
			} else
				throw 'No options found in JSON';
		} catch (e:haxe.Exception)
			Sys.println('Cannot register modded options - ${e.details()}');
	}

	public function registerDefaults():Void {
		register("preferences", {
			name: "Preferences",
			options: [
				{
					type: "number",
					name: "Framerate",
					variable: "frameRate",
					description: "How many times the game is updated and drawn to your screen",
					numberStep: 1,
					numberBoundLeft: 30,
					numberBoundRight: 360,
					setFunc: Preferences.setFPSCap
				},
				{
					type: "choice",
					name: "Scroll Type",
					variable: "scrollType",
					description: "Changes where the notes scroll to",
					choices: ["Up", "Down", "Split"],
				},
				{type: "keybind", name: "Note Left", variable: "note_left"},
				{type: "keybind", name: "Note Down", variable: "note_down"},
				{type: "keybind", name: "Note Up", variable: "note_up"},
				{type: "keybind", name: "Note Right", variable: "note_right"},
				{
					name: "Center Strums",
					variable: "centerStrums",
					description: "Centers your strums and hides the opponent's"
				},
				{
					name: "Ghost Tapping",
					description: "Lets you mash without penalty",
					variable: "ghostTapping"
				},
				/*{
					name: "Wife3 Accuracy",
					description: "Changes the accuracy system to use Wife3\nIt's way more complex (math-wise) for the sake of encouraging super accurate hits\nBut may feel mean to newer players",
					variable: "etternaMode"
				},*/
				{
					type: "number",
					name: "Scroll Speed",
					variable: "scrollSpeed",
					description: "Overrides the chart's scroll speed with your own (provided you change Scroll Speed Type below)",
					numberStep: 0.1,
					numberBoundLeft: 0.1,
					numberBoundRight: 10.0
				},
				{
					type: "choice",
					name: "Scroll Speed Type",
					variable: "scrollSpeedType",
					description: "What should the scroll speed setting do?",
					choices: ["Chart", "Additive", "Constant", "BPM-Based"]
				}
			]
		});
		register("other_controls", {
			name: "Other Controls",
			options: [
				{type: "keybind", name: "UI Left", variable: "ui_left"},
				{type: "keybind", name: "UI Down", variable: "ui_down"},
				{type: "keybind", name: "UI Up", variable: "ui_up"},
				{type: "keybind", name: "UI Right", variable: "ui_right"},
				{type: "keybind", name: "Accept/Forward", variable: "ui_accept"},
				{type: "keybind", name: "Cancel/Backward", variable: "ui_back"},
			]
		});
		register("visuals", {
			name: "Visuals",
			options: [
				#if FEATURE_TRANSLATIONS
				{
					name: "Language",
					description: "Changes the game's text interfaces to be on a different language",
					variable: "language",
					type: "choice",
					choices: Translator.getAvailableLanguageIDs()
				},
				#end
				{
					name: "Low Quality",
					description: "Disables certain background effects to increase loading times (and in some cases, performance.)",
					variable: "lowQualityMode"
				},
				{
					name: "HUD Style",
					description: "Changes the style of the HUD.\n\"Detailed\" being the default",
					choices: gameplay.hud.BaseHUD.listHUDs(),
					translationPrefix: "hud_",
					variable: "hudStyle",
					type: "choice"
				},
				{
					name: "Show Miss Combo",
					description: "Displays miss popups with negative combo when you miss notes",
					variable: "showMissPopups"
				},
				{
					name: "Show Song Position",
					description: "Shows a progress bar for the song in the HUD",
					variable: "showSongPosition"
				},
				{
					name: "Show Judgement Counts",
					description: "Shows a judgement counter during gameplay on the left side of the screen",
					variable: "showJudgeCounts"
				},
				{
					name: "Notes per Second",
					description: "Shows a NPS counter on the Score Text",
					variable: "showNps"
				},
				{
					name: "Note Splashes",
					description: "Hitting a sick and above spawns a funny splash that gives you a boner", // thanks josh -asmadeuxs
					variable: "noteSplashes",
				},
				{
					name: "Distractions",
					description: "Disables certain sounds and effects that may be distracting",
					variable: "distractions"
				},
				{
					type: "number",
					name: "Interface Dim",
					description: "Enables a background behind the strums or stage",
					variable: "strumUnderlay",
					// displayStyle: "{}%",
					numberStep: 1.0,
					numberBoundLeft: 0,
					numberBoundRight: 100
				},
				{
					name: "Dim Type",
					description: "Where should the underlay be layered on",
					variable: "strumUnderlayType",
					choices: ["Strums", "Stage"],
					type: "choice",
				}
			]
		});
	}
}
