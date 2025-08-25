return {
    IsPlayer = true,
    IsServer = game:GetService("RunService"):IsServer()
}

--[[
It is possible to also possible to trigger loading by making function:

function data:AsetaInit()
end

No data are passed however...

]]