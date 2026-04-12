package registry;

import util.CoolUtil;

using StringTools;

typedef LevelLabel = {
	texture:String,
}

typedef LevelSong = {
	name:String,
	folder:String,
	?album:String,
	?icon:String,
	?difficulties:Array<String>,
}

typedef LevelData = {
	tagline:String,
	difficulties:Array<String>,
	labelObject:LevelLabel,
	songs:Array<LevelSong>
}

class LevelRegistry extends BaseRegistry<LevelData> {
	public static var current:LevelRegistry = null;

	var ordered:Array<String> = null;

	public function new():Void {
		super("LevelRegistry");
		current = this;
	}

	override function destroy() {
		ordered.resize(0);
		ordered = null;
		super.destroy();
	}

	@:noPrivateAccess
	private function isJson(f:String) {
		var ext = haxe.io.Path.extension(f);
		return Paths.jsonExtensions.contains(ext);
	}

	public function loadLevels(?mod:String = null) {
		if (ordered == null || ordered.length > 0) {
			if (ordered == null)
				ordered = [];
			else
				ordered.resize(0);
		}
		var origin:String = Paths.getAssetOrigin(mod);
		var levelDir:String = Paths.getPath('data/levels', null, mod);
		if (!Paths.fileExists(levelDir)) {
			trace('Level directory "$levelDir" does not exist.');
			return;
		}
		if (mod == "core")
			trace('Loading built-in levels (from assets folder)');
		else
			trace('Loading levels from mod "$mod"');
		for (file in Paths.listFiles(levelDir)) {
			if (!isJson(file) || !Paths.fileExists(Paths.getPath('data/levels/$file')))
				continue;
			var regKey:String = '$origin${file.substr(0, file.lastIndexOf("."))}';
			var level:LevelData = cast Paths.getPath('data/levels/$file', JSON5);
			if (level != null)
				register(regKey, level);
			else
				trace('Level "$file" is not valid. (check spelling errors?)');
		}
		if (Paths.fileExists(Paths.getPath('data/levelList.txt')))
			ordered = CoolUtil.coolList(Paths.getText(Paths.getPath('data/levelList.txt')));
	}

	public function getOrderedLevels():Array<String>
		return ordered;
}
