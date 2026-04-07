package menus;

class GenericMenu extends MusicBeatState
{
	public var curSelected:Int = 0;

	public var minSelections:Int = 0;
	public var maxSelections:Int = 1;

	public var onSelectionChanged:Void->Void;
	public var onAcceptPressed:Void->Void;
	public var onBackPressed:Void->Void;

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (Controls.justPressed("ui_cancel") && onBackPressed != null)
      onBackPressed();
    if (Controls.justPressed("ui_accept") && onAcceptPressed != null)
      onAcceptPressed();
  }

	public function changeSelection(next:Int = 0, ?playScrollSound:Bool = true)
	{
		curSelected = flixel.math.FlxMath.wrap(curSelected + next, minSelections, maxSelections);
		if (next != 0 && playScrollSound)
			FlxG.sound.play(Paths.sound("scrollMenu"));
    if (onSelectionChanged != null)
      onSelectionChanged();
	}
}
