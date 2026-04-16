package data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.typeLimit.OneOfTwo;
import gameplay.FunkinSprite;
import gameplay.Note;
import haxe.Json5;
import util.AnimationHelper;

private typedef ModAnimation = Dynamic; // OneOfTwo<Dynamic, String>;

private typedef StrumAnimations = {
	animStatic:Array<ModAnimation>,
	animPressed:Array<ModAnimation>,
	animConfirm:Array<ModAnimation>,
	?animHolding:Array<ModAnimation>
}

// TODO: make this typedef just a general mod thing and not exclusive to this file
// this file *in general* is very useful
private typedef TextureConfig = {path:String, ?atlasType:String}
private typedef AnimationConfig = {?antialiasing:Bool, animations:Array<ModAnimation>, ?atlas:TextureConfig};

typedef NoteskinFile = {
	?name:String,
	?author:String,
	?atlasType:String,
	?keyCount:Int,
	?defaultFramerate:Int,
	?offsets:Array<OneOfTwo<Dynamic, Array<Float>>>,
	defaultAtlas:TextureConfig,
	strums:{?antialiasing:Bool, animations:StrumAnimations, ?atlas:TextureConfig, ?scale:Float},
	arrows:AnimationConfig & {?scale:Float},
	?holds:AnimationConfig,
	?splashes:AnimationConfig & {?scale:Float},
}

// i hate this file in specific -asmadeuxs
// actually i rewrote it entirely and i hate it slightly less now -asmadeuxs
class Noteskin {
	public static final DEFAULT_SKIN:NoteskinFile = {
		name: "Classic",
		author: "PhantomArcade",
		defaultAtlas: {path: "gameplay/noteskins/NOTE_assets", atlasType: "sparrow"},
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

	private var atlasMap:Map<String, FlxAtlasFrames> = [];
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
			var atlas = Paths.getSparrowAtlas(texConf.path);
			if (atlas != null)
				atlasMap.set(key, atlas);
			else
				trace('Cannot load noteskin atlas for $key (path: ${Paths.getPath('images/${texConf.path}')})');
		}
		return atlasMap.get(key);
	}

	private function getAtlas(key:String):FlxAtlasFrames
		return (atlasMap.get(key) != null) ? atlasMap.get(key) : atlasMap.get("defaultAtlas");

	private function preload():Void {
		var conf = file;
		keyCount = conf.keyCount ?? DEFAULT_SKIN.keyCount;
		defaultFramerate = conf.defaultFramerate ?? DEFAULT_SKIN.defaultFramerate;

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
		} else {
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
		} else
			splashAnimNames = [];

		strumScale = conf.strums.scale ?? DEFAULT_SKIN.strums.scale;
		arrowScale = conf.arrows.scale ?? DEFAULT_SKIN.arrows.scale;
		splashScale = conf.splashes.scale ?? DEFAULT_SKIN.splashes.scale;

		strumAA = conf.strums.antialiasing ?? DEFAULT_SKIN.strums.antialiasing;
		arrowAA = conf.arrows.antialiasing ?? DEFAULT_SKIN.arrows.antialiasing;
		splashAA = conf.splashes.antialiasing ?? DEFAULT_SKIN.splashes.antialiasing;
	}

	private static function _animMapper(anim:ModAnimation):String {
		var mapped:String = null;
		if (anim is String)
			mapped = anim;
		else if (anim.prefix != null)
			mapped = anim.prefix;
		return mapped;
	}

	private static function loadAnimArray(arr:Array<ModAnimation>):Array<String>
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

		strum.animation.addByPrefix("static", staticName, defaultFramerate, false);
		strum.animation.addByPrefix("pressed", pressedName, defaultFramerate, false);
		strum.animation.addByPrefix("confirm", confirmName, defaultFramerate, false);
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
		var scrollName = getFromArray(scrollAnimNames, noteData);
		arrow.animation.addByPrefix('${noteData}Scroll', scrollName, defaultFramerate, false);
		arrow.setGraphicSize(Std.int(arrow.width * arrowScale));
		arrow.playAnim('${noteData}Scroll', true);
		arrow.antialiasing = arrowAA;
		return arrow;
	}

	public function generateNoteSplashSprite():FunkinSprite {
		var splash = new FunkinSprite(0, 0);
		var frames = getAtlas("splashes");
		if (frames == null)
			return splash;
		splash.frames = frames;
		for (i in 0...splashAnimNames.length)
			for (j in 0...splashAnimNames[i].length)
				splash.animation.addByPrefix('splash$j-$i', splashAnimNames[i][j], defaultFramerate, false);
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
		if (splash.animation.getByName(playThis) != null) {
			splash.playAnim(playThis, true);
			// splash.animation.curAnim.frameRate += Std.int(defaultFramerate);
			played = true;
		}
		return played;
	}

	public static function getDefaultConfig():NoteskinFile
		return DEFAULT_SKIN;

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

	public static function loadNoteskinFile(noteskinPath:String):Noteskin {
		var filePath = findNoteskinFile(noteskinPath);
		var skinData:NoteskinFile;
		if (!Paths.fileExists(filePath)) {
			trace('Noteskin "$noteskinPath" not found, using default');
			skinData = DEFAULT_SKIN;
		} else {
			trace('Loading noteskin from $filePath');
			skinData = cast Json5.parse(Paths.getText(filePath));
		}
		return new Noteskin(skinData);
	}
}
