package data;

import flixel.FlxG;
import haxe.io.Path;
import hscript.*;

typedef HScriptFunction = {
	name:String,
	value:Dynamic,
	caller:Dynamic
}

@:structInit @:publicFields class Script {
	var priority:Int = 0;
	var fileName:String = "hscript";
	var filePath:String = null;
	var codeString:String = null;
	var code:Any = null; // fuck if i know.
	var interp:Interp;

	function callFunc(funcName:String, ?args:Array<Dynamic>):HScriptFunction {
		if (args == null)
			args = [];
		var func = this.interp.variables.get(funcName);
		var info = this.interp.posInfos();
		var caller:HScriptFunction = null;
		try {
			if (func != null && Reflect.isFunction(func)) {
				try {
					var value = Reflect.callMethod(null, func, args);
					caller = {name: funcName, value: value, caller: func};
					if (caller.value == ScriptLoader.KILL_SCRIPT) {
						this.destroy();
						return caller;
					}
				}
				catch (e:haxe.Exception)
					trace('Script Error (${this.fileName} at line ${info.lineNumber}) - $e');
			}
		}
		catch (e:Expr.Error)
			trace('Script Error (${this.fileName} at line ${info.lineNumber}) - $e');
		return caller;
	}

	function hasFunction(funcName:String) {
		var func = this.interp.variables.get(funcName);
		return func != null && Reflect.isFunction(funcName);
	}

	function getVar(varname:String)
		this.interp.variables.get(varname);

	function setVar(varname:String, value:Dynamic)
		this.interp.variables.set(varname, value);

	function destroy() {
		code = null;
		interp = null;
		codeString = null;
	}
}

class ScriptLoader {
	public static inline var STOP_FUNC:String = "#HSCRIPT_STOP_FUNC";
	public static inline var CONTINUE_FUNC:String = "#HSCRIPT_CONTINUE_FUNC";
	public static inline var KILL_SCRIPT:String = "#HSCRIPT_KILL_SCRIPT";

	public static final acceptedExtensions:Array<String> = ["hx", "hxc", "hxs"];

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
		interp.variables.set("FlxG", FlxG);
		interp.variables.set("state", FlxG.state);
		// game
		interp.variables.set("Paths", Paths);
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
	 * It's just a way of checking of the file exists.
	 * @param dir String Directory
	 * @param scriptName String Script Name without extensions ("MainMenu" not "MainMenu.hx")
	 * @return String
	 */
	public static function getScriptFile(dir:String, scriptName:String):String {
		var file:String = null;
		if (!Paths.fileExists(dir))
			return "null (Folder not found)";
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
				return script;
			}
			catch (e:haxe.Exception)
				trace('Unexpected script error, ${e.message} (details: ${e.details()})');
		return null;
	}
}
