# Mystics Hub

The current Lumber Tycoon 2 module is **Mystics LT2 v2.33** (compact Blood Red animated UI). The launcher is the entry point and loads that exact module from an immutable GitHub commit when you select **Lumber Tycoon 2**.

## Run Mystics

Execute this launcher command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MysticsALT/temp/main/Mystics_Launcher.lua"))()
```

Then select **Lumber Tycoon 2** in the Mystics Hub. The launcher downloads and runs the pinned LT2 v2.33 module. It includes the Wire Art Studio, with a built-in Mystics cursive sign preset, editable dimensions, an in-world neon preview, preview repositioning, and a separate confirm-to-place step. Wire Art Studio includes a built-in Mystics cursive sign preset, editable dimensions, an in-world neon preview, preview repositioning, and a separate confirm-to-place step. v2.33 is rebuilt from the stable v2.21 module and adds a safe Wire Placement Diagnostics panel. SCAN WIRE SETUP only inspects the ClientPlacedWire remote, Wire template and owned Wire models; it does not send placement requests. The Wire Art Studio and Wire Placement Diagnostics now have their own WIRE ART tab, separate from TOOLS. v2.33 adds local design editing controls: horizontal mirror, vertical flip, undo, redo, and JSON export (copy-to-clipboard when the executor exposes setclipboard). These edits do not place anything in-game. The launcher is temporarily pinned to the previously confirmed-loading v2.33 module. The newer v2.33/v2.33 wire placement experiments are not loaded while their GUI crash is investigated. v2.33 retains the dedicated Wire Art tab and read-only Wire Placement Diagnostics; it does not include the experimental placement test. The tab includes the Mystics cursive preset, custom JSON path input, adjustable dimensions, local neon preview, clear/update controls, validation, existing placement controls, and a read-only scan of the LT2 wire remote, Purchasables/WireObjects/Wire.OtherInfo metadata path, discovered WireObjects children, and owned Wire models. Custom JSON stroke paths are also supported. Stand facing the wall where you want the art, and make sure enough Wire items are available in your inventory. It does not run an older embedded copy.

## Current files

- `Mystics_Launcher.lua` — Mystics Hub entry point and on-demand module loader.
- `LT2.lua` — Lumber Tycoon 2 module, v2.33.
- `RLCrate.lua` — separate RL Crate experience module.
- `backups/` — retained backups.

## Version / loading notes

- The launcher pins the LT2 module to commit `2436f0dbf16ef29672493fdc8587969dd2a5051a`.
- The launcher checks for the `V2.33 | Self-contained` module marker before executing.
- To update the LT2 experience, update `LT2.lua`, then update the pinned commit and version marker in `Mystics_Launcher.lua`.


## Experimental Wire Art placement lab

- `WireArtPlacementLab.lua` is a separate, opt-in experiment and is not loaded by `Mystics_Launcher.lua`.
- Execute it manually only in Lumber Tycoon 2. It opens a small panel and does nothing until PLACE ONE TEST WIRE is clicked.
- The test checks for an owned plot, the recursively located `Purchasables` Wire template, `PlaceStructure.ClientPlacedWire`, and one owned purchased Wire model in `Workspace.PlayerModels`.
- On click it sends at most one short two-point request using the public LT2 five-argument `ClientPlacedWire:FireServer(template, points, player, purchasedWire, true)` pattern. The test wire may remain on the plot.
- This is an experimental compatibility probe, not a confirmed fix. The main launcher remains pinned to the previously confirmed-loading v2.33 module; this lab must not be added to the launcher until separately tested.


v2.33 adds a read-only SCAN REPLICATED STORAGE button to the main WIRE ART tab. It lists ReplicatedStorage's top-level children and paths for descendants named Purchasables, WireObjects, Wire, or OtherInfo. It sends no placement requests. The launcher remains based on the previously confirmed-loading v2.33 module, with only this read-only scan added.


Temporary stability note: the launcher is rolled back to the confirmed-loading v2.33 module while the v2.33 load error is investigated. The ReplicatedStorage scan remains in the newer LT2.lua revision but is not active through the launcher.


## v2.33 — Wire item inspection

- Adds **INSPECT CLIENT ITEM INFO** to the WIRE ART tab.
- Read-only inspection targets the observed `ReplicatedStorage.ClientItemInfo.Wire` path and reports its direct children, nested descendants, and `OtherInfo` value fields.
- Also lists other replicated Wire-named objects and Wire-like models under `Workspace.PlayerModels`, including ownership information.
- The inspector does not fire remotes, move objects, or consume inventory.
- The launcher is pinned to the v2.33 LT2 commit and checks the v2.33 module marker.
- This is a diagnostic update only; it does not claim to fix live wire placement.


## v2.33 — Expanded Wire inspector output

- Increases the Client Item Info / Wire Inspector results panel height so the complete read-only diagnostic, including Wire-like PlayerModels and ownership information, is visible.
- No placement behavior or remote calls changed.
- Launcher pinned to LT2 commit `07d6f5c091acd358a2d187855c167b37181e04d9`.


## v2.33 — Visible build version alignment

- Updates the module header, UI header, footer, and startup notification to display v2.33 consistently.
- Retains the expanded read-only Wire inspector.
- Launcher pinned to LT2 commit `c5eb81e12a71175b8fd3cfae3602ae46b5332c56`.
- No wire placement behavior changed.


## v2.33 — Prioritized placed Wire model diagnostics

- The Wire inspector now reports Workspace.PlayerModels and Wire-like placed models before optional replicated Wire-named objects.
- Searches model descendants for ItemName, PurchasedBoxItemName, Type, and Owner values.
- Reports model class, owner, item identifiers, and BasePart count.
- Keeps output compact so the important PlayerModels results are not pushed below a long metadata listing.
- Read-only only; no remote requests or inventory changes.
- Launcher pinned to LT2 commit `e2a386b908a699e16e0f0d97e4d38ea9f8f03def`.


## v2.33 — Wire ownership and remote diagnostics

- Reports local player name and UserId alongside each Wire-like model.
- Shows Owner value class and whether its value matches the local Player instance, username, or UserId.
- Reports the classes of ClientPlacedWire and ClientPlacedWireServerServer.
- Read-only diagnostic update; placement code remains unchanged pending confirmation of the ownership representation and server expectations.
- Launcher pinned to LT2 commit `2fc1fc610c2e9f30a00dcecd0aee4b09145bc08d`.


## v2.33 — Complete Wire ownership counts

- Scans all up to 2,000 top-level PlayerModels items instead of stopping after the first eight Wire-like models.
- Counts Wire-like models owned by the local player and groups all detected models by Owner value.
- Sorts locally owned matches first and displays up to ten model details.
- Read-only diagnostics only; no placement remote is invoked and no inventory is changed.
- Launcher pinned to LT2 commit `c21815be14208d3e12ef0946f1663efb58ade4af`.


## v2.33 — Local plot / Wire spatial diagnostics

- Uses the existing local plot ownership helper to locate the player's plot.
- Reads the plot's OriginSquare and compares it with detected Wire model pivots.
- Reports the nearest detected Wire models and their distance from the plot origin.
- This is read-only diagnostics: it does not call placement remotes or modify inventory.
- Launcher pinned to LT2 commit `3a9e174b1af115d3b80a83e3730ee2ca497a1ef9`.


## Launcher download reliability fix

- The launcher now tries the immutable v2.33 commit URL first, then the GitHub main-branch raw URL, then jsDelivr.
- Each response is validated for source length, the LT2 module marker, and the v2.33 marker before compilation.
- If all sources fail, the console error lists the attempted URLs and response previews.


## v2.33 — Local plot proximity Wire scan

- Adds a separate **SCAN NEAR MY PLOT** diagnostic in the WIRE ART tab.
- Finds the local plot using the existing plot ownership helper and reads its OriginSquare.
- Scans up to 12,000 Workspace descendants for nearby Models with Wire identity metadata or End1/End2/Line structure.
- Reports matching model paths, distance from the local plot origin, owner value, and detection reason for matches within 120 studs.
- Read-only: no remotes, placement requests, inventory changes, or object modifications.
- Launcher pinned to LT2 commit `0dd36cf4ac11e9a290b272da31df01558221eeaf`.


## v2.33 — Targeted local Wire scan

- Replaces the truncated first-12,000-Workspace-descendants traversal with direct scans of PlayerModels and the local plot.
- Checks nested Models under PlayerModels and descendants of the local plot.
- Reports scan counts, wire-identity matches, End1/End2/Line structures, nearby model paths, owner values, and item metadata.
- Read-only; no remotes or inventory changes.
- Launcher pinned to LT2 commit `4f844b728df72684d973648da4fcbf72a35221d4`.
