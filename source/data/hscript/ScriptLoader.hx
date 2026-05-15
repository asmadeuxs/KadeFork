package data.hscript;

import data.hscript.Script;
import flixel.FlxG;
import haxe.io.Path;
import hscript.*;

using StringTools;

class ScriptLoader {
	public static inline var STOP_FUNC:String = "#HSCRIPT_STOP_FUNC";
	public static inline var CONTINUE_FUNC:String = "#HSCRIPT_CONTINUE_FUNC";
	public static inline var KILL_SCRIPT:String = "#HSCRIPT_KILL_SCRIPT";

	public static function findScript(path:String):Script {
		var origin:String = Paths.getAssetOrigin(path);
		var script:Script = loadScript(path);
		return script;
	}

	private static function setDefaultVariables(interp:InterpType, ?mod:String = null) {
		#if FEATURE_HSCRIPT
		// script global
		interp.variables.set("STOP", STOP_FUNC);
		interp.variables.set("CONTINUE", CONTINUE_FUNC);
		interp.variables.set("KILL", KILL_SCRIPT);
		if (mod != null) {
			interp.variables.set("setSetting", (name:String, value:Dynamic) -> return Preferences.setModOption(mod, name, value));
			interp.variables.set("getSetting", (name:String) -> return Preferences.getModOption(mod, name));
			interp.variables.set("_MODNAME", mod);
		}
		// standard library
		interp.variables.set("Math", Math);
		interp.variables.set("Std", Std);
		interp.variables.set("StringTools", StringTools);
		// flixel-specific
		interp.variables.set("FlxG", flixel.FlxG);
		interp.variables.set("FlxSprite", gameplay.FunkinSprite);
		interp.variables.set("FlxColor", new data.hscript.FlxColorWrapper());
		interp.variables.set("state", flixel.FlxG.state);
		// game
		interp.variables.set("Translator", #if FEATURE_TRANSLATIONS data.Locale.current #else null #end);
		interp.variables.set("Preferences", data.Preferences);
		interp.variables.set("CoolUtil", util.CoolUtil);
		interp.variables.set("Paths", util.Paths);
		// other
		interp.variables.set("_GAMEVERSION", Main.versions.BASE_GAME);
		interp.variables.set("_KADEVERSION", Main.versions.KADE);
		interp.variables.set("_FORKVERSION", Main.versions.FORK);
		#end
		return interp;
	}

	/**
	 * Clears every destroyed script from an array of them.
	 */
	public static function clearDestroyed(scripts:Array<Script>):Array<Script> {
		for (s in scripts) {
			if (s.interp == null) {
				if (s.code != null || s.codeString.length != 0)
					s.destroy(); // just ensure its dead
				scripts.remove(s);
			}
		}
		scripts.sort(ScriptLoader.sortByPriority);
		return scripts;
	}

	/**
	 * Returns a script file from the specified directory.
	 *
	 * This mainly exists as a safety-net and you don't need to use it.
	 *
	 * I guess the main benefit is that you won't need to include the extension in the scriptName, but ultimately...
	 *
	 * It's just a way of checking if the file exists.
	 * @param dir String Directory
	 * @param scriptName String Script Name without extensions ("MainMenu" not "MainMenu.hx")
	 * @return String
	 */
	public static function getScriptFile(dir:String, scriptName:String):String {
		var file:String = Path.addTrailingSlash(dir) + scriptName;
		if (!Paths.scriptExtensions.contains(Path.extension(file))) {
			for (ext in Paths.scriptExtensions)
				if (Paths.fileExists('$file.$ext')) {
					file += '.$ext';
					break;
				}
		}
		return file;
	}

	public static function loadScript(filepath:String):Script {
		var script:Script = null;
		#if FEATURE_HSCRIPT
		if (Paths.fileExists(filepath) && Paths.scriptExtensions.contains(Path.extension(filepath))) {
			var origin:String = Paths.getAssetOrigin(filepath);
			script = parseScript(Paths.getText(filepath), null, filepath, origin.substr(0, -1));
			script.fileName = Path.withoutExtension(Path.withoutDirectory(filepath));
			script.filePath = filepath;
			script.interp.execute(script.code);
			// not needed for this case
			// script.priority = script.interp.variables.get("_priority");
		}
		#end
		return script;
	}

	public static function runScriptsAtDir(directory:String, ?sort:Bool = true):Array<Script> {
		var scripts:Array<Script> = null;
		#if FEATURE_HSCRIPT
		if (!Paths.fileExists(directory))
			return scripts;
		var files:Array<String> = Paths.listFiles(directory);
		for (i in 0...files.length) {
			var path:String = Path.addTrailingSlash(directory) + files[i];
			if (Paths.scriptExtensions.contains(Path.extension(path))) {
				if (scripts == null)
					scripts = [];
				var origin:String = Paths.getAssetOrigin(path);
				var p:Script = parseScript(Paths.getText(path), null, path, origin.substr(0, -1));
				p.fileName = Path.withoutExtension(files[i]);
				p.filePath = path;
				p.interp.execute(p.code);
				p.priority = p.getVar("_priority") ?? 0;
				scripts.push(p);
			}
		}
		if (sort)
			scripts.sort(ScriptLoader.sortByPriority);
		#end
		return scripts;
	}

	public static function sortByPriority(a:Script, b:Script)
		return Std.int(a.priority - b.priority);

	private static function parseScript(scriptStr:String, ?interp:InterpType, ?origin:String = 'hscript', ?mod:String = null):Script {
		#if FEATURE_HSCRIPT
		if (scriptStr.length <= 0)
			trace('Cannot load an empty script! (HScript error)');
		else
			try {
				if (interp == null)
					interp = new InterpType();
				setDefaultVariables(interp, mod);
				var parser:Parser = new Parser();
				parser.allowMetadata = true;
				parser.allowTypes = true;
				parser.allowJSON = true;
				var program = parser.parseString(scriptStr, origin);
				var script:Script = {code: program, codeString: scriptStr, interp: interp};
				script.initVars();
				return script;
			}
			catch (e:haxe.Exception)
				trace('Unexpected script error, ${e.message} (details: ${e.details()})');
		#else
		trace('Scripts are not enabled in this build! (HScript error)');
		#end
		return null;
	}
}
