local exampleSingleton = {
    _AsetaHeader = {
        ["#Index"] = "Example2",
        ["#Dependencies"] = {"Logger"},
    }
}

function exampleSingleton:GetAndCallSharedFunction()
    self.SharedFunction = self.Aseta:GetSharedFunction("FoobarExample1")
    --// Second argument can be true to get raw function without original self passed.

    self:SharedFunction("Hello from Example2!")
end

function exampleSingleton:AsetaInit()
    self.Aseta:GetSharedFunction("GeneratedFunction")("Hola from example2!")

    self:GetAndCallSharedFunction()

    self.Logger:Log(1, "Example1 loaded! It will always load first because of loadMap setup!")
end

return exampleSingleton