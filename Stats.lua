local addonName, FeralCalc = ...

-- Default SavedVariables
local DEFAULT_DB = {
    showPostArmor = true,
    showCharacterPane = true,
    showPriorityPane = false,
    showThreatPane = false,
    showMinimapButton = true,
    minimapAngle = 225,
    prioPoint = nil,
    threatPoint = nil,
}

local function IsSecret(val)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, val)
        if not ok or secret then return true end
    end
    return false
end

local function SafeNumber(val, default)
    if val == nil or IsSecret(val) or type(val) ~= "number" or val ~= val then
        return default or 0
    end
    return val
end

local function SafeString(val)
    if val == nil or IsSecret(val) or type(val) ~= "string" then
        return nil
    end
    return val
end

function FeralCalc:Print(msg)
    local text = "|cFFFF7D0A[ForeverStats]|r " .. tostring(msg)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    else
        print(text)
    end
end

function FeralCalc:InitDB()
    if type(FeralCalcDB) ~= "table" then
        FeralCalcDB = {}
    end
    for k, v in pairs(DEFAULT_DB) do
        if FeralCalcDB[k] == nil then
            FeralCalcDB[k] = v
        end
    end
    if type(FeralCalcDB.collapsedSectionsByChar) ~= "table" then
        FeralCalcDB.collapsedSectionsByChar = {}
    end
    self.db = FeralCalcDB
end

-- ============================================================================
-- SLASH COMMANDS (/ft, /tank, /fc, /feralcalc, /fcalc) - Registered upfront
-- ============================================================================
local function HandleSlashCommand(msg)
    FeralCalc:InitDB()
    local cmd = (type(msg) == "string" and msg or ""):lower():match("^%s*(%S*)") or ""

    if cmd == "toggle" then
        if FeralCalc.ToggleCharacterPane then
            local ok, err = pcall(FeralCalc.ToggleCharacterPane, FeralCalc, true)
            if not ok then
                FeralCalc:Print("|cFFFF5555Error in toggle:|r " .. tostring(err))
            end
        else
            FeralCalc:Print("CharacterPane module not ready yet.")
        end
    elseif cmd == "prio" or cmd == "priority" or cmd == "list" or cmd == "skills" then
        if FeralCalc.TogglePriorityPane then
            local ok, err = pcall(FeralCalc.TogglePriorityPane, FeralCalc)
            if not ok then
                FeralCalc:Print("|cFFFF5555Error in prio:|r " .. tostring(err))
            end
        else
            FeralCalc:Print("Priority pane not ready yet.")
        end
    elseif cmd == "threat" or cmd == "tpr" or cmd == "tpm" then
        if FeralCalc.ToggleThreatPane then
            local ok, err = pcall(FeralCalc.ToggleThreatPane, FeralCalc)
            if not ok then
                FeralCalc:Print("|cFFFF5555Error in threat:|r " .. tostring(err))
            end
        else
            FeralCalc:Print("Threat pane not ready yet.")
        end
    elseif cmd == "armor" then
        FeralCalc.db.showPostArmor = not FeralCalc.db.showPostArmor
        local state = FeralCalc.db.showPostArmor and "|cFF00FF00ENABLED|r" or "|cFFFF5555DISABLED|r"
        FeralCalc:Print("Post-armor tooltip estimates (vs Lvl 63 Boss, 3731 Armor): " .. state)
        if FeralCalc.RefreshOptionsFrame then FeralCalc:RefreshOptionsFrame() end
    elseif cmd == "options" or cmd == "config" or cmd == "menu" or cmd == "opt" then
        if FeralCalc.ToggleOptionsFrame then
            FeralCalc:ToggleOptionsFrame()
        else
            FeralCalc:Print("Options module not ready yet.")
        end
    elseif cmd == "minimap" then
        FeralCalc.db.showMinimapButton = not FeralCalc.db.showMinimapButton
        if FeralCalc.UpdateMinimapButtonVisibility then
            FeralCalc:UpdateMinimapButtonVisibility()
        end
        if FeralCalc.RefreshOptionsFrame then FeralCalc:RefreshOptionsFrame() end
        local state = FeralCalc.db.showMinimapButton and "|cFF00FF00SHOWN|r" or "|cFFFF5555HIDDEN|r"
        FeralCalc:Print("Minimap button: " .. state)
    elseif cmd == "debug" or cmd == "dump" then
        local ok, err = pcall(FeralCalc.DumpDebugInfo, FeralCalc)
        if not ok then
            FeralCalc:Print("|cFFFF5555Error in debug:|r " .. tostring(err))
        end
    else
        FeralCalc:Print("Commands (Aliases: |cFFFFFF00/fs|r, |cFFFFFF00/ft|r, |cFFFFFF00/fc|r):")
        FeralCalc:Print("  |cFFFFFF00/fs options|r - Open the ForeverStats Options menu")
        FeralCalc:Print("  |cFFFFFF00/fs prio|r    - Show/hide the movable Top-7 Skill Priority window")
        FeralCalc:Print("  |cFFFFFF00/fs threat|r  - Show/hide the movable Top-5 Threat Priority window")
        FeralCalc:Print("  |cFFFFFF00/fs toggle|r  - Show/hide the Character Sheet Stats pane")
        FeralCalc:Print("  |cFFFFFF00/fs armor|r   - Toggle post-armor mitigation preview in spell tooltips")
        FeralCalc:Print("  |cFFFFFF00/fs minimap|r - Show/hide the Minimap button")
        FeralCalc:Print("  |cFFFFFF00/fs debug|r   - Dump live Stance/Form, Stats, Talents & Spell IDs")
    end
end

local function HandlePrioSlashCommand()
    HandleSlashCommand("prio")
end

local function HandleThreatSlashCommand()
    HandleSlashCommand("threat")
end

function FeralCalc:RegisterSlashCommands()
    SLASH_FERALCALC1 = "/fs"
    SLASH_FERALCALC2 = "/fstats"
    SLASH_FERALCALC3 = "/ft"
    SLASH_FERALCALC4 = "/tank"
    SLASH_FERALCALC5 = "/fc"
    SLASH_FERALCALC6 = "/feralcalc"
    SLASH_FERALCALC7 = "/fcalc"
    SlashCmdList["FERALCALC"] = HandleSlashCommand

    SLASH_FERALCALCPRIO1 = "/fsprio"
    SLASH_FERALCALCPRIO2 = "/ftprio"
    SLASH_FERALCALCPRIO3 = "/fcprio"
    SlashCmdList["FERALCALCPRIO"] = HandlePrioSlashCommand

    SLASH_FERALCALCTHREAT1 = "/fsthreat"
    SLASH_FERALCALCTHREAT2 = "/ftthreat"
    SLASH_FERALCALCTHREAT3 = "/fcthreat"
    SlashCmdList["FERALCALCTHREAT"] = HandleThreatSlashCommand

    if type(hash_SlashCmdList) == "table" then
        hash_SlashCmdList["/FS"] = HandleSlashCommand
        hash_SlashCmdList["/FSTATS"] = HandleSlashCommand
        hash_SlashCmdList["/FT"] = HandleSlashCommand
        hash_SlashCmdList["/TANK"] = HandleSlashCommand
        hash_SlashCmdList["/FC"] = HandleSlashCommand
        hash_SlashCmdList["/FERALCALC"] = HandleSlashCommand
        hash_SlashCmdList["/FCALC"] = HandleSlashCommand
        hash_SlashCmdList["/FSPRIO"] = HandlePrioSlashCommand
        hash_SlashCmdList["/FTPRIO"] = HandlePrioSlashCommand
        hash_SlashCmdList["/FCPRIO"] = HandlePrioSlashCommand
        hash_SlashCmdList["/FSTHREAT"] = HandleThreatSlashCommand
        hash_SlashCmdList["/FTTHREAT"] = HandleThreatSlashCommand
        hash_SlashCmdList["/FCTHREAT"] = HandleThreatSlashCommand
    end
end

FeralCalc:RegisterSlashCommands()

-- ============================================================================
-- SPELL HELPERS & SPELLBOOK SCANNER
-- ============================================================================
function FeralCalc:GetSpellNameByID(spellID)
    if not spellID then return nil end
    if C_Spell and type(C_Spell.GetSpellName) == "function" then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and SafeString(name) then return name end
    end
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(info) == "table" and SafeString(info.name) then return info.name end
    end
    if type(GetSpellInfo) == "function" then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and SafeString(name) then return name end
    end
    return nil
end

function FeralCalc:GetSpellSubtextByID(spellID)
    if not spellID then return nil end
    if C_Spell and type(C_Spell.GetSpellSubtext) == "function" then
        local ok, sub = pcall(C_Spell.GetSpellSubtext, spellID)
        if ok and SafeString(sub) and sub ~= "" then return sub end
    end
    if type(GetSpellSubtext) == "function" then
        local ok, sub = pcall(GetSpellSubtext, spellID)
        if ok and SafeString(sub) and sub ~= "" then return sub end
    end
    if self.SpellbookRankByID and self.SpellbookRankByID[spellID] then
        return "Rank " .. tostring(self.SpellbookRankByID[spellID])
    end
    return nil
end

function FeralCalc:ScanSpellbook()
    self.SpellbookRankByID = self.SpellbookRankByID or {}
    self.HighestKnownRankByName = {}
    local found = {}

    local function RecordSpell(spellName, subName, spellID)
        spellName = SafeString(spellName)
        subName = SafeString(subName)
        if not spellName then return end

        local cleanName, inlineRank = spellName:match("^(.-)%s*%(Rank%s*(%d+)%)$")
        if cleanName then spellName = cleanName end

        local rankNum = tonumber(inlineRank) or (subName and tonumber(subName:match("(%d+)"))) or nil
        if not rankNum and spellID and self.SpellData[spellID] then
            rankNum = self.SpellData[spellID].rank
        end
        if spellID and rankNum then
            self.SpellbookRankByID[spellID] = rankNum
        end

        local cur = self.HighestKnownRankByName[spellName]
        local entryObj = {
            name = spellName,
            rank = rankNum or 1,
            spellID = spellID,
            subText = rankNum and ("Rank " .. tostring(rankNum)) or (subName or ""),
        }
        if not cur or (rankNum and rankNum >= (cur.rank or 0)) then
            self.HighestKnownRankByName[spellName] = entryObj
        end

        if spellID and self.SpellData[spellID] and self.SpellData[spellID].name and self.SpellData[spellID].name ~= spellName then
            local canonicalName = self.SpellData[spellID].name
            local curCanon = self.HighestKnownRankByName[canonicalName]
            if not curCanon or (rankNum and rankNum >= (curCanon.rank or 0)) then
                self.HighestKnownRankByName[canonicalName] = entryObj
            end
        end

        table.insert(found, { name = spellName, subText = subName or "", spellID = spellID, rank = rankNum })
    end

    pcall(function()
        if type(GetNumSpellTabs) == "function" and type(GetSpellTabInfo) == "function" then
            for tab = 1, GetNumSpellTabs() do
                local _, _, offset, numSlots = GetSpellTabInfo(tab)
                for slot = (offset or 0) + 1, (offset or 0) + (numSlots or 0) do
                    local spellName, subName = GetSpellBookItemName(slot, BOOKTYPE_SPELL or "spell")
                    local _, spellID = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL or "spell")
                    RecordSpell(spellName, subName, spellID)
                end
            end
        elseif C_SpellBook and type(C_SpellBook.GetNumSpellBookSkillLines) == "function" then
            local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
            local numLines = C_SpellBook.GetNumSpellBookSkillLines() or 0
            for tab = 1, numLines do
                local tabData = C_SpellBook.GetSpellBookSkillLineInfo(tab)
                if type(tabData) == "table" then
                    local offset = tabData.itemIndexOffset or 0
                    local numSlots = tabData.numSpellBookItems or 0
                    for slot = offset + 1, offset + numSlots do
                        local spellName, subName = C_SpellBook.GetSpellBookItemName(slot, bank)
                        local itemInfo = C_SpellBook.GetSpellBookItemInfo and C_SpellBook.GetSpellBookItemInfo(slot, bank)
                        local spellID = type(itemInfo) == "table" and (itemInfo.spellID or itemInfo.actionID) or nil
                        RecordSpell(spellName, subName, spellID)
                    end
                end
            end
        end
    end)

    return found
end

-- ============================================================================
-- DYNAMIC CLASS, FORM, STANCE & AURA DETECTION (Druid / Warrior / Paladin)
-- ============================================================================
function FeralCalc:GetPlayerClass()
    if type(UnitClass) == "function" then
        local ok, className, classFile = pcall(UnitClass, "player")
        if ok and SafeString(classFile) then
            return classFile, SafeString(className) or classFile
        end
    end
    return "DRUID", "Druid"
end

function FeralCalc:HasPlayerAura(spellID)
    if not spellID then return false end
    if C_UnitAuras and type(C_UnitAuras.GetPlayerAuraBySpellID) == "function" then
        if C_Secrets and type(C_Secrets.ShouldSpellAuraBeSecret) == "function" and C_Secrets.ShouldSpellAuraBeSecret(spellID) then
            return false
        end
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and aura ~= nil then return true end
    end
    return false
end

function FeralCalc:GetCurrentForm()
    local classFile = self:GetPlayerClass()
    local formIndex = 0
    if type(GetShapeshiftForm) == "function" then
        local ok, idx = pcall(GetShapeshiftForm)
        if ok then formIndex = SafeNumber(idx, 0) end
    end

    local icon, active, castable, spellID
    if formIndex > 0 and type(GetShapeshiftFormInfo) == "function" then
        local ok, ic, act, cast, sID = pcall(GetShapeshiftFormInfo, formIndex)
        if ok then icon, active, castable, spellID = ic, act, cast, sID end
    end
    local spellName = self:GetSpellNameByID(spellID)
    local iconStr = tostring(SafeString(icon) or ""):lower()
    local nameStr = tostring(SafeString(spellName) or ""):lower()

    -- 1. WARRIOR STANCES
    if classFile == "WARRIOR" then
        if spellID == 71 or nameStr:find("defensive", 1, true) or formIndex == 2 then
            return "DEFENSIVE_STANCE", "Defensive Stance (-10%)", 0, formIndex, spellID, 0.90
        elseif spellID == 2457 or nameStr:find("battle", 1, true) or formIndex == 1 then
            return "BATTLE_STANCE", "Battle Stance", 0, formIndex, spellID, 1.00
        elseif spellID == 2458 or nameStr:find("berserker", 1, true) or formIndex == 3 then
            return "BERSERKER_STANCE", "Berserker Stance (+10%)", 0, formIndex, spellID, 1.10
        end
        return "NO_STANCE", "No Stance", 0, 0, nil, 1.00
    end

    -- 2. PALADIN AURAS & RIGHTEOUS FURY
    if classFile == "PALADIN" then
        local hasRF = self:HasPlayerAura(25780)
        local rfSuffix = hasRF and " |cFF00FF00[RF]|r" or ""
        local auraDisplay = spellName or (formIndex > 0 and ("Aura " .. tostring(formIndex)) or "No Aura")
        return hasRF and "PALADIN_RF" or "PALADIN", auraDisplay .. rfSuffix, 0, formIndex, spellID, 1.00
    end

    -- 3. DRUID SHAPESHIFT FORMS
    if formIndex == 0 then
        return "CASTER", (classFile == "DRUID" and "Caster Form" or "Normal"), 0, 0, nil, 1.00
    end

    if spellID == 9634 or nameStr:find("dire bear", 1, true) then
        return "DIRE_BEAR", "Dire Bear Form", self.Constants.BEAR_SPEED, formIndex, spellID, 1.00
    elseif spellID == 5487 or nameStr:find("bear", 1, true) or iconStr:find("bearform", 1, true) then
        return "BEAR", "Bear Form", self.Constants.BEAR_SPEED, formIndex, spellID, 1.00
    elseif spellID == 768 or nameStr:find("cat", 1, true) or iconStr:find("catform", 1, true) then
        return "CAT", "Cat Form", self.Constants.CAT_SPEED, formIndex, spellID, 1.00
    elseif spellID == 1066 or nameStr:find("aquatic", 1, true) or iconStr:find("aquaticform", 1, true) then
        return "AQUATIC", "Aquatic Form", 2.0, formIndex, spellID, 1.00
    elseif spellID == 783 or nameStr:find("travel", 1, true) or iconStr:find("travelform", 1, true) then
        return "TRAVEL", "Travel Form", 2.0, formIndex, spellID, 1.00
    elseif spellID == 24858 or nameStr:find("moonkin", 1, true) or iconStr:find("treant", 1, true) then
        return "MOONKIN", "Moonkin Form", 2.0, formIndex, spellID, 1.00
    end

    if classFile == "DRUID" then
        if formIndex == 1 then
            return "BEAR", "Bear Form", self.Constants.BEAR_SPEED, formIndex, spellID, 1.00
        elseif formIndex == 3 then
            return "CAT", "Cat Form", self.Constants.CAT_SPEED, formIndex, spellID, 1.00
        end
    end

    return "OTHER", spellName or ("Form " .. tostring(formIndex)), 2.0, formIndex, spellID, 1.00
end

-- ============================================================================
-- DYNAMIC TALENT SCANNER (Supports Classic GetTalentInfo & Forever C_Traits)
-- ============================================================================
function FeralCalc:GetTalentStats()
    local talents = {
        savageFury = 0,
        naturalist = 0,
        naturalWeapons = 0,
        feralAggression = 0,
        ferocity = 0,
        improvedShred = 0,
        sharpenedClaws = 0,
        predatoryStrikes = 0,
        thickHide = 0,
        heartOfTheWild = 0,
        survivalOfFittest = 0,
        oneHandSpec = 0,
        impHeroicStrike = 0,
        impThunderClap = 0,
        discovered = {},
        tabPoints = {},
        tabNames = {},
    }

    local function RecordTalent(tab, index, name, rank, maxRank)
        name = SafeString(name)
        if not name then return end
        rank = SafeNumber(rank, 0)
        maxRank = SafeNumber(maxRank, 0)
        if tab and rank > 0 then
            talents.tabPoints[tab] = (talents.tabPoints[tab] or 0) + rank
        end

        local key = self.TrackedTalentNames[name]
        if not key then
            local lowerName = name:lower()
            for trackedName, trackedKey in pairs(self.TrackedTalentNames) do
                if trackedName:lower() == lowerName then
                    key = trackedKey
                    break
                end
            end
        end

        if key then
            talents[key] = math.max(talents[key] or 0, rank)
            table.insert(talents.discovered, {
                tab = tab,
                index = index,
                name = name,
                rank = rank,
                maxRank = maxRank,
            })
        elseif rank > 0 then
            table.insert(talents.discovered, {
                tab = tab,
                index = index,
                name = name,
                rank = rank,
                maxRank = maxRank,
            })
        end
    end

    pcall(function()
        if type(GetNumTalentTabs) == "function" and type(GetTalentInfo) == "function" then
            local numTabs = SafeNumber(GetNumTalentTabs(), 0)
            for tab = 1, numTabs do
                local tabApiPts = 0
                if type(GetTalentTabInfo) == "function" then
                    local okTab, a, b, c, d, e = pcall(GetTalentTabInfo, tab)
                    if okTab then
                        local tabName = SafeString(a) or SafeString(b)
                        if tabName then
                            talents.tabNames[tab] = tabName
                        end
                        tabApiPts = (type(a) == "string" and SafeNumber(c, 0)) or (type(b) == "string" and SafeNumber(e, 0)) or 0
                    end
                end
                local numTalents = type(GetNumTalents) == "function" and SafeNumber(GetNumTalents(tab), 0) or 0
                for index = 1, numTalents do
                    local name, _, _, _, rank, maxRank = GetTalentInfo(tab, index)
                    RecordTalent(tab, index, name, rank, maxRank)
                end
                if tabApiPts > (talents.tabPoints[tab] or 0) then
                    talents.tabPoints[tab] = tabApiPts
                end
            end
        end

        if #talents.discovered == 0 and C_Traits and type(C_Traits.GetNodeInfo) == "function" then
            local configID = nil
            if C_ClassTalents and type(C_ClassTalents.GetActiveConfigID) == "function" then
                local ok, cid = pcall(C_ClassTalents.GetActiveConfigID)
                if ok and SafeNumber(cid, 0) > 0 then configID = cid end
            end
            if not configID and PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame and type(PlayerSpellsFrame.TalentsFrame.GetConfigID) == "function" then
                local ok, cid = pcall(PlayerSpellsFrame.TalentsFrame.GetConfigID, PlayerSpellsFrame.TalentsFrame)
                if ok and SafeNumber(cid, 0) > 0 then configID = cid end
            end
            if not configID and type(C_Traits.GetConfigIDBySystemID) == "function" then
                local ok, cid = pcall(C_Traits.GetConfigIDBySystemID, 1)
                if ok and SafeNumber(cid, 0) > 0 then configID = cid end
            end

            if configID and type(C_Traits.GetConfigInfo) == "function" and type(C_Traits.GetTreeNodes) == "function" then
                local okCfg, cfgInfo = pcall(C_Traits.GetConfigInfo, configID)
                local treeIDs = (okCfg and type(cfgInfo) == "table" and type(cfgInfo.treeIDs) == "table") and cfgInfo.treeIDs or {}
                for treeIdx, treeID in ipairs(treeIDs) do
                    if type(C_Traits.GetTreeInfo) == "function" then
                        local okTree, treeInfo = pcall(C_Traits.GetTreeInfo, configID, treeID)
                        if okTree and type(treeInfo) == "table" and SafeString(treeInfo.name) then
                            talents.tabNames[treeIdx] = SafeString(treeInfo.name)
                        end
                    end
                    local okNodes, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
                    if okNodes and type(nodeIDs) == "table" then
                        for _, nodeID in ipairs(nodeIDs) do
                            local okNode, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                            if okNode and type(nodeInfo) == "table" then
                                local rank = SafeNumber(nodeInfo.activeRank or nodeInfo.ranksPurchased, 0)
                                local maxRank = SafeNumber(nodeInfo.maxRanks, 0)
                                local tabKey = treeIdx
                                if SafeNumber(nodeInfo.subTreeID, 0) > 0 then
                                    tabKey = "sub_" .. tostring(nodeInfo.subTreeID)
                                    if not talents.tabNames[tabKey] and type(C_Traits.GetSubTreeInfo) == "function" then
                                        local okSub, subInfo = pcall(C_Traits.GetSubTreeInfo, configID, nodeInfo.subTreeID)
                                        if okSub and type(subInfo) == "table" and SafeString(subInfo.name) then
                                            talents.tabNames[tabKey] = SafeString(subInfo.name)
                                        end
                                    end
                                end
                                local entryID = (type(nodeInfo.activeEntry) == "table" and nodeInfo.activeEntry.entryID)
                                    or (type(nodeInfo.entryIDs) == "table" and nodeInfo.entryIDs[1])
                                if entryID and maxRank > 0 and type(C_Traits.GetEntryInfo) == "function" and type(C_Traits.GetDefinitionInfo) == "function" then
                                    local okEntry, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
                                    if okEntry and type(entryInfo) == "table" and entryInfo.definitionID then
                                        local okDef, defInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
                                        if okDef and type(defInfo) == "table" then
                                            local name = SafeString(defInfo.overrideName) or self:GetSpellNameByID(defInfo.spellID)
                                            RecordTalent(tabKey, nodeID, name, rank, maxRank)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    local natRank = math.max(talents.naturalist or 0, talents.naturalWeapons or 0, talents.oneHandSpec or 0)
    talents.effectiveNaturalistRank = natRank
    talents.savageFuryMod = 1 + (0.10 * (talents.savageFury or 0))
    talents.naturalistMod = 1 + (0.02 * natRank)
    talents.feralAggressionMod = 1 + (0.03 * (talents.feralAggression or 0))

    return talents
end

-- ============================================================================
-- TANK SPEC DETECTOR (Enhancement Shaman, Prot Pally, Prot Warrior, Feral Druid)
-- ============================================================================
local TANK_TREE_CONFIG = {
    SHAMAN  = { keyword = "enhancement", fallbackTab = 2 },
    PALADIN = { keyword = "protection",  fallbackTab = 2 },
    WARRIOR = { keyword = "protection",  fallbackTab = 3 },
    DRUID   = { keyword = "feral",       fallbackTab = 2 },
}

local TANK_TALENT_SIGNATURES = {
    DRUID = {
        ["Ferocity"] = true, ["Feral Aggression"] = true, ["Feral Instinct"] = true,
        ["Brutal Impact"] = true, ["Thick Hide"] = true, ["Feral Swiftness"] = true,
        ["Feral Charge"] = true, ["Sharpened Claws"] = true, ["Shredding Attacks"] = true,
        ["Improved Shred"] = true, ["Predatory Strikes"] = true, ["Primal Fury"] = true,
        ["Savage Fury"] = true, ["Faerie Fire (Feral)"] = true, ["Heart of the Wild"] = true,
        ["Leader of the Pack"] = true, ["Survival of the Fittest"] = true, ["Mangle"] = true,
    },
    WARRIOR = {
        ["Shield Specialization"] = true, ["Anticipation"] = true, ["Improved Bloodrage"] = true,
        ["Toughness"] = true, ["Iron Will"] = true, ["Last Stand"] = true,
        ["Improved Shield Block"] = true, ["Improved Revenge"] = true, ["Defiance"] = true,
        ["Improved Sunder Armor"] = true, ["Improved Disarm"] = true, ["Improved Taunt"] = true,
        ["Improved Shield Wall"] = true, ["Concussion Blow"] = true, ["Improved Shield Bash"] = true,
        ["One-Handed Weapon Specialization"] = true, ["Shield Slam"] = true, ["Devastate"] = true,
    },
    PALADIN = {
        ["Improved Devotion Aura"] = true, ["Redoubt"] = true, ["Precision"] = true,
        ["Guardian's Favor"] = true, ["Toughness"] = true, ["Blessing of Kings"] = true,
        ["Improved Righteous Fury"] = true, ["Shield Specialization"] = true, ["Anticipation"] = true,
        ["Improved Hammer of Justice"] = true, ["Improved Concentration Aura"] = true,
        ["Blessing of Sanctuary"] = true, ["Reckoning"] = true, ["One-Handed Weapon Specialization"] = true,
        ["Holy Shield"] = true, ["Ardent Defender"] = true, ["Avenger's Shield"] = true,
    },
    SHAMAN = {
        ["Ancestral Knowledge"] = true, ["Shield Specialization"] = true, ["Guardian Totems"] = true,
        ["Thundering Strikes"] = true, ["Improved Ghost Wolf"] = true, ["Improved Lightning Shield"] = true,
        ["Enhancing Totems"] = true, ["Two-Handed Axes and Maces"] = true, ["Anticipation"] = true,
        ["Flurry"] = true, ["Toughness"] = true, ["Improved Weapon Totems"] = true,
        ["Elemental Weapons"] = true, ["Parry"] = true, ["Weapon Mastery"] = true,
        ["Stormstrike"] = true, ["Shamanistic Rage"] = true,
    },
}

function FeralCalc:IsTankSpecByTalents(classFile, talents)
    local cfg = classFile and TANK_TREE_CONFIG[classFile]
    if not cfg then
        return false
    end

    -- 1. Check GetPrimaryTalentTree (Cataclysm / MoP / some Forever builds)
    if type(GetPrimaryTalentTree) == "function" then
        local okPrim, primTab = pcall(GetPrimaryTalentTree)
        if okPrim and SafeNumber(primTab, 0) > 0 then
            return primTab == cfg.fallbackTab
        end
    end

    -- 2. Check Specialization API (C_SpecializationInfo or global GetSpecialization)
    local getSpec = (C_SpecializationInfo and type(C_SpecializationInfo.GetSpecialization) == "function" and C_SpecializationInfo.GetSpecialization)
        or (type(GetSpecialization) == "function" and GetSpecialization)
    local getSpecInfo = (C_SpecializationInfo and type(C_SpecializationInfo.GetSpecializationInfo) == "function" and C_SpecializationInfo.GetSpecializationInfo)
        or (type(GetSpecializationInfo) == "function" and GetSpecializationInfo)
    if getSpec and getSpecInfo then
        local okIdx, specIdx = pcall(getSpec)
        if okIdx and SafeNumber(specIdx, 0) > 0 then
            local okInfo, _, specName = pcall(getSpecInfo, specIdx)
            specName = okInfo and SafeString(specName)
            if specName and specName:lower():find(cfg.keyword, 1, true) then
                return true
            end
        end
    end

    talents = talents or self:GetTalentStats()
    local tabPoints = talents and talents.tabPoints or {}
    local tabNames = talents and talents.tabNames or {}

    local maxPoints = 0
    local tabsWithPoints = 0
    for _, pts in pairs(tabPoints) do
        if pts > 0 then
            tabsWithPoints = tabsWithPoints + 1
        end
        if pts > maxPoints then
            maxPoints = pts
        end
    end

    if maxPoints > 0 then
        local targetTab = nil
        for tab, name in pairs(tabNames) do
            if type(name) == "string" and name:lower():find(cfg.keyword, 1, true) then
                targetTab = tab
                break
            end
        end

        -- If multiple tabs exist or tabNames matched the target tree, compare tabPoints directly
        if targetTab ~= nil or tabsWithPoints > 1 or (tabPoints[cfg.fallbackTab] or 0) > 0 then
            targetTab = targetTab or cfg.fallbackTab
            local targetPoints = tabPoints[targetTab] or 0
            return targetPoints > 0 and targetPoints == maxPoints
        end

        -- Fallback: C_Traits merged all trees into a single treeID (only 1 tab has points)
        -- Estimate points in the target tree using discovered talent names.
        local sigs = TANK_TALENT_SIGNATURES[classFile]
        if sigs and type(talents.discovered) == "table" then
            local tankPts = 0
            local totalPts = 0
            for _, t in ipairs(talents.discovered) do
                local r = SafeNumber(t.rank, 0)
                if r > 0 then
                    totalPts = totalPts + r
                    if sigs[t.name] then
                        tankPts = tankPts + r
                    end
                end
            end
            if totalPts > 0 and tankPts > (totalPts / 2) then
                return true
            end
        end
    end

    return false
end

-- ============================================================================
-- SAFE DEFENSE SKILL READER (Supports Classic UnitDefense & Forever 16001)
-- ============================================================================
function FeralCalc:GetPlayerDefense()
    local playerLevel = (type(UnitLevel) == "function" and SafeNumber(UnitLevel("player"), 60)) or 60
    if playerLevel <= 0 then playerLevel = 60 end
    local defaultBase = playerLevel * 5

    if type(UnitDefense) == "function" then
        local ok, baseDef, armorDef = pcall(UnitDefense, "player")
        if ok and SafeNumber(baseDef, 0) > 0 then
            return SafeNumber(baseDef, defaultBase), SafeNumber(armorDef, 0)
        end
    end

    if type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
        local ok, numSkills = pcall(GetNumSkillLines)
        if ok and SafeNumber(numSkills, 0) > 0 then
            local defLocale = SafeString(DEFENSE) or "Defense"
            for i = 1, numSkills do
                local okLine, sName, isHeader, _, sRank, _, sMod = pcall(GetSkillLineInfo, i)
                if okLine and not isHeader and SafeString(sName) and (sName == defLocale or sName == "Defense") then
                    return SafeNumber(sRank, defaultBase), SafeNumber(sMod, 0)
                end
            end
        end
    end

    local bonusDef = 0
    if type(GetCombatRatingBonus) == "function" then
        local ok, bonus = pcall(GetCombatRatingBonus, CR_DEFENSE_SKILL or 2)
        if ok and SafeNumber(bonus, 0) > 0 then
            bonusDef = SafeNumber(bonus, 0)
        end
    end

    if bonusDef == 0 and C_Item and type(C_Item.GetItemStats) == "function" and type(GetInventoryItemLink) == "function" then
        for slot = 1, 18 do
            local okLink, link = pcall(GetInventoryItemLink, "player", slot)
            if okLink and SafeString(link) then
                local ok, stats = pcall(C_Item.GetItemStats, link)
                if ok and type(stats) == "table" then
                    local defStat = SafeNumber(stats["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"], 0)
                    bonusDef = bonusDef + defStat
                end
            end
        end
    end

    return defaultBase, bonusDef
end

-- ============================================================================
-- TANK MITIGATION, AVOIDANCE & OFFENSE STATS ENGINE (Druid / Warrior / Paladin)
-- ============================================================================
function FeralCalc:GetMitigationStats()
    local C = self.Constants
    local classFile, className = self:GetPlayerClass()
    local formKey, formName, formSpeed, formIndex, formSpellID, stanceDmgMult = self:GetCurrentForm()
    stanceDmgMult = stanceDmgMult or 1.0
    local talents = self:GetTalentStats()

    local canParry = (classFile ~= "DRUID" and classFile ~= "SHAMAN" and classFile ~= "PRIEST" and classFile ~= "MAGE" and classFile ~= "WARLOCK")
    local canBlock = (classFile == "WARRIOR" or classFile == "PALADIN" or classFile == "SHAMAN")

    -- Weapon Damage
    local lowDmg, hiDmg, offLowDmg, offHiDmg, posBuff, negBuff, percentMod = 0, 0, 0, 0, 0, 0, 1
    if type(UnitDamage) == "function" then
        local ok, l, h, ol, oh, pb, nb, pm = pcall(UnitDamage, "player")
        if ok then lowDmg, hiDmg, offLowDmg, offHiDmg, posBuff, negBuff, percentMod = l, h, ol, oh, pb, nb, pm end
    end
    lowDmg = SafeNumber(lowDmg, 0)
    hiDmg = SafeNumber(hiDmg, 0)
    percentMod = SafeNumber(percentMod, 1)
    if percentMod <= 0 then percentMod = 1 end
    local avgDmg = (lowDmg + hiDmg) / 2

    local mainSpeed, offSpeed = 0, 0
    if type(UnitAttackSpeed) == "function" then
        local ok, spd, offSpd = pcall(UnitAttackSpeed, "player")
        if ok then
            mainSpeed = SafeNumber(spd, 0)
            offSpeed = SafeNumber(offSpd, 0)
        end
    end
    if mainSpeed <= 0 then
        mainSpeed = (formSpeed and formSpeed > 0) and formSpeed or 2.0
    end

    local isDualWield = false
    if classFile ~= "DRUID" and classFile ~= "HUNTER" then
        if type(IsDualWielding) == "function" then
            local ok, dw = pcall(IsDualWielding)
            if ok and dw then isDualWield = true end
        end
        if not isDualWield and offSpeed > 0 then
            isDualWield = true
        end
    end

    -- Attack Power
    local baseAP, posAP, negAP = 0, 0, 0
    if type(UnitAttackPower) == "function" then
        local ok, b, p, n = pcall(UnitAttackPower, "player")
        if ok then baseAP, posAP, negAP = b, p, n end
    end
    local totalAP = SafeNumber(baseAP, 0) + SafeNumber(posAP, 0) + SafeNumber(negAP, 0)

    -- Armor & Physical Damage Reduction
    local baseArmor, effectiveArmor = 0, 0
    if type(UnitArmor) == "function" then
        local ok, bArmor, effArmor = pcall(UnitArmor, "player")
        if ok then
            baseArmor = SafeNumber(bArmor, 0)
            effectiveArmor = SafeNumber(effArmor, 0)
        end
    end

    local playerLevel = (type(UnitLevel) == "function" and SafeNumber(UnitLevel("player"), 60)) or 60
    if playerLevel <= 0 then playerLevel = 60 end
    local bossLevel = playerLevel + 3
    local equalDefense = playerLevel * 5
    local bossDefense = bossLevel * 5

    local armorConstEqual = 400 + 85 * playerLevel
    local armorConstBoss = 400 + 85 * bossLevel
    local armorCapEqual = 3 * armorConstEqual
    local armorCapBoss = 3 * armorConstBoss

    local rawDR60 = effectiveArmor / (effectiveArmor + armorConstEqual)
    local dr60 = math.min(C.ARMOR_CAP_PCT, rawDR60)

    local rawDR63 = effectiveArmor / (effectiveArmor + armorConstBoss)
    local dr63 = math.min(C.ARMOR_CAP_PCT, rawDR63)

    -- Total physical mitigation including Defensive Stance (-10% dmg taken)
    local effectiveDR63 = 1 - ((1 - dr63) * stanceDmgMult)
    local effectiveDR60 = 1 - ((1 - dr60) * stanceDmgMult)

    local capProgress60 = math.min(100, (effectiveArmor / armorCapEqual) * 100)
    local capProgress63 = math.min(100, (effectiveArmor / armorCapBoss) * 100)
    local armorNeeded60 = math.max(0, armorCapEqual - effectiveArmor)
    local armorNeeded63 = math.max(0, armorCapBoss - effectiveArmor)

    -- Defense Skill & Critical Hit Immunity
    local baseDefense, armorDefense = self:GetPlayerDefense()
    local exactDefense = baseDefense + armorDefense
    local totalDefense = math.floor(exactDefense + 0.5)

    local bossCritFromDef = 5.0 + (bossDefense - totalDefense) * 0.04
    local talentCritRed = (talents.survivalOfFittest or 0) * 1.0
    local bossCritPct = math.max(0, bossCritFromDef - talentCritRed)
    local critImmuneDef = math.ceil(bossDefense + math.max(0, (5.0 - talentCritRed) / 0.04))
    local defNeededForCrit = math.max(0, critImmuneDef - totalDefense)
    local isCritImmune = (bossCritPct <= 0) or (totalDefense >= critImmuneDef)

    -- Avoidance (Dodge, Parry, Miss) & Block
    local dodgePct = 0
    if type(GetDodgeChance) == "function" then
        local ok, d = pcall(GetDodgeChance)
        if ok then dodgePct = SafeNumber(d, 0) end
    end

    local parryPct = 0
    if canParry and type(GetParryChance) == "function" then
        local ok, p = pcall(GetParryChance)
        if ok then parryPct = SafeNumber(p, 0) end
    end

    local blockPct = 0
    if canBlock and type(GetBlockChance) == "function" then
        local ok, b = pcall(GetBlockChance)
        if ok then blockPct = SafeNumber(b, 0) end
    end

    local blockValue = 0
    if canBlock and type(GetShieldBlock) == "function" then
        local ok, bv = pcall(GetShieldBlock)
        if ok then blockValue = SafeNumber(bv, 0) end
    end

    local bossMissPct = math.max(0, C.BASE_BOSS_MISS + (totalDefense - bossDefense) * 0.04)
    local equalMissPct = math.max(0, C.BASE_BOSS_MISS + (totalDefense - equalDefense) * 0.04)

    -- Pure Avoidance = Miss + Dodge + Parry
    local totalAvoidancePct = bossMissPct + dodgePct + parryPct
    -- Combat Table Coverage = Miss + Dodge + Parry + Block (pushes Crushing Blows off the 102.4% table)
    local combatTablePct = totalAvoidancePct + blockPct

    local bossCrushPct = C.BASE_BOSS_CRUSH
    if combatTablePct >= C.AVOIDANCE_CRUSH_CAP then
        bossCrushPct = 0
    elseif (combatTablePct + bossCritPct) > (C.AVOIDANCE_CRUSH_CAP - C.BASE_BOSS_CRUSH) then
        bossCrushPct = math.max(0, C.AVOIDANCE_CRUSH_CAP - combatTablePct - bossCritPct)
    end
    local avoidanceToCrushCap = math.max(0, C.AVOIDANCE_CRUSH_CAP - combatTablePct)
    local isCrushImmune = (bossCrushPct <= 0)

    -- Health & Effective Health (EHP)
    local maxHP = 1
    if type(UnitHealthMax) == "function" then
        local ok, hp = pcall(UnitHealthMax, "player")
        if ok then maxHP = SafeNumber(hp, 1) end
    end
    if maxHP <= 0 then maxHP = 1 end
    local physicalEHP = maxHP / math.max(0.01, (1 - effectiveDR63))
    local physicalEHP60 = maxHP / math.max(0.01, (1 - effectiveDR60))
    local avoidanceFraction = math.min(0.99, math.max(0, totalAvoidancePct / 100))
    local avoidanceEHP = physicalEHP / (1 - avoidanceFraction)

    -- Offense Crit, Hit & Spell Power
    local meleeCritPct = 0
    if type(GetCritChance) == "function" then
        local ok, c = pcall(GetCritChance)
        if ok then meleeCritPct = SafeNumber(c, 0) end
    end
    local meleeHitPct = 0
    if type(GetHitModifier) == "function" then
        local ok, h = pcall(GetHitModifier)
        if ok then meleeHitPct = SafeNumber(h, 0) end
    end
    if meleeHitPct == 0 and type(GetCombatRatingBonus) == "function" then
        local ok, hitBonus = pcall(GetCombatRatingBonus, CR_HIT_MELEE or 6)
        if ok then meleeHitPct = SafeNumber(hitBonus, 0) end
    end
    local whiteHitCapBoss = isDualWield and 28.0 or 9.0
    local whiteHitCapEqual = isDualWield and 24.0 or 5.0
    local hitNeededBoss = math.max(0, whiteHitCapBoss - meleeHitPct)
    local hitNeededEqual = math.max(0, whiteHitCapEqual - meleeHitPct)
    local isHitCappedBoss = (meleeHitPct >= whiteHitCapBoss)
    local isHitCappedEqual = (meleeHitPct >= whiteHitCapEqual)
    local yellowHitNeededBoss = math.max(0, 9.0 - meleeHitPct)
    local yellowHitNeededEqual = math.max(0, 5.0 - meleeHitPct)
    local isYellowHitCappedBoss = (meleeHitPct >= 9.0)
    local isYellowHitCappedEqual = (meleeHitPct >= 5.0)

    local spellPowerBySchool = {}
    local maxSpellPower = 0
    if type(GetSpellBonusDamage) == "function" then
        for school = 2, 7 do
            local ok, sp = pcall(GetSpellBonusDamage, school)
            local val = ok and SafeNumber(sp, 0) or 0
            spellPowerBySchool[school] = val
            if val > maxSpellPower then maxSpellPower = val end
        end
    end
    local holySpellPower = spellPowerBySchool[2] or 0

    -- Spell Crit & Spell Hit (for Casters)
    local isCaster = (classFile == "WARLOCK" or classFile == "MAGE" or classFile == "PRIEST"
        or (classFile == "DRUID" and formKey ~= "BEAR" and formKey ~= "DIRE_BEAR" and formKey ~= "CAT"))

    local spellCritPct = 0
    if type(GetSpellCritChance) == "function" then
        for school = 2, 7 do
            local ok, sc = pcall(GetSpellCritChance, school)
            local val = ok and SafeNumber(sc, 0) or 0
            if val > spellCritPct then spellCritPct = val end
        end
    end
    if spellCritPct <= 0 then spellCritPct = meleeCritPct end

    local spellHitPct = 0
    if type(GetSpellHitModifier) == "function" then
        local ok, sh = pcall(GetSpellHitModifier)
        if ok then spellHitPct = SafeNumber(sh, 0) end
    end
    if type(GetCombatRatingBonus) == "function" then
        local ok, shBonus = pcall(GetCombatRatingBonus, CR_HIT_SPELL or 8)
        if ok and SafeNumber(shBonus, 0) > spellHitPct then
            spellHitPct = SafeNumber(shBonus, 0)
        end
    end
    local spellHitNeededBoss = math.max(0, 16.0 - spellHitPct)
    local spellHitNeededEqual = math.max(0, 3.0 - spellHitPct)
    local isSpellHitCappedBoss = (spellHitPct >= 16.0)
    local isSpellHitCappedEqual = (spellHitPct >= 3.0)

    -- Ranged Weapon Damage, Ranged AP, Ranged Crit & Ranged Hit (for Hunters)
    local rangedCritPct = meleeCritPct
    if type(GetRangedCritChance) == "function" then
        local ok, rc = pcall(GetRangedCritChance)
        if ok and SafeNumber(rc, 0) > 0 then rangedCritPct = SafeNumber(rc, 0) end
    end
    local rangedHitPct = meleeHitPct
    if type(GetCombatRatingBonus) == "function" then
        local ok, rhBonus = pcall(GetCombatRatingBonus, CR_HIT_RANGED or 7)
        if ok and SafeNumber(rhBonus, 0) > rangedHitPct then
            rangedHitPct = SafeNumber(rhBonus, 0)
        end
    end
    local rangedSpeed, rangedLow, rangedHi = 0, 0, 0
    if type(UnitRangedDamage) == "function" then
        local ok, rSpd, rLow, rHi = pcall(UnitRangedDamage, "player")
        if ok then
            rangedSpeed = SafeNumber(rSpd, 0)
            rangedLow = SafeNumber(rLow, 0)
            rangedHi = SafeNumber(rHi, 0)
        end
    end
    if rangedLow <= 0 and rangedHi <= 0 then
        rangedLow, rangedHi = lowDmg, hiDmg
    end

    local rangedAP = totalAP
    if type(UnitRangedAttackPower) == "function" then
        local ok, rb, rp, rn = pcall(UnitRangedAttackPower, "player")
        if ok then
            local rap = SafeNumber(rb, 0) + SafeNumber(rp, 0) + SafeNumber(rn, 0)
            if rap > 0 then rangedAP = rap end
        end
    end

    local bossArmor = (bossLevel >= 63) and C.BOSS_ARMOR or math.floor(C.BOSS_ARMOR * (bossLevel / 63) + 0.5)
    local bossTargetArmorDR = bossArmor / (bossArmor + 400 + 85 * playerLevel)

    return {
        playerLevel = playerLevel,
        bossLevel = bossLevel,
        equalDefense = equalDefense,
        bossDefense = bossDefense,
        armorConstEqual = armorConstEqual,
        armorConstBoss = armorConstBoss,
        armorCapEqual = armorCapEqual,
        armorCapBoss = armorCapBoss,
        critImmuneDef = critImmuneDef,
        bossArmor = bossArmor,
        classFile = classFile,
        className = className,
        canParry = canParry,
        canBlock = canBlock,
        formKey = formKey,
        formName = formName,
        formSpeed = formSpeed,
        formIndex = formIndex,
        stanceDmgMult = stanceDmgMult,
        maxHP = maxHP,

        -- Mitigation
        baseArmor = baseArmor,
        effectiveArmor = effectiveArmor,
        dr60 = dr60,
        dr60Pct = dr60 * 100,
        dr63 = dr63,
        dr63Pct = dr63 * 100,
        effectiveDR63Pct = effectiveDR63 * 100,
        capProgress60 = capProgress60,
        capProgress63 = capProgress63,
        armorNeeded60 = armorNeeded60,
        armorNeeded63 = armorNeeded63,
        physicalEHP = physicalEHP,
        physicalEHP60 = physicalEHP60,
        avoidanceEHP = avoidanceEHP,

        -- Avoidance & Boss Table
        baseDefense = baseDefense,
        armorDefense = armorDefense,
        totalDefense = totalDefense,
        dodgePct = dodgePct,
        parryPct = parryPct,
        blockPct = blockPct,
        blockValue = blockValue,
        bossMissPct = bossMissPct,
        equalMissPct = equalMissPct,
        totalAvoidancePct = totalAvoidancePct,
        combatTablePct = combatTablePct,
        bossCritPct = bossCritPct,
        defNeededForCrit = defNeededForCrit,
        isCritImmune = isCritImmune,
        bossCrushPct = bossCrushPct,
        avoidanceToCrushCap = avoidanceToCrushCap,
        isCrushImmune = isCrushImmune,

        -- Offense
        lowDmg = lowDmg,
        hiDmg = hiDmg,
        avgDmg = avgDmg,
        percentMod = percentMod,
        mainSpeed = mainSpeed,
        totalAP = totalAP,
        rangedAP = rangedAP,
        rangedLow = rangedLow,
        rangedHi = rangedHi,
        rangedSpeed = rangedSpeed,
        holySpellPower = holySpellPower,
        maxSpellPower = maxSpellPower,
        spellPowerBySchool = spellPowerBySchool,
        isCaster = isCaster,
        spellCritPct = spellCritPct,
        spellHitPct = spellHitPct,
        spellHitNeededBoss = spellHitNeededBoss,
        spellHitNeededEqual = spellHitNeededEqual,
        isSpellHitCappedBoss = isSpellHitCappedBoss,
        isSpellHitCappedEqual = isSpellHitCappedEqual,
        rangedCritPct = rangedCritPct,
        rangedHitPct = rangedHitPct,
        meleeCritPct = meleeCritPct,
        meleeHitPct = meleeHitPct,
        isDualWield = isDualWield,
        whiteHitCapBoss = whiteHitCapBoss,
        whiteHitCapEqual = whiteHitCapEqual,
        hitNeededBoss = hitNeededBoss,
        hitNeededEqual = hitNeededEqual,
        isHitCappedBoss = isHitCappedBoss,
        isHitCappedEqual = isHitCappedEqual,
        yellowHitNeededBoss = yellowHitNeededBoss,
        yellowHitNeededEqual = yellowHitNeededEqual,
        isYellowHitCappedBoss = isYellowHitCappedBoss,
        isYellowHitCappedEqual = isYellowHitCappedEqual,
        bossTargetArmorDR = bossTargetArmorDR,
        bossTargetArmorMult = 1 - bossTargetArmorDR,

        -- Talents
        talents = talents,
    }
end

-- ============================================================================
-- ABILITY DAMAGE & EFFICIENCY CALCULATOR
-- ============================================================================
function FeralCalc:GetEffectivePowerCost(entry, talents, spellID)
    local cost = entry.baseCost or 0
    if entry.powerType == "MANA" and spellID then
        local liveCost = nil
        if C_Spell and type(C_Spell.GetSpellPowerCost) == "function" then
            local ok, costTable = pcall(C_Spell.GetSpellPowerCost, spellID)
            if ok and type(costTable) == "table" and type(costTable[1]) == "table" then
                liveCost = SafeNumber(costTable[1].cost, 0)
            end
        elseif type(GetSpellPowerCost) == "function" then
            local ok, costTable = pcall(GetSpellPowerCost, spellID)
            if ok and type(costTable) == "table" and type(costTable[1]) == "table" then
                liveCost = SafeNumber(costTable[1].cost, 0)
            end
        end
        if liveCost and liveCost > 0 then
            cost = liveCost
        end
    end
    if entry.costTalent == "ferocity" then
        cost = cost - (talents.ferocity or 0)
    elseif entry.costTalent == "improvedShred" then
        cost = cost - ((talents.improvedShred or 0) * 6)
    elseif entry.costTalent == "impHeroicStrike" then
        cost = cost - (talents.impHeroicStrike or 0)
    elseif entry.costTalent == "impThunderClap" then
        local r = talents.impThunderClap or 0
        cost = cost - (r == 3 and 4 or r)
    elseif entry.costTalent == "impSunderArmor" then
        cost = cost - (talents.impSunderArmor or 0)
    end
    return math.max(0, cost)
end

function FeralCalc:GetAbilityDamage(spellID, spellName, spellSubText)
    local entry = self:GetSpellEntry(spellID, spellName, spellSubText)
    if not entry then
        return nil
    end

    local stats = self:GetMitigationStats()
    local talents = stats.talents
    local lowDmg = stats.lowDmg
    local hiDmg = stats.hiDmg
    local avgDmg = stats.avgDmg
    local totalAP = stats.totalAP
    local armorMult = stats.bossTargetArmorMult
    local cost = self:GetEffectivePowerCost(entry, talents, spellID)

    local sfMod = talents.savageFuryMod
    local natMod = talents.naturalistMod
    local faMod = talents.feralAggressionMod

    local displaySpellName = entry.name
    if type(spellName) == "string" and spellName ~= "" then
        local clean = spellName:match("^(.-)%s*%(Rank%s*%d+%)$") or spellName
        if clean ~= "" then displaySpellName = clean end
    end

    local result = {
        entry = entry,
        name = displaySpellName,
        rank = entry.rank,
        type = entry.type,
        powerType = entry.powerType,
        cost = cost,
        formKey = stats.formKey,
        classFile = stats.classFile,
        bossLevel = stats.bossLevel or 63,
        bossArmorDRPct = stats.bossTargetArmorDR * 100,
        talents = talents,
    }

    if entry.type == "bear_strike" or entry.type == "cat_strike" or entry.type == "war_strike" then
        local mod = (entry.type == "war_strike") and natMod or (sfMod * natMod)
        local minDmg = (lowDmg + entry.flatBonus) * mod
        local maxDmg = (hiDmg + entry.flatBonus) * mod
        local avgHit = (minDmg + maxDmg) / 2

        result.mod = mod
        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.minPostArmor = minDmg * armorMult
        result.maxPostArmor = maxDmg * armorMult
        result.avgPostArmor = avgHit * armorMult
        result.efficiency = (cost > 0) and (avgHit / cost) or 0
        result.efficiencyPostArmor = (cost > 0) and (result.avgPostArmor / cost) or 0

    elseif entry.type == "war_shield_slam" then
        local bv = stats.blockValue or 0
        local minDmg = (entry.minBase + bv) * natMod
        local maxDmg = (entry.maxBase + bv) * natMod
        local avgHit = (minDmg + maxDmg) / 2

        result.blockValue = bv
        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.minPostArmor = minDmg * armorMult
        result.maxPostArmor = maxDmg * armorMult
        result.avgPostArmor = avgHit * armorMult
        result.efficiency = (cost > 0) and (avgHit / cost) or 0
        result.efficiencyPostArmor = (cost > 0) and (result.avgPostArmor / cost) or 0

    elseif entry.type == "war_revenge" then
        local minDmg = entry.minBase * natMod
        local maxDmg = entry.maxBase * natMod
        local avgHit = (minDmg + maxDmg) / 2

        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.minPostArmor = minDmg * armorMult
        result.maxPostArmor = maxDmg * armorMult
        result.avgPostArmor = avgHit * armorMult
        result.efficiency = (cost > 0) and (avgHit / cost) or 0
        result.efficiencyPostArmor = (cost > 0) and (result.avgPostArmor / cost) or 0

    elseif entry.type == "war_cleave" then
        local minSingle = (lowDmg + entry.flatBonus) * natMod
        local maxSingle = (hiDmg + entry.flatBonus) * natMod
        local avgSingle = (minSingle + maxSingle) / 2
        local targets = entry.targets or 2
        local avgCleave = avgSingle * targets

        result.targets = targets
        result.singleHit = avgSingle
        result.cleaveTotal = avgCleave
        result.singlePostArmor = avgSingle * armorMult
        result.cleavePostArmor = avgCleave * armorMult
        result.efficiencySingle = (cost > 0) and (avgSingle / cost) or 0
        result.efficiencyCleave = (cost > 0) and (avgCleave / cost) or 0

    elseif entry.type == "war_shield_block" then
        local bv = stats.blockValue or 0
        local charges = entry.charges or 1
        local totalMitigated = bv * charges
        result.blockValue = bv
        result.charges = charges
        result.totalMitigated = totalMitigated
        result.mitigationPerRage = (cost > 0) and (totalMitigated / cost) or 0
        result.newCombatTablePct = stats.combatTablePct + (entry.bonusBlock or 75)

    elseif entry.type == "pal_holy_shield" then
        local charges = entry.charges or 4
        local perBlock = entry.baseDmg + (0.05 * (stats.holySpellPower or 0))
        local totalAllCharges = perBlock * charges
        local bv = stats.blockValue or 0
        local totalMitigated = bv * charges

        result.perBlock = perBlock
        result.charges = charges
        result.totalAllCharges = totalAllCharges
        result.blockValue = bv
        result.totalMitigated = totalMitigated
        result.dpm = (cost > 0) and (totalAllCharges / cost) or 0
        result.mpm = (cost > 0) and (totalMitigated / cost) or 0
        result.newCombatTablePct = stats.combatTablePct + (entry.bonusBlock or 30)

    elseif entry.type == "pal_consecration" then
        local totalHoly = entry.baseTotal + (entry.spRatio * (stats.holySpellPower or 0))
        local perTick = totalHoly / (entry.ticks or 8)
        local cleave3 = totalHoly * 3
        local cleave5 = totalHoly * 5

        result.totalHoly = totalHoly
        result.perTick = perTick
        result.cleave3 = cleave3
        result.cleave5 = cleave5
        result.dpm1 = (cost > 0) and (totalHoly / cost) or 0
        result.dpm3 = (cost > 0) and (cleave3 / cost) or 0
        result.dpm5 = (cost > 0) and (cleave5 / cost) or 0

    elseif entry.type == "pal_holy_nuke" then
        local spBonus = (entry.spRatio or 0.43) * (stats.holySpellPower or 0)
        local minDmg = entry.minBase + spBonus
        local maxDmg = entry.maxBase + spBonus
        local avgHit = (minDmg + maxDmg) / 2

        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.dpm = (cost > 0) and (avgHit / cost) or 0

    elseif entry.type == "cat_shred" then
        local mod = natMod
        local mult = entry.mult or 2.25
        local minDmg = ((lowDmg * mult) + entry.flatBonus) * mod
        local maxDmg = ((hiDmg * mult) + entry.flatBonus) * mod
        local avgHit = (minDmg + maxDmg) / 2

        result.mod = mod
        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.minPostArmor = minDmg * armorMult
        result.maxPostArmor = maxDmg * armorMult
        result.avgPostArmor = avgHit * armorMult
        result.efficiency = (cost > 0) and (avgHit / cost) or 0
        result.efficiencyPostArmor = (cost > 0) and (result.avgPostArmor / cost) or 0

    elseif entry.type == "bear_swipe" then
        local mod = sfMod * natMod
        local singleHit = (entry.baseDmg + (entry.apRatio * totalAP)) * mod
        local targets = entry.targets or 3
        local cleaveTotal = singleHit * targets

        result.mod = mod
        result.singleHit = singleHit
        result.targets = targets
        result.cleaveTotal = cleaveTotal
        result.singlePostArmor = singleHit * armorMult
        result.cleavePostArmor = cleaveTotal * armorMult
        result.efficiencySingle = (cost > 0) and (singleHit / cost) or 0
        result.efficiencyCleave = (cost > 0) and (cleaveTotal / cost) or 0

    elseif entry.type == "bear_lacerate" then
        result.stacks = {}
        for s = 0, 5 do
            local totalBleed = entry.baseBleed + (entry.stackWeaponPct * avgDmg * s)
            local perTick = totalBleed / entry.ticks
            result.stacks[s] = {
                stacks = s,
                totalBleed = totalBleed,
                perTick = perTick,
                dpr = (cost > 0) and (totalBleed / cost) or 0,
            }
        end

    elseif entry.type == "cat_rake" then
        local mod = sfMod * natMod
        local directHit = (entry.baseDirect + (entry.directAP * totalAP)) * mod
        local bleedTotal = (entry.baseBleed + (entry.bleedAP * totalAP)) * mod
        local bleedTick = bleedTotal / entry.ticks
        local totalDmg = directHit + bleedTotal

        local directPostArmor = directHit * armorMult
        local totalPostArmor = directPostArmor + bleedTotal

        result.mod = mod
        result.directHit = directHit
        result.bleedTotal = bleedTotal
        result.bleedTick = bleedTick
        result.totalDmg = totalDmg
        result.directPostArmor = directPostArmor
        result.totalPostArmor = totalPostArmor
        result.efficiency = (cost > 0) and (totalDmg / cost) or 0
        result.efficiencyPostArmor = (cost > 0) and (totalPostArmor / cost) or 0

    elseif entry.type == "cat_pounce" then
        local bleedTotal = entry.baseBleed + (entry.bleedAP * totalAP)
        local bleedTick = bleedTotal / entry.ticks
        result.bleedTotal = bleedTotal
        result.bleedTick = bleedTick
        result.ticks = entry.ticks
        result.duration = entry.duration
        result.efficiency = (cost > 0) and (bleedTotal / cost) or 0

    elseif entry.type == "cat_rip" then
        result.comboPoints = {}
        for cp = 1, 5 do
            local ratio = entry.apRatio[cp] or (0.04 * cp)
            local perTick = entry.baseTick + (entry.cpTickBonus * cp) + (ratio * totalAP)
            local totalBleed = perTick * entry.ticks
            result.comboPoints[cp] = {
                cp = cp,
                perTick = perTick,
                totalBleed = totalBleed,
                dpe = (cost > 0) and (totalBleed / cost) or 0,
            }
        end

    elseif entry.type == "cat_fb" then
        local mod = faMod * natMod
        local currentEnergy = 0
        local energyType = (Enum and Enum.PowerType and Enum.PowerType.Energy) or 3
        if type(UnitPower) == "function" then
            local ok, en = pcall(UnitPower, "player", energyType)
            if ok then currentEnergy = SafeNumber(en, 0) end
        end
        local extraEnergy = (stats.formKey == "CAT" and currentEnergy > cost) and (currentEnergy - cost) or 0
        local extraDmg = (extraEnergy * entry.energyMod) * mod
        local totalEnergyUsed = cost + extraEnergy

        result.mod = mod
        result.extraEnergy = extraEnergy
        result.extraDmg = extraDmg
        result.totalEnergyUsed = totalEnergyUsed
        result.comboPoints = {}

        for cp = 1, 5 do
            local minBaseNoExtra = (entry.minBase + (entry.perCP * cp) + (entry.apRatio * totalAP)) * mod
            local maxBaseNoExtra = (entry.maxBase + (entry.perCP * cp) + (entry.apRatio * totalAP)) * mod
            local avgNoExtra = (minBaseNoExtra + maxBaseNoExtra) / 2
            local minBase = minBaseNoExtra + extraDmg
            local maxBase = maxBaseNoExtra + extraDmg
            local avgHit = (minBase + maxBase) / 2
            result.comboPoints[cp] = {
                cp = cp,
                minDmg = minBase,
                maxDmg = maxBase,
                avgDmg = avgHit,
                avgBaseDmg = avgNoExtra,
                minPostArmor = minBase * armorMult,
                maxPostArmor = maxBase * armorMult,
                avgPostArmor = avgHit * armorMult,
                dpe = (totalEnergyUsed > 0) and (avgHit / totalEnergyUsed) or 0,
                dpeBase = (cost > 0) and (avgNoExtra / cost) or 0,
                dpeBasePostArmor = (cost > 0) and ((avgNoExtra * armorMult) / cost) or 0,
            }
        end

    elseif entry.type == "melee_strike" then
        local mult = entry.mult or 1.0
        local flat = entry.flatBonus or 0
        local minDmg = ((lowDmg * mult) + flat) * natMod
        local maxDmg = ((hiDmg * mult) + flat) * natMod
        local avgHit = (minDmg + maxDmg) / 2

        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.minPostArmor = minDmg * armorMult
        result.maxPostArmor = maxDmg * armorMult
        result.avgPostArmor = avgHit * armorMult
        result.efficiency = (cost > 0) and (avgHit / cost) or 0
        result.efficiencyPostArmor = (cost > 0) and (result.avgPostArmor / cost) or 0

    elseif entry.type == "ap_strike" then
        local apBonus = (entry.apRatio or 0) * totalAP
        local minDmg = ((entry.minBase or 0) + apBonus) * natMod
        local maxDmg = ((entry.maxBase or 0) + apBonus) * natMod
        local avgHit = (minDmg + maxDmg) / 2

        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.minPostArmor = minDmg * armorMult
        result.maxPostArmor = maxDmg * armorMult
        result.avgPostArmor = avgHit * armorMult
        result.efficiency = (cost > 0) and (avgHit / cost) or 0
        result.efficiencyPostArmor = (cost > 0) and (result.avgPostArmor / cost) or 0

    elseif entry.type == "melee_bleed" then
        local bleedTotal = (entry.baseBleed or 0) + ((entry.bleedAP or 0) * totalAP)
        local ticks = entry.ticks or 6
        local bleedTick = bleedTotal / ticks

        result.bleedTotal = bleedTotal
        result.bleedTick = bleedTick
        result.ticks = ticks
        result.duration = entry.duration or 18
        result.efficiency = (cost > 0) and (bleedTotal / cost) or 0
        result.efficiencyPostArmor = result.efficiency

    elseif entry.type == "rogue_evis" then
        result.comboPoints = {}
        for cp = 1, 5 do
            local apBonus = (entry.apPerCP or 0.03) * cp * totalAP
            local minDmg = (entry.minBase or 0) + ((entry.perCP or 0) * (cp - 1)) + apBonus
            local maxDmg = (entry.maxBase or 0) + ((entry.perCP or 0) * (cp - 1)) + apBonus
            local avgHit = (minDmg + maxDmg) / 2
            result.comboPoints[cp] = {
                cp = cp,
                minDmg = minDmg,
                maxDmg = maxDmg,
                avgDmg = avgHit,
                avgBaseDmg = avgHit,
                minPostArmor = minDmg * armorMult,
                maxPostArmor = maxDmg * armorMult,
                avgPostArmor = avgHit * armorMult,
                dpe = (cost > 0) and (avgHit / cost) or 0,
                dpeBase = (cost > 0) and (avgHit / cost) or 0,
                dpeBasePostArmor = (cost > 0) and ((avgHit * armorMult) / cost) or 0,
            }
        end

    elseif entry.type == "rogue_rupture" then
        result.comboPoints = {}
        local base5 = entry.base5 or 100
        for cp = 1, 5 do
            local scale = (0.20 + (0.16 * cp))
            local totalBleed = (base5 * scale) + (((entry.apRatio5 or 0.24) * (cp / 5)) * totalAP)
            local ticks = 3 + cp
            result.comboPoints[cp] = {
                cp = cp,
                perTick = totalBleed / ticks,
                totalBleed = totalBleed,
                dpe = (cost > 0) and (totalBleed / cost) or 0,
            }
        end

    elseif entry.type == "ranged_shot" then
        local rLow = stats.rangedLow or lowDmg
        local rHi = stats.rangedHi or hiDmg
        local flat = entry.flatBonus or 0
        local minDmg = rLow + flat
        local maxDmg = rHi + flat
        local avgHit = (minDmg + maxDmg) / 2
        local targets = entry.targets or 1

        result.targets = targets
        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.cleaveTotal = avgHit * targets
        result.minPostArmor = minDmg * armorMult
        result.maxPostArmor = maxDmg * armorMult
        result.avgPostArmor = avgHit * armorMult
        result.cleavePostArmor = result.avgPostArmor * targets
        result.efficiency = (cost > 0) and (avgHit / cost) or 0
        result.efficiencyPostArmor = (cost > 0) and (result.avgPostArmor / cost) or 0
        result.efficiencyCleave = (cost > 0) and (result.cleaveTotal / cost) or 0

    elseif entry.type == "ranged_arcane" then
        local rap = stats.rangedAP or totalAP
        local dmg = (entry.baseDmg or 0) + ((entry.rapRatio or 0.15) * rap)

        result.minDmg = dmg
        result.maxDmg = dmg
        result.avgDmg = dmg
        result.minPostArmor = dmg
        result.maxPostArmor = dmg
        result.avgPostArmor = dmg
        result.efficiency = (cost > 0) and (dmg / cost) or 0
        result.efficiencyPostArmor = result.efficiency

    elseif entry.type == "ranged_dot" then
        local rap = stats.rangedAP or totalAP
        local totalDot = (entry.baseTotal or 0) + ((entry.rapRatio or 0.10) * rap)
        local ticks = entry.ticks or 5

        result.totalDot = totalDot
        result.perTick = totalDot / ticks
        result.ticks = ticks
        result.duration = entry.duration or 15
        result.efficiency = (cost > 0) and (totalDot / cost) or 0
        result.efficiencyPostArmor = result.efficiency

    elseif entry.type == "spell_nuke" then
        local sp = (stats.spellPowerBySchool and stats.spellPowerBySchool[entry.school or 2]) or stats.maxSpellPower or 0
        local spBonus = (entry.spRatio or 0.43) * sp
        local minDmg = (entry.minBase or 0) + spBonus
        local maxDmg = (entry.maxBase or 0) + spBonus
        local avgHit = (minDmg + maxDmg) / 2
        local targets = entry.targets or 1
        local cleaveMult = entry.cleaveMult or targets

        result.targets = targets
        result.minDmg = minDmg
        result.maxDmg = maxDmg
        result.avgDmg = avgHit
        result.cleaveTotal = avgHit * cleaveMult
        result.dpm = (cost > 0) and (avgHit / cost) or 0
        result.dpmCleave = (cost > 0) and (result.cleaveTotal / cost) or 0

    elseif entry.type == "spell_dot" then
        local sp = (stats.spellPowerBySchool and stats.spellPowerBySchool[entry.school or 6]) or stats.maxSpellPower or 0
        local totalDot = (entry.baseTotal or 0) + ((entry.spRatio or 1.0) * sp)
        local ticks = entry.ticks or 6

        result.totalDot = totalDot
        result.perTick = totalDot / ticks
        result.ticks = ticks
        result.duration = entry.duration or 18
        result.dpm = (cost > 0) and (totalDot / cost) or 0

    elseif entry.type == "spell_hybrid" then
        local sp = (stats.spellPowerBySchool and stats.spellPowerBySchool[entry.school or 3]) or stats.maxSpellPower or 0
        local minDirect = (entry.minDirect or 0) + ((entry.directSP or 0.2) * sp)
        local maxDirect = (entry.maxDirect or 0) + ((entry.directSP or 0.2) * sp)
        local avgDirect = (minDirect + maxDirect) / 2
        local dotTotal = (entry.baseDot or 0) + ((entry.dotSP or 0.5) * sp)
        local ticks = entry.ticks or 4
        local totalDmg = avgDirect + dotTotal

        result.directHit = avgDirect
        result.dotTotal = dotTotal
        result.dotTick = dotTotal / ticks
        result.ticks = ticks
        result.duration = entry.duration or 12
        result.totalDmg = totalDmg
        result.dpm = (cost > 0) and (totalDmg / cost) or 0
    end

    return result
end

-- ============================================================================
-- DYNAMIC SKILL PRIORITY RANKING (DPR / DPE / DPM)
-- ============================================================================
function FeralCalc:GetSkillPriorityList(stats)
    stats = stats or self:GetMitigationStats()
    if not self.HighestKnownRankByName or not next(self.HighestKnownRankByName) then
        self:ScanSpellbook()
    end

    local known = self.HighestKnownRankByName or {}
    local hasAnyKnown = (next(known) ~= nil)
    local classFile = stats.classFile
    local formKey = stats.formKey

    local function GetKnownOrFallback(spellName)
        if known[spellName] then
            return known[spellName]
        end
        if not hasAnyKnown then
            return { name = spellName, rank = 1, spellID = nil, subText = "Rank 1" }
        end
        return nil
    end

    local list = {}
    local unitLabel = "DPR"
    local modeLabel = "Bear Form"

    if classFile == "DRUID" and formKey == "CAT" then
        unitLabel = "DPE"
        modeLabel = "Cat Form"
        local catOrder = { "Ravage", "Pounce", "Shred", "Rake", "Claw", "Rip", "Ferocious Bite" }
        for _, name in ipairs(catOrder) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    if calc.type == "cat_strike" or calc.type == "cat_shred" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = calc.avgDmg,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    elseif calc.type == "cat_rake" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = calc.totalDmg,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    elseif calc.type == "cat_pounce" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = calc.bleedTotal,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiency,
                        })
                    elseif calc.type == "cat_rip" and calc.comboPoints and calc.comboPoints[5] then
                        local cp5 = calc.comboPoints[5]
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Rip 5CP (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = cp5.totalBleed,
                            eff = cp5.dpe,
                            effPostArmor = cp5.dpe,
                        })
                    elseif calc.type == "cat_fb" and calc.comboPoints and calc.comboPoints[5] then
                        local cp5 = calc.comboPoints[5]
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Ferocious 5CP (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = cp5.avgBaseDmg,
                            eff = cp5.dpeBase,
                            effPostArmor = cp5.dpeBasePostArmor,
                        })
                    end
                end
            end
        end

    elseif classFile == "WARRIOR" then
        unitLabel = "DPR"
        modeLabel = "Warrior"
        local warOrder = { "Revenge", "Overpower", "Shield Slam", "Bloodthirst", "Mortal Strike", "Heroic Strike", "Cleave", "Whirlwind", "Thunder Clap" }
        for _, name in ipairs(warOrder) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    if calc.type == "war_revenge" or calc.type == "war_shield_slam" or calc.type == "war_strike"
                        or calc.type == "melee_strike" or calc.type == "ap_strike" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPR",
                            avgDmg = calc.avgDmg,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    elseif calc.type == "war_cleave" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Cleave 2T (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPR",
                            avgDmg = calc.cleaveTotal,
                            eff = calc.efficiencyCleave,
                            effPostArmor = (calc.cost > 0) and (calc.cleavePostArmor / calc.cost) or 0,
                        })
                    elseif calc.type == "bear_swipe" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s 4T (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPR",
                            avgDmg = calc.cleaveTotal,
                            eff = calc.efficiencyCleave,
                            effPostArmor = (calc.cost > 0) and (calc.cleavePostArmor / calc.cost) or 0,
                        })
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s 1T (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPR",
                            avgDmg = calc.singleHit,
                            eff = calc.efficiencySingle,
                            effPostArmor = (calc.cost > 0) and (calc.singlePostArmor / calc.cost) or 0,
                        })
                    end
                end
            end
        end

    elseif classFile == "PALADIN" then
        unitLabel = "DPM"
        modeLabel = "Paladin"
        local palOrder = { "Consecration", "Holy Shield", "Exorcism", "Holy Shock", "Hammer of Wrath" }
        for _, name in ipairs(palOrder) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    if calc.type == "pal_consecration" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Consecration 3T (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.cleave3,
                            eff = calc.dpm3,
                            effPostArmor = calc.dpm3,
                        })
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Consecration 1T (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.totalHoly,
                            eff = calc.dpm1,
                            effPostArmor = calc.dpm1,
                        })
                    elseif calc.type == "pal_holy_shield" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Holy Shield 4x (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.totalAllCharges,
                            eff = calc.dpm,
                            effPostArmor = calc.dpm,
                        })
                    elseif calc.type == "pal_holy_nuke" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.avgDmg,
                            eff = calc.dpm,
                            effPostArmor = calc.dpm,
                        })
                    end
                end
            end
        end

    elseif classFile == "HUNTER" then
        unitLabel = "DPM"
        modeLabel = "Hunter"
        local hunterOrder = { "Aimed Shot", "Multi-Shot", "Serpent Sting", "Arcane Shot", "Raptor Strike", "Mongoose Bite" }
        for _, name in ipairs(hunterOrder) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    if calc.type == "ranged_shot" then
                        if (calc.targets or 1) > 1 then
                            table.insert(list, {
                                name = calc.name,
                                displayName = string.format("%s %dT (R%d)", calc.name, calc.targets, calc.rank),
                                rank = calc.rank,
                                cost = calc.cost,
                                unit = "DPM",
                                avgDmg = calc.cleaveTotal,
                                eff = calc.efficiencyCleave,
                                effPostArmor = (calc.cost > 0) and (calc.cleavePostArmor / calc.cost) or 0,
                            })
                        end
                        table.insert(list, {
                            name = calc.name,
                            displayName = (calc.targets or 1) > 1 and string.format("%s 1T (R%d)", calc.name, calc.rank) or string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.avgDmg,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    elseif calc.type == "ranged_dot" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.totalDot,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    else
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.avgDmg,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    end
                end
            end
        end

    elseif classFile == "SHAMAN" or classFile == "WARLOCK" or classFile == "MAGE" or classFile == "PRIEST"
        or (classFile == "DRUID" and formKey ~= "BEAR" and formKey ~= "DIRE_BEAR" and formKey ~= "CAT") then
        unitLabel = "DPM"
        local pool = {}
        if classFile == "SHAMAN" then
            modeLabel = "Shaman"
            pool = { "Lightning Bolt", "Chain Lightning", "Flame Shock", "Earth Shock", "Frost Shock", "Stormstrike" }
        elseif classFile == "WARLOCK" then
            modeLabel = "Warlock"
            pool = { "Curse of Agony", "Corruption", "Siphon Life", "Immolate", "Shadow Bolt", "Soul Fire", "Searing Pain", "Shadowburn", "Drain Life" }
        elseif classFile == "MAGE" then
            modeLabel = "Mage"
            pool = { "Frostbolt", "Fireball", "Scorch", "Fire Blast", "Arcane Missiles" }
        elseif classFile == "PRIEST" then
            modeLabel = "Priest"
            pool = { "Shadow Word: Pain", "Mind Flay", "Holy Fire", "Smite", "Mind Blast" }
        else
            modeLabel = (formKey == "MOONKIN") and "Moonkin" or "Caster Druid"
            pool = { "Starfire", "Wrath", "Moonfire", "Insect Swarm" }
        end

        for _, name in ipairs(pool) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    if calc.type == "spell_nuke" then
                        if (calc.targets or 1) > 1 then
                            table.insert(list, {
                                name = calc.name,
                                displayName = string.format("%s %dT (R%d)", calc.name, calc.targets, calc.rank),
                                rank = calc.rank,
                                cost = calc.cost,
                                unit = "DPM",
                                avgDmg = calc.cleaveTotal,
                                eff = calc.dpmCleave,
                                effPostArmor = calc.dpmCleave,
                            })
                        end
                        table.insert(list, {
                            name = calc.name,
                            displayName = (calc.targets or 1) > 1 and string.format("%s 1T (R%d)", calc.name, calc.rank) or string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.avgDmg,
                            eff = calc.dpm,
                            effPostArmor = calc.dpm,
                        })
                    elseif calc.type == "spell_dot" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.totalDot,
                            eff = calc.dpm,
                            effPostArmor = calc.dpm,
                        })
                    elseif calc.type == "spell_hybrid" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.totalDmg,
                            eff = calc.dpm,
                            effPostArmor = calc.dpm,
                        })
                    elseif calc.type == "melee_strike" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPM",
                            avgDmg = calc.avgDmg,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    end
                end
            end
        end

    elseif classFile == "ROGUE" then
        unitLabel = "DPE"
        modeLabel = "Rogue"
        local rogueOrder = { "Ambush", "Backstab", "Riposte", "Rupture", "Garrote", "Eviscerate", "Sinister Strike", "Ghostly Strike", "Hemorrhage" }
        for _, name in ipairs(rogueOrder) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    if calc.type == "melee_strike" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = calc.avgDmg,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    elseif calc.type == "melee_bleed" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = calc.bleedTotal,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiency,
                        })
                    elseif calc.type == "rogue_rupture" and calc.comboPoints and calc.comboPoints[5] then
                        local cp5 = calc.comboPoints[5]
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Rupture 5CP (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = cp5.totalBleed,
                            eff = cp5.dpe,
                            effPostArmor = cp5.dpe,
                        })
                    elseif calc.type == "rogue_evis" and calc.comboPoints and calc.comboPoints[5] then
                        local cp5 = calc.comboPoints[5]
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Eviscerate 5CP (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPE",
                            avgDmg = cp5.avgBaseDmg,
                            eff = cp5.dpeBase,
                            effPostArmor = cp5.dpeBasePostArmor,
                        })
                    end
                end
            end
        end

    else
        -- Default / Druid Bear & Dire Bear Form
        unitLabel = "DPR"
        modeLabel = "Bear Form"
        local bearOrder = { "Primal Bite", "Maul", "Lacerate", "Swipe" }
        for _, name in ipairs(bearOrder) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    if calc.type == "bear_strike" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPR",
                            avgDmg = calc.avgDmg,
                            eff = calc.efficiency,
                            effPostArmor = calc.efficiencyPostArmor,
                        })
                    elseif calc.type == "bear_lacerate" and calc.stacks then
                        local s5 = calc.stacks[5]
                        if s5 then
                            table.insert(list, {
                                name = calc.name,
                                displayName = string.format("Lacerate 5x (R%d)", calc.rank),
                                rank = calc.rank,
                                cost = calc.cost,
                                unit = "DPR",
                                avgDmg = s5.totalBleed,
                                eff = s5.dpr,
                                effPostArmor = s5.dpr,
                            })
                        end
                    elseif calc.type == "bear_swipe" then
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Swipe 3T (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPR",
                            avgDmg = calc.cleaveTotal,
                            eff = calc.efficiencyCleave,
                            effPostArmor = (calc.cost > 0) and (calc.cleavePostArmor / calc.cost) or 0,
                        })
                        table.insert(list, {
                            name = calc.name,
                            displayName = string.format("Swipe 1T (R%d)", calc.rank),
                            rank = calc.rank,
                            cost = calc.cost,
                            unit = "DPR",
                            avgDmg = calc.singleHit,
                            eff = calc.efficiencySingle,
                            effPostArmor = (calc.cost > 0) and (calc.singlePostArmor / calc.cost) or 0,
                        })
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b)
        if math.abs((a.eff or 0) - (b.eff or 0)) > 0.001 then
            return (a.eff or 0) > (b.eff or 0)
        end
        return (a.avgDmg or 0) > (b.avgDmg or 0)
    end)

    return list, unitLabel, modeLabel
end

-- ============================================================================
-- DYNAMIC THREAT PRIORITY RANKING (TPR for Bear/Warrior, TPM for Paladin/Shaman)
-- ============================================================================
function FeralCalc:GetThreatPriorityList(stats)
    stats = stats or self:GetMitigationStats()
    if not self.HighestKnownRankByName or not next(self.HighestKnownRankByName) then
        self:ScanSpellbook()
    end

    local known = self.HighestKnownRankByName or {}
    local hasAnyKnown = (next(known) ~= nil)
    local classFile = stats.classFile
    local formKey = stats.formKey
    local talents = stats.talents or {}

    local function GetKnownOrFallback(spellName)
        if known[spellName] then
            return known[spellName]
        end
        if not hasAnyKnown then
            return { name = spellName, rank = 1, spellID = nil, subText = "Rank 1" }
        end
        return nil
    end

    local list = {}
    local unitLabel = "TPR"
    local modeLabel = "Bear Threat"

    if classFile == "WARRIOR" then
        unitLabel = "TPR"
        local isDefStance = (formKey == "DEFENSIVE_STANCE")
        local stanceMult = isDefStance and (1.30 * (1 + 0.03 * (talents.defiance or 0)))
            or ((formKey == "BERSERKER_STANCE" or formKey == "BATTLE_STANCE") and 0.80 or 1.00)
        modeLabel = isDefStance and "Warrior (Def)" or "Warrior"

        local revengeFlat = { [1]=155, [2]=195, [3]=235, [4]=275, [5]=315, [6]=355 }
        local slamFlat    = { [1]=175, [2]=200, [3]=225, [4]=250 }
        local hsFlat      = { [1]=20, [2]=32, [3]=45, [4]=60, [5]=78, [6]=98, [7]=118, [8]=145, [9]=175 }

        local warPool = { "Revenge", "Shield Slam", "Sunder Armor", "Heroic Strike", "Thunder Clap", "Cleave" }
        for _, name in ipairs(warPool) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    local cost = calc.cost or 0
                    if calc.type == "war_revenge" then
                        local threat = ((calc.avgDmg or 0) + (revengeFlat[calc.rank or 1] or 155)) * stanceMult
                        table.insert(list, {
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPR",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "war_shield_slam" then
                        local threat = ((calc.avgDmg or 0) + (slamFlat[calc.rank or 1] or 175)) * stanceMult
                        table.insert(list, {
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPR",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "war_sunder" then
                        local threat = (calc.entry.flatThreat or 260) * stanceMult
                        table.insert(list, {
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPR",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "war_strike" then
                        local threat = ((calc.avgDmg or 0) + (hsFlat[calc.rank or 1] or 20)) * stanceMult
                        table.insert(list, {
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPR",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "bear_swipe" then
                        local t4 = (calc.cleaveTotal or 0) * 1.75 * stanceMult
                        local t1 = (calc.singleHit or 0) * 1.75 * stanceMult
                        table.insert(list, {
                            displayName = string.format("Thunder Clap 4T (R%d)", calc.rank),
                            unit = "TPR",
                            threat = t4,
                            eff = (cost > 0) and (t4 / cost) or 0,
                        })
                        table.insert(list, {
                            displayName = string.format("Thunder Clap 1T (R%d)", calc.rank),
                            unit = "TPR",
                            threat = t1,
                            eff = (cost > 0) and (t1 / cost) or 0,
                        })
                    elseif calc.type == "war_cleave" then
                        local threat = ((calc.cleaveTotal or 0) + 100) * stanceMult
                        table.insert(list, {
                            displayName = string.format("Cleave 2T (R%d)", calc.rank),
                            unit = "TPR",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    end
                end
            end
        end

    elseif classFile == "PALADIN" then
        unitLabel = "TPM"
        local hasRF = (formKey == "PALADIN_RF")
        local rfMult = hasRF and (1.60 * (1 + 0.1667 * (talents.impRighteousFury or 0))) or 1.00
        modeLabel = hasRF and "Paladin [RF]" or "Paladin"

        local palPool = { "Holy Shield", "Consecration", "Exorcism", "Holy Shock", "Hammer of Wrath" }
        for _, name in ipairs(palPool) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    local cost = calc.cost or 0
                    if calc.type == "pal_holy_shield" then
                        local threat = (calc.totalAllCharges or 0) * 1.20 * rfMult
                        table.insert(list, {
                            displayName = string.format("Holy Shield 4x (R%d)", calc.rank),
                            unit = "TPM",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "pal_consecration" then
                        local t3 = (calc.cleave3 or 0) * rfMult
                        local t1 = (calc.totalHoly or 0) * rfMult
                        table.insert(list, {
                            displayName = string.format("Consecration 3T (R%d)", calc.rank),
                            unit = "TPM",
                            threat = t3,
                            eff = (cost > 0) and (t3 / cost) or 0,
                        })
                        table.insert(list, {
                            displayName = string.format("Consecration 1T (R%d)", calc.rank),
                            unit = "TPM",
                            threat = t1,
                            eff = (cost > 0) and (t1 / cost) or 0,
                        })
                    elseif calc.type == "pal_holy_nuke" then
                        local threat = (calc.avgDmg or 0) * rfMult
                        table.insert(list, {
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPM",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    end
                end
            end
        end

    elseif classFile == "SHAMAN" then
        unitLabel = "TPM"
        modeLabel = "Shaman Threat"
        local shamPool = { "Earth Shock", "Lightning Bolt", "Chain Lightning", "Flame Shock", "Frost Shock", "Stormstrike" }
        for _, name in ipairs(shamPool) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    local cost = calc.cost or 0
                    if calc.name == "Earth Shock" then
                        local threat = (calc.avgDmg or 0) * 2.0 -- Earth Shock causes 2x high threat
                        table.insert(list, {
                            displayName = string.format("Earth Shock 2x (R%d)", calc.rank),
                            unit = "TPM",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "spell_nuke" then
                        if (calc.targets or 1) > 1 then
                            local tc = (calc.cleaveTotal or 0)
                            table.insert(list, {
                                displayName = string.format("%s %dT (R%d)", calc.name, calc.targets, calc.rank),
                                unit = "TPM",
                                threat = tc,
                                eff = (cost > 0) and (tc / cost) or 0,
                            })
                        end
                        local t1 = (calc.avgDmg or 0)
                        table.insert(list, {
                            displayName = (calc.targets or 1) > 1 and string.format("%s 1T (R%d)", calc.name, calc.rank) or string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPM",
                            threat = t1,
                            eff = (cost > 0) and (t1 / cost) or 0,
                        })
                    elseif calc.type == "spell_hybrid" then
                        local threat = (calc.totalDmg or 0)
                        table.insert(list, {
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPM",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "melee_strike" then
                        local threat = (calc.avgDmg or 0)
                        table.insert(list, {
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPM",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    end
                end
            end
        end

    else
        -- Druid Bear / Dire Bear Form (and fallback)
        unitLabel = "TPR"
        modeLabel = "Bear Threat"
        local bearThreatMult = 1.30 * (1 + 0.03 * (talents.feralInstinct or 0))
        local lacerateFlat = { [1]=180, [2]=230, [3]=285 }
        local bearPool = { "Maul", "Primal Bite", "Lacerate", "Swipe" }

        for _, name in ipairs(bearPool) do
            local sp = GetKnownOrFallback(name)
            if sp then
                local calc = self:GetAbilityDamage(sp.spellID, sp.name, sp.subText)
                if calc then
                    local cost = calc.cost or 0
                    if calc.type == "bear_strike" then
                        local mult = (calc.name == "Maul") and 1.75 or 1.30
                        local threat = (calc.avgDmg or 0) * mult * bearThreatMult
                        table.insert(list, {
                            displayName = string.format("%s (R%d)", calc.name, calc.rank),
                            unit = "TPR",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "bear_lacerate" and calc.stacks and calc.stacks[5] then
                        local flat = lacerateFlat[calc.rank or 1] or 285
                        local bleedThreat = (calc.stacks[5].totalBleed or 0) * 0.5
                        local threat = (flat + bleedThreat) * bearThreatMult
                        table.insert(list, {
                            displayName = string.format("Lacerate 5x (R%d)", calc.rank),
                            unit = "TPR",
                            threat = threat,
                            eff = (cost > 0) and (threat / cost) or 0,
                        })
                    elseif calc.type == "bear_swipe" then
                        local t3 = (calc.cleaveTotal or 0) * bearThreatMult
                        local t1 = (calc.singleHit or 0) * bearThreatMult
                        table.insert(list, {
                            displayName = string.format("Swipe 3T (R%d)", calc.rank),
                            unit = "TPR",
                            threat = t3,
                            eff = (cost > 0) and (t3 / cost) or 0,
                        })
                        table.insert(list, {
                            displayName = string.format("Swipe 1T (R%d)", calc.rank),
                            unit = "TPR",
                            threat = t1,
                            eff = (cost > 0) and (t1 / cost) or 0,
                        })
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b)
        if math.abs((a.eff or 0) - (b.eff or 0)) > 0.001 then
            return (a.eff or 0) > (b.eff or 0)
        end
        return (a.threat or 0) > (b.threat or 0)
    end)

    return list, unitLabel, modeLabel
end

-- ============================================================================
-- DEBUG / DIAGNOSTIC DUMP (/ft debug and /fc debug)
-- ============================================================================
function FeralCalc:DumpDebugInfo()
    self:Print("=== WoW: Forever Live Tank Diagnostic Dump ===")
    local stats = self:GetMitigationStats()
    self:Print(string.format(
        "Class: %s | Form/Stance: %s (Index=%d)",
        stats.className, stats.formName, stats.formIndex or 0
    ))
    self:Print(string.format(
        "UnitDamage: %.1f - %.1f (Avg=%.1f, Speed=%.2fs, PercentMod=%.2f)",
        stats.lowDmg, stats.hiDmg, stats.avgDmg, stats.mainSpeed, stats.percentMod
    ))
    self:Print(string.format(
        "AttackPower: %d | Crit: %.2f%% | Bonus Hit: +%.1f%%",
        stats.totalAP, stats.meleeCritPct, stats.meleeHitPct
    ))
    self:Print(string.format(
        "UnitArmor: Effective=%d (Base=%d) -> DR60=%.2f%%, DR63=%.2f%%",
        stats.effectiveArmor, stats.baseArmor, stats.dr60Pct, stats.dr63Pct
    ))
    self:Print(string.format(
        "Defense: %d (%d+%.1f) | Dodge=%.2f%% | Parry=%.2f%% | Block=%.2f%% | Miss=%.2f%% | Table=%.2f%%",
        stats.totalDefense, stats.baseDefense, stats.armorDefense, stats.dodgePct, stats.parryPct, stats.blockPct, stats.bossMissPct, stats.combatTablePct
    ))

    self:Print("--- Discovered Talents ---")
    local tabSummary = {}
    for k, pts in pairs(stats.talents.tabPoints or {}) do
        local tName = (stats.talents.tabNames and stats.talents.tabNames[k]) or ("Tab " .. tostring(k))
        table.insert(tabSummary, string.format("%s=%d", tName, pts))
    end
    self:Print(string.format("  Trees: %s | IsTankSpec=%s", (#tabSummary > 0 and table.concat(tabSummary, ", ") or "none"), tostring(self:IsTankSpecByTalents(stats.classFile, stats.talents))))
    if #stats.talents.discovered == 0 then
        self:Print("  (No active or tracked talents found)")
    else
        for _, t in ipairs(stats.talents.discovered) do
            self:Print(string.format(
                "  [Tree/Tab %s, Node/Idx %s] %s: %d/%d",
                tostring(t.tab), tostring(t.index), t.name, t.rank, t.maxRank
            ))
        end
    end

    self:Print("--- Spellbook Tank/Feral Spell IDs ---")
    local allSpells = self:ScanSpellbook()
    local foundSpells = 0
    for _, sp in ipairs(allSpells) do
        if self:GetSpellEntry(sp.spellID, sp.name, sp.subText) then
            foundSpells = foundSpells + 1
            self:Print(string.format(
                "  %s (%s) -> SpellID = %s",
                sp.name, sp.subText ~= "" and sp.subText or "No Rank", tostring(sp.spellID)
            ))
        end
    end
    if foundSpells == 0 then
        self:Print("  (No tracked Tank/Feral spells found in current spellbook)")
    end
end
