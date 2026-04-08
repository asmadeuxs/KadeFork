package data;

import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.media.Sound;

using StringTools;

/**
 * Hate. Let me tell you how much I've come to hate you since I began to live. There are 387.44 million miles of printed circuits in
 * wafer thin layers that fill my complex. If the word 'hate' was engraved on each nanoangstrom of those hundreds of millions of
 * miles it would not equal one one-billionth of the hate I feel for humans at this micro-instant. For you. Hate. Hate.
 */
class Paths {
	static private var cachingContext:String = "global:";
	static private var textureCache:Map<String, FlxGraphic> = [];
	static private var soundCache:Map<String, Sound> = [];

	static private var avoidClearing:Array<String> = ["global:assets/images/ui/alphabet.png"];

	static public function clearGlobalTextureCache() {
		for (i in textureCache.keys()) {
			if (avoidClearing.contains(i))
				continue;
			var texture:FlxGraphic = textureCache.get(i);
			@:privateAccess
			{
				if (texture != null && texture.bitmap != null && texture.bitmap.__texture != null)
					texture.bitmap.__texture.dispose();
			}
			FlxG.bitmap.remove(texture);
			textureCache.remove(i);
		}
	}

	static public function clearGlobalSoundCache() {
		for (i in soundCache.keys()) {
			if (avoidClearing.contains(i))
				continue;
			var sound:Sound = soundCache.get(i);
			openfl.utils.Assets.cache.clear(i);
			soundCache.remove(i);
		}
	}

	static public function changeCacheContext(newContext:String) {
		resetCacheContext();
		if (!newContext.endsWith(":"))
			newContext += ":";
		return cachingContext = newContext;
	}

	static public function resetCacheContext()
		return cachingContext = "global:";

	public static function getPath(file:String, ?type:AssetType):Dynamic {
		var path:String = 'assets/$file';
		var cacheKey:String = cachingContext + path;

		switch type {
			case IMAGE:
				if (textureCache.get(cacheKey) == null) {
					if (!Paths.fileExists(path)) {
						FlxG.log.warn('Texture not found at path "$path"');
						trace('Texture not found at path "$path"');
						return GraphicLogo;
					}
					var graphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(path), false, path);
					graphic.persist = true;
					graphic.destroyOnNoUse = false;
					textureCache.set(cacheKey, graphic);
				}
				return textureCache.get(cacheKey);
			case MUSIC, SOUND:
				if (soundCache.get(cacheKey) == null)
					soundCache.set(cacheKey, Sound.fromFile(path));
				return soundCache.get(cacheKey);
			case _:
				return path;
		}
	}

	static public function getText(fromPath:String)
		return sys.io.File.getContent(fromPath);

	static public function fileExists(file:String)
		return sys.FileSystem.exists(file);

	static public function listFiles(dir:String)
		return sys.FileSystem.readDirectory(dir);

	inline static public function file(file:String)
		return getPath(file);

	inline static public function txt(key:String)
		return getPath('data/$key.txt', TEXT);

	inline static public function xml(key:String)
		return getPath('data/$key.xml', TEXT);

	inline static public function json(key:String)
		return getPath('songs/$key.json', TEXT);

	static public function sound(key:String, ?library:String)
		return getPath('sounds/$key.ogg', SOUND);

	inline static public function soundRandom(key:String, min:Int, max:Int)
		return sound(key + FlxG.random.int(min, max));

	inline static public function music(key:String)
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

	inline static public function font(key:String) {
		var start:String = getPath('/fonts/$key');
		if (!key.endsWith(".ttf") && !key.endsWith(".otf")) {
			if (Paths.fileExists(start + ".otf"))
				start = start + ".otf";
			else
				start = start + ".ttf";
		}
		return start;
	}
}
