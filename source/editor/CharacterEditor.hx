package editor;

import data.ConfigTypes.CharacterConfig;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.animation.FlxAnimation;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import gameplay.Character;
import gameplay.PlayState;
import gameplay.StageBG;
import ui.FunkinCamera;

class CharacterEditor extends MusicBeatState {
	var camFollow:FlxObject;
	var _prevState:String = null;
	var showReference:Bool = false;
	var editingChar:Int = 0;

	var chars:Array<Array<Dynamic>> = [[], [], []]; // [name, character ghost, character]
	var animList:Array<FlxAnimation> = null;
	var reference:Character;
	var character:Character;
	var stage:StageBG;

	// UI
	var infoText:FlxText;

	public function new(prevState:String, chars:Array<String>, ?daStage:String = 'stage') {
		this._prevState = prevState;
		super();

		add(stage = new StageBG(daStage));
		add(camFollow = new FlxObject());
		FlxG.camera.zoom = stage.cameraZoom;
		resetCameraPosition();

		// hardcoding for now
		var types = ['player', 'opponent', 'metronome'];
		for (i => char in chars)
			addChar(char, types[i]);

		infoText = new FlxText(10, 10, 0, "", 16);
		infoText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		infoText.scrollFactor.set();
		add(infoText);
	}

	public function positionCharacter(char:Character, type:String) {
		if (char == null)
			return;
		switch type {
			case 'player':
				char.setPosition(770, 450);
			case 'metronome':
				char.setPosition(400, 130);
			case _:
				char.setPosition(100, 100);
		}
		var typeLower:String = type.toLowerCase();
		if (stage.characterOffsets.exists(typeLower)) {
			var o:Array<Float> = stage.characterOffsets.get(typeLower);
			char.x += o[0] ?? 0;
			char.y += o[1] ?? 0;
		}
	}

	public function addChar(characterName:String, type:String = 'opponent'):Void {
		var cref:Character = new Character(0, 0, characterName, type);
		var char:Character = new Character(0, 0, characterName, type);

		cref.playAnim(cref.idleAnimations[0], true);
		cref.color = FlxColor.GRAY;
		cref.visible = showReference;
		cref.debugMode = true;
		char.debugMode = true;
		char.alpha = 0.1;
		cref.alpha = 0.1;

		chars[0].push(characterName);
		chars[1].push(cref);
		chars[2].push(char);

		positionCharacter(cref, type);
		positionCharacter(char, type);

		add(cref);
		add(char);

		changeEditing(0);
		changeAnimation(0);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.justPressed.G) {
			showReference = !showReference;
			if (reference != null)
				reference.visible = showReference;
		}

		// @formatter:off
		if (FlxG.keys.justPressed.W) changeAnimation(-1);
		if (FlxG.keys.justPressed.S) changeAnimation(1);
		if (FlxG.keys.justPressed.SPACE) changeAnimation(0);

		if (FlxG.keys.justPressed.TAB) changeEditing(1);

		var pressed = FlxG.keys.pressed;
		var justPressed = FlxG.keys.justPressed;
		var holdingCtrl:Bool = pressed.CONTROL;

		var cameraPanSpeed:Float = FlxG.keys.pressed.SHIFT ? 4.0 : 1.0;
		if ((holdingCtrl ? justPressed : pressed).J) camFollow.x += -cameraPanSpeed;
		if ((holdingCtrl ? justPressed : pressed).L) camFollow.x += cameraPanSpeed;
		if ((holdingCtrl ? justPressed : pressed).I) camFollow.y += -cameraPanSpeed;
		if ((holdingCtrl ? justPressed : pressed).K) camFollow.y += cameraPanSpeed;
		if (justPressed.R) resetCameraPosition();

		var step:Float = FlxG.keys.pressed.SHIFT ? 0.5 : 1;
		if ((holdingCtrl ? justPressed : pressed).LEFT) changeOffset(step, 0);
		if ((holdingCtrl ? justPressed : pressed).RIGHT) changeOffset(-step, 0);
		if ((holdingCtrl ? justPressed : pressed).UP) changeOffset(0, step);
		if ((holdingCtrl ? justPressed : pressed).DOWN) changeOffset(0, -step);
		if (justPressed.F5) saveOffsets();
		
		// @formatter:on
		var minZoom:Float = 0.3;
		var maxZoom:Float = 5.0;
		var q:Bool = FlxG.keys.justPressed.Q;
		if (q || FlxG.keys.justPressed.E)
			FlxG.camera.zoom = Math.max(minZoom, FlxG.camera.zoom + (q ? -0.1 : 0.1));
		var mausWheel:Float = FlxG.mouse.wheel;
		if (mausWheel != 0)
			FlxG.camera.zoom = Math.max(minZoom, Math.min(maxZoom, FlxG.camera.zoom + mausWheel * 0.05));

		if (FlxG.keys.justPressed.ESCAPE) {
			if (_prevState == 'PlayState') {
				Paths.skipNextClear = true;
				FlxG.switchState(new gameplay.PlayState());
			} else
				FlxG.switchState(new menus.MainMenuState());
		}
		updateInfoText();
	}

	public function changeEditing(next:Int = 0):Void {
		if (chars[0].length == 0)
			return;

		if (character != null)
			character.alpha = 0.1;
		if (reference != null)
			reference.alpha = 0.1;

		editingChar = (editingChar + next) % chars[0].length;
		if (editingChar < 0)
			editingChar += chars[0].length;

		reference = chars[1][editingChar];
		character = chars[2][editingChar];
		if (reference != null)
			reference.visible = showReference;

		if (character != null) {
			character.alpha = 1.0;
			reference.alpha = 1.0;
			animList = character.animation.getAnimationList();
			resetCameraPosition();
		}
	}

	public function resetCameraPosition():Void {
		camFollow.setPosition(0, 0);
		if (character != null) {
			var mid = character.getMidpoint();
			var off = character.cameraOffset;

			var camPos:FlxPoint = new FlxPoint(mid.x + off.x, mid.y + off.y);
			camFollow.setPosition(camPos.x, camPos.y);
			FlxG.camera.follow(camFollow, LOCKON, 0.04);
		}
	}

	public function changeAnimation(next:Int = 0):Void {
		if (character == null || animList == null || animList.length < 1)
			return;

		var curAnim:FlxAnimation = character.animation.curAnim;
		var curIdx:Int = (curAnim != null) ? animList.indexOf(curAnim) : -1;

		if (next == 0) {
			if (curAnim != null)
				character.playAnim(curAnim.name, true);
			return;
		}

		var newIdx:Int = (curIdx + next) % animList.length;
		if (newIdx < 0)
			newIdx += animList.length;
		character.playAnim(animList[newIdx].name, true);
	}

	public function changeOffset(byX:Float = 0, byY:Float = 0):Void {
		if (character == null)
			return;
		var anim:String = character.animation.curAnim.name;
		var current:Array<Float> = character.getOffset(anim);
		character.addOffset(anim, current[0] + byX, current[1] + byY);
		character.playAnim(anim, true);
	}

	function saveOffsets():Void {
		if (character == null)
			return;

		var jsonPath:String = character.filePath;
		if (!Paths.fileExists(jsonPath)) {
			trace('Character JSON not found at $jsonPath, cannot save offsets');
			return;
		}

		var jsonContent:String = Paths.getText(jsonPath);
		var config:CharacterConfig = haxe.Json5.parse(jsonContent);

		if (config.offsets == null)
			config.offsets = {};

		var animNames:Array<String> = character.animation.getNameList();
		for (anim in animNames) {
			var curOffset:Array<Float> = character.getOffset(anim);
			if (curOffset != null)
				Reflect.setField(config.offsets, anim, {x: curOffset[0], y: curOffset[1]});
		}
		var newJson:String = haxe.Json.stringify(config, "\t") + "\n";
		sys.io.File.saveContent(jsonPath + '~', jsonContent);
		sys.io.File.saveContent(jsonPath, newJson);
		trace('Saved offsets for ${animNames.length} animations');
		infoText.text += "\nALL OFFSETS SAVED!";
	}

	function updateInfoText():Void {
		if (character == null) {
			infoText.text = "No character loaded";
			return;
		}

		var animName:String = character.animation.curAnim != null ? character.animation.curAnim.name : "none";
		var off:Array<Float> = character.getOffset(animName);
		var totalChars:Int = chars[0].length;

		infoText.text = 'Character: ${chars[0][editingChar]} ($editingChar+1/$totalChars)
			[W/S] Animation: $animName (SPACE to Replay)
			[Arrow Keys] X=${off[0]}  Y=${off[1]}  (Arrow SHIFT to move 10 pixels faster)
			[G] Reference ${showReference ? "ON" : "OFF"} ${(chars[0].length > 1 ? '[Q/E] Switch Character' : '')}
			[IJKL] Move Camera       [Shift+IJKL] Move Camera Slowly       [Q/E] Change Zoom        [R] Reset Camera
			[CTRL+Arrows / CTRL+IJKL] Move offset or camera with pixel precision
			[F5] Save Offsets       [ESC] Exit';
	}
}
