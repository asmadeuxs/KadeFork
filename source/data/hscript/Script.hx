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
	@:optional var priority:Int = 0;
	var fileName:String = "hscript";
	var filePath:String = null;
	var codeString:String = null;
	var code:Any = null; // fuck if i know.
	var interp:Interp;

	function callFunc(funcName:String, ?args:Array<Dynamic>):HScriptFunction {
		var caller:HScriptFunction = null;
		if (this.interp == null) {
			Sys.println('Script Error (${this.fileName}) - The script interpret is null (destroyed? value is: $interp)');
			return caller;
		}

		if (args == null)
			args = [];
		var info = this.interp.posInfos();
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

	function getPosInfos():haxe.PosInfos
		return this.interp.posInfos();

	function hasVar(varname:String):Bool
		return getVar(varname) != null;

	function getVar(varname:String):Dynamic
		return this.interp != null && this.interp.variables != null ? this.interp.variables.get(varname) : null;

	function setVar(varname:String, value:Dynamic):Dynamic {
		if (this.interp != null && this.interp.variables != null)
			this.interp.variables.set(varname, value);
		return getVar(varname);
	}

	function destroy():Void {
		code = null;
		interp = null;
		codeString = null;
	}
}
