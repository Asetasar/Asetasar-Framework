local BITSIZE_USED = {"writeu8", "readu8"}

local signalHandler = {
    CallbackFunctionArray = {},
    AvailableIndexes = {},
    ["#OneTimeLoad"] = true,
    ["#Index"] = "Signals"
}

local signalHandlerHolder = {}
signalHandlerHolder.__INDEX = signalHandlerHolder

local bufferWrapper = {}
local assertWrapper = {}

function assertWrapper:Function(_function)
    local varTypeOf = typeof(_function)

    if varTypeOf ~= "function" then
        error(`Function expected, got {varTypeOf}`)

        return true
    end

    return false
end

function assertWrapper:Number(number)
    local varTypeOf = typeof(number)

    if varTypeOf ~= "number" then
        error(`Number expected, got {varTypeOf}`)

        return true
    end

    return false
end

function bufferWrapper:Write(_buffer, value)
    buffer[BITSIZE_USED[1]](_buffer, 0, value)
end

function bufferWrapper:Read(_buffer)
    return buffer[BITSIZE_USED[2]](_buffer, 0)
end

function bufferWrapper:WriteSecondary(_buffer, value)
    buffer.writeu8(_buffer, 1, value)
end

function bufferWrapper:ReadSecondary(_buffer)
    return buffer.readu8(_buffer, 1)
end

function bufferWrapper:CreatePointer(value, signalState)
    local _buffer = buffer.create(2)

    self:Write(_buffer, value)
    self:WriteSecondary(_buffer, signalState)

    return _buffer
end

function bufferWrapper:ReadPointer(_buffer)
    local firstValue = self:Read(_buffer)
    local secondValue = self:ReadSecondary(_buffer)

    return firstValue, secondValue
end

local function assignIndexToCallbackFunction(callbackFunction)
    local callbackFunctionArray = signalHandler.CallbackFunctionArray
    local availibleIndexes = signalHandler.AvailableIndexes
    local availableIndexesAmount = #availibleIndexes

    if availableIndexesAmount == 0 then
        table.insert(callbackFunctionArray, callbackFunction)

        return #callbackFunctionArray
    end

    local availibleIndex = availibleIndexes[availableIndexesAmount]
    callbackFunctionArray[availibleIndex] = callbackFunctionArray

    table.remove(availibleIndexes, availableIndexesAmount)

    return availibleIndex
end

function signalHandlerHolder:Connect(callbackFunction, priority)
    if assertWrapper:Function(callbackFunction) then
        return
    end

    if priority and assertWrapper:Number(priority) then
        return
    else
        priority = #self.PointerArray + 1
    end

    local assignedIndex = assignIndexToCallbackFunction(callbackFunction)
    local pointerBuffer = bufferWrapper:CreatePointer(assignedIndex, 0)

    table.insert(self.PointerArray, priority, pointerBuffer)

    return {
        Disconnect = function()
            bufferWrapper:WriteSecondary(pointerBuffer, 2)
        end,
        DisconnectAfterSignal = function()
            bufferWrapper:WriteSecondary(pointerBuffer, 1)
        end
    }
end

function signalHandlerHolder:Once(callbackFunction, priority)
    if assertWrapper:Function(callbackFunction) then
        return
    end

    if priority and assertWrapper:Number(priority) then
        return
    else
        priority = #self.PointerArray + 1
    end

    local assignedIndex = assignIndexToCallbackFunction(callbackFunction)
    local pointerBuffer = bufferWrapper:CreatePointer(assignedIndex, 1)

    table.insert(self.PointerArray, priority, pointerBuffer)

    return {
        Disconnect = function()
            bufferWrapper:WriteSecondary(pointerBuffer, 2)
        end
    }
end

function signalHandlerHolder:Fire(...)
    for index, pointerBuffer in self.PointerArray do
        local pointerIndex, signalState = bufferWrapper:ReadPointer(pointerBuffer)

        if signalState == 2 then
            --// Disconnect state
            self.GlobalCallbackFunctionArray[pointerIndex] = 0
            table.insert(self.GlobalAvailableIndexes, pointerIndex)
            table.remove(self.PointerArray, index)

            continue
        end

        self.GlobalCallbackFunctionArray[pointerIndex](...)

        if signalState == 1 then
            --// Once state
            self.GlobalCallbackFunctionArray[pointerIndex] = 0
            table.insert(self.GlobalAvailableIndexes, pointerIndex)
            table.remove(self.PointerArray, index)
        end
    end
end

--[[
function signalHolder:Wait(callbackFunction)

end
]]

function signalHandler.New()
    local _signalHolder = signalHandlerHolder
    local pointerArray = {}

    setmetatable(_signalHolder, signalHandlerHolder)
    _signalHolder.PointerArray = pointerArray
    _signalHolder.GlobalCallbackFunctionArray = signalHandler.CallbackFunctionArray
    _signalHolder.GlobalAvailableIndexes = signalHandler.AvailableIndexes

    return _signalHolder
end

return signalHandler