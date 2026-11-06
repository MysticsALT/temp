# Mystics Hub

The current Lumber Tycoon 2 module is **Mystics LT2 v2.22** (compact Blood Red animated UI). The launcher is the entry point and loads that exact module from an immutable GitHub commit when you select **Lumber Tycoon 2**.

## Run Mystics

Execute this launcher command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MysticsALT/temp/main/Mystics_Launcher.lua"))()
```

Then select **Lumber Tycoon 2** in the Mystics Hub. The launcher downloads and runs the pinned LT2 v2.22 module. It includes the Wire Art Studio, with a built-in Mystics cursive sign preset, editable dimensions, an in-world neon preview, preview repositioning, and a separate confirm-to-place step. Wire Art Studio includes a built-in Mystics cursive sign preset, editable dimensions, an in-world neon preview, preview repositioning, and a separate confirm-to-place step. v2.22 is rebuilt from the stable v2.21 module and adds a safe Wire Placement Diagnostics panel. SCAN WIRE SETUP only inspects the ClientPlacedWire remote, Wire template and owned Wire models; it does not send placement requests. The experimental placement tester is intentionally not included yet. Custom JSON stroke paths are also supported. Stand facing the wall where you want the art, and make sure enough Wire items are available in your inventory. It does not run an older embedded copy.

## Current files

- `Mystics_Launcher.lua` — Mystics Hub entry point and on-demand module loader.
- `LT2.lua` — Lumber Tycoon 2 module, v2.22.
- `RLCrate.lua` — separate RL Crate experience module.
- `backups/` — retained backups.

## Version / loading notes

- The launcher pins the LT2 module to commit `400e533ff9b08849cac976192dc4bf0bdbbd8424`.
- The launcher checks for the `V2.22 | Self-contained` module marker before executing.
- To update the LT2 experience, update `LT2.lua`, then update the pinned commit and version marker in `Mystics_Launcher.lua`.
