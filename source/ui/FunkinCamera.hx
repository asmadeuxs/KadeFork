package ui;

class FunkinCamera extends flixel.FlxCamera {
	/**
	 * Any `FlxCamera` with a zoom of 0 (the default value) will have this zoom value.
	 */
	public static var defaultZoom:Float = 1.0;

	/**
	 * Instantiates a new camera at the specified location, with the specified size and zoom level.
	 *
	 * @param   X        X location of the camera's display in pixels. Uses native, 1:1 resolution, ignores zoom.
	 * @param   Y        Y location of the camera's display in pixels. Uses native, 1:1 resolution, ignores zoom.
	 * @param   Width    The width of the camera display in pixels.
	 * @param   Height   The height of the camera display in pixels.
	 * @param   Zoom     The initial zoom level of the camera.
	 *                   A zoom level of 2 will make all pixels display at 2x resolution.
	 */
	public function new(x:Float = 0, y:Float = 0, width:Int = 0, height:Int = 0, zoom:Float = 0) {
		super(0, 0, width, height, zoom);
		// these parameters are ints in FlxCamera (even though this.x and this.y are floats)
		// so I had to override it -asmadeuxs
		this.x = x;
		this.y = y;
	}
}
