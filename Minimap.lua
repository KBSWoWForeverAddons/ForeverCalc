local addonName, FeralCalc = ...

-- ============================================================================
-- MINIMAP BUTTON POSITIONING HELPER
-- ============================================================================
local function UpdateMinimapButtonPosition(btn, angleDeg)
    if not btn or not Minimap then return end
    local rad = math.rad(angleDeg or 225)
    local radius = 80
    if Minimap.GetWidth then
        local w = Minimap:GetWidth()
        if type(w) == "number" and w > 40 then
            radius = (w / 2) + 8
        end
    end
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- ============================================================================
-- OPTIONS INTERFACE (Select / Deselect Pane & Priority Options)
-- ============================================================================
function FeralCalc:CreateOptionsFrame()
    if self.optionsFrame then
        return self.optionsFrame
    end
    self:InitDB()

    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    local frame = CreateFrame("Frame", "ForeverTankOptionsFrame", UIParent, backdropTemplate)
    frame:SetSize(390, 322)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
    end)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        })
        frame:SetBackdropColor(0.06, 0.06, 0.09, 0.96)
        frame:SetBackdropBorderColor(0.85, 0.75, 0.55, 1.0)
    end

    -- Allow ESC to close the options window
    if type(UISpecialFrames) == "table" then
        local alreadyRegistered = false
        for _, name in ipairs(UISpecialFrames) do
            if name == "ForeverTankOptionsFrame" then
                alreadyRegistered = true
                break
            end
        end
        if not alreadyRegistered then
            table.insert(UISpecialFrames, "ForeverTankOptionsFrame")
        end
    end

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Custom Dwarven King's Crown Logo in Header
    local logo = frame:CreateTexture(nil, "ARTWORK")
    logo:SetSize(26, 26)
    logo:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -13)
    logo:SetTexture("Interface\\AddOns\\ForeverStats\\DwarfCrown.tga")
    logo:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    title:SetText("|cFFFF7D0AForeverStats Options|r")

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -44)
    subtitle:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("|cFFAAAAAASelect which panes, tooltips, and priority windows to show:|r")

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -60)
    divider:SetColorTexture(0.6, 0.5, 0.25, 0.6)

    frame.checks = {}

    local function AddCheckbox(key, labelText, descText, yPos, onClick)
        local cb = CreateFrame("CheckButton", "ForeverTankCheck_" .. key, frame, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, yPos)
        cb:SetSize(26, 26)

        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", cb, "RIGHT", 6, 1)
        label:SetText(labelText)

        local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
        desc:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
        desc:SetJustifyH("LEFT")
        desc:SetWordWrap(true)
        desc:SetText("|cFF999999" .. descText .. "|r")

        cb:SetScript("OnClick", function(selfBtn)
            local checked = selfBtn:GetChecked() and true or false
            onClick(checked)
        end)

        frame.checks[key] = cb
        return cb
    end

    AddCheckbox(
        "charPane",
        "Character Sheet Stats Pane",
        "Show the side stats panel when viewing your Character Sheet.",
        -70,
        function(checked)
            FeralCalc:InitDB()
            FeralCalc.db.showCharacterPane = checked
            if FeralCalc.UpdateCharacterPaneVisibility then
                FeralCalc:UpdateCharacterPaneVisibility()
            end
            if checked and FeralCalc.UpdateCharacterPane then
                FeralCalc:UpdateCharacterPane()
            end
        end
    )

    AddCheckbox(
        "prioPane",
        "Top 5 Damage Priority Window",
        "Show the movable Top 5 DPR/DPE/DPM window (/ft prio).",
        -112,
        function(checked)
            if FeralCalc.SetPriorityPaneVisible then
                FeralCalc:SetPriorityPaneVisible(checked, true)
            else
                FeralCalc:InitDB()
                FeralCalc.db.showPriorityPane = checked
            end
        end
    )

    AddCheckbox(
        "threatPane",
        "Top 5 Threat Priority Window",
        "Show Threat/Rage (Bear/War) or Threat/Mana (Pal/Sham) (/ft threat).",
        -154,
        function(checked)
            if FeralCalc.SetThreatPaneVisible then
                FeralCalc:SetThreatPaneVisible(checked, true)
            else
                FeralCalc:InitDB()
                FeralCalc.db.showThreatPane = checked
            end
        end
    )

    AddCheckbox(
        "postArmor",
        "Post-Armor Boss Tooltip Estimates",
        "Include Lvl 63 Raid Boss armor reduction in spell tooltips.",
        -196,
        function(checked)
            FeralCalc:InitDB()
            FeralCalc.db.showPostArmor = checked
        end
    )

    AddCheckbox(
        "minimapBtn",
        "Show Minimap Button",
        "Toggle this minimap shield button (restore with /ft minimap).",
        -238,
        function(checked)
            FeralCalc:InitDB()
            FeralCalc.db.showMinimapButton = checked
            if FeralCalc.UpdateMinimapButtonVisibility then
                FeralCalc:UpdateMinimapButtonVisibility()
            end
        end
    )

    -- Bottom Action Buttons
    local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(145, 24)
    resetBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 14)
    resetBtn:SetText("Reset Window Pos")
    resetBtn:SetScript("OnClick", function()
        FeralCalc:InitDB()
        FeralCalc.db.prioPoint = nil
        FeralCalc.db.threatPoint = nil
        if FeralCalc.priorityPane then
            FeralCalc.priorityPane:ClearAllPoints()
            FeralCalc.priorityPane:SetPoint("CENTER", UIParent, "CENTER", 320, 80)
        end
        if FeralCalc.threatPane then
            FeralCalc.threatPane:ClearAllPoints()
            FeralCalc.threatPane:SetPoint("CENTER", UIParent, "CENTER", 320, -90)
        end
        FeralCalc:Print("Damage & Threat Priority window positions reset.")
    end)

    local doneBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    doneBtn:SetSize(96, 24)
    doneBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 14)
    doneBtn:SetText("Close")
    doneBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:SetScript("OnShow", function()
        FeralCalc:RefreshOptionsFrame()
    end)

    frame:Hide()
    self.optionsFrame = frame
    return frame
end

function FeralCalc:RefreshOptionsFrame()
    if not self.optionsFrame or not self.optionsFrame.checks then
        return
    end
    self:InitDB()
    local checks = self.optionsFrame.checks
    if checks.charPane then
        checks.charPane:SetChecked(self.db.showCharacterPane and true or false)
    end
    if checks.prioPane then
        local isPrioShown = self.priorityPane and self.priorityPane:IsShown()
        if isPrioShown ~= nil then
            checks.prioPane:SetChecked(isPrioShown and true or false)
        else
            checks.prioPane:SetChecked(self.db.showPriorityPane and true or false)
        end
    end
    if checks.threatPane then
        local isThreatShown = self.threatPane and self.threatPane:IsShown()
        if isThreatShown ~= nil then
            checks.threatPane:SetChecked(isThreatShown and true or false)
        else
            checks.threatPane:SetChecked(self.db.showThreatPane and true or false)
        end
    end
    if checks.postArmor then
        checks.postArmor:SetChecked(self.db.showPostArmor and true or false)
    end
    if checks.minimapBtn then
        checks.minimapBtn:SetChecked(self.db.showMinimapButton and true or false)
    end
end

function FeralCalc:ToggleOptionsFrame()
    self:InitDB()
    if not self.optionsFrame then
        self:CreateOptionsFrame()
    end
    if self.optionsFrame:IsShown() then
        self.optionsFrame:Hide()
    else
        self:RefreshOptionsFrame()
        self.optionsFrame:Show()
    end
end

-- ============================================================================
-- MINIMAP BUTTON WITH TANK SHIELD LOGO
-- ============================================================================
function FeralCalc:CreateMinimapButton()
    if self.minimapButton or not Minimap then
        return
    end
    self:InitDB()

    local btn = CreateFrame("Button", "ForeverTankMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Circular background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(24, 24)
    bg:SetPoint("CENTER", btn, "CENTER", 0, 0)
    bg:SetColorTexture(0.08, 0.08, 0.1, 0.9)

    -- Custom Dwarven King's Crown Logo
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\ForeverStats\\DwarfCrown.tga")
    icon:SetTexCoord(0.10, 0.90, 0.10, 0.90)
    btn.icon = icon

    -- Standard circular Minimap ring border
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Hover highlight
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    UpdateMinimapButtonPosition(btn, self.db.minimapAngle or 225)

    -- Dragging around the Minimap rim
    local isDragging = false
    btn:SetScript("OnDragStart", function(selfBtn)
        isDragging = true
        selfBtn:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale() or 1
            if mx and my and cx and cy then
                cx, cy = cx / scale, cy / scale
                local angle = math.deg(math.atan2(cy - my, cx - mx))
                FeralCalc.db.minimapAngle = angle
                UpdateMinimapButtonPosition(selfBtn, angle)
            end
        end)
    end)

    btn:SetScript("OnDragStop", function(selfBtn)
        isDragging = false
        selfBtn:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(_, button)
        if isDragging then return end
        if button == "RightButton" then
            if FeralCalc.TogglePriorityPane then
                FeralCalc:TogglePriorityPane()
            end
        else
            FeralCalc:ToggleOptionsFrame()
        end
    end)

    btn:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFFFF7D0AForeverStats|r")
        GameTooltip:AddLine("Tank · DPS · Caster Stats & Priorities", 0.9, 0.9, 0.9)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Left-Click:", "Open Options Menu", 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine("Right-Click:", "Toggle Top 5 Skill Priority", 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine("Drag:", "Move Minimap Button", 1, 0.82, 0, 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.minimapButton = btn
    self:UpdateMinimapButtonVisibility()
end

function FeralCalc:UpdateMinimapButtonVisibility()
    if not self.minimapButton then return end
    self:InitDB()
    if self.db.showMinimapButton then
        self.minimapButton:Show()
    else
        self.minimapButton:Hide()
    end
end
