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
	var _prevState:String = null;
	var camFollow:FlxObject;
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
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		for (char in chars)
			addChar(char);

		infoText = new FlxText(10, 10, 0, "", 16);
		infoText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		infoText.scrollFactor.set();
		add(infoText);
	}

	public function positionCharacter(char:Character) {
		if (char != null) {
			char.setPosition(char.facesLeft ? 770 : 100, char.facesLeft ? 450 : 100);
			var tag:String = char.facesLeft ? 'player' : 'opponent';
			if (stage.characterOffsets.exists(tag)) {
				var o:Array<Float> = stage.characterOffsets.get(tag);
				char.x += o[0] ?? 0;
				char.y += o[1] ?? 0;
			}
		}
	}

	public function addChar(characterName:String):Void {
		var cref:Character = new Character(0, 0, characterName);
		var char:Character = new Character(0, 0, characterName);

		cref.playAnim(cref.idleAnimations[0], true);
		cref.color = FlxColor.GRAY;
		cref.visible = showReference;
		cref.debugMode = true;
		char.debugMode = true;

		chars[0].push(characterName);
		chars[1].push(cref);
		chars[2].push(char);

		positionCharacter(cref);
		positionCharacter(char);

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

		var cameraPanSpeed:Float = FlxG.keys.pressed.SHIFT ? 4.0 : 1.0;
		if (FlxG.keys.pressed.CONTROL) {
			var panX:Float = 0;
			var panY:Float = 0;
			if (FlxG.keys.justPressed.LEFT) panX = cameraPanSpeed;
			if (FlxG.keys.justPressed.RIGHT) panX = -cameraPanSpeed;
			if (FlxG.keys.justPressed.UP) panY = cameraPanSpeed;
			if (FlxG.keys.justPressed.DOWN) panY = -cameraPanSpeed;
			if (panX != 0 || panY != 0) {
				camFollow.x += panX;
				camFollow.y += panY;
			}
		}
		else {
			var step:Float = FlxG.keys.pressed.SHIFT ? 0.5 : 1;
			if (FlxG.keys.justPressed.LEFT) changeOffset(step, 0);
			if (FlxG.keys.justPressed.RIGHT) changeOffset(-step, 0);
			if (FlxG.keys.justPressed.UP) changeOffset(0, step);
			if (FlxG.keys.justPressed.DOWN) changeOffset(0, -step);
			if (FlxG.keys.justPressed.F5) saveOffsets();
		}
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

		editingChar = (editingChar + next) % chars[0].length;
		if (editingChar < 0)
			editingChar += chars[0].length;

		reference = chars[1][editingChar];
		character = chars[2][editingChar];
		if (reference != null)
			reference.visible = showReference;

		if (character != null) {
			animList = character.animation.getAnimationList();
			var mid = character.getMidpoint();
			var off = character.cameraOffset;
			var camPos:FlxPoint = new FlxPoint(mid.x + off.x, mid.y + off.y);
			camFollow.setPosition(camPos.x, camPos.y);
			#if hxdiscord_rpc
			DiscordClient.changePresence('Character ${character.characterId}', 'Editing Character');
			#end
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

		var charName:String = chars[0][editingChar];
		var jsonPath:String = character.filePath;

		if (!Paths.fileExists(jsonPath)) {
			trace('Character JSON not found at $jsonPath, cannot save offsets');
			return;
		}

		var jsonContent:String = Paths.getText(jsonPath);
		var config:CharacterConfig = haxe.Json5.parse(jsonContent);
		var curAnimName:String = character.animation.curAnim.name;
		var currentOffset:Array<Float> = character.getOffset(curAnimName);

		if (config.offsets == null)
			config.offsets = {x: 0, y: 0};
		Reflect.setField(config.offsets, curAnimName, [currentOffset[0], currentOffset[1]]);

		var newJson:String = haxe.Json.stringify(config, "\t");
		sys.io.File.saveContent(jsonPath + '~', jsonContent);
		sys.io.File.saveContent(jsonPath, newJson);
		trace('saved offset for $curAnimName: [${currentOffset[0]}, ${currentOffset[1]}]');
		infoText.text += "\nOFFSET SAVED!";
	}

	function updateInfoText():Void {
		if (character == null) {
			infoText.text = "No character loaded";
			return;
		}

		var animName:String = character.animation.curAnim != null ? character.animation.curAnim.name : "none";
		var off:Array<Float> = character.getOffset(animName);
		var totalChars:Int = chars[0].length;

		infoText.text = 'Character: ${chars[0][editingChar]} ($editingChar+1/$totalChars)\n'
			+ 'Animation: $animName (W/S to change, SPACE to replay current animation)\n'
			+ 'Offsets: X=${off[0]}  Y=${off[1]}  (Arrow Keys, SHIFT+Arrow Keys = 10px)\n'
			+ 'Reference (G): ${showReference ? "ON" : "OFF"}\n'
			+ (chars[0].length > 1 ? '[Q/E] Switch Character        ' : '')
			+ '[F5] Save Offsets        [ESC] Exit\n'
			+ '[Ctrl+Arrows] Move Camera        [Shift+Ctrl+Arrows] Move Camera Slowly\n[+/-] Zoom'
			+ '        [R] Reset Camera';
	}
}
