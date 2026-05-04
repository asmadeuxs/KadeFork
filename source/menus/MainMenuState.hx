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
import flixel.util.FlxTimer;
import lime.app.Application;
import menus.GenericMenu.SimpleMenuButton;
import util.Mods;

using StringTools;

class MainMenuState extends GenericMenu {
	var menuItems:FlxTypedGroup<FlxSprite>;
	var optionShit:Array<SimpleMenuButton> = null;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create() {
		super.create();
		#if hxdiscord_rpc
		DiscordClient.changePresence('Main Menu', "Browsing Menus");
		#end

		Mods.currentMod = null;
		persistentUpdate = persistentDraw = true;
		optionShit = [
			// {name: 'story mode', func: () -> menus.ScriptedMenu.switchToMenu("StoryMenuState")},
			{name: 'freeplay', func: () -> menus.ScriptedMenu.switchToMenu("FreeplayState")},
			{
				name: 'options',
				func: () -> {
					this.active = false;
					tweenItemsBackIn();
					openSubState(new menus.OptionsMenu());
				}
			}
		];
		maxVerticals = optionShit.length - 1;

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Mods.menuMusic("freakyMenu"), 0.7);

		add(camFollow = new FlxObject(0, 0, 1, 1));
		FlxG.camera.follow(camFollow, null, 0.10);

		createBG();
		createMenuItems();

		var versionShit:FlxText = new FlxText(5, 0, 0, 'FNF v${Main.versions.BASE_GAME} - KE v${Main.versions.KADE} - Fork v${Main.versions.FORK}', 12);
		versionShit.setFormat(Mods.menuFont("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.y = (FlxG.height - versionShit.height) - 5;
		versionShit.scrollFactor.set();
		add(versionShit);

		changeVertical();
	}

	public function createBG():Void {
		var bg:FlxSprite = new FlxSprite().loadGraphic(Mods.menuImage('ui/backgrounds/menuBG'));
		bg.scrollFactor.set(0, 0.15);
		bg.scale.set(1.1, 1.1);
		bg.screenCenter();
		bg.updateHitbox();
		bg.antialiasing = true;
		add(bg);

		magenta = new FlxSprite(bg.x, bg.y).loadGraphic(Mods.menuImage('ui/backgrounds/menuBGMagenta'));
		magenta.scrollFactor.set(0, 0.15);
		magenta.scale.set(1.1, 1.1);
		magenta.updateHitbox();
		magenta.antialiasing = true;
		magenta.visible = false;
		add(magenta);
	}

	function createMenuItems():Void {
		menuItems = new FlxTypedGroup<FlxSprite>();
		for (i in 0...optionShit.length) {
			var menuItem:FlxSprite = new FlxSprite(0, 130 + (i * 180));
			menuItem.frames = Mods.menuSparrowAtlas('ui/FNF_main_menu_assets');
			menuItem.animation.addByPrefix('idle', optionShit[i].name + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i].name + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
		}
		add(menuItems);
	}

	override function update(elapsed:Float):Void {
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		super.update(elapsed);
		if (canInput && FlxG.keys.justPressed.TAB) {
			// temporary
			var mods = Mods.getEnabled();
			var curIndex = mods.indexOf(Mods.menuPriorityMod);
			var nextIndex = (curIndex + 1) % mods.length;
			Mods.menuPriorityMod = mods[nextIndex];
			// Show feedback
			trace('Menu priority set to: ${Mods.menuPriorityMod}');
			if (FlxG.save.data.menuPriorityMod != Mods.menuPriorityMod)
				FlxG.save.data.menuPriorityMod = Mods.menuPriorityMod;
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			FlxG.resetState();
		}
		if (FlxG.keys.justPressed.SEVEN) {
			FlxG.sound.music.stop();
			FlxG.switchState(new gameplay.DummyPlayState());
			canInput = false;
		}
		menuItems.forEach(function(spr:FlxSprite) spr.screenCenter(X));
	}

	override function onBackPressed():Void
		FlxG.switchState(new menus.TitleState());

	override function onAcceptPressed(v:Int, h:Int):Void {
		canInput = false;
		FlxG.sound.play(Mods.menuSound('confirmMenu'));
		FlxFlicker.flicker(magenta, 1.1, 0.15, false);

		menuItems.forEach(function(spr:FlxSprite) {
			if (v != spr.ID) {
				FlxTween.tween(spr, {alpha: 0}, 1.3, {
					onComplete: function(twn:FlxTween) spr.kill(),
					ease: FlxEase.quadOut
				});
			} else {
				FlxFlicker.flicker(spr, 1, 0.06, true, false, function(flick:FlxFlicker) {
					if (optionShit[v] != null && optionShit[v].func != null)
						optionShit[v].func();
					else {
						tweenItemsBackIn();
						canInput = true;
					}
				});
			}
		});
	}

	override function onVerticalChanged(huh:Int):Void {
		FlxG.sound.play(Mods.menuSound("scrollMenu"));
		for (spr in menuItems) {
			spr.animation.play(spr.ID == huh ? 'selected' : 'idle');
			spr.screenCenter(X);
			camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			spr.updateHitbox();
		}
	}

	public function tweenItemsBackIn():Void {
		this.active = true;
		for (spr in menuItems) {
			spr.revive();
			FlxTween.cancelTweensOf(spr);
			FlxTween.tween(spr, {alpha: 1}, 0.3, {ease: FlxEase.quadIn});
		}
	}
}
