# Jagged Alliance 3: Developer Tools

Circumvent sandbox to allow more control over modding tools and other features in the game.

## WARNING
Operating without the sandbox circumvents the security measures that prevent scripts from accessing your filesystem and other sensitive areas. It's important to keep in mind that any mods you install can also inherit these capabilities if they are made with malicious intent.

## Modified Lua.hpk
Used to inject our scripts as early as possible in the loading. Only one file (`CommonLua\Core\autorun.lua`) is changed, adding the lines below:

```lua
print("[autorun.lua] Platform.developer = true")
Platform.developer = true
print("[autorun.lua] Platform.goldmaster = false")
Platform.goldmaster = false
print("[autorun.lua] Injecting dev_inject.lua")
dofile("dev_inject.lua")
```


## Installation

- Clone/download repo.

- Copy `dev_inject.lua` and `dev_luadebugger.lua` to your installation directory (ex. `"C:\Program Files (x86)\Steam\steamapps\common\Jagged Alliance 3"`.)

- Replace official `Lua.hpk` (`"C:\Program Files (x86)\Steam\steamapps\common\Jagged Alliance 3\Packs\Lua.hpk"`) with `Packs/Lua.hpk`.

- Change `dev_log_dir` and `local_files_path` in `dev_inject.lua`, near the top.

- Start the game with the command line argument `-dev`.
Steam shortut: `steam://run/1084160//-dev`

## Features

- Add files and folders to `use_local_files` if you want the game to load them rather than the packaged files. Paths need to be the normal relative loading paths that the game uses.

- Fixes XWindow Inspector property view and context inspection.

- Use `DevLog(...)` in the console to log to a basic text editor window.

- `DevLog(msg_log)` shows all `Msg(...)` events since the last clear (`msg_log = {}`.)

- Log anything to a file in the `dev_log` directory quickly with:
`LogToFile(log_name, data, levels, charsperline)`
`LogToFile(data, levels, charsperline)`

- Unlocks `ReloadLua()`.

- Use call tracing and write log file: `Tracing.TraceFor(<seconds>)` or `Tracing.SetHook()`, `Tracing.RemoveHook()` and `Tracing.SaveLog()`.

- Modify things directly after a specific file is loaded in the method: `dev_file_was_loaded`.

- Adds tags to the Mod Editor.

- Includes an example of how to modify ModItemOption to allow custom properties to be uploaded to Steam Workshop.

- Modifies `FetchLuaSource` to enable the game to get the actual Lua code for methods during runtime. This fixes all missing functions in templates, etc.

- Re-enables the Console anytime it is disabled.

- Activates Console, XInspector, DevLog, etc. in all Ged Apps.

- Hotkeys
Alt-Shift-U: User Actions menu
Alt-Shift-I: XWindow Inspector
Alt-Shift-M: Mod Manager

## Optional

`Lua\Config\load_at_startup.lua`
Simple way to break sandbox and access real `_G`. Loads too late for full control over the Lua environment.
