local logModule = {
    ["#OneTimeLoad"] = true,
    ["#Index"] = "Logger"
}

local logFuncArray = {
    print,
    warn,
    error
}

function logModule:SanitizeArrayToString(array)
    if #array == 0 then
        return array, true
    end

    for index = 1, #array do
        array[index] = tostring(array[index])
    end

    return array, false
end

function logModule:Log(logType, ...)
    local sanitizedText = self:SanitizeArrayToString({...})
    local desiredLogType = logFuncArray[logType or 1]

    sanitizedText = table.concat(sanitizedText, " ")

    task.spawn(desiredLogType, sanitizedText)
end

return logModule