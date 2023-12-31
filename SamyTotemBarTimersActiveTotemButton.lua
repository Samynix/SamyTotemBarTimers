SamyTotemBarTimersActiveTotemButton = {}

local function CreateMissingBuffOverlay(parentFrame)
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetWidth(parentFrame:GetWidth())
    frame:SetHeight(parentFrame:GetHeight())

    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetColorTexture(1, 0, 0, 0.4)
    texture:SetAllPoints(frame)
    frame.texture = texture

    frame:SetPoint("CENTER", 0, 0)
    return frame
end

local function CreatePulseStatusBar(parentFrame)
    local statusbar = CreateFrame("StatusBar", nil, parentFrame)
    statusbar:SetPoint("BOTTOM", parentFrame, "TOP", 0, 0)
    statusbar:SetWidth(parentFrame:GetWidth())
    statusbar:SetHeight(SamyTotemBarTimersConfig.PULSESTATUSBARHEIGHT)
    statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar:GetStatusBarTexture():SetHorizTile(false)
    statusbar:GetStatusBarTexture():SetVertTile(false)
    statusbar:SetStatusBarColor(0, 0.65, 0)

    statusbar.value = statusbar:CreateFontString(nil, "OVERLAY")
    statusbar.value:SetPoint("LEFT", statusbar, "LEFT", 4, 0)
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    statusbar.value:SetJustifyH("LEFT")
    statusbar.value:SetShadowOffset(1, -1)
    statusbar.value:SetTextColor(0, 1, 0)

    statusbar:Hide()
    return statusbar
end

function SamyTotemBarTimersActiveTotemButton:Create(parentFrame, availableTotems, totemListId)
    local templates = "ActionButtonTemplate"
    local instance = SamyTotemBarTimersButtonBase:Create(parentFrame,
        "SamyTotemBarTimers" .. totemListId .. "ActiveTotemButton", templates)
    instance.pulseStatusBar = CreatePulseStatusBar(instance.frame)
    instance.frame:SetEnabled(false)
    instance.frame.NormalTexture:Hide()
    instance.frame.Border:Hide()
    instance.frame:SetScript("OnShow", function(self)
        self.NormalTexture:Hide()
        self.Border:Hide()
    end)
    instance.frame:Show()

    instance.affectedFontString = instance.frame:CreateFontString(instance.frame:GetName() .. "AffectedText", "OVERLAY",
        "NumberFontNormal")
    instance.affectedFontString:SetPoint("TOP", instance.frame, "TOP", 0, -2)
    instance.affectedFontString:Hide()

    instance.missingBuffOverlay = CreateMissingBuffOverlay(instance.frame)
    instance.missingBuffOverlay:Hide()

    function instance:SetVisibility(isVisible) end --override

    function instance:SetIsShowPulse(isShowPulse)
        instance.isShowPulse = isShowPulse
    end

    local elementTotemDictionary = {}
    for k, v in pairs(availableTotems) do
        if (not elementTotemDictionary[v["ElementID"]]) then
            elementTotemDictionary[v["ElementID"]] = {}
        end

        local spellName = GetSpellInfo(v["RankOneSpellID"])
        table.insert(elementTotemDictionary[v["ElementID"]], {
            ["spellName"] = spellName,
            ["pulseTime"] = v["PulseTime"],
            ["buffDuration"] = v["BuffDuration"],
            ["elementId"] = v["ElementID"],
            ["hasBuff"] = v["hasBuff"],
        })
    end

    local function DoWork()
        local duration = instance.duration and instance.duration or 0
        local startTime = instance.startTime and instance.startTime or 0
        local timeLeft = duration + startTime - GetTime()
        if (not instance.hasTotem or timeLeft <= 0) then
            instance:ResetAndHide()
            C_Timer.NewTimer(0.1, function() DoWork() end)
            return
        end



        instance:SetTexture(instance.activeTotem.spellName)
        instance:SetSpell(instance.activeTotem.spellName, instance.activeTotem.elementId, true)
        instance:SetHasBuff(instance.activeTotem.hasBuff)
        if (instance.activeTotem.pulseTime and instance.isShowPulse) then
            local pulseTime = instance.activeTotem.pulseTime - timeLeft % instance.activeTotem.pulseTime
            instance.pulseStatusBar:SetMinMaxValues(0, instance.activeTotem.pulseTime)
            instance.pulseStatusBar:SetValue(pulseTime)
            instance.pulseStatusBar.value:SetText(SamyTotemBarTimersUtils:Round(pulseTime, 1))
            instance.pulseStatusBar:Show()
        else
            instance.pulseStatusBar:Hide()
        end

        local d, h, m, s = ChatFrame_TimeBreakDown(timeLeft)
        instance.frame.Count:SetFormattedText("%01d:%02d", m, s)

        if (not instance.frame:IsVisible()) then
            instance.frame:Show()
        end

        C_Timer.NewTimer(0.1, function() DoWork() end)
    end

    function instance:UpdateActiveTotemInfo(totemIndexChanged, latency)
        if (not elementTotemDictionary[totemIndexChanged]) then
            return
        end

        for k, v in pairs(elementTotemDictionary[totemIndexChanged]) do
            local haveTotem, totemName, startTime, duration, icon = GetTotemInfo(totemIndexChanged)
            if (v.spellName and haveTotem and string.match(totemName, v.spellName)) then
                instance.activeTotem = v
                instance.hasTotem = true
                instance.startTime = startTime + latency
                instance.duration = duration
                instance.frame:Show();
                return
            end
        end

        instance:ResetAndHide()
    end

    function instance:ResetAndHide()
        instance:SetSpell(nil, nil)
        instance.activeTotem = nil
        instance.hasTotem = false
        instance.frame:Hide()
    end

    function instance:UpdateActiveTotemAffectedCount()
        if (instance.spellName) then
            local affected = 0
            local totalPossible = nil
            local units = {}
            local myName = UnitName('player');
            if (UnitInRaid('player')) then
                for i = 1, MAX_RAID_MEMBERS do
                    local unitId = 'raid' .. i;
                    local unitName = UnitName(unitId);
                    if (unitName and unitName ~= myName) then
                        table.insert(units, unitId);
                    end
                end

                table.insert(units, 'player');
            else
                units = { "player", "party1", "party2", "party3", "party4" }
            end

            for k, v in pairs(units) do
                local buffs = SamyTotemBarTimersUtils:GetUnitBuffs(v, nil)
                local foundBuff = false
                for k2, v2 in pairs(buffs) do
                    if (v2.isRelevant and string.match(instance.spellName, v2.name) and v2.expirationTime > GetTime()) then
                        affected = affected + 1
                        foundBuff = true
                    end
                end

                if v == "player" then
                    if SamyTotemBarTimersDB.isWarnIfMissingBuff and instance.hasBuff and not foundBuff then
                        instance.missingBuffOverlay:Show()
                    else
                        instance.missingBuffOverlay:Hide()
                    end
                end
            end

            if (affected > 0 or (totalPossible and totalPossible > 0)) then
                local affectedString = tostring(affected)
                if (totalPossible) then
                    affectedString = affectedString .. '/' .. tostring(totalPossible)
                end

                instance.affectedFontString:Show()
                instance.affectedFontString:SetText(tostring(affectedString))
            else
                instance.affectedFontString:Hide()
            end
        end
    end

    DoWork()
    return instance
end
