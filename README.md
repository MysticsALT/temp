# Mystics Hub

The launcher is the only script that should be executed directly. It creates the Mystics Hub UI and does not load the RL Crate experience during startup.

## Launch

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MysticsALT/temp/main/Mystics_Launcher.lua"))()
```

## On-demand RL Crate loading

- Click **RL Crate Unboxing** in the hub.
- The launcher downloads `RLCrate.lua` from a pinned GitHub commit.
- It checks that the response is a complete Mystics RL Crate module, compiles it, and then runs it.
- If download or compilation fails, the hub stays open and the button can be retried.

The module pin is stored in `Mystics_Launcher.lua`. Updating the module requires deliberately changing that commit SHA.
