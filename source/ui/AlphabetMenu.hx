package ui;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

class AlphabetMenu extends FlxTypedSpriteGroup<Alphabet> {
	public var spacingBetweenItems:Int = 160;
	public var items:Array<String> = null;

	public function new(x:Float, y:Float, ?list:Array<String>):Void {
		super(x, y);
		if (list != null) {
			this.items = list;
			generateMenu();
		}
	}

	public function generateMenu(?customItems:Array<String>):AlphabetMenu {
		var items:Array<String> = (customItems != null && customItems.length != 0) ? customItems : this.items;
		if (items == null || items.length == 0)
			return this;
		for (i in 0...items.length) {
			var entry:Alphabet = new Alphabet(0, (70 * i) + 30, items[i], true, false);
			entry.isMenuItem = true;
			entry.targetY = i;
			add(entry);
		}
		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (members.length != 0) {
			var fps:Int = Preferences.user.frameRate;
			for (i in members) {
				if (i.y < -10 || i.y > FlxG.height) {
					i.active = false;
					i.visible = false;
				} else {
					i.active = true;
					i.visible = true;
				}
				var scaledY = FlxMath.remapToRange(i.targetY, 0, 1, 0, 1.3);
				i.y = FlxMath.lerp(i.y, (scaledY * spacingBetweenItems) + (FlxG.height * 0.48), 0.16 / (fps / 60));
				i.x = FlxMath.lerp(i.x, (i.targetY * 20) + 90, 0.16 / (fps / 60));
			}
		}
	}
}
