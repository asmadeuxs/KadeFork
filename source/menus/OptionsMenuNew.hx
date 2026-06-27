package menus;

import data.Option;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath.wrap;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import registry.OptionRegistry;
import ui.FunkinCamera;

using StringTools;
using util.CoolUtil;

class OptionsMenuNew extends flixel.FlxSubState {
	public var cat:Int = 0;
	public var sel:Int = 0;

	public var moveCamera:FunkinCamera;
	public var followObject:FlxObject;

	public var catGroup:FlxTypedGroup<FlxObject>;
	public var optionsGroup:FlxTypedGroup<FlxObject>;
	public var data:OptionRegistry = new OptionRegistry();

	public var curOptions:Array<Option> = null;
	public var cats:Array<String> = null;

	public function new():Void {
		cats = [for (i in data.keys()) i];
		super();

		var bg:FlxSprite = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set(0, 0);
		bg.alpha = 0.0;
		add(bg);

		add(catGroup = new FlxTypedGroup());

		for (i => cat in cats) {
			var catName:String = data.getFromIndex(i).name;
			#if FEATURE_TRANSLATIONS
			var formatted:String = cat.trim().toLowerCase().replace(" ", "_");
			var translated:String = Translator.translateString('options', 'category_$formatted');
			if (translated != 'options:category_$formatted')
				catName = translated;
			#end
			var catText:FlxText = new FlxText(0, 0, 0, catName, 24);
			catText.screenCenter(Y);
			catText.y += (60 * i);
			catText.y -= FlxG.height * 0.25;
			catText.x += 50;
			catGroup.add(catText);
		}

		add(optionsGroup = new FlxTypedGroup());

		add(moveCamera = new FunkinCamera(0, 0, FlxG.width * 0.45, FlxG.height * 0.5));
		moveCamera.antialiasing = true;
		moveCamera.bgColor.alpha = 0;
		FlxG.cameras.add(moveCamera, false);

		add(followObject = new FlxObject());

		FlxTween.tween(bg, {alpha: 0.6}, 0.5, {ease: FlxEase.sineOut});
		moveCamera.follow(followObject, null, 0.60 * (60 / Preferences.user.frameRate));
		reloadCategory();
	}

	override function destroy():Void {
		if (moveCamera != null) {
			FlxG.cameras.remove(moveCamera);
			moveCamera.destroy();
			if (followObject != null)
				followObject.destroy();
		}
		super.destroy();
	}

	public function changeSel(newSel:Int = 0):Void {
		var length:Int = 1;
		if (curOptions != null && curOptions.length > 0)
			length = curOptions.length - 1;
		sel = wrap(sel + newSel, 0, length);
	}

	public function changeCat(newCat:Int = 0):Void {
		var length:Int = 1;
		if (cats != null && cats.length > 0)
			length = cats.length - 1;
		cat = wrap(cat + newCat, 0, length);
	}

	public function reloadCategory() {
		while (optionsGroup.members.length > 0)
			optionsGroup.members.pop().destroy();
		curOptions = data.getFromIndex(cat).options;

		if (curOptions != null)
			return;

		for (i => option in curOptions) {
			var optionName:String = option.name;
			#if FEATURE_TRANSLATIONS
			var prefix:String = option.translationPrefix != null ? option.translationPrefix : "";
			optionName = Translator.translateString('options', prefix + 'option_' + option.variable);
			#end
			var nameText:FlxText = new FlxText(0, 0, 0, optionName, 24);
			var valueText:FlxText = new FlxText(0, 0, 0, option.valueString(), 24);
			nameText.antialiasing = true;
			valueText.antialiasing = true;
			valueText.alignment = RIGHT;
			optionsGroup.add(nameText);
			optionsGroup.add(valueText);
			valueText.ID = i;
			nameText.ID = i;
		}

		changeSel();
	}
}
