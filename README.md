# WC3 Code Paste Helper

This small script helps you to paste Lua code from your editor to
[Eikonium's Lua Debug Console](https://www.hiveworkshop.com/threads/lua-debug-utils-ingame-console-etc.330758/)
for execution. This console can accept multi-line input of code when you prepend
it with `>`.

All you have to do:

1. Copy code in editor
2. Go to game and press CTRL+B to paste it as multi-line code

For example, copy this code:

```lua
x = 19
y = 2
print("x + y = ".. x + y)
```

will be pasted in game chat like this to be executed:

```lua
>x = 19
>y = 2
print("x + y = ".. x + y)
```

Watch the [video here](https://github.com/Luashine/wc3-debug-console-paste-helper/issues/1)

<video src="https://user-images.githubusercontent.com/103937213/201783924-1320cf78-bd72-47fe-a750-27dd784ba2f8.mp4" />

## Features:

- Fast
- Multi-line paste
- Prepares code lines for you
- Skips empty lines
- Warns about lines too long for chat (max: 127 characters)
- Audio indicators
- Restores your clipboard after pasting in WC3
- Configurable
- Probably many false-positives by anti-virus software (complain to them about it)
    - Why? AutoIt was used by scriptkiddies in the past, but it doesn't excuse
a blanket ban that flags ALL au3 scripts as malware.

## Usage instructions

- Open [in-game console](https://www.hiveworkshop.com/threads/lua-debug-utils-ingame-console-etc.330758/) with `-console`
- Start the program
- Copy code
- Go to Warcraft III window
- Press `CTRL+B`

Exit the program: there'll be an icon in tray. Right Click -> Exit.
Note: if you just right click the icon, the script will be paused immediately.
You need to unpause it to use.

## Compilation instructions:

It uses AutoIt3, [download](https://www.autoitscript.com/site/autoit/downloads/) and install it. Then you can double-click to run the `.au3` file or right-click -> compile to EXE.
