package registry;

import util.CoolUtil;
import util.Mods;

using haxe.io.Path;
using StringTools;

typedef LevelLabel = {
	texture:String,
}

typedef LevelSong = {
	name:String,
	folder:String,
	?album:String,
	?icon:String,
	?difficulties:Array<String>,
}

typedef LevelData = {
	tagline:String,
	difficulties:Array<String>,
	labelObject:LevelLabel,
	songs:Array<LevelSong>
}

class LevelRegistry extends BaseRegistry<LevelData> {
	public static var current:LevelRegistry = null;

	var ordered:Map<String, Array<LevelData>> = new Map();

	public function new():Void {
		super("LevelRegistry");
		current = this;
	}

	override function destroy() {
		ordered.clear();
		ordered = null;
		super.destroy();
	}

	public function loadLevels(?mod:String = null) {
		if (!ordered.exists(mod))
			ordered.set(mod, []);
		else
			ordered[mod].resize(0);
		var origin = Paths.getAssetOrigin(mod);
		var levelDir = Paths.resolveAssetPath('data/levels', mod);

		try {
			if (!Paths.fileExists(levelDir)) {
				// trace('Levels not found for $mod');
				return;
			}
			if (mod == "core")
				trace('Loading built-in levels (from assets folder)');
			else
				trace('Loading levels from mod "$mod"');
			var orderFile = Paths.resolveAssetPath('data/levelList.txt', mod);
			var levelNames:Array<String> = [];
			var useOrderFile = Paths.fileExists(orderFile);
			if (useOrderFile) {
				var content = Paths.getText(orderFile);
				levelNames = CoolUtil.coolList(content);
			}
			var availableLevels:Map<String, String> = new Map();
			for (file in Paths.listFiles(levelDir)) {
				var ext = file.extension();
				if (!Paths.jsonExtensions.contains(ext))
					continue;
				var name = file.withoutExtension();
				var filePath = haxe.io.Path.addTrailingSlash(levelDir) + file;
				if (Paths.fileExists(filePath))
					availableLevels.set(name, filePath);
			}
			var namesToProcess = useOrderFile ? levelNames : [for (name in availableLevels.keys()) name];
			for (name in namesToProcess) {
				var filePath = availableLevels.get(name);
				if (filePath == null) {
					if (useOrderFile)
						trace('Level "$name" listed in levelList.txt but not found in $levelDir');
					continue;
				}
				var regKey = '$origin$name';
				var level:LevelData = cast haxe.Json5.parse(Paths.getText(filePath));
				if (level != null) {
					register(regKey, level, true);
					ordered[mod].push(level);
				} else {
					trace('Level "$filePath" is not valid JSON5 (check spelling?)');
				}
			}
		}
		catch (e:haxe.Exception) {
			Sys.println(e.message);
			Sys.println(e.details());
		}
	}

	public function getModsLoaded():Array<String>
		return [for (key in ordered.keys()) key];

	/**
	 * Returns all LevelData for a given mod 
	 *
	 * will either be in the order specified in levelList.txt OR the filesystem order (if the file doesn't exist)
	 */
	public function getLevelData(mod:String):Array<LevelData>
		return ordered.get(mod);

	/**
	 * Returns every LevelSong from every level in the given mod.
	 */
	public function getModLevelSongs(mod:String):Array<LevelSong> {
		var songs:Array<LevelSong> = [];
		var levels = ordered.get(mod);
		// this is dizzying
		if (levels != null)
			for (level in levels)
				if (level.songs != null)
					for (song in level.songs)
						songs.push(song);
		return songs;
	}
}
