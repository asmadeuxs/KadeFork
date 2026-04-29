package data;

import flixel.math.FlxMath.wrap;

using StringTools;

/*enum Option
	{
	Checkmark;
	Number(min:Float, max:Float, step:Float),
	Choice(choices:Array<String>)
}*/
@:structInit class Option {
	@:optional public var setFunc:(value:Dynamic) -> Void;

	public var name:String = null;
	public var description:String = null;
	public var variable:String = null;
	@:optional public var type:String = "bool";

	// For numbers
	@:optional public var numberStep:Float = 1.0;
	@:optional public var numberBoundLeft:Float = 0.0;
	@:optional public var numberBoundRight:Float = 1.0;

	// For choices
	@:optional public var choices:Array<String> = [];

	/*public function new(name:String, ?type:String = "bool", ?description:String):Void
		{
			this.name = name;
			this.type = validateType(type);
			this.description = description;
	}*/
	//
	public function valueString():String {
		var value:Dynamic = Reflect.field(Preferences.user, this.variable);
		var str:String = switch validateType(this.type) {
			case "checkmark": value == true ? "ON" : "OFF";
			case "number": Std.string(value);
			case "choice": (value is Int) ? choices[value] : Std.string(value);
			case "keybind": Std.string(Controls.current.actions.get(this.variable)[0]);
			case _: Std.string(value);
		};
		#if FEATURE_TRANSLATIONS
		if (variable == 'language')
			str = Translator.getNativeLangName(str);
		else {
			var transStr:String = 'optionval_$str';
			var translated:String = Translator.translateString(transStr);
			if (translated != transStr)
				str = translated;
		}
		#end
		return str;
	}

	public function validateType(type:String):String {
		return switch type.toLowerCase().trim() {
			case "float", "number", "int": "number";
			case "list", "map", "array", "choice": "choice";
			case "control", "key", "keybind": "keybind";
			case _: "checkmark";
		}
	}

	public function change(byThisMuch:Int = 0):Dynamic {
		var value:Dynamic = Reflect.field(Preferences.user, this.variable);
		switch validateType(this.type) {
			case "checkmark":
				if (byThisMuch != 0)
					Reflect.setField(Preferences.user, this.variable, !value);
			case "number":
				var newVal = value + this.numberStep * byThisMuch;
				newVal = Math.min(this.numberBoundRight, Math.max(this.numberBoundLeft, newVal));
				Reflect.setField(Preferences.user, this.variable, newVal);
			case "choice":
				if (Std.isOfType(value, Int)) {
					var newValue:Int = wrap(value + byThisMuch, 0, choices.length - 1);
					Reflect.setField(Preferences.user, this.variable, newValue);
				} else {
					var index:Int = 0;
					for (i in 0...choices.length)
						if (choices[i] == value) {
							index = i;
							break;
						}
					index = wrap(index + byThisMuch, 0, choices.length - 1);
					Reflect.setField(Preferences.user, this.variable, choices[index]);
				}
		}
		if (setFunc != null)
			setFunc(Reflect.field(Preferences.user, this.variable));
		return value;
	}
}
