SamyTotemBarTimersDBVersion = {}

local function IsDoDbVersion(versionNumber, db)
    if (db and (not db.version or db.version < versionNumber)) then
        return true
    end

    return false
end

function SamyTotemBarTimersDBVersion:UpdateDatabase(SamyTotemBarTimersDB, forceRun, setDefault)
    if forceRun then
        SamyTotemBarTimersDB.version = 0
    end

    if (IsDoDbVersion(1.0, SamyTotemBarTimersDB)) then
        isReset = true
        SamyTotemBarTimersUtils:Print("DBVersion 1.0 initialize db")
        SamyTotemBarTimersDB.version = 1.0
    end
end
