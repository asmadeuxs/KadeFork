package gameplay.hud;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import gameplay.PlayState;
import moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacyMetaValues;
import ui.HealthIcon;

using util.CoolUtil;

class Classic extends BaseHUD {
	public var healthBar:FlxBar;
	public var healthBarBG:FlxSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var scoreTxt:FlxText;
	public var judgesTxt:FlxText;

	var songPosBG:FlxSprite;
	var songName:FlxText;

	var songPos:Float = 0;
	var songLength:Float = 0;

	override public function new():Void {
		super();
		songLength = PlayState.songLength;
		if (Preferences.user.showSongPosition) // I dont wanna talk about this code :( -KadeDev // I do -asmadeuxs
		{
			var songPosBar = new FlxBar(0, 10, LEFT_TO_RIGHT, 200, 25, this, 'songPos', 0, songLength);
			songPosBar.createFilledBar(FlxColor.BLACK, FlxColor.LIME);
			if (Preferences.user.scrollType == 1)
				songPosBar.y = FlxG.height * 0.9 + 45;
			songPosBar.screenCenter(X);

			songPosBG = new FlxSprite(songPosBar.x, songPosBar.y).makeGraphic(Std.int(songPosBar.width), Std.int(songPosBar.height), FlxColor.TRANSPARENT);
			songName = new FlxText(0, songPosBG.y + 3, 0, "", 16);
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			FlxSpriteUtil.drawRect(songPosBG, 0, 0, songPosBar.width, songPosBar.height, FlxColor.TRANSPARENT, {thickness: 4, color: FlxColor.BLACK});
			updateSongPosition();

			add(songPosBar);
			add(songPosBG);
			add(songName);
		}

		// FlxG.height * 0.9 originally but I like it this way -asmadeuxs
		// should be 630 if FlxG.height is 720
		var healthY:Float = FlxG.height * 0.875;
		if (Preferences.user.scrollType == 1)
			healthY = 70; // 50 originally
		healthBarBG = new FlxSprite(0, healthY).loadGraphic(Paths.image('gameplay/ui/healthBar'));
		healthBarBG.antialiasing = true;
		healthBarBG.screenCenter(X);
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8),
			PlayState.current, 'health', 0, 2);
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		healthBar.antialiasing = true;
		add(healthBar);

		iconP1 = new HealthIcon(PlayState.moonMeta.extraData.get(PLAYER_1) ?? "bf", true);
		iconP1.y = healthBar.y - (iconP1.height * 0.5);
		add(iconP1);

		iconP2 = new HealthIcon(PlayState.moonMeta.extraData.get(PLAYER_2) ?? "bf", false);
		iconP2.y = healthBar.y - (iconP2.height * 0.5);
		add(iconP2);

		scoreTxt = new FlxText(0, 0, 0, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		scoreTxt.antialiasing = true;
		add(scoreTxt);

		if (Preferences.user.showJudgeCounts) {
			judgesTxt = new FlxText(5, 0, FlxG.width, "");
			judgesTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
			judgesTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.0);
			judgesTxt.antialiasing = true;
			judgesTxt.screenCenter(Y);
			judgesTxt.y -= 30;
			add(judgesTxt);
		}
		updateScoreText();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (Conductor.time >= 0.0)
			songPos = Conductor.time;
		// icon
		var iconOffset:Int = 26;
		var hpCenter:Float = healthBar.x + healthBar.width * (1 - healthBar.percent * 0.01);
		if (iconP1 != null) {
			// TODO: restore this
			/*if (FlxG.keys.justPressed.NINE) {
				if (iconP1.animation.curAnim.name == 'bf-old')
					iconP1.animation.play(PlayState.SONG.player1);
				else
					iconP1.animation.play('bf-old');
			}*/
			iconP1.x = hpCenter - iconOffset;
			iconP1.setGraphicSize(FlxMath.lerp(iconP1.width, 150, elapsed * 30));
			iconP1.updateHitbox();
		}
		if (iconP2 != null) {
			iconP2.x = hpCenter - (iconP2.width - iconOffset);
			iconP2.setGraphicSize(FlxMath.lerp(iconP2.width, 150, elapsed * 30));
			iconP2.updateHitbox();
		}
		if (iconP1 != null && iconP2 != null) {
			if (healthBar.percent < 20) {
				iconP1.switchState("losing");
				iconP2.switchState("winning");
			} else if (healthBar.percent > 80) {
				iconP1.switchState("winning");
				iconP2.switchState("losing");
			} else {
				iconP1.switchState("idle");
				iconP2.switchState("idle");
			}
		}
		updateSongPosition();
	}

	override function updateScoreText(?miss:Bool = false):Void {
		var layout:String;
		if (Preferences.user.showNps)
			layout = '${PlayState.nps} / ${PlayState.maxNps} NPS | ';
		else
			layout = '';
		var score:Int = PlayState.session?.score ?? 0;
		var scoreMoney:String = flixel.util.FlxStringUtil.formatMoney(score, false, true);
		#if FEATURE_TRANSLATIONS
		layout += Translator.translateFormat('main', 'score', scoreMoney);
		#else
		layout += 'Score: $scoreMoney';
		#end
		scoreTxt.text = layout;
		// values copied from here https://github.com/FunkinCrew/Funkin/blob/bdedc0aad2b93b3a7787357313ba662ba8d3173f/source/funkin/play/PlayState.hx#L2016
		scoreTxt.x = healthBarBG.x + healthBarBG.width - 190;
		scoreTxt.y = healthBarBG.y + 30;
		scoreTxt.alignment = RIGHT;
		if (judgesTxt != null)
			judgesTxt.text = getJudgeCounts();
	}

	public function updateSongPosition() {
		if (songName != null) {
			var cur:String = FlxStringUtil.formatTime(songPos * 0.001, false);
			var len:String = FlxStringUtil.formatTime(songLength * 0.001, false);
			songName.text = '$cur / $len';
			songName.objectCenter(songPosBG, X);
			songName.alignment = CENTER;
		}
	}

	public function getJudgeCounts() {
		var str:String = '';
		if (PlayState.session != null && PlayState.session.judgeMan.activeList?.length > 0)
			for (idx => judge in PlayState.session.judgeMan.activeList) {
				var judgeName:String = null;
				#if FEATURE_TRANSLATIONS
				judgeName = Translator.translatePlural('main', 'judge_' + judge.name);
				#else
				judgeName = judge.name;
				#end
				str += '$judgeName: ${judge.hits}\n';
			}
		return str;
	}

	override function beatHit(beat:Int):Void {
		if (iconP1 != null) {
			iconP1.setGraphicSize(Std.int(iconP1.width + 30));
			iconP1.updateHitbox();
		}
		if (iconP2 != null) {
			iconP2.setGraphicSize(Std.int(iconP2.width + 30));
			iconP2.updateHitbox();
		}
	}
}
