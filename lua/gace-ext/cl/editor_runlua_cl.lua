
gace.luarun = {}

function gace.luarun.test_compile(code, code_id)
    local fn = CompileString(code, code_id, false)
    if type(fn) == "string" then
        return false, ("Compilation error: " .. fn)
    end
    return true, fn
end

gace.AddHook("HandleNetMessage", "HandleLuaRunCl", function(netmsg)
    local op = netmsg:GetOpcode()
    local reqid = netmsg:GetReqId()
    local payload = netmsg:GetPayload()

    if op == "lua-runclient" then
        local r, e = gace.luarun.test_compile(payload.code or "", payload.code_id or "server-sent-code")
        if not r then
            gace.Log(gace.LOG_ERROR, "Running lua on self failed: ", e)
        else
            e()
        end
    end
end)
