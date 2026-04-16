package data.hscript;

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

	private var _noCache:Bool = false;

	function callFunc(funcName:String, ?args:Array<Dynamic>):HScriptFunction {
		if (args == null)
			args = [];
		var info = this.interp.posInfos();
		var caller:HScriptFunction = null;
		try {
			var func = this.interp.variables.get(funcName);
			if (func != null && Reflect.isFunction(func)) {
				var value = Reflect.callMethod(null, func, args);
				caller = {name: funcName, value: value, caller: func};
				if (caller.value == ScriptLoader.KILL_SCRIPT) {
					this.destroy();
					return caller;
				}
			}
		}
		catch (e:Expr.Error)
			Sys.println('Script Error (${this.fileName} at line ${info.lineNumber}) - $e');
		return caller;
	}

	function getPosInfos()
		return this.interp.posInfos();

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
