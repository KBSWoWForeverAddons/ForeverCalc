# Changelog

## [v1.4.0] - 2026-11-25

### Added
- **Paladin Seals, Judgement & Holy Wrath**: Added **Seal of Fury** (with 50% shield absorb and 3s taunt Judgement), **Seal of Righteousness** (Ranks 1–8), **Seal of Command** (Ranks 1–5), **Judgement**, **Holy Wrath**, and the **Improved Seal of Righteousness** talent to both Top 7 DPM and Top 5 TPM priority lists and spell tooltips.
- **Weapon Enchant DPS & TPS Tracking**: Detects equipped main-hand and off-hand weapon enchants (**Fiery Weapon**, **Lifestealing**, **Crusader**, and flat **+Weapon Damage** enchants), displaying proc DPS/TPS in the Character Sheet **Weapon Damage** tooltip and factoring enchant proc DPS into weapon upgrade comparisons.
- **Dynamic Spell Rank & Righteous Fury Scaling**: Automatically reads live spell descriptions so higher ranks of **Seal of Fury**, **Seal of Righteousness**, and **Righteous Fury** scale accurately without hardcoded caps, and displays live **Righteous Fury Threat & TPM** on Paladin Holy spell tooltips.

### Fixed
- **All-Class Top 5 Threat Lists**: Fixed non-tank classes (**Hunter**, **Warlock**, **Mage**, **Priest**, **Rogue**, and **Cat/Caster Druid**) showing blank Threat windows by computing class-appropriate `TPM`/`TPE` (including `2x` threat for *Searing Pain* and `0.71x` for Rogue/Cat Form).
- **Righteous Fury Aura Detection**: Added `GetAuraDataByIndex` and `UnitBuff` fallbacks so the `[RF]` state and threat multipliers update reliably whenever Righteous Fury is active.

## [v1.3.1] - 2026-11-24

### Added
- **Expanded Pet Threat Talents & Skills**: Added Hunter and Warlock pet threat talents (*Intimidation*, *Bestial Discipline*, *Improved Voidwalker*, *Improved Firebolt*, and *Improved Lash of Pain*) and active pet action-bar abilities (*Suffering*, *Thunderstomp*, *Screech*, *Lightning Breath*, *Bite*, *Claw*, *Firebolt*, and *Lash of Pain*) with a new **Bonus Threat** breakdown row and autocast-off warning for *Growl* / *Torment*.

### Changed
- **Equal-Level & +3 Boss Pet Threat Rows**: Split Pet Threat into two clear rows — `Threat (Lvl X)` for equal-level targets and `Threat (Lvl X+3 Boss)` for `+3` bosses — and updated `Melee White DPS` to show equal-level, raw, and `+3` boss values cleanly.

## [v1.3.0] - 2026-11-24

### Added
- **Pet Mitigation & Threat Pane (Hunters & Warlocks)**: Added a separate movable **Pet Stats** window showing live pet Health, Armor, dynamic equal-level and `+3` boss Damage Reduction & Effective Health, Miss/Dodge Avoidance, Melee Damage/AP, post-armor Boss White DPS, and pet threat abilities (*Growl*, *Torment*, *Suffering*, *Anguish*) with estimated sustained TPS.
- **Quick Access & Options**: Added a **Pet** toggle button to the top-left of the main Character Sheet stats pane (for Hunters and Warlocks), a **Pet Mitigation & Threat Pane** checkbox and position reset in the Options menu, and the `/fs pet` slash command.

## [v1.2.2] - 2026-11-21

### Added
- **Talent Hit Tracking**: Added class hit talents (*Precision*, *Nature's Guidance*, *Surefooted*, *Elemental Precision*, *Arcane Focus*, *Suppression*, *Shadow Focus*, and *Balance of Power*) to melee, ranged, and spell hit & hit-cap calculations, along with a **From Talents** breakdown in the hit tooltip.

### Fixed
- **Shaman Parry**: Enabled Parry tracking and tooltip display for Shamans, and updated the non-parry tooltip message for other classes that cannot parry.

## [v1.2.1] - 2026-11-19

### Added
- Extended gear upgrade tooltip previews to all armor and accessory slots, allowing you to compare stat and priority changes directly on item tooltips across every equipment slot.
