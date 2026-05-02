package data;

import util.CoolUtil;

using StringTools;

typedef StringMap = Map<String, String>;

@:structInit @:publicFields class LocaleData {
	var name:String;
	var nativeName:String;
	@:optional var strings:Map<String, StringMap> = [];
	@:optional var pathOverrides:Map<String, StringMap> = [];

	function hasCategory(cat:String):Bool
		return strings.exists(cat);

	function hasString(cat:String, id:String):Bool
		return strings.exists(cat) && strings[cat].exists(id);

	public function getCategory(cat:String, id:String):StringMap
		return strings[cat];

	function getString(cat:String, id:String):String
		return strings.exists(cat) ? strings[cat][id] : null;

	function getPath(category:String, id:String):String
		return pathOverrides[category][id];

	function find(id:String):String {
		var formatted:String = id;
		for (key in strings.keys()) {
			if (strings[key] != null && strings[key][id] != null) {
				formatted = strings[key][id];
				break;
			}
		}
		return formatted;
	}

	function findPath(path:String):String {
		var formatted:String = path;
		for (key in pathOverrides.keys()) {
			if (pathOverrides[key] != null && pathOverrides[key][path] != null) {
				formatted = pathOverrides[key][path];
				break;
			}
		}
		return formatted;
	}

	function toString():String
		return '[Locale, $name]';
}

class Locale {
	public static var current:Locale;

	public var language:String = 'en';

	var locales:Map<String, LocaleData> = [];

	public function new(language:String):Void {
		this.language = language;
		reloadLocales();
		current = this;
	}

	public function reloadLocales():Void {
		var path:String = Paths.getPath('data/locales');
		if (!Paths.fileExists(path))
			return;
		for (localeDir in Paths.listFiles(path)) {
			var lang = reloadLocaleDirectory(localeDir);
			if (lang != null)
				locales.set(localeDir, lang);
		}
	}

	public function reloadLocaleDirectory(locale:String):LocaleData {
		var localeFiles:String = Paths.getPath('data/locales/$locale');
		if (!Paths.fileExists(localeFiles))
			return null;
		var ats = haxe.io.Path.addTrailingSlash;
		var language:LocaleData = {name: null, nativeName: null};
		for (i in Paths.listFiles(localeFiles)) {
			if (!i.endsWith('.csv'))
				continue;
			var lines:Array<String> = Paths.getText(ats(localeFiles) + i).split('\n');
			if (lines == null || lines.length == 0) {
				trace('Translation file "$i" (for language $locale) is empty.');
				continue;
			}
			var ii:String = haxe.io.Path.withoutExtension(i);
			language.strings.set(ii, new Map());
			for (id => line in lines) {
				var t:String = line.trim();
				if (t.length == 0 || CoolUtil.isComment(t))
					continue;
				var lineSplit:Array<String> = line.trim().split(',');
				if (lineSplit.length < 2) {
					trace('Line $id has no value set (for translation file "$i")');
					continue;
				}
				var keyTrim:String = lineSplit[0].trim();
				var value:String = lineSplit[1];
				switch keyTrim {
					case(_.toLowerCase() == 'name') => true:
						language.name = value;
					case(_.toLowerCase() == 'nativename' || _.toLowerCase() == 'native name') => true:
						language.nativeName = value;
					case(Paths.fileExists(_)) => true:
						if (!language.pathOverrides.exists(ii))
							language.pathOverrides.set(ii, new Map());
						language.pathOverrides[ii].set(keyTrim, value);
					case _:
						language.strings[ii].set(keyTrim, CoolUtil.formatEscapeStrings(value));
				}
			}
		}
		return language;
	}

	public function getAvailableLanguageIDs():Array<String> {
		var ids:Array<String> = [];
		for (i in locales.keys())
			ids.push(i);
		return ids;
	}

	public function setLocale(localeID:String, ?resetToDefault:Bool = false):String {
		if (locales.exists(localeID))
			this.language = localeID;
		else if (resetToDefault)
			this.language = 'en';
		return this.language;
	}

	public function setLocaleFromName(localeName:String):String {
		for (lang in locales.keys()) {
			var i:LocaleData = locales.get(lang);
			if (i.name == localeName)
				return this.language = lang;
		}
		return this.language;
	}

	public function setLocaleFromNativeName(nativeName:String):String {
		for (lang in locales.keys()) {
			var i:LocaleData = locales.get(lang);
			if (i.nativeName == nativeName)
				return this.language = lang;
		}
		return this.language;
	}

	public function getLangName(?lang:String):String {
		if (lang == null)
			lang = this.language;
		return locales.exists(lang) ? locales.get(lang).name : lang;
	}

	public function getNativeLangName(?lang:String):String {
		if (lang == null)
			lang = this.language;
		return locales.exists(lang) ? locales.get(lang).nativeName : lang;
	}

	public function format(id:String, ...rest:Dynamic):String {
		var result = id;
		for (i in 0...rest.length)
			result = result.split('{${i + 1}}').join(Std.string(rest[i]));
		return result;
	}

	/**
	 * Translates a string and replaces all numbered brackets (i.e: {1}, {2}, ...) with the values attached.
	 *
	 * May be a bit slow if you're doing it every frame.
	 * @param cat String Category the string is at (i.e: menus) - this is usually the csv file name
	 * @param id String
	 * @param replacements haxe.Rest<Dynamic>
	 * @return String
	 */
	public function translateFormat(cat:String, id:String, ...replacements:Dynamic):String
		return format(translateString(cat, id), ...replacements);

	/**
	 * Translates a string from an id
	 *
	 * @param cat String Category the string is at (i.e: main) - this is usually the csv file name
	 * @param id String
	 * @return String
	 */
	public function translateString(cat:String, id:String):String {
		var l:LocaleData = locales.get(this.language);
		return l?.getString(cat, id) ?? '$cat:$id';
	}

	/**
	 * Same as translateString but specifically looks for any IDs ending in _plural
	 *
	 * returns a non-plural version of the string if it can't be found.
	 * @param cat String Category the string is at (i.e: menus) - this is usually the csv file name
	 * @param id String
	 * @return String
	 */
	public function translatePlural(cat:String, id:String):String {
		var plu:String = translateString(cat, id + '_plural');
		if (plu == '$cat:${id}_plural') {
			trace('${this.language} has no plural for string "$id"');
			plu = translateString(cat, id);
		}
		return plu;
	}
}
