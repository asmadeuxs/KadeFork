package data;

import animate.FlxAnimateFrames;
import gameplay.FunkinSprite;
import data.ConfigTypes;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.typeLimit.OneOfTwo;
import gameplay.FunkinSprite;
import gameplay.note.Note;
import haxe.Json5;
import util.AnimationHelper;

// i hate this file in specific -asmadeuxs
// actually i rewrote it entirely and i hate it slightly less now -asmadeuxs
class Noteskin {
	public static var noteskinCache:Map<String, Noteskin> = new Map<String, Noteskin>();

	public static function loadNoteskinFile(noteskinPath:String, ?skipCache:Bool = false):Noteskin {
		var filePath = findNoteskinFile(noteskinPath);
		// doing this mainly so there's no unused instances of the same skin
		if (!skipCache) {
			if (noteskinCache.get(filePath) != null)
				return noteskinCache.get(filePath);
			else
				noteskinCache.remove(filePath);
		}
		var skinData:NoteskinFile;
		if (!Paths.fileExists(filePath)) {
			trace('Noteskin "$noteskinPath" not found, using default');
			skinData = DEFAULT_SKIN_CONFIG;
		}
		else {
			trace('Loading noteskin from $filePath');
			skinData = cast Json5.parse(Paths.getText(filePath));
		}
		var skin:Noteskin = new Noteskin(skinData);
		skin.resolvedPath = filePath;
		noteskinCache.set(filePath, skin);
		return noteskinCache.get(filePath);
	}

	public static final DEFAULT_SKIN_CONFIG:NoteskinFile = {
		name: "Classic",
		author: "PhantomArcade",
		defaultAtlas: {
			path: "gameplay/noteskins/NOTE_assets",
			atlasType: "sparrow"
		},
		defaultFramerate: 24,
		keyCount: 4,
		strums: {
			antialiasing: true,
			scale: 0.7,
			animations: {
				animStatic: ["arrowLEFT", "arrowDOWN", "arrowUP", "arrowRIGHT"],
				animPressed: ["left press", "down press", "up press", "right press"],
				animConfirm: ["left confirm", "down confirm", "up confirm", "right confirm"],
				animHolding: null
			}
		},
		arrows: {
			antialiasing: true,
			scale: 0.7,
			animations: ["purple0", "blue0", "green0", "red0"]
		},
		holds: {
			antialiasing: true,
			animations: [
				"purple hold piece", "blue hold piece", "green hold piece", "red hold piece",
				  "pruple end hold",   "blue hold end",   "green hold end",   "red hold end"
			]
		},
		splashes: {
			antialiasing: true,
			scale: 1.0,
			atlas: {path: "gameplay/noteskins/noteSplashes"},
			animations: [
				"note impact 1 purple", "note impact 1  blue", "note impact 1 green", "note impact 1 red",
				"note impact 2 purple",  "note impact 2 blue", "note impact 2 green", "note impact 2 red"
			]
		}
	};

	public var resolvedPath:String = null;

	private var graphicKeys:Array<String> = [];

	private var atlasMap:Map<String, Dynamic> = [];
	private var defaultFramerate:Int;
	private var keyCount:Int;

	private var strumScale:Float = 0.7;
	private var arrowScale:Float = 0.7;
	private var splashScale:Float = 1.0;

	private var strumAA:Bool = true;
	private var arrowAA:Bool = true;
	private var splashAA:Bool = true;

	private var staticAnimNames:Array<String>;
	private var pressedAnimNames:Array<String>;
	private var confirmAnimNames:Array<String>;

	private var scrollAnimNames:Array<String>;
	private var holdBodyAnimNames:Array<String>;
	private var holdEndAnimNames:Array<String>;
	private var splashAnimNames:Array<Array<String>>;

	public var file:NoteskinFile;

	public function new(file:NoteskinFile) {
		this.file = file;
		preload();
	}

	public function destroy():Void {
		for (key in graphicKeys)
			Paths.removeFromAvoidClearing(key);
		graphicKeys.resize(0);
		atlasMap.clear();
		if (resolvedPath != null)
			noteskinCache.remove(resolvedPath);
		file = null;
	}

	public function loadNoteskinTextures(conf:NoteskinFile, ?type:String) {
		var key:String = type;
		var texConf:TextureConfig = switch type {
			case "strums": conf.strums.atlas;
			case "arrows": conf.arrows.atlas;
			case "holds": conf.holds.atlas;
			case "splashes": conf.splashes.atlas;
			case _:
				key = "defaultAtlas"; // make sure this is default
				conf.defaultAtlas;
		}
		if (texConf != null) {
			var atlasType:String = ConfigTypes.getAtlasType(texConf);
			var texPath:String = ConfigTypes.getTexturePath(texConf);
			var mod:String = Paths.getAssetOrigin(texPath);
			var atlas = switch atlasType {
				case 'spritesheet': Paths.image(texPath);
				case 'animate': Paths.getAnimateAtlas(texPath);
				case 'packer': Paths.getPackerAtlas(texPath);
				case _: Paths.getSparrowAtlas(texPath);
			}
			if (atlas != null) {
				atlasMap.set(key, atlas);
				if (texPath != null && !graphicKeys.contains(texPath)) {
					graphicKeys.push(texPath);
					Paths.addToAvoidClearing(texPath);
				}
			}
			else
				trace('Cannot load noteskin atlas for $key (path: ${Paths.resolveAssetPath('images/$texPath', mod)}');
		}
		return atlasMap.get(key);
	}

	private function getAtlas(key:String):FlxAtlasFrames
		return if (atlasMap.get(key) != null) atlasMap.get(key) else atlasMap.get("defaultAtlas");

	private function preload():Void {
		var conf = file;
		keyCount = conf.keyCount ?? DEFAULT_SKIN_CONFIG.keyCount;
		defaultFramerate = conf.defaultFramerate ?? DEFAULT_SKIN_CONFIG.defaultFramerate;

		for (type in ["defaultAtlas", "strums", "arrows", "holds", "splashes"])
			loadNoteskinTextures(conf, type);

		var strumAnims = conf.strums.animations;
		staticAnimNames = loadAnimArray(strumAnims.animStatic);
		pressedAnimNames = loadAnimArray(strumAnims.animPressed);
		confirmAnimNames = loadAnimArray(strumAnims.animConfirm);
		scrollAnimNames = loadAnimArray(conf.arrows.animations);

		var holdAnims = conf.holds.animations;
		if (holdAnims != null && holdAnims.length >= 2 * keyCount) {
			holdBodyAnimNames = loadAnimArray(holdAnims.slice(0, keyCount));
			holdEndAnimNames = loadAnimArray(holdAnims.slice(keyCount, 2 * keyCount));
		}
		else {
			holdBodyAnimNames = [for (i in 0...keyCount) ""];
			holdEndAnimNames = [for (i in 0...keyCount) ""];
		}

		var splashAnims = conf.splashes.animations;
		if (splashAnims != null) {
			var numVariants = Math.floor(splashAnims.length / keyCount);
			splashAnimNames = [];
			for (variant in 0...numVariants) {
				var variantAnims:Array<String> = [];
				for (dir in 0...keyCount)
					variantAnims.push(_animMapper(splashAnims[variant * keyCount + dir]));
				splashAnimNames.push(variantAnims);
			}
		}
		else
			splashAnimNames = [];

		strumScale = conf.strums.scale ?? DEFAULT_SKIN_CONFIG.strums.scale;
		arrowScale = conf.arrows.scale ?? DEFAULT_SKIN_CONFIG.arrows.scale;
		splashScale = conf.splashes.scale ?? DEFAULT_SKIN_CONFIG.splashes.scale;

		strumAA = conf.strums.antialiasing ?? DEFAULT_SKIN_CONFIG.strums.antialiasing;
		arrowAA = conf.arrows.antialiasing ?? DEFAULT_SKIN_CONFIG.arrows.antialiasing;
		splashAA = conf.splashes.antialiasing ?? DEFAULT_SKIN_CONFIG.splashes.antialiasing;
	}

	private static function _animMapper(a):String
		return ConfigTypes.getAnimationPrefix(a);

	private static function loadAnimArray(arr:Array<AnimationDef>):Array<String>
		return arr == null ? [] : arr.map(_animMapper);

	private inline function getFromArray(arr:Array<String>, noteData:Int):String
		return arr.length == 0 ? "" : arr[noteData % arr.length];

	public function generateStrum(noteData:Int):FunkinSprite {
		var strum = new FunkinSprite(0, 0);
		noteData = FlxMath.wrap(noteData, 0, keyCount - 1);
		var frames = getAtlas("strums");

		if (frames == null) {
			strum.makeGraphic(50, 50, 0xFF888888);
			return strum;
		}

		strum.frames = frames;
		var staticName = getFromArray(staticAnimNames, noteData);
		var pressedName = getFromArray(pressedAnimNames, noteData);
		var confirmName = getFromArray(confirmAnimNames, noteData);

		strum.anim.addByPrefix("static", staticName, defaultFramerate, false);
		strum.anim.addByPrefix("pressed", pressedName, defaultFramerate, false);
		strum.anim.addByPrefix("confirm", confirmName, defaultFramerate, false);
		strum.setGraphicSize(Std.int(strum.width * strumScale));
		strum.antialiasing = strumAA;
		strum.playAnim('static', true);
		return strum;
	}

	public function generateArrow(noteData:Int, ?note:Note):Note {
		var arrow:Note = note ?? new Note();
		noteData = FlxMath.wrap(noteData, 0, keyCount - 1);
		var frames = getAtlas("arrows");
		if (frames == null) {
			arrow.makeGraphic(50, 50, 0xFF888888);
			return arrow;
		}
		arrow.frames = frames;
		arrow.setGraphicSize(Std.int(arrow.width * arrowScale));
		var scrollName = getFromArray(scrollAnimNames, noteData);
		arrow.anim.addByPrefix('${noteData}Scroll', scrollName, defaultFramerate, false);
		arrow.playAnim('${noteData}Scroll', true);
		arrow.antialiasing = arrowAA;
		return arrow;
	}

	public function generateSustain(noteData:Int, isEnd:Bool = false):FunkinSprite {
		var sustain:FunkinSprite = new FunkinSprite(0, 0);
		noteData = FlxMath.wrap(noteData, 0, keyCount - 1);
		var frames = getAtlas("arrows");
		if (frames == null) {
			sustain.makeGraphic(50, 50, 0xFF888888);
			return sustain;
		}
		sustain.frames = frames;
		var animName = isEnd ? getFromArray(holdEndAnimNames, noteData) : getFromArray(holdBodyAnimNames, noteData);
		sustain.anim.addByPrefix('hold', animName, defaultFramerate, false);
		sustain.setGraphicSize(Std.int(sustain.width * arrowScale));
		sustain.antialiasing = arrowAA;
		sustain.anim.play('hold');
		return sustain;
	}

	public function generateNoteSplashSprite():FunkinSprite {
		var splash = new FunkinSprite(0, 0);
		var frames = getAtlas("splashes");
		if (frames == null)
			return splash;
		splash.frames = frames;
		for (i in 0...splashAnimNames.length)
			for (j in 0...splashAnimNames[i].length)
				splash.anim.addByPrefix('splash$j-$i', splashAnimNames[i][j], defaultFramerate, false);
		splash.setGraphicSize(Std.int(splash.width * splashScale));
		splash.antialiasing = splashAA;
		splash.updateHitbox();
		return splash;
	}

	public function playSplashAnimation(splash:FunkinSprite, noteData:Int):Bool {
		noteData = FlxMath.wrap(noteData, 0, keyCount - 1);
		var randomInt:Int = Std.random(splashAnimNames.length); // FlxG.random.int wasn't working properly
		var playThis:String = 'splash$noteData-$randomInt';
		var played:Bool = false;
		if (splash.anim.getByName(playThis) != null) {
			splash.playAnim(playThis, true);
			// splash.anim.curAnim.frameRate += Std.int(defaultFramerate);
			played = true;
		}
		return played;
	}

	public static function getDefaultConfig():NoteskinFile
		return DEFAULT_SKIN_CONFIG;

	private static function findNoteskinFile(skin:String):String {
		var paths = [
			Paths.getPath('images/gameplay/noteskins/$skin.json'),
			Paths.getPath('images/gameplay/noteskins/config.json'),
			Paths.getPath('images/gameplay/noteskins/$skin-config.json')
		];
		for (p in paths)
			if (Paths.fileExists(p))
				return p;
		return paths[0];
	}
}
