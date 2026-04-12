package gameplay.hud;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import gameplay.PlayState;
import moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacyMetaValues;
import ui.HealthIcon;

class Kade extends BaseHUD {
	public var healthBarBG:FlxSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var judgesTxt:FlxText;

	var songPos:Float = 0;

	override public function new():Void {
		super();
		if (Preferences.user.showSongPosition) // I dont wanna talk about this code :(
		{
			var songPosBG = new FlxSprite(0, 10).loadGraphic(Paths.image('gameplay/ui/healthBar'));
			if (Preferences.user.scrollType == 1)
				songPosBG.y = FlxG.height * 0.9 + 45;
			songPosBG.screenCenter(X);
			add(songPosBG);

			var songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
				'songPos', 0, 90000);
			songPosBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
			add(songPosBar);

			var songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - 20, songPosBG.y, 0, PlayState.moonMeta.title, 16);
			if (Preferences.user.scrollType == 1)
				songName.y -= 3;
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(songName);
		}

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('gameplay/ui/healthBar'));
		if (Preferences.user.scrollType == 1)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8),
			PlayState.current, 'health', 0, 2);
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		add(healthBar);

		scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 50, 0, "", 20);
		if (!Preferences.user.accuracyDisplay)
			scoreTxt.x = healthBarBG.x + healthBarBG.width / 2;
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(scoreTxt);
		if (Preferences.user.showJudgeCounts) {
			judgesTxt = new FlxText(5, 0, FlxG.width, "");
			judgesTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
			judgesTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.0);
			judgesTxt.screenCenter(Y);
			judgesTxt.y -= 30;
			add(judgesTxt);
		}
		updateScoreText();

		var songText:FlxText = new FlxText(5, 0, 0, '${PlayState.moonMeta.title} ${PlayState.difficulty.toUpperCase()} - KE v${Main.versions.KADE}', 12);
		songText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		songText.y = (FlxG.height - songText.height) - 3;
		add(songText);

		iconP1 = new HealthIcon(PlayState.moonMeta.extraData.get(PLAYER_1) ?? "bf", true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(PlayState.moonMeta.extraData.get(PLAYER_2) ?? "bf", false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		songPos = Conductor.songPosition;
		// icon
		var iconOffset:Int = 26;
		if (iconP1 != null) {
			// TODO: restore this
			/*if (FlxG.keys.justPressed.NINE) {
				if (iconP1.animation.curAnim.name == 'bf-old')
					iconP1.animation.play(PlayState.SONG.player1);
				else
					iconP1.animation.play('bf-old');
			}*/
			iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
			iconP1.setGraphicSize(FlxMath.lerp(150, iconP1.width, elapsed * 30));
			iconP1.updateHitbox();
		}
		if (iconP2 != null) {
			iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
			iconP2.setGraphicSize(FlxMath.lerp(150, iconP2.width, elapsed * 30));
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
	}

	override function updateScoreText(?miss:Bool = false):Void {
		var layout:String;
		if (Preferences.user.showNps)
			layout = '${PlayState.nps} / ${PlayState.maxNps} NPS | ';
		else
			layout = '';
		if (Preferences.user.accuracyDisplay) {
			layout += 'Score: ${PlayState.songScore}';
			layout += ' | Misses: ${PlayState.misses}';
			layout += ' | Accuracy: ${FlxMath.roundDecimal(PlayState.accuracy, 2)}% | ${generateRanking()}';
		} else
			layout += 'Score: ${PlayState.songScore}';
		scoreTxt.text = layout;
		if (judgesTxt != null)
			judgesTxt.text = PlayState.judgementData.listCounts();
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
		if (PlayState.current == null || PlayState.accuracy <= 0.0)
			return "N/A";
		var ranking:String = PlayState.judgementData.getClearFlag();
		if (ranking == "N/A")
			return ranking;
		else
			ranking = '($ranking) ';

		// WIFE TIME :)))) (based on Wife3)
		ranking += switch PlayState.accuracy {
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
