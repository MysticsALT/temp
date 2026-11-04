# Mystics V3.0

A premium two-stage launcher and Rocket League crate interface.

## Run Mystics

Execute only the launcher:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MysticsALT/temp/main/Mystics_Launcher.lua"))()
```

## Startup and on-demand loading

- Startup creates only the Mystics Hub launcher.
- The RL Crate experience is not downloaded or initialized at startup.
- Clicking **RL Crate Unboxing** downloads `RLCrate.lua` from the immutable commit pinned in `Mystics_Launcher.lua`.
- The launcher checks the response, compiles it, and then executes it.
- If loading fails, the hub remains available and the button can be retried.

## Files

- `Mystics_Launcher.lua` — premium hub, launcher UI and lazy loader.
- `RLCrate.lua` — RL Crate interface, themes, statistics and automation.
- `backups/Mystics_Launcher_pre_V3.lua` — pre-refresh launcher backup.
- `backups/RLCrate_pre_V3.lua` — pre-refresh crate module backup.

The V3 refresh is cosmetic. Core reward detection, value tracking, automation and Anti-AFK logic were intentionally left unchanged.
