package data.song;

import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFPsych;

using StringTools;

typedef SwagSection = moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacySection;
typedef SwagSong = PsychJsonFormat;

class Song {
	public static function detect() {
		//
	}

	public static function getSongPath(mod:String, song:String, difficulty:String = 'normal'):String {
		var paths:Array<String> = [
			'songs/$song/$song-$difficulty',
			'songs/$song/$song-$difficulty-chart',
			'songs/$song/$song-chart',
			'songs/$song/$difficulty',
			'songs/$song/$song',
		];

		var path:String = null;
		for (possiblePath in paths) {
			var candidate:String = Paths.resolveAssetPath(possiblePath + '.json', mod);
			if (Paths.fileExists(candidate)) {
				path = candidate;
				break;
			}
		}

		return path;
	}

	public static function loadFromFile(mod:String, song:String, ?difficulty:String):DynamicFormat {
		var path:String = getSongPath(mod, song, difficulty);
		if (path == null)
			throw 'Song file not found for $song ($difficulty) in mod $mod';
		return new FNFPsych().fromFile(path, null, null);
	}
}
