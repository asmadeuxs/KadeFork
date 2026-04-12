package registry;

/**
 * @author asmadeuxs
 */
class BaseRegistry<Registrable> {
	public var entries:Map<String, Registrable> = [];

	public var name:String = "BaseRegistry";
	public var locked:Bool = false;

	public function new(name:String):Void {
		this.name = name;
	}

	public function destroy():Void {
		locked = true;
		entries.clear();
	}

	public function unlock():Bool
		return locked = false;

	public function lock():Bool
		return locked = true;

	public function register(id:String, object:Registrable):Registrable {
		if (this.has(id)) {
			throw 'Tried registering "$id" but it already exists, use a different ID.';
			return null;
		}
		if (locked) {
			trace('You cannot register anything new if the registry is locked (for "$name")');
			return null;
		}
		entries.set(id, object);
		return entries.get(id);
	}

	public function get(id:String):Registrable {
		if (!this.has(id)) {
			trace('Registry does not have "$id" (does it need to be registered?)');
			return null;
		}
		return entries.get(id);
	}

	public function iterator():Iterator<Registrable>
		return entries.iterator();

	public function keys():Iterator<String>
		return entries.keys();

	public function has(id:String):Bool
		return entries.exists(id);
}
