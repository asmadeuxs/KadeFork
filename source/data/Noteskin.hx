package data;

import flixel.util.typeLimit.OneOfTwo;

typedef NoteskinFile = {
	texture:String,
	animations:Array<OneOfTwo<Dynamic, String>>,
	offsets:Array<OneOfTwo<Array<Dynamic>, String>>
}

class Noteskin {
	public static function getDefaultConfig() {}

	public function loadNoteskin(filename:String):Void {
		var file:NoteskinFle = Json.parse(Assets.getText(findCharacterFile(filename)));
		if (file.texture != null)
			frames = Paths.getSparrowAtlas('${file.texture}');
		else
			frames = Paths.getSparrowAtlas('gameplay/noteskins/$filename/$filename');
		if (file.offsets != null) {
			for (key in Reflect.fields(file.offsets)) {
				var offset:Dynamic = Reflect.field(file.offsets, key);
				if (offset != null) {
					if (offset is Array)
						addOffset(key, offset[0] ?? 0, offset[1] ?? 0);
					else if (offset is Dynamic)
						addOffset(key, offset.x ?? 0, offset.y ?? 0);
				}
			}
		}
		if (file.animations != null) {
			var defaultFramerate:Int = file.defaultFramerate ?? 24;
			for (key in Reflect.fields(file.animations)) {
				var stuff:Dynamic = Reflect.field(file.animations, key);
				switch Type.typeof(stuff) {
					case TObject:
						stuff.looped = Std.string(stuff.looped);
						if (stuff.indices != null) {
							var indies:Array<Int> = parseJsonIndicesField(stuff.indices);
							animation.addByIndices(key, stuff.prefix, indies, "", stuff.frameRate ?? defaultFramerate, stuff.looped == "true");
						} else
							animation.addByPrefix(key, stuff.prefix, stuff.frameRate ?? defaultFramerate, stuff.looped == "true");
						if (stuff.offset != null) {
							if (stuff.offset is Array)
								addOffset(key, stuff.offset[0] ?? 0, stuff.offset[1] ?? 0);
							else if (stuff.offset is Dynamic)
								addOffset(key, stuff.offset.x ?? 0, stuff.offset.y ?? 0);
						}
					case TClass(String):
						animation.addByPrefix(key, stuff, defaultFramerate, false);
					case _:
						continue;
				}
			}
		}
	}
}
