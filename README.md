# Mystics Hub

The current Lumber Tycoon 2 module is **Mystics LT2 v2.24** (compact Blood Red animated UI). The launcher is the entry point and loads that exact module from an immutable GitHub commit when you select **Lumber Tycoon 2**.

## Run Mystics

Execute this launcher command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MysticsALT/temp/main/Mystics_Launcher.lua"))()
```

Then select **Lumber Tycoon 2** in the Mystics Hub. The launcher downloads and runs the pinned LT2 v2.24 module. It includes the Wire Art Studio, with a built-in Mystics cursive sign preset, editable dimensions, an in-world neon preview, preview repositioning, and a separate confirm-to-place step. Wire Art Studio includes a built-in Mystics cursive sign preset, editable dimensions, an in-world neon preview, preview repositioning, and a separate confirm-to-place step. v2.24 is rebuilt from the stable v2.21 module and adds a safe Wire Placement Diagnostics panel. SCAN WIRE SETUP only inspects the ClientPlacedWire remote, Wire template and owned Wire models; it does not send placement requests. The Wire Art Studio and Wire Placement Diagnostics now have their own WIRE ART tab, separate from TOOLS. v2.24 adds local design editing controls: horizontal mirror, vertical flip, undo, redo, and JSON export (copy-to-clipboard when the executor exposes setclipboard). These edits do not place anything in-game. The launcher is temporarily pinned to the previously confirmed-loading v2.24 module. The newer v2.26/v2.27 wire placement experiments are not loaded while their GUI crash is investigated. v2.24 retains the dedicated Wire Art tab and read-only Wire Placement Diagnostics; it does not include the experimental placement test. The tab includes the Mystics cursive preset, custom JSON path input, adjustable dimensions, local neon preview, clear/update controls, validation, existing placement controls, and a read-only scan of the LT2 wire remote, Purchasables/WireObjects/Wire.OtherInfo metadata path, discovered WireObjects children, and owned Wire models. Custom JSON stroke paths are also supported. Stand facing the wall where you want the art, and make sure enough Wire items are available in your inventory. It does not run an older embedded copy.

## Current files

- `Mystics_Launcher.lua` — Mystics Hub entry point and on-demand module loader.
- `LT2.lua` — Lumber Tycoon 2 module, v2.24.
- `RLCrate.lua` — separate RL Crate experience module.
- `backups/` — retained backups.

## Version / loading notes

- The launcher pins the LT2 module to commit `c48ecd39a94f5e4f03a9f8ff2c36341592761a79`.
- The launcher checks for the `V2.24 | Self-contained` module marker before executing.
- To update the LT2 experience, update `LT2.lua`, then update the pinned commit and version marker in `Mystics_Launcher.lua`.


## Experimental Wire Art placement lab

- `WireArtPlacementLab.lua` is a separate, opt-in experiment and is not loaded by `Mystics_Launcher.lua`.
- Execute it manually only in Lumber Tycoon 2. It opens a small panel and does nothing until PLACE ONE TEST WIRE is clicked.
- The test checks for an owned plot, the recursively located `Purchasables` Wire template, `PlaceStructure.ClientPlacedWire`, and one owned purchased Wire model in `Workspace.PlayerModels`.
- On click it sends at most one short two-point request using the public LT2 five-argument `ClientPlacedWire:FireServer(template, points, player, purchasedWire, true)` pattern. The test wire may remain on the plot.
- This is an experimental compatibility probe, not a confirmed fix. The main launcher remains pinned to the previously confirmed-loading v2.24 module; this lab must not be added to the launcher until separately tested.
