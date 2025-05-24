local exampleSingleton = {
    _AsetaHeader = {
        ["#Index"] = "Module1",
        ["#Dependencies"] = {"DbgCounter", "Toilet"},
        ["#IgnoreDependencyErrors"] = true,
        ["#LoadOrder"] = 2,
        ["#DoNotCleanupInternals"] = true
    }
}

function exampleSingleton:AsetaInit(passThroughDict)
    for index, value in passThroughDict do
        self[index] = value
    end

    print("Module1 loaded before error")

    self.Nil += 1
end

return exampleSingleton