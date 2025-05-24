local singletonHandler = {
    Singletons = {},
    ReverseSingletonsLookup = {},
    TotalSingletonLoadInitTime = 0
}

function singletonHandler:CleanUpInternalsSingleton(singleton)
    singleton["_AsetaHeader"] = nil
end

function singletonHandler:VerifyAndSerializeSingletonIntegrity(singleton, loadedSingleton)
    --// Somewhat stupid for now, wanted to future proof this.

    local asetaHeader = loadedSingleton["_AsetaHeader"]

    if not asetaHeader then
        loadedSingleton["_AsetaHeader"]  = {
            ["#Index"] = singleton.Name,
            ["#LoadOrder"] = 999,
        }

        return
    end

    if not asetaHeader["#Index"] then
        asetaHeader["#Index"] = singleton.Name
    end

    if not asetaHeader["#LoadOrder"] then
        --// Might have to change this if it causes any issues
        asetaHeader["#LoadOrder"] = 999
    end

    if asetaHeader["#Dependencies"] and #asetaHeader["#Dependencies"] == 0 then
        asetaHeader["#Dependencies"] = nil
    end

    --// All that matters for simplifying code below is here.
end

function singletonHandler:FindIndexBySingleton(singleton)
    return self.ReverseSingletonsLookup[singleton]
end

function singletonHandler:LoadSingleton(_singleton, passThroughDict)
    local loadCounter = self.Counter:Start()
    local success, singleton = self:_Require(_singleton)

    if not success then
        return false, singleton
    end

    self:VerifyAndSerializeSingletonIntegrity(_singleton, singleton)

    local asetaHeader = singleton["_AsetaHeader"]
    local dependencyIndexArray = asetaHeader["#Dependencies"]
    local singletonIndex = asetaHeader["#Index"]
    local ignoreDependencyErrors = asetaHeader["#IgnoreDependencyErrors"]

    if dependencyIndexArray then
        local success, errorMessages = self:LoadDependenciesByArray(dependencyIndexArray, passThroughDict)

        if not success then
            local errorMessageIndex = (#errorMessages == 1) and "FAILED_LOAD_ONE_DEPENDENCY" or
                "FAILED_LOAD_MULTIPLE_DEPENDENCIES"

            self:Log(3, errorMessageIndex, table.concat(errorMessages, "\n"))

            if not ignoreDependencyErrors then
                return false
            end
        end
    end

    self.ReverseSingletonsLookup[singleton] = singletonIndex
    self.Singletons[singletonIndex] = singleton

    return true, {singleton, passThroughDict, loadCounter:Stop()}
end

function singletonHandler:LoadAndSortSingletons(singletonsArray)
    local _singletonsArray = table.clone(singletonsArray)

    table.clear(singletonsArray)

    for _, _singleton in _singletonsArray do
        local success, singletonPassthroughArray = self:LoadSingleton(_singleton, self:GetDefaultPassDict())

        if not success then
            self:Log(3, "SINGLETON_FAILED_LOAD", _singleton, singletonPassthroughArray)

            continue
        end

        table.insert(singletonsArray, singletonPassthroughArray[1]["_AsetaHeader"]["#LoadOrder"], singletonPassthroughArray)
    end
end

function singletonHandler:LoadSingletons()
    self:Log(1, "INITIALIZING_SINGLETONS_INITIAL")

    local singletonsFolder = self.Script:WaitForChild("Singletons")
    local singletonsArray = singletonsFolder:GetChildren()

    self:LoadAndSortSingletons(singletonsArray)

    for _, singletonAndPassthroughDict in singletonsArray do
        local singleton, passThroughDict, loadTime = table.unpack(singletonAndPassthroughDict)
        local asetaHeader = singleton["_AsetaHeader"]

        local initTime = self.Counter:Start()

        if not asetaHeader["#DoNotCleanupInternals"] then
            self:CleanUpInternalsSingleton(singleton)
        end

        local success, _error = pcall(singleton.AsetaInit, singleton, passThroughDict)
        local singletonIndex = self:FindIndexBySingleton(singleton)

        if not success then
            self:Log(3, "SINGLETON_FAILED_LOAD", self:FindIndexBySingleton(singleton), _error)

            self.Singletons[singletonIndex] = nil

            continue
        end

        initTime = initTime:Stop()

        self:Log(1, "SINGLETON_LOADED_INIT_TIME", singletonIndex, loadTime, initTime)
        self.TotalSingletonLoadInitTime += (loadTime + initTime)
    end

    if self["DELETE_SINGLETON_FOLDER"] then
        table.insert(self.DELETE_UPON_CLEANUP_ARRAY, singletonsFolder)
    end

    self:Log(2, "SINGLETONS_INITIALIZED", tostring(self.TotalSingletonLoadInitTime))
end

return singletonHandler