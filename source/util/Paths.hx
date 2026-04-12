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
	static public var jsonExtensions:Array<String> = ["json", "json5", "jsonc"];

	static private var textureRegistry = new AssetRegistry<FlxGraphic>((key, graphic) -> {
		@:privateAccess {
			if (graphic.bitmap?.__texture != null)
				graphic.bitmap.__texture.dispose();
		}
		FlxG.bitmap.remove(graphic);
	});

	static private var soundRegistry = new AssetRegistry<Sound>((key, sound) -> {
		openfl.utils.Assets.cache.clear(key);
	});

	public static function getAssetOrigin(?mod:String = null):String {
		#if FEATURE_MODS
		if (!mod.startsWith(root) && mod.contains("/")) // probably a path and not an actual mod id
			mod = mod.split("/")[1];
		return (mod != null && mod != "core") ? '$mod:' : "core:";
		#else
		return "core:";
		#end
	}

	public static function getPath(file:String, ?type:AssetType, ?mod:String = null):Dynamic {
		var origin:String = getAssetOrigin(mod);
		var corePath:String = '$root/$file';
		var cacheKey:String = origin + file;
		var assetPath:String = corePath;
		#if FEATURE_MODS
		if (mod == null) {
			var modPath:String = Mods.getAssetFromMod(file);
			if (modPath != null)
				assetPath = modPath;
		} else {
			var modPath:String = '${Mods.modRoot}/$mod/$file';
			if (Paths.fileExists(modPath))
				assetPath = modPath;
		}
		#end

		switch type {
			case IMAGE:
				if (!textureRegistry.has(cacheKey)) {
					if (!Paths.fileExists(assetPath)) {
						FlxG.log.warn('Texture not found at "$assetPath"');
						return GraphicLogo;
					}
					var graphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(assetPath), false, cacheKey);
					graphic.destroyOnNoUse = false;
					graphic.persist = true;
					textureRegistry.register(cacheKey, graphic);
				}
				return textureRegistry.get(cacheKey);
			case FONT:
				var start:String = assetPath;
				if (!assetPath.endsWith(".ttf") && !assetPath.endsWith(".otf")) {
					if (Paths.fileExists(start + ".otf"))
						start = start + ".otf";
					else
						start = start + ".ttf";
				}
				return start;
			// case SPARROW_ATLAS:
			//	var p:String = Path.withoutExtension(assetPath);
			//	return FlxAtlasFrames.fromSparrow(getPath(p, IMAGE), file('$p.xml'));
			// case PACKER_ATLAS:
			//	var p:String = Path.withoutExtension(assetPath);
			//	return FlxAtlasFrames.fromSpriteSheetPacker(getPath(p, IMAGE), file('$p.txt'));
			// music
			case MUSIC, SOUND:
				if (!soundRegistry.has(cacheKey)) {
					if (!Paths.fileExists(assetPath)) {
						FlxG.log.warn('Sound not found at "$assetPath"');
						return null;
					}
					soundRegistry.register(cacheKey, Sound.fromFile(assetPath));
				}
				return soundRegistry.get(cacheKey);
			// data
			case JSON:
				var input:String = assetPath;
				if (!input.endsWith(".json"))
					input = '$input.json';
				return haxe.Json.parse(Paths.getText(input));
			case JSON5:
				var input:String = Path.withoutExtension(assetPath);
				var ext:String = Path.extension(assetPath);
				if (ext == null || !jsonExtensions.contains(ext)) {
					for (ext in jsonExtensions) {
						if (Paths.fileExists('$input.$ext'))
							input += '.$ext';
					}
				} else
					input += "." + jsonExtensions[0];
				return haxe.Json5.parse(Paths.getText(input));
			case _:
				return assetPath;
		}
	}

	static public function getText(fromPath:String)
		return sys.io.File.getContent(fromPath);

	static public function fileExists(file:String)
		return sys.FileSystem.exists(file);

	static public function listFiles(dir:String)
		return sys.FileSystem.readDirectory(dir);

	// old functions for compatibility reasons.

	inline static public function file(file:String)
		return getPath(file);

	inline static public function txt(key:String)
		return getPath('data/$key.txt', TEXT);

	inline static public function xml(key:String)
		return getPath('data/$key.xml', TEXT);

	static public function sound(key:String, ?library:String):Sound
		return getPath('sounds/$key.ogg', SOUND);

	inline static public function soundRandom(key:String, min:Int, max:Int):Sound
		return sound(key + FlxG.random.int(min, max));

	inline static public function music(key:String):Sound
		return getPath('music/$key.ogg', MUSIC);

	inline static public function voices(song:String)
		return getPath('songs/${song.toLowerCase()}/Voices.ogg', MUSIC);

	inline static public function inst(song:String)
		return getPath('songs/${song.toLowerCase()}/Inst.ogg', MUSIC);

	inline static public function image(key:String)
		return getPath('images/$key.png', IMAGE);

	inline static public function getSparrowAtlas(key:String,)
		return FlxAtlasFrames.fromSparrow(image(key), file('images/$key.xml'));

	inline static public function getPackerAtlas(key:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key), file('images/$key.txt'));

	inline static public function font(key:String)
		return getPath('fonts/$key', FONT);
}
