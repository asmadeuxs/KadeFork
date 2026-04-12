package util;

import util.CoolUtil;

using StringTools;

private typedef ModConfig = {name:String, ?version:String, ?description:String}

class Mods {
	public static final modRoot:String = 'mods';
	public static final apiVer:String = "1.0.0";
	public static final defaultDesc:String = "No description provided.";

	private static var allMods:Map<String, ModConfig> = [];
	private static var activeMods:Array<String> = [];

	/**
	 * Scans for mods in the mods folder
	 * @param enableActive Checks for active mods and enables them
	 * @return allMods
	 */
	public static function scan(?enableActive:Bool = false):Map<String, ModConfig> {
		allMods.clear();
		#if FEATURE_MODS
		if (!Paths.fileExists(modRoot)) {
			trace('Mods directory "$modRoot" not found (was it deleted?)');
			return allMods;
		}
		for (modId in Paths.listFiles(modRoot)) {
			if(!sys.FileSystem.isDirectory(modId))
				continue;
			if (!Paths.fileExists('$modRoot/$modId/mod.txt')) {
				trace('Mod "$modId" not added (missing mod.txt file.)');
				trace('That file must look like this:\n');
				trace('Mod Name|Mod Version (i.e: 1.0.0)|Mod description.\n');
				continue;
			}
			var configFile:String = Paths.getText('$modRoot/$modId/mod.txt').trim();
			var modData:Array<String> = configFile.split("|");
			if (modData.length < 1) {
				trace('Mod file too short (must have at least its name.)');
				continue;
			}
			allMods.set(modId, {name: modData[0], version: modData[1] ?? apiVer, description: modData[2] ?? defaultDesc});
		}
		if (enableActive)
			scanActiveMods();
		#elseif debug
		trace('Mods feature disabled in this build (did you compile with FEATURE_MODS defined?)');
		#end
		return allMods;
	}

	public static function scanActiveMods():Array<String> {
		var modsListFile:String = '$modRoot/modList.txt';
		if (!Paths.fileExists(modsListFile)) {
			trace('Mods list file "$modRoot" not found (was it deleted?)');
			trace('No mods were enabled or disabled.');
			return activeMods;
		}
		activeMods.resize(0);
		for (info in CoolUtil.coolList(Paths.getText(modsListFile))) {
			var data = info.split("|");
			if (data.length > 1) {
				if (data[1] == "true")
					activeMods.push(data[0]);
			} else {
				trace('Mod folder ${data[0]} is not properly set on the mods list (not enough data.)');
				trace('It usually looks like this:\n');
				trace('mod_folder|true (or false)\n');
			}
		}
		return activeMods;
	}

	public static function getAssetFromMod(file:String) {
		var assetPath:String = null;
		var topPath:String = '$modRoot/${activeMods[0]}/$file';
		if (Paths.fileExists(topPath)) // prioritize top mod
			assetPath = topPath;
		else {
			for (i in 1...activeMods.length) {
				var modPath:String = '$modRoot/${activeMods[i]}/$file';
				if (Paths.fileExists(modPath)) {
					assetPath = modPath;
					break;
				}
			}
		}
		return assetPath;
	}

	public static function getEnabled()
		return activeMods;
}
