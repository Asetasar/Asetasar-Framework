local sharedFunctionsHandler = {}

function sharedFunctionsHandler:SerializeFunction(_self, func)
    return {
        Serialized = function(...)
            return func(_self, ...)
        end,
        Raw = func
    }
end

function sharedFunctionsHandler:IndexFunction(funcSelf, functionIndex, func)
    if typeof(funcSelf) ~= "table" then
        return false, self:FormatByStringList("X_EXPECTED_GOT_X", "Table", typeof(func))
    end

    if typeof(functionIndex)  ~= "string" then
        return false, self:FormatByStringList("X_EXPECTED_GOT_X", "String", typeof(func))
    end

    if typeof(func) ~= "function" then
        return false, self:FormatByStringList("X_EXPECTED_GOT_X", "Function", typeof(func))
    end

    self.SharedFunctions[functionIndex] = self:SerializeFunction(funcSelf, func)

    self:Log(1, "SHARED_FUNCTION", functionIndex)

    return true
end

function sharedFunctionsHandler:IndexFunctionsFromArray(funcSelf, functionDataArray)
    local success, errorArray = true, {}

    for functionIndex, actualFunctionIndex in functionDataArray do
        local _success, _error = self:IndexFunction(funcSelf, functionIndex, funcSelf[actualFunctionIndex])

        if not _success then
            success = false

            table.insert(errorArray, _error)
        end
    end

    return success, errorArray
end

function sharedFunctionsHandler:GetSharedFunction(functionIndex, getRaw)
    local sharedFunctionData = self.SharedFunctions[functionIndex]

    if not sharedFunctionData then
        return false
    end

    return getRaw and sharedFunctionData.Raw or sharedFunctionData.Serialized
end

function sharedFunctionsHandler:GetInternals()
    return {
        IndexFunction = function(_, ...)
            return sharedFunctionsHandler:IndexFunction(...)
        end,
        GetSharedFunction = function(_, ...)
            return sharedFunctionsHandler:GetSharedFunction(...)
        end,
        IndexFunctionsFromArray = function(_, ...)
            return sharedFunctionsHandler:IndexFunctionsFromArray(...)
        end
    }
end

function sharedFunctionsHandler:Load(sharedKeys)
    for key, value in sharedKeys do
        self[key] = value
    end

    self.SharedFunctions = {}
end

return sharedFunctionsHandler