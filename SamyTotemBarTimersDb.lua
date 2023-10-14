SamyTotemBarTimersDatabase = {}

local _db = nil
local _SamyTotemBarTimers = nil

local function EnsureSavedVariablesExists(isReset)
    local function SetDefault(ref, default, isOverride)
        if (ref == nil or isOverride) then
            return default
        end

        return ref
    end

    SamyTotemBarTimersDB = SetDefault(SamyTotemBarTimersDB, {}, isReset);
    SamyTotemBarTimersDB.isWarnIfMissingBuff = SetDefault(SamyTotemBarTimersDB.isWarnIfMissingBuff,
        SamyTotemBarTimersConfig.defaultGeneralSettings.isWarnIfMissingBuff, isReset);
    SamyTotemBarTimersDB.totemLists = SetDefault(SamyTotemBarTimersDB.totemLists, SamyTotemBarTimersConfig
        .defaultTotemLists,
        isReset);

    SamyTotemBarTimersDBVersion:UpdateDatabase(SamyTotemBarTimersDB, isReset, SetDefault)

    --Ensure all totems are in config
    for k, element in pairs(SamyTotemBarTimersConfig.defaultTotemLists) do
        if not SamyTotemBarTimersDB.totemLists[k] then
            SamyTotemBarTimersDB.totemLists[k] = element
            SamyTotemBarTimersUtils:Print("Added missing totemlist " .. k)
        else
            for k2, totem in pairs(element["totems"]) do
                if not SamyTotemBarTimersDB.totemLists[k]["totems"][k2] then
                    SamyTotemBarTimersDB.totemLists[k]["totems"][k2] = totem
                    SamyTotemBarTimersUtils:Print("Added missing totem " .. k2 .. " to totem list " .. k)
                end
            end
        end
    end

    for k, v in pairs(SamyTotemBarTimersDB.totemLists) do
        if (v.isShowPulseTimers == nil) then
            v.isShowPulseTimers = true
        end

        for k2, v2 in pairs(v.totems) do
            if (v2.isEnabled == nil) then
                v2.isEnabled = true
            end

            local defaultHasBuff = SamyTotemBarTimersConfig.defaultTotemLists[k]["totems"][k2]["hasBuff"]
            if (v2.hasBuff == nil and defaultHasBuff ~= nil) then
                v2.hasBuff = defaultHasBuff
            end
        end
    end

    return SamyTotemBarTimersDB
end

function SamyTotemBarTimersDatabase:OnInitialize(SamyTotemBarTimers)
    _SamyTotemBarTimers = SamyTotemBarTimers
    _db = EnsureSavedVariablesExists(false)

    local options = {
        name = 'SamyTotemBarTimers ' .. SamyTotemBarTimersConfig.Version,
        type = "group",
        handler = self,
        args = {
            reset = {
                order = 10,
                type = 'execute',
                name = "Reset",
                func = 'ResetConfig'
            },

            general = {
                order = 3,
                type = 'group',
                name = 'General',
                args = {
                    isWarnIfMissingBuff = {
                        order = 1,
                        name = "Show red overlay if you are missing totem buff",
                        desc = "Show warning overlay if you are missing buff from active totem",
                        type = "toggle",
                        set = function(info, newValue) SamyTotemBarTimersDatabase:SetWarnIfMissingBuffEnabled(newValue) end,
                        get = function() return SamyTotemBarTimersDatabase:GetWarnIfMissingBuffEnabled() end,
                    },
                }
            },

            totems = {
                order = 3,
                type = 'group',
                name = 'Totems',
                args = {}
            },
        },
    }

    for k, v in pairs(_db.totemLists) do
        local key = tostring(k)
        options.args.totems.args[key] = {
            order = k,
            type = "group",
            name = v.name,
            args = {
                isEnabled = {
                    order = 1,
                    name = "Enabled",
                    desc = "Enable/Disable totem list",
                    type = "toggle",
                    set = function(info, newValue) SamyTotemBarTimersDatabase:SetTotemListEnabled(k, newValue) end,
                    get = function() return SamyTotemBarTimersDatabase:GetTotemListEnabled(k) end,
                },
                isShowPulseTimers = {
                    order = 2,
                    name = "Show pulse",
                    desc = "Show pulse timers for supported totems?",
                    type = "toggle",
                    set = function(info, newValue) SamyTotemBarTimersDatabase:SetIsShowPulse(k, newValue) end,
                    get = function() return SamyTotemBarTimersDatabase:GetIsShowPulse(k) end
                },
                order = {
                    order   = 3,
                    name    = "Order",
                    min     = 1,
                    max     = #SamyTotemBarTimersDB.totemLists,
                    softMin = 1,
                    softMax = #SamyTotemBarTimersDB.totemLists,
                    step    = 1,
                    bigStep = 1,
                    type    = "range",
                    set     = function(info, newValue) SamyTotemBarTimersDatabase:SetTotemListOrder(k, newValue) end,
                    get     = function() return SamyTotemBarTimersDatabase:GetTotemListOrder(k) end,
                }
            }
        }
    end

    local ACD3 = LibStub("AceConfigDialog-3.0")
    LibStub("AceConfig-3.0"):RegisterOptionsTable("SamyTotemBarTimers", options, { "stt", "SamyTotemBarTimers" })
    local optFrame = ACD3:AddToBlizOptions("SamyTotemBarTimers", "SamyTotemBarTimers")
end

function SamyTotemBarTimersDatabase:SetWarnIfMissingBuffEnabled(isEnabled)
    _db.isWarnIfMissingBuff = isEnabled
end

function SamyTotemBarTimersDatabase:GetWarnIfMissingBuffEnabled()
    return _db.isWarnIfMissingBuff
end

function SamyTotemBarTimersDatabase:GetTotemLists()
    return _db.totemLists
end

function SamyTotemBarTimersDatabase:SetTotemListEnabled(totemListId, isEnabled)
    _db.totemLists[totemListId].isEnabled = isEnabled
    _SamyTotemBarTimers:SetActiveTotemEnabled(totemListId, isEnabled)
end

function SamyTotemBarTimersDatabase:GetTotemListEnabled(totemListId)
    return _db.totemLists[totemListId].isEnabled
end

function SamyTotemBarTimersDatabase:SetIsShowPulse(totemListId, isShowPulseTimers)
    _db.totemLists[totemListId].isShowPulseTimers = isShowPulseTimers
    _SamyTotemBarTimers:SetIsShowPulse(totemListId, isShowPulseTimers)
end

function SamyTotemBarTimersDatabase:GetIsShowPulse(totemListId)
    return _db.totemLists[totemListId].isShowPulseTimers
end

function SamyTotemBarTimersDatabase:SetTotemListOrder(totemListId, newValue)
    local ordersChanged = {}
    local oldOrder = _db.totemLists[totemListId].order
    for k, v in pairs(_db.totemLists) do
        if (v.order == newValue) then
            v.order = oldOrder
            ordersChanged[k] = v.order
        end
    end

    _db.totemLists[totemListId].order = newValue
    ordersChanged[totemListId] = _db.totemLists[totemListId].order
    _SamyTotemBarTimers:TotemListsOrderChanged(ordersChanged)
end

function SamyTotemBarTimersDatabase:GetTotemListOrder(totemListId)
    return _db.totemLists[totemListId].order
end

function SamyTotemBarTimersDatabase:ResetConfig()
    EnsureSavedVariablesExists(true);
    ReloadUI();
end
