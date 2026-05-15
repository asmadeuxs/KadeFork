package data.song;

import data.song.SongMetadata;
import flixel.FlxG;
import flixel.math.FlxMath;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacyMetaValues;
import moonchart.formats.fnf.legacy.FNFPsych;

class SongPlaylist {
	var storyMode:Bool = false;

	var songs:Array<DynamicFormat> = [];
	var current:Int = 0;

	var curSong(default, set):DynamicFormat;
	var songMeta:BasicMetaData;

	var _songToFreeplayMeta:Map<DynamicFormat, SongMetadata> = new Map();

	public function new():Void {}

	function set_curSong(to:DynamicFormat):DynamicFormat {
		if (to == null)
			to = Song.loadFromFile('core', 'test');
		songMeta = to.getChartMeta();
		return curSong = to;
	}

	public function addSongFromMetadata(song:SongMetadata, ?difficulty:String = 'normal') {
		if (song == null || song.songFolder == null)
			return null;
		var daSong = Song.loadFromFile(song.mod, song.songFolder, difficulty);
		_songToFreeplayMeta.set(daSong, song);
		songs.push(daSong);
		return daSong;
	}

	public function addSong(song:DynamicFormat) {
		if (songs == null)
			songs = [];
		songs.push(song);
		return song;
	}

	public function removeSong(song:DynamicFormat) {
		if (songs == null)
			songs = [];
		songs.remove(song);
		return song;
	}

	public function removeSongFromTitle(songTitle:String) {
		for (song => meta in _songToFreeplayMeta) {
			if (meta.songName == songTitle) {
				var index:Int = songs.indexOf(song);
				if (index != -1)
					songs.splice(index, 1);
				break;
			}
		}
	}

	public function removeSongFromFolder(folderName:String) {
		for (song => meta in _songToFreeplayMeta) {
			if (meta.songFolder == folderName) {
				var index:Int = songs.indexOf(song);
				if (index != -1)
					songs.splice(index, 1);
				break;
			}
		}
	}

	public function isStory()
		return storyMode == true;

	public function toggleStory(story:Bool)
		return storyMode = story;

	public function clear() {
		_songToFreeplayMeta.clear();
		for (i in 0...songs.length)
			songs[i] = null;
		songs.resize(0);
	}

	public function previous() {
		current = FlxMath.wrap(current - 1, 0, songs.length - 1);
		curSong = songs[current];
		return curSong;
	}

	public function next() {
		current = FlxMath.wrap(current + 1, 0, songs.length - 1);
		curSong = songs[current];
		return curSong;
	}

	public function getCurrent() {
		if (curSong != songs[current])
			curSong = songs[current];
		return songs[current];
	}

	public function getMeta()
		return songMeta;

	public function getFreeplayMeta()
		return _songToFreeplayMeta.get(curSong);

	public function getNext() {
		var next = songs[current + 1];
		return next;
	}

	public function getPrev() {
		var prev = songs[current - 1];
		return prev;
	}
}
