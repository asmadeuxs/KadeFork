package data;

import flixel.FlxG;

typedef ScoreSave = {
	score:Int,
	misses:Int,
	comboBreaks:Int,
	accuracy:Float,
	combo:Int
}

class Highscore {
	public static var songScores:Map<String, ScoreSave> = new Map<String, ScoreSave>();
	public static var levelScores:Map<String, ScoreSave> = new Map<String, ScoreSave>();

	private static function formatSong(song:String, diff:String):String
		return '$song-$diff';

	public static function saveScore(song:String, diff:String = 'normal', save:ScoreSave):Void {
		var daSong:String = formatSong(song, diff);
		var existing:ScoreSave = songScores.get(daSong);
		if (existing == null || save.score > existing.score)
			setSongHighscore(daSong, save);
	}

	public static function saveLevelScore(levelID:String, diff:String = 'normal', save:ScoreSave):Void {
		var daLevel:String = formatSong('level-$levelID', diff);
		var existing:ScoreSave = levelScores.get(daLevel);
		if (existing == null || save.score > existing.score)
			setLevelHighscore(daLevel, save);
	}

	public static function getScore(song:String, diff:String):Int {
		var daSong:String = formatSong(song, diff);
		var existing:ScoreSave = songScores.get(daSong);
		return (existing != null) ? existing.score : 0;
	}

	public static function getCampaignScore(levelID:String, diff:String):Int {
		var level:String = formatSong('level-$levelID', diff);
		var existing:ScoreSave = levelScores.get(level);
		return (existing != null) ? existing.score : 0;
	}

	public static function getFullScore(song:String, diff:String):Null<ScoreSave> {
		var daSong:String = formatSong(song, diff);
		return songScores.get(daSong);
	}

	public static function getFullLevelScore(levelID:String, diff:String):Null<ScoreSave> {
		var daLevel:String = formatSong('level-$levelID', diff);
		return levelScores.get(daLevel);
	}

	static function setSongHighscore(song:String, save:ScoreSave):Void {
		songScores.set(song, save);
		saveSongHighscores();
	}

	static function setLevelHighscore(levelID:String, save:ScoreSave):Void {
		levelScores.set(levelID, save);
		saveCampaignHighscores();
	}

	public static function saveAll():Void {
		saveSongHighscores();
		saveCampaignHighscores();
	}

	public static function saveSongHighscores():Void {
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/scores', company);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	public static function saveCampaignHighscores():Void {
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/scores', company);
		FlxG.save.data.levelScores = levelScores;
		FlxG.save.flush();
	}

	public static function load():Void {
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/scores', company);

		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;
		if (FlxG.save.data.levelScores != null)
			levelScores = FlxG.save.data.levelScores;
	}
}
