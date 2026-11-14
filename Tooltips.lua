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

    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(
        string.format("|cFFFF7D0AForeverStats:|r |cFFFFFFFF%s (Rank %d)|r", data.name, data.rank or 1),
        string.format("|cFFAAAAAA%d %s|r", data.cost or 0, powerLabel)
    )

    if data.classFile == "DRUID" then
        local isBearSpell = data.type:find("^bear_") ~= nil
        local isCatSpell = data.type:find("^cat_") ~= nil
        if isBearSpell and data.formKey ~= "BEAR" and data.formKey ~= "DIRE_BEAR" then
            tooltip:AddLine("|cFF888888(Using current form weapon dmg; shift to Bear for 2.5s norm)|r")
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

    -- 9. DIRECT SPELL NUKES (Paladin, Shaman, Warlock, Mage, Priest, Balance Druid)
    elseif data.type == "pal_holy_nuke" or data.type == "spell_nuke" then
        tooltip:AddDoubleLine(
            "  |cFFFFD100Spell Damage:|r",
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
    end

    tooltip:Show()
end

if type(TooltipDataProcessor) == "table" and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and type(Enum) == "table" and type(Enum.TooltipDataType) == "table" and Enum.TooltipDataType.Spell then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
        if tooltip == GameTooltip then
            tooltip.feralCalcLastSpell = nil
            FeralCalc:AppendSpellTooltip(tooltip, data)
        end
    end)
end

if GameTooltip and GameTooltip.HookScript then
    pcall(function()
        GameTooltip:HookScript("OnTooltipSetSpell", function(self)
            FeralCalc:AppendSpellTooltip(self, nil)
        end)
    end)
    pcall(function()
        GameTooltip:HookScript("OnTooltipCleared", function(self)
            self.feralCalcLastSpell = nil
        end)
    end)
    pcall(function()
        GameTooltip:HookScript("OnHide", function(self)
            self.feralCalcLastSpell = nil
        end)
    end)
end
