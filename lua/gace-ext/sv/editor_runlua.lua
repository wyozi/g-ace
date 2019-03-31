-- Running newly created unsaved files requires a gace.VFS.Permission.EXECUTE
-- on the root folder

gace.luarun = {}

function gace.luarun.transform(code, codeId)
    local transformed, err = gace.CallHook("GAceTransformLua", code, codeId)
    if transformed == true then return err, true end
    if transformed == false then return false, err end
    return code
end

function gace.luarun.test_compile(code, code_id)
    local fn = CompileString(code, code_id, false)
    if type(fn) == "string" then
        return false, ("Compilation error: " .. fn)
    end
    return true, fn
end

function gace.luarun.server(code, code_id)
    RunString(code, code_id)

    return true
end

function gace.luarun.serverrepl(ply, code, code_id)
    local upvals2 = gace.repl.contextSrc:Replace("$UNIQID", ply:UniqueID())

    code = gace.repl.TransformReplCode(code)

    -- First try as expression
    local f = CompileString(upvals2 .. "\n return " .. code, code_id, false)

    -- If expression failed, try as is
    if type(f) == "string" then
        f = CompileString(upvals2 .. "\n" .. code, code_id, false)
    end

    -- Nope, we're all dead
    if type(f) == "string" then
        return false, "Compile error: " .. f
    end

    local ret = {pcall(f)}
    if ret[1] == false then
        return false, "Run error: " .. tostring(ret[2])
    end

    return true, unpack(ret, 2)
end
function gace.luarun.client(cl, code, code_id)
    gace.NetMessageOut("lua-runclient", {code = code, code_id = code_id}):Send(cl)

    return true
end
function gace.luarun.clients(code, code_id)
    for _,ply in pairs(player.GetAll()) do
        gace.NetMessageOut("lua-runclient", {code = code, code_id = code_id}):Send(ply)
    end

    return true
end
function gace.luarun.shared(code, code_id)
    local status, ret = gace.luarun.server(code, code_id)
    if not status then
        return status, ret
    end

    local status, ret = gace.luarun.clients(code, code_id)
    if not status then
        return status, ret
    end

    return true
end

gace.AddHook("HandleNetMessage", "HandleLuaRun", function(netmsg)
    local ply = netmsg:GetSender()
    local op = netmsg:GetOpcode()
    local reqid = netmsg:GetReqId()
    local payload = netmsg:GetPayload()

    local function CheckPermission()
        return gace.fs.resolve(""):then_(function(node)
            return node:checkPermission(ply, gace.VFS.Permission.EXECUTE)
        end)
    end

    local function HandleOp(callback)
        local code_id = payload.codeId or string.format("%s by %s (%s)", op, ply:Nick(), ply:SteamID())

        CheckPermission():then_(function()
            local tr, te = gace.luarun.transform(payload.code or "", payload.codeId)
            if tr == false then
                return gace.RejectedATPromise("Transform error: " .. tostring(te))
            end

            local r, e = callback(tr, code_id)
            if not r then
                return gace.RejectedATPromise(e)
            end

            netmsg:CreateResponsePacket(op, {out = e}):Send()
        end):catch(function(e)
            netmsg:CreateResponsePacket(op, {err = e}):Send()
        end)
    end

    -- Git integration
    if op == "lua-runsv" then
        HandleOp(function(code, code_id)
            return gace.luarun.server(code, code_id)
        end)
    elseif op == "lua-runsvrepl" then
        HandleOp(function(code, code_id)
            return gace.luarun.serverrepl(ply, code, code_id)
        end)
    elseif op == "lua-runsh" then
        HandleOp(function(code, code_id)
            return gace.luarun.shared(code, code_id)
        end)
    elseif op == "lua-runcl" then
        HandleOp(function(code, code_id)
            return gace.luarun.clients(code, code_id)
        end)
    elseif op == "lua-runself" then
        HandleOp(function(code, code_id)
            return gace.luarun.client(ply, code, code_id)
        end)
    elseif op == "lua-runtarget" then
        local target = payload.target
        if not IsValid(target) or not target:IsPlayer() then return end

        HandleOp(function(code, code_id)
            return gace.luarun.client(target, code, code_id)
        end)
    end
end)
