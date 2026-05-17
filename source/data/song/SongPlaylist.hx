package data.song;

import data.song.KadeForkChart;
import data.song.SongMetadata;
import flixel.FlxG;
import flixel.math.FlxMath;
import gameplay.PlayState;
import util.Mods;

class SongPlaylist {
	public function new():Void {}

	var storyMode:Bool = false;

	var songs:Array<KadeForkChart> = [];
	var current:Int = 0;

	var curSong:KadeForkChart;
	var songMeta:KFCMeta;

	function _resetSong() {
		if (curSong != null)
			return;
		if (songs[current] != null)
			curSong = songs[current];
		else
			curSong = Song.loadFromFile('core', 'test');
		songMeta = curSong.meta;
	}

	var _songToFreeplayMeta:Map<KadeForkChart, SongMetadata> = new Map<KadeForkChart, SongMetadata>();

	public function addSongFromMetadata(song:SongMetadata, ?difficulty:String = 'normal') {
		if (song == null || song.songFolder == null)
			return null;
		var daSong = Song.loadFromFile(song.mod, song.songFolder, difficulty);
		_songToFreeplayMeta.set(daSong, song);
		songs.push(daSong);
		return daSong;
	}

	public function addSong(song:KadeForkChart) {
		if (songs == null)
			songs = [];
		songs.push(song);
		return song;
	}

	public function removeSong(song:KadeForkChart) {
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

	/**
	 * Call this whenever you need to update the song data in PlayState and Mods
	**/
	public function updateSong() {
		var metadata = getFreeplayMeta();
		if (metadata != null) {
			PlayState.songName = metadata.songFolder;
			PlayState.difficulty = metadata.curDifficulty;
			Mods.currentMod = metadata.mod;
		}
	}

	public function isStory()
		return storyMode == true;

	public function toggleStory(story:Bool)
		return storyMode = story;

	public function clear() {
		current = 0;
		songs.resize(0);
		_songToFreeplayMeta.clear();
		songMeta = null;
		curSong = null;
	}

	public function previous() {
		current = FlxMath.wrap(current - 1, 0, songs.length - 1);
		curSong = songs[current];
		songMeta = songs[current].meta;
		return curSong;
	}

	public function next() {
		current = FlxMath.wrap(current + 1, 0, songs.length - 1);
		curSong = songs[current];
		songMeta = songs[current].meta;
		return curSong;
	}

	public function getCurrent() {
		_resetSong();
		return curSong;
	}

	public function getNext() {
		if (songs.length == 0)
			return null;
		var next = songs[current + 1];
		return next;
	}

	public function getPrev() {
		if (songs.length == 0)
			return null;
		var prev = songs[current - 1];
		return prev;
	}

	public function getMeta() {
		_resetSong();
		return songMeta;
	}

	public function getFreeplayMeta() {
		_resetSong();
		return _songToFreeplayMeta.get(curSong);
	}

	public function getCurrentRaw()
		return songs[current];

	public function getMetaRaw()
		return songMeta;

	public function getFreeplayMetaRaw()
		return _songToFreeplayMeta.get(curSong);
}
