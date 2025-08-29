local dependencyHandler = {}

function dependencyHandler:IndexDependencyToDict(fetchedDependenciesDict, dependencyModule, loadedDependency)
    local dependencyIndex = loadedDependency["#Index"]

    if not loadedDependency["#OneTimeLoad"] then
        fetchedDependenciesDict[dependencyIndex] = {
                dependencyModule,
                loadedDependency
            }
    else
        fetchedDependenciesDict[dependencyIndex] = loadedDependency
    end

    loadedDependency["#OneTimeLoad"] = nil
    loadedDependency["#Index"] = nil
end

function dependencyHandler:FetchDependencies(dependencyArray)
    local fetchedDependencies = {}

    for _, dependency in dependencyArray do
        local success, loadedDependency = pcall(function()
            return require(dependency)
        end)

        if not success then
            self:Log(3, "DEPENDENCY_FAILED_LOAD", dependency, loadedDependency)

            continue
        end

        local passThroughDict = {}

        self:IndexDependencyToDict(fetchedDependencies, dependency, loadedDependency)

        if loadedDependency.AsetaLoad then
            loadedDependency:AsetaLoad(passThroughDict)
        end
    end

    return fetchedDependencies
end

function dependencyHandler:GetDependency(dependencyIndex)
    local dependency = self.Dependencies[dependencyIndex]
    local typeofDependency = typeof(dependency)

    if not dependency then
        return false, self:FormatByStringList("X_DOESNT_EXIST", dependencyIndex)
    end

    if (typeofDependency == "table") then
        --// Naive approach, change if it creates issues.
        if #dependency == 2 then
            local loadedDependency = dependency[2]

            self.Dependencies[dependencyIndex] = dependency[1]

            return true, loadedDependency
        else
            return true, dependency
        end
    elseif (typeofDependency == "Instance") then
        local success, loadedDependency = pcall(function()
            return require(dependency)
        end)

        if not success then
            return false, loadedDependency
        end

        return true, loadedDependency
    else
        return false, self:FormatByStringList("INVALID_TYPEOF_DEPENDENCY", typeofDependency)
    end

    --// Assumptions made, keeping it simple, because there is no need to verify stuff like this.
end

function dependencyHandler:LoadDependenciesByArray(dependencyIndexArray, indexToDict)
    local didSucceed, errorArray = true, {}

    for _, dependencyIndex in dependencyIndexArray do
        local success, loadedDependency = self:GetDependency(dependencyIndex)

        if not success then
            didSucceed = false

            table.insert(errorArray, loadedDependency)

            continue
        end

        indexToDict[dependencyIndex] = loadedDependency
    end

    return didSucceed, errorArray
end

function dependencyHandler:GetInternals()
    return {
        _log = self._log,
        Counter = self.Counter,
        DependencyHandler = self
    }
end

function dependencyHandler:FetchLoadDependencies(sharedKeys)
    for key, value in sharedKeys do
        self[key] = value
    end

    local dependencies = self.Script:WaitForChild("Dependencies")
    local internalDependencies = self._Internal.Dependencies
    internalDependencies = self:FetchDependencies(internalDependencies)

    self._log = internalDependencies["Logger"]
    self.Counter = internalDependencies["DbgCounter"]

    if self.Config["TransferInternalDependenciesForUserUse"] then
        self.Dependencies = internalDependencies
    else
        self.Dependencies = {}
    end

    local dependencyCounter = self.Counter:Start(self:GetStringFromStringList("FINISHED_FETCHING_DEPENDENCIES_TIME"))
    self:Log(1, "FETCHING_DEPENDENCIES_INITIAL")

    for key, value in self:FetchDependencies(dependencies:GetChildren()) do
        self.Dependencies[key] = value
    end

    self:Log(2, false, dependencyCounter:Stop())

    if self.Config["TransferInternalDependenciesForUserUse"] then
        internalDependencies = self.Script.Internal.Dependencies

        for _, module in internalDependencies:GetChildren() do
            module.Parent = dependencies
        end
    end

    if self.Config.RemoveFolder["Dependencies"] then
        dependencies:Destroy()
    end

    return self.Dependencies
end

return dependencyHandler