# Mods!

Simply put, every mod folder has the same exact structure as the assets folder

You can add your own files or override existing ones

## Folder naming

- Mods folder **cannot** contain forward slashes in their names
	- Internally, this is used to distinguish a mod name from a path
		If your mod folder has a forward slash in its name, the assets system gets confused
		and will likely think its a path and not a mod, that's why it may fail to get the asset from your mod.

Other than that there's not much restriction when it comes to mod folder names

## NOTE (for Windows users)

Due to the nature of non-Windows systems, This modding system purposefully *disables* Windows' case-insensitive paths

All your files *must* be named and accessed with the correct case, so you can't call

```haxe
Paths.image('menu/Background')
```

While the actual file is named `background.png` - this will fail.

So, name your files properly, access them with their actual names, case included.

I do **not** plan on fixing this! -asmadeuxs

## Built-in files

Currently, for a mod to be recognised, it must have a mod.txt file in its folder

```
mods/
	myMod/
		mod.txt
```

The contents of that file are something like this

```plain
Mod Name|Description|v.v.v
```

where `v.v.v` is the API Version intended for the mod to run on

for example, if you're running v1.0.0 of the engine, then you wanna set the API Version to 1.0.0

The good news is that if you don't set the version, it just assumes its meant to work in the latest version

The bad news is that if you don't set the version, it **assumes** its meant to work in the latest version
	If your mod uses deprecated functions/files or some characteristics added in a later version, it may be buggy for the player

This file can also simply have a name

```plain
Mod Name
```

The other fields are optional, but realistically, you probably *want* a description.
