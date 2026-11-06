# Mystics Hub

The current Lumber Tycoon 2 module is **Mystics LT2 v2.23** (compact Blood Red animated UI). The launcher is the entry point and loads that exact module from an immutable GitHub commit when you select **Lumber Tycoon 2**.

## Run Mystics

Execute this launcher command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MysticsALT/temp/main/Mystics_Launcher.lua"))()
```

Then select **Lumber Tycoon 2** in the Mystics Hub. The launcher downloads and runs the pinned LT2 v2.23 module. It includes the Wire Art Studio, with a built-in Mystics cursive sign preset, editable dimensions, an in-world neon preview, preview repositioning, and a separate confirm-to-place step. Wire Art Studio includes a built-in Mystics cursive sign preset, editable dimensions, an in-world neon preview, preview repositioning, and a separate confirm-to-place step. v2.23 is rebuilt from the stable v2.21 module and adds a safe Wire Placement Diagnostics panel. SCAN WIRE SETUP only inspects the ClientPlacedWire remote, Wire template and owned Wire models; it does not send placement requests. The Wire Art Studio and Wire Placement Diagnostics now have their own WIRE ART tab, separate from TOOLS. The tab includes the Mystics cursive preset, custom JSON path input, adjustable dimensions, local neon preview, clear/update controls, validation, existing placement controls, and a read-only scan of the LT2 wire remote/template/owned Wire models. Custom JSON stroke paths are also supported. Stand facing the wall where you want the art, and make sure enough Wire items are available in your inventory. It does not run an older embedded copy.

## Current files

- `Mystics_Launcher.lua` — Mystics Hub entry point and on-demand module loader.
- `LT2.lua` — Lumber Tycoon 2 module, v2.23.
- `RLCrate.lua` — separate RL Crate experience module.
- `backups/` — retained backups.

## Version / loading notes

- The launcher pins the LT2 module to commit `f76789f2ca866f3998529e558c1c00e0b6134555`.
- The launcher checks for the `V2.23 | Self-contained` module marker before executing.
- To update the LT2 experience, update `LT2.lua`, then update the pinned commit and version marker in `Mystics_Launcher.lua`.
