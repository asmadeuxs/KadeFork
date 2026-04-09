package data.song;

import data.song.Section;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

typedef SwagSong = {
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Int;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
}

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

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong {
		if (folder == null)
			folder = jsonInput.substring(0, jsonInput.lastIndexOf("-"));
		var pathWithSuf:String = Paths.getPath('songs/$folder/$jsonInput.json');
		var pathNoSuf:String = Paths.getPath('songs/$folder/${jsonInput.substring(0, jsonInput.lastIndexOf("-"))}.json');
		var path:String = Paths.fileExists(pathWithSuf) ? pathWithSuf : pathNoSuf;

		trace('loading song at path $path');
		var rawJson = Paths.getText(path).trim();
		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);
		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(rawJson:String):SwagSong
		return cast Json.parse(rawJson).song;
}
