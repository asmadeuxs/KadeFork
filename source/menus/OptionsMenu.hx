package menus;

import data.Option;
import data.Preferences;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.events.KeyboardEvent;
import registry.OptionRegistry;
import ui.FunkinCamera;

using flixel.util.FlxSpriteUtil;
using util.CoolUtil;

// I JUST MADE SOME BULLLLLLLLLLLLLLLLLLSHIT -asmadeuxs
class OptionsMenu extends MusicBeatSubstate {
	var optionStash:OptionRegistry = new OptionRegistry();
	var curCatOptions:Array<Option> = null;

	var curSelected:Int = 0;
	var catSelected:Int = 0;

	var catNameText:FlxText;
	var descriptionThingy:FlxText;
	var catOptions:FlxTypedSpriteGroup<FlxText>;
	var catFrame:FlxSprite;

	var camScroll:FunkinCamera;
	var camFollow:FlxObject;
	var optionsFont = Paths.font("vcr.ttf");
	var binding:Bool = false;

	override function create():Void {
		super.create();
		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		#if FEATURE_TRANSLATIONS
		for (cat in optionStash.keys())
			for (i in optionStash.get(cat).options)
				if (i.variable == 'language')
					i.setFunc = onLanguageChanged;
		#end

		var bgCover:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		bgCover.scale.set(FlxG.width, FlxG.height);
		bgCover.scrollFactor.set();
		bgCover.updateHitbox();
		bgCover.alpha = 0.8;
		add(bgCover);

		var header:FlxText = new FlxText(0, 30, FlxG.width, "[ Options ]");
		header.setFormat(optionsFont, 32, 0xFF808080, CENTER);
		header.scrollFactor.set();
		add(header);

		catNameText = new FlxText(0, header.y + 30, FlxG.width, "Cat");
		catNameText.setFormat(optionsFont, 24, FlxColor.WHITE, CENTER);
		catNameText.scrollFactor.set();
		add(catNameText);

		var panelWidth:Int = Std.int(FlxG.width * 0.45);
		var panelHeight:Int = Std.int(FlxG.height * 0.5);

		catFrame = new FlxSprite(0, 50).makeScaledGraphic(panelWidth, panelHeight, 0xFF000000);
		catFrame.scrollFactor.set();
		catFrame.updateHitbox();
		catFrame.screenCenter();
		add(catFrame);

		camScroll = new FunkinCamera(catFrame.x, catFrame.y, panelWidth, panelHeight);
		camScroll.antialiasing = true;
		camScroll.bgColor.alpha = 0;
		FlxG.cameras.add(camScroll, false);

		camFollow = new FlxObject();
		camScroll.follow(camFollow, null, 0.60 * (60 / Preferences.user.frameRate));
		add(camFollow);

		catOptions = new FlxTypedSpriteGroup<FlxText>();
		catOptions.scrollFactor.set(0, 0.8);
		catOptions.camera = camScroll;
		add(catOptions);

		descriptionThingy = new FlxText(catFrame.x, 0, catFrame.width, "");
		descriptionThingy.textField.backgroundColor = 0x80000000;
		descriptionThingy.setFormat(optionsFont, 24, CENTER);
		descriptionThingy.textField.background = true;
		descriptionThingy.y = (FlxG.height - descriptionThingy.height) - 5;
		descriptionThingy.scrollFactor.set();
		descriptionThingy.screenCenter(X);
		add(descriptionThingy);

		updateCat();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, setKeybind);
	}

	var closing:Bool = false;
	var keyTimer:Float = 1.0;
	var bindTimer:Float = 0.0;

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (closing)
			return;
		if (bindTimer > 0.0)
			bindTimer -= 0.1;
		if (binding)
			return;
		var up:Bool = controls.UP_P;
		if (up || controls.DOWN_P)
			changeSelection((up ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 5 : 1));
		// I genuinely hate this entire block of code and I'll probably change it later on -asmadeuxs
		var curOption:Option = curCatOptions[curSelected];
		if (controls.ACCEPT_P && curOption.type == 'keybind') {
			catOptions.members[curSelected * 2 + 1].text = '(PRESS ANY KEY)';
			bindTimer = 1.0;
			binding = true;
			return;
		}

		var leftp:Bool = controls.LEFT_P;
		var rightp:Bool = controls.RIGHT_P;
		// choice options
		if (curOption.type != "keybind") {
			if ((leftp || rightp) && curOption.type != "number")
				changeOption(leftp ? -1 : 1);
			// number options
			var lefth:Bool = controls.LEFT;
			var righth:Bool = controls.RIGHT;
			if ((leftp || rightp || lefth || righth) && curOption.type == "number") {
				var change:Bool = false;
				if (leftp || rightp)
					change = true;
				else if (lefth || righth) {
					// TODO: implement keyRepeat in Controls so I don't have to do this shit manually -asmadeuxs
					keyTimer += 0.1;
					if (keyTimer >= 1.0) {
						change = true;
						keyTimer = 0.0;
					}
				}
				if (change) {
					var inc:Int = FlxG.keys.pressed.SHIFT ? 4 : 1;
					var left:Bool = leftp || lefth;
					changeOption(left ? -inc : inc);
				}
			} else if (controls.LEFT_R || controls.RIGHT_R)
				keyTimer = 0.0;
		}
		// rest of the controls
		var leftCat:Bool = FlxG.keys.justPressed.Q;
		if (leftCat || FlxG.keys.justPressed.E) {
			catSelected = flixel.math.FlxMath.wrap(catSelected + (leftCat ? -1 : 1), 0, optionStash.length - 1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateCat();
		}
		if (controls.BACK_P) {
			closing = true;
			close();
			Preferences.save();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			new flixel.util.FlxTimer().start(0.5, (_) -> {
				if (FlxG.state is MainMenuState) {
					var menu:MainMenuState = cast FlxG.state;
					menu.tweenItemsBackIn();
					menu.canInput = true;
					menu = null;
				} else if (FlxG.state is gameplay.PlayState) {
					var play:gameplay.PlayState = cast FlxG.state;
					play.onSettingsChanged();
					play = null;
				}
				// i don't like this conditional
				if (FlxG.state != null && FlxG.state.subState != null) {
					FlxG.state.subState.persistentDraw = true;
					FlxG.state.subState.persistentUpdate = false;
				}
			});
		}
		updateScroll();
	}

	override function destroy():Void {
		if (camScroll != null)
			camScroll.destroy();
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, setKeybind);
		FlxG.cameras.remove(camScroll);
		Preferences.loadKeybinds();
		super.destroy();
	}

	public function setKeybind(key:KeyboardEvent):Void {
		if (!binding)
			return;
		if (bindTimer > 0.0)
			return;
		if (key.keyCode == FlxKey.ESCAPE) {
			binding = false;
			return;
		}
		var curOption:Option = curCatOptions[curSelected];
		if (!Controls.current.actions.exists(curOption.variable))
			Controls.current.actions.set(curOption.variable, []);
		Preferences.user.keybinds.get(curOption.variable)[0] = key.keyCode;
		Controls.current.actions.get(curOption.variable)[0] = key.keyCode;
		catOptions.members[curSelected * 2 + 1].text = curOption.valueString();
		changeOption();
		binding = false;
	}

	public function changeOption(by:Int = 0, ?playSound:Bool = true) {
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));
		curCatOptions[curSelected].change(by);

		var curOption:Option = curCatOptions[curSelected];
		var val:FlxText = catOptions.members[curSelected * 2 + 1];
		if (curOption.type != "keybind")
			val.text = curOption.valueString();
	}

	public function changeSelection(next:Int = 0, ?playSound:Bool = true) {
		curSelected = flixel.math.FlxMath.wrap(curSelected + next, 0, curCatOptions.length - 1);
		if (next != 0 && playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		if (catOptions.members.length > 0)
			for (entry in catOptions)
				entry.alpha = entry.ID == curSelected ? 1.0 : 0.6;
		if (curCatOptions != null) {
			#if FEATURE_TRANSLATIONS
			var prefix:String = "";
			var option = curCatOptions[curSelected];
			if (option.translationString != null)
				prefix = option.translationString;
			descriptionThingy.text = Translator.translateString('options', prefix + 'optiondesc_${option.variable}');
			#else
			descriptionThingy.text = option.description;
			#end
			descriptionThingy.y = catFrame.y + catFrame.height + 10;
		}
	}

	public function updateScroll() {
		var scrollOffset:Float = 140;
		camFollow.y = catOptions.members[curSelected].y + scrollOffset;
	}

	public function updateCat() {
		while (catOptions.members.length > 0)
			catOptions.members.pop().destroy();
		var curCat = optionStash.getFromIndex(catSelected);
		curCatOptions = curCat.options;
		if (curSelected < 0 || curSelected > curCatOptions.length - 1)
			curSelected = 0;
		if (catNameText != null)
			catNameText.text = 'Viewing: ${curCat.name}\nPress Q/E to change category\nPress Left/Right to change option';

		for (i => option in curCatOptions) {
			var optionName:String = option.name;
			#if FEATURE_TRANSLATIONS
			var prefix:String = option.translationString != null ? option.translationString : "";
			optionName = Translator.translateString('options', prefix + 'option_${option.variable}');
			#end
			var nameText = new FlxText(20, 50 + i * 40, catFrame.width, optionName, 24);
			var valText = new FlxText(0, nameText.y, catFrame.width - 20, option.valueString(), 24);
			valText.font = optionsFont;
			valText.alignment = RIGHT;
			nameText.font = optionsFont;
			catOptions.add(nameText);
			catOptions.add(valText);
			nameText.ID = i;
			valText.ID = i;
		}
		changeSelection();
	}

	#if FEATURE_TRANSLATIONS
	function onLanguageChanged(lang:String) {
		Translator.setLocale(lang);
		updateCat();
	}
	#end
}
