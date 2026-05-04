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

class Kade extends BaseHUD {
	public var healthBar:FlxBar;
	public var healthBarBG:FlxSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var scoreTxt:FlxText;
	public var judgesTxt:FlxText;

	var songPosBar:FlxBar;
	var songPosBG:FlxSprite;
	var songName:FlxText;

	var songPos:Float = 0;
	var songLength:Float = 1;

	override public function new():Void {
		super();
		songLength = PlayState.songLength;
		if (Preferences.user.showSongPosition) // I dont wanna talk about this code :( -KadeDev // I do -asmadeuxs
		{
			songPosBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 500, 25, this, 'songPos', 0, songLength);
			songPosBG = new FlxSprite(0, 0).makeGraphic(Std.int(songPosBar.width), Std.int(songPosBar.height), FlxColor.TRANSPARENT);
			songName = new FlxText(0, 0, Std.int(songPosBG.width), "", 16);
			songPosBar.createFilledBar(FlxColor.BLACK, FlxColor.fromRGB(0, 255, 128));
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			FlxSpriteUtil.drawRect(songPosBG, 0, 0, songPosBar.width, songPosBar.height, FlxColor.TRANSPARENT, {thickness: 4, color: FlxColor.BLACK});
			updateSongPosition();
		}

		healthBarBG = new FlxSprite(0, 0).loadGraphic(Paths.image('gameplay/ui/healthBar'));
		healthBar = new FlxBar(0, 0, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), PlayState.current, 'health', 0, 2);
		iconP1 = new HealthIcon(HealthIcon.getPlayerIcon(), true);
		iconP2 = new HealthIcon(HealthIcon.getOpponentIcon(), false);
		scoreTxt = new FlxText(0, healthBarBG.y + 50, 0, "", 20);
		if (Preferences.user.showJudgeCounts) {
			judgesTxt = new FlxText(0, 0, FlxG.width, "");
			judgesTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
			judgesTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.0);
			judgesTxt.antialiasing = true;
		}

		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		healthBarBG.antialiasing = true;
		healthBar.antialiasing = true;
		scoreTxt.antialiasing = true;

		add(healthBarBG);
		add(healthBar);
		add(iconP1);
		add(iconP2);
		add(scoreTxt);

		if (Preferences.user.showJudgeCounts)
			add(judgesTxt);

		if (Preferences.user.showSongPosition) {
			add(songPosBar);
			add(songPosBG);
			add(songName);
		}

		updateScoreText();

		var diff:String = PlayState.difficulty;
		#if FEATURE_TRANSLATIONS
		diff = Translator.translateString('menus', 'difficulty_' + PlayState.difficulty);
		#end
		var watermark:FlxText = new FlxText(5, 0, 0, '${PlayState.moonMeta.title} - ${diff.toUpperCase()}', 12);
		watermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		watermark.y = (FlxG.height - watermark.height) - 3;
		watermark.antialiasing = true;
		add(watermark);
	}

	override function onSettingsChanged() {
		positionElements();
	}

	public function positionElements() {
		if (Preferences.user.showSongPosition) {
			songPosBar.y = 10;
			if (Preferences.user.scrollType == 1)
				songPosBar.y = FlxG.height * 0.9 + 45;
			songPosBar.screenCenter(X);
			songPosBG.setPosition(songPosBar.x, songPosBar.y);
			songName.y = songPosBG.y + 3;
		}

		// FlxG.height * 0.9 originally but I like it this way -asmadeuxs
		// should be 630 if FlxG.height is 720
		var healthY:Float = FlxG.height * 0.875;
		if (Preferences.user.scrollType == 1)
			healthY = 70; // 50 originally
		healthBarBG.screenCenter(X);
		healthBarBG.y = healthY;
		add(healthBarBG);

		healthBar.setPosition(healthBarBG.x + 4, healthBarBG.y + 4);
		iconP1.y = healthBar.y - (iconP1.height * 0.5);
		iconP2.y = healthBar.y - (iconP2.height * 0.5);
		scoreTxt.y = healthBarBG.y + 50;
		scoreTxt.screenCenter(X);

		if (Preferences.user.showJudgeCounts) {
			judgesTxt.screenCenter(Y);
			judgesTxt.y -= 30;
			judgesTxt.y = 5;
		}
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
		var scoreMoney:String = FlxStringUtil.formatMoney(score, false, true);
		#if FEATURE_TRANSLATIONS
		var cbs:Int = PlayState.session?.comboBreaks ?? 0;
		var acc:Float = PlayState.session?.calculateAccuracy() ?? 0.0;
		layout += Translator.translateFormat('main', 'keScoreText', scoreMoney, cbs, FlxMath.roundDecimal(acc, 2), generateRanking());
		#else
		var cbs:Int = PlayState.session?.comboBreaks ?? 0;
		var acc:Float = PlayState.session?.calculateAccuracy() ?? 0.0;
		layout += 'Score: $scoreMoney | Combo Breaks: $cbs | Accuracy: ${FlxMath.roundDecimal(acc, 2)} | ${generateRanking()}';
		#end
		scoreTxt.text = layout;
		scoreTxt.objectCenter(healthBarBG, X);
		if (judgesTxt != null)
			judgesTxt.text = getJudgeCounts();
	}

	public function updateSongPosition() {
		if (songName != null) {
			var cur:String = FlxStringUtil.formatTime(songPos * 0.001, false);
			var len:String = FlxStringUtil.formatTime(songLength * 0.001, false);
			songName.text = '- ${PlayState.songTitle} ($cur / $len) -';
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

	function generateRanking():String {
		var acc:Float = PlayState.session?.calculateAccuracy() ?? 0.0;
		if (PlayState.current == null || acc <= 0.0)
			return "N/A";
		var ranking:String = PlayState.session?.judgeMan?.getClearFlag() ?? 'N/A';
		if (ranking == "N/A")
			return ranking;
		else
			ranking = '($ranking) ';

		ranking += switch acc {
			// WIFE TIME :)))) (based on Wife3)
			case(_ >= 99.9935) => true: "AAAAA";
			case(_ >= 99.980) => true: "AAAA:";
			case(_ >= 99.970) => true: "AAAA.";
			case(_ >= 99.955) => true: "AAAA";
			case(_ >= 99.90) => true: "AAA:";
			case(_ >= 99.80) => true: "AAA.";
			case(_ >= 99.70) => true: "AAA";
			case(_ >= 99) => true: "AA:";
			case(_ >= 96.50) => true: "AA.";
			case(_ >= 93) => true: "AA";
			case(_ >= 90) => true: "A:";
			case(_ >= 85) => true: "A.";
			case(_ >= 80) => true: "A";
			case(_ >= 70) => true: "B";
			case(_ >= 60) => true: "C";
			case(_ < 60) => true: "D";
			case _: "N/A";
		}
		return ranking;
	}
}
