local _samyTotemBarTimers = LibStub("AceAddon-3.0"):NewAddon("SamyTotemBarTimers", "AceEvent-3.0")

local _activeTotemList = {}
local _timeSinceLastUpdate = 0
local _castChangedTime = nil
local _currentZone = nil

local function IsPlayerShaman()
    local localizedClass, englishClass, classIndex = UnitClass("player");
    return englishClass == "SHAMAN"
end

local function CreateActiveTotemButton(parentFrame, totemInfoList, totemListId)
    local activeTotemButton = SamyTotemBarTimersActiveTotemButton:Create(parentFrame, totemInfoList, totemListId)
    return activeTotemButton
end

local function CreateActiveTotemButtons()
    local activeTotemList = {}

    for k, v in pairs(SamyTotemBarTimersDatabase:GetTotemLists()) do
        local parent = nil;
        local activeTotemButton = nil;
        if (k == 1) then
            parent = MultiCastActionButton1;
        elseif k == 2 then
            parent = MultiCastActionButton2;
        elseif k == 3 then
            parent = MultiCastActionButton3;
        elseif k == 4 then
            parent = MultiCastActionButton4;
        end

        local isShowBuffDuration = false;
        if (isShowBuffDuration) then --Functionalty not done
            activeTotemButton = SamyTotemBarTimersBuffTotemButton:Create(parent,
                SamyTotemBarTimersUtils:FirstOrDefault(v["totems"]), k)
        else
            activeTotemButton = CreateActiveTotemButton(parent, v["totems"], k)
        end


        activeTotemButton:SetEnabled(v["isEnabled"]);
        activeTotemButton:SetPosition(0, SamyTotemBarTimersConfig.BUTTON_SIZE + SamyTotemBarTimersConfig
            .VERTICAL_SPACING);
        activeTotemButton:SetIsShowPulse(v.isShowPulseTimers)
        activeTotemList[k] = activeTotemButton
    end

    return activeTotemList
end

function _samyTotemBarTimers:OnInitialize()
    if (not IsPlayerShaman()) then
        SamyTotemBarTimersUtils:Print("Not loaded. Only works for shamans")
        return
    end

    SamyTotemBarTimersDatabase:OnInitialize(self)

    self.frame = CreateFrame("Frame", "SamyTotemBarTimersFrame", UIParent)
    self.frame:SetScript("OnUpdate", self.OnUpdate)

    local totemLists = CreateActiveTotemButtons()
    _activeTotemList = totemLists

    _currentZone = GetZoneText()
    SamyTotemBarTimersUtils:Print("Loaded")
end

function _samyTotemBarTimers:SetActiveTotemEnabled(listId, isEnabled)
    _activeTotemList[listId]:SetEnabled(isEnabled)
end

function _samyTotemBarTimers:SetIsShowPulse(listId, isShowPulse)
    _activeTotemList[listId]:SetIsShowPulse(isShowPulse)
end

function _samyTotemBarTimers:OnUpdate(elapsed)
    _timeSinceLastUpdate = _timeSinceLastUpdate + elapsed
    if (_timeSinceLastUpdate < SamyTotemBarTimersConfig.ONUPDATEDELAY) then
        return
    end

    _timeSinceLastUpdate = 0
    for k, v in pairs(_activeTotemList) do
        if (v.isEnabled) then
            v:UpdateActiveTotemAffectedCount()
        end
    end
end

local function MeasureLatency()
    local delay = 0
    if (_castChangedTime) then
        delay = GetTime() - _castChangedTime
        _castChangedTime = nil
    end

    return delay
end

_samyTotemBarTimers:RegisterEvent("PLAYER_TOTEM_UPDATE", function(self, totemIndex)
    local latency = MeasureLatency()
    for k, v in pairs(_activeTotemList) do
        if (v.isEnabled) then
            v:UpdateActiveTotemInfo(totemIndex, latency)
        end
    end
end)

_samyTotemBarTimers:RegisterEvent("SPELLS_CHANGED", function()

end)

_samyTotemBarTimers:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", function(event)
    _castChangedTime = GetTime()
end)

local function ResetAllActive()
    for k, v in pairs(_activeTotemList) do
        if (v.isEnabled) then
            v:ResetAndHide()
        end
    end
end

local function HasChangedZone()
    local currentZone = GetZoneText()
    if (_currentZone ~= currentZone) then
        _currentZone = currentZone
        return true
    end

    return false
end

_samyTotemBarTimers:RegisterEvent("ZONE_CHANGED", function(event)
    if (not HasChangedZone()) then
        return
    end

    ResetAllActive()
end)

_samyTotemBarTimers:RegisterEvent("ZONE_CHANGED_INDOORS", function(event)
    if (not HasChangedZone()) then
        return
    end

    ResetAllActive()
end)

_samyTotemBarTimers:RegisterEvent("ZONE_CHANGED_NEW_AREA", function(event)
    if (not HasChangedZone()) then
        return
    end

    ResetAllActive()
end)

_samyTotemBarTimers:RegisterEvent("PLAYER_DEAD", function(event)
    ResetAllActive()
end)
