local masterModule = {
    DELETE_INTERNALS_FOLDER = false,
    DELETE_DEPENDENCIES_FOLDER = false,
    DELETE_SINGLETON_FOLDER = false,
    CLEANUP_INTERNALS = true,
    DELETE_UPON_CLEANUP_ARRAY = {}
}

--// Future-proof if other languages are desired for example

function masterModule:GeneratePassDictionary()
    self.PassDict = {
        RunService = game:GetService("RunService"),
        Players = game:GetService("Players"),
        LocalPlayer = game:GetService("Players").LocalPlayer,
        Aseta = self,
        Singletons = self.Singletons,
        IsMaster = false
    }
end

function masterModule:GetDefaultPassDict()
    return table.clone(self.PassDict)
end

function masterModule:_Require(moduleScript)
    return pcall(function()
        return require(moduleScript)
    end)
end

function masterModule:LoadInternals()
    local internalsFolder = script:WaitForChild("Internals")

    for _, module in internalsFolder:GetChildren() do
        local success, loadedModule = self:_Require(module)

        if not success then
           error(`Failed to load internal [{module}].`)
        end

        for index, value in loadedModule do
            self[index] = value
        end

        --// Just to be sure, not sure about this one
        table.clear(loadedModule)
        loadedModule = nil
    end

    if self["DELETE_INTERNALS_FOLDER"] then
        table.insert(self.DELETE_UPON_CLEANUP_ARRAY, internalsFolder)
    end
end

function masterModule:CleanUpInternalsMaster()
    local loadTime = self.Counter:Start(self:GetStringFromStringList("MASTER_CLEANUP"))
    self:Log(1, "MASTER_CLEANUP_INITIAL")

    for _, instance in self.DELETE_UPON_CLEANUP_ARRAY do
        instance:Destroy()
    end
    self.DELETE_UPON_CLEANUP_ARRAY = nil
    self:Log(1, "QUEUE_ARRAY_CLEANUP")

    if self["CLEANUP_INTERNALS"] then
        self["DELETE_INTERNALS_FOLDER"] = nil
        self["DELETE_DEPENDENCIES_FOLDER"] = nil
        self["DELETE_SINGLETON_FOLDER"] = nil

        self.FetchDependencies = nil
        self.FetchLoadDependencies = nil
        self.LoadSingletons = nil

        self.CleanUpInternalsSingleton = nil
        self.CleanUpInternalsMaster = nil

        self.TotalSingletonLoadInitTime = nil

        self.LoadAndSortSingletons = nil
        self.LoadDependenciesByArray = nil

        self.LoadInternals = nil
        self.Load = nil

        self["CLEANUP_INTERNALS"] = nil
    end

    self:Log(1, false, loadTime:Stop())
end

function masterModule:Load()
    warn("[Asetasar master] Initializing...")
    local loadTime = os.clock()

    self.IsMaster = true
    self.Script = script

    self:LoadInternals()
    self:FetchLoadDependencies()

    self:GeneratePassDictionary()
    self:LoadSingletons()

    self:CleanUpInternalsMaster()

    self:Log(2, "MASTER_INITIALIZED", (os.clock() - loadTime))
end

return masterModule