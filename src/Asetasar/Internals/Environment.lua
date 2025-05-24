local environmentModule = {}

function environmentModule:GetStringFromStringList(messageType)
    return self.StringList[messageType]
end

function environmentModule:FormatByStringList(messageType, ...)
    local stringArray, isEmpty = self._log:SanitizeArrayToString({...})

    if isEmpty then
        return self:GetStringFromStringList(messageType)
    else
        return string.format(self:GetStringFromStringList(messageType), table.unpack(stringArray))
    end

    --// Just don't be a bad coder because I don't want to make this more complex than it already is
end

function environmentModule:Log(logType, messageType, ...)
    if not self._log then
        --// Will work because always 1 concated string will be passed
        local errorMessage = {...}
        errorMessage = errorMessage[1]

        error(`[Asetasar master] very internal error, the error in question:\n{messageType}`, 3)
    end

    if not messageType then
        self._log:Log(logType, "[Asetasar master]", ...)
    else
        self._log:Log(logType, "[Asetasar master]", self:FormatByStringList(messageType, ...))
    end
end

return environmentModule