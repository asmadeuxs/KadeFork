package data.song;

import data.song.KadeForkChart;
import moonchart.Moonchart;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFPsych;
import openfl.media.Sound;

using StringTools;

class Song {
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

	public static function loadFromFile(mod:String, song:String, ?difficulty:String):KadeForkChart {
		var path:String = getSongPath(mod, song, difficulty);
		if (path == null)
			throw 'Song file not found for $song ($difficulty) in mod $mod';
		var fnfPsychFormat = new FNFPsych().fromFile(path, null, null);
		return new KFCHandler().fromFormat(fnfPsychFormat);
	}

	public static function createTracks(metadata:KFCMeta, songName:String, difficulty:String, mod:String = 'core'):Array<Sound> {
		var tracks:Array<Sound> = [];
		var variationSuf:String = '-$difficulty.ogg';

		var instFile:String = Paths.resolveSongPath('Inst', songName, difficulty, mod);
		var isVariation:Bool = instFile.endsWith(variationSuf);
		var isMultiVocals:Bool = false;

		tracks.push(Paths.getPath(instFile, MUSIC, mod));

		// try to find per-player vocals
		var p1 = null;
		for (p1track in [metadata.player, 'Player']) {
			var trackPath:String = Paths.resolveSongPath('Voices-$p1track', songName, difficulty, mod);
			if (isVariation && !trackPath.endsWith(variationSuf))
				break;
			p1 = Paths.getPath(trackPath, MUSIC, mod);
			if (p1 != null)
				break;
		}
		if (p1 != null) {
			isMultiVocals = true;
			Conductor.current.addTrack(p1);
			var p2 = null;
			for (p2track in [metadata.opponent, 'Opponent']) {
				var trackPath:String = Paths.resolveSongPath('Voices-$p2track', songName, difficulty, mod);
				if (isVariation && !trackPath.endsWith(variationSuf))
					break;
				p2 = Paths.getPath(trackPath, MUSIC, mod);
				if (p2 != null)
					break;
			}
			if (p2 != null)
				Conductor.current.addTrack(p2);
		}

		if (!isMultiVocals) {
			// fallback to old system
			var voicesFile:String = Paths.resolveSongPath('Inst', songName, difficulty, mod);
			if (!isVariation || (isVariation && voicesFile.endsWith(variationSuf)))
				Conductor.current.addTrack(Paths.getPath(voicesFile, MUSIC, mod));
		}

		return tracks;
	}
}
