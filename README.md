# ForeverCalc

**ForeverCalc** (`v1.2.1`) is a World of Warcraft Classic / Forever addon for **Tank · DPS · Caster** role stat analysis, priority panes, item tooltips, and character-pane breakdowns.

## Features

- **Role & Priority Panes** (`Stats.lua`, `Data.lua`): Supports Tank, DPS, and Caster calculations, including a dedicated Threat-per-Rage (Bear / Warrior) and Threat-per-Mana (Paladin / Shaman) priority pane.
- **Character Pane Integration** (`CharacterPane.lua`): Displays detailed stat breakdowns directly alongside the character frame.
- **Item Tooltips** (`Tooltips.lua`): Adds stat and priority evaluations to item tooltips.
- **Minimap Button & Custom Artwork** (`Minimap.lua`, `DwarfCrown.tga`, `ForeverStatsIcon.tga`): Includes a Dwarven King's Crown minimap icon and a dedicated AddOns-list icon (`## IconTexture: Interface\AddOns\ForeverCalc\ForeverStatsIcon`).

## Files

- `ForeverCalc.toc` — Addon manifest (`Interface: 11504, 11505, 11506, 11507, 11508, 11509, 16000, 16001`)
- `Data.lua`, `Stats.lua`, `Tooltips.lua`, `CharacterPane.lua`, `Minimap.lua` — Core addon modules
- `DwarfCrown.tga`, `ForeverStatsIcon.tga` — In-game icons
- `ForeverStats_CurseForgeLogo.png` — CurseForge project logo (excluded from game deployment via `.curseignore`)
- `deploy.ps1` & `wow_paths.json` — Local deployment script and WoW `AddOns` path configuration

## Local Deployment

1. Edit `wow_paths.json` to point `wowAddonPath` to your World of Warcraft `Interface\AddOns` directory (if different from the default).
2. Run the deployment script from PowerShell:

```powershell
.\deploy.ps1
```

`deploy.ps1` reads `.gitignore` and `.curseignore` so development files (`wow_paths.json`, `.curseignore`, `deploy.ps1`, etc.) are not copied into your live `AddOns\ForeverCalc` folder.
