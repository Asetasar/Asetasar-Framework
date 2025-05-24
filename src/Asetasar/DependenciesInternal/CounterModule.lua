local counterModule = {
    ["#OneTimeLoad"] = true,
    ["#Index"] = "DbgCounter"
}

function counterModule:Start(formatString)
    local returnTable = {
        StartTime = os.clock()
    }

    function returnTable:Stop()
        self.StopTime = os.clock()

        local timeElapsed = self.StopTime - self.StartTime

        if formatString then
            return string.format(formatString, tostring(timeElapsed))
        else
            return timeElapsed
        end
    end

    function returnTable:Reset()
        self.PreviousStartTime = self.StartTime
        self.PreviousStoTime = self.StopTime or 0

        self.StartTime = os.clock()
        self.StopTime = nil
    end

    return returnTable
end

return counterModule