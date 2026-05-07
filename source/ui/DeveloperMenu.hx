package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameplay.PlayState;
import gameplay.StageBG;
import ui.AlphabetMenu;

using util.CoolUtil;

private typedef DevOption = {name:String, ?hover:() -> Void, ?altChange:() -> Void, confirm:() -> Void, ?description:String}

// oddly specific toolkit for mods
// I might extend this later, just made this so my life testing mods is a little bit less convoluted
// for now it does the job -asmadeuxs
class DeveloperMenu extends MusicBeatSubstate {
	var options:Array<DevOption>;
	var descriptionText:FlxText;
	var selected:Int = 0;
	var alternative:Int = 0;
	var items:AlphabetMenu;
	var canInput:Bool = false;

	var altLen:Int = 1;
	var altText:FlxText;
	var colorTween:FlxTween;
	var descTimer:FlxTimer;

	public function new():Void {
		super();

		descTimer = new FlxTimer();

		var stages:Array<String> = StageBG.getStageFiles();
		options = [
			{
				name: 'Reset State',
				description: "Resets the current state (immediately)",
				confirm: () -> {
					FlxG.resetState();
					close();
				}
			},
			{
				name: "Test Stage",
				description: "Reloads the stage to a different one (without clearing cache)\nPress ESC after you do this",
				hover: () -> {
					altLen = stages.length;
					var i = items.members[selected];
					altText.objectCenter(i, XY);
					altText.y += (i.height + altText.height) + 5;
					altText.text = stages[alternative];
					altText.visible = true;
				},
				altChange: () -> altText.text = Std.string(stages[alternative]), // Std.string just in case this is ever null
				confirm: () -> {
					var state:PlayState = cast FlxG.state;
					if (state != null && state.stage != null && stages.length != 0) {
						state.stage.clear();
						state.stage.stageFile = stages[alternative];
						state.camGame.zoom = state.stage.cameraZoom;
						FlxG.sound.play(util.Mods.menuSound("confirmMenu"));
						state.positionCharacters();
						if (colorTween != null)
							colorTween.cancel();
						items.members[selected].color = FlxColor.LIME;
						colorTween = FlxTween.color(items.members[selected], 0.5, items.members[selected].color, FlxColor.WHITE, {ease: FlxEase.sineOut});
					}
				}
			},
			{
				name: "Clear Stage Cache",
				description: "Clears the in-game stage cache and reloads the current one\nUseful if you've changed your stage json or script and need to immediately see the changes",
				confirm: () -> {
					var state:PlayState = cast FlxG.state;
					if (state != null && state.stage != null) {
						var current:String = state.stage.stageFile;
						state.stage.clear();
						state.stage.clearCache();
						state.stage.stageFile = current;
						FlxG.sound.play(util.Mods.menuSound("confirmMenu"));
						if (colorTween != null)
							colorTween.cancel();
						items.members[selected].color = FlxColor.LIME;
						colorTween = FlxTween.color(items.members[selected], 0.5, items.members[selected].color, FlxColor.WHITE, {ease: FlxEase.sineOut});
					} else {
						FlxG.sound.play(util.Mods.menuSound("cancelMenu"));
						if (descTimer != null)
							descTimer.cancel();
						if (descriptionText != null) {
							descriptionText.text = "Stage not available (are you in a menu?)";
							descTimer.start(1.0, (_) -> resetDescription());
						}
					}
				}
			},
			{
				name: 'Reload Locales',
				description: "Reloads every language in the locales folder",
				confirm: () -> {
					FlxG.sound.play(util.Mods.menuSound("confirmMenu"));
					Translator.reloadLocales();
					if (colorTween != null)
						colorTween.cancel();
					items.members[selected].color = FlxColor.LIME;
					colorTween = FlxTween.color(items.members[selected], 0.5, items.members[selected].color, FlxColor.WHITE, {ease: FlxEase.sineOut});
					canInput = true;
				}
			},
		];

		var bg:FlxSprite = null;
		add(bg = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, 0xFF000000));
		add(items = new AlphabetMenu(0, 0).generateMenu([for (i in 0...options.length) options[i].name]));
		add(descriptionText = new FlxText(0, 0, FlxG.width, "..."));
		add(altText = new FlxText(0, 0, FlxG.width, ""));

		descriptionText.setFormat(util.Mods.menuFont("vcr.ttf"), 20, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		altText.setFormat(util.Mods.menuFont("vcr.ttf"), 20, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		items.lerpStyle = LerpingStyle.CENTERED;
		bg.alpha = 0.6;

		canInput = true;
		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		changeSelection();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (canInput) {
			var up:Bool = controls.UP_P;
			if (up || controls.DOWN_P)
				changeSelection(up ? -1 : 1);
			var left:Bool = controls.LEFT_P;
			if (altLen > 0 && (left || controls.RIGHT_P))
				changeAlternative(left ? -1 : 1);
			if (controls.ACCEPT_P && options[selected] != null && options[selected].confirm != null)
				options[selected].confirm();
			if (controls.BACK_P) {
				canInput = false;
				close();
			}
		}
	}

	function changeSelection(next:Int = 0):Void {
		var prev:Int = selected;
		altText.visible = false;
		altLen = 0;
		selected = flixel.math.FlxMath.wrap(selected + next, 0, options.length - 1);
		if (selected != prev)
			FlxG.sound.play(util.Mods.menuSound("scrollMenu"));
		for (index => item in items.members) {
			item.targetY = index - selected;
			if (item.targetY == 0)
				item.alpha = 1.0;
			else
				item.alpha = 0.6;
		}
		if (options[selected] != null && options[selected].hover != null)
			options[selected].hover();
		if (descTimer == null || !descTimer.active || descTimer.finished)
			resetDescription();
	}

	function resetDescription():Void {
		descriptionText.text = Std.string(options[selected].description);
		descriptionText.x = (FlxG.width - descriptionText.width) * 0.5;
		descriptionText.y = 100;
	}

	function changeAlternative(next:Int = 0):Void {
		var prev:Int = alternative;
		alternative = flixel.math.FlxMath.wrap(alternative + next, 0, altLen - 1);
		if (options[selected] != null && options[selected].altChange != null)
			options[selected].altChange();
		if (alternative != prev)
			FlxG.sound.play(util.Mods.menuSound("scrollMenu"));
	}
}
