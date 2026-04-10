package util;

class ObjectPool<T:flixel.FlxObject> {
	var _pool:Array<T> = [];
	var _constructor:(Int) -> T = null;
	var _size:Int = 16;

	public function new(length:Int, constructor:(Int) -> T):Void {
		this._size = length > 0 ? length : this._size;
		this._constructor = constructor;
		if (this._constructor == null) {
			throw "(ObjectPool.new) Cannot have an object pool without any constructor, Please provide one.";
			return;
		}
		initiatePool();
	}

	public function initiatePool():Void {
		for (_ in 0..._size) {
			var obj = _constructor(_);
			obj.visible = false;
			obj.active = false;
			_pool.push(obj);
		}
	}

	public function get():Null<T> {
		for (obj in _pool) {
			if (!obj.visible && !obj.active) {
				obj.visible = true;
				obj.active = true;
				return obj;
			}
		}
		return null;
	}

	public function release(obj:T):Void {
		obj.visible = false;
		obj.active = false;
	}

	public function getSize():Int
		return this._size;

	public function getAll():Array<T>
		return this._pool;
}
