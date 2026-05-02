package data.hscript;

import flixel.FlxG;
import haxe.io.Path;

typedef HScriptFunction = {
	name:String,
	value:Dynamic,
	caller:Dynamic
}

typedef InterpType = #if FEATURE_HSCRIPT hscript.Interp #else Any #end;

@:structInit @:publicFields class Script {
	@:optional var priority:Int = 0;
	var fileName:String = "hscript";
	var filePath:String = null;
	var codeString:String = null;
	var code:Any = null; // fuck if i know.
	var interp:InterpType;

	function callFunc(funcName:String, ?args:Array<Dynamic>):HScriptFunction {
		var caller:HScriptFunction = null;
		#if FEATURE_HSCRIPT
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
		catch (e)
			Sys.println('Script Error (${this.fileName} at line ${info.lineNumber}) - $e');
		#end
		return caller;
	}

	public function initVars():Void {
		if (interp != null && interp.variables != null) {
			interp.variables.set("trace", function(...args:Array<Dynamic>) {
				var pos:haxe.PosInfos = getPosInfos();
				var line:Int = pos.lineNumber + 1;
				var message:String = [for (a in args) Std.string(a)].join(" ");
				Sys.println('[$fileName:$line] $message');
			});
		}
	}

	function getPosInfos():haxe.PosInfos
		return #if FEATURE_HSCRIPT this.interp.posInfos() #else null #end;

	function hasVar(varname:String):Bool
		return getVar(varname) != null;

	function getVar(varname:String):Dynamic {
		#if FEATURE_HSCRIPT
		return this.interp != null && this.interp.variables != null ? this.interp.variables.get(varname) : null;
		#else
		return null;
		#end
	}

	function setVar(varname:String, value:Dynamic):Dynamic {
		#if FEATURE_HSCRIPT
		if (this.interp != null && this.interp.variables != null)
			this.interp.variables.set(varname, value);
		#end
		return getVar(varname);
	}

	function destroy():Void {
		code = null;
		interp = null;
		codeString = null;
	}
}
