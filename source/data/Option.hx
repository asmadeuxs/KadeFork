package data;

import flixel.math.FlxMath.wrap;

using StringTools;

@:structInit class Option {
	public var name:String = null;
	public var description:String = null;
	public var variable:String = null;

	@:optional public var setFunc:(value:Dynamic) -> Void;
	@:optional public var openSubstate:Void->Void;

	@:optional public var translationString:String = null;
	@:optional public var type:String = "bool";

	@:optional public var fromMod:String = null;
	@:optional public var defaultValue:Dynamic = null;

	// For numbers
	@:optional public var numberStep:Float = 1.0;
	@:optional public var numberBoundLeft:Float = 0.0;
	@:optional public var numberBoundRight:Float = 1.0;

	// For choices
	@:optional public var choices:Array<String> = null;

	public function valueString():String {
		var value:Dynamic = getValue();
		var str:String = switch validateType(this.type) {
			case "checkmark": value == true ? "ON" : "OFF";
			case "number": Std.string(value);
			case "choice": (value is Int) ? choices[value] : Std.string(value);
			case "keybind": Std.string(Controls.current.actions.get(this.variable)[0]);
			case "substate": "[OPEN]";
			case _: Std.string(value);
		};
		#if FEATURE_TRANSLATIONS
		if (variable == 'language')
			str = Translator.getNativeLangName(str);
		else {
			var prefix:String = '';
			if (translationString != null)
				prefix = translationString;
			var transStr:String = 'optionval_';
			// just so if mod options fail to bring a string
			var noPrefix:String = Translator.translateString('options', '$transStr$str');
			var translated:String = Translator.translateStringDefault('options', prefix + '$transStr$str', noPrefix);
			if (!translated.contains(transStr))
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
			case "menu", "substate": "substate";
			case _: "checkmark";
		}
	}

	public function getValue() {
		var value:Dynamic = null;
		if (this.fromMod != null) {
			value = Preferences.getModOption(this.fromMod, this.variable);
			if (value == null) {
				if (defaultValue != null)
					value = defaultValue;
				else
					value = switch validateType(this.type) {
						case "choice": choices[0];
						case "number": 0.0;
						case "bool": false;
						case _: defaultValue;
					}
			}
		} else
			value = Reflect.field(Preferences.user, this.variable);
		return value;
	}

	public function change(byThisMuch:Int = 0):Dynamic {
		var value:Dynamic = getValue();
		switch validateType(this.type) {
			case "checkmark":
				if (byThisMuch != 0)
					if (this.fromMod != null)
						Preferences.setModOption(this.fromMod, this.variable, !value);
					else
						Reflect.setField(Preferences.user, this.variable, !value);
			case "number":
				var newValue = value + this.numberStep * byThisMuch;
				newValue = Math.min(this.numberBoundRight, Math.max(this.numberBoundLeft, newValue));
				if (this.fromMod != null)
					Preferences.setModOption(this.fromMod, this.variable, newValue);
				else
					Reflect.setField(Preferences.user, this.variable, newValue);
			case "choice":
				if (Std.isOfType(value, Int)) {
					var newValue:Int = wrap(value + byThisMuch, 0, choices.length - 1);
					if (this.fromMod != null)
						Preferences.setModOption(this.fromMod, this.variable, newValue);
					else
						Reflect.setField(Preferences.user, this.variable, newValue);
				} else {
					var index:Int = 0;
					for (i in 0...choices.length)
						if (choices[i] == value) {
							index = i;
							break;
						}
					index = wrap(index + byThisMuch, 0, choices.length - 1);
					if (this.fromMod != null)
						Preferences.setModOption(this.fromMod, this.variable, choices[index]);
					else
						Reflect.setField(Preferences.user, this.variable, choices[index]);
				}
		}
		if (setFunc != null)
			setFunc(Reflect.field(Preferences.user, this.variable));
		return value;
	}
}
