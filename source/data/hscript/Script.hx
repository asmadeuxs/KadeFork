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
		var func = this.interp.variables.get(funcName);
		if (func != null && Reflect.isFunction(func)) {
			try {
				var value = Reflect.callMethod(null, func, args);
				caller = {name: funcName, value: value, caller: func};
				if (caller.value == ScriptLoader.KILL_SCRIPT) {
					this.destroy();
					return caller;
				}
			}
			catch (e:Dynamic) {
				var lineText = 'at unknown line';
				var priorPos = getPosInfos();
				if (Std.isOfType(e, hscript.Expr.Error)) {
					var exprError:hscript.Expr.Error = cast e;
					if (exprError != null)
						lineText = 'at line ' + exprError.line;
				} else if (priorPos != null)
					lineText = 'at line ' + priorPos.lineNumber + ' (call site)';
				Sys.println('Script Error (${this.filePath} $lineText) - $e');
			}
		}
		#end
		return caller;
	}

	public function initVars():Void {}

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
