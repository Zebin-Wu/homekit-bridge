local char = require "hap.char"
local tab = require "tab"

local lock = {}

local logger = log.getLogger("lock")
local inited = false

function lock.isInited()
    return inited
end

function lock.init()
    inited = true
    logger:info("Initialized.")
    return true
end

function lock.deinit()
    inited = false
    logger:info("Deinitialized.")
end

local function checkAccessoryConf(conf)
    return true
end

local function lockMechanismLockCurrentStateCharacteristic()
    return {
        format = "UInt8",
        iid = hap.getNewInstanceID(),
        type = "LockCurrentState",
        props = {
            readable = true,
            writable = false,
            supportsEventNotification = true,
            hidden = false,
            requiresTimedWrite = false,
            supportsAuthorizationData = false,
            ip = { controlPoint = false, supportsWriteResponse = false },
            ble = {
                supportsBroadcastNotification = true,
                supportsDisconnectedNotification = true,
                readableWithoutSecurity = false,
                writableWithoutSecurity = false
            }
        },
        units = "None",
        constraints = {
            minVal = 0,
            maxVal = 3,
            stepVal = 1
        },
        cbs = {
            read = function (request, context)
                logger:info(string.format("Read currentState: %s",
                    tab.findKey(char.LockCurrentState, context.curState)))
                return context.curState, hap.Error.None
            end
        }
    }
end

local function lockMechanismLockTargetStateCharacteristic()
    return {
        format = "UInt8",
        iid = hap.getNewInstanceID(),
        type = "LockTargetState",
        props = {
            readable = true,
            writable = true,
            supportsEventNotification = true,
            hidden = false,
            requiresTimedWrite = true,
            supportsAuthorizationData = false,
            ip = { controlPoint = false, supportsWriteResponse = false },
            ble = {
                supportsBroadcastNotification = true,
                supportsDisconnectedNotification = true,
                readableWithoutSecurity = false,
                writableWithoutSecurity = false
            }
        },
        units = "None",
        constraints = {
            minVal = 0,
            maxVal = 1,
            stepVal = 1
        },
        cbs = {
            read = function (request, context)
                logger:info(string.format("Read targetState: %s",
                    tab.findKey(char.LockTargetState, context.tgtState)))
                return context.tgtState, hap.Error.None
            end,
            write = function (request, value, context)
                local changed = false
                logger:info(string.format("Write targetState: %s",
                    tab.findKey(char.LockTargetState, value)))
                if value ~= context.tgtState then
                    context.tgtState = value
                    changed = true
                end
                return changed, hap.Error.None
            end
        }
    }
end

local function lockManagementLockControlPointCharacteristic()
    return {
        format = "TLV8",
        iid = hap.getNewInstanceID(),
        type = "LockControlPoint",
        props = {
            readable = false,
            writable = true,
            supportsEventNotification = false,
            hidden = false,
            requiresTimedWrite = true,
            supportsAuthorizationData = false,
            ip = { controlPoint = false, supportsWriteResponse = false },
            ble = {
                supportsBroadcastNotification = false,
                supportsDisconnectedNotification = false,
                readableWithoutSecurity = false,
                writableWithoutSecurity = false
            }
        },
        cbs = {
            write = function (request, value, context)
                return false, hap.Error.None
            end
        }
    }
end

local function lockManagementVersionCharacteristic()
    return {
        format = "String",
        iid = hap.getNewInstanceID(),
        type = "Version",
        props = {
            readable = true,
            writable = false,
            supportsEventNotification = false,
            hidden = false,
            requiresTimedWrite = false,
            supportsAuthorizationData = false,
            ip = { controlPoint = false, supportsWriteResponse = false },
            ble = {
                supportsBroadcastNotification = false,
                supportsDisconnectedNotification = false,
                readableWithoutSecurity = false,
                writableWithoutSecurity = false
            }
        },
        constraints = { maxLen = 64 },
        cbs = {
            read = function (request, context)
                return "1.0", hap.Error.None
            end
        }
    }
end

function lock.gen(conf)
    if checkAccessoryConf(conf) == false then
        return nil
    end
    local state = {
        curState = char.LockCurrentState.Unsecured,
        tgtState = char.LockTargetState.Unsecured
    }
    return {
        aid = hap.getNewBridgedAccessoryID(),
        category = "BridgedAccessory",
        name = conf.name,
        mfg = "Acme",
        model = "Lock1,1",
        sn = conf.sn,
        fwVer = "1",
        hwVer = "1",
        services = {
            hap.AccessoryInformationService,
            hap.HapProtocolInformationService,
            hap.PairingService,
            {
                iid = hap.getNewInstanceID(),
                type = "LockMechanism",
                name = "Lock",
                props = {
                    primaryService = true,
                    hidden = false,
                    ble = {
                        supportsConfiguration = false,
                    }
                },
                chars = {
                    char.newServiceSignatureCharacteristic(),
                    char.newNameCharacteristic(),
                    lockMechanismLockCurrentStateCharacteristic(),
                    lockMechanismLockTargetStateCharacteristic()
                }
            },
            {
                iid = hap.getNewInstanceID(),
                type = "LockManagement",
                props = {
                    primaryService = false,
                    hidden = false,
                    ble = {
                        supportsConfiguration = false,
                    }
                },
                chars = {
                    char.newServiceSignatureCharacteristic(),
                    lockManagementLockControlPointCharacteristic(),
                    lockManagementVersionCharacteristic()
                }
            }
        },
        cbs = {
            identify = function (request, context)
                logger:info("Identify callback is called.")
                logger:info(string.format("transportType: %s, remote: %s.",
                    request.transportType, request.remote))
                return hap.Error.None
            end
        },
        context = state,
    }
end

return lock