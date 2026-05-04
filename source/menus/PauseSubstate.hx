package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import gameplay.PlayState;
import menus.GenericMenu.SimpleMenuButton;

using util.CoolUtil;

class PauseSubstate extends GenericMenu {
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<SimpleMenuButton> = null;
	var pauseMusic:FlxSound;

	public function new(x:Float, y:Float) {
		super();

		#if FEATURE_TRANSLATIONS
		var resume:String = Translator.translateString('menus', 'pause_resumeSong');
		var restart:String = Translator.translateString('menus', 'pause_restartSong');
		var options:String = Translator.translateString('menus', 'pause_changeOptions');
		var exit:String = Translator.translateString('menus', 'pause_exit');
		#else
		var resume:String = 'Resume';
		var restart:String = 'Restart';
		var options:String = 'Change Options';
		var exit:String = 'Exit';
		#end
		menuItems = [
			{name: resume, func: () -> close()},
			{name: restart, func: () -> FlxG.resetState()},
			{
				name: options,
				func: () -> {
					persistentDraw = true;
					persistentUpdate = false;
					openSubState(new menus.OptionsMenu());
				}
			},
			{
				name: exit,
				func: () -> {
					if (!FlxG.sound.music.playing) {
						FlxG.sound.playMusic(Paths.inst(PlayState.songName, PlayState.difficulty, util.Mods.currentMod), 0);
						FlxG.sound.music.time = FlxG.random.int(0, Std.int(FlxG.sound.music.length * 0.5));
						FlxG.sound.music.fadeIn(4, 0, 0.7);
					}
					menus.ScriptedMenu.switchToMenu("FreeplayState");
				}
			}
		];
		maxVerticals = menuItems.length - 1;

		pauseMusic = new FlxSound().loadEmbedded(util.Mods.menuMusic('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length * 0.5)));
		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.6;
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.moonMeta.title;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		#if FEATURE_TRANSLATIONS
		var diff:String = Translator.translateString('menus', 'difficulty_' + PlayState.difficulty.toLowerCase());
		#else
		var diff:String = PlayState.difficulty;
		#end

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += diff.toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		// todo: restore these
		// FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		// FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		// FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		reloadMenu();

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}

	override function update(elapsed:Float) {
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;
		super.update(elapsed);
		if (controls.ACCEPT && canInput && menuItems[curVertical] != null && menuItems[curVertical].func != null)
			menuItems[curVertical].func();
	}

	override function destroy() {
		if (pauseMusic != null)
			pauseMusic.destroy();
		super.destroy();
	}

	override function onVerticalChanged(change:Int):Void {
		if (change != 0)
			FlxG.sound.play(util.Mods.menuSound("scrollMenu"));
		var bullShit:Int = 0;
		for (item in grpMenuShit.members) {
			item.targetY = bullShit - curVertical;
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == 0)
				item.alpha = 1;
		}
	}

	function reloadMenu() {
		for (i in 0...menuItems.length) {
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i].name, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}
		changeVertical(curVertical);
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
}
