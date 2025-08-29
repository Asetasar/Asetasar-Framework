local dataStorageHandler = {}

function dataStorageHandler:FetchDataSources(dataArray)
    local fetchedData = {}

    for _, data in dataArray do
        local success, loadedData = pcall(function()
            return require(data)
        end)

        if not success then
            task.spawn(error, `Data [{data.Name}] failed to load! Error: {loadedData}.`)

            continue
        end

        local dataIndex = loadedData["#Index"] or data.Name

        fetchedData[dataIndex] = loadedData
        loadedData["#Index"] = nil

        if loadedData.AsetaInit then
            loadedData:AsetaInit()
        end
    end

    return fetchedData
end

function dataStorageHandler:GetAllDataSourcesFromFolder(folder)
    local fetchedDataSources = {}

    for _, dataSource in folder:GetDescendants() do
        if not dataSource:IsA("ModuleScript") then
            continue
        end

        table.insert(fetchedDataSources, dataSource)
    end

    return fetchedDataSources
end

function dataStorageHandler:LoadDataSourcesByArray(dataSourceIndexArray, indexToDict)
    local success, errorArray = true, {}

    for _, dataSourceIndex in dataSourceIndexArray do
        local dataSource = self.Data[dataSourceIndex]
        if dataSource then
            indexToDict[dataSourceIndex] = dataSource
        else
            success = false

            table.insert(errorArray, self:FormatByStringList("DATASOURCE_DOESNT_EXIST", dataSourceIndex))
        end
    end

    return success, errorArray
end

function dataStorageHandler:GetInternals()
    return {
        Data = self.Data,
        DataStorageHandler = self,
        Config = self.Config,
        StringList = self.StringList
    }
end

function dataStorageHandler:FetchLoadDataSources(sharedKeys)
    for key, value in sharedKeys do
        self[key] = value
    end

    local dataSources = self.Script:WaitForChild("Data")
    local internalDataSources = self._Internal.Data
    internalDataSources = dataStorageHandler:FetchDataSources(internalDataSources)

    self.StringList = internalDataSources.StringList
    self.Config = internalDataSources.Configuration

    if self.Config["TransferInternalDataForUserUse"] then
        self.Data = internalDataSources
    else
        self.Data = {}
    end

    for key, value in dataStorageHandler:FetchDataSources(dataStorageHandler:GetAllDataSourcesFromFolder(dataSources)) do
        self.Data[key] = value
    end

    if self.Config["TransferInternalDataForUserUse"] then
        for _, module in internalDataSources do
            module.Parent = dataSources
        end
    end

    if self.Config.RemoveFolder["Data"] then
        dataSources:Destroy()
    end
end

return dataStorageHandler