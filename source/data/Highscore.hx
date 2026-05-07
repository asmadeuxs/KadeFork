package data;

import flixel.FlxG;

class Highscore {
	public static var songScores:Map<String, Int> = new Map();
	public static var levelScores:Map<String, Int> = new Map();

	private static function formatSong(song:String, diff:String):String
		return '$song-$diff';

	// TODO: make this mod compliant? some mods may have identically named songs and whatever

	public static function saveScore(song:String, diff:String = 'normal', score:Int = 0):Void {
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong))
			setSongHighscore(daSong, score);
		else if (songScores.get(daSong) < score)
			setSongHighscore(daSong, score);
	}

	public static function getScore(song:String, diff:String):Int {
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong))
			setSongHighscore(daSong, 0);
		return songScores.get(daSong);
	}

	public static function getCampaignScore(levelID:String, diff:String):Int {
		var level:String = formatSong('level-$levelID', diff);
		if (!levelScores.exists(level))
			setLevelHighscore(level, 0);
		return levelScores.get(level);
	}

	static function setSongHighscore(song:String, score:Int):Void {
		songScores.set(song, score);
		saveSongHighscores();
	}

	static function setLevelHighscore(levelID:String, score:Int):Void {
		levelScores.set(levelID, score);
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
