package registry;

/**
 * @author asmadeuxs
 */
class BaseRegistry<Registrable> {
	public var entries:Map<String, Registrable> = new Map();

	var _toID:Map<String, Int> = new Map();

	public var name:String = "BaseRegistry";
	public var locked:Bool = false;
	public var length(get, never):Int;

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

	public function register(id:String, object:Registrable, ?force:Bool = false):Registrable {
		if (this.has(id) && !force) {
			throw 'Tried registering "$id" but it already exists, use a different ID.';
			return null;
		}
		if (locked) {
			trace('You cannot register anything new if the registry is locked (for "$name")');
			return null;
		}
		_toID.set(id, _length);
		_length++;
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

	public function getFromIndex(idx:Int):Registrable {
		for (key in _toID.keys())
			if (_toID.get(key) == idx)
				return entries.get(key);
		trace('Entry at index $idx not found.');
		return null;
	}

	public function unregister(id:String):Bool {
		var result:Bool = false;
		if (locked) {
			trace('You cannot unregister anything new if the registry is locked (for "$name")');
			return result;
		}
		if (this.has(id)) {
			result = true;
			entries.remove(id);
			_toID.remove(id);
			_length--;
		}
		return result;
	}

	public function unregisterWithInstance(instance:Registrable):Bool {
		var result:Bool = false;
		if (locked) {
			trace('You cannot unregister anything new if the registry is locked (for "$name")');
			return result;
		}
		for (i in entries.keys()) {
			if (entries.get(i) == instance) {
				result = true;
				entries.remove(i);
				_toID.remove(i);
				_length--;
				break;
			}
		}
		return result;
	}

	public function getAll():Array<Registrable>
		return [for (registered in entries) registered];

	public function iterator():Iterator<Registrable>
		return entries.iterator();

	public function keys():Iterator<String>
		return entries.keys();

	public function has(id:String):Bool
		return entries.exists(id);

	@:noCompletion @:noPrivateAccess @:unreflective
	var _length:Int = 0;

	@:noCompletion function get_length():Int
		return _length;
}
