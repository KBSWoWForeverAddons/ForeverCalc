local addonName, FeralCalc = ...

local function FormatNumber(n)
    local formatted = tostring(math.floor((n or 0) + 0.5))
    while true do
        local k
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local PANE_WIDTH = 284
local PANE_HEIGHT = 536

function FeralCalc:CreateCharacterPane()
    if self.paneCreated or not PaperDollFrame then
        return
    end
    self.paneCreated = true
    self:InitDB()

    -- 1. Toggle Button on PaperDollItemsFrame / PaperDollFrame labeled "Tank"
    local buttonParent = PaperDollItemsFrame or PaperDollFrame
    local toggleBtn = CreateFrame("Button", "FeralCalcToggleButton", buttonParent, "UIPanelButtonTemplate")
    toggleBtn:SetSize(56, 22)
    if CharacterWristSlot then
        toggleBtn:SetPoint("TOPLEFT", CharacterWristSlot, "BOTTOMLEFT", -4, -18)
    else
        toggleBtn:SetPoint("BOTTOMLEFT", buttonParent, "BOTTOMLEFT", 18, 14)
    end
    toggleBtn:SetFrameLevel((buttonParent:GetFrameLevel() or 1) + 10)
    toggleBtn:SetText("Stats")
    toggleBtn:SetScript("OnClick", function()
        FeralCalc:ToggleCharacterPane(false)
    end)
    toggleBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("ForeverCalc", 1.0, 0.49, 0.04)
        GameTooltip:AddLine("Click to toggle mitigation, avoidance, hit/crit caps, and offense stats.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    toggleBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    self.toggleButton = toggleBtn

    -- 2. Main Docked Side Pane on PaperDollFrame
    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    local pane = CreateFrame("Frame", "FeralCalcCharacterPane", PaperDollFrame, backdropTemplate)
    pane:SetSize(PANE_WIDTH, PANE_HEIGHT)
    -- Clear the vertical sidebar tab buttons on the right edge of Forever's CharacterFrame
    local xOffset = CharacterStatsPane and 50 or -32
    local yPaneOffset = CharacterStatsPane and 0 or -12
    pane:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", xOffset, yPaneOffset)
    pane:SetFrameStrata("HIGH")
    pane:SetFrameLevel((CharacterFrame:GetFrameLevel() or 1) + 10)

    if pane.SetBackdrop then
        pane:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        })
        pane:SetBackdropColor(0.06, 0.06, 0.08, 0.94)
        pane:SetBackdropBorderColor(0.85, 0.75, 0.55, 1.0)
    end

    -- Close Button in top-right corner of the pane
    local closeBtn = CreateFrame("Button", nil, pane, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        FeralCalc:ToggleCharacterPane(false)
    end)

    -- Pet Stats Button in top-left corner of the pane (Hunters & Warlocks)
    local petBtn = CreateFrame("Button", "FeralCalcPetToggleButton", pane, "UIPanelButtonTemplate")
    petBtn:SetSize(42, 20)
    petBtn:SetPoint("TOPLEFT", pane, "TOPLEFT", 10, -10)
    petBtn:SetText("Pet")
    petBtn:SetScript("OnClick", function()
        FeralCalc:TogglePetPane()
    end)
    petBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Pet Mitigation & Threat", 1.0, 0.49, 0.04)
        GameTooltip:AddLine("Click to open or close the separate Pet Stats pane (Hunters & Warlocks).", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    petBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    pane.petBtn = petBtn
    local initClass = select(1, self:GetPlayerClass())
    if initClass == "HUNTER" or initClass == "WARLOCK" then
        petBtn:Show()
    else
        petBtn:Hide()
    end

    -- Title Banner
    local titleText = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", pane, "TOP", 0, -14)
    titleText:SetText("|cFFFF7D0AForeverCalc|r")
    pane.titleText = titleText

    -- Form / Stance & Max HP Subheader Box
    local headerBox = CreateFrame("Frame", nil, pane, backdropTemplate)
    headerBox:SetSize(PANE_WIDTH - 24, 44)
    headerBox:SetPoint("TOP", pane, "TOP", 0, -34)
    if headerBox.SetBackdrop then
        headerBox:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        headerBox:SetBackdropColor(0.14, 0.11, 0.08, 0.9)
        headerBox:SetBackdropBorderColor(0.6, 0.45, 0.2, 0.9)
    end

    local formLabel = headerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    formLabel:SetPoint("TOPLEFT", headerBox, "TOPLEFT", 10, -7)
    formLabel:SetText("Form / Stance:")

    local formValue = headerBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    formValue:SetPoint("TOPRIGHT", headerBox, "TOPRIGHT", -10, -7)

    local hpLabel = headerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hpLabel:SetPoint("BOTTOMLEFT", headerBox, "BOTTOMLEFT", 10, 7)
    hpLabel:SetText("Max Health:")

    local hpValue = headerBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hpValue:SetPoint("BOTTOMRIGHT", headerBox, "BOTTOMRIGHT", -10, 7)

    pane.formLabel = formLabel
    pane.formValue = formValue
    pane.hpValue = hpValue
    pane.rows = {}
    pane.leftLabels = {}
    pane.sections = {}

    local yOffset = -84
    local currentSection = nil

    local function AddSectionHeader(key, text)
        yOffset = yOffset - 8

        local headerBtn = CreateFrame("Button", nil, pane)
        headerBtn:SetSize(PANE_WIDTH - 28, 18)
        headerBtn:SetPoint("TOPLEFT", pane, "TOPLEFT", 14, yOffset)

        local highlight = headerBtn:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 0.82, 0, 0.10)
        highlight:Hide()

        local indicator = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        indicator:SetPoint("RIGHT", headerBtn, "RIGHT", -2, 0)
        indicator:SetText("|cFFFFD100[-]|r")

        local hdr = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        hdr:SetPoint("LEFT", headerBtn, "LEFT", 0, 0)
        hdr:SetText(text)
        hdr:SetTextColor(1.0, 0.49, 0.04)

        local line = headerBtn:CreateTexture(nil, "ARTWORK")
        line:SetHeight(2)
        line:SetPoint("TOPLEFT", headerBtn, "TOPLEFT", 0, -15)
        line:SetPoint("TOPRIGHT", headerBtn, "TOPRIGHT", 0, -15)
        line:SetColorTexture(0.7, 0.55, 0.25, 0.85)

        local sec = {
            key = key,
            headerBtn = headerBtn,
            title = hdr,
            indicator = indicator,
            rows = {},
        }
        table.insert(pane.sections, sec)
        currentSection = sec

        headerBtn:SetScript("OnEnter", function()
            highlight:Show()
        end)
        headerBtn:SetScript("OnLeave", function()
            highlight:Hide()
        end)
        headerBtn:SetScript("OnClick", function()
            FeralCalc:InitDB()
            local charKey = FeralCalc:GetCharacterKey()
            FeralCalc.db.collapsedSectionsByChar = FeralCalc.db.collapsedSectionsByChar or {}
            FeralCalc.db.collapsedSectionsByChar[charKey] = FeralCalc.db.collapsedSectionsByChar[charKey] or {}
            local collapsed = FeralCalc:GetSectionCollapsed(key, FeralCalc.lastStats)
            FeralCalc.db.collapsedSectionsByChar[charKey][key] = not collapsed
            FeralCalc:LayoutCharacterPane()
        end)

        yOffset = yOffset - 20
        return hdr
    end

    local function AddStatRow(key, labelText, tooltipTitle, tooltipFunc)
        local row = CreateFrame("Frame", nil, pane)
        row:SetSize(PANE_WIDTH - 28, 18)
        row:SetPoint("TOPLEFT", pane, "TOPLEFT", 14, yOffset)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 0.82, 0, 0.12)
        highlight:Hide()

        local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        left:SetPoint("LEFT", row, "LEFT", 2, 0)
        left:SetText(labelText)

        local right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        right:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        right:SetText("-")

        if tooltipTitle or tooltipFunc then
            row:EnableMouse(true)
            row:SetScript("OnEnter", function(selfRow)
                highlight:Show()
                GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                if tooltipTitle then
                    GameTooltip:SetText(tooltipTitle, 1.0, 0.82, 0.0)
                end
                if tooltipFunc and FeralCalc.lastStats then
                    tooltipFunc(GameTooltip, FeralCalc.lastStats)
                end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                highlight:Hide()
                GameTooltip:Hide()
            end)
        end

        pane.rows[key] = right
        pane.leftLabels[key] = left
        if currentSection then
            table.insert(currentSection.rows, row)
        end
        yOffset = yOffset - 18
    end

    -- =========================================================================
    -- SECTION 1: MITIGATION & HEALTH
    -- =========================================================================
    AddSectionHeader("mitigation", "Mitigation & Health")

    AddStatRow("armor", "Armor:", "Effective Armor", function(tt, s)
        tt:AddDoubleLine("Base Armor:", FormatNumber(s.baseArmor), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Effective Armor:", FormatNumber(s.effectiveArmor), 1, 1, 1, 0, 1, 0)
    end)

    AddStatRow("dr60", "DR vs Equal Lvl:", "Damage Reduction (Equal Level)", function(tt, s)
        tt:AddLine(string.format("Formula (vs Lvl %d): Armor / (Armor + %d)", s.playerLevel, s.armorConstEqual), 0.8, 0.8, 0.8)
        tt:AddDoubleLine("75% Cap Target:", FormatNumber(s.armorCapEqual) .. " Armor", 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine(string.format("Armor to Lvl %d Cap:", s.playerLevel), FormatNumber(s.armorNeeded60), 1, 1, 1, 1, 1, 1)
    end)

    AddStatRow("dr63", "DR vs +3 Boss:", "Damage Reduction (vs +3 Boss)", function(tt, s)
        tt:AddLine(string.format("Formula (vs Lvl %d): Armor / (Armor + %d)", s.bossLevel, s.armorConstBoss), 0.8, 0.8, 0.8)
        tt:AddDoubleLine(string.format("Armor DR (vs Lvl %d):", s.bossLevel), string.format("%.2f%%", s.dr63Pct), 1, 1, 1, 1, 1, 1)
        if s.stanceDmgMult ~= 1.0 then
            tt:AddDoubleLine("Total Physical DR (w/ Stance):", string.format("%.2f%%", s.effectiveDR63Pct), 1, 1, 1, 0, 1, 0)
        end
        tt:AddDoubleLine("75% Armor Cap Target:", FormatNumber(s.armorCapBoss) .. " Armor", 1, 1, 1, 1, 0.82, 0)
    end)

    AddStatRow("armorCap", "Armor Cap (Boss):", "75% Armor Cap Progress", function(tt, s)
        tt:AddDoubleLine(string.format("vs Lvl %d Boss (%s):", s.bossLevel, FormatNumber(s.armorCapBoss)), string.format("%.1f%% (%s needed)", s.capProgress63, FormatNumber(s.armorNeeded63)), 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine(string.format("vs Lvl %d Mob (%s):", s.playerLevel, FormatNumber(s.armorCapEqual)), string.format("%.1f%% (%s needed)", s.capProgress60, FormatNumber(s.armorNeeded60)), 1, 1, 1, 0.8, 0.8, 0.8)
    end)

    AddStatRow("ehp", "Physical EHP (Boss):", "Effective Health (EHP)", function(tt, s)
        tt:AddLine("Physical EHP = MaxHP / (1 - TotalPhysicalDR)", 0.8, 0.8, 0.8)
        tt:AddDoubleLine(string.format("Physical EHP (vs Lvl %d):", s.bossLevel), FormatNumber(s.physicalEHP), 1, 1, 1, 0, 1, 0)
        tt:AddDoubleLine(string.format("Physical EHP (vs Lvl %d):", s.playerLevel), FormatNumber(s.physicalEHP60), 1, 1, 1, 0.8, 0.8, 0.8)
        tt:AddDoubleLine("Avoidance-Adjusted EHP:", FormatNumber(s.avoidanceEHP), 1, 1, 1, 0, 0.8, 1)
    end)

    AddStatRow("avoidEhp", "Avoidance EHP:", "Avoidance-Adjusted EHP", function(tt, s)
        tt:AddLine("Formula: Physical EHP / (1 - (Miss% + Dodge% + Parry%))", 0.8, 0.8, 0.8)
        tt:AddDoubleLine("Pure Avoidance:", string.format("%.2f%%", s.totalAvoidancePct), 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine("Avoidance-Adjusted EHP:", FormatNumber(s.avoidanceEHP), 1, 1, 1, 0, 0.8, 1)
    end)

    -- =========================================================================
    -- SECTION 2: AVOIDANCE & BOSS TABLE
    -- =========================================================================
    AddSectionHeader("avoidance", "Avoidance & Boss Table")

    AddStatRow("defense", "Defense Skill:", "Defense Skill", function(tt, s)
        tt:AddDoubleLine("Base Defense:", tostring(s.baseDefense), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Bonus Defense:", string.format("+%d", math.floor(s.armorDefense + 0.5)), 1, 1, 1, 0, 1, 0)
        tt:AddLine("Each point of Defense grants +0.04% Miss, +0.04% Dodge, +0.04% Parry, +0.04% Block, and -0.04% Boss Crit.", 0.8, 0.8, 0.8, true)
    end)

    AddStatRow("dodge", "Dodge Chance:", "Dodge Percentage", function(tt, s)
        tt:AddDoubleLine("Exact Dodge:", string.format("%.2f%%", s.dodgePct), 1, 1, 1, 1, 1, 1)
    end)

    AddStatRow("parry", "Parry Chance:", "Parry Percentage", function(tt, s)
        if s.canParry then
            tt:AddDoubleLine("Exact Parry:", string.format("%.2f%%", s.parryPct), 1, 1, 1, 1, 1, 1)
        else
            local msg = (s.classFile == "DRUID") and "Druids cannot Parry attacks." or "This class cannot Parry attacks."
            tt:AddLine(msg, 0.7, 0.7, 0.7, true)
        end
    end)

    AddStatRow("block", "Block Chance:", "Shield Block Percentage & Value", function(tt, s)
        if s.canBlock then
            tt:AddDoubleLine("Block Chance:", string.format("%.2f%%", s.blockPct), 1, 1, 1, 1, 1, 1)
            tt:AddDoubleLine("Block Value:", FormatNumber(s.blockValue), 1, 1, 1, 1, 0.82, 0)
            tt:AddLine("Blocked attacks cannot be Critical Hits or Crushing Blows.", 0.8, 0.8, 0.8, true)
        else
            tt:AddLine("Druids cannot equip shields or Block attacks.", 0.7, 0.7, 0.7, true)
        end
    end)

    AddStatRow("bossMiss", "Boss Miss Chance:", "Enemy Miss Chance", function(tt, s)
        tt:AddLine(string.format("Formula vs Lvl %d: 5.0%% + (Defense - %d) * 0.04%%", s.bossLevel, s.bossDefense), 0.8, 0.8, 0.8)
        tt:AddDoubleLine(string.format("vs Lvl %d Boss (%d WS):", s.bossLevel, s.bossDefense), string.format("%.2f%%", s.bossMissPct), 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine(string.format("vs Lvl %d Mob (%d WS):", s.playerLevel, s.equalDefense), string.format("%.2f%%", s.equalMissPct), 1, 1, 1, 0.8, 0.8, 0.8)
    end)

    AddStatRow("totalAvoid", "Total Avoidance:", "Avoidance & Combat Table Coverage", function(tt, s)
        tt:AddDoubleLine("Boss Miss %:", string.format("%.2f%%", s.bossMissPct), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Dodge %:", string.format("%.2f%%", s.dodgePct), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Parry %:", string.format("%.2f%%", s.parryPct), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Pure Avoidance (No Hit):", string.format("%.2f%%", s.totalAvoidancePct), 1, 1, 1, 0, 1, 0)
        if s.canBlock then
            tt:AddLine(" ")
            tt:AddDoubleLine("Block %:", string.format("%.2f%%", s.blockPct), 1, 1, 1, 1, 0.82, 0)
            tt:AddDoubleLine("Total Table (w/ Block):", string.format("%.2f%% / 102.4%%", s.combatTablePct), 1, 1, 1, 0, 0.8, 1)
        end
    end)

    AddStatRow("bossCrit", "Boss Crit Chance:", "Boss Critical Strike Chance (+3 Lvl)", function(tt, s)
        tt:AddLine(string.format("Formula: 5.0%% + (%d - Defense) * 0.04%%", s.bossDefense), 0.8, 0.8, 0.8)
        tt:AddDoubleLine(string.format("Crit Immunity Cap (Lvl %d):", s.bossLevel), string.format("%d Defense", s.critImmuneDef), 1, 1, 1, 1, 0.82, 0)
    end)

    AddStatRow("critImmunity", "Crit Immunity:", "Boss Crit Immunity (+3 Lvl)", function(tt, s)
        if s.isCritImmune then
            tt:AddLine(string.format("You are Crit Immune against Level %d Bosses!", s.bossLevel), 0, 1, 0, true)
        else
            tt:AddDoubleLine(string.format("Defense Needed (vs Lvl %d):", s.bossLevel), string.format("%d more Defense", s.defNeededForCrit), 1, 1, 1, 1, 0.4, 0.4)
        end
    end)

    AddStatRow("bossCrush", "Boss Crush Chance:", "Boss Crushing Blows (1.5x Dmg)", function(tt, s)
        tt:AddLine(string.format("Level %d Bosses (%d WS) have a 15.0%% base chance to land Crushing Blows.", s.bossLevel, s.bossDefense), 0.85, 0.85, 0.85, true)
        tt:AddLine("Reaching 102.4% combined Miss + Dodge + Parry + Block pushes Crushing Blows completely off the attack table.", 1, 0.82, 0, true)
        tt:AddDoubleLine("Current Table Coverage:", string.format("%.2f%% / 102.4%%", s.combatTablePct), 1, 1, 1, 0, 0.8, 1)
        tt:AddDoubleLine("Needed for Crush Cap:", string.format("%.2f%%", s.avoidanceToCrushCap), 1, 1, 1, 1, 0.5, 0.2)
    end)

    -- =========================================================================
    -- SECTION 3: OFFENSE (Dynamically switches for Tank/Melee, Hunter, & Caster)
    -- =========================================================================
    pane.offenseHeader = AddSectionHeader("offense", "Tank Offense")

    AddStatRow("weaponDmg", "Weapon Damage:", "Weapon Damage & Speed", function(tt, s)
        if s.classFile == "HUNTER" and (s.rangedSpeed or 0) > 0 then
            tt:AddDoubleLine("Ranged Damage:", string.format("%.1f - %.1f (%.2fs)", s.rangedLow, s.rangedHi, s.rangedSpeed), 1, 1, 1, 1, 0.82, 0)
        end
        tt:AddDoubleLine("Melee Damage:", string.format("%.1f - %.1f (%.2fs)", s.lowDmg, s.hiDmg, s.mainSpeed), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Average Melee Hit:", string.format("%.1f", s.avgDmg), 1, 1, 1, 1, 0.82, 0)
        if s.mainSpeed and s.mainSpeed > 0 then
            tt:AddDoubleLine("Melee Swing DPS:", string.format("%.1f DPS", s.avgDmg / s.mainSpeed), 1, 1, 1, 0.8, 0.8, 0.8)
        end
        local function ShowEnchantLine(slotLabel, ench)
            if not ench then return end
            if (ench.procDPS or 0) > 0 then
                local mult = s.enchantThreatMult or 1.0
                tt:AddDoubleLine(
                    string.format("%s Enchant (%s):", slotLabel, ench.name),
                    string.format("+%.1f DPS (+%.1f TPS)", ench.procDPS, ench.procDPS * mult),
                    1, 1, 1, 1, 0.5, 0.2
                )
            elseif (ench.flatDmg or 0) > 0 then
                tt:AddDoubleLine(
                    string.format("%s Enchant:", slotLabel),
                    string.format("+%d Wpn Dmg (in melee dmg)", ench.flatDmg),
                    1, 1, 1, 0.6, 0.9, 1
                )
            end
        end
        ShowEnchantLine("MH", s.mhEnchant)
        ShowEnchantLine("OH", s.ohEnchant)
        if s.classFile == "DRUID" then
            tt:AddLine(" ")
            tt:AddLine("Bear/Dire Bear normalizes swing speed to 2.50s (Cat Form: 1.00s).", 0.85, 0.85, 0.85, true)
            tt:AddLine("Base Bear paw damage = Listed Weapon DPS x 2.50s (slow weapons compress to 2.50s; 1 Weapon DPS ~= 14 AP).", 0.7, 0.7, 0.7, true)
        end
    end)

    AddStatRow("attackPower", "Attack Power:", "Attack Power & Spell Damage", function(tt, s)
        if s.isCaster or (s.maxSpellPower or 0) > 0 then
            local sp = s.spellPowerBySchool or {}
            tt:AddDoubleLine("Holy Spell Damage:", string.format("+%d", sp[2] or 0), 1, 1, 1, 1, 0.9, 0.5)
            tt:AddDoubleLine("Fire Spell Damage:", string.format("+%d", sp[3] or 0), 1, 1, 1, 1, 0.5, 0.2)
            tt:AddDoubleLine("Nature Spell Damage:", string.format("+%d", sp[4] or 0), 1, 1, 1, 0.4, 1, 0.4)
            tt:AddDoubleLine("Frost Spell Damage:", string.format("+%d", sp[5] or 0), 1, 1, 1, 0.4, 0.8, 1)
            tt:AddDoubleLine("Shadow Spell Damage:", string.format("+%d", sp[6] or 0), 1, 1, 1, 0.75, 0.5, 1)
            tt:AddDoubleLine("Arcane Spell Damage:", string.format("+%d", sp[7] or 0), 1, 1, 1, 0.8, 0.9, 1)
            tt:AddLine(" ")
        end
        if s.classFile == "HUNTER" then
            tt:AddDoubleLine("Ranged Attack Power:", FormatNumber(s.rangedAP), 1, 1, 1, 0, 1, 0)
        end
        tt:AddDoubleLine("Melee Attack Power:", FormatNumber(s.totalAP), 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine("Bonus DPS from Melee AP:", string.format("+%.1f DPS", s.totalAP / 14), 1, 1, 1, 0.8, 0.8, 0.8)
        if s.classFile == "DRUID" then
            tt:AddDoubleLine("Bonus Bear Paw Hit (2.50s):", string.format("+%.1f Dmg/hit", (s.totalAP / 14) * 2.5), 1, 1, 1, 1, 0.82, 0)
            tt:AddLine("14 AP = 1 DPS (+2.5 dmg per 2.50s Bear swing; 1 Weapon DPS ~= 14 AP).", 0.7, 0.7, 0.7, true)
        end
    end)

    AddStatRow("critChance", "Melee Crit Chance:", "Critical Strike Chance", function(tt, s)
        tt:AddDoubleLine("Melee Crit:", string.format("%.2f%%", s.meleeCritPct), 1, 1, 1, 1, 1, 1)
        if s.classFile == "HUNTER" then
            tt:AddDoubleLine("Ranged Crit:", string.format("%.2f%%", s.rangedCritPct or s.meleeCritPct), 1, 1, 1, 0, 1, 0)
        end
        if s.isCaster or (s.spellCritPct or 0) > 0 then
            tt:AddDoubleLine("Spell Crit:", string.format("%.2f%%", s.spellCritPct or 0), 1, 1, 1, 0.4, 0.8, 1)
        end
    end)

    AddStatRow("hitChance", "Bonus Melee Hit:", "Bonus Hit Chance", function(tt, s)
        if s.isCaster then
            tt:AddDoubleLine("Bonus Spell Hit:", string.format("+%.1f%%", s.spellHitPct or 0), 1, 1, 1, 0, 1, 0)
            if (s.talentSpellHit or 0) > 0 then
                tt:AddDoubleLine("  From Talents:", string.format("+%.1f%%", s.talentSpellHit), 0.8, 0.8, 0.8, 0.4, 0.8, 1)
            end
            tt:AddDoubleLine(string.format("Lvl %d Boss Spell Hit Cap:", s.bossLevel), "16.0% (1% min resist)", 1, 1, 1, 1, 0.82, 0)
            tt:AddDoubleLine(string.format("Lvl %d Mob Spell Hit Cap:", s.playerLevel), "3.0% (1% min resist)", 1, 1, 1, 0.8, 0.8, 0.8)
        else
            local hitVal = (s.classFile == "HUNTER") and (s.rangedHitPct or s.meleeHitPct) or s.meleeHitPct
            local talHit = (s.classFile == "HUNTER") and (s.talentRangedHit or 0) or (s.talentMeleeHit or 0)
            tt:AddDoubleLine("Bonus Melee/Ranged Hit:", string.format("+%.1f%%", hitVal), 1, 1, 1, 0, 1, 0)
            if talHit > 0 then
                tt:AddDoubleLine("  From Talents:", string.format("+%.1f%%", talHit), 0.8, 0.8, 0.8, 0.4, 0.8, 1)
            end
            if s.isDualWield then
                tt:AddDoubleLine(string.format("Lvl %d Boss Yellow Cap (%d Def):", s.bossLevel, s.bossDefense), string.format("9.0%% (8.0%% with %d WS)", s.equalDefense + 5), 1, 1, 1, 1, 0.82, 0)
                tt:AddDoubleLine(string.format("Lvl %d Boss White Cap (DW):", s.bossLevel), string.format("28.0%% (27.0%% with %d WS)", s.equalDefense + 5), 1, 1, 1, 1, 0.82, 0)
                tt:AddDoubleLine(string.format("Lvl %d Mob Cap (DW White / Yellow):", s.playerLevel), "24.0% / 5.0%", 1, 1, 1, 0.8, 0.8, 0.8)
            else
                tt:AddDoubleLine(string.format("Lvl %d Boss Hit Cap (%d Def):", s.bossLevel, s.bossDefense), string.format("9.0%% (8.0%% with %d WS)", s.equalDefense + 5), 1, 1, 1, 1, 0.82, 0)
                tt:AddDoubleLine(string.format("Lvl %d Mob Hit Cap:", s.playerLevel), "5.0%", 1, 1, 1, 0.8, 0.8, 0.8)
            end
        end
    end)

    AddStatRow("hitCap", "White Hit Cap (Boss):", "Hit Cap Progress", function(tt, s)
        if s.isCaster then
            tt:AddLine(string.format("Caster spells vs Level %d Boss (17%% base miss, 1%% min resist):", s.bossLevel), 0.85, 0.85, 0.85, true)
            if s.isSpellHitCappedBoss then
                tt:AddDoubleLine(string.format("vs Lvl %d Boss (16.0%% Cap):", s.bossLevel), "CAPPED (99% max hit)", 1, 1, 1, 0, 1, 0)
            else
                tt:AddDoubleLine(string.format("vs Lvl %d Boss (16.0%% Cap):", s.bossLevel), string.format("%.1f%% Spell Hit needed", s.spellHitNeededBoss), 1, 1, 1, 1, 0.4, 0.4)
            end
            if s.isSpellHitCappedEqual then
                tt:AddDoubleLine(string.format("vs Lvl %d Mob (3.0%% Cap):", s.playerLevel), "CAPPED (99% max hit)", 1, 1, 1, 0, 1, 0)
            else
                tt:AddDoubleLine(string.format("vs Lvl %d Mob (3.0%% Cap):", s.playerLevel), string.format("%.1f%% Spell Hit needed", s.spellHitNeededEqual), 1, 1, 1, 1, 0.82, 0)
            end
        elseif s.isDualWield then
            tt:AddLine("Dual-Wield white attacks (+19% DW miss penalty):", 0.85, 0.85, 0.85)
            if s.isHitCappedBoss then
                tt:AddDoubleLine(string.format("vs Lvl %d Boss (28.0%% Cap):", s.bossLevel), "CAPPED (0.0% Miss)", 1, 1, 1, 0, 1, 0)
            else
                tt:AddDoubleLine(string.format("vs Lvl %d Boss (28.0%% Cap):", s.bossLevel), string.format("%.1f%% Hit needed", s.hitNeededBoss), 1, 1, 1, 1, 0.4, 0.4)
            end
            if s.isHitCappedEqual then
                tt:AddDoubleLine(string.format("vs Lvl %d Mob (24.0%% Cap):", s.playerLevel), "CAPPED (0.0% Miss)", 1, 1, 1, 0, 1, 0)
            else
                tt:AddDoubleLine(string.format("vs Lvl %d Mob (24.0%% Cap):", s.playerLevel), string.format("%.1f%% Hit needed", s.hitNeededEqual), 1, 1, 1, 1, 0.82, 0)
            end
            tt:AddLine(" ")
            tt:AddLine("Yellow / Special attacks (no DW penalty):", 0.85, 0.85, 0.85)
            if s.isYellowHitCappedBoss then
                tt:AddDoubleLine(string.format("vs Lvl %d Boss (9.0%% Cap):", s.bossLevel), "CAPPED (0.0% Miss)", 1, 1, 1, 0, 1, 0)
            else
                tt:AddDoubleLine(string.format("vs Lvl %d Boss (9.0%% Cap):", s.bossLevel), string.format("%.1f%% Hit needed", s.yellowHitNeededBoss), 1, 1, 1, 1, 0.4, 0.4)
            end
            if s.isYellowHitCappedEqual then
                tt:AddDoubleLine(string.format("vs Lvl %d Mob (5.0%% Cap):", s.playerLevel), "CAPPED (0.0% Miss)", 1, 1, 1, 0, 1, 0)
            else
                tt:AddDoubleLine(string.format("vs Lvl %d Mob (5.0%% Cap):", s.playerLevel), string.format("%.1f%% Hit needed", s.yellowHitNeededEqual), 1, 1, 1, 1, 0.82, 0)
            end
        else
            tt:AddLine("Single-wield / Ranged / Shapeshift white & yellow attacks:", 0.85, 0.85, 0.85)
            if s.isHitCappedBoss then
                tt:AddDoubleLine(string.format("vs Lvl %d Boss (9.0%% Cap):", s.bossLevel), "CAPPED (0.0% Miss)", 1, 1, 1, 0, 1, 0)
            else
                tt:AddDoubleLine(string.format("vs Lvl %d Boss (9.0%% Cap):", s.bossLevel), string.format("%.1f%% Hit needed", s.hitNeededBoss), 1, 1, 1, 1, 0.4, 0.4)
            end
            if s.isHitCappedEqual then
                tt:AddDoubleLine(string.format("vs Lvl %d Mob (5.0%% Cap):", s.playerLevel), "CAPPED (0.0% Miss)", 1, 1, 1, 0, 1, 0)
            else
                tt:AddDoubleLine(string.format("vs Lvl %d Mob (5.0%% Cap):", s.playerLevel), string.format("%.1f%% Hit needed", s.hitNeededEqual), 1, 1, 1, 1, 0.82, 0)
            end
        end
    end)

    self.characterPane = pane

    PaperDollFrame:HookScript("OnShow", function()
        FeralCalc:UpdateCharacterPaneVisibility()
        FeralCalc:UpdateCharacterPane()
    end)

    self:UpdateCharacterPaneVisibility()
    self:UpdateCharacterPane()
    self:LayoutCharacterPane()
end

function FeralCalc:GetCharacterKey()
    local name = (type(UnitName) == "function" and UnitName("player")) or "Unknown"
    local realm = (type(GetRealmName) == "function" and GetRealmName()) or "Realm"
    return tostring(name) .. "-" .. tostring(realm)
end

function FeralCalc:GetSectionCollapsed(sectionKey, stats)
    self:InitDB()
    local charKey = self:GetCharacterKey()
    local byChar = self.db.collapsedSectionsByChar
    if type(byChar) == "table" and type(byChar[charKey]) == "table" and byChar[charKey][sectionKey] ~= nil then
        return byChar[charKey][sectionKey] and true or false
    end

    if sectionKey == "mitigation" or sectionKey == "avoidance" then
        stats = stats or self.lastStats or self:GetMitigationStats()
        return not self:IsTankSpecByTalents(stats.classFile, stats.talents)
    end
    return false
end

function FeralCalc:LayoutCharacterPane()
    local pane = self.characterPane
    if not pane or not pane.sections then
        return
    end

    local yOffset = -84
    for _, sec in ipairs(pane.sections) do
        local isCollapsed = self:GetSectionCollapsed(sec.key, self.lastStats)
        yOffset = yOffset - 8

        sec.headerBtn:ClearAllPoints()
        sec.headerBtn:SetPoint("TOPLEFT", pane, "TOPLEFT", 14, yOffset)
        if sec.indicator then
            sec.indicator:SetText(isCollapsed and "|cFFAAAAAA[+]|r" or "|cFFFFD100[-]|r")
        end

        yOffset = yOffset - 20

        for _, row in ipairs(sec.rows) do
            if isCollapsed then
                row:Hide()
            else
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", pane, "TOPLEFT", 14, yOffset)
                row:Show()
                yOffset = yOffset - 18
            end
        end
    end

    pane:SetHeight(math.max(120, -yOffset + 10))
end

-- ============================================================================
-- STANDALONE MOVABLE TOP-7 SKILL PRIORITY PANE (Toggled only via Slash Command)
-- ============================================================================
function FeralCalc:CreatePriorityPane()
    if self.priorityPane then
        return
    end
    self:InitDB()

    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    local pFrame = CreateFrame("Frame", "FeralCalcPriorityPane", UIParent, backdropTemplate)
    pFrame:SetSize(276, 190)
    pFrame:SetFrameStrata("HIGH")
    pFrame:SetClampedToScreen(true)
    pFrame:SetMovable(true)
    pFrame:EnableMouse(true)
    pFrame:RegisterForDrag("LeftButton")

    local function SavePrioPosition()
        pFrame:StopMovingOrSizing()
        local point, _, relPoint, xOfs, yOfs = pFrame:GetPoint()
        if point then
            FeralCalc.db.prioPoint = {
                point = point,
                relPoint = relPoint or point,
                x = xOfs or 0,
                y = yOfs or 0,
            }
        end
    end

    pFrame:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    pFrame:SetScript("OnDragStop", SavePrioPosition)

    local savedPos = self.db.prioPoint
    if type(savedPos) == "table" and savedPos.point then
        pFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint or savedPos.point, savedPos.x or 0, savedPos.y or 0)
    else
        pFrame:SetPoint("CENTER", UIParent, "CENTER", 320, 80)
    end

    if pFrame.SetBackdrop then
        pFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 20,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        pFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.94)
        pFrame:SetBackdropBorderColor(0.85, 0.75, 0.55, 1.0)
    end

    local closeBtn = CreateFrame("Button", nil, pFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", pFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        FeralCalc:InitDB()
        FeralCalc.db.showPriorityPane = false
        pFrame:Hide()
        if FeralCalc.RefreshOptionsFrame then
            FeralCalc:RefreshOptionsFrame()
        end
    end)

    local title = pFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", pFrame, "TOPLEFT", 14, -12)
    title:SetText("|cFFFF7D0ATop 7 Skill Priority|r")
    pFrame.title = title

    local subHeader = pFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subHeader:SetPoint("TOPLEFT", pFrame, "TOPLEFT", 14, -27)
    subHeader:SetText("|cFFAAAAAA(Drag to move · Hover for full breakdown)|r")
    pFrame.subHeader = subHeader

    local line = pFrame:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", pFrame, "TOPLEFT", 12, -41)
    line:SetPoint("TOPRIGHT", pFrame, "TOPRIGHT", -12, -41)
    line:SetColorTexture(0.6, 0.5, 0.25, 0.6)

    pFrame.leftLabels = {}
    pFrame.rightValues = {}

    local function ShowPriorityTooltip(tt)
        local s = FeralCalc:GetMitigationStats()
        local prioList, unitLabel, modeLabel = FeralCalc:GetSkillPriorityList(s)
        tt:AddLine(string.format("%s — Ranked by %s (Highest Known Rank)", modeLabel, unitLabel), 0.85, 0.85, 0.85)
        tt:AddLine(" ")
        if #prioList == 0 then
            tt:AddLine("No known abilities found for this form/class.", 0.7, 0.7, 0.7)
            return
        end
        for idx, item in ipairs(prioList) do
            local leftText = string.format("%d. %s", idx, item.displayName)
            local rightText
            if item.unit == "Dmg" then
                rightText = string.format("%.0f Total Dmg", item.avgDmg or 0)
            else
                rightText = string.format("%.1f %s (%.1f vs Boss) · %.0f Dmg", item.eff or 0, item.unit, item.effPostArmor or 0, item.avgDmg or 0)
            end
            local r, g, b = 1, 1, 1
            if idx == 1 then
                r, g, b = 0, 1, 0
            elseif idx == 2 then
                r, g, b = 1, 0.82, 0
            end
            tt:AddDoubleLine(leftText, rightText, 1, 0.82, 0, r, g, b)
        end
        tt:AddLine(" ")
        tt:AddLine("Updates automatically when shifting forms, swapping gear, or training new spell ranks.", 0.65, 0.85, 1.0, true)
    end

    local yOffset = -46
    for i = 1, 7 do
        local row = CreateFrame("Frame", nil, pFrame)
        row:SetSize(252, 18)
        row:SetPoint("TOPLEFT", pFrame, "TOPLEFT", 12, yOffset)
        row:EnableMouse(true)
        row:RegisterForDrag("LeftButton")
        row:SetScript("OnDragStart", function()
            pFrame:StartMoving()
        end)
        row:SetScript("OnDragStop", SavePrioPosition)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 0.82, 0, 0.12)
        highlight:Hide()

        local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        left:SetPoint("LEFT", row, "LEFT", 2, 0)
        left:SetText(i .. ". -")

        local right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        right:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        right:SetText("-")

        row:SetScript("OnEnter", function(selfRow)
            highlight:Show()
            GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
            GameTooltip:SetText("Skill Efficiency Priority", 1.0, 0.82, 0.0)
            ShowPriorityTooltip(GameTooltip)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            highlight:Hide()
            GameTooltip:Hide()
        end)

        pFrame.leftLabels[i] = left
        pFrame.rightValues[i] = right
        yOffset = yOffset - 19
    end

    -- Restore visibility from SavedVariables (hidden by default)
    if self.db.showPriorityPane then
        pFrame:Show()
    else
        pFrame:Hide()
    end
    self.priorityPane = pFrame
end

function FeralCalc:SetPriorityPaneVisible(visible, silent)
    self:InitDB()
    if not self.priorityPane then
        self:CreatePriorityPane()
    end
    self.db.showPriorityPane = visible and true or false
    if self.db.showPriorityPane then
        self:ScanSpellbook()
        self.priorityPane:Show()
        self:UpdatePriorityPane()
        if not silent then
            self:Print("Skill Priority window: |cFF00FF00SHOWN|r (Drag anywhere on the window to move)")
        end
    else
        self.priorityPane:Hide()
        if not silent then
            self:Print("Skill Priority window: |cFFFF5555HIDDEN|r")
        end
    end
    if self.RefreshOptionsFrame then
        self:RefreshOptionsFrame()
    end
end

function FeralCalc:TogglePriorityPane()
    self:InitDB()
    if not self.priorityPane then
        self:CreatePriorityPane()
    end
    self:SetPriorityPaneVisible(not self.priorityPane:IsShown(), false)
end

function FeralCalc:UpdatePriorityPane()
    if not self.priorityPane or not self.priorityPane:IsShown() then
        return
    end

    local s = self:GetMitigationStats()
    local prioList, unitLabel, modeLabel = self:GetSkillPriorityList(s)

    if self.priorityPane.title then
        self.priorityPane.title:SetText(string.format("|cFFFF7D0ATop 7 Priority (%s · %s)|r", unitLabel, modeLabel))
    end

    for i = 1, 7 do
        local item = prioList[i]
        local left = self.priorityPane.leftLabels[i]
        local right = self.priorityPane.rightValues[i]
        if item and left and right then
            left:SetText(string.format("%d. %s", i, item.displayName))
            local valColor = (i == 1) and "|cFF00FF00" or ((i == 2) and "|cFFFFD100" or "|cFFFFFFFF")
            if item.unit == "Dmg" then
                right:SetText(string.format("%s%.0f Dmg|r", valColor, item.avgDmg or 0))
            else
                right:SetText(string.format("%s%.1f %s|r |cFFAAAAAA(%.0f)|r", valColor, item.eff or 0, item.unit, item.avgDmg or 0))
            end
        elseif left and right then
            left:SetText(string.format("|cFF666666%d. -|r", i))
            right:SetText("|cFF666666-|r")
        end
    end
end

-- ============================================================================
-- STANDALONE MOVABLE TOP-5 THREAT PRIORITY PANE (TPR / TPM)
-- ============================================================================
function FeralCalc:CreateThreatPane()
    if self.threatPane then
        return
    end
    self:InitDB()

    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    local tFrame = CreateFrame("Frame", "ForeverTankThreatPane", UIParent, backdropTemplate)
    tFrame:SetSize(276, 152)
    tFrame:SetFrameStrata("HIGH")
    tFrame:SetClampedToScreen(true)
    tFrame:SetMovable(true)
    tFrame:EnableMouse(true)
    tFrame:RegisterForDrag("LeftButton")

    local function SaveThreatPosition()
        tFrame:StopMovingOrSizing()
        local point, _, relPoint, xOfs, yOfs = tFrame:GetPoint()
        if point then
            FeralCalc.db.threatPoint = {
                point = point,
                relPoint = relPoint or point,
                x = xOfs or 0,
                y = yOfs or 0,
            }
        end
    end

    tFrame:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    tFrame:SetScript("OnDragStop", SaveThreatPosition)

    local savedPos = self.db.threatPoint
    if type(savedPos) == "table" and savedPos.point then
        tFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint or savedPos.point, savedPos.x or 0, savedPos.y or 0)
    else
        tFrame:SetPoint("CENTER", UIParent, "CENTER", 320, -90)
    end

    if tFrame.SetBackdrop then
        tFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 20,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        tFrame:SetBackdropColor(0.08, 0.05, 0.05, 0.94)
        tFrame:SetBackdropBorderColor(0.85, 0.45, 0.35, 1.0)
    end

    local closeBtn = CreateFrame("Button", nil, tFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", tFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        FeralCalc:InitDB()
        FeralCalc.db.showThreatPane = false
        tFrame:Hide()
        if FeralCalc.RefreshOptionsFrame then
            FeralCalc:RefreshOptionsFrame()
        end
    end)

    local title = tFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", tFrame, "TOPLEFT", 14, -12)
    title:SetText("|cFFFF5555Top 5 Threat Priority|r")
    tFrame.title = title

    local subHeader = tFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subHeader:SetPoint("TOPLEFT", tFrame, "TOPLEFT", 14, -27)
    subHeader:SetText("|cFFAAAAAA(Drag to move · Hover for full threat table)|r")
    tFrame.subHeader = subHeader

    local line = tFrame:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", tFrame, "TOPLEFT", 12, -41)
    line:SetPoint("TOPRIGHT", tFrame, "TOPRIGHT", -12, -41)
    line:SetColorTexture(0.75, 0.35, 0.25, 0.6)

    tFrame.leftLabels = {}
    tFrame.rightValues = {}

    local function ShowThreatTooltip(tt)
        local s = FeralCalc:GetMitigationStats()
        local tList, unitLabel, modeLabel = FeralCalc:GetThreatPriorityList(s)
        tt:AddLine(string.format("%s — Ranked by %s (Highest Known Rank)", modeLabel, unitLabel), 0.85, 0.85, 0.85)
        tt:AddLine(" ")
        if #tList == 0 then
            tt:AddLine("No known threat abilities found.", 0.7, 0.7, 0.7)
            return
        end
        for idx, item in ipairs(tList) do
            local leftText = string.format("%d. %s", idx, item.displayName)
            local rightText = string.format("%.1f %s · %.0f Threat", item.eff or 0, item.unit, item.threat or 0)
            local r, g, b = 1, 1, 1
            if idx == 1 then
                r, g, b = 0, 1, 0
            elseif idx == 2 then
                r, g, b = 1, 0.82, 0
            end
            tt:AddDoubleLine(leftText, rightText, 1, 0.82, 0, r, g, b)
        end
        tt:AddLine(" ")
        tt:AddLine("Includes Bear/Def Stance/Righteous Fury & Threat Talent multipliers.", 0.65, 0.85, 1.0, true)
    end

    local yOffset = -46
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, tFrame)
        row:SetSize(252, 18)
        row:SetPoint("TOPLEFT", tFrame, "TOPLEFT", 12, yOffset)
        row:EnableMouse(true)
        row:RegisterForDrag("LeftButton")
        row:SetScript("OnDragStart", function()
            tFrame:StartMoving()
        end)
        row:SetScript("OnDragStop", SaveThreatPosition)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 0.35, 0.25, 0.14)
        highlight:Hide()

        local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        left:SetPoint("LEFT", row, "LEFT", 2, 0)
        left:SetText(i .. ". -")

        local right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        right:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        right:SetText("-")

        row:SetScript("OnEnter", function(selfRow)
            highlight:Show()
            GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
            GameTooltip:SetText("Threat Efficiency Priority", 1.0, 0.4, 0.3)
            ShowThreatTooltip(GameTooltip)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            highlight:Hide()
            GameTooltip:Hide()
        end)

        tFrame.leftLabels[i] = left
        tFrame.rightValues[i] = right
        yOffset = yOffset - 19
    end

    if self.db.showThreatPane then
        tFrame:Show()
    else
        tFrame:Hide()
    end
    self.threatPane = tFrame
end

function FeralCalc:SetThreatPaneVisible(visible, silent)
    self:InitDB()
    if not self.threatPane then
        self:CreateThreatPane()
    end
    self.db.showThreatPane = visible and true or false
    if self.db.showThreatPane then
        self:ScanSpellbook()
        self.threatPane:Show()
        self:UpdateThreatPane()
        if not silent then
            self:Print("Threat Priority window: |cFF00FF00SHOWN|r (Drag anywhere on the window to move)")
        end
    else
        self.threatPane:Hide()
        if not silent then
            self:Print("Threat Priority window: |cFFFF5555HIDDEN|r")
        end
    end
    if self.RefreshOptionsFrame then
        self:RefreshOptionsFrame()
    end
end

function FeralCalc:ToggleThreatPane()
    self:InitDB()
    if not self.threatPane then
        self:CreateThreatPane()
    end
    self:SetThreatPaneVisible(not self.threatPane:IsShown(), false)
end

function FeralCalc:UpdateThreatPane()
    if not self.threatPane or not self.threatPane:IsShown() then
        return
    end

    local s = self:GetMitigationStats()
    local tList, unitLabel, modeLabel = self:GetThreatPriorityList(s)

    if self.threatPane.title then
        self.threatPane.title:SetText(string.format("|cFFFF5555Top 5 Threat (%s · %s)|r", unitLabel, modeLabel))
    end

    for i = 1, 5 do
        local item = tList[i]
        local left = self.threatPane.leftLabels[i]
        local right = self.threatPane.rightValues[i]
        if item and left and right then
            left:SetText(string.format("%d. %s", i, item.displayName))
            local valColor = (i == 1) and "|cFF00FF00" or ((i == 2) and "|cFFFFD100" or "|cFFFFFFFF")
            right:SetText(string.format("%s%.1f %s|r |cFFAAAAAA(%.0f)|r", valColor, item.eff or 0, item.unit, item.threat or 0))
        elseif left and right then
            left:SetText(string.format("|cFF666666%d. -|r", i))
            right:SetText("|cFF666666-|r")
        end
    end
end

-- ============================================================================
-- STANDALONE MOVABLE PET MITIGATION & THREAT PANE (Hunters & Warlocks)
-- ============================================================================
function FeralCalc:CreatePetPane()
    if self.petPane then
        return
    end
    self:InitDB()

    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    local pFrame = CreateFrame("Frame", "FeralCalcPetPane", UIParent, backdropTemplate)
    pFrame:SetSize(276, 380)
    pFrame:SetFrameStrata("HIGH")
    pFrame:SetClampedToScreen(true)
    pFrame:SetMovable(true)
    pFrame:EnableMouse(true)
    pFrame:RegisterForDrag("LeftButton")

    local function SavePetPosition()
        pFrame:StopMovingOrSizing()
        local point, _, relPoint, xOfs, yOfs = pFrame:GetPoint()
        if point then
            FeralCalc.db.petPoint = {
                point = point,
                relPoint = relPoint or point,
                x = xOfs or 0,
                y = yOfs or 0,
            }
        end
    end

    pFrame:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    pFrame:SetScript("OnDragStop", SavePetPosition)

    local savedPos = self.db.petPoint
    if type(savedPos) == "table" and savedPos.point then
        pFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint or savedPos.point, savedPos.x or 0, savedPos.y or 0)
    else
        pFrame:SetPoint("CENTER", UIParent, "CENTER", 320, 20)
    end

    if pFrame.SetBackdrop then
        pFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        })
        pFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.94)
        pFrame:SetBackdropBorderColor(0.85, 0.75, 0.55, 1.0)
    end

    local closeBtn = CreateFrame("Button", nil, pFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", pFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        FeralCalc:SetPetPaneVisible(false, true)
    end)

    local title = pFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", pFrame, "TOP", 0, -12)
    title:SetText("|cFFFF7D0APet Stats|r")
    pFrame.title = title

    local headerBox = CreateFrame("Frame", nil, pFrame, backdropTemplate)
    headerBox:SetSize(252, 44)
    headerBox:SetPoint("TOP", pFrame, "TOP", 0, -34)
    if headerBox.SetBackdrop then
        headerBox:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        headerBox:SetBackdropColor(0.14, 0.11, 0.08, 0.9)
        headerBox:SetBackdropBorderColor(0.6, 0.45, 0.2, 0.9)
    end

    local petLabel = headerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    petLabel:SetPoint("TOPLEFT", headerBox, "TOPLEFT", 10, -7)
    petLabel:SetText("Pet:")

    local petValue = headerBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    petValue:SetPoint("TOPRIGHT", headerBox, "TOPRIGHT", -10, -7)

    local hpLabel = headerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hpLabel:SetPoint("BOTTOMLEFT", headerBox, "BOTTOMLEFT", 10, 7)
    hpLabel:SetText("Max Health:")

    local hpValue = headerBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hpValue:SetPoint("BOTTOMRIGHT", headerBox, "BOTTOMRIGHT", -10, 7)

    pFrame.petValue = petValue
    pFrame.hpValue = hpValue
    pFrame.rows = {}
    pFrame.leftLabels = {}

    local yOffset = -84

    local function AddPetSection(text)
        yOffset = yOffset - 8
        local hdr = pFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        hdr:SetPoint("TOPLEFT", pFrame, "TOPLEFT", 14, yOffset)
        hdr:SetText(text)
        hdr:SetTextColor(1.0, 0.49, 0.04)

        local line = pFrame:CreateTexture(nil, "ARTWORK")
        line:SetHeight(2)
        line:SetPoint("TOPLEFT", pFrame, "TOPLEFT", 14, yOffset - 15)
        line:SetPoint("TOPRIGHT", pFrame, "TOPRIGHT", -14, yOffset - 15)
        line:SetColorTexture(0.7, 0.55, 0.25, 0.85)

        yOffset = yOffset - 20
    end

    local function AddPetRow(key, labelText, tooltipTitle, tooltipFunc)
        local row = CreateFrame("Frame", nil, pFrame)
        row:SetSize(248, 18)
        row:SetPoint("TOPLEFT", pFrame, "TOPLEFT", 14, yOffset)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 0.82, 0, 0.12)
        highlight:Hide()

        local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        left:SetPoint("LEFT", row, "LEFT", 2, 0)
        left:SetText(labelText)

        local right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        right:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        right:SetText("-")

        if tooltipTitle or tooltipFunc then
            row:EnableMouse(true)
            row:SetScript("OnEnter", function(selfRow)
                highlight:Show()
                GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                if tooltipTitle then
                    GameTooltip:SetText(tooltipTitle, 1.0, 0.82, 0.0)
                end
                local ps = pFrame.lastPetStats
                if ps and ps.hasPet and tooltipFunc then
                    tooltipFunc(GameTooltip, ps)
                else
                    GameTooltip:AddLine("Summon a pet to view live pet mitigation and threat stats.", 0.8, 0.8, 0.8, true)
                end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                highlight:Hide()
                GameTooltip:Hide()
            end)
        end

        pFrame.rows[key] = right
        pFrame.leftLabels[key] = left
        yOffset = yOffset - 18
    end

    -- Section 1: Pet Mitigation
    AddPetSection("Pet Mitigation")

    AddPetRow("armor", "Armor:", "Pet Effective Armor", function(tt, p)
        tt:AddDoubleLine("Base Armor:", FormatNumber(p.baseArmor), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Effective Armor:", FormatNumber(p.effectiveArmor), 1, 1, 1, 0, 1, 0)
        tt:AddDoubleLine(string.format("75%% Cap (vs Lvl %d Boss):", p.bossLevel), FormatNumber(p.armorCapBoss), 1, 1, 1, 1, 0.82, 0)
    end)

    AddPetRow("drEqual", "DR vs Equal Lvl:", "Pet Damage Reduction (Equal Level)", function(tt, p)
        tt:AddLine(string.format("Formula (vs Lvl %d): Armor / (Armor + %d)", p.petLevel, p.armorConstEqual), 0.8, 0.8, 0.8)
        tt:AddDoubleLine(string.format("Physical DR (vs Lvl %d):", p.petLevel), string.format("%.2f%%", p.drEqualPct), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Physical EHP (Equal):", FormatNumber(p.physicalEHPEqual), 1, 1, 1, 0.8, 0.8, 0.8)
    end)

    AddPetRow("drBoss", "DR vs +3 Boss:", "Pet Damage Reduction (vs +3 Boss)", function(tt, p)
        tt:AddLine(string.format("Formula (vs Lvl %d): Armor / (Armor + %d)", p.bossLevel, p.armorConstBoss), 0.8, 0.8, 0.8)
        tt:AddDoubleLine(string.format("Armor DR (vs Lvl %d):", p.bossLevel), string.format("%.2f%%", p.drBossPct), 1, 1, 1, 1, 0.82, 0)
    end)

    AddPetRow("ehp", "Physical EHP (Boss):", "Pet Effective Health (EHP)", function(tt, p)
        tt:AddLine("Physical EHP = Pet MaxHP / (1 - Boss Armor DR)", 0.8, 0.8, 0.8)
        tt:AddDoubleLine(string.format("Physical EHP (vs Lvl %d):", p.bossLevel), FormatNumber(p.physicalEHP), 1, 1, 1, 0, 1, 0)
        tt:AddDoubleLine("Avoidance-Adjusted EHP:", FormatNumber(p.avoidanceEHP), 1, 1, 1, 0, 0.8, 1)
    end)

    AddPetRow("avoid", "Avoidance:", "Pet Avoidance & Defense", function(tt, p)
        tt:AddDoubleLine("Pet Defense:", string.format("%d (vs %d Boss WS)", p.totalDefense, p.bossDefense), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Boss Miss %:", string.format("%.2f%%", p.bossMissPct), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine(string.format("Est. Dodge (%d Agi):", p.petAgi), string.format("%.2f%%", p.estDodgePct), 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine("Combined Avoidance:", string.format("%.2f%%", p.avoidancePct), 1, 1, 1, 0, 1, 0)
    end)

    -- Section 2: Pet Threat & Offense
    AddPetSection("Pet Threat & Offense")

    AddPetRow("meleeDmg", "Melee Damage:", "Pet Melee Damage & Speed", function(tt, p)
        tt:AddDoubleLine("Melee Range:", string.format("%.1f - %.1f (%.2fs)", p.lowDmg, p.hiDmg, p.mainSpeed), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Raw White DPS:", string.format("%.1f DPS", p.whiteDPS), 1, 1, 1, 1, 0.82, 0)
        if p.happinessLabel then
            tt:AddDoubleLine("Happiness:", p.happinessLabel, 1, 1, 1, 0, 1, 0)
        end
    end)

    AddPetRow("attackPower", "Attack Power:", "Pet Attack Power", function(tt, p)
        tt:AddDoubleLine("Total Pet AP:", FormatNumber(p.totalAP), 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine("AP DPS Contribution:", string.format("+%.1f DPS", p.totalAP / 14), 1, 1, 1, 0.8, 0.8, 0.8)
    end)

    AddPetRow("whiteDps", "Melee White DPS:", "Pet Melee White DPS", function(tt, p)
        tt:AddDoubleLine("Raw White DPS:", string.format("%.1f DPS", p.whiteDPS), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine(string.format("vs Lvl %d (-%.1f%% Armor):", p.petLevel, p.equalArmorDRPct), string.format("%.1f DPS", p.equalWhiteDPS), 1, 1, 1, 0, 1, 0)
        tt:AddDoubleLine(string.format("vs Lvl %d Boss (-%.1f%% Armor):", p.bossLevel, p.bossArmorDRPct), string.format("%.1f DPS", p.bossWhiteDPS), 1, 1, 1, 1, 0.82, 0)
    end)

    AddPetRow("threatAbility", "Threat Ability:", "Pet Taunt / Threat Ability", function(tt, p)
        if p.abilityThreat > 0 then
            tt:AddDoubleLine(p.abilityName .. ":", string.format("+%d Threat every %ds", p.abilityThreat, p.abilityCD), 1, 1, 1, 1, 0.82, 0)
            tt:AddDoubleLine("Ability Sustained TPS:", string.format("%.1f TPS", p.abilityTPS), 1, 1, 1, 0, 1, 0)
            if (p.impVoidwalkerRank or 0) > 0 then
                tt:AddDoubleLine("Improved Voidwalker:", string.format("+%d%% Torment/Suffering", p.impVoidwalkerRank * 10), 1, 1, 1, 0.4, 0.8, 1)
            end
            if p.primaryAutoCastOff then
                tt:AddLine("Note: Autocast is currently OFF on pet bar.", 1, 0.82, 0, true)
            end
        else
            tt:AddLine("No Growl / Torment / Anguish threat ability active for this pet.", 0.8, 0.8, 0.8, true)
        end
    end)

    AddPetRow("extraThreat", "Bonus Threat:", "Pet Skills & Talents Threat", function(tt, p)
        local sources = p.extraSources or {}
        if #sources > 0 then
            for _, src in ipairs(sources) do
                local detail = (src.cd and src.cd > 0)
                    and string.format("+%.0f every %.1gs (%.1f TPS)", src.threat or 0, src.cd, src.tps or 0)
                    or string.format("+%.1f TPS (Focus)", src.tps or 0)
                tt:AddDoubleLine(src.name .. ":", detail, 1, 1, 1, 1, 0.82, 0)
            end
            tt:AddDoubleLine("Combined Bonus TPS:", string.format("+%.1f TPS", p.extraThreatTPS or 0), 1, 1, 1, 0, 1, 0)
        else
            tt:AddLine("No active pet threat talents or bar skills (Intimidation, Suffering, Screech, Bite, Claw, etc.).", 0.8, 0.8, 0.8, true)
        end
    end)

    AddPetRow("totalTpsEqual", "Threat (Equal Lvl):", "Estimated Pet TPS (Equal Level)", function(tt, p)
        tt:AddDoubleLine(string.format("White Melee TPS (Lvl %d):", p.petLevel), string.format("%.1f TPS", p.estWhiteTPSEqual), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Primary Ability TPS:", string.format("%.1f TPS", p.abilityTPS), 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine("Skills & Talents TPS:", string.format("+%.1f TPS", p.extraThreatTPS or 0), 1, 1, 1, 0.4, 0.8, 1)
        tt:AddDoubleLine(string.format("Total TPS (Lvl %d):", p.petLevel), string.format("%.1f TPS", p.totalEstTPSEqual), 1, 1, 1, 0, 1, 0)
    end)

    AddPetRow("totalTps", "Threat (+3 Boss):", "Estimated Pet TPS (+3 Boss)", function(tt, p)
        tt:AddDoubleLine(string.format("White Melee TPS (Lvl %d Boss):", p.bossLevel), string.format("%.1f TPS", p.estWhiteTPS), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine("Primary Ability TPS:", string.format("%.1f TPS", p.abilityTPS), 1, 1, 1, 1, 0.82, 0)
        tt:AddDoubleLine("Skills & Talents TPS:", string.format("+%.1f TPS", p.extraThreatTPS or 0), 1, 1, 1, 0.4, 0.8, 1)
        tt:AddDoubleLine(string.format("Total TPS (Lvl %d Boss):", p.bossLevel), string.format("%.1f TPS", p.totalEstTPS), 1, 1, 1, 1, 0.5, 0.5)
    end)

    if self.db.showPetPane then
        pFrame:Show()
    else
        pFrame:Hide()
    end
    self.petPane = pFrame
end

function FeralCalc:SetPetPaneVisible(visible, silent)
    self:InitDB()
    if not self.petPane then
        self:CreatePetPane()
    end
    self.db.showPetPane = visible and true or false
    if self.db.showPetPane then
        self.petPane:Show()
        self:UpdatePetPane()
        if not silent then
            self:Print("Pet Mitigation & Threat window: |cFF00FF00SHOWN|r (Drag anywhere on the window to move)")
        end
    else
        self.petPane:Hide()
        if not silent then
            self:Print("Pet Mitigation & Threat window: |cFFFF5555HIDDEN|r")
        end
    end
    if self.RefreshOptionsFrame then
        self:RefreshOptionsFrame()
    end
end

function FeralCalc:TogglePetPane()
    self:InitDB()
    if not self.petPane then
        self:CreatePetPane()
    end
    self:SetPetPaneVisible(not self.petPane:IsShown(), false)
end

function FeralCalc:UpdatePetPane()
    if not self.petPane or not self.petPane:IsShown() then
        return
    end

    local p = self:GetPetStats()
    self.petPane.lastPetStats = p
    local rows = self.petPane.rows
    local leftLabels = self.petPane.leftLabels

    if not p.hasPet then
        self.petPane.petValue:SetText("|cFF888888No Pet Summoned|r")
        self.petPane.hpValue:SetText("|cFF888888-|r")
        if leftLabels.drEqual then leftLabels.drEqual:SetText("DR vs Equal Lvl:") end
        if leftLabels.drBoss then leftLabels.drBoss:SetText("DR vs +3 Boss:") end
        if leftLabels.totalTpsEqual then leftLabels.totalTpsEqual:SetText("Threat (Equal Lvl):") end
        if leftLabels.totalTps then leftLabels.totalTps:SetText("Threat (+3 Boss):") end
        for _, valFS in pairs(rows) do
            valFS:SetText("|cFF666666-|r")
        end
        return
    end

    local familyPart = (p.petFamily ~= "" and (" · " .. p.petFamily)) or ""
    self.petPane.petValue:SetText(string.format("|cFFFFFFFF%s|r |cFFAAAAAA(Lvl %d%s)|r", p.petName, p.petLevel, familyPart))
    self.petPane.hpValue:SetText("|cFF00FF00" .. FormatNumber(p.maxHP) .. "|r")

    if leftLabels.drEqual then leftLabels.drEqual:SetText(string.format("DR vs Lvl %d:", p.petLevel)) end
    if leftLabels.drBoss then leftLabels.drBoss:SetText(string.format("DR vs Lvl %d Boss:", p.bossLevel)) end
    if leftLabels.totalTpsEqual then leftLabels.totalTpsEqual:SetText(string.format("Threat (Lvl %d):", p.petLevel)) end
    if leftLabels.totalTps then leftLabels.totalTps:SetText(string.format("Threat (Lvl %d Boss):", p.bossLevel)) end

    rows.armor:SetText("|cFFFFFFFF" .. FormatNumber(p.effectiveArmor) .. "|r")
    rows.drEqual:SetText(string.format("|cFFFFFFFF%.2f%%|r", p.drEqualPct))
    rows.drBoss:SetText(string.format("|cFFFFCC80%.2f%%|r", p.drBossPct))
    rows.ehp:SetText("|cFF00FF00" .. FormatNumber(p.physicalEHP) .. "|r")
    rows.avoid:SetText(string.format("|cFF00CCFF%.1f%%|r |cFFAAAAAA(%.1fM / %.1fD)|r", p.avoidancePct, p.bossMissPct, p.estDodgePct))

    rows.meleeDmg:SetText(string.format("|cFFFFFFFF%d - %d|r |cFFAAAAAA(%.2fs)|r", math.floor(p.lowDmg + 0.5), math.floor(p.hiDmg + 0.5), p.mainSpeed))
    rows.attackPower:SetText("|cFFFFFFFF" .. FormatNumber(p.totalAP) .. "|r")
    rows.whiteDps:SetText(string.format("|cFFFFFFFF%.1f DPS|r |cFFAAAAAA(%.1f raw)|r", p.equalWhiteDPS, p.whiteDPS))

    if p.abilityThreat > 0 then
        rows.threatAbility:SetText(string.format("|cFFFFCC00%s|r |cFFAAAAAA(%.1f TPS)|r", p.abilityName, p.abilityTPS))
    else
        rows.threatAbility:SetText("|cFF888888None|r")
    end

    if (p.extraThreatTPS or 0) > 0 then
        rows.extraThreat:SetText(string.format("|cFF00FF00+%.1f TPS|r |cFFAAAAAA(%d active)|r", p.extraThreatTPS, #(p.extraSources or {})))
    else
        rows.extraThreat:SetText("|cFF8888880.0 TPS|r")
    end

    rows.totalTpsEqual:SetText(string.format("|cFF00FF00%.1f TPS|r", p.totalEstTPSEqual))
    rows.totalTps:SetText(string.format("|cFFFF5555%.1f TPS|r", p.totalEstTPS))
end

function FeralCalc:UpdateCharacterPaneVisibility()
    if not self.characterPane then return end
    self:InitDB()
    if self.db.showCharacterPane and PaperDollFrame and PaperDollFrame:IsShown() then
        self.characterPane:Show()
    else
        self.characterPane:Hide()
    end
end

function FeralCalc:ToggleCharacterPane(fromSlash)
    self:InitDB()
    if not self.characterPane then
        self:CreateCharacterPane()
    end

    if fromSlash and CharacterFrame and not CharacterFrame:IsShown() then
        self.db.showCharacterPane = true
        if not InCombatLockdown() and type(ToggleCharacter) == "function" then
            pcall(ToggleCharacter, "PaperDollFrame")
        end
    else
        self.db.showCharacterPane = not self.db.showCharacterPane
    end

    self:UpdateCharacterPaneVisibility()
    if self.characterPane and self.characterPane:IsShown() then
        self:UpdateCharacterPane()
    end
    if self.RefreshOptionsFrame then
        self:RefreshOptionsFrame()
    end

    if fromSlash then
        local state = self.db.showCharacterPane and "|cFF00FF00SHOWN|r" or "|cFFFF5555HIDDEN|r"
        self:Print("Character Sheet Tank Stats pane: " .. state)
    end
end

function FeralCalc:UpdateCharacterPane()
    if not self.characterPane or not self.characterPane:IsShown() then
        return
    end

    local s = self:GetMitigationStats()
    self.lastStats = s
    if self.characterPane.petBtn then
        if s.classFile == "HUNTER" or s.classFile == "WARLOCK" then
            self.characterPane.petBtn:Show()
        else
            self.characterPane.petBtn:Hide()
        end
    end
    local rows = self.characterPane.rows

    -- Header & Class Styling
    if s.classFile == "WARRIOR" then
        self.characterPane.formLabel:SetText("Current Stance:")
    elseif s.classFile == "PALADIN" then
        self.characterPane.formLabel:SetText("Aura / RF:")
    else
        self.characterPane.formLabel:SetText("Current Form:")
    end

    local formColor = "|cFFFFFFFF"
    if s.formKey == "DIRE_BEAR" or s.formKey == "BEAR" then
        formColor = "|cFFFF7D0A"
    elseif s.formKey == "CAT" then
        formColor = "|cFFFFFF00"
    elseif s.formKey == "DEFENSIVE_STANCE" or s.formKey == "PALADIN_RF" then
        formColor = "|cFF00FF00"
    elseif s.formKey == "BERSERKER_STANCE" then
        formColor = "|cFFFF5555"
    end
    self.characterPane.formValue:SetText(formColor .. s.formName .. "|r")
    self.characterPane.hpValue:SetText("|cFF00FF00" .. FormatNumber(s.maxHP) .. "|r")

    -- Section 1: Mitigation & Health
    local leftLabels = self.characterPane.leftLabels or {}
    if leftLabels.dr60 then leftLabels.dr60:SetText(string.format("DR vs Lvl %d:", s.playerLevel)) end
    if leftLabels.dr63 then leftLabels.dr63:SetText(string.format("DR vs Lvl %d Boss:", s.bossLevel)) end

    rows.armor:SetText("|cFFFFFFFF" .. FormatNumber(s.effectiveArmor) .. "|r")
    rows.dr60:SetText(string.format("|cFFFFFFFF%.2f%%|r", s.dr60Pct))
    if s.stanceDmgMult < 1.0 then
        rows.dr63:SetText(string.format("|cFF00FF00%.2f%%|r |cFFAAAAAA(%.1f%%)|r", s.effectiveDR63Pct, s.dr63Pct))
    else
        rows.dr63:SetText(string.format("|cFFFFCC80%.2f%%|r", s.dr63Pct))
    end

    if s.armorNeeded63 <= 0 then
        rows.armorCap:SetText("|cFF00FF00100% (CAPPED)|r")
    else
        rows.armorCap:SetText(string.format("|cFFFFFFFF%.1f%%|r |cFFAAAAAA(-%s)|r", s.capProgress63, FormatNumber(s.armorNeeded63)))
    end

    rows.ehp:SetText("|cFF00FF00" .. FormatNumber(s.physicalEHP) .. "|r")
    rows.avoidEhp:SetText("|cFF00CCFF" .. FormatNumber(s.avoidanceEHP) .. "|r")

    -- Section 2: Avoidance & Boss Table
    local bonusDef = math.floor(s.armorDefense + 0.5)
    rows.defense:SetText(string.format("|cFFFFFFFF%d|r |cFFAAAAAA(%d+%d)|r", s.totalDefense, s.baseDefense, bonusDef))
    rows.dodge:SetText(string.format("|cFFFFFFFF%.2f%%|r", s.dodgePct))
    rows.parry:SetText(s.canParry and string.format("|cFFFFFFFF%.2f%%|r", s.parryPct) or "|cFF7777770.00% (N/A)|r")
    rows.block:SetText(s.canBlock and string.format("|cFFFFFFFF%.2f%%|r |cFFAAAAAA(%d)|r", s.blockPct, s.blockValue) or "|cFF7777770.00% (N/A)|r")
    rows.bossMiss:SetText(string.format("|cFFFFFFFF%.2f%%|r", s.bossMissPct))

    if s.canBlock and s.blockPct > 0 then
        rows.totalAvoid:SetText(string.format("|cFF00CCFF%.2f%%|r |cFFAAAAAA(%.1f%% tbl)|r", s.totalAvoidancePct, s.combatTablePct))
    else
        rows.totalAvoid:SetText(string.format("|cFF00CCFF%.2f%%|r", s.totalAvoidancePct))
    end

    local critColor = s.isCritImmune and "|cFF00FF00" or "|cFFFF5555"
    rows.bossCrit:SetText(string.format("%s%.2f%%|r", critColor, s.bossCritPct))

    if s.isCritImmune then
        rows.critImmunity:SetText(string.format("|cFF00FF00IMMUNE (%d+)|r", s.critImmuneDef))
    else
        rows.critImmunity:SetText(string.format("|cFFFF8040%d Def needed|r", s.defNeededForCrit))
    end

    if s.isCrushImmune then
        rows.bossCrush:SetText("|cFF00FF000.0% (IMMUNE)|r")
    else
        rows.bossCrush:SetText(string.format("|cFFFF5555%.1f%%|r |cFFAAAAAA(-%.1f%%)|r", s.bossCrushPct, s.avoidanceToCrushCap))
    end

    -- Section 3: Offense (Dynamically adapts for Caster, Hunter, or Melee/Tank)
    if s.isCaster then
        if self.characterPane.offenseHeader then
            self.characterPane.offenseHeader:SetText("Caster Offense")
            self.characterPane.offenseHeader:SetTextColor(1.0, 0.49, 0.04)
        end
        if leftLabels.weaponDmg then leftLabels.weaponDmg:SetText("Melee Damage:") end
        if leftLabels.attackPower then leftLabels.attackPower:SetText("Bonus Spell Dmg:") end
        if leftLabels.critChance then leftLabels.critChance:SetText("Spell Crit Chance:") end
        if leftLabels.hitChance then leftLabels.hitChance:SetText("Bonus Spell Hit:") end
        if leftLabels.hitCap then leftLabels.hitCap:SetText("Spell Hit Cap (Boss):") end

        rows.weaponDmg:SetText(string.format("|cFFFFFFFF%d - %d|r |cFFAAAAAA(%.1fs)|r", math.floor(s.lowDmg + 0.5), math.floor(s.hiDmg + 0.5), s.mainSpeed))
        rows.attackPower:SetText("|cFF00CCFF+" .. FormatNumber(s.maxSpellPower or 0) .. "|r")
        rows.critChance:SetText(string.format("|cFFFFFFFF%.2f%%|r", s.spellCritPct or 0))
        rows.hitChance:SetText(string.format("|cFFFFFFFF+%.1f%%|r", s.spellHitPct or 0))
        if s.isSpellHitCappedBoss then
            rows.hitCap:SetText("|cFF00FF00CAPPED (16.0%+)|r")
        else
            rows.hitCap:SetText(string.format("|cFFFF8040%.1f%% Hit needed|r", s.spellHitNeededBoss or 16.0))
        end
    elseif s.classFile == "HUNTER" then
        if self.characterPane.offenseHeader then
            self.characterPane.offenseHeader:SetText("Ranged & Melee Offense")
            self.characterPane.offenseHeader:SetTextColor(1.0, 0.49, 0.04)
        end
        if leftLabels.weaponDmg then leftLabels.weaponDmg:SetText("Ranged Damage:") end
        if leftLabels.attackPower then leftLabels.attackPower:SetText("Ranged Attack Power:") end
        if leftLabels.critChance then leftLabels.critChance:SetText("Ranged Crit Chance:") end
        if leftLabels.hitChance then leftLabels.hitChance:SetText("Bonus Ranged Hit:") end
        if leftLabels.hitCap then leftLabels.hitCap:SetText("Ranged Hit Cap (Boss):") end

        local rSpd = (s.rangedSpeed and s.rangedSpeed > 0) and s.rangedSpeed or s.mainSpeed
        rows.weaponDmg:SetText(string.format("|cFFFFFFFF%d - %d|r |cFFAAAAAA(%.1fs)|r", math.floor((s.rangedLow or s.lowDmg) + 0.5), math.floor((s.rangedHi or s.hiDmg) + 0.5), rSpd))
        rows.attackPower:SetText("|cFFFFFFFF" .. FormatNumber(s.rangedAP or s.totalAP) .. "|r")
        rows.critChance:SetText(string.format("|cFFFFFFFF%.2f%%|r", s.rangedCritPct or s.meleeCritPct))
        rows.hitChance:SetText(string.format("|cFFFFFFFF+%.1f%%|r", s.rangedHitPct or s.meleeHitPct))
        if s.isHitCappedBoss then
            rows.hitCap:SetText(string.format("|cFF00FF00CAPPED (%.1f%%+)|r", s.whiteHitCapBoss or 9.0))
        else
            rows.hitCap:SetText(string.format("|cFFFF8040%.1f%% Hit needed|r", s.hitNeededBoss))
        end
    else
        if self.characterPane.offenseHeader then
            self.characterPane.offenseHeader:SetText("Tank / Melee Offense")
            self.characterPane.offenseHeader:SetTextColor(1.0, 0.49, 0.04)
        end
        if leftLabels.weaponDmg then leftLabels.weaponDmg:SetText("Weapon Damage:") end
        if leftLabels.attackPower then leftLabels.attackPower:SetText("Attack Power:") end
        if leftLabels.critChance then leftLabels.critChance:SetText("Melee Crit Chance:") end
        if leftLabels.hitChance then leftLabels.hitChance:SetText("Bonus Melee Hit:") end
        if leftLabels.hitCap then leftLabels.hitCap:SetText("White Hit Cap (Boss):") end

        rows.weaponDmg:SetText(string.format("|cFFFFFFFF%d - %d|r |cFFAAAAAA(%.1fs)|r", math.floor(s.lowDmg + 0.5), math.floor(s.hiDmg + 0.5), s.mainSpeed))
        rows.attackPower:SetText("|cFFFFFFFF" .. FormatNumber(s.totalAP) .. "|r")
        rows.critChance:SetText(string.format("|cFFFFFFFF%.2f%%|r", s.meleeCritPct))
        rows.hitChance:SetText(string.format("|cFFFFFFFF+%.1f%%|r", s.meleeHitPct))
        if s.isHitCappedBoss then
            rows.hitCap:SetText(string.format("|cFF00FF00CAPPED (%.1f%%+)|r", s.whiteHitCapBoss or 9.0))
        else
            rows.hitCap:SetText(string.format("|cFFFF8040%.1f%% Hit needed|r", s.hitNeededBoss))
        end
    end

    self:LayoutCharacterPane()
end

-- ============================================================================
-- EVENT HANDLER FOR LIVE STAT UPDATES
-- ============================================================================
local eventFrame = CreateFrame("Frame")
local trackedEvents = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "SPELLS_CHANGED",
    "TRAIT_CONFIG_UPDATED",
    "UNIT_STATS",
    "UNIT_AURA",
    "UNIT_DAMAGE",
    "UNIT_ATTACK_POWER",
    "UNIT_DEFENSE",
    "UNIT_RESISTANCES",
    "UNIT_MAXHEALTH",
    "COMBAT_RATING_UPDATE",
    "PLAYER_DAMAGE_DONE_MODS",
    "UPDATE_SHAPESHIFT_FORM",
    "PLAYER_EQUIPMENT_CHANGED",
    "CHARACTER_POINTS_CHANGED",
    "UNIT_PET",
    "PET_UI_UPDATE",
    "PET_BAR_UPDATE",
    "UNIT_HAPPINESS",
}
for _, ev in ipairs(trackedEvents) do
    pcall(eventFrame.RegisterEvent, eventFrame, ev)
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "ForeverCalc" or arg1 == "ForeverStats" or arg1 == "FeralCalc" or arg1 == "ForeverFeral" or arg1 == "ForeverTank") then
        FeralCalc:InitDB()
        FeralCalc:RegisterSlashCommands()
        FeralCalc:CreateCharacterPane()
        FeralCalc:CreatePriorityPane()
        FeralCalc:CreateThreatPane()
        FeralCalc:CreatePetPane()
        if FeralCalc.CreateMinimapButton then FeralCalc:CreateMinimapButton() end
    elseif event == "PLAYER_LOGIN" then
        FeralCalc:InitDB()
        FeralCalc:RegisterSlashCommands()
        if FeralCalc.CreateMinimapButton then FeralCalc:CreateMinimapButton() end
        FeralCalc:Print("Loaded! Click the |cFFFF7D0AMinimap Crown|r or type |cFFFFFF00/fs|r for options.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        FeralCalc:InitDB()
        FeralCalc:RegisterSlashCommands()
        FeralCalc:ScanSpellbook()
        FeralCalc:CreateCharacterPane()
        FeralCalc:CreatePriorityPane()
        FeralCalc:CreateThreatPane()
        FeralCalc:CreatePetPane()
        if FeralCalc.CreateMinimapButton then FeralCalc:CreateMinimapButton() end
        FeralCalc:UpdateCharacterPane()
        FeralCalc:UpdatePriorityPane()
        FeralCalc:UpdateThreatPane()
        FeralCalc:UpdatePetPane()
    elseif event == "SPELLS_CHANGED" then
        FeralCalc:ScanSpellbook()
        FeralCalc:UpdateCharacterPane()
        FeralCalc:UpdatePriorityPane()
        FeralCalc:UpdateThreatPane()
        FeralCalc:UpdatePetPane()
    elseif event == "UNIT_PET" or event == "PET_UI_UPDATE" or event == "PET_BAR_UPDATE" or event == "UNIT_HAPPINESS" then
        FeralCalc:UpdatePetPane()
    else
        if arg1 == "pet" and event:find("^UNIT_") then
            FeralCalc:UpdatePetPane()
            return
        end
        if arg1 and arg1 ~= "player" and event:find("^UNIT_") then
            return
        end
        FeralCalc:UpdateCharacterPane()
        FeralCalc:UpdatePriorityPane()
        FeralCalc:UpdateThreatPane()
    end
end)
