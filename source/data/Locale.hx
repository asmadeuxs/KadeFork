package data;

import util.CoolUtil;

using StringTools;

@:structInit @:publicFields class LocaleData {
	var name:String;
	var nativeName:String;
	@:optional var strings:Map<String, String> = [];
	@:optional var pathOverrides:Map<String, String> = [];

	public function has(id:String):Bool
		return strings.exists(id);

	public function get(id:String):String
		return strings.get(id);

	public function toString():String
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
		for (i in Paths.listFiles(path)) {
			if (!i.endsWith('.csv'))
				continue;
			var lines:Array<String> = Paths.getText(haxe.io.Path.addTrailingSlash(path) + i).split('\n');
			if (lines == null || lines.length == 0) {
				trace('Translation file "$i" is empty.');
				continue;
			}
			var language:LocaleData = {name: null, nativeName: null};
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
						language.pathOverrides.set(keyTrim, value);
					case _:
						language.strings.set(keyTrim, value);
				}
			}
			locales.set(haxe.io.Path.withoutExtension(i), language);
		}
		trace(locales);
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
	 * @param id String
	 * @param replacements haxe.Rest<Dynamic>
	 * @return String
	 */
	public function translateFormat(id:String, ...replacements:Dynamic):String
		return format(translateString(id), ...replacements);

	/**
	 * Translates a string from an id
	 *
	 * @param id String
	 * @return String
	 */
	public function translateString(id:String):String {
		var l:LocaleData = locales.get(this.language);
		return l?.get(id) ?? '$id';
	}

	/**
	 * Same as translateString but specifically looks for any IDs ending in _plural
	 *
	 * returns a non-plural version of the string if it can't be found.
	 * @param id String
	 * @return String 
	 */
	public function translatePlural(id:String):String {
		var plu:String = translateString(id + '_plural');
		if (plu == id) {
			trace('${this.language} has no plural for string "$id"');
			plu = translateString(id);
		}
		return plu;
	}
}
