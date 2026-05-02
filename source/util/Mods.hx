package util;

import flixel.FlxG;
import util.CoolUtil;

using StringTools;

private typedef ModConfig = {name:String, ?version:String, ?description:String}

class Mods {
	public static final modRoot:String = 'mods';
	public static final apiVer:String = "1.0.0";
	public static final defaultDesc:String = "No description provided.";

	public static var currentMod:String = 'core';
	public static var menuPriorityMod:String = null;

	private static var allMods:Map<String, ModConfig> = [];
	private static var activeMods:Array<String> = [];

	public static function saveMods() {
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/mods', company);
		if (FlxG.save.data.menuPriorityMod != Mods.menuPriorityMod)
			FlxG.save.data.menuPriorityMod = Mods.menuPriorityMod;
		FlxG.save.data.activeMods = activeMods.copy();
		FlxG.save.flush();
	}

	public static function loadMods() {
		var company:String = lime.app.Application.current.meta["file"];
		var appName:String = lime.app.Application.current.meta["company"];
		FlxG.save.bind('$appName/mods', company);
		if (FlxG.save.data.menuPriorityMod != null)
			Mods.menuPriorityMod = FlxG.save.data.menuPriorityMod;
		if (FlxG.save.data.activeMods != null) {
			var saved:Array<String> = FlxG.save.data.activeMods;
			var available = getAvailableMods();
			activeMods = saved.filter(modId -> available.contains(modId));
			if (activeMods.length != saved.length)
				saveMods();
		} else {
			activeMods = getAvailableMods();
			saveMods();
		}
	}

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
			var root:String = haxe.io.Path.removeTrailingSlashes(modRoot);
			if (!sys.FileSystem.isDirectory('$root/$modId'))
				continue;
			if (!Paths.fileExists('$root/$modId/mod.txt')) {
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
			activeMods.push(modId);
			trace('Loaded mod folder $modId');
		}
		// TODO: re-enable this, I'll just enable every mod at once for now
		// if (enableActive)
		//	scanActiveMods();
		#elseif debug
		trace('Mods feature disabled in this build (did you compile with FEATURE_MODS defined?)');
		#end
		return allMods;
	}

	public static function getAvailableMods():Array<String> {
		var mods:Array<String> = [];
		#if FEATURE_MODS
		if (!Paths.fileExists(modRoot))
			return mods;
		for (modId in Paths.listFiles(modRoot)) {
			var path = haxe.io.Path.removeTrailingSlashes('$modRoot/$modId');
			if (sys.FileSystem.isDirectory(path) && Paths.fileExists('$path/mod.txt'))
				mods.push(modId);
		}
		#end
		return mods;
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

	public static function searchAssetOnMods(file:String) {
		var assetPath:String = null;
		var found:Bool = false;
		if (currentMod != null && currentMod != 'core') {
			var topPath:String = '$modRoot/${currentMod}/$file';
			if (Paths.fileExists(topPath)) { // prioritize current mod
				assetPath = topPath;
				found = true;
			}
		}
		if (!found) {
			for (i in 0...activeMods.length) {
				var modPath:String = '$modRoot/${activeMods[i]}/$file';
				if (Paths.fileExists(modPath)) {
					assetPath = modPath;
					break;
				}
			}
		}
		return assetPath;
	}

	public static function getAssetFromMod(mod:String, file:String) {
		var assetPath:String = null;
		var path:String = '$modRoot/${mod}/$file';
		if (mod != null && mod != 'core' && Paths.fileExists(path))
			assetPath = path;
		return assetPath;
	}

	public static function getEnabled(?appendCore:Bool = true):Array<String> {
		var ids:Array<String> = [];
		if (appendCore)
			ids.push('core');
		for (modId in activeMods)
			ids.push(modId);
		return ids;
	}

	// wanted mods to be able to override the built-in sounds
	// that is assuming they don't have scripts of their own to override their menus
	// its finicky, it works, so whatever. -asmadeuxs
	inline public static function menuImage(key:String):flixel.graphics.FlxGraphic
		return Paths.image(key, (Mods.menuPriorityMod != null && Mods.menuPriorityMod != "core") ? Mods.menuPriorityMod : "core");

	inline public static function menuSound(key:String):openfl.media.Sound
		return Paths.sound(key, (Mods.menuPriorityMod != null && Mods.menuPriorityMod != "core") ? Mods.menuPriorityMod : "core");

	inline public static function menuMusic(key:String):openfl.media.Sound
		return Paths.music(key, (Mods.menuPriorityMod != null && Mods.menuPriorityMod != "core") ? Mods.menuPriorityMod : "core");

	inline public static function menuSparrowAtlas(key:String):flixel.graphics.frames.FlxAtlasFrames
		return Paths.getSparrowAtlas(key, (Mods.menuPriorityMod != null && Mods.menuPriorityMod != "core") ? Mods.menuPriorityMod : "core");

	inline public static function menuFont(key:String):String
		return Paths.font(key, (Mods.menuPriorityMod != null && Mods.menuPriorityMod != "core") ? Mods.menuPriorityMod : "core");
}
