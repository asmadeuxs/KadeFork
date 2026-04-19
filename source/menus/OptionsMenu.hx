package menus;

import data.Option;
import data.Preferences;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.FunkinCamera;

using flixel.util.FlxSpriteUtil;

// I JUST MADE SOME BULLLLLLLLLLLLLLLLLLSHIT -asmadeuxs
class OptionsMenu extends MusicBeatSubstate {
	public var optionStash:Map<String, Array<Option>> = [
		"Preferences" => [
			{
				type: "number",
				name: "Framerate",
				variable: "frameRate",
				description: "How many times the game is updated and drawn to your screen",
				numberStep: 1,
				numberBoundLeft: 30,
				numberBoundRight: 360,
				setFunc: Preferences.setFPSCap
			},
			{
				type: "choice",
				name: "Scroll Type",
				variable: "scrollType",
				description: "Changes where the notes scroll to",
				choices: ["Up", "Down"],
			},
			/*{
				name: "Center Strums",
				variable: "centerStrums",
				description: "Centers your strums and hides the opponent's"
			},*/
			{
				name: "Ghost Tapping",
				description: "Lets you mash without penalty",
				variable: "ghostTapping"
			},
			/*{
				name: "Wife3 Accuracy",
				description: "Changes the accuracy system to use Wife3\nIt's way more complex (math-wise) for the sake of encouraging super accurate hits\nBut may feel mean to newer players",
				variable: "etternaMode"
			},*/
			{
				type: "number",
				name: "Scroll Speed",
				variable: "scrollSpeed",
				description: "Overrides the chart's scroll speed with your own\napplies if it's not set to 1",
				numberStep: 0.1,
				numberBoundLeft: 0.1,
				numberBoundRight: 10.0
			}
		],
		"Visuals" => [
			{
				name: "Low Quality",
				description: "Disables certain background effects to increase loading times (and in some cases, performance.)",
				variable: "lowQualityMode"
			},
			{
				name: "Show More Stats",
				description: "Shows Misses and Accuracy in the Score Text",
				variable: "accuracyDisplay"
			},
			{
				name: "Show Song Position",
				description: "Shows a progress bar for the song in the HUD",
				variable: "showSongPosition"
			},
			{
				name: "Show Judgement Counts",
				description: "Shows a judgement counter during gameplay on the left side of the screen",
				variable: "showJudgeCounts"
			},
			{
				name: "Notes per Second",
				description: "Shows a NPS counter on the Score Text",
				variable: "showNps"
			},
			{
				name: "Note Splashes",
				description: "Hitting a sick and above spawns a funny splash that gives you a boner", // thanks josh -asmadeuxs
				variable: "noteSplashes",
			},
			{
				name: "Distractions",
				description: "Disables certain sounds and effects that may be distracting",
				variable: "distractions"
			},
			{
				name: "Language",
				description: "Changes the game's text interfaces to be on a different language",
				variable: "language",
				type: "choice",
				choices: Translator.getAvailableLanguageIDs()
			},
			{
				type: "number",
				name: "Interface Dim",
				description: "Enables a background behind the strums or stage",
				variable: "strumUnderlay",
				// displayStyle: "{}%",
				numberStep: 1.0,
				numberBoundLeft: 0,
				numberBoundRight: 100
			},
			{
				name: "Dim Type",
				description: "Where should the underlay be layered on",
				variable: "strumUnderlayType",
				choices: ["Strums", "Stage"],
				type: "choice",
			}
		]
	];

	var catSelected:Int = 0;
	var categoryOrder:Array<String> = ["Preferences", "Visuals"];
	var curCatOptions:Array<Option> = null;
	var currentCat:String = "none";
	var curSelected:Int = 0;

	var catNameText:FlxText;
	var descriptionThingy:FlxText;
	var catOptions:FlxTypedSpriteGroup<FlxText>;
	var catFrame:FlxSprite;

	var camScroll:FunkinCamera;
	var camFollow:FlxObject;
	var optionsFont = Paths.font("vcr.ttf");
	var parent:MusicBeatState;

	public function new(parent:MusicBeatState) {
		this.parent = parent;
		super();
	}

	override function create():Void {
		super.create();
		currentCat = categoryOrder[catSelected];

		// it wouldn't let me do it up there
		for (cat in optionStash.keys())
			for (i in optionStash.get(cat))
				if (i.variable == 'language')
					i.setFunc = onLanguageChanged;

		var bgCover:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		bgCover.scale.set(FlxG.width, FlxG.height);
		bgCover.scrollFactor.set();
		bgCover.updateHitbox();
		bgCover.alpha = 0.8;
		add(bgCover);

		var header:FlxText = new FlxText(0, 30, FlxG.width, "[ Options ]");
		header.setFormat(optionsFont, 32, 0xFF808080, CENTER);
		header.scrollFactor.set();
		add(header);

		catNameText = new FlxText(0, header.y + 30, FlxG.width, "Cat");
		catNameText.setFormat(optionsFont, 24, FlxColor.WHITE, CENTER);
		catNameText.scrollFactor.set();
		add(catNameText);

		var panelWidth:Int = Std.int(FlxG.width * 0.45);
		var panelHeight:Int = Std.int(FlxG.height * 0.5);

		catFrame = new FlxSprite(0, 50).makeGraphic(1, 1, 0xFF000000);
		// scaling it up instead of passing width and height on makeGraphic directly
		// because of the way flixel generates rectangles, its *worse* to do it on makeGraphic
		// scaling is generally better for memory usage
		catFrame.scale.set(panelWidth, panelHeight);
		catFrame.scrollFactor.set();
		catFrame.updateHitbox();
		catFrame.screenCenter();
		add(catFrame);

		camScroll = new FunkinCamera(catFrame.x, catFrame.y, panelWidth, panelHeight);
		camScroll.antialiasing = true;
		camScroll.bgColor.alpha = 0;
		FlxG.cameras.add(camScroll, false);

		camFollow = new FlxObject();
		camScroll.follow(camFollow, null, 0.60 * (60 / Preferences.user.frameRate));
		add(camFollow);

		catOptions = new FlxTypedSpriteGroup<FlxText>();
		catOptions.scrollFactor.set(0, 0.8);
		catOptions.camera = camScroll;
		add(catOptions);

		descriptionThingy = new FlxText(catFrame.x, 0, catFrame.width, "");
		descriptionThingy.textField.backgroundColor = 0x80000000;
		descriptionThingy.setFormat(optionsFont, 24, CENTER);
		descriptionThingy.textField.background = true;
		descriptionThingy.y = (FlxG.height - descriptionThingy.height) - 5;
		descriptionThingy.scrollFactor.set();
		descriptionThingy.screenCenter(X);
		add(descriptionThingy);

		updateCat();
	}

	var closing:Bool = false;
	var keyTimer:Float = 1.0;

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (closing)
			return;
		var up:Bool = controls.UP_P;
		if (up || controls.DOWN_P)
			changeSelection((up ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 5 : 1));
		// I genuinely hate this entire block of code and I'll probably change it later on -asmadeuxs
		var curOption:Option = curCatOptions[curSelected];
		var leftp:Bool = controls.LEFT_P;
		var rightp:Bool = controls.RIGHT_P;
		// choice options
		if ((leftp || rightp) && curOption.type != "number")
			changeOption(leftp ? -1 : 1);
		// number options
		var lefth:Bool = controls.LEFT;
		var righth:Bool = controls.RIGHT;
		if ((leftp || rightp || lefth || righth) && curOption.type == "number") {
			var change:Bool = false;
			if (leftp || rightp)
				change = true;
			else if (lefth || righth) {
				// TODO: implement keyRepeat in Controls so I don't have to do this shit manually -asmadeuxs
				keyTimer += 0.1;
				if (keyTimer >= 1.0) {
					change = true;
					keyTimer = 0.0;
				}
			}
			if (change) {
				var inc:Int = FlxG.keys.pressed.SHIFT ? 4 : 1;
				var left:Bool = leftp || lefth;
				changeOption(left ? -inc : inc);
			}
		} else if (controls.LEFT_R || controls.RIGHT_R)
			keyTimer = 0.0;
		// rest of the controls
		var leftCat:Bool = FlxG.keys.justPressed.Q;
		if (leftCat || FlxG.keys.justPressed.E) {
			catSelected = flixel.math.FlxMath.wrap(catSelected + (leftCat ? -1 : 1), 0, categoryOrder.length - 1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
			currentCat = categoryOrder[catSelected];
			updateCat();
		}
		if (controls.BACK_P) {
			closing = true;
			close();
			Preferences.save();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			new flixel.util.FlxTimer().start(0.5, (_) -> {
				if (parent is MainMenuState) {
					var menu:MainMenuState = cast parent;
					menu.selectedSomethin = false;
					menu.tweenItemsBackIn();
				}
			});
		}
		updateScroll();
	}

	public function changeOption(by:Int = 0, ?playSound:Bool = true) {
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));
		curCatOptions[curSelected].change(by);

		var val:FlxText = catOptions.members[curSelected * 2 + 1];
		val.text = curCatOptions[curSelected].valueString();
	}

	public function changeSelection(next:Int = 0, ?playSound:Bool = true) {
		curSelected = flixel.math.FlxMath.wrap(curSelected + next, 0, curCatOptions.length - 1);
		if (next != 0 && playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		if (catOptions.members.length > 0)
			for (entry in catOptions)
				entry.alpha = entry.ID == curSelected ? 1.0 : 0.6;
		if (curCatOptions != null) {
			var option = curCatOptions[curSelected];
			// descriptionThingy.text = option.description;
			descriptionThingy.text = Translator.translateString('optiondesc_${option.variable}');
			descriptionThingy.y = catFrame.y + catFrame.height + 10;
		}
	}

	public function updateScroll() {
		var scrollOffset:Float = 140;
		camFollow.y = catOptions.members[curSelected].y + scrollOffset;
	}

	public function updateCat() {
		while (catOptions.members.length > 0)
			catOptions.members.pop().destroy();
		curCatOptions = optionStash.get(currentCat);
		if (curSelected < 0 || curSelected > curCatOptions.length - 1)
			curSelected = 0;
		if (catNameText != null)
			catNameText.text = 'Viewing: $currentCat\nPress Q/E to change category\nPress Left/Right to change option';

		for (i => option in curCatOptions) {
			var nameText = new FlxText(20, 50 + i * 40, catFrame.width, Translator.translateString('option_${option.variable}'), 24);
			var valText = new FlxText(0, nameText.y, catFrame.width - 20, option.valueString(), 24);
			valText.font = optionsFont;
			valText.alignment = RIGHT;
			nameText.font = optionsFont;
			valText.ID = i;
			nameText.ID = i;
			catOptions.add(nameText);
			catOptions.add(valText);
		}
		changeSelection();
	}

	function onLanguageChanged(lang:String) {
		Translator.setLocale(lang);
		updateCat();
	}
}
