package gameplay;

import data.ConfigTypes;
import data.hscript.Script;
import data.hscript.ScriptLoader;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.typeLimit.OneOfTwo;
import gameplay.FunkinSprite;
import haxe.Json5;

using util.AnimationHelper;
using util.CoolUtil;

@:allow(ui.DeveloperMenu, gameplay.PlayState)
class StageBG extends FlxBasic {
	public var characterOffsets:Map<String, Array<Float>> = new Map();
	public var cameraZoom:Float = 1.0;

	var objects:Array<FlxBasic> = [];
	var stageFile(default, set):String;
	var _loadedFiles:Map<String, StageFile> = [];

	var stageScript:Script;

	public function new(stageFile:String):Void {
		super();
		this.stageFile = stageFile;
	}

	override function update(elapsed:Float):Void {
		scriptFuncCall('update', [elapsed, this]);
		super.update(elapsed);
	}

	public function getStageFileName():String
		return stageFile;

	public function beatHit(beat:Int):Void
		scriptFuncCall('onBeatHit', [beat, this]);

	public function stepHit(step:Int):Void
		scriptFuncCall('onStepHit', [step, this]);

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

	/**
	 * Lists every stage file in both assets and mods.
	**/
	public static function getStageFiles():Array<String> {
		var stages:Array<String> = [];
		var cats = util.Mods.getEnabled();
		for (modId in cats) {
			var stagesPath:String = Paths.getPath('data/stages', modId);
			if (!Paths.fileExists(stagesPath))
				continue;
			for (i in Paths.listFiles(stagesPath)) {
				if (!Paths.jsonExtensions.contains(haxe.io.Path.extension(i)))
					continue;
				stages.push('$modId:$i');
			}
		}
		return stages;
	}

	private function loadStageScript(stageName:String):Script {
		var scriptPath:String = Paths.getPath('data/stages/$stageName');
		stageScript = ScriptLoader.findScript(ScriptLoader.getScriptFile(scriptPath, stageName), true);
		scriptFuncCall('onLoad', [this]);
		return stageScript;
	}

	public function scriptFuncCall(funcName:String, ?args:Array<Dynamic>):HScriptFunction {
		if (stageScript == null)
			return null;
		return stageScript.callFunc(funcName, args);
	}

	private function findStageFile(file:String):String {
		var modId:String = null;
		var stage:String = file;
		if (file.indexOf(":") != -1) {
			var info = file.split(":");
			modId = info[0];
			stage = info[1];
		}
		var paths = ['data/stages/$stage', 'data/stages/$stage-config'];
		var path:String = Paths.getPath(paths[0] + '.json');
		for (i in paths) {
			for (ext in Paths.jsonExtensions) {
				var target:String = Paths.getPath(i, modId);
				if (Paths.fileExists(target)) {
					path = target;
					break;
				}
			}
		}
		return path;
	}

	function loadDummy():Void {
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
				} else {
					loadStageScript(stage);
					loadStageObjects(newStage);
					scriptFuncCall('onStageLoaded', [this, stage]);
				}
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
		if (stageData.characterOffsets != null) {
			for (key in Reflect.fields(stageData.characterOffsets)) {
				characterOffsets.set(key, [0, 0]);
				var offset:Dynamic = Reflect.field(stageData.characterOffsets, key);
				if (offset != null) {
					if (offset is Array)
						characterOffsets.set(key, [offset[0] ?? 0, offset[1] ?? 0]);
					else if (offset is Dynamic)
						characterOffsets.set(key, [offset.x ?? 0, offset.y ?? 0]);
				}
			}
		}
		if (stageData.objects != null && stageData.objects.length != 0) {
			for (id => data in stageData.objects) {
				var sprite = new FunkinSprite(data.position[0] ?? 0.0, data.position[1] ?? 0.0);
				var atlasType:String = ConfigTypes.getAtlasType(data.texture, 'spritesheet');
				var path:String = ConfigTypes.getTexturePath(data.texture);
				var tex = switch atlasType {
					case 'sparrow': Paths.getSparrowAtlas(path);
					case 'packer': Paths.getPackerAtlas(path);
					case _: Paths.image(path);
				}
				if (tex is FlxAtlasFrames)
					sprite.frames = cast tex;
				else
					sprite.loadGraphic(cast tex);
				if (data.animations != null) {
					sprite.addFromJson(data.animations, data.defaultFramerate ?? 24);
					if (data.defaultAnimation != null && sprite.animation.getByName(data.defaultAnimation) != null)
						sprite.playAnim(data.defaultAnimation, true);
				}
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
				// trace('array index $id - sprite index ${sprite.ID}');
				objects.push(sprite);
			}
			objects.sort((a, b) -> return FlxSort.byValues(FlxSort.ASCENDING, a.ID, b.ID));
		}
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
		for (i in objects)
			if (i.ID == id) {
				i.ID = newPosition;
				obj = i;
				break;
			}
		objects.sort((a, b) -> return FlxSort.byValues(FlxSort.ASCENDING, a.ID, b.ID));
		return obj;
	}
}
