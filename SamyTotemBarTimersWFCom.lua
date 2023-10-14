SamyTotemBarTimersWFCom = {}
SamyTotemBarTimersWFCom.WfStatusList = {}

local COMM_PREFIX_OLD = "WFC01"
local COMM_PREFIX = "WF_STATUS"

local _incoming = {}

C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX_OLD)

function SamyTotemBarTimersWFCom:UpdateGroupRooster()
    local function addPlayerData(unitId)
        if (not UnitIsConnected(unitId)) then --Piece of shit, saying yes when someone goes offline
            return false
        end

        local playerGuid = UnitGUID(unitId)
        local _, unitClass = UnitClass(unitId)
        if (not playerGuid) then
            return false
        end

        local unitName = UnitName(unitId)
        local oldStatus = SamyTotemBarTimersWFCom.WfStatusList[playerGuid]
        SamyTotemBarTimersWFCom.WfStatusList[playerGuid] =
        {
            name = unitName,
            guid = playerGuid,
            hasWfCom = oldStatus and oldStatus.hasWfCom or false,
            isRelevant = SamyTotemBarTimersDB.wfComClass[unitClass],
            expirationTime = oldStatus and oldStatus.expirationTime or 0,
            duration = oldStatus and oldStatus.duration or 0
        }

        local incoming = _incoming[gGUID]
        if (incoming) then
            if (incoming.timeReceived + 10 <= GetTime()) then
                SamyTotemBarTimersWFCom:ChatMessageReceived(nil, incoming.prefix, incoming.message)
            end

            incoming[gGUID] = nil
        end

        return playerGuid
    end

    local unitGuids = {}
    local playerGuid = addPlayerData("player")
    if (playerGuid) then
        unitGuids[playerGuid] = true
    end

    for index = 1, 4 do
        local guid = addPlayerData("party" .. index)
        if (guid) then
            unitGuids[guid] = true
        end
    end

    for k, v in pairs(SamyTotemBarTimersWFCom.WfStatusList) do
        if (not unitGuids[k]) then
            SamyTotemBarTimersWFCom.WfStatusList[k] = nil
        end
    end
end

local function GetUnitIdFromGuid(guid)
    if (UnitGUID("player") == guid) then
        return "player"
    end

    for index = 1, 4 do
        local unitId = "party" .. tostring(index)
        local partyGuid = UnitGUID(unitId)
        if (partyGuid == guid) then
            return unitId
        end
    end

    return nil
end

function SamyTotemBarTimersWFCom:OnUpdate()
    local playerGuid = UnitGUID("player")
    if (not SamyTotemBarTimersWFCom.WfStatusList[playerGuid]) then
        return
    end

    local hasWepEnchant, expire = GetWeaponEnchantInfo("player")
    if (SamyTotemBarTimersWFCom.WfStatusList[playerGuid]) then
        SamyTotemBarTimersWFCom.WfStatusList[playerGuid].duration = hasWepEnchant and 1 or 0
        SamyTotemBarTimersWFCom.WfStatusList[playerGuid].expirationTime = hasWepEnchant and expire or 0
        SamyTotemBarTimersWFCom.WfStatusList[playerGuid].hasWfCom = true
    end

    for k, v in pairs(SamyTotemBarTimersWFCom.WfStatusList) do
        local unitId = GetUnitIdFromGuid(k)
        if (not unitId or not UnitIsConnected(unitId)) then
            SamyTotemBarTimersWFCom.WfStatusList[k] = nil
        end
    end
end

function SamyTotemBarTimersWFCom:ChatMessageReceived(event, prefix, message, channel, sender)
    if (prefix == COMM_PREFIX_OLD) then -- wf com old API
        local commType, expiration, lag, gGUID = strsplit(":", message)
        if (not SamyTotemBarTimersWFCom.WfStatusList[gGUID]) then
            _incoming[gGUID] = {
                prefix = prefix,
                message = message,
                timeReceived = GetTime()
            }

            return
        end

        if (commType == "W") then -- message w/ wf duration, should always fire on application)
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].duration = 1
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].expirationTime = GetTime() + expiration / 1000
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].hasWfCom = true
        elseif (commType == "E") then -- message wf lost
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].duration = 0
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].expirationTime = 0
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].hasWfCom = true
        elseif (commType == "I") then -- message signaling that unit has addon installed
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].hasWfCom = true
        end
    elseif (prefix == COMM_PREFIX) then --wf com new API
        local gGUID, spellID, expiration, lag = strsplit(':', message)
        if (not SamyTotemBarTimersWFCom.WfStatusList[gGUID]) then
            _incoming[gGUID] = {
                prefix = prefix,
                message = message,
                timeReceived = GetTime()
            }

            return
        end

        local spellID, expire, lagHome = tonumber(spellID), tonumber(expiration), tonumber(lagHome)
        if spellID then --update buffs
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].duration = 1
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].expirationTime = GetTime() + expire / 1000
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].hasWfCom = true
        else --addon installed or buff expired
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].duration = 0
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].expirationTime = 0
            SamyTotemBarTimersWFCom.WfStatusList[gGUID].hasWfCom = true
        end
    end
end
