Kade Engine 1.4.2 fork because I was bored.

you might wanna use `--recurse-submodules` when cloning this repository since it has some local ones that are needed for the game to compile.

```
git clone --recurse-submodules https://github.com/asmadeuxs/KadeFork.git
```
or with ssh
```
git clone --recurse-submodules git@github.com:asmadeuxs/KadeFork.git
```

todo (this is more for myself @asmadeuxs than anything.):
- repo:
	- write real readme
	- write new issue templates
- libs:
	- add [flixel-animate](https://github.com/MaybeMaru?tab=repositories) support
	- add [hxvlc](https://github.com/MAJigsaw77/hxvlc) for video support
- game:
	- re-add replays
	- add things to make hardcoding easier and convenient since that's the orientation i wanna go with
		- softcoded mods will exist, but again, hardcoding is the focus
	- rewrite all the menus
		- probably change the visuals also if i can when i get to that point
		- - it's my fork anyway the default menus can look different from other forks idc.
	- darnell
	- image_friend
