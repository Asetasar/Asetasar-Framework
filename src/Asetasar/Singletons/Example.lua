local exampleSingleton = {
    _AsetaHeader = {
        ["#Index"] = "Module2",
        ["#Dependencies"] = {"Logger", "Signals"},
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

    print(self.Signals)

    local function test1()
        print("fsdfsd 1")
    end

    local function test2()
        print(":da 2")
    end

    local function test3()
        print("9213 3")
    end

    local function test4()
        print("9213 4")
    end

    local signal = self.Signals.New()

    signal:Once(test3)
    signal:Connect(test1)
    signal:Once(test4)
    signal:Connect(test2)
    

    for i=1, 10 do
        signal:Fire()
    end

    print("Module2 works fine, no errors")
end

return exampleSingleton