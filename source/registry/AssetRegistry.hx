package registry;

class AssetRegistry<Asset> extends BaseRegistry<Asset> {
	public var clearFunc:(key:String, value:Asset) -> Void;

	public function new(clearFunc:(key:String, value:Asset) -> Void):Void {
		super("AssetRegistry");
		this.clearFunc = clearFunc;
	}

	public function clear(validate:(key:String, value:Asset) -> Bool):Void {
		for (key in entries.keys()) {
			var assetEntry:Asset = entries.get(key);
			if (validate(key, assetEntry)) {
				clearFunc(key, assetEntry);
				entries.remove(key);
			}
		}
	}
}
