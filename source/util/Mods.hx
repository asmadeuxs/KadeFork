package util;

import util.CoolUtil;

using StringTools;

class Mods {
	public static final modRoot:String = 'mods';

	private static var allMods:Array<String> = [];
	private static var activeMods:Array<String> = [];

	public static function scan():Array<String> {
		allMods.resize(0);
		activeMods.resize(0);
		#if FEATURE_MODS
		var modList:Array<String> = CoolUtil.coolList(Paths.getText('$modRoot/modList.txt'));
		for (idState in modList) {
			var data = idState.split(":");
			if (data.length > 1) {
				var enabled = data[1] == "true";
				allMods.push(data[0]);
				if (enabled)
					activeMods.push(data[0]);
			}
		}
		#elseif debug
		trace('Mods feature disabled in this build (did you compile with FEATURE_MODS defined?)');
		#end
		return allMods;
	}

	public static function getEnabled()
		return activeMods;
}
