# Scripts!

Scripts specifically refer to HScript, Where the specific library we use in this engine is [this one](https://github.com/troll-slaiyers/t-hscript)

Supported file extensions are

```
hx
hxc
hxs
hscript
```

## Built-in variables (*All script types!*)

```haxe
// By default, the following libraries are implemented:
// - Standard Libraries:
// --- Std, Math, StringTools
// - Flixel Classes:
// --- FlxG, FlxSprite, FlxColor
// - Game Classes:
// --- Translator
// ---- This is an instance of Locale.current
// ---- Note that it may not exist if you compiled *without* translation support
// --- Preferences
// ---- So you can access built-in settings
// --- CoolUtil, Paths

// FlxColor in particular is a wrapper
// As FlxColor is not a real object
// For that, it's a bit more limited in HScript (can't be used as a value for example)

// These are built-in values so you can get the version numbers for the game
// The relevant one is really just _FORKVERSION, the rest are *very* unlikely to ever be updated
_GAMEVERSION = Main.versions.KADE;
_KADEVERSION = Main.versions.BASE_GAME;
_FORKVERSION = Main.versions.FORK;

// This defines the script's priority
// Negative values will be ignored
_priority = -1;

// These are return values for functins
STOP = "#HSCRIPT_STOP_FUNC"; // Stops the *original* hardcoded function so you can make your own logic
CONTINUE = "#HSCRIPT_CONTINUE_FUNC"; // Default return value for hscript functions, here for consistency, you can probably find a usage for it
KILL = "#HSCRIPT_KILL_SCRIPT"; // This lets the hardcoded function run, but *immediately* deactivates the current script
_MODNAME = "???" // This saves the name of the mod that the script was found at, useful for Paths mainly

// These two are useful if you want to get/set settings for your own mod
// keep in mind, these can only get settings from the *current* mod (at least for now)
// So if you're playing songs from "Mod A", you won't be able to get settings at "Mod B"
function getSetting(name:String):Dynamic;
function setSetting(name:String, value:Dynamic):Void;
```
