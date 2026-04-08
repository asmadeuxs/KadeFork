package data.song;

@:structInit class SongMetadata {
	public var songName:String = "";
	public var songFolder:String = null;
	public var songCharacter:String = "";
	public var week:Int = 0;

	public function new(songName:String, songFolder:String, songCharacter:String):Void {
		this.songName = songName;
		this.songCharacter = songCharacter;
		this.songFolder = songFolder;
	}
}
