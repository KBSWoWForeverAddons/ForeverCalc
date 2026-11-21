local addonName, FeralCalc = ...
_G.FeralCalc = FeralCalc
_G.ForeverTank = FeralCalc

-- ============================================================================
-- CONSTANTS & BOSS DEFAULTS
-- ============================================================================
FeralCalc.Constants = {
    BOSS_LEVEL = 63,
    BOSS_DEFENSE = 315,
    BOSS_ARMOR = 3731,        -- Standard Level 63 Classic Raid Boss Armor
    EQUAL_LEVEL = 60,
    EQUAL_DEFENSE = 300,
    ARMOR_CAP_PCT = 0.75,
    ARMOR_CAP_60 = 16500,     -- 75% DR vs Level 60
    ARMOR_CAP_63 = 17265,     -- 75% DR vs Level 63 Raid Boss
    CRIT_IMMUNE_DEF = 440,    -- 300 base + 140 defense skill for 5.6% crit reduction
    BASE_BOSS_CRIT = 5.0,
    BASE_BOSS_MISS = 5.0,
    BASE_BOSS_CRUSH = 15.0,
    AVOIDANCE_CRUSH_CAP = 102.4,
    BEAR_SPEED = 2.5,
    CAT_SPEED = 1.0,
}

-- ============================================================================
-- TALENT NAMES (Scanned dynamically by name via GetTalentInfo / C_Traits)
-- ============================================================================
FeralCalc.TrackedTalentNames = {
    -- Druid Talents
    ["Savage Fury"]             = "savageFury",        -- +10%/20% Claw, Rake, Maul, Swipe, Primal Bite
    ["Naturalist"]              = "naturalist",        -- +2%/4%/6%/8%/10% physical damage (WoW: Forever / TBC name)
    ["Natural Weapons"]         = "naturalWeapons",    -- +2%/4%/6%/8%/10% physical damage (Classic Era name)
    ["Feral Aggression"]        = "feralAggression",   -- +3%/6%/9%/12%/15% Ferocious Bite damage
    ["Ferocity"]                = "ferocity",          -- -1/-2/-3/-4/-5 Rage/Energy cost on Maul, Swipe, Claw, Rake, Primal Bite
    ["Improved Shred"]          = "improvedShred",     -- -6/-12 Energy cost on Shred
    ["Sharpened Claws"]         = "sharpenedClaws",    -- +2%/4%/6% Crit in Bear/Cat Form
    ["Predatory Strikes"]       = "predatoryStrikes",  -- +50%/100%/150% of level as AP in Bear/Cat Form
    ["Thick Hide"]              = "thickHide",         -- +2%/4%/6%/8%/10% Armor from items
    ["Heart of the Wild"]       = "heartOfTheWild",    -- +4%/8%/12%/16%/20% Stamina in Bear, AP/Str in Cat
    ["Survival of the Fittest"] = "survivalOfFittest", -- -1%/2%/3% crit taken
    ["Feral Instinct"]          = "feralInstinct",     -- +3%/6%/9%/12%/15% Bear Form threat

    -- Warrior Talents
    ["One-Handed Weapon Specialization"] = "oneHandSpec", -- +2%/4%/6%/8%/10% 1H physical damage
    ["Improved Heroic Strike"]  = "impHeroicStrike",   -- -1/-2/-3 Rage cost on Heroic Strike
    ["Improved Thunder Clap"]   = "impThunderClap",    -- -1/-2/-4 Rage cost on Thunder Clap
    ["Improved Sunder Armor"]   = "impSunderArmor",    -- -1/-2/-3 Rage cost on Sunder Armor
    ["Defiance"]                = "defiance",          -- +3%/6%/9%/12%/15% Defensive Stance threat
    ["Anticipation"]            = "anticipation",      -- Defense skill
    ["Toughness"]               = "toughness",         -- Armor from items
    ["Shield Specialization"]   = "shieldSpec",        -- Block %

    -- Paladin Talents
    ["Improved Righteous Fury"] = "impRighteousFury",  -- +16%/33%/50% Righteous Fury threat bonus
    ["Redoubt"]                 = "redoubt",
    ["Precision"]               = "precision",         -- +1%/rank Melee Hit (Rogue) or Melee & Spell Hit (Paladin)

    -- Shaman, Hunter & Caster Hit Talents
    ["Nature's Guidance"]       = "naturesGuidance",   -- +1%/2%/3% Melee & Spell Hit (Shaman)
    ["Surefooted"]              = "surefooted",        -- +1%/2%/3% Melee & Ranged Hit (Hunter)
    ["Elemental Precision"]     = "elementalPrecision",-- +2%/4%/6% Frost/Fire/Ele Spell Hit (Mage/Shaman)
    ["Arcane Focus"]            = "arcaneFocus",       -- +2%/4%/6%/8%/10% Arcane Spell Hit (Mage)
    ["Suppression"]             = "suppression",       -- +2%/4%/6%/8%/10% Affliction Spell Hit (Warlock)
    ["Shadow Focus"]            = "shadowFocus",       -- +2%/4%/6%/8%/10% Shadow Spell Hit (Priest)
    ["Balance of Power"]        = "balanceOfPower",    -- +2%/4% Spell Hit (Druid)
}

-- ============================================================================
-- SPELL DATABASE (Druid Bear/Cat + Warrior & Paladin Tank Abilities)
-- ============================================================================
FeralCalc.SpellData = {
    -- =========================================================================
    -- DRUID: CAT FORM ABILITIES
    -- =========================================================================

    -- CLAW: (Weapon Damage + flatBonus) * TalentMods
    [1082] = { name = "Claw", rank = 1, type = "cat_strike", flatBonus = 8,   baseCost = 45, powerType = "ENERGY", costTalent = "ferocity" },
    [3029] = { name = "Claw", rank = 2, type = "cat_strike", flatBonus = 13,  baseCost = 45, powerType = "ENERGY", costTalent = "ferocity" },
    [5201] = { name = "Claw", rank = 3, type = "cat_strike", flatBonus = 26,  baseCost = 45, powerType = "ENERGY", costTalent = "ferocity" },
    [9849] = { name = "Claw", rank = 4, type = "cat_strike", flatBonus = 58,  baseCost = 45, powerType = "ENERGY", costTalent = "ferocity" },
    [9850] = { name = "Claw", rank = 5, type = "cat_strike", flatBonus = 115, baseCost = 45, powerType = "ENERGY", costTalent = "ferocity" },

    -- SHRED: ((Weapon Damage * 2.25) + flatBonus) * TalentMods
    [5221] = { name = "Shred", rank = 1, type = "cat_shred", mult = 2.25, flatBonus = 54,  baseCost = 60, powerType = "ENERGY", costTalent = "improvedShred" },
    [6800] = { name = "Shred", rank = 2, type = "cat_shred", mult = 2.25, flatBonus = 72,  baseCost = 60, powerType = "ENERGY", costTalent = "improvedShred" },
    [8992] = { name = "Shred", rank = 3, type = "cat_shred", mult = 2.25, flatBonus = 99,  baseCost = 60, powerType = "ENERGY", costTalent = "improvedShred" },
    [9829] = { name = "Shred", rank = 4, type = "cat_shred", mult = 2.25, flatBonus = 144, baseCost = 60, powerType = "ENERGY", costTalent = "improvedShred" },
    [9830] = { name = "Shred", rank = 5, type = "cat_shred", mult = 2.25, flatBonus = 180, baseCost = 60, powerType = "ENERGY", costTalent = "improvedShred" },

    -- RAVAGE: ((Weapon Damage * 3.50) + flatBonus) * TalentMods (60 Energy)
    [6785]  = { name = "Ravage", rank = 1, type = "cat_shred", mult = 3.50, flatBonus = 147, baseCost = 60, powerType = "ENERGY" },
    [6787]  = { name = "Ravage", rank = 2, type = "cat_shred", mult = 3.50, flatBonus = 217, baseCost = 60, powerType = "ENERGY" },
    [9866]  = { name = "Ravage", rank = 3, type = "cat_shred", mult = 3.50, flatBonus = 291, baseCost = 60, powerType = "ENERGY" },
    [9867]  = { name = "Ravage", rank = 4, type = "cat_shred", mult = 3.50, flatBonus = 385, baseCost = 60, powerType = "ENERGY" },
    [27005] = { name = "Ravage", rank = 5, type = "cat_shred", mult = 3.50, flatBonus = 514, baseCost = 60, powerType = "ENERGY" },

    -- POUNCE: Bleed over 18s / 6 ticks (baseBleed + 0.18 * AP) (50 Energy)
    [9005]  = { name = "Pounce", rank = 1, type = "cat_pounce", baseBleed = 270, bleedAP = 0.18, ticks = 6, duration = 18, baseCost = 50, powerType = "ENERGY" },
    [9823]  = { name = "Pounce", rank = 2, type = "cat_pounce", baseBleed = 330, bleedAP = 0.18, ticks = 6, duration = 18, baseCost = 50, powerType = "ENERGY" },
    [9827]  = { name = "Pounce", rank = 3, type = "cat_pounce", baseBleed = 450, bleedAP = 0.18, ticks = 6, duration = 18, baseCost = 50, powerType = "ENERGY" },
    [27006] = { name = "Pounce", rank = 4, type = "cat_pounce", baseBleed = 600, bleedAP = 0.18, ticks = 6, duration = 18, baseCost = 50, powerType = "ENERGY" },

    -- RAKE: Direct Hit (baseDirect + 0.01 * AP) + Bleed over 9s / 3 ticks (baseBleed + 0.06 * AP)
    [1822] = { name = "Rake", rank = 1, type = "cat_rake", baseDirect = 17, directAP = 0.01, baseBleed = 30, bleedAP = 0.06, ticks = 3, duration = 9, baseCost = 40, powerType = "ENERGY", costTalent = "ferocity" },
    [1823] = { name = "Rake", rank = 2, type = "cat_rake", baseDirect = 26, directAP = 0.01, baseBleed = 45, bleedAP = 0.06, ticks = 3, duration = 9, baseCost = 40, powerType = "ENERGY", costTalent = "ferocity" },
    [1824] = { name = "Rake", rank = 3, type = "cat_rake", baseDirect = 46, directAP = 0.01, baseBleed = 75, bleedAP = 0.06, ticks = 3, duration = 9, baseCost = 40, powerType = "ENERGY", costTalent = "ferocity" },
    [9904] = { name = "Rake", rank = 4, type = "cat_rake", baseDirect = 61, directAP = 0.01, baseBleed = 96, bleedAP = 0.06, ticks = 3, duration = 9, baseCost = 40, powerType = "ENERGY", costTalent = "ferocity" },

    -- RIP: Bleed over 12s (6 ticks every 2s). Scales per Combo Point (1-5) + AP
    [1079] = {
        name = "Rip", rank = 1, type = "cat_rip", ticks = 6, duration = 12,
        baseTick = 4, cpTickBonus = 3, baseCost = 30, powerType = "ENERGY",
        apRatio = { [1] = 0.04, [2] = 0.08, [3] = 0.12, [4] = 0.16, [5] = 0.20 }
    },
    [9492] = {
        name = "Rip", rank = 2, type = "cat_rip", ticks = 6, duration = 12,
        baseTick = 7, cpTickBonus = 5, baseCost = 30, powerType = "ENERGY",
        apRatio = { [1] = 0.04, [2] = 0.08, [3] = 0.12, [4] = 0.16, [5] = 0.20 }
    },
    [9493] = {
        name = "Rip", rank = 3, type = "cat_rip", ticks = 6, duration = 12,
        baseTick = 11, cpTickBonus = 8, baseCost = 30, powerType = "ENERGY",
        apRatio = { [1] = 0.04, [2] = 0.08, [3] = 0.12, [4] = 0.16, [5] = 0.20 }
    },
    [9752] = {
        name = "Rip", rank = 4, type = "cat_rip", ticks = 6, duration = 12,
        baseTick = 16, cpTickBonus = 12, baseCost = 30, powerType = "ENERGY",
        apRatio = { [1] = 0.04, [2] = 0.08, [3] = 0.12, [4] = 0.16, [5] = 0.20 }
    },
    [9894] = {
        name = "Rip", rank = 5, type = "cat_rip", ticks = 6, duration = 12,
        baseTick = 22, cpTickBonus = 16, baseCost = 30, powerType = "ENERGY",
        apRatio = { [1] = 0.04, [2] = 0.08, [3] = 0.12, [4] = 0.16, [5] = 0.20 }
    },
    [9896] = {
        name = "Rip", rank = 6, type = "cat_rip", ticks = 6, duration = 12,
        baseTick = 29, cpTickBonus = 21, baseCost = 30, powerType = "ENERGY",
        apRatio = { [1] = 0.04, [2] = 0.08, [3] = 0.12, [4] = 0.16, [5] = 0.20 }
    },

    -- FEROCIOUS BITE: minBase to maxBase + (perCP * CP) + (0.15 * totalAP) + (extraEnergy * energyMod)
    [22568] = { name = "Ferocious Bite", rank = 1, type = "cat_fb", minBase = 50,  maxBase = 66,  perCP = 36,  apRatio = 0.15, energyMod = 1.0, baseCost = 35, powerType = "ENERGY" },
    [22827] = { name = "Ferocious Bite", rank = 2, type = "cat_fb", minBase = 79,  maxBase = 103, perCP = 59,  apRatio = 0.15, energyMod = 1.5, baseCost = 35, powerType = "ENERGY" },
    [22828] = { name = "Ferocious Bite", rank = 3, type = "cat_fb", minBase = 122, maxBase = 162, perCP = 92,  apRatio = 0.15, energyMod = 2.0, baseCost = 35, powerType = "ENERGY" },
    [22829] = { name = "Ferocious Bite", rank = 4, type = "cat_fb", minBase = 173, maxBase = 223, perCP = 128, apRatio = 0.15, energyMod = 2.5, baseCost = 35, powerType = "ENERGY" },
    [31018] = { name = "Ferocious Bite", rank = 5, type = "cat_fb", minBase = 199, maxBase = 259, perCP = 147, apRatio = 0.15, energyMod = 2.7, baseCost = 35, powerType = "ENERGY" },

    -- =========================================================================
    -- DRUID: BEAR / DIRE BEAR FORM ABILITIES
    -- =========================================================================

    -- MAUL: (Weapon Damage + flatBonus) * TalentMods
    [6807] = { name = "Maul", rank = 1, type = "bear_strike", flatBonus = 18,  baseCost = 15, powerType = "RAGE", costTalent = "ferocity" },
    [6808] = { name = "Maul", rank = 2, type = "bear_strike", flatBonus = 27,  baseCost = 15, powerType = "RAGE", costTalent = "ferocity" },
    [6809] = { name = "Maul", rank = 3, type = "bear_strike", flatBonus = 37,  baseCost = 15, powerType = "RAGE", costTalent = "ferocity" },
    [8972] = { name = "Maul", rank = 4, type = "bear_strike", flatBonus = 49,  baseCost = 15, powerType = "RAGE", costTalent = "ferocity" },
    [9745] = { name = "Maul", rank = 5, type = "bear_strike", flatBonus = 71,  baseCost = 15, powerType = "RAGE", costTalent = "ferocity" },
    [9880] = { name = "Maul", rank = 6, type = "bear_strike", flatBonus = 101, baseCost = 15, powerType = "RAGE", costTalent = "ferocity" },
    [9881] = { name = "Maul", rank = 7, type = "bear_strike", flatBonus = 128, baseCost = 15, powerType = "RAGE", costTalent = "ferocity" },

    -- PRIMAL BITE (WoW: Forever Mangle): (Weapon Damage + flatBonus) * TalentMods
    [33878] = { name = "Primal Bite", rank = 1, type = "bear_strike", flatBonus = 26, baseCost = 20, powerType = "RAGE", costTalent = "ferocity" },
    [33986] = { name = "Primal Bite", rank = 2, type = "bear_strike", flatBonus = 42, baseCost = 20, powerType = "RAGE", costTalent = "ferocity" },
    [33987] = { name = "Primal Bite", rank = 3, type = "bear_strike", flatBonus = 77, baseCost = 20, powerType = "RAGE", costTalent = "ferocity" },

    -- SWIPE: (baseDmg + 0.03 * totalAP) * TalentMods (up to 3 targets)
    [779]  = { name = "Swipe", rank = 1, type = "bear_swipe", baseDmg = 18, apRatio = 0.03, targets = 3, baseCost = 20, powerType = "RAGE", costTalent = "ferocity" },
    [780]  = { name = "Swipe", rank = 2, type = "bear_swipe", baseDmg = 25, apRatio = 0.03, targets = 3, baseCost = 20, powerType = "RAGE", costTalent = "ferocity" },
    [769]  = { name = "Swipe", rank = 3, type = "bear_swipe", baseDmg = 36, apRatio = 0.03, targets = 3, baseCost = 20, powerType = "RAGE", costTalent = "ferocity" },
    [9754] = { name = "Swipe", rank = 4, type = "bear_swipe", baseDmg = 60, apRatio = 0.03, targets = 3, baseCost = 20, powerType = "RAGE", costTalent = "ferocity" },
    [9908] = { name = "Swipe", rank = 5, type = "bear_swipe", baseDmg = 83, apRatio = 0.03, targets = 3, baseCost = 20, powerType = "RAGE", costTalent = "ferocity" },

    -- LACERATE: baseBleed (over 15s, 5 ticks) + (0.10 * avgWeaponDmg * existingStacks)
    [33745] = { name = "Lacerate", rank = 1, type = "bear_lacerate", baseBleed = 25, stackWeaponPct = 0.10, ticks = 5, duration = 15, baseCost = 15, powerType = "RAGE" },
    [41464] = { name = "Lacerate", rank = 2, type = "bear_lacerate", baseBleed = 35, stackWeaponPct = 0.10, ticks = 5, duration = 15, baseCost = 15, powerType = "RAGE" },
    [41467] = { name = "Lacerate", rank = 3, type = "bear_lacerate", baseBleed = 50, stackWeaponPct = 0.10, ticks = 5, duration = 15, baseCost = 15, powerType = "RAGE" },

    -- =========================================================================
    -- WARRIOR TANK ABILITIES
    -- =========================================================================

    -- SHIELD SLAM: minBase to maxBase + Shield Block Value
    [23922] = { name = "Shield Slam", rank = 1, type = "war_shield_slam", minBase = 225, maxBase = 235, baseCost = 20, powerType = "RAGE" },
    [23923] = { name = "Shield Slam", rank = 2, type = "war_shield_slam", minBase = 264, maxBase = 276, baseCost = 20, powerType = "RAGE" },
    [23924] = { name = "Shield Slam", rank = 3, type = "war_shield_slam", minBase = 303, maxBase = 317, baseCost = 20, powerType = "RAGE" },
    [23925] = { name = "Shield Slam", rank = 4, type = "war_shield_slam", minBase = 342, maxBase = 358, baseCost = 20, powerType = "RAGE" },

    -- REVENGE: minBase to maxBase
    [6572]  = { name = "Revenge", rank = 1, type = "war_revenge", minBase = 12, maxBase = 14, baseCost = 5, powerType = "RAGE" },
    [6574]  = { name = "Revenge", rank = 2, type = "war_revenge", minBase = 18, maxBase = 22, baseCost = 5, powerType = "RAGE" },
    [7379]  = { name = "Revenge", rank = 3, type = "war_revenge", minBase = 25, maxBase = 31, baseCost = 5, powerType = "RAGE" },
    [11600] = { name = "Revenge", rank = 4, type = "war_revenge", minBase = 43, maxBase = 53, baseCost = 5, powerType = "RAGE" },
    [11601] = { name = "Revenge", rank = 5, type = "war_revenge", minBase = 64, maxBase = 78, baseCost = 5, powerType = "RAGE" },
    [25288] = { name = "Revenge", rank = 6, type = "war_revenge", minBase = 81, maxBase = 99, baseCost = 5, powerType = "RAGE" },

    -- HEROIC STRIKE: Weapon Damage + flatBonus
    [78]    = { name = "Heroic Strike", rank = 1, type = "war_strike", flatBonus = 11,  baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },
    [284]   = { name = "Heroic Strike", rank = 2, type = "war_strike", flatBonus = 21,  baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },
    [285]   = { name = "Heroic Strike", rank = 3, type = "war_strike", flatBonus = 32,  baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },
    [1608]  = { name = "Heroic Strike", rank = 4, type = "war_strike", flatBonus = 44,  baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },
    [11564] = { name = "Heroic Strike", rank = 5, type = "war_strike", flatBonus = 58,  baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },
    [11565] = { name = "Heroic Strike", rank = 6, type = "war_strike", flatBonus = 80,  baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },
    [11566] = { name = "Heroic Strike", rank = 7, type = "war_strike", flatBonus = 111, baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },
    [11567] = { name = "Heroic Strike", rank = 8, type = "war_strike", flatBonus = 138, baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },
    [25286] = { name = "Heroic Strike", rank = 9, type = "war_strike", flatBonus = 157, baseCost = 15, powerType = "RAGE", costTalent = "impHeroicStrike" },

    -- THUNDER CLAP: baseDmg up to 4 targets
    [6343]  = { name = "Thunder Clap", rank = 1, type = "bear_swipe", baseDmg = 10,  apRatio = 0.0, targets = 4, baseCost = 20, powerType = "RAGE", costTalent = "impThunderClap" },
    [8198]  = { name = "Thunder Clap", rank = 2, type = "bear_swipe", baseDmg = 23,  apRatio = 0.0, targets = 4, baseCost = 20, powerType = "RAGE", costTalent = "impThunderClap" },
    [8204]  = { name = "Thunder Clap", rank = 3, type = "bear_swipe", baseDmg = 37,  apRatio = 0.0, targets = 4, baseCost = 20, powerType = "RAGE", costTalent = "impThunderClap" },
    [8205]  = { name = "Thunder Clap", rank = 4, type = "bear_swipe", baseDmg = 55,  apRatio = 0.0, targets = 4, baseCost = 20, powerType = "RAGE", costTalent = "impThunderClap" },
    [11580] = { name = "Thunder Clap", rank = 5, type = "bear_swipe", baseDmg = 82,  apRatio = 0.0, targets = 4, baseCost = 20, powerType = "RAGE", costTalent = "impThunderClap" },
    [11581] = { name = "Thunder Clap", rank = 6, type = "bear_swipe", baseDmg = 103, apRatio = 0.0, targets = 4, baseCost = 20, powerType = "RAGE", costTalent = "impThunderClap" },

    -- CLEAVE: Weapon Damage + flatBonus on up to 2 targets (20 Rage)
    [845]   = { name = "Cleave", rank = 1, type = "war_cleave", flatBonus = 5,  targets = 2, baseCost = 20, powerType = "RAGE" },
    [7369]  = { name = "Cleave", rank = 2, type = "war_cleave", flatBonus = 10, targets = 2, baseCost = 20, powerType = "RAGE" },
    [11608] = { name = "Cleave", rank = 3, type = "war_cleave", flatBonus = 18, targets = 2, baseCost = 20, powerType = "RAGE" },
    [11609] = { name = "Cleave", rank = 4, type = "war_cleave", flatBonus = 32, targets = 2, baseCost = 20, powerType = "RAGE" },
    [20569] = { name = "Cleave", rank = 5, type = "war_cleave", flatBonus = 50, targets = 2, baseCost = 20, powerType = "RAGE" },

    -- SHIELD BLOCK: +75% Block Chance (10 Rage)
    [2565]  = { name = "Shield Block", rank = 1, type = "war_shield_block", bonusBlock = 75, charges = 1, baseCost = 10, powerType = "RAGE" },

    -- =========================================================================
    -- PALADIN TANK ABILITIES
    -- =========================================================================

    -- HOLY SHIELD: +30% Block Chance for 10s (4 charges), deals Holy damage per block
    [20925] = { name = "Holy Shield", rank = 1, type = "pal_holy_shield", baseDmg = 65,  charges = 4, bonusBlock = 30, baseCost = 150, powerType = "MANA" },
    [20927] = { name = "Holy Shield", rank = 2, type = "pal_holy_shield", baseDmg = 95,  charges = 4, bonusBlock = 30, baseCost = 195, powerType = "MANA" },
    [20928] = { name = "Holy Shield", rank = 3, type = "pal_holy_shield", baseDmg = 130, charges = 4, bonusBlock = 30, baseCost = 240, powerType = "MANA" },

    -- CONSECRATION: Holy AoE over 8s (8 ticks)
    [26573] = { name = "Consecration", rank = 1, type = "pal_consecration", baseTotal = 64,  spRatio = 0.33, ticks = 8, duration = 8, baseCost = 135, powerType = "MANA" },
    [20116] = { name = "Consecration", rank = 2, type = "pal_consecration", baseTotal = 120, spRatio = 0.33, ticks = 8, duration = 8, baseCost = 235, powerType = "MANA" },
    [20922] = { name = "Consecration", rank = 3, type = "pal_consecration", baseTotal = 192, spRatio = 0.33, ticks = 8, duration = 8, baseCost = 320, powerType = "MANA" },
    [20923] = { name = "Consecration", rank = 4, type = "pal_consecration", baseTotal = 280, spRatio = 0.33, ticks = 8, duration = 8, baseCost = 435, powerType = "MANA" },
    [20924] = { name = "Consecration", rank = 5, type = "pal_consecration", baseTotal = 384, spRatio = 0.33, ticks = 8, duration = 8, baseCost = 565, powerType = "MANA" },

    -- EXORCISM: Direct Holy damage (minBase to maxBase + 0.43 * SP)
    [879]   = { name = "Exorcism", rank = 1, type = "pal_holy_nuke", minBase = 84,  maxBase = 96,  spRatio = 0.43, baseCost = 85,  powerType = "MANA" },
    [5614]  = { name = "Exorcism", rank = 2, type = "pal_holy_nuke", minBase = 152, maxBase = 172, spRatio = 0.43, baseCost = 135, powerType = "MANA" },
    [5615]  = { name = "Exorcism", rank = 3, type = "pal_holy_nuke", minBase = 217, maxBase = 245, spRatio = 0.43, baseCost = 180, powerType = "MANA" },
    [10312] = { name = "Exorcism", rank = 4, type = "pal_holy_nuke", minBase = 304, maxBase = 342, spRatio = 0.43, baseCost = 235, powerType = "MANA" },
    [10313] = { name = "Exorcism", rank = 5, type = "pal_holy_nuke", minBase = 393, maxBase = 441, spRatio = 0.43, baseCost = 285, powerType = "MANA" },
    [10314] = { name = "Exorcism", rank = 6, type = "pal_holy_nuke", minBase = 505, maxBase = 563, spRatio = 0.43, baseCost = 345, powerType = "MANA" },

    -- HOLY SHOCK: Direct Holy damage (minBase to maxBase + 0.43 * SP)
    [20473] = { name = "Holy Shock", rank = 1, type = "pal_holy_nuke", minBase = 204, maxBase = 220, spRatio = 0.43, baseCost = 225, powerType = "MANA" },
    [20929] = { name = "Holy Shock", rank = 2, type = "pal_holy_nuke", minBase = 279, maxBase = 301, spRatio = 0.43, baseCost = 275, powerType = "MANA" },
    [20930] = { name = "Holy Shock", rank = 3, type = "pal_holy_nuke", minBase = 365, maxBase = 395, spRatio = 0.43, baseCost = 325, powerType = "MANA" },

    -- HAMMER OF WRATH: Direct Holy execute (minBase to maxBase + 0.43 * SP)
    [24275] = { name = "Hammer of Wrath", rank = 1, type = "pal_holy_nuke", minBase = 304, maxBase = 336, spRatio = 0.43, baseCost = 295, powerType = "MANA" },
    [24274] = { name = "Hammer of Wrath", rank = 2, type = "pal_holy_nuke", minBase = 399, maxBase = 441, spRatio = 0.43, baseCost = 360, powerType = "MANA" },
    [24239] = { name = "Hammer of Wrath", rank = 3, type = "pal_holy_nuke", minBase = 504, maxBase = 556, spRatio = 0.43, baseCost = 425, powerType = "MANA" },
}

-- ============================================================================
-- MULTI-CLASS SPELL DATABASE BUILDER (All 9 Classes: All Ranks)
-- ============================================================================
FeralCalc.SpellRanksByName = {}

local function RegisterSpellEntry(spellID, entry)
    if spellID and not FeralCalc.SpellData[spellID] then
        FeralCalc.SpellData[spellID] = entry
    end
    local name = entry.name
    if name then
        FeralCalc.SpellRanksByName[name] = FeralCalc.SpellRanksByName[name] or {}
        FeralCalc.SpellRanksByName[name][entry.rank or 1] = entry
    end
end

for id, entry in pairs(FeralCalc.SpellData) do
    RegisterSpellEntry(id, entry)
end

local function AddRanks(name, spellType, powerType, shared, ranks)
    for rIdx, rData in ipairs(ranks) do
        local entry = {
            name = name,
            rank = rData.rank or rIdx,
            type = spellType,
            powerType = powerType,
        }
        if shared then
            for k, v in pairs(shared) do entry[k] = v end
        end
        for k, v in pairs(rData) do
            if k ~= "id" then entry[k] = v end
        end
        RegisterSpellEntry(rData.id, entry)
    end
end

-- ============================================================================
-- HUNTER ABILITIES (Ranged Shots, Stings & Melee Strikes)
-- ============================================================================
AddRanks("Aimed Shot", "ranged_shot", "MANA", nil, {
    { id = 19434, flatBonus = 70,  baseCost = 75 },
    { id = 20900, flatBonus = 125, baseCost = 115 },
    { id = 20901, flatBonus = 200, baseCost = 160 },
    { id = 20902, flatBonus = 330, baseCost = 210 },
    { id = 20903, flatBonus = 460, baseCost = 260 },
    { id = 20904, flatBonus = 600, baseCost = 310 },
})

AddRanks("Multi-Shot", "ranged_shot", "MANA", { targets = 3 }, {
    { id = 2643,  flatBonus = 0,   baseCost = 100 },
    { id = 14288, flatBonus = 40,  baseCost = 140 },
    { id = 14289, flatBonus = 80,  baseCost = 175 },
    { id = 14290, flatBonus = 120, baseCost = 210 },
    { id = 25294, flatBonus = 150, baseCost = 230 },
})

AddRanks("Arcane Shot", "ranged_arcane", "MANA", { rapRatio = 0.15 }, {
    { id = 3044,  baseDmg = 13,  baseCost = 25 },
    { id = 14281, baseDmg = 21,  baseCost = 35 },
    { id = 14282, baseDmg = 33,  baseCost = 50 },
    { id = 14283, baseDmg = 59,  baseCost = 80 },
    { id = 14284, baseDmg = 83,  baseCost = 105 },
    { id = 14285, baseDmg = 115, baseCost = 135 },
    { id = 14286, baseDmg = 145, baseCost = 160 },
    { id = 14287, baseDmg = 183, baseCost = 190 },
})

AddRanks("Serpent Sting", "ranged_dot", "MANA", { rapRatio = 0.10, ticks = 5, duration = 15 }, {
    { id = 1978,  baseTotal = 20,  baseCost = 15 },
    { id = 13549, baseTotal = 40,  baseCost = 30 },
    { id = 13550, baseTotal = 80,  baseCost = 50 },
    { id = 13551, baseTotal = 140, baseCost = 80 },
    { id = 13552, baseTotal = 210, baseCost = 115 },
    { id = 13553, baseTotal = 290, baseCost = 150 },
    { id = 13554, baseTotal = 385, baseCost = 190 },
    { id = 13555, baseTotal = 490, baseCost = 230 },
    { id = 25295, baseTotal = 555, baseCost = 250 },
})

AddRanks("Raptor Strike", "melee_strike", "MANA", { mult = 1.0 }, {
    { id = 2973,  flatBonus = 5,   baseCost = 15 },
    { id = 14260, flatBonus = 11,  baseCost = 25 },
    { id = 14261, flatBonus = 21,  baseCost = 35 },
    { id = 14262, flatBonus = 34,  baseCost = 45 },
    { id = 14263, flatBonus = 50,  baseCost = 60 },
    { id = 14264, flatBonus = 80,  baseCost = 80 },
    { id = 14265, flatBonus = 110, baseCost = 100 },
    { id = 14266, flatBonus = 140, baseCost = 120 },
})

AddRanks("Mongoose Bite", "ap_strike", "MANA", { apRatio = 0.20 }, {
    { id = 1495,  minBase = 25,  maxBase = 25,  baseCost = 30 },
    { id = 14269, minBase = 45,  maxBase = 45,  baseCost = 40 },
    { id = 14270, minBase = 75,  maxBase = 75,  baseCost = 50 },
    { id = 14271, minBase = 115, maxBase = 115, baseCost = 65 },
})

-- ============================================================================
-- SHAMAN ABILITIES (Shocks, Lightning, Stormstrike)
-- ============================================================================
AddRanks("Earth Shock", "spell_nuke", "MANA", { school = 4, spRatio = 0.386 }, {
    { id = 8042,  minBase = 17,  maxBase = 19,  baseCost = 30 },
    { id = 8044,  minBase = 32,  maxBase = 36,  baseCost = 50 },
    { id = 8045,  minBase = 60,  maxBase = 66,  baseCost = 85 },
    { id = 8046,  minBase = 119, maxBase = 129, baseCost = 145 },
    { id = 10412, minBase = 225, maxBase = 240, baseCost = 240 },
    { id = 10413, minBase = 359, maxBase = 381, baseCost = 345 },
    { id = 10414, minBase = 517, maxBase = 545, baseCost = 450 },
})

AddRanks("Frost Shock", "spell_nuke", "MANA", { school = 5, spRatio = 0.386 }, {
    { id = 8056,  minBase = 89,  maxBase = 95,  baseCost = 115 },
    { id = 8058,  minBase = 206, maxBase = 220, baseCost = 225 },
    { id = 10472, minBase = 333, maxBase = 353, baseCost = 325 },
    { id = 10473, minBase = 486, maxBase = 514, baseCost = 430 },
})

AddRanks("Flame Shock", "spell_hybrid", "MANA", { school = 3, directSP = 0.214, dotSP = 0.52, ticks = 4, duration = 12 }, {
    { id = 8050,  minDirect = 21,  maxDirect = 21,  baseDot = 28,  baseCost = 55 },
    { id = 8052,  minDirect = 45,  maxDirect = 45,  baseDot = 48,  baseCost = 95 },
    { id = 8053,  minDirect = 86,  maxDirect = 86,  baseDot = 96,  baseCost = 160 },
    { id = 10447, minDirect = 152, maxDirect = 152, baseDot = 168, baseCost = 250 },
    { id = 10448, minDirect = 230, maxDirect = 230, baseDot = 256, baseCost = 345 },
    { id = 29228, minDirect = 292, maxDirect = 292, baseDot = 320, baseCost = 410 },
})

AddRanks("Lightning Bolt", "spell_nuke", "MANA", { school = 4, spRatio = 0.857 }, {
    { id = 403,   minBase = 13,  maxBase = 15,  baseCost = 15 },
    { id = 529,   minBase = 26,  maxBase = 31,  baseCost = 30 },
    { id = 548,   minBase = 45,  maxBase = 53,  baseCost = 45 },
    { id = 915,   minBase = 83,  maxBase = 95,  baseCost = 75 },
    { id = 943,   minBase = 125, maxBase = 143, baseCost = 105 },
    { id = 6041,  minBase = 172, maxBase = 194, baseCost = 135 },
    { id = 10391, minBase = 227, maxBase = 255, baseCost = 165 },
    { id = 10392, minBase = 282, maxBase = 316, baseCost = 195 },
    { id = 15207, minBase = 347, maxBase = 389, baseCost = 230 },
    { id = 15208, minBase = 419, maxBase = 467, baseCost = 265 },
})

AddRanks("Chain Lightning", "spell_nuke", "MANA", { school = 4, spRatio = 0.714, targets = 3, cleaveMult = 2.19 }, {
    { id = 421,   minBase = 191, maxBase = 217, baseCost = 280 },
    { id = 930,   minBase = 277, maxBase = 311, baseCost = 380 },
    { id = 2860,  minBase = 378, maxBase = 424, baseCost = 490 },
    { id = 10605, minBase = 493, maxBase = 551, baseCost = 605 },
})

AddRanks("Stormstrike", "melee_strike", "MANA", { mult = 1.0, flatBonus = 0 }, {
    { id = 17364, baseCost = 210 },
})

-- ============================================================================
-- WARLOCK ABILITIES (Shadow Bolt, DoTs, Fire Spells & Drains)
-- ============================================================================
AddRanks("Shadow Bolt", "spell_nuke", "MANA", { school = 6, spRatio = 0.857 }, {
    { id = 686,   minBase = 12,  maxBase = 16,  baseCost = 25 },
    { id = 695,   minBase = 23,  maxBase = 29,  baseCost = 40 },
    { id = 705,   minBase = 48,  maxBase = 56,  baseCost = 70 },
    { id = 1088,  minBase = 86,  maxBase = 98,  baseCost = 110 },
    { id = 1106,  minBase = 142, maxBase = 162, baseCost = 160 },
    { id = 7641,  minBase = 204, maxBase = 230, baseCost = 210 },
    { id = 11659, minBase = 281, maxBase = 315, baseCost = 265 },
    { id = 11660, minBase = 360, maxBase = 402, baseCost = 315 },
    { id = 11661, minBase = 455, maxBase = 507, baseCost = 370 },
    { id = 25307, minBase = 482, maxBase = 538, baseCost = 380 },
})

AddRanks("Corruption", "spell_dot", "MANA", { school = 6, spRatio = 1.0, ticks = 6, duration = 18 }, {
    { id = 172,   baseTotal = 40,  baseCost = 35 },
    { id = 6222,  baseTotal = 90,  baseCost = 55 },
    { id = 6223,  baseTotal = 222, baseCost = 100 },
    { id = 7648,  baseTotal = 324, baseCost = 135 },
    { id = 11671, baseTotal = 486, baseCost = 190 },
    { id = 11672, baseTotal = 666, baseCost = 250 },
    { id = 25311, baseTotal = 822, baseCost = 290 },
})

AddRanks("Curse of Agony", "spell_dot", "MANA", { school = 6, spRatio = 1.0, ticks = 12, duration = 24 }, {
    { id = 980,   baseTotal = 84,   baseCost = 25 },
    { id = 1014,  baseTotal = 180,  baseCost = 50 },
    { id = 6217,  baseTotal = 324,  baseCost = 90 },
    { id = 11711, baseTotal = 504,  baseCost = 130 },
    { id = 11712, baseTotal = 780,  baseCost = 170 },
    { id = 11713, baseTotal = 1044, baseCost = 215 },
})
FeralCalc.SpellRanksByName["Bane of Agony"] = FeralCalc.SpellRanksByName["Curse of Agony"]

AddRanks("Immolate", "spell_hybrid", "MANA", { school = 3, directSP = 0.20, dotSP = 0.65, ticks = 5, duration = 15 }, {
    { id = 348,   minDirect = 8,   maxDirect = 8,   baseDot = 20,  baseCost = 25 },
    { id = 707,   minDirect = 19,  maxDirect = 19,  baseDot = 40,  baseCost = 45 },
    { id = 1094,  minDirect = 45,  maxDirect = 45,  baseDot = 90,  baseCost = 90 },
    { id = 2941,  minDirect = 90,  maxDirect = 90,  baseDot = 165, baseCost = 155 },
    { id = 11665, minDirect = 134, maxDirect = 134, baseDot = 255, baseCost = 220 },
    { id = 11667, minDirect = 192, maxDirect = 192, baseDot = 365, baseCost = 295 },
    { id = 11668, minDirect = 258, maxDirect = 258, baseDot = 485, baseCost = 370 },
    { id = 25309, minDirect = 279, maxDirect = 279, baseDot = 510, baseCost = 380 },
})

AddRanks("Siphon Life", "spell_dot", "MANA", { school = 6, spRatio = 0.50, ticks = 10, duration = 30 }, {
    { id = 18265, baseTotal = 150, baseCost = 150 },
    { id = 18879, baseTotal = 220, baseCost = 205 },
    { id = 18880, baseTotal = 330, baseCost = 285 },
    { id = 18881, baseTotal = 450, baseCost = 365 },
})

AddRanks("Drain Life", "spell_dot", "MANA", { school = 6, spRatio = 0.50, ticks = 5, duration = 5 }, {
    { id = 689,   baseTotal = 50,  baseCost = 55 },
    { id = 699,   baseTotal = 85,  baseCost = 85 },
    { id = 709,   baseTotal = 145, baseCost = 135 },
    { id = 7651,  baseTotal = 205, baseCost = 185 },
    { id = 11699, baseTotal = 275, baseCost = 240 },
    { id = 11700, baseTotal = 355, baseCost = 300 },
})

AddRanks("Searing Pain", "spell_nuke", "MANA", { school = 3, spRatio = 0.429 }, {
    { id = 5676,  minBase = 34,  maxBase = 42,  baseCost = 45 },
    { id = 17919, minBase = 59,  maxBase = 71,  baseCost = 68 },
    { id = 17920, minBase = 86,  maxBase = 104, baseCost = 91 },
    { id = 17921, minBase = 122, maxBase = 146, baseCost = 118 },
    { id = 17922, minBase = 158, maxBase = 188, baseCost = 141 },
    { id = 17923, minBase = 204, maxBase = 240, baseCost = 168 },
})

AddRanks("Soul Fire", "spell_nuke", "MANA", { school = 3, spRatio = 1.0 }, {
    { id = 6353,  minBase = 623, maxBase = 783, baseCost = 305 },
    { id = 17924, minBase = 703, maxBase = 881, baseCost = 335 },
})

AddRanks("Shadowburn", "spell_nuke", "MANA", { school = 6, spRatio = 0.429 }, {
    { id = 17877, minBase = 87,  maxBase = 99,  baseCost = 105 },
    { id = 18867, minBase = 115, maxBase = 131, baseCost = 130 },
    { id = 18868, minBase = 186, maxBase = 210, baseCost = 190 },
    { id = 18869, minBase = 261, maxBase = 293, baseCost = 245 },
    { id = 18870, minBase = 350, maxBase = 392, baseCost = 305 },
    { id = 18871, minBase = 450, maxBase = 502, baseCost = 365 },
})

-- ============================================================================
-- ROGUE ABILITIES (Energy Builders & Combo Point Finishers)
-- ============================================================================
AddRanks("Sinister Strike", "melee_strike", "ENERGY", { mult = 1.0, baseCost = 45 }, {
    { id = 1752,  flatBonus = 3 },
    { id = 1757,  flatBonus = 6 },
    { id = 1758,  flatBonus = 10 },
    { id = 1759,  flatBonus = 15 },
    { id = 1760,  flatBonus = 22 },
    { id = 8621,  flatBonus = 33 },
    { id = 11293, flatBonus = 52 },
    { id = 11294, flatBonus = 68 },
})

AddRanks("Backstab", "melee_strike", "ENERGY", { mult = 1.50, baseCost = 60 }, {
    { id = 53,    flatBonus = 15 },
    { id = 2589,  flatBonus = 30 },
    { id = 2590,  flatBonus = 48 },
    { id = 2591,  flatBonus = 69 },
    { id = 8721,  flatBonus = 90 },
    { id = 11279, flatBonus = 135 },
    { id = 11280, flatBonus = 165 },
    { id = 11281, flatBonus = 210 },
    { id = 25300, flatBonus = 225 },
})

AddRanks("Ambush", "melee_strike", "ENERGY", { mult = 2.50, baseCost = 60 }, {
    { id = 8676,  flatBonus = 70 },
    { id = 8724,  flatBonus = 100 },
    { id = 8725,  flatBonus = 125 },
    { id = 11267, flatBonus = 185 },
    { id = 11268, flatBonus = 230 },
    { id = 11269, flatBonus = 290 },
    { id = 27441, flatBonus = 335 },
})

AddRanks("Hemorrhage", "melee_strike", "ENERGY", { mult = 1.0, baseCost = 35 }, {
    { id = 16511, flatBonus = 0 },
    { id = 17347, flatBonus = 0 },
    { id = 17348, flatBonus = 0 },
})

AddRanks("Ghostly Strike", "melee_strike", "ENERGY", { mult = 1.25, baseCost = 40, flatBonus = 0 }, {
    { id = 14278 },
})

AddRanks("Riposte", "melee_strike", "ENERGY", { mult = 1.50, baseCost = 10, flatBonus = 0 }, {
    { id = 14251 },
})

AddRanks("Garrote", "melee_bleed", "ENERGY", { bleedAP = 0.18, ticks = 6, duration = 18, baseCost = 50 }, {
    { id = 703,   baseBleed = 72 },
    { id = 8631,  baseBleed = 102 },
    { id = 8632,  baseBleed = 144 },
    { id = 8633,  baseBleed = 198 },
    { id = 11289, baseBleed = 264 },
    { id = 11290, baseBleed = 342 },
})

AddRanks("Eviscerate", "rogue_evis", "ENERGY", { baseCost = 35, apPerCP = 0.03 }, {
    { id = 2098,  minBase = 6,   maxBase = 10,  perCP = 5 },
    { id = 6760,  minBase = 14,  maxBase = 22,  perCP = 11 },
    { id = 6761,  minBase = 25,  maxBase = 39,  perCP = 19 },
    { id = 6762,  minBase = 41,  maxBase = 61,  perCP = 31 },
    { id = 8623,  minBase = 60,  maxBase = 90,  perCP = 45 },
    { id = 8624,  minBase = 93,  maxBase = 137, perCP = 71 },
    { id = 11299, minBase = 144, maxBase = 212, perCP = 110 },
    { id = 11300, minBase = 199, maxBase = 295, perCP = 151 },
    { id = 31016, minBase = 224, maxBase = 332, perCP = 170 },
})

AddRanks("Rupture", "rogue_rupture", "ENERGY", { baseCost = 25, ticks = 8, duration = 16, apRatio5 = 0.24 }, {
    { id = 1943,  base5 = 100 },
    { id = 8639,  base5 = 160 },
    { id = 8640,  base5 = 245 },
    { id = 11273, base5 = 355 },
    { id = 11274, base5 = 490 },
    { id = 11275, base5 = 675 },
})

-- ============================================================================
-- MAGE ABILITIES (Frost, Fire & Arcane Spells)
-- ============================================================================
AddRanks("Frostbolt", "spell_nuke", "MANA", { school = 5, spRatio = 0.814 }, {
    { id = 116,   minBase = 18,  maxBase = 20,  baseCost = 25 },
    { id = 205,   minBase = 31,  maxBase = 35,  baseCost = 35 },
    { id = 837,   minBase = 51,  maxBase = 57,  baseCost = 50 },
    { id = 7322,  minBase = 74,  maxBase = 82,  baseCost = 65 },
    { id = 8406,  minBase = 126, maxBase = 138, baseCost = 100 },
    { id = 8407,  minBase = 174, maxBase = 190, baseCost = 130 },
    { id = 8408,  minBase = 227, maxBase = 247, baseCost = 160 },
    { id = 10179, minBase = 292, maxBase = 316, baseCost = 195 },
    { id = 10180, minBase = 353, maxBase = 383, baseCost = 225 },
    { id = 10181, minBase = 429, maxBase = 463, baseCost = 260 },
    { id = 25304, minBase = 515, maxBase = 555, baseCost = 290 },
})

AddRanks("Fireball", "spell_hybrid", "MANA", { school = 3, directSP = 1.0, dotSP = 0.0, ticks = 4, duration = 8 }, {
    { id = 133,   minDirect = 14,  maxDirect = 22,  baseDot = 2,  baseCost = 30 },
    { id = 143,   minDirect = 31,  maxDirect = 45,  baseDot = 3,  baseCost = 45 },
    { id = 145,   minDirect = 53,  maxDirect = 73,  baseDot = 6,  baseCost = 65 },
    { id = 3140,  minDirect = 84,  maxDirect = 116, baseDot = 12, baseCost = 95 },
    { id = 8400,  minDirect = 139, maxDirect = 187, baseDot = 20, baseCost = 140 },
    { id = 8401,  minDirect = 199, maxDirect = 265, baseDot = 28, baseCost = 185 },
    { id = 8402,  minDirect = 255, maxDirect = 335, baseDot = 36, baseCost = 220 },
    { id = 10148, minDirect = 318, maxDirect = 414, baseDot = 44, baseCost = 260 },
    { id = 10149, minDirect = 392, maxDirect = 506, baseDot = 56, baseCost = 305 },
    { id = 10150, minDirect = 475, maxDirect = 609, baseDot = 68, baseCost = 350 },
    { id = 10151, minDirect = 561, maxDirect = 715, baseDot = 76, baseCost = 395 },
    { id = 25306, minDirect = 596, maxDirect = 760, baseDot = 76, baseCost = 410 },
})

AddRanks("Fire Blast", "spell_nuke", "MANA", { school = 3, spRatio = 0.429 }, {
    { id = 2136,  minBase = 24,  maxBase = 32,  baseCost = 40 },
    { id = 2137,  minBase = 57,  maxBase = 71,  baseCost = 75 },
    { id = 2138,  minBase = 103, maxBase = 127, baseCost = 115 },
    { id = 8412,  minBase = 168, maxBase = 202, baseCost = 165 },
    { id = 8413,  minBase = 246, maxBase = 294, baseCost = 220 },
    { id = 10197, minBase = 332, maxBase = 394, baseCost = 280 },
    { id = 10199, minBase = 431, maxBase = 509, baseCost = 340 },
})

AddRanks("Scorch", "spell_nuke", "MANA", { school = 3, spRatio = 0.429 }, {
    { id = 2948,  minBase = 53,  maxBase = 65,  baseCost = 50 },
    { id = 8444,  minBase = 77,  maxBase = 93,  baseCost = 65 },
    { id = 8445,  minBase = 100, maxBase = 120, baseCost = 80 },
    { id = 8446,  minBase = 133, maxBase = 159, baseCost = 100 },
    { id = 10205, minBase = 168, maxBase = 199, baseCost = 115 },
    { id = 10206, minBase = 207, maxBase = 245, baseCost = 135 },
    { id = 10207, minBase = 233, maxBase = 275, baseCost = 150 },
})

AddRanks("Arcane Missiles", "spell_nuke", "MANA", { school = 7, spRatio = 1.0 }, {
    { id = 5143,  minBase = 72,   maxBase = 72,   baseCost = 85 },
    { id = 5144,  minBase = 144,  maxBase = 144,  baseCost = 140 },
    { id = 5145,  minBase = 280,  maxBase = 280,  baseCost = 235 },
    { id = 8416,  minBase = 415,  maxBase = 415,  baseCost = 320 },
    { id = 8417,  minBase = 575,  maxBase = 575,  baseCost = 410 },
    { id = 10211, minBase = 755,  maxBase = 755,  baseCost = 500 },
    { id = 10212, minBase = 960,  maxBase = 960,  baseCost = 595 },
    { id = 25345, minBase = 1150, maxBase = 1150, baseCost = 655 },
})

-- ============================================================================
-- PRIEST ABILITIES (Shadow & Holy Offensive Spells)
-- ============================================================================
AddRanks("Shadow Word: Pain", "spell_dot", "MANA", { school = 6, spRatio = 1.0, ticks = 6, duration = 18 }, {
    { id = 589,   baseTotal = 30,  baseCost = 25 },
    { id = 594,   baseTotal = 66,  baseCost = 50 },
    { id = 970,   baseTotal = 132, baseCost = 95 },
    { id = 992,   baseTotal = 234, baseCost = 155 },
    { id = 2767,  baseTotal = 366, baseCost = 230 },
    { id = 10892, baseTotal = 510, baseCost = 305 },
    { id = 10893, baseTotal = 672, baseCost = 385 },
    { id = 10894, baseTotal = 852, baseCost = 470 },
})

AddRanks("Mind Blast", "spell_nuke", "MANA", { school = 6, spRatio = 0.429 }, {
    { id = 8092,  minBase = 39,  maxBase = 43,  baseCost = 50 },
    { id = 8102,  minBase = 72,  maxBase = 78,  baseCost = 80 },
    { id = 8103,  minBase = 112, maxBase = 122, baseCost = 110 },
    { id = 8104,  minBase = 167, maxBase = 179, baseCost = 150 },
    { id = 8105,  minBase = 217, maxBase = 231, baseCost = 185 },
    { id = 8106,  minBase = 279, maxBase = 297, baseCost = 225 },
    { id = 10945, minBase = 346, maxBase = 366, baseCost = 265 },
    { id = 10946, minBase = 425, maxBase = 449, baseCost = 310 },
    { id = 10947, minBase = 503, maxBase = 531, baseCost = 350 },
})

AddRanks("Mind Flay", "spell_dot", "MANA", { school = 6, spRatio = 0.45, ticks = 3, duration = 3 }, {
    { id = 15407, baseTotal = 75,  baseCost = 45 },
    { id = 17311, baseTotal = 126, baseCost = 70 },
    { id = 17312, baseTotal = 186, baseCost = 100 },
    { id = 17313, baseTotal = 261, baseCost = 135 },
    { id = 17314, baseTotal = 330, baseCost = 165 },
    { id = 18807, baseTotal = 426, baseCost = 205 },
})

AddRanks("Smite", "spell_nuke", "MANA", { school = 2, spRatio = 0.714 }, {
    { id = 585,   minBase = 15,  maxBase = 20,  baseCost = 20 },
    { id = 591,   minBase = 28,  maxBase = 34,  baseCost = 30 },
    { id = 598,   minBase = 54,  maxBase = 62,  baseCost = 60 },
    { id = 984,   minBase = 91,  maxBase = 104, baseCost = 95 },
    { id = 1004,  minBase = 150, maxBase = 170, baseCost = 140 },
    { id = 6060,  minBase = 212, maxBase = 240, baseCost = 185 },
    { id = 10933, minBase = 287, maxBase = 323, baseCost = 230 },
    { id = 10934, minBase = 371, maxBase = 415, baseCost = 280 },
})

AddRanks("Holy Fire", "spell_hybrid", "MANA", { school = 2, directSP = 0.75, dotSP = 0.25, ticks = 5, duration = 10 }, {
    { id = 14914, minDirect = 78,  maxDirect = 98,  baseDot = 30,  baseCost = 85 },
    { id = 15262, minDirect = 97,  maxDirect = 122, baseDot = 40,  baseCost = 95 },
    { id = 15263, minDirect = 137, maxDirect = 173, baseDot = 55,  baseCost = 125 },
    { id = 15264, minDirect = 173, maxDirect = 218, baseDot = 65,  baseCost = 145 },
    { id = 15265, minDirect = 219, maxDirect = 273, baseDot = 85,  baseCost = 170 },
    { id = 15266, minDirect = 271, maxDirect = 340, baseDot = 100, baseCost = 200 },
    { id = 15267, minDirect = 323, maxDirect = 406, baseDot = 125, baseCost = 230 },
    { id = 15261, minDirect = 355, maxDirect = 449, baseDot = 145, baseCost = 255 },
})

-- ============================================================================
-- DRUID: CASTER / MOONKIN SPELLS (Wrath, Starfire, Moonfire, Insect Swarm)
-- ============================================================================
AddRanks("Wrath", "spell_nuke", "MANA", { school = 4, spRatio = 0.571 }, {
    { id = 5176, minBase = 13,  maxBase = 16,  baseCost = 20 },
    { id = 5177, minBase = 28,  maxBase = 33,  baseCost = 35 },
    { id = 5178, minBase = 48,  maxBase = 57,  baseCost = 55 },
    { id = 5179, minBase = 69,  maxBase = 79,  baseCost = 70 },
    { id = 5180, minBase = 108, maxBase = 123, baseCost = 100 },
    { id = 6780, minBase = 148, maxBase = 167, baseCost = 125 },
    { id = 8905, minBase = 198, maxBase = 221, baseCost = 155 },
    { id = 9912, minBase = 248, maxBase = 277, baseCost = 180 },
})

AddRanks("Starfire", "spell_nuke", "MANA", { school = 7, spRatio = 1.0 }, {
    { id = 2912,  minBase = 95,  maxBase = 115, baseCost = 95 },
    { id = 8949,  minBase = 146, maxBase = 177, baseCost = 135 },
    { id = 8950,  minBase = 212, maxBase = 253, baseCost = 180 },
    { id = 8951,  minBase = 293, maxBase = 348, baseCost = 230 },
    { id = 9875,  minBase = 378, maxBase = 445, baseCost = 275 },
    { id = 9876,  minBase = 463, maxBase = 543, baseCost = 315 },
    { id = 25298, minBase = 496, maxBase = 584, baseCost = 340 },
})

AddRanks("Moonfire", "spell_hybrid", "MANA", { school = 7, directSP = 0.15, dotSP = 0.52, ticks = 4, duration = 12 }, {
    { id = 8921, minDirect = 9,   maxDirect = 12,  baseDot = 12,  baseCost = 25 },
    { id = 8924, minDirect = 17,  maxDirect = 21,  baseDot = 32,  baseCost = 50 },
    { id = 8925, minDirect = 30,  maxDirect = 37,  baseDot = 52,  baseCost = 75 },
    { id = 8926, minDirect = 47,  maxDirect = 55,  baseDot = 80,  baseCost = 105 },
    { id = 8927, minDirect = 70,  maxDirect = 82,  baseDot = 124, baseCost = 150 },
    { id = 8928, minDirect = 91,  maxDirect = 108, baseDot = 164, baseCost = 190 },
    { id = 8929, minDirect = 117, maxDirect = 137, baseDot = 212, baseCost = 235 },
    { id = 9833, minDirect = 143, maxDirect = 168, baseDot = 264, baseCost = 280 },
    { id = 9834, minDirect = 172, maxDirect = 200, baseDot = 320, baseCost = 325 },
    { id = 9835, minDirect = 195, maxDirect = 228, baseDot = 384, baseCost = 375 },
})

AddRanks("Insect Swarm", "spell_dot", "MANA", { school = 4, spRatio = 0.76, ticks = 6, duration = 12 }, {
    { id = 5570,  baseTotal = 66,  baseCost = 45 },
    { id = 24974, baseTotal = 108, baseCost = 65 },
    { id = 24975, baseTotal = 174, baseCost = 100 },
    { id = 24976, baseTotal = 264, baseCost = 135 },
    { id = 24977, baseTotal = 324, baseCost = 160 },
})

-- ============================================================================
-- WARRIOR: ARMS / FURY rotational skills (Mortal Strike, Bloodthirst, Overpower, Whirlwind, Rend)
-- ============================================================================
AddRanks("Mortal Strike", "melee_strike", "RAGE", { mult = 1.0, baseCost = 30 }, {
    { id = 12294, flatBonus = 85 },
    { id = 21551, flatBonus = 110 },
    { id = 21552, flatBonus = 135 },
    { id = 21553, flatBonus = 160 },
})

AddRanks("Bloodthirst", "ap_strike", "RAGE", { minBase = 0, maxBase = 0, apRatio = 0.45, baseCost = 30 }, {
    { id = 23881 },
    { id = 23892 },
    { id = 23893 },
    { id = 23894 },
})

AddRanks("Overpower", "melee_strike", "RAGE", { mult = 1.0, baseCost = 5 }, {
    { id = 7384,  flatBonus = 5 },
    { id = 7887,  flatBonus = 15 },
    { id = 11584, flatBonus = 25 },
    { id = 11585, flatBonus = 35 },
})

AddRanks("Whirlwind", "war_cleave", "RAGE", { flatBonus = 0, targets = 4, baseCost = 25 }, {
    { id = 1680 },
})

AddRanks("Sunder Armor", "war_sunder", "RAGE", { baseCost = 15, costTalent = "impSunderArmor" }, {
    { id = 7386,  flatThreat = 45 },
    { id = 7405,  flatThreat = 105 },
    { id = 8380,  flatThreat = 140 },
    { id = 11596, flatThreat = 180 },
    { id = 11597, flatThreat = 260 },
})

-- ============================================================================
-- SPELL ENTRY LOOKUP (ID first, then Name + Rank fallback)
-- ============================================================================
function FeralCalc:GetSpellEntry(spellID, spellName, spellSubText)
    if spellID and self.SpellData[spellID] then
        return self.SpellData[spellID]
    end
    if not spellName then
        return nil
    end

    local cleanName, inlineRank = spellName:match("^(.-)%s*%(Rank%s*(%d+)%)$")
    if cleanName then
        spellName = cleanName
    end

    local rankNum = tonumber(inlineRank) or (spellSubText and tonumber(spellSubText:match("(%d+)"))) or nil

    local byRank = self.SpellRanksByName and self.SpellRanksByName[spellName]
    if byRank then
        if rankNum and byRank[rankNum] then
            return byRank[rankNum]
        end
        local highestRank = 0
        local best = nil
        for r, entry in pairs(byRank) do
            if r > highestRank then
                highestRank = r
                best = entry
            end
        end
        if best then
            return best
        end
    end

    local bestMatch = nil
    for _, data in pairs(self.SpellData) do
        if data.name == spellName then
            if rankNum and data.rank == rankNum then
                return data
            end
            if not bestMatch or (data.rank and data.rank > (bestMatch.rank or 0)) then
                bestMatch = data
            end
        end
    end

    return bestMatch
end
