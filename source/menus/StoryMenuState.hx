package menus;

import data.ConfigTypes;
import data.Highscore;
import data.song.SongMetadata;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import gameplay.PlayState;
import registry.LevelRegistry;
import ui.FunkinSprite;

using StringTools;
using util.AnimationHelper;
using util.CoolUtil;

class StoryMenuState extends GenericMenuState {
	var mainBG:FlxSprite;

	var lvlLabels:FlxTypedSpriteGroup<FunkinSprite>;
	var modToData:Map<String, Array<LevelData>> = new Map<String, Array<LevelData>>();

	var levelData:Array<LevelData> = null;
	var lastDifficultyArray:Array<String> = null;

	var scoreText:FlxText;
	var taglineText:FlxText;
	var tracklistText:FlxText;

	var difficultySprites:FlxSpriteGroup;
	var diffMapSprite:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	var aboutToTransition:Bool = false;
	var flashValue:Int = 0;

	// stole these from freeplay
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	override function create():Void {
		this.menuScrollType = BOTH;

		// load levels
		var modIDs:Array<String> = util.Mods.getEnabled();
		for (modId in modIDs) {
			var levels:Array<LevelData> = LevelRegistry.current.getLevelData(modId);
			if (levels != null && levels.length != 0)
				modToData.set(modId, levels);
		}

		super.create();

		add(new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, 0xFF000000));

		mainBG = new FlxSprite(0, 56).makeScaledGraphic(FlxG.width, FlxG.height / 1.8, 0xFFF9CF51);
		add(lvlLabels = new FlxTypedSpriteGroup<FunkinSprite>(0, -5000));
		add(mainBG);
		// black bar above the main (yellow) bg
		add(new FlxSprite().makeScaledGraphic(FlxG.width, 56, 0xFF000000));

		// temporary lol
		var firstModWithActualLevels:String = util.Mods.currentMod;
		for (key => levelData in modToData) {
			if (levelData == null || levelData.length == 0)
				continue;
			firstModWithActualLevels = key;
			break;
		}
		levelData = loadLevels(firstModWithActualLevels);
		maxVerticals = levelData.length - 1;

		difficultySprites = new FlxSpriteGroup(0, mainBG.y + mainBG.height + 20);
		difficultySprites.x = FlxG.width * 0.67; // don't even

		var arrowTex = Paths.getSparrowAtlas('ui/story/arrows');

		var arrowLeft = new FlxSprite();
		arrowLeft.frames = arrowTex;
		arrowLeft.animation.addByPrefix('idle', 'leftIdle', 0, false);
		arrowLeft.animation.addByPrefix('pressed', 'leftConfirm', 0, false);
		arrowLeft.animation.play('idle', true);
		difficultySprites.add(arrowLeft);

		var spacing:Float = 80;
		var uniqueDiffs:Map<String, Bool> = new Map<String, Bool>();
		var rightX:Float = spacing;

		for (data in modToData) {
			for (level in data) {
				if (level != null && level.difficulties != null)
					for (diff in level.difficulties)
						uniqueDiffs.set(diff, true);
			}
		}

		for (diff in uniqueDiffs.keys()) {
			var diffSpr = new FlxSprite(0, 10);
			diffSpr.loadGraphic(Paths.image('ui/story/difficulties/${diff.toLowerCase()}'));
			diffMapSprite.set(diff, diffSpr);
			if ((diffSpr.width + spacing) > rightX)
				rightX = diffSpr.width + spacing;
		}

		uniqueDiffs.clear();
		uniqueDiffs = null;

		var arrowRight = new FlxSprite(rightX);
		arrowRight.frames = arrowTex;
		arrowRight.animation.addByPrefix('idle', 'rightIdle', 0, false);
		arrowRight.animation.addByPrefix('pressed', 'rightConfirm', 0, false);
		arrowRight.animation.play('idle', true);
		difficultySprites.add(arrowRight);

		for (sprite in diffMapSprite)
			difficultySprites.add(sprite);

		add(difficultySprites);

		scoreText = new FlxText(10, 10, 0, "LEVEL SCORE: 0");
		scoreText.setFormat(Paths.font("vcr"), 32, 0xFFFFFFFF, LEFT);
		add(scoreText);

		taglineText = new FlxText(0, 10, 0, 32);
		taglineText.font = scoreText.font;
		taglineText.color = 0xFFFFFFFF;
		taglineText.alignment = RIGHT;
		taglineText.alpha = 0.7;
		add(taglineText);

		tracklistText = new FlxText(0, mainBG.x + mainBG.height + 100, 0, "TRACKS:\n", 32);
		tracklistText.font = taglineText.font;
		tracklistText.color = 0xFFE55777;
		tracklistText.alignment = CENTER;
		add(tracklistText);

		onVerticalChanged(curVertical);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (aboutToTransition) {
			var cur = lvlLabels.members[curVertical];
			if (cur != null) {
				flashValue++;
				var frameRate:Int = Math.round((1 / elapsed) / 10);
				if (flashValue % frameRate >= Math.floor(frameRate / 2))
					cur.color = 0xFF33FFFF;
				else
					cur.color = 0xFFFFFFFF;
			}
			return;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));
		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		for (item in lvlLabels.members) {
			var spacing:Float = 20;
			var startY:Float = lvlLabels.y + 50;
			item.y = FlxMath.lerp(item.y, startY + (item.ID * (item.height + spacing)), 0.16 * (60 / Preferences.user.frameRate));
			item.screenCenter(X);
			item.x -= 20;
		}

		if (controls.BACK_P)
			util.StateOverride.switchState("menus.MainMenuState");
	}

	public function snapPosition() {
		for (item in lvlLabels.members) {
			var spacing:Float = 20;
			item.y = lvlLabels.y + 50 + (item.ID * (item.height + spacing));
			item.screenCenter(X);
			item.x -= 20;
		}
	}

	override function onVerticalChanged(index:Int):Void {
		updateTexts();
		refreshDifficulties();
		FlxG.sound.play(util.Mods.menuSound("scrollMenu"));
		maxHorizontals = lastDifficultyArray.length - 1;
		var bullShit:Int = 0;
		for (item in lvlLabels.members) {
			item.ID = bullShit - index;
			bullShit++;
			item.alpha = item.ID == 0 ? 1.0 : 0.6;
		}
		changeHorizontal(); // recalculate score
	}

	override function onHorizontalChanged(index:Int):Void {
		if (levelData == null)
			return;
		var diffic:String = lastDifficultyArray[index];
		var arrowL = difficultySprites.members[0];
		var arrowR = difficultySprites.members[1];
		for (diff => sprite in diffMapSprite) {
			sprite.objectCenterBetween(arrowL, arrowR, X);
			sprite.alpha = 0;
			if (diff == diffic) {
				FlxTween.completeTweensOf(sprite); // not cancelling so curY is right by the time we get it
				var curY:Float = sprite.y;
				sprite.y -= 15;
				FlxTween.tween(sprite, {y: curY, alpha: 1.0}, 0.07);
			}
		}
		// var l = lvlLabels.members[curVertical];
		// difficultySprites.x = l.x + l.width + 20;
		var level = levelData[curVertical];
		intendedScore = Highscore.getCampaignScore('${level.mod}:${level.fileName}', diffic);
	}

	override function onAcceptPressed(level:Int, difficulty:Int):Void {
		if (PlayState.playlist == null)
			PlayState.playlist = new data.song.SongPlaylist();
		PlayState.playlist.clear();
		PlayState.playlist.toggleStory(true);

		var curSong:SongMetadata = null;
		for (daSong in levelData[curVertical].songs) {
			var diff:String = lastDifficultyArray[curHorizontal].toLowerCase();
			curSong = SongMetadata.fromLevelSong(daSong, levelData[curVertical].mod);
			PlayState.playlist.addSongFromMetadata(curSong, diff);
			curSong.curDifficulty = diff;
		}

		if (curSong != null) {
			PlayState.playlist.setLevel(levelData[curVertical]);
			PlayState.playlist.getCurrent();
			PlayState.playlist.updateSong();
			aboutToTransition = true;
			FlxG.sound.play(util.Mods.menuSound("confirmMenu"));
			new flixel.util.FlxTimer().start(1.0, (_) -> FlxG.switchState(new gameplay.PlayState()));
		}
	}

	public function updateTexts() {
		if (levelData == null || levelData[curVertical] == null)
			return;

		taglineText.text = levelData[curVertical].tagline;
		tracklistText.text = "TRACKS:\n";
		for (i in levelData[curVertical].songs)
			tracklistText.text += '\n${i.name}';

		// same code as the original game
		taglineText.x = FlxG.width - (taglineText.width + 10);
		tracklistText.screenCenter(X);
		tracklistText.x -= FlxG.width * 0.35;
	}

	function refreshDifficulties() {
		var difficulties:Array<String> = getDifficultyList(curVertical);
		// check to prevent null difficulties
		if (lastDifficultyArray != difficulties) {
			lastDifficultyArray = difficulties;
			curHorizontal = Math.round(maxHorizontals * 0.5);
			if (curHorizontal > maxHorizontals)
				curHorizontal = 0;
		}
	}

	function getDifficultyList(index:Int) {
		var difficulties:Array<String> = CoolUtil.defaultDifficulties;
		if (levelData[index] != null && levelData[index].difficulties != null && levelData[index].difficulties.length > 0)
			difficulties = levelData[index].difficulties;
		return difficulties;
	}

	public function loadLevels(fromMod:String = 'core'):Array<LevelData> {
		var levels:Array<LevelData> = modToData.get(fromMod);
		lvlLabels.y = -5000;
		while (lvlLabels.members.length > 0)
			lvlLabels.members.pop().destroy();
		if (levels == null || levels.length == 0)
			return null;
		for (id => level in levels) {
			if (level == null)
				continue;
			var levelLabel:FunkinSprite = loadLabel(level, fromMod);
			if (levelLabel == null)
				continue;
			levelLabel.ID = id;
			levelLabel.alpha = 0.6;
			if (id == curVertical)
				levelLabel.alpha = 1.0;
			// TODO: check level lock state and add the lock sprite
			lvlLabels.add(levelLabel);
		}

		// this is genuinely so manual
		lvlLabels.y = FlxG.height / 1.8;
		lvlLabels.y += 50;
		return levels;
	}

	public function loadLabel(levelData:LevelData, modId:String = 'core'):FunkinSprite {
		var defaultTex:TextureConfig = {path: 'ui/story/levels/${levelData.fileName}', atlasType: "spritesheet"};
		var label:LevelLabel = levelData.labelObject ?? null;
		if (label == null)
			label = {texture: defaultTex};

		if (label.texture == null) {
			label.texture = defaultTex;
			label.antialiasing = true;
		}

		var path:String = ConfigTypes.getTexturePath(label.texture);
		var atlasType:String = ConfigTypes.getAtlasType(label.texture, 'spritesheet');

		var tex = switch atlasType {
			case 'sparrow': Paths.getSparrowAtlas(path, modId);
			case 'animate': Paths.getAnimateAtlas(path, modId);
			case 'packer': Paths.getPackerAtlas(path, modId);
			case _: Paths.image(path);
		};
		var labelSprite:FunkinSprite = new FunkinSprite();
		if (tex is FlxAtlasFrames)
			labelSprite.frames = cast tex;
		else
			labelSprite.loadGraphic(cast tex);
		if (label.animations != null)
			labelSprite.addFromJson(label.animations, label.defaultFramerate ?? 24);
		if (label.offsets != null)
			labelSprite.addOffsetsFromJson(label.offsets);
		labelSprite.antialiasing = label.antialiasing == true;
		labelSprite.flipX = label.flipX == true;
		labelSprite.flipY = label.flipY == true;
		return labelSprite;
	}
}
