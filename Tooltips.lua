local addonName, FeralCalc = ...

local function FormatInt(val)
    return string.format("%d", math.floor((val or 0) + 0.5))
end

local function FormatDec(val)
    return string.format("%.1f", val or 0)
end

local function SafeText(val)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, val)
        if not ok or secret then return nil end
    end
    if type(val) == "string" and val ~= "" then
        return val
    end
    return nil
end

function FeralCalc:GetCurrentComboPoints()
    local cpType = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4
    if type(UnitPower) == "function" then
        local ok, cp = pcall(UnitPower, "player", cpType)
        if ok and type(cp) == "number" and cp > 0 then
            return cp
        end
    end
    if type(GetComboPoints) == "function" then
        local ok, cp = pcall(GetComboPoints, "player", "target")
        if ok and type(cp) == "number" and cp > 0 then
            return cp
        end
    end
    return 0
end

function FeralCalc:AppendSpellTooltip(tooltip, tooltipData)
    if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then
        return
    end

    local spellName, spellID
    if type(tooltipData) == "table" and type(tooltipData.id) == "number" then
        spellID = tooltipData.id
        spellName = self:GetSpellNameByID(spellID)
    end
    if (not spellName or not spellID) and type(tooltip.GetSpell) == "function" then
        local ok, sName, sID = pcall(tooltip.GetSpell, tooltip)
        if ok then
            spellName = spellName or SafeText(sName)
            spellID = spellID or sID
        end
    end

    local ttName = tooltip.GetName and tooltip:GetName() or "GameTooltip"
    if not spellName then
        local left1 = _G[ttName .. "TextLeft1"]
        if left1 and left1.GetText then
            spellName = SafeText(left1:GetText())
        end
    end

    if not spellName and not spellID then
        return
    end

    local cacheKey = tostring(spellID or spellName)
    if tooltip.feralCalcLastSpell == cacheKey then
        return
    end

    self:InitDB()

    local subText = self:GetSpellSubtextByID(spellID)
    if not subText then
        local right1 = _G[ttName .. "TextRight1"]
        if right1 and right1.GetText then
            subText = SafeText(right1:GetText())
        end
    end

    local data = self:GetAbilityDamage(spellID, spellName, subText)
    if not data then
        return
    end

    tooltip.feralCalcLastSpell = cacheKey
    local showArmor = self.db and self.db.showPostArmor
    local currentCP = self:GetCurrentComboPoints()
    local powerLabel = (data.powerType == "RAGE") and "Rage" or ((data.powerType == "MANA") and "Mana" or "Energy")
    local effLabel = (data.powerType == "RAGE") and "DPR" or ((data.powerType == "MANA") and "DPM" or "DPE")

    local function AddRFThreatLine(baseDmg)
        if data.classFile == "PALADIN" and data.rfHolyMult and data.rfHolyMult > 1.0 then
            local rfThreat = (baseDmg or 0) * data.rfHolyMult
            local tpm = ((data.cost or 0) > 0) and (rfThreat / data.cost) or 0
            tooltip:AddDoubleLine(
                "  |cFFFF8040Righteous Fury Threat:|r",
                string.format("|cFFFF8040%s Threat|r (|cFFFFCC00%.2f TPM|r)", FormatInt(rfThreat), tpm)
            )
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(
        string.format("|cFFFF7D0AForeverCalc:|r |cFFFFFFFF%s (Rank %d)|r", data.name, data.rank or 1),
        string.format("|cFFAAAAAA%d %s|r", data.cost or 0, powerLabel)
    )

    if data.classFile == "DRUID" then
        local isBearSpell = data.type:find("^bear_") ~= nil
        local isCatSpell = data.type:find("^cat_") ~= nil
        if isBearSpell and data.formKey ~= "BEAR" and data.formKey ~= "DIRE_BEAR" then
            tooltip:AddLine("|cFF888888(Using current form dmg; Bear normalizes Weapon DPS x 2.50s)|r")
        elseif isBearSpell then
            tooltip:AddLine("|cFF888888Bear Norm: Weapon DPS x 2.50s · 14 AP = 1 DPS (+2.5 dmg/hit)|r")
        elseif isCatSpell and data.formKey ~= "CAT" then
            tooltip:AddLine("|cFF888888(Using current form weapon dmg; shift to Cat for 1.0s norm)|r")
        end
    end

    -- 1. PHYSICAL & RANGED STRIKES (Druid, Warrior, Rogue, Hunter, Shaman)
    if data.type == "bear_strike" or data.type == "cat_strike" or data.type == "cat_shred"
        or data.type == "war_strike" or data.type == "war_shield_slam" or data.type == "war_revenge"
        or data.type == "melee_strike" or data.type == "ap_strike" or data.type == "ranged_arcane" then
        if data.type == "war_shield_slam" then
            tooltip:AddDoubleLine(
                "  |cFFFFD100Shield Block Value Bonus:|r",
                string.format("|cFF00FF00+%s Dmg|r", FormatInt(data.blockValue))
            )
        end
        tooltip:AddDoubleLine(
            "  |cFFFFD100Raw Damage:|r",
            string.format("|cFFFFFFFF%s - %s|r |cFFAAAAAA(Avg: %s)|r", FormatInt(data.minDmg), FormatInt(data.maxDmg), FormatInt(data.avgDmg))
        )
        if showArmor and data.type ~= "ranged_arcane" then
            tooltip:AddDoubleLine(
                string.format("  |cFFFF8040vs Lvl %d Boss (-%s%% Armor):|r", data.bossLevel or 63, FormatDec(data.bossArmorDRPct)),
                string.format("|cFFFFCC80%s - %s|r |cFFAAAAAA(Avg: %s)|r", FormatInt(data.minPostArmor), FormatInt(data.maxPostArmor), FormatInt(data.avgPostArmor))
            )
        end
        tooltip:AddDoubleLine(
            string.format("  |cFF00CCFFEfficiency (%s):|r", effLabel),
            (showArmor and data.type ~= "ranged_arcane")
                and string.format("|cFF00CCFF%s|r raw / |cFFFFCC80%s|r boss Dmg/%s", FormatDec(data.efficiency), FormatDec(data.efficiencyPostArmor), powerLabel)
                or string.format("|cFF00CCFF%s Dmg / %s|r", FormatDec(data.efficiency), powerLabel)
        )

    -- 1b. HUNTER RANGED SHOTS (Aimed Shot / Multi-Shot)
    elseif data.type == "ranged_shot" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Ranged Shot Damage:|r",
            string.format("|cFFFFFFFF%s - %s|r |cFFAAAAAA(Avg: %s)|r", FormatInt(data.minDmg), FormatInt(data.maxDmg), FormatInt(data.avgDmg))
        )
        if (data.targets or 1) > 1 then
            tooltip:AddDoubleLine(
                string.format("  |cFFFFD100%d-Target Cleave Total:|r", data.targets),
                string.format("|cFF00FF00%s|r (|cFF00FF00%.2f %s|r)", FormatInt(data.cleaveTotal), data.efficiencyCleave or 0, effLabel)
            )
        end
        if showArmor then
            tooltip:AddDoubleLine(
                string.format("  |cFFFF8040vs Lvl %d Boss (-%s%% Armor):|r", data.bossLevel or 63, FormatDec(data.bossArmorDRPct)),
                string.format("|cFFFFCC80%s - %s|r |cFFAAAAAA(Avg: %s)|r", FormatInt(data.minPostArmor), FormatInt(data.maxPostArmor), FormatInt(data.avgPostArmor))
            )
        end
        tooltip:AddDoubleLine(
            string.format("  |cFF00CCFFEfficiency (%s):|r", effLabel),
            showArmor
                and string.format("|cFF00CCFF%.2f|r raw / |cFFFFCC80%.2f|r boss Dmg/%s", data.efficiency or 0, data.efficiencyPostArmor or 0, powerLabel)
                or string.format("|cFF00CCFF%.2f Dmg / %s|r", data.efficiency or 0, powerLabel)
        )

    -- 1c. HUNTER / SPELL DOTS (Serpent Sting, Corruption, Curse of Agony, SW:P, Mind Flay, Siphon Life, Drain Life, Insect Swarm)
    elseif data.type == "ranged_dot" or data.type == "spell_dot" then
        tooltip:AddDoubleLine(
            string.format("  |cFFFF6060Total DoT (%ds / %d Ticks):|r", data.duration or 15, data.ticks or 5),
            string.format("|cFFFFFFFF%s total|r (|cFFFF9999%s / tick|r)", FormatInt(data.totalDot), FormatDec(data.perTick))
        )
        tooltip:AddDoubleLine(
            string.format("  |cFF00CCFFEfficiency (%s):|r", effLabel),
            string.format("|cFF00CCFF%.2f Dmg / %s|r", data.dpm or data.efficiency or 0, powerLabel)
        )

    -- 1d. HYBRID DIRECT + DOT SPELLS (Flame Shock, Immolate, Moonfire, Holy Fire, Fireball)
    elseif data.type == "spell_hybrid" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Initial Direct Hit:|r",
            string.format("|cFFFFFFFF%s|r", FormatInt(data.directHit))
        )
        tooltip:AddDoubleLine(
            string.format("  |cFFFF6060DoT (%ds / %d Ticks):|r", data.duration or 12, data.ticks or 4),
            string.format("|cFFFFFFFF%s total|r (|cFFFF9999%s / tick|r)", FormatInt(data.dotTotal), FormatDec(data.dotTick))
        )
        tooltip:AddDoubleLine(
            "  |cFF00FF00Combined Total Damage:|r",
            string.format("|cFF00FF00%s|r (|cFF00CCFF%.2f %s|r)", FormatInt(data.totalDmg), data.dpm or 0, effLabel)
        )

    -- 2. SWIPE / THUNDER CLAP / CLEAVE
    elseif data.type == "bear_swipe" or data.type == "war_cleave" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Per-Target Hit:|r",
            string.format("|cFFFFFFFF%s|r", FormatInt(data.singleHit))
        )
        tooltip:AddDoubleLine(
            string.format("  |cFFFFD100%d-Target Cleave Total:|r", data.targets),
            string.format("|cFF00FF00%s|r", FormatInt(data.cleaveTotal))
        )
        if showArmor then
            tooltip:AddDoubleLine(
                string.format("  |cFFFF8040vs Lvl %d Boss (-%s%%):|r", data.bossLevel or 63, FormatDec(data.bossArmorDRPct)),
                string.format("|cFFFFCC80%s|r (1T) / |cFFFFCC80%s|r (%dT)", FormatInt(data.singlePostArmor), FormatInt(data.cleavePostArmor), data.targets)
            )
        end
        tooltip:AddDoubleLine(
            "  |cFF00CCFFEfficiency (DPR):|r",
            string.format("|cFF00CCFF%s|r (1T) / |cFF00FF00%s|r (%dT) Dmg/Rage", FormatDec(data.efficiencySingle), FormatDec(data.efficiencyCleave), data.targets)
        )

    -- 2b. WARRIOR SHIELD BLOCK (Mitigation Per Rage)
    elseif data.type == "war_shield_block" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Physical Mitigated per Block:|r",
            string.format("|cFFFFFFFF%s Dmg|r", FormatInt(data.blockValue))
        )
        tooltip:AddDoubleLine(
            "  |cFF00CCFFMitigation Per Rage (MPR):|r",
            string.format("|cFF00CCFF%.2f Mitigated / Rage|r", data.mitigationPerRage or 0)
        )
        local crushState = (data.newCombatTablePct >= 102.4)
            and "|cFF00FF00UNCRUSHABLE (102.4%+)|r"
            or string.format("|cFFFFCC80%.1f%% / 102.4%%|r", data.newCombatTablePct)
        tooltip:AddDoubleLine("  |cFF00FF00Combat Table w/ Shield Block:|r", crushState)

    -- 3. LACERATE (0 to 5 Stacks Table)
    elseif data.type == "bear_lacerate" then
        tooltip:AddDoubleLine(
            "  |cFFFF6060Existing Stacks|r",
            "|cFFFF6060Bleed Pool (15s)  |  Per-Tick (3s)|r"
        )
        for s = 0, 5 do
            local row = data.stacks[s]
            tooltip:AddDoubleLine(
                string.format("  |cFFFFD100%d %s:|r", s, s == 1 and "Stack" or "Stacks"),
                string.format("|cFFFFFFFF%s total|r  (|cFFFF9999%s / tick|r, %s DPR)", FormatInt(row.totalBleed), FormatDec(row.perTick), FormatDec(row.dpr))
            )
        end
        if showArmor then
            tooltip:AddLine("  |cFF88CC88* Bleed damage ignores Boss Armor (100% effectiveness)|r")
        end

    -- 4. RAKE
    elseif data.type == "cat_rake" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Initial Direct Hit:|r",
            showArmor
                and string.format("|cFFFFFFFF%s|r |cFFFFCC80(%s vs Boss)|r", FormatInt(data.directHit), FormatInt(data.directPostArmor))
                or string.format("|cFFFFFFFF%s|r", FormatInt(data.directHit))
        )
        tooltip:AddDoubleLine(
            "  |cFFFF6060Bleed (9s / 3 Ticks):|r",
            string.format("|cFFFFFFFF%s total|r (|cFFFF9999%s / 3s tick|r)", FormatInt(data.bleedTotal), FormatDec(data.bleedTick))
        )
        tooltip:AddDoubleLine(
            "  |cFF00FF00Total Rake Damage:|r",
            showArmor
                and string.format("|cFF00FF00%s|r |cFFFFCC80(%s vs Boss)|r", FormatInt(data.totalDmg), FormatInt(data.totalPostArmor))
                or string.format("|cFF00FF00%s|r", FormatInt(data.totalDmg))
        )
        tooltip:AddDoubleLine(
            "  |cFF00CCFFEfficiency (DPE):|r",
            string.format("|cFF00CCFF%s Dmg / Energy|r", FormatDec(showArmor and data.efficiencyPostArmor or data.efficiency))
        )

    -- 4b. POUNCE / GARROTE
    elseif data.type == "cat_pounce" or data.type == "melee_bleed" then
        tooltip:AddDoubleLine(
            string.format("  |cFFFF6060Bleed (%ds / %d Ticks):|r", data.duration, data.ticks),
            string.format("|cFFFFFFFF%s total|r (|cFFFF9999%s / 3s tick|r)", FormatInt(data.bleedTotal), FormatDec(data.bleedTick))
        )
        tooltip:AddDoubleLine(
            string.format("  |cFF00CCFFEfficiency (%s):|r", effLabel),
            string.format("|cFF00CCFF%s Dmg / %s|r", FormatDec(data.efficiency), powerLabel)
        )
        if showArmor then
            tooltip:AddLine("  |cFF88CC88* Bleed damage ignores Boss Armor (100% effectiveness)|r")
        end

    -- 5. RIP / RUPTURE (1 to 5 Combo Points Table)
    elseif data.type == "cat_rip" or data.type == "rogue_rupture" then
        tooltip:AddDoubleLine(
            "  |cFFFF6060Combo Points|r",
            "|cFFFF6060Total Bleed  |  Per-Tick|r"
        )
        for cp = 1, 5 do
            local row = data.comboPoints[cp]
            local isCurrent = (currentCP == cp)
            local prefix = isCurrent and "|cFF00FF00> " or "  |cFFFFD100"
            local valColor = isCurrent and "|cFF00FF00" or "|cFFFFFFFF"
            tooltip:AddDoubleLine(
                string.format("%s%d CP:|r", prefix, cp),
                string.format("%s%s total|r  (|cFFFF9999%s / tick|r, %s DPE)", valColor, FormatInt(row.totalBleed), FormatDec(row.perTick), FormatDec(row.dpe))
            )
        end
        if showArmor then
            tooltip:AddLine("  |cFF88CC88* Bleed damage ignores Boss Armor (100% effectiveness)|r")
        end

    -- 6. FEROCIOUS BITE / EVISCERATE (1 to 5 Combo Points Table)
    elseif data.type == "cat_fb" or data.type == "rogue_evis" then
        local energyNote = (data.extraEnergy and data.extraEnergy > 0)
            and string.format("|cFF00CCFF(at %d Energy: +%d extra -> +%s dmg)|r", data.totalEnergyUsed, data.extraEnergy, FormatInt(data.extraDmg))
            or "|cFFAAAAAA(Base 35 Energy)|r"
        tooltip:AddDoubleLine("  |cFFFFD100Combo Points|r", energyNote)

        for cp = 1, 5 do
            local row = data.comboPoints[cp]
            local isCurrent = (currentCP == cp)
            local prefix = isCurrent and "|cFF00FF00> " or "  |cFFFFD100"
            local valColor = isCurrent and "|cFF00FF00" or "|cFFFFFFFF"
            local rightText
            if showArmor then
                rightText = string.format(
                    "%s%s - %s|r |cFFFFCC80(Boss: %s-%s)|r |cFFAAAAAA[%s DPE]|r",
                    valColor, FormatInt(row.minDmg), FormatInt(row.maxDmg),
                    FormatInt(row.minPostArmor), FormatInt(row.maxPostArmor), FormatDec(row.dpe)
                )
            else
                rightText = string.format(
                    "%s%s - %s|r |cFFAAAAAA(Avg: %s, %s DPE)|r",
                    valColor, FormatInt(row.minDmg), FormatInt(row.maxDmg), FormatInt(row.avgDmg), FormatDec(row.dpe)
                )
            end
            tooltip:AddDoubleLine(string.format("%s%d CP:|r", prefix, cp), rightText)
        end

    -- 7. PALADIN HOLY SHIELD (Damage Per Mana + Mitigation Per Mana)
    elseif data.type == "pal_holy_shield" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Holy Damage per Block:|r",
            string.format("|cFFFFFFFF%s|r (%d charges = |cFF00FF00%s total|r)", FormatInt(data.perBlock), data.charges, FormatInt(data.totalAllCharges))
        )
        tooltip:AddDoubleLine(
            "  |cFF00CCFFDamage Per Mana (DPM):|r",
            string.format("|cFF00CCFF%.2f Dmg / Mana|r (all %d blocks)", data.dpm or 0, data.charges)
        )
        tooltip:AddDoubleLine(
            string.format("  |cFFFFD100Mitigation (%d Blocks):|r", data.charges),
            string.format("|cFFFFFFFF%s mitigated|r (|cFF00CCFF%.2f Mitigated / Mana|r)", FormatInt(data.totalMitigated), data.mpm or 0)
        )
        local crushState = (data.newCombatTablePct >= 102.4)
            and "|cFF00FF00UNCRUSHABLE (102.4%+)|r"
            or string.format("|cFFFFCC80%.1f%% / 102.4%%|r", data.newCombatTablePct)
        tooltip:AddDoubleLine("  |cFF00FF00Combat Table w/ Holy Shield:|r", crushState)
        AddRFThreatLine((data.totalAllCharges or 0) * 1.20)

    -- 8. PALADIN CONSECRATION (Damage Per Mana: 1T / 3T / 5T)
    elseif data.type == "pal_consecration" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Single-Target (8s):|r",
            string.format("|cFFFFFFFF%s total|r (|cFFFFCC80%s / tick|r)", FormatInt(data.totalHoly), FormatDec(data.perTick))
        )
        tooltip:AddDoubleLine(
            "  |cFF00FF00AoE Total (3 / 5 Targets):|r",
            string.format("|cFF00FF00%s|r (3T) / |cFF00FF00%s|r (5T)", FormatInt(data.cleave3), FormatInt(data.cleave5))
        )
        tooltip:AddDoubleLine(
            "  |cFF00CCFFDamage Per Mana (DPM):|r",
            string.format("|cFF00CCFF%.2f|r (1T) / |cFF00FF00%.2f|r (3T) / |cFF00FF00%.2f|r (5T)", data.dpm1 or 0, data.dpm3 or 0, data.dpm5 or 0)
        )
        AddRFThreatLine(data.totalHoly)

    -- 9. PALADIN SEALS (Seal of Fury / Seal of Righteousness / Seal of Command)
    elseif data.type == "pal_seal_sof" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Per Swing Holy:|r",
            string.format("|cFFFFFFFF%s|r (%.0f swings = |cFF00FF00%s|r)", FormatDec(data.perHit), data.hits or 15, FormatInt(data.totalDmg))
        )
        tooltip:AddDoubleLine(
            "  |cFF66CCFFShield Absorb (50%):|r",
            string.format("|cFF66CCFF%s/swing|r (|cFF66CCFF%s|r over 30s)", FormatDec(data.absorbPerHit), FormatInt(data.totalAbsorb))
        )
        tooltip:AddDoubleLine(
            "  |cFFFFD100Judgement (3s Taunt):|r",
            string.format("|cFFFFFFFF%s - %s|r |cFFAAAAAA(Avg: %s)|r", FormatInt(data.judgeMin), FormatInt(data.judgeMax), FormatInt(data.judgeAvg))
        )
        tooltip:AddDoubleLine(
            "  |cFF00CCFFDamage Per Mana (DPM):|r",
            string.format("|cFF00CCFF%.2f Dmg / Mana|r (30s total)", data.dpm or 0)
        )
        AddRFThreatLine(data.totalDmg)

    elseif data.type == "pal_seal_sor" or data.type == "pal_seal_soc" then
        local procLabel = (data.type == "pal_seal_soc") and "Per Proc (70% Wpn):" or "Per Swing Holy:"
        local countLabel = (data.type == "pal_seal_soc") and string.format("%.1f procs", data.hits or 3.5) or string.format("%.0f swings", data.hits or 15)
        tooltip:AddDoubleLine(
            "  |cFFFFD100" .. procLabel .. "|r",
            string.format("|cFFFFFFFF%s|r (%s = |cFF00FF00%s|r)", FormatDec(data.perHit), countLabel, FormatInt(data.totalDmg))
        )
        tooltip:AddDoubleLine(
            "  |cFFFFD100Judgement Unleash:|r",
            string.format("|cFFFFFFFF%s - %s|r |cFFAAAAAA(Avg: %s)|r", FormatInt(data.judgeMin), FormatInt(data.judgeMax), FormatInt(data.judgeAvg))
        )
        tooltip:AddDoubleLine(
            "  |cFF00CCFFDamage Per Mana (DPM):|r",
            string.format("|cFF00CCFF%.2f Dmg / Mana|r (30s total)", data.dpm or 0)
        )
        AddRFThreatLine(data.totalDmg)

    -- 10. DIRECT SPELL NUKES & JUDGEMENT (Paladin, Shaman, Warlock, Mage, Priest, Balance Druid)
    elseif data.type == "pal_holy_nuke" or data.type == "pal_judgement" or data.type == "spell_nuke" then
        local dmgTitle = (data.type == "pal_judgement")
            and string.format("Judgement (%s):", data.sealLabel or "SoR")
            or "Spell Damage:"
        tooltip:AddDoubleLine(
            "  |cFFFFD100" .. dmgTitle .. "|r",
            string.format("|cFFFFFFFF%s - %s|r |cFFAAAAAA(Avg: %s)|r", FormatInt(data.minDmg), FormatInt(data.maxDmg), FormatInt(data.avgDmg))
        )
        if (data.targets or 1) > 1 then
            tooltip:AddDoubleLine(
                string.format("  |cFF00FF00%d-Target Cleave Total:|r", data.targets),
                string.format("|cFF00FF00%s|r (|cFF00FF00%.2f %s|r)", FormatInt(data.cleaveTotal), data.dpmCleave or 0, effLabel)
            )
        end
        tooltip:AddDoubleLine(
            "  |cFF00CCFFDamage Per Mana (DPM):|r",
            string.format("|cFF00CCFF%.2f Dmg / Mana|r", data.dpm or 0)
        )
        AddRFThreatLine(data.avgDmg)
    end

    tooltip:Show()
end

-- ============================================================================
-- ITEM TOOLTIP: FULL GEAR UPGRADE PREVIEW (DPS, THREAT, CRIT, DODGE, ARMOR, HP)
-- ============================================================================
local GEAR_EQUIP_SLOTS = {
    INVTYPE_HEAD           = 1,
    INVTYPE_NECK           = 2,
    INVTYPE_SHOULDER       = 3,
    INVTYPE_CHEST          = 5,
    INVTYPE_ROBE           = 5,
    INVTYPE_WAIST          = 6,
    INVTYPE_LEGS           = 7,
    INVTYPE_FEET           = 8,
    INVTYPE_WRIST          = 9,
    INVTYPE_HAND           = 10,
    INVTYPE_FINGER         = { 11, 12 },
    INVTYPE_TRINKET        = { 13, 14 },
    INVTYPE_CLOAK          = 15,
    INVTYPE_WEAPON         = 16,
    INVTYPE_2HWEAPON       = 16,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND  = 17,
    INVTYPE_SHIELD         = 17,
    INVTYPE_HOLDABLE       = 17,
    INVTYPE_RANGED         = 18,
    INVTYPE_RANGEDRIGHT    = 18,
    INVTYPE_THROWN         = 18,
    INVTYPE_RELIC          = 18,
}

local WEAPON_EQUIP_LOCS = {
    INVTYPE_WEAPON         = true,
    INVTYPE_2HWEAPON       = true,
    INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND  = true,
}

local scanTooltip
local function GetItemTooltipScanner()
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", "FeralCalcItemScanTooltip", UIParent, "GameTooltipTemplate")
        scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    return scanTooltip
end

local function ParseTooltipLinesForGear(tt, info)
    if not tt or not tt.GetName then return end
    local ttName = tt:GetName()
    local numLines = tt:NumLines() or 0
    for i = 2, numLines do
        local leftFS = _G[ttName .. "TextLeft" .. i]
        local rightFS = _G[ttName .. "TextRight" .. i]
        local leftText = leftFS and SafeText(leftFS:GetText())
        local rightText = rightFS and SafeText(rightFS:GetText())

        if leftText then
            if info.dps == 0 then
                local dpsStr = leftText:match("%(%s*([%d%.]+)%s+[Dd]amage [Pp]er [Ss]econd%)")
                if dpsStr then info.dps = tonumber(dpsStr) or 0 end
            end
            if info.minDmg == 0 then
                local lo, hi = leftText:match("(%d+)%s*%-%s*(%d+)%s+[Dd]amage")
                if lo and hi then
                    info.minDmg = tonumber(lo) or 0
                    info.maxDmg = tonumber(hi) or 0
                end
            end
            if info.armor == 0 then
                local arm = leftText:match("^(%d+)%s+[Aa]rmor$")
                    or leftText:match("^%+(%d+)%s+[Aa]rmor$")
                if arm then info.armor = tonumber(arm) or 0 end
            end
            if info.equipAP == 0 then
                local apStr = leftText:match("[Ee]quip:.-%+(%d+)%s+[Aa]ttack [Pp]ower")
                    or leftText:match("[Ee]quip:.-(%d+)%s+[Aa]ttack [Pp]ower")
                if apStr then info.equipAP = tonumber(apStr) or 0 end
            end
            if info.str == 0 then
                local s = leftText:match("^%+(%d+)%s+[Ss]trength")
                if s then info.str = tonumber(s) or 0 end
            end
            if info.agi == 0 then
                local a = leftText:match("^%+(%d+)%s+[Aa]gility")
                if a then info.agi = tonumber(a) or 0 end
            end
            if info.sta == 0 then
                local st = leftText:match("^%+(%d+)%s+[Ss]tamina")
                if st then info.sta = tonumber(st) or 0 end
            end
            if info.int == 0 then
                local iv = leftText:match("^%+(%d+)%s+[Ii]ntellect")
                if iv then info.int = tonumber(iv) or 0 end
            end
            if info.critPct == 0 then
                local c = leftText:match("critical strike by ([%d%.]+)%%")
                if c then info.critPct = tonumber(c) or 0 end
            end
            if info.dodgePct == 0 then
                local d = leftText:match("dodge an attack by ([%d%.]+)%%")
                if d then info.dodgePct = tonumber(d) or 0 end
            end
            if info.hitPct == 0 then
                local h = leftText:match("chance to hit by ([%d%.]+)%%")
                if h then info.hitPct = tonumber(h) or 0 end
            end
            if info.defense == 0 then
                local def = leftText:match("[Ii]ncreased [Dd]efense %+(%d+)")
                if def then info.defense = tonumber(def) or 0 end
            end
            if info.health == 0 then
                local hp = leftText:match("^%+(%d+)%s+[Hh]ealth")
                    or leftText:match("[Ee]quip:.-%+(%d+)%s+[Hh]ealth")
                if hp then info.health = tonumber(hp) or 0 end
            end
            if info.spellPower == 0 then
                local sp = leftText:match("magical spells and effects by up to (%d+)")
                if sp then info.spellPower = tonumber(sp) or 0 end
            end
        end

        if rightText and info.speed == 0 then
            local spdStr = rightText:match("[Ss]peed%s+([%d%.]+)")
            if spdStr then info.speed = tonumber(spdStr) or 0 end
        end
    end
end

local function ExtractGearStats(itemLink, visibleTooltip)
    local info = {
        dps = 0,
        speed = 0,
        minDmg = 0,
        maxDmg = 0,
        armor = 0,
        ap = 0,
        equipAP = 0,
        str = 0,
        agi = 0,
        sta = 0,
        int = 0,
        critPct = 0,
        dodgePct = 0,
        hitPct = 0,
        defense = 0,
        health = 0,
        spellPower = 0,
        enchantProcDPS = 0,
        enchantName = nil,
    }

    if FeralCalc and FeralCalc.GetWeaponEnchantBonus then
        local ench = FeralCalc:GetWeaponEnchantBonus(itemLink)
        if ench then
            info.enchantProcDPS = ench.procDPS or 0
            info.enchantName = ench.name
        end
    end

    local getItemStats = (C_Item and type(C_Item.GetItemStats) == "function" and C_Item.GetItemStats)
        or (type(GetItemStats) == "function" and GetItemStats)
    if getItemStats then
        local ok, stats = pcall(getItemStats, itemLink)
        if ok and type(stats) == "table" then
            info.dps = tonumber(stats["ITEM_MOD_DAMAGE_PER_SECOND_SHORT"]) or 0
            info.armor = tonumber(stats["RESISTANCE0_NAME"] or stats["ITEM_MOD_ARMOR_SHORT"]) or 0
            info.ap = (tonumber(stats["ITEM_MOD_ATTACK_POWER_SHORT"]) or 0)
                + (tonumber(stats["ITEM_MOD_FERAL_ATTACK_POWER_SHORT"]) or 0)
            info.str = tonumber(stats["ITEM_MOD_STRENGTH_SHORT"]) or 0
            info.agi = tonumber(stats["ITEM_MOD_AGILITY_SHORT"]) or 0
            info.sta = tonumber(stats["ITEM_MOD_STAMINA_SHORT"]) or 0
            info.int = tonumber(stats["ITEM_MOD_INTELLECT_SHORT"]) or 0
            info.critPct = tonumber(stats["ITEM_MOD_CRIT_RATING_SHORT"] or stats["ITEM_MOD_CRIT_MELEE_RATING_SHORT"]) or 0
            info.dodgePct = tonumber(stats["ITEM_MOD_DODGE_RATING_SHORT"]) or 0
            info.hitPct = tonumber(stats["ITEM_MOD_HIT_RATING_SHORT"] or stats["ITEM_MOD_HIT_MELEE_RATING_SHORT"]) or 0
            info.defense = tonumber(stats["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"]) or 0
            info.health = tonumber(stats["ITEM_MOD_HEALTH_SHORT"]) or 0
            info.spellPower = tonumber(stats["ITEM_MOD_SPELL_POWER_SHORT"] or stats["ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"]) or 0
        end
    end

    if visibleTooltip then
        ParseTooltipLinesForGear(visibleTooltip, info)
    else
        local scanner = GetItemTooltipScanner()
        scanner:ClearLines()
        scanner:SetHyperlink(itemLink)
        ParseTooltipLinesForGear(scanner, info)
    end

    if info.ap == 0 and info.equipAP > 0 then
        info.ap = info.equipAP
    end
    if info.dps == 0 and info.minDmg > 0 and info.maxDmg > 0 and info.speed > 0 then
        info.dps = ((info.minDmg + info.maxDmg) / 2) / info.speed
    end

    return info
end

local function FormatDelta(val, unit, decimals)
    local fmt = decimals and ("%." .. decimals .. "f") or "%.1f"
    local prefix = (val >= 0) and "+" or ""
    local color = (val > 0.005) and "|cFF00FF00" or ((val < -0.005) and "|cFFFF5555" or "|cFFAAAAAA")
    return string.format("%s%s" .. fmt .. "%s|r", color, prefix, val, unit or "")
end

function FeralCalc:AppendItemTooltip(tooltip, tooltipData)
    if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then
        return
    end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then
        return
    end

    local itemName, itemLink
    if type(tooltip.GetItem) == "function" then
        local ok, iName, iLink = pcall(tooltip.GetItem, tooltip)
        if ok then
            itemName = SafeText(iName)
            itemLink = SafeText(iLink)
        end
    end
    if not itemLink then
        return
    end

    if tooltip.feralCalcLastItem == itemLink then
        return
    end

    local getItemInfo = (C_Item and type(C_Item.GetItemInfo) == "function" and C_Item.GetItemInfo)
        or (type(GetItemInfo) == "function" and GetItemInfo)
    if not getItemInfo then
        return
    end

    local okInfo, _, _, _, _, _, _, _, _, equipLoc = pcall(getItemInfo, itemLink)
    local slotMapping = okInfo and equipLoc and GEAR_EQUIP_SLOTS[equipLoc]
    if not slotMapping then
        return
    end

    local equippedLink
    if type(slotMapping) == "table" then
        local link1 = (type(GetInventoryItemLink) == "function") and SafeText(GetInventoryItemLink("player", slotMapping[1]))
        local link2 = (type(GetInventoryItemLink) == "function") and SafeText(GetInventoryItemLink("player", slotMapping[2]))
        if link1 == itemLink or link2 == itemLink then
            return
        end
        equippedLink = link1 or link2
    else
        equippedLink = (type(GetInventoryItemLink) == "function") and SafeText(GetInventoryItemLink("player", slotMapping))
        if equippedLink == itemLink then
            return
        end
    end

    local newGear = ExtractGearStats(itemLink, tooltip)
    local eqGear = equippedLink and ExtractGearStats(equippedLink, nil) or {
        dps = 0, speed = 0, minDmg = 0, maxDmg = 0, armor = 0,
        ap = 0, equipAP = 0, str = 0, agi = 0, sta = 0, int = 0,
        critPct = 0, dodgePct = 0, hitPct = 0, defense = 0, health = 0, spellPower = 0,
    }

    local isWeapon = WEAPON_EQUIP_LOCS[equipLoc]
    if isWeapon and (newGear.dps <= 0 or eqGear.dps <= 0) then
        isWeapon = false
    end

    tooltip.feralCalcLastItem = itemLink

    local s = self:GetMitigationStats()
    local classFile = s.classFile
    local talents = s.talents or {}

    local isDruid = (classFile == "DRUID")
    local isCat = (isDruid and s.formKey == "CAT")
    local isBear = (isDruid and (s.formKey == "BEAR" or s.formKey == "DIRE_BEAR"))

    local strToAP = (classFile == "ROGUE" or classFile == "HUNTER") and 1 or 2
    local agiToAP = (isCat or classFile == "ROGUE" or classFile == "HUNTER") and 1 or 0
    local newAP = newGear.ap + (newGear.str * strToAP) + (newGear.agi * agiToAP)
    local eqAP = eqGear.ap + (eqGear.str * strToAP) + (eqGear.agi * agiToAP)
    local deltaAP = newAP - eqAP

    local newTotalDPS = (isWeapon and (newGear.dps + (newGear.enchantProcDPS or 0)) or 0) + (newAP / 14)
    local eqTotalDPS = (isWeapon and (eqGear.dps + (eqGear.enchantProcDPS or 0)) or 0) + (eqAP / 14)
    local deltaDPS = newTotalDPS - eqTotalDPS

    local levelScale = 60 / math.max(10, s.playerLevel or 60)
    local baseAgiPerCrit = (classFile == "ROGUE") and 29 or ((classFile == "HUNTER") and 53 or 20)
    local baseAgiPerDodge = (classFile == "ROGUE") and 14.5 or ((classFile == "HUNTER") and 26.5 or 20)
    local agiToCrit = (1 / baseAgiPerCrit) * levelScale
    local agiToDodge = (1 / baseAgiPerDodge) * levelScale

    local deltaAgi = newGear.agi - eqGear.agi
    local deltaSta = newGear.sta - eqGear.sta
    local deltaDef = newGear.defense - eqGear.defense
    local deltaHit = newGear.hitPct - eqGear.hitPct
    local deltaSP = newGear.spellPower - eqGear.spellPower

    local deltaCrit = (newGear.critPct - eqGear.critPct) + (deltaAgi * agiToCrit)
    local deltaDodge = (newGear.dodgePct - eqGear.dodgePct) + (deltaAgi * agiToDodge) + (deltaDef * 0.04)

    local bearArmorMult = 1.0
    if s.formKey == "DIRE_BEAR" then
        bearArmorMult = 4.60 * (1 + 0.02 * (talents.thickHide or 0))
    elseif s.formKey == "BEAR" then
        bearArmorMult = 2.80 * (1 + 0.02 * (talents.thickHide or 0))
    end
    local deltaBaseArmor = newGear.armor - eqGear.armor
    local deltaArmor = (deltaBaseArmor * bearArmorMult) + (deltaAgi * 2)

    local hotwMult = isBear and (1 + 0.04 * (talents.heartOfTheWild or 0)) or 1.0
    local deltaHP = (deltaSta * 10 * hotwMult) + (newGear.health - eqGear.health)

    local hasAnyDelta = (math.abs(deltaDPS) > 0.05) or (math.abs(deltaAP) >= 1)
        or (math.abs(deltaCrit) > 0.01) or (math.abs(deltaDodge) > 0.01)
        or (math.abs(deltaArmor) >= 1) or (math.abs(deltaHP) >= 1)
        or (math.abs(deltaHit) > 0.01) or (math.abs(deltaDef) >= 1)
        or (math.abs(deltaSP) >= 1)
    if not hasAnyDelta then
        return
    end

    tooltip:AddLine(" ")

    if isDruid then
        local normSpeed = isCat and 1.00 or 2.50
        local modeLabel = isCat and "Cat Paw (1.00s)" or "Bear Paw (2.50s)"
        local deltaSwing = deltaDPS * normSpeed

        tooltip:AddLine(string.format("|cFFFF7D0AForeverStats:|r |cFFFFFFFF%s vs Equipped|r", modeLabel))
        if math.abs(deltaDPS) > 0.05 or math.abs(deltaAP) >= 1 then
            local dmgLabel = isWeapon and "Weapon+AP DPS:" or "Attack Power / DPS:"
            local extra = isWeapon and string.format("(%s/hit)", FormatDelta(deltaSwing, " Dmg", 1))
                or string.format("(%s AP, %s/hit)", FormatDelta(deltaAP, "", 0), FormatDelta(deltaSwing, " Dmg", 1))
            tooltip:AddDoubleLine(
                "  |cFFFFD100" .. dmgLabel .. "|r",
                string.format("%s |cFFAAAAAA%s|r", FormatDelta(deltaDPS, " DPS", 1), extra)
            )
        end

        if not isCat and math.abs(deltaDPS) > 0.05 then
            local bearThreatMult = 1.30 * (1 + 0.03 * (talents.feralInstinct or 0))
            local deltaTPS = deltaDPS * bearThreatMult
            local deltaWhiteThreat = deltaSwing * bearThreatMult

            tooltip:AddDoubleLine(
                "  |cFFFF8040Bear Threat:|r",
                string.format("%s |cFFAAAAAA(%s/hit)|r", FormatDelta(deltaTPS, " TPS", 1), FormatDelta(deltaWhiteThreat, "", 1))
            )
            if isWeapon then
                local deltaMaulThreat = deltaSwing * 1.75 * bearThreatMult
                tooltip:AddDoubleLine(
                    "  |cFFFF8040Maul Threat (1.75x):|r",
                    FormatDelta(deltaMaulThreat, " Threat/hit", 1)
                )
            end
        end
    else
        local headerLabel = isWeapon and "Weapon Comparison" or "Gear Comparison"
        tooltip:AddLine(string.format("|cFFFF7D0AForeverStats:|r |cFFFFFFFF%s|r", headerLabel))
        if math.abs(deltaDPS) > 0.05 or math.abs(deltaAP) >= 1 then
            local newSpeed = (newGear.speed > 0) and newGear.speed or 2.0
            local eqSpeed = (eqGear.speed > 0) and eqGear.speed or 2.0
            local deltaSwing = isWeapon and ((newTotalDPS * newSpeed) - (eqTotalDPS * eqSpeed)) or 0
            local rightText = isWeapon
                and string.format("%s |cFFAAAAAA(%s/swing)|r", FormatDelta(deltaDPS, " DPS", 1), FormatDelta(deltaSwing, " Dmg", 1))
                or string.format("%s |cFFAAAAAA(%s AP)|r", FormatDelta(deltaDPS, " DPS", 1), FormatDelta(deltaAP, "", 0))
            tooltip:AddDoubleLine("  |cFFFFD100Damage / AP:|r", rightText)
        end

        if (classFile == "WARRIOR" or classFile == "PALADIN" or classFile == "SHAMAN") and math.abs(deltaDPS) > 0.05 then
            local threatMult = 1.0
            if classFile == "WARRIOR" then
                threatMult = 1.30 * (1 + 0.03 * (talents.defiance or 0))
            elseif classFile == "PALADIN" then
                threatMult = select(1, self:GetRighteousFuryMultipliers(talents))
            end
            tooltip:AddDoubleLine(
                "  |cFFFF8040Tank Threat:|r",
                FormatDelta(deltaDPS * threatMult, " TPS", 1)
            )
        end
    end

    if math.abs(deltaSP) >= 1 then
        tooltip:AddDoubleLine("  |cFF00CCFFSpell Power:|r", FormatDelta(deltaSP, " SP", 0))
    end
    if math.abs(deltaCrit) > 0.01 then
        tooltip:AddDoubleLine("  |cFFFFCC00Crit Chance:|r", FormatDelta(deltaCrit, "%", 2))
    end
    if math.abs(deltaHit) > 0.01 then
        tooltip:AddDoubleLine("  |cFFFFCC00Hit Chance:|r", FormatDelta(deltaHit, "%", 1))
    end
    if math.abs(deltaDodge) > 0.01 then
        tooltip:AddDoubleLine("  |cFF66FF99Dodge Chance:|r", FormatDelta(deltaDodge, "%", 2))
    end
    if math.abs(deltaDef) >= 1 then
        tooltip:AddDoubleLine("  |cFF66FF99Defense:|r", FormatDelta(deltaDef, " Def", 0))
    end
    if math.abs(deltaArmor) >= 1 then
        local armorText = (bearArmorMult > 1.0 and math.abs(deltaBaseArmor) >= 1)
            and string.format("%s |cFFAAAAAA(%s base)|r", FormatDelta(deltaArmor, " Armor", 0), FormatDelta(deltaBaseArmor, "", 0))
            or FormatDelta(deltaArmor, " Armor", 0)
        tooltip:AddDoubleLine("  |cFFCCCCCCArmor:|r", armorText)
    end
    if math.abs(deltaHP) >= 1 then
        tooltip:AddDoubleLine(
            "  |cFF00CCFFHitpoints:|r",
            string.format("%s |cFFAAAAAA(%s Sta)|r", FormatDelta(deltaHP, " HP", 0), FormatDelta(deltaSta, "", 0))
        )
    end
    if isWeapon and ((newGear.enchantProcDPS or 0) > 0 or (eqGear.enchantProcDPS or 0) > 0) then
        local deltaEnch = (newGear.enchantProcDPS or 0) - (eqGear.enchantProcDPS or 0)
        tooltip:AddDoubleLine(
            "  |cFFFF8040Enchant Proc DPS:|r",
            FormatDelta(deltaEnch, " DPS", 1)
        )
    end

    tooltip:Show()
end

if type(TooltipDataProcessor) == "table" and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and type(Enum) == "table" and type(Enum.TooltipDataType) == "table" then
    if Enum.TooltipDataType.Spell then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
            if tooltip == GameTooltip then
                tooltip.feralCalcLastSpell = nil
                FeralCalc:AppendSpellTooltip(tooltip, data)
            end
        end)
    end
    if Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip == GameTooltip or tooltip == ItemRefTooltip then
                tooltip.feralCalcLastItem = nil
                FeralCalc:AppendItemTooltip(tooltip, data)
            end
        end)
    end
end

if GameTooltip and GameTooltip.HookScript then
    pcall(function()
        GameTooltip:HookScript("OnTooltipSetSpell", function(self)
            FeralCalc:AppendSpellTooltip(self, nil)
        end)
    end)
    pcall(function()
        GameTooltip:HookScript("OnTooltipSetItem", function(self)
            FeralCalc:AppendItemTooltip(self, nil)
        end)
    end)
    pcall(function()
        GameTooltip:HookScript("OnTooltipCleared", function(self)
            self.feralCalcLastSpell = nil
            self.feralCalcLastItem = nil
        end)
    end)
    pcall(function()
        GameTooltip:HookScript("OnHide", function(self)
            self.feralCalcLastSpell = nil
            self.feralCalcLastItem = nil
        end)
    end)
end

if ItemRefTooltip and ItemRefTooltip.HookScript then
    pcall(function()
        ItemRefTooltip:HookScript("OnTooltipSetItem", function(self)
            FeralCalc:AppendItemTooltip(self, nil)
        end)
    end)
    pcall(function()
        ItemRefTooltip:HookScript("OnTooltipCleared", function(self)
            self.feralCalcLastItem = nil
        end)
    end)
    pcall(function()
        ItemRefTooltip:HookScript("OnHide", function(self)
            self.feralCalcLastItem = nil
        end)
    end)
end
