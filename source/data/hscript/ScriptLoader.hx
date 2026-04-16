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

	// just a little something so we can reuse scripts instead of loading a new one that is identical to an older one.
	// this is mainly useful for note scripts, not so much for gameplay scripts and whatnot
	public static var scriptCache:Map<String, Script> = [];

	public static final acceptedExtensions:Array<String> = ["hx", "hxc", "hxs"];

	public static function findScript(path:String, ?noCache:Bool = false):Script {
		var origin:String = Paths.getAssetOrigin(path);
		var script = scriptCache.get(origin + path);
		if (script != null && @:privateAccess script._noCache)
			removeScriptFromCache(script);
		script = loadScript(path);
		@:privateAccess script._noCache = noCache;
		scriptCache.set(origin + path, script);
		return script;
	}

	public static function removeScriptFromCachedPath(path:String, ?destroyScript:Bool = true):Script {
		var script:Script = null;
		for (key in scriptCache.keys()) {
			if (key == path) {
				script = scriptCache.get(key);
				scriptCache.remove(key);
				if (destroyScript)
					script.destroy();
			}
		}
		return script;
	}

	public static function removeScriptFromCache(script:Script, ?destroyScript:Bool = true):Script {
		for (key in scriptCache.keys()) {
			var target = scriptCache.get(key);
			if (target == script) {
				scriptCache.remove(key);
				if (destroyScript)
					script.destroy();
			}
		}
		return script;
	}

	private static function makeInterpreter() {
		var interp = new Interp();
		// script global
		interp.variables.set("STOP", STOP_FUNC);
		interp.variables.set("CONTINUE", CONTINUE_FUNC);
		interp.variables.set("KILL", KILL_SCRIPT);
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
		interp.variables.set("Preferences", data.Preferences);
		interp.variables.set("CoolUtil", util.CoolUtil);
		interp.variables.set("Paths", util.Paths);

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
		scripts.sort(function(a, b) return Std.int(a.priority - b.priority));
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
		var file:String = null;
		if (Paths.fileExists(dir)) {
			// file already the extension so leave early
			if (acceptedExtensions.contains(Path.extension(scriptName)))
				file = Path.addTrailingSlash(dir) + scriptName;
			else { // find a file with a script extension
				for (i in Paths.listFiles(dir)) {
					var full:String = Path.addTrailingSlash(dir) + i;
					if (acceptedExtensions.contains(Path.extension(i))) {
						file = full;
						break;
					}
				}
			}
		}
		trace(file);
		return file;
	}

	public static function loadScript(filepath:String):Script {
		var script:Script = null;
		if (Paths.fileExists(filepath)) {
			if (acceptedExtensions.contains(Path.extension(filepath))) {
				script = parseScript(Paths.getText(filepath));
				script.fileName = Path.withoutExtension(Path.withoutDirectory(filepath));
				script.filePath = filepath;
				script.interp.execute(script.code);
				// not needed for this case
				// script.priority = script.interp.variables.get("priority");
			}
		}
		return script;
	}

	public static function runScriptsAtDir(directory:String):Array<Script> {
		var scripts:Array<Script> = null;
		var files:Array<String> = Paths.listFiles(directory);
		for (i in 0...files.length) {
			var path:String = Path.addTrailingSlash(directory) + files[i];
			if (acceptedExtensions.contains(Path.extension(path))) {
				if (scripts == null)
					scripts = [];
				var p:Script = parseScript(Paths.getText(path));
				p.fileName = Path.withoutExtension(files[i]);
				p.filePath = path;
				p.interp.execute(p.code);
				p.priority = p.interp.variables.get("_priority");
				scripts.push(p);
			}
		}
		scripts.sort(function(a, b) return Std.int(a.priority - b.priority));
		return scripts;
	}

	private static function parseScript(scriptStr:String, ?customInterp:Interp):Script {
		if (scriptStr.length <= 0)
			trace('Cannot load an empty script! (HScript error)');
		else
			try {
				var parser:Parser = new Parser();
				parser.allowMetadata = true;
				parser.allowTypes = true;
				parser.allowJSON = true;
				var program = parser.parseString(scriptStr);
				var script:Script = {
					code: program,
					codeString: scriptStr,
					interp: customInterp == null ? makeInterpreter() : customInterp,
					priority: 0,
				};
				script.setVar("trace", function(v:Dynamic) trace(v, {
					fileName: script.fileName,
					lineNumber: script.getPosInfos(),
				}));
				return script;
			}
			catch (e:haxe.Exception) {
				trace('Unexpected script error, ${e.message} (details: ${e.details()})');
			}
		return null;
	}
}
