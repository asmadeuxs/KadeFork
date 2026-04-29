package menus;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import menus.GenericMenu.SimpleMenuButton;

using StringTools;

class MainMenuState extends MusicBeatState {
	var curSelected:Int = 0;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var optionShit:Array<SimpleMenuButton> = null;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create() {
		super.create();
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music("freakyMenu"), 0.7);
		#if hxdiscord_rpc
		DiscordClient.changePresence('Main Menu', "Browsing Menus");
		#end

		persistentUpdate = persistentDraw = true;

		optionShit = [
			// {name: 'story mode', func: () -> FlxG.switchState(new menus.StoryMenuState())},
			{name: 'freeplay', func: () -> FlxG.switchState(new menus.FreeplayState())},
			{
				name: 'options',
				func: () -> {
					this.active = false;
					tweenItemsBackIn();
					openSubState(new menus.OptionsMenu(this));
				}
			}
		];

		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/backgrounds/menuBG'));
		bg.scrollFactor.set(0, 0.15);
		bg.scale.set(1.1, 1.1);
		bg.screenCenter();
		bg.updateHitbox();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(bg.x, bg.y).loadGraphic(Paths.image('ui/backgrounds/menuBGMagenta'));
		magenta.scrollFactor.set(0, 0.15);
		magenta.scale.set(1.1, 1.1);
		magenta.updateHitbox();
		magenta.antialiasing = true;
		magenta.visible = false;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length) {
			var menuItem:FlxSprite = new FlxSprite(0, 130 + (i * 180));
			menuItem.frames = Paths.getSparrowAtlas('ui/FNF_main_menu_assets');
			menuItem.animation.addByPrefix('idle', optionShit[i].name + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i].name + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
		}

		FlxG.camera.follow(camFollow, null, 0.10);

		var versionShit:FlxText = new FlxText(5, 0, 0, 'FNF v${Main.versions.BASE_GAME} - KE v${Main.versions.KADE} - Fork v${Main.versions.FORK}', 12);
		versionShit.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.y = (FlxG.height - versionShit.height) - 5;
		versionShit.scrollFactor.set();
		add(versionShit);

		changeItem();
	}

	public var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!selectedSomethin) {
			if (FlxG.keys.justPressed.SEVEN) {
				FlxG.sound.music.stop();
				FlxG.switchState(new gameplay.DummyPlayState());
				selectedSomethin = true;
			}
			if (controls.UP_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.DOWN_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
				FlxG.switchState(new menus.TitleState());

			if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						FlxTween.tween(spr, {alpha: 0}, 1.3, {
							onComplete: function(twn:FlxTween) spr.kill(),
							ease: FlxEase.quadOut
						});
					} else {
						FlxFlicker.flicker(spr, 1, 0.06, true, false, function(flick:FlxFlicker) {
							if (optionShit[curSelected] != null && optionShit[curSelected].func != null)
								optionShit[curSelected].func();
							else {
								tweenItemsBackIn();
								selectedSomethin = false;
							}
						});
					}
				});
			}
		}

		menuItems.forEach(function(spr:FlxSprite) spr.screenCenter(X));
	}

	public function tweenItemsBackIn() {
		this.active = true;
		menuItems.forEach(function(spr:FlxSprite) {
			spr.revive();
			FlxTween.cancelTweensOf(spr);
			FlxTween.tween(spr, {alpha: 1}, 0.3, {ease: FlxEase.quadIn});
		});
	}

	function changeItem(huh:Int = 0) {
		curSelected += huh;
		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play(spr.ID == curSelected ? 'selected' : 'idle');
			spr.screenCenter(X);
			camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			spr.updateHitbox();
		});
	}
}
