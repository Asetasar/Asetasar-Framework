local singletonHandler = {
    ReverseSingletonsLookup = {},
    TotalSingletonLoadInitTime = 0
}

function singletonHandler:VerifyAndSerializeSingletonIntegrity(singleton, loadedSingleton)
    --// Somewhat stupid for now, wanted to future proof this.

    local asetaHeader = loadedSingleton["_AsetaHeader"]

    if not asetaHeader then
        loadedSingleton["_AsetaHeader"]  = {
            ["#Index"] = singleton.Name,
        }

        return
    end

    if not asetaHeader["#Index"] then
        asetaHeader["#Index"] = singleton.Name
    end
end

function singletonHandler:FindIndexBySingleton(singleton)
    return self.ReverseSingletonsLookup[singleton]
end

function singletonHandler:LoadSingleton(_singleton)
    local loadCounter = self.Counter:Start()
    local success, singleton = pcall(function()
        return require(_singleton)
    end)

    if not success then
        self:Log("SINGLETON_FAILED_LOAD", _singleton.Name, singleton)

        return success
    end

    self:VerifyAndSerializeSingletonIntegrity(_singleton, singleton)

    local asetaHeader = singleton["_AsetaHeader"]
    local dependencyArray = asetaHeader["#Dependencies"]
    local dataSourcesArray= asetaHeader["#DataSources"]
    local singletonIndex = asetaHeader["#Index"]
    local sharedFunctionsDict = asetaHeader["#SharedFunctions"]

    if dependencyArray and #dependencyArray > 0 then
        local passthroughDict = table.clone(self.PassthroughDict)

        local success, errorArray = self.DependencyHandler:LoadDependenciesByArray(dependencyArray, passthroughDict)

        for key, value in passthroughDict do
            singleton[key] = value
        end

        if not success then
            if #errorArray > 1 then
                self:Log(
                    3,
                    "FAILED_LOAD_MULTIPLE_DEPENDENCIES",
                    table.concat(errorArray, "\n")
                )
            else
                self:Log(
                    3,
                    "FAILED_LOAD_ONE_DEPENDENCY",
                    errorArray[1]
                )
            end
        end
    end

    if dataSourcesArray and #dataSourcesArray > 0 then
        local success, errorArray = self.DataStoreHandler:LoadDataSourcesByArray(dataSourcesArray, singleton)

        if not success then
            if #errorArray > 1 then
                self:Log(
                    3,
                    "FAILED_LOAD_MULTIPLE_DATASOURCES",
                    table.concat(errorArray, "\n")
                )
            else
                self:Log(
                    3,
                    "FAILED_LOAD_ONE_DATASOURCE",
                    errorArray[1]
                )
            end
        end
    end

    if sharedFunctionsDict then
        local success, errorArray = self.SharedFuncsHandler:IndexFunctionsFromArray(singleton, sharedFunctionsDict)

        if not success then
            if #errorArray > 1 then
                self:Log(
                    3, 
                    "FAILED_SHARE_MULTIPLE_FUNCS",
                    table.concat(errorArray, "\n")
                )
            else
                self:Log(
                    3,
                    "FAILED_SHARE_FUNCTION",
                    errorArray[1]
                )
            end
        end
    end

    self.ReverseSingletonsLookup[singleton] = singletonIndex
    self.Singletons[singletonIndex] = singleton

    return true, {
        Singleton = singleton,
        TimeElapsed = loadCounter:Stop(),
        SingletonIndex = singletonIndex
    }
end

function singletonHandler:LoadAndSortSingletons(singletonsArray)
    local _singletonsArray = table.clone(singletonsArray)

    table.clear(singletonsArray)

    for index = #_singletonsArray, 1, -1 do
        local _singleton = _singletonsArray[index]
        local success, singletonData = self:LoadSingleton(_singleton)

        if not success then
            table.remove(_singletonsArray, index)

            continue
        end

        local loadmapLoadIndex = table.find(self.Loadmap, singletonData.SingletonIndex)

        if loadmapLoadIndex then
            singletonsArray[loadmapLoadIndex] = singletonData
            table.remove(_singletonsArray, index)

            continue
        end

        _singletonsArray[index] = singletonData
    end

    for _, singleton in _singletonsArray do
        table.insert(singletonsArray, singleton)
    end
end

function singletonHandler:FetchSingletonsFromArray(array)
    local singletonsArray = {}

    for _, singleton in array do
        if singleton:IsA("ModuleScript") then
            table.insert(singletonsArray, singleton)
        elseif singleton:IsA("Folder") then
            table.insert(singletonsArray, table.unpack(self:FetchSingletonsFromArray()))
        end
    end

    if #singletonsArray > 0 then
        return singletonsArray
    end
end

function singletonHandler:GetSingleton(singletonIndex)
    return self.Singletons[singletonIndex]
end

function singletonHandler:GetInternals()
    return {
        GetSingleton = function(_, singletonIndex)
            return singletonHandler:GetSingleton(singletonIndex)
        end
    }
end

function singletonHandler:LoadSingletons(requiredData)
    for key, value in requiredData do
        singletonHandler[key] = value
    end

    self.Singletons = {}
    self:Log(1, "INITIALIZING_SINGLETONS_INITIAL")

    local singletonsFolder = self.Script:WaitForChild("Singletons")
    local singletonsArray = self:FetchSingletonsFromArray(singletonsFolder:GetChildren())

    local totalLoadTime = 0

    if not singletonsArray then
        warn("No singletons")
    end

    self:LoadAndSortSingletons(singletonsArray)

    for _, singletonData in singletonsArray do
        local singleton, singletonIndex, loadTime = singletonData.Singleton, singletonData.SingletonIndex, singletonData.TimeElapsed

        local initTime = self.Counter:Start()

        if not singleton["_AsetaHeader"]["#DoNotCleanupInternals"] then
            singleton["_AsetaHeader"] = nil
        end

        self._log:Log(2, self:FormatByStringList("LOADING_SINGLETON", singletonIndex))

        local success, _error = pcall(singleton.AsetaInit, singleton)

        if not success then
            self:Log(3, "SINGLETON_FAILED_LOAD", singletonIndex, _error)

            self.Singletons[singletonIndex] = nil

            continue
        end

        initTime = initTime:Stop()

        self._log:Log(1, self:FormatByStringList("SINGLETON_LOADED_INIT_TIME", singletonIndex, loadTime, initTime))

        totalLoadTime += (loadTime + initTime)
    end

    if self.Config.RemoveFolder["Singletons"] then
        singletonsFolder:Destroy()
    end

    self:Log(2, "SINGLETONS_INITIALIZED", totalLoadTime)
end

return singletonHandler