package editor.obj;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Matrix;

class ChartingGrid extends FlxSprite {
	public var columns:Int;
	public var rows:Int;

	public var cellSize:Int;
	public var beatInterval:Int = 4;

	public var lineColor1:FlxColor = 0xFF505050;
	public var lineColor2:FlxColor = 0xFF808080;

	public var lineWidth1:Int = 2;
	public var lineWidth2:Int = 1;

	public var checkerColor1:FlxColor = 0xFFDDDDDD;
	public var checkerColor2:FlxColor = 0xFFAAAAAA;

	public function new(x:Float, y:Float, columns:Int, rows:Int, cellSize:Int):Void {
		super(x, y);
		antialiasing = false;
		this.columns = columns;
		this.cellSize = cellSize;
		this.rows = rows;
		redraw();
	}

	public function changeLineColor(color1:FlxColor, ?color2:FlxColor) {
		lineColor1 = color1;
		lineColor2 = color2 != null ? color2 : 0xFF505050;
		redraw();
	}

	public function changeCheckerColor(color1:FlxColor, ?color2:FlxColor) {
		checkerColor1 = color1;
		checkerColor2 = color2 != null ? color2 : 0xFFAAAAAA;
		redraw();
	}

	public function redraw():Void {
		var width = columns * cellSize;
		var height = rows * cellSize;
		var temp = new Sprite();
		var g = temp.graphics;

		g.clear();

		// checkerboard pattern
		for (row in 0...rows) {
			for (col in 0...columns) {
				var isEven = (row + col) % 2 == 0; // https://www.npmjs.com/package/is-even
				g.beginFill(isEven ? checkerColor1 : checkerColor2, 1.0);
				g.drawRect(col * cellSize, row * cellSize, cellSize, cellSize);
				g.endFill();
			}
		}
		// vertical lines
		g.lineStyle(1, lineColor1, 1.0);
		for (c in 0...columns + 1) {
			var linex = c * cellSize;
			g.moveTo(linex, 0);
			g.lineTo(linex, height);
		}
		// beat lines
		for (row in 0...rows + 1) {
			if (row % beatInterval == 0)
				g.lineStyle(lineWidth1, lineColor1, 1.0);
			else
				g.lineStyle(lineWidth2, lineColor2, 1.0);
			var lineY = row * cellSize;
			g.moveTo(0, lineY);
			g.lineTo(width, lineY);
		}
		var bmd = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
		bmd.draw(temp, new Matrix());
		loadGraphic(bmd);
		setSize(width, height);
	}
}
