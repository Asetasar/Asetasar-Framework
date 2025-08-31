local masterModule = {
    CleanupInstanceArray = {}
}

function masterModule:GetDefaultPassDict()
    return {
        Aseta = self,
        Singletons = self.Singletons,
        IsMaster = false
    }
end

function masterModule:_Require(moduleScript)
    return pcall(function()
        return require(moduleScript)
    end)
end

function masterModule:GetStringFromStringList(stringIndex)
    return self.StringList[stringIndex]
end

function masterModule:FormatByStringList(messageType, ...)
    local stringArray, isEmpty = self._log:SanitizeArrayToString({...})

    if isEmpty then
        return self.StringList[messageType]
    else
        return string.format(self.StringList[messageType], table.unpack(stringArray))
    end
end

function masterModule:Log(logType, messageType, ...)
    if not self._log then
        --// Will work because always 1 concated string will be passed
        local errorMessage = {...}
        errorMessage = errorMessage[1]

        print(`[Asetasar master]: {messageType} {...}`)
    end

    if not messageType then
        self._log:Log(logType, "[Asetasar master]:", ...)
    else
        self._log:Log(logType, "[Asetasar master]:", self:FormatByStringList(messageType, ...))
    end
end

function masterModule:IndexAndLoadInternalStructure()
    local internalFolder = script:WaitForChild("Internal")

    self._Internal = {}

    for _, module in internalFolder:GetDescendants() do
        if not module:IsA("ModuleScript") then
            continue
        end

        local moduleKey = module.Parent.Name

        if self._Internal[moduleKey] then
            self._Internal[moduleKey][module.Name] = module
        else
            self._Internal[moduleKey] = {[module.Name] = module}
        end
    end
end

function masterModule:GetLoadMap()
    local success, loadMap = self:_Require(script:FindFirstChild("LoadMap"))

    if not success then
        self:Log(3, "FAILED_LOADMAP_LOAD", loadMap)
    end

    return loadMap
end

function masterModule:LoadDataStorage()
    local success, dataStorageHandler = self:_Require(self._Internal.Modules.DataStorageHandler)

    if not success then
        --// Cant use stringList
        self:Log(3, `DataStorageHandler failed to load! Error: {dataStorageHandler}`)
    end

    dataStorageHandler:FetchLoadDataSources({
        Script = script,
        _Internal = self._Internal,
        FormatByStringList = self.FormatByStringList
    })

    for key, value in dataStorageHandler:GetInternals() do
        self[key] = value
    end
end

function masterModule:LoadDependencies()
    local success, dependencyHandler = self:_Require(self._Internal.Modules.DependencyHandler)

    if not success then
        self:Log(3, "FAILED_LOAD_DEPENDENCY_HANDLER", dependencyHandler)
    end

    dependencyHandler:FetchLoadDependencies({
        Script = script,
        _Internal = self._Internal,
        FormatByStringList = self.FormatByStringList,
        GetStringFromStringList = self.GetStringFromStringList,
        StringList = self.StringList,
        Config = self.Config,
        Log = self.Log
    })

    for key, value in dependencyHandler:GetInternals() do
        self[key] = value
    end
end

function masterModule:LoadSharedFuncsHandler()
    local success, sharedFuncsHandler = self:_Require(self._Internal.Modules.SharedFunctionsHandler)

    if not success then
        self:Log(3, "FAILED_LOAD_SHAREDFUNC_HANDLER", sharedFuncsHandler)
    end

    sharedFuncsHandler:Load({
        _log = self._log,
        Log = self.Log,
        StringList = self.StringList,
        FormatByStringList = self.FormatByStringList,
        GetStringFromStringList = self.GetStringFromStringList
    })

    for key, value in sharedFuncsHandler:GetInternals() do
        self[key] = value
    end

    self.SharedFuncsHandler = sharedFuncsHandler

    self:Log(1, "LOADED_SHARED_FUNC_HANDLER")
end

function masterModule:LoadSingletons()
    local success, singletonHandler = self:_Require(self._Internal.Modules.SingletonHandler)

    if not success then
        self:Log(3, "FAILED_LOAD_SINGLETON_HANDLER", singletonHandler)
    end

    singletonHandler:LoadSingletons({
        PassthroughDict = self:GetDefaultPassDict(),
        Script = script,
        Counter = self.Counter,
        Log = self.Log,
        _log = self._log,
        StringList = self.StringList,
        Config = self.Config,
        Singletons = self.Singletons,
        FormatByStringList = self.FormatByStringList,
        DependencyHandler = self.DependencyHandler,
        DataStoreHandler = self.DataStorageHandler,
        SharedFuncsHandler = self.SharedFuncsHandler,
        Loadmap = self:GetLoadMap()
    })

    for key, value in singletonHandler:GetInternals() do
        self[key] = value
    end
end

function masterModule:CleanUpInternalsMaster()
    local loadTime = self.Counter:Start(self:GetStringFromStringList("MASTER_CLEANUP"))
    self:Log(1, "MASTER_CLEANUP_INITIAL")

    if self.Config.RemoveFolder["Internal"] then
        table.insert(self.CleanupInstanceArray, script.Internal)
    end

    if self.Config.CleanupMaster then
        self.DataStoreHandler = nil
        self.DependencyHandler = nil
        self.SharedFuncsHandler = nil

        --self.FormatByStringList = nil
        --self.StringList = nil
        --self.Log = nil
        --self._log = nil
        --self.GetStringFromStringList = nil

        self.Counter = nil
        self.GetDefaultPassDict = nil
        self.GetLoadMap = nil
        self.IndexAndLoadInternalStructure = nil
        self.Load = nil
        self.LoadDataStorage = nil
        self.LoadDependencies = nil
        self.LoadSharedFuncsHandler = nil
        self.LoadSingletons = nil
        self._Internal = nil
        self._Require = nil
        self.CleanUpInternalsMaster = nil
    end

    for _, instance in self.CleanupInstanceArray do
        instance:Destroy()
    end
    self.CleanupInstanceArray = nil

    self.Config = nil

    self:Log(1, "QUEUE_ARRAY_CLEANUP")
    self:Log(1, false, loadTime:Stop())
end

function masterModule:Load()
    print("[Asetasar master] Initializing...")
    local loadTime = os.clock()

    self.IsMaster = true
    self.Script = script

    self:IndexAndLoadInternalStructure()

    self:LoadDataStorage()
    self:LoadDependencies()
    self:LoadSharedFuncsHandler()
    self:LoadSingletons()

    self:CleanUpInternalsMaster()

    print(self)

    self:Log(2, "MASTER_INITIALIZED", (os.clock() - loadTime))
end

return masterModule