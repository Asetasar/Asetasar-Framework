local exampleSingleton = {
    _AsetaHeader = {
        ["#Index"] = "Module2",
        ["#Dependencies"] = {"Logger"},
        ["#IgnoreDependencyErrors"] = true,
        ["#LoadOrder"] = 1
    }
}

function exampleSingleton:Foobar()
    print("Module2 stuff")
end

function exampleSingleton:AsetaInit(passThroughDict)
    for index, value in passThroughDict do
        self[index] = value
    end

    print("Module2 works fine, no errors")
end

return exampleSingleton