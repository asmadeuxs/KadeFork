package gameplay;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.typeLimit.OneOfTwo;
import gameplay.FunkinSprite;
import haxe.Json5;

using util.CoolUtil;

class StageBG extends FlxBasic {
	public var cameraZoom:Float = 1.0;

	var objects:Array<FlxBasic> = [];
	var stageFile(default, set):String;
	var _loadedFiles:Map<String, StageFile> = [];

	public function new(stageFile:String):Void {
		super();
		this.stageFile = stageFile;
	}

	public function clear() {
		for (o in objects)
			if (o != null)
				o.destroy();
		objects.resize(0);
	}

	public function clearCache():Void {
		for (f in _loadedFiles)
			f = null;
		_loadedFiles.clear();
	}

	override function destroy():Void {
		clear();
		super.destroy();
	}

	private function findStageFile(file:String):String {
		var paths = [
			Paths.getPath('data/stages/${file}'),
			Paths.getPath('data/stages/${file}-config'),
		];
		var path:String = paths[0] + '.json';
		for (i in paths) {
			for (ext in Paths.jsonExtensions) {
				if (Paths.fileExists(i + ext)) {
					path = i;
					break;
				}
			}
		}
		return path;
	}

	function loadDummy() {
		var dummy = new FunkinSprite(0, 0).makeScaledGraphic(FlxG.width, FlxG.height, 0xFF808080);
		dummy.scrollFactor.set();
		dummy.ID = 0;
		objects.push(dummy);
	}

	function set_stageFile(stage:String):String {
		clear();
		switch stage {
			default:
				var newStage:StageFile = loadStage(stage);
				if (newStage == null) {
					loadDummy();
					return stageFile = 'dummy';
				} else
					loadStageObjects(newStage);
				return stageFile = stage;
		}
	}

	public function loadStage(stage:String):StageFile {
		var newStage:StageFile = null;
		if (!_loadedFiles.exists(stage)) {
			var file:String = findStageFile(stage);
			if (!Paths.fileExists(file)) {
				trace('Stage failed to load (Because "$stage" doesn\'t exist in any stage file paths (tried path: $file)');
				return newStage;
			}
			newStage = cast Json5.parse(Paths.getText(file));
			_loadedFiles.set(stage, newStage);
		} else
			newStage = _loadedFiles.get(stage);
		return newStage;
	}

	public function loadStageObjects(stageData:StageFile):Void {
		if (stageData == null)
			return;
		cameraZoom = stageData.cameraZoom ?? 1.0;
		if (stageData.objects != null && stageData.objects.length != 0) {
			for (id => data in stageData.objects) {
				var sprite = new FunkinSprite(data.position[0] ?? 0.0, data.position[1] ?? 0.0);
				sprite.loadGraphic(Paths.image(data.file));

				if (data.scrollFactor != null) {
					if (data.scrollFactor is Array) {
						var scrollX:Float = data.scrollFactor[0] ?? 0.0;
						sprite.scrollFactor.set(scrollX, data.scrollFactor[1] ?? scrollX);
					} else if (data.scrollFactor is Float)
						sprite.scrollFactor.set(data.scrollFactor ?? 0.0, data.scrollFactor ?? 0.0);
				}
				if (data.scale != null) {
					if (data.scale is Array) {
						var scaleX:Float = data.scale[0] ?? 0.0;
						sprite.scale.set(scaleX, data.scale[1] ?? scaleX);
					} else if (data.scale is Float)
						sprite.scale.set(data.scale ?? 0.0, data.scale ?? 0.0);
					sprite.updateHitbox();
				}
				sprite.visible = switch Std.string(data.visible) {
					case "lowQualityMode": Preferences.user.lowQualityMode;
					case "highQualityMode": !Preferences.user.lowQualityMode;
					case _: data.visible != "false";
				}
				sprite.antialiasing = data.antialiasing ?? stageData.defaultAntialiasing ?? true;
				sprite.ID = data.id ?? id;
				if (data.color != null) {
					if (data.color is Array) {
						var red:Int = data.color[0] ?? 255;
						sprite.color = FlxColor.fromRGB(red, data.color[1] ?? red, data.color[2] ?? red);
					} else if (data.color is String)
						sprite.color = FlxColor.fromString(data.color);
				}
				trace('array index $id - sprite index ${sprite.ID}');
				objects.push(sprite);
			}
		}
		objects.sort((a, b) -> return FlxSort.byValues(FlxSort.ASCENDING, a.ID, b.ID));
	}

	override function draw() {
		if (!visible || !alive || !exists || objects.length == 0)
			return;
		for (o in objects) {
			if (o != null)
				o.draw();
			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}

	public function add(basic:FlxBasic):FlxBasic {
		objects.push(basic);
		return basic;
	}

	public function remove(basic:FlxBasic):FlxBasic {
		objects.remove(basic);
		return basic;
	}

	public function removeByID(id:Int):FlxBasic {
		var obj:FlxBasic = null;
		for (i in objects)
			if (i.ID == id) {
				objects.remove(i);
				obj = i;
				break;
			}
		return obj;
	}

	public function moveByID(id:Int, newPosition:Int):FlxBasic {
		var obj:FlxBasic = null;
		return obj;
	}
}

private typedef JsonAnimation = {
	prefix:String,
	frameRate:Int,
	looped:Bool
}

private typedef JsonSprite = {
	name:String,
	file:String,
	?atlasType:String,
	position:Array<Float>,
	?visible:OneOfTwo<String, Bool>,
	?animations:Array<JsonAnimation>,
	?scale:OneOfTwo<Array<Float>, Float>,
	?scrollFactor:OneOfTwo<Array<Float>, Float>,
	?color:OneOfTwo<Array<Int>, String>,
	?antialiasing:Bool,
	?id:Int
}

typedef StageFile = {
	?name:String,
	?cameraZoom:Float,
	?defaultAntialiasing:Bool,
	objects:Array<JsonSprite>
}
