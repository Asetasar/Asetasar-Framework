local dependencyHandler = {
    Dependencies = {}
}

function dependencyHandler:FetchDependencies(dependencyFolder)
    local fetchedDependencies = {}

    for _, dependency in dependencyFolder:GetChildren() do
        local success, loadedDependency = self:_Require(dependency)

        if not success then
            self:Log(3, "DEPENDENCY_FAILED_LOAD", dependency, loadedDependency)

            continue
        end

        local dependencyIndex = loadedDependency["#Index"]
        if not loadedDependency["#OneTimeLoad"] then
                fetchedDependencies[dependencyIndex] = {
                    dependency,
                    loadedDependency
                }
        else
            fetchedDependencies[dependencyIndex] = loadedDependency
        end

        loadedDependency["#OneTimeLoad"] = nil
        loadedDependency["#Index"] = nil
    end

    return fetchedDependencies
end

function dependencyHandler:FetchLoadDependencies()
    local internalDependencies = self.Script:WaitForChild("DependenciesInternal")
    internalDependencies = self:FetchDependencies(internalDependencies)

    self.Dependencies = internalDependencies
    self._log = self.Dependencies["Logger"]
    self.Counter = self.Dependencies["DbgCounter"]

    local dependencyCounter = self.Counter:Start(self:GetStringFromStringList("FINISHED_FETCHING_DEPENDENCIES_TIME"))
    self:Log(1, "FETCHING_DEPENDENCIES_INITIAL")

    local dependencies = self.Script:WaitForChild("Dependencies")
    dependencies = self:FetchDependencies(dependencies)

    table.move(dependencies, 1, #dependencies, #self.Dependencies, self.Dependencies)

    self:Log(2, false, dependencyCounter:Stop())

    internalDependencies = self.Script:WaitForChild("DependenciesInternal")
    dependencies = self.Script:WaitForChild("Dependencies")

    if self["DELETE_DEPENDENCIES_FOLDER"] then
        table.insert(self.DELETE_UPON_CLEANUP_ARRAY, internalDependencies)
        table.insert(self.DELETE_UPON_CLEANUP_ARRAY, dependencies)
    end

    for _, module in internalDependencies:GetChildren() do
        module.Parent = dependencies
    end

    internalDependencies:Destroy()
    --// No bullcrap, GC will clean this up
end

function dependencyHandler:GetDependency(dependencyIndex)
    local dependency = self.Dependencies[dependencyIndex]
    local typeofDependency = typeof(dependency)

    if not dependency then
        return false, self:FormatByStringList("DOESNT_EXIST")
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
        local success, loadedDependency = self:_Require(dependency)

        if not success then
            return false, loadedDependency
        end

        return true, loadedDependency
    else
        return false, self:FormatByStringList("INVALID_TYPEOF_DEPENDENCY", typeofDependency)
    end

    --// Assumptions made, keeping it simple, because there is no need to verify stuff like this.
    --// Only argument I could see would be exploiter inputting false
end

function dependencyHandler:LoadDependenciesByArray(dependencyIndexArray, indexToDict)
    local didSucceed, errorArray = true, {}

    for _, dependencyIndex in dependencyIndexArray do
        local success, loadedDependency = self:GetDependency(dependencyIndex)

        if not success then
            didSucceed = false

            table.insert(errorArray, self:FormatByStringList("DEPENDENCY_FAILED_LOAD", dependencyIndex, loadedDependency))

            continue
        end

        indexToDict[dependencyIndex] = loadedDependency
    end

    return didSucceed, errorArray
end

return dependencyHandler