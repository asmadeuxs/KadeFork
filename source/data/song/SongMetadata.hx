package data.song;

import data.ConfigTypes.LevelSong;
import flixel.util.FlxColor;

@:structInit class SongMetadata {
	public static function fromLevelSong(item:LevelSong, modId:String = 'core') {
		return new SongMetadata(item.name, item.folder, item.icon ?? "face", modId, item.difficulties, item.color);
	}

	public var name:String = "";
	public var folder:String = null;
	public var character:String = "";
	public var mod:String = null;

	public var difficulties:Array<String> = null;
	public var curDifficulty:String = null; // For playlists.
	public var color:Null<FlxColor> = null;

	public function new(name:String, folder:String, character:String, mod:String = 'core', ?difficulties:Array<String>, ?color:String):Void {
		this.name = name;
		this.character = character;
		this.folder = folder ?? name;
		this.difficulties = difficulties;
		if (color != null)
			this.color = FlxColor.fromString(color);
		this.mod = mod;
	}
}
