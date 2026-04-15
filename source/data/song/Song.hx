package data.song;

import data.song.Song.Section;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFLegacy;

using StringTools;

typedef SwagSection = moonchart.formats.fnf.legacy.FNFLegacy.FNFLegacySection;
typedef SwagSong = FNFLegacyFormat;

class Song {
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';

	public function new(song, notes, bpm) {
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function detect() {
		//
	}

	public static function loadFromFile(jsonInput:String, ?folder:String):DynamicFormat {
		if (folder == null)
			folder = jsonInput.substring(0, jsonInput.lastIndexOf("-"));
		var pathWithSuf:String = Paths.getPath('songs/$folder/$jsonInput.json');
		var pathNoSuf:String = Paths.getPath('songs/$folder/${jsonInput.substring(0, jsonInput.lastIndexOf("-"))}.json');
		var path:String = Paths.fileExists(pathWithSuf) ? pathWithSuf : pathNoSuf;

		var funkinLegacy = new FNFLegacy().fromFile(path, null, "hard");
		return funkinLegacy;
	}
}

class Section {
	public var sectionNotes:Array<Dynamic> = [];

	public var lengthInSteps:Int = 16;
	public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(lengthInSteps:Int = 16) {
		this.lengthInSteps = lengthInSteps;
	}
}
