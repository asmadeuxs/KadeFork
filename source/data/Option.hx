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
	public static final supportedOptionTypes:Array<String> = [
		// Boolean
		"bool",
		"toggle",
		"checkmark",
		"checkbox",
		// Number
		"float",
		"number",
		"int",
		"list",
		// List
		"map",
		"array",
		"choice"
	];

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
		switch validateType(this.type) {
			case "checkmark":
				return value == true ? "ON" : "OFF";
			case "number":
				return Std.string(value);
			case "choice":
				if (value is Int)
					return choices[value];
				else
					return Std.string(value); // probably already a string
			case _:
				return Std.string(value);
		}
	}

	public function validateType(type:String):String {
		return switch type.toLowerCase().trim() {
			case "float", "number", "int": "number";
			case "list", "map", "array", "choice": "choice";
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
