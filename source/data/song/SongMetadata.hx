package data.song;

import data.ConfigTypes.LevelSong;

@:structInit class SongMetadata {
	public static function fromLevelSong(item:LevelSong, modId:String = 'core') {
		return new SongMetadata(item.name, item.folder, item.icon ?? "face", modId, item.difficulties);
	}

	public var songName:String = "";
	public var songFolder:String = null;
	public var songCharacter:String = "";
	public var difficulties:Array<String> = null;
	public var curDifficulty:String = null; // For playlists.
	public var mod:String = null;

	public function new(songName:String, songFolder:String, songCharacter:String, mod:String = 'core', ?difficulties:Array<String>):Void {
		this.songName = songName;
		this.songCharacter = songCharacter;
		this.songFolder = songFolder ?? songName;
		this.difficulties = difficulties;
		this.mod = mod;
	}
}
