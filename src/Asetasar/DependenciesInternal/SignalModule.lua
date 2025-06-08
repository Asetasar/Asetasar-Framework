local signalHandler = {
    CallbackFunctionLookup = {},
    SignalToCleanUp = {},
    GC_RUNNING = false,

    ["#OneTimeLoad"] = true,
    ["#Index"] = "Signals"
}

local typeToNumber = {
    Connect = 0,
    Once = 1,
    DisconnectAfterOnce = 2
}

local signalHandlerHolder = {}
signalHandlerHolder.__INDEX = signalHandlerHolder

local GC_TIME = 12

local assertWrapper = {
    Function = function(_function)
        local varTypeOf = typeof(_function)

        if varTypeOf ~= "function" then
            error(`Function expected, got {varTypeOf}`)

            return true
        end

        return false
    end,
    Number = function(number)
        local varTypeOf = typeof(number)

        if varTypeOf ~= "number" then
            error(`Number expected, got {varTypeOf}`)

            return true
        end

        return false
    end
}

local function sanitizePriority(priority)
    if priority and not assertWrapper.Number(priority) then
        return priority
    end

    return false
end

local function generateReturnDictForConnection(signal, callbackFunction)
    local callbackFunctionLookup = signalHandler.CallbackFunctionLookup
    local connectionsArray = signal._Connections

    return {
        Disconnect = function()
            local callbackFunctionIndex = table.find(connectionsArray, callbackFunction)

            if not callbackFunction then
                error("Signal no longer exists.")
            end

            signalHandler:MarkForCleanup(signal, callbackFunction, callbackFunctionIndex)
        end,
        ChangeConnectionType = function(_, signalType)
            local numberFromType = typeToNumber[signalType]

            if not numberFromType then
                error(`Invalid connection type {signalType}`)
            end

            if callbackFunctionLookup[callbackFunction] == -1 then
                error("Signal no longer exists")
            end

            callbackFunctionLookup[callbackFunction] = numberFromType
        end,
        Wait = function()
            return signal:Wait()
        end
    }
end

local function sanitizePassArgs(callbackFunction, priority)
    assertWrapper.Function(callbackFunction)
    return sanitizePriority(priority)
end

function signalHandler:MarkForCleanup(signal, callbackFunction, index)
    local indexedSignalArray =  signalHandler.SignalToCleanUp[signal]

    if not indexedSignalArray then
        signalHandler.SignalToCleanUp[signal] = {}
        indexedSignalArray = signalHandler.SignalToCleanUp[signal]
    end

    table.insert(indexedSignalArray, index)
    self.CallbackFunctionLookup[callbackFunction] = -1
end

function signalHandlerHolder:AssignNewConnection(callbackFunction, typeofNumber, priority)
    self._CallbackFunctionLookup[callbackFunction] = typeofNumber

    if priority then
        table.insert(self._Connections, priority, callbackFunction)
    else
        table.insert(self._Connections, callbackFunction)
    end
end

function signalHandlerHolder:Connect(callbackFunction, priority)
    priority = sanitizePassArgs(callbackFunction, priority)

    self:AssignNewConnection(callbackFunction, typeToNumber["Connect"], priority)

    return generateReturnDictForConnection(self, callbackFunction)
end

function signalHandlerHolder:Once(callbackFunction, priority)
    priority = sanitizePassArgs(callbackFunction, priority)

    self:AssignNewConnection(callbackFunction, typeToNumber["Once"], priority)

    return generateReturnDictForConnection(self, callbackFunction)
end

function signalHandlerHolder:Wait()
    local thread = coroutine.running()

    self:Once(function()
        coroutine.resume(thread)
    end)

    return coroutine.yield()
end

function signalHandlerHolder:Fire(...)
    for index, callbackFunction in self._Connections do
        local typeofConnection = self._CallbackFunctionLookup[callbackFunction]

        print(typeofConnection)

        if not typeofConnection or typeofConnection == -1 then
            continue
        end

        callbackFunction(...)

        if typeofConnection == 1 or typeofConnection == 2 then
            signalHandler:MarkForCleanup(self, callbackFunction, index)
        end
    end
end

function signalHandler:CleanupRequest()
    for signal, desiredConnections in self.SignalToCleanUp do
        local signalConnections = signal._Connections

        for index = #desiredConnections, -1 do
            table.remove(signalConnections, index)
        end

        self.SignalToCleanUp[signal] = nil
    end
end

function signalHandler:InitializeGC()
    self.GC_RUNNING = true

    while task.wait(GC_TIME) do
        self:CleanupRequest()
    end
end

function signalHandler.New()
    local _signalHolder = signalHandlerHolder

    setmetatable(_signalHolder, signalHandlerHolder)
    _signalHolder._Connections = {}
    _signalHolder._CallbackFunctionLookup = signalHandler.CallbackFunctionLookup

    if not signalHandler.GC_RUNNING then
        task.spawn(signalHandler.InitializeGC, signalHandler)
    end

    return _signalHolder
end

return signalHandler