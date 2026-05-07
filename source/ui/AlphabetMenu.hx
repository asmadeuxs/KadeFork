package ui;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

enum abstract LerpingStyle(String) from String to String {
	var DEFAULT = "default";
	var CENTERED = "centered";
}

class AlphabetMenu extends FlxTypedSpriteGroup<Alphabet> {
	public var lerpStyle:String = LerpingStyle.DEFAULT;
	public var spacingBetweenItems:Int = 130;
	public var items:Array<String> = null;

	public function new(x:Float, y:Float, ?list:Array<String>):Void {
		super(x, y);
		if (list != null) {
			this.items = list;
			generateMenu();
		}
	}

	public function generateMenu(?customItems:Array<String>, ?onItemAdded:(Int, Alphabet) -> Void):AlphabetMenu {
		var items:Array<String> = (customItems != null && customItems.length != 0) ? customItems : this.items;
		if (items == null || items.length == 0)
			return this;
		for (i in 0...items.length) {
			var entry:Alphabet = new Alphabet(0, (70 * i) + 30, items[i], true, false);
			entry.targetY = i;
			add(entry);
			if (onItemAdded != null)
				onItemAdded(i, entry);
		}
		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (members.length != 0) {
			for (i in members) {
				if (i.y < -30 || i.y > FlxG.height + 30) {
					i.active = false;
					i.visible = false;
				} else {
					i.active = true;
					i.visible = true;
				}
				var scaledY = FlxMath.remapToRange(i.targetY, 0, 1, 0, 1.3);
				switch lerpStyle {
					case LerpingStyle.CENTERED:
						i.y = FlxMath.lerp(i.y, (scaledY * spacingBetweenItems) + (FlxG.height * 0.48), 0.16);
						i.x = (FlxG.width - i.width) * 0.5;
					case _:
						i.y = FlxMath.lerp(i.y, (scaledY * spacingBetweenItems) + (FlxG.height * 0.48), 0.16);
						i.x = FlxMath.lerp(i.x, (i.targetY * 20) + 90, 0.16);
				}
			}
		}
	}
}
