local exampleSingleton = {
    _AsetaHeader = {
        ["#Index"] = "Example1",
        ["#Dependencies"] = {"Logger"},
        ["#Data"] = {"ExampleData"},
        ["#SharedFunctions"] = {
            FoobarExample1 = "Foobar"
        }
    }
}

function exampleSingleton:Foobar()
    self.Logger:Log(2, "Example one foobar warn print!")
end

function exampleSingleton:GenerateSharedFunction()
    function exampleSingleton:GeneratedFunction(...)
        self.Logger:Log(1, "This function has been generated, input from other module:", ...)
    end
    --// Just like normally, if you use . instead of : self will get passed through :D

    self.Aseta:IndexFunction(exampleSingleton, "GeneratedFunction", exampleSingleton.GeneratedFunction)
    --// You need to pass the "owner"(self) of which environment you wanna call it in.
end

function exampleSingleton:AsetaInit()
    self:GenerateSharedFunction()

    self.Logger:Log(1, "Example1 loaded! It will always load first because of loadMap setup!")
end

return exampleSingleton