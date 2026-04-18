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

	public static function loadFromFile(jsonInput:String, ?folder:String):DynamicFormat {
		if (folder == null)
			folder = jsonInput.substring(0, jsonInput.lastIndexOf("-"));
		var pathWithSuf:String = Paths.getPath('songs/$folder/$jsonInput.json');
		var pathNoSuf:String = Paths.getPath('songs/$folder/${jsonInput.substring(0, jsonInput.lastIndexOf("-"))}.json');
		var path:String = Paths.fileExists(pathWithSuf) ? pathWithSuf : pathNoSuf;
		return new FNFPsych().fromFile(path, null, "hard");
	}
}
