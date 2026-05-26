The folders themselves look like this

```
assets/
	scripts/
		songs/
			songName/
				a.hxs
				b.hscript
				c.hx
				d.hxc
```

All scripts in that folder will run

You can set the priority of each script by overriding one of its built-in variables

```haxe
// like this
_priority = 9999;
```
