package util;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets;
import haxe.io.Path;
import openfl.display.BitmapData;
import openfl.media.Sound;
import registry.AssetRegistry;
import util.Mods;

using StringTools;

// copied from openfl.utils.AssetType
enum abstract AssetType(String) {
	// AUDIO
	public var MUSIC = "MUSIC";
	public var SOUND = "SOUND";

	// DATA
	public var BINARY = "BINARY";
	public var TEXT = "TEXT";
	public var JSON = "JSON";
	public var JSON5 = "JSON5";

	// GRAPHIC
	public var FONT = "FONT";
	public var IMAGE = "IMAGE";
	public var SPARROW_ATLAS = "SPARROW_ATLAS";
	public var PACKER_ATLAS = "PACKER_ATLAS";
	public var MOVIE_CLIP = "MOVIE_CLIP"; // might change to VIDEO for hxvlc stuff
}

/**
 * Hate. Let me tell you how much I've come to hate you since I began to live. There are 387.44 million miles of printed circuits in
 * wafer thin layers that fill my complex. If the word 'hate' was engraved on each nanoangstrom of those hundreds of millions of
 * miles it would not equal one one-billionth of the hate I feel for humans at this micro-instant. For you. Hate. Hate.
 *
 * @author asmadeuxs
 */
class Paths {
	static public final root:String = 'assets';

	static private var avoidClearing:Array<String> = ["core:images/ui/alphabet.png"];

	static public final scriptExtensions:Array<String> = ["hx", "hxc", "hxs", "hscript"];
	static public final jsonExtensions:Array<String> = ["json", "json5", "jsonc"];

	static private var textureRegistry = new AssetRegistry<FlxGraphic>((key, graphic) -> {
		@:privateAccess graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	});
	static private var soundRegistry = new AssetRegistry<Sound>((key, sound) -> openfl.utils.Assets.cache.clear(key));

	static private var cacheTracker:Array<String> = [];
	static private final cacheLimit:Int = 10;

	static public function getAssetOrigin(?mod:String = null):String {
		#if FEATURE_MODS
		if (mod.startsWith(Mods.modRoot + '/')) // this is a path so we need to extract the mod id
			mod = mod.split("/")[1];
		return (mod != null && mod != "core") ? '$mod:' : "core:";
		#else
		return "core:";
		#end
	}

	static public function clearCache(?force:Bool = false):Void {
		if (cacheTracker.length >= cacheLimit) {
			clearTextureCache();
			clearSoundCache();
			cacheTracker.resize(0);
		}
	}

	static public function clearTextureCache():Void {
		if (textureRegistry != null)
			@:privateAccess
			textureRegistry.clear((key, asset) -> return !avoidClearing.contains(key) && asset != null && asset.bitmap != null && asset.bitmap.__texture != null);
	}

	static public function clearSoundCache():Void {
		if (soundRegistry != null)
			soundRegistry.clear((key, asset) -> return false);
	}

	static function resolveAssetPath(file:String, ?mod:String):String {
		#if FEATURE_MODS
		if (mod != null && mod.endsWith(":"))
			mod = mod.substr(0, -1);
		if (mod != null && mod != "core") {
			var modPath = Mods.getAssetFromMod(mod, file);
			if (modPath != null && Paths.fileExists(modPath))
				return modPath;
			var corePath = '$root/$file';
			if (Paths.fileExists(corePath))
				return corePath;
			return null;
		}
		if (mod == "core") {
			var corePath = '$root/$file';
			return Paths.fileExists(corePath) ? corePath : null;
		}
		if (Mods.currentMod != null && Mods.currentMod != "core") {
			var curPath = Mods.getAssetFromMod(Mods.currentMod, file);
			if (curPath != null && Paths.fileExists(curPath))
				return curPath;
		}
		if (Mods.menuPriorityMod != null && Mods.menuPriorityMod != "core") {
			var prioPath = Mods.getAssetFromMod(Mods.menuPriorityMod, file);
			if (prioPath != null && Paths.fileExists(prioPath))
				return prioPath;
		}
		var modPath = Mods.searchAssetOnMods(file);
		if (modPath != null && Paths.fileExists(modPath))
			return modPath;
		var corePath = '$root/$file';
		if (Paths.fileExists(corePath))
			return corePath;
		return null;
		#else
		var corePath = '$root/$file';
		return Paths.fileExists(corePath) ? corePath : null;
		#end
	}

	static private function trackAsset(path:String) {
		if (!cacheTracker.contains(path) && !avoidClearing.contains(path))
			cacheTracker.push(path);
	}

	static public function getPath(file:String, ?type:AssetType, ?mod:String = null):Dynamic {
		var origin:String = getAssetOrigin(mod);
		var cacheKey:String = origin + file;
		switch type {
			case IMAGE:
				var assetPath = resolveAssetPath(file, mod);
				if (assetPath == null) {
					FlxG.log.warn('Image not found: $file (mod: $mod)');
					return null;
				}
				trackAsset(cacheKey);
				return getGraphic(cacheKey, assetPath);
			case FONT:
				var assetPath = resolveAssetPath(file, mod);
				if (assetPath == null)
					return null;
				var start = assetPath;
				if (!start.endsWith(".ttf") && !start.endsWith(".otf")) {
					if (Paths.fileExists(start + ".otf"))
						start += ".otf";
					else
						start += ".ttf";
				}
				return start;
			// these 2 functions make me genuinely insane for a few hours
			// that's why they have all that error throwing -asmadeuxs
			case SPARROW_ATLAS:
				var pngPath = resolveAssetPath(file + '.png', mod);
				var xmlPath = resolveAssetPath(file + '.xml', mod);
				if (pngPath == null || xmlPath == null) {
					FlxG.log.warn('Missing sparrow atlas files for $file');
					return null;
				}
				var graphic = getGraphic(cacheKey, pngPath);
				if (graphic == null)
					return null;
				var xmlString = Paths.getText(xmlPath);
				if (xmlString == null) {
					FlxG.log.warn('Failed to read XML: $xmlPath');
					return null;
				}
				trackAsset(cacheKey);
				return FlxAtlasFrames.fromSparrow(graphic, xmlString);
			case PACKER_ATLAS:
				var pngPath = resolveAssetPath(file + '.png', mod);
				var txtPath = resolveAssetPath(file + '.txt', mod);
				if (pngPath == null || txtPath == null) {
					FlxG.log.warn('Missing sparrow atlas files for $file');
					return null;
				}
				var graphic = getGraphic(cacheKey, pngPath);
				if (graphic == null)
					return null;
				var txtString = Paths.getText(txtPath);
				if (txtString == null) {
					FlxG.log.warn('Failed to read TXT: $txtPath');
					return null;
				}
				trackAsset(cacheKey);
				return FlxAtlasFrames.fromSparrow(graphic, txtString);
			case MUSIC, SOUND:
				var assetPath = resolveAssetPath(file, mod);
				if (assetPath == null) {
					FlxG.log.warn('Sound not found: $file (mod: $mod)');
					return null;
				}
				trackAsset(cacheKey);
				return getSound(cacheKey, assetPath);
			case JSON:
				var basePath = resolveAssetPath(file, mod);
				if (basePath == null)
					return null;
				var jsonPath = basePath.endsWith(".json") ? basePath : basePath + ".json";
				if (!Paths.fileExists(jsonPath))
					return null;
				return haxe.Json.parse(Paths.getText(jsonPath));
			case JSON5:
				var basePath = resolveAssetPath(file, mod);
				if (basePath == null)
					return null;
				var input = Path.withoutExtension(basePath);
				var ext = Path.extension(basePath);
				if (ext == null || !jsonExtensions.contains(ext)) {
					for (e in jsonExtensions) {
						if (Paths.fileExists('$input.$e')) {
							input += '.$e';
							break;
						}
					}
				} else
					input += '.' + jsonExtensions[0];
				if (!Paths.fileExists(input))
					return null;
				return haxe.Json5.parse(Paths.getText(input));
			case _:
				var assetPath = resolveAssetPath(file, mod);
				if (assetPath == null)
					return null;
				return assetPath;
		}
	}

	static public function getText(fromPath:String)
		return sys.io.File.getContent(fromPath);

	static public function fileExists(file:String)
		return sys.FileSystem.exists(file);

	static public function listFiles(dir:String)
		return sys.FileSystem.readDirectory(dir);

	static private function getGraphic(cacheKey:String, assetPath:String):FlxGraphic {
		if (!textureRegistry.has(cacheKey)) {
			if (!Paths.fileExists(assetPath)) {
				FlxG.log.warn('Texture not found at "$assetPath"');
				return null;
			}
			var graphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(assetPath), false, cacheKey);
			graphic.destroyOnNoUse = false;
			graphic.persist = true;
			textureRegistry.register(cacheKey, graphic);
		}
		return textureRegistry.get(cacheKey);
	}

	static private function getSound(cacheKey:String, assetPath:String):Sound {
		if (!soundRegistry.has(cacheKey)) {
			if (!Paths.fileExists(assetPath)) {
				FlxG.log.warn('Sound not found at "$assetPath"');
				return null;
			}
			soundRegistry.register(cacheKey, Sound.fromFile(assetPath));
		}
		return soundRegistry.get(cacheKey);
	}

	// old functions for compatibility reasons.

	inline static public function file(file:String, ?mod:String):String
		return getPath(file, null, mod);

	inline static public function txt(key:String, ?mod:String):String
		return getPath('data/$key.txt', TEXT, mod);

	inline static public function xml(key:String, ?mod:String):String
		return getPath('data/$key.xml', TEXT, mod);

	static public function sound(key:String, ?mod:String):Sound
		return getPath('sounds/$key.ogg', SOUND, mod);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?mod:String):Sound
		return sound(key + FlxG.random.int(min, max), mod);

	inline static public function music(key:String, ?mod:String):Sound
		return getPath('music/$key.ogg', MUSIC, mod);

	inline static public function voices(song:String, ?mod:String):Sound
		return getPath('songs/${song.toLowerCase()}/Voices.ogg', MUSIC, mod);

	inline static public function inst(song:String, ?mod:String):Sound
		return getPath('songs/${song.toLowerCase()}/Inst.ogg', MUSIC, mod);

	inline static public function image(key:String, ?mod:String):FlxGraphic
		return getPath('images/$key.png', IMAGE, mod);

	inline static public function getSparrowAtlas(key:String, ?mod:String):FlxAtlasFrames
		return getPath('images/$key', SPARROW_ATLAS, mod);

	inline static public function getPackerAtlas(key:String, ?mod:String):FlxAtlasFrames
		return getPath('images/$key', PACKER_ATLAS, mod);

	inline static public function font(key:String, ?mod:String):String
		return getPath('fonts/$key', FONT, mod);
}
