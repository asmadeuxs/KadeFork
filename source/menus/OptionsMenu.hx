package menus;

import data.Option;
import data.Preferences;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

// I JUST MADE SOME BULLLLLLLLLLLLLLLLLLSHIT -asmadeuxs
class OptionsMenu extends MusicBeatSubstate {
	public var optionStash:Map<String, Array<Option>> = [
		"Preferences" => [
			{
				type: "number",
				name: "FPS",
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
			{
				name: "Center Strums",
				variable: "centerStrums",
				description: "Centers your strums and hides the opponent's"
			},
			{
				name: "Ghost Tapping",
				description: "Lets you mash without penalty",
				variable: "ghostTapping"
			},
			{
				name: "Wife3 Accuracy",
				description: "Changes the accuracy system to use Wife3\nIt's way more complex (math-wise) for the sake of encouraging super accurate hits\nBut may feel mean to newer players",
				variable: "etternaMode"
			},
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
				name: "Show Song Position",
				description: "Shows a progress bar for the song in the HUD",
				variable: "showSongPosition"
			},
			{
				name: "Show Notes per Second",
				description: "Shows a NPS counter on the Score Text",
				variable: "showNps"
			},
			{
				name: "More Stats",
				description: "Shows Misses and Accuracy in the Score Text",
				variable: "accuracyDisplay"
			},
			{
				name: "Distractions",
				description: "Disables certain sounds and effects that may be distracting.",
				variable: "distractions"
			},
			/*{
				name: "Language",
				description: "Changes the game's text interfaces to be on a different language.",
				type: "choice",
				choices: Locale.list(),
			},*/
			{
				name: "Interface Dim",
				description: "Enables a background behind the strums or stage",
				variable: "strumUnderlay"
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
	var catOptions:FlxTypedGroup<FlxText>;
	var catFrame:FlxSprite;

	var optionsFont = Paths.font("vcr");
	var parent:MusicBeatState;

	public function new(parent:MusicBeatState) {
		this.parent = parent;
		super();
	}

	override function create():Void {
		super.create();
		currentCat = categoryOrder[catSelected];

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

		catFrame = new FlxSprite(0, 50).makeGraphic(1, 1, 0xFF000000);
		// scaling it up instead of passing width and height on makeGraphic directly
		// because of the way flixel generates rectangles, its *worse* to do it on makeGraphic
		// scaling is generally better for memory usage
		catFrame.scale.set(FlxG.width * 0.45, FlxG.height * 0.5);
		catFrame.scrollFactor.set();
		catFrame.updateHitbox();
		catFrame.screenCenter();
		add(catFrame);

		catOptions = new FlxTypedGroup<FlxText>();
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

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (closing)
			return;
		var leftCat:Bool = FlxG.keys.justPressed.Q;
		if (leftCat || FlxG.keys.justPressed.E) {
			catSelected = flixel.math.FlxMath.wrap(catSelected + (leftCat ? -1 : 1), 0, categoryOrder.length - 1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
			currentCat = categoryOrder[catSelected];
			updateCat();
		}
		var up:Bool = controls.UP_P;
		if (up || controls.DOWN_P)
			changeSelection((up ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 5 : 1));
		var left:Bool = controls.LEFT_P;
		if (left || controls.RIGHT_P) {
			curCatOptions[curSelected].change(left ? -1 : 1);
			catOptions.members[curSelected * 2 + 1].text = curCatOptions[curSelected].valueString();
			FlxG.sound.play(Paths.sound('scrollMenu'));
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
	}

	public function changeSelection(next:Int = 0, ?playSound:Bool = true) {
		curSelected = flixel.math.FlxMath.wrap(curSelected + next, 0, curCatOptions.length - 1);
		if (next != 0 && playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		if (catOptions.members.length > 0)
			for (entry in catOptions)
				entry.alpha = entry.ID == curSelected ? 1.0 : 0.6;
		if (curCatOptions != null) {
			descriptionThingy.text = curCatOptions[curSelected].description;
			descriptionThingy.y = catFrame.y + catFrame.height + 10;
		}
	}

	public function updateCat() {
		curSelected = 0;
		if (catNameText != null)
			catNameText.text = 'Viewing: $currentCat\nPress Q/E to change category\nPress Left/Right to change option';

		while (catOptions.members.length > 0)
			catOptions.members.pop().destroy();

		var i:Int = 0;
		curCatOptions = optionStash.get(currentCat);
		for (option in curCatOptions) {
			var nameText = new FlxText(catFrame.x + 20, catFrame.y + 50 + i * 40, 0, option.name, 24);
			var valText = new FlxText(catFrame.x + catFrame.width - 100, nameText.y, 0, option.valueString(), 24);
			valText.scrollFactor.set();
			valText.font = optionsFont;
			valText.alignment = RIGHT;
			nameText.scrollFactor.set();
			nameText.font = optionsFont;
			valText.ID = i;
			nameText.ID = i;
			catOptions.add(nameText);
			catOptions.add(valText);
			i++;
		}
		changeSelection();
	}
}
